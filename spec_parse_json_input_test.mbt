// Independent continuation: SPEC-JSON-CONTRACTS-2026-10-23.md.
// JSON data permits scalar roots; YAML admission restrictions do not apply.

///|
fn json_input_call(data : String) -> OrderingExpr {
  rounding_apply("parseJson", [(None, reflect_string(data))])
}

///|
test "parseJson consumes one complete JSON value for every root family" {
  let roots : Array[(String, Json)] = [
    ("null", null),
    ("true", true),
    ("false", false),
    ("0", 0),
    ("-12.5", -12.5),
    ("\"text\"", "text"),
    ("[]", []),
    ("{}", {}),
  ]
  for (data, expected) in roots {
    sequence_value(json_input_call(" \t\r\n" + data + " \r\n\t"), expected)
    for suffix in [" false", "\n{}", " //comment", "x", "\u000c"] {
      sequence_failure(
        sequence_call("type", [json_input_call(data + suffix)]),
        @moonjsonnet.Runtime,
        None,
      )
    }
  }
}

///|
test "parseJson preserves standard escapes canonical Unicode pairs and arbitrary String keys" {
  let cases : Array[(String, Json)] = [
    ("\"\\\"\\\\\\/\\b\\f\\n\\r\\t\"", "\"\\/\b\u000c\n\r\t"),
    ("\"\\u0041\\u03a9\\u4E2D\\u0000\"", "AΩ中\u0000"),
    ("\"\\uD83d\\uDE00\"", "😀"),
    ("\"\\uD800\\uDC00\"", "\u{10000}"),
    ("\"\\uDBFF\\uDFFF\"", "\u{10ffff}"),
    ("\"a\\ufeffb\"", "a\ufeffb"),
    ("{\"\\u0061\":\"\\u03a9\",\"x\":\"😀\"}", { "a": "Ω", "x": "😀" }),
    (
      "{\"\":0,\"self\":1,\"super\":2,\"std\":3,\"local\":4,\"$\":5}",
      { "": 0, "self": 1, "super": 2, "std": 3, "local": 4, "$": 5 },
    ),
  ]
  for (data, expected) in cases {
    sequence_value(json_input_call(data), expected)
  }
}

///|
test "parseJson rejects malformed escapes and raw controls inside String keys and values" {
  for
    data in [
      "\"\\u12\"", "\"\\u12G4\"", "\"\\U00000041\"", "\"\\x41\"", "\"\\v\"", "\"\\u{41}\"",
      "\"a\nb\"", "{\"a\u0000\":1}", "[\"a\rb\"]",
    ] {
    sequence_failure(
      sequence_call("type", [json_input_call(data)]),
      @moonjsonnet.Runtime,
      None,
    )
  }
}

///|
test "parseJson rejects every nonfinite member before returning its parsed collection" {
  for
    data in [
      "{\"x\":1e309}", "{\"x\":-1e309}", "{\"outer\":{\"x\":1e309}}", "[{\"x\":1e309}]",
      "{\"x\":[0,1e309]}", "[1e309]",
    ] {
    sequence_failure(
      sequence_call("type", [json_input_call(data)]),
      @moonjsonnet.Runtime,
      None,
    )
  }
  let bad = json_input_call("{\"good\":1,\"bad\":1e309}")
  sequence_failure(sequence_call("length", [bad]), @moonjsonnet.Runtime, None)
  sequence_failure(additive_select(bad, "good"), @moonjsonnet.Runtime, None)
  sequence_value(json_input_call("{\"x\":[1e308,{\"ok\":-2.5}]}"), {
    "x": [1.0e308, { "ok": -2.5 }],
  })
  sequence_value(json_input_call("\"1e309\""), "1e309")
}

///|
test "parseJson boundaries retain ordinary field laziness and quoted versus actual nesting" {
  let ordinary = reflect_object([
    (reflect_string("bad"), 1, ordering_error("ordinary-field-unused")),
    (reflect_string("ok"), 1, sequence_num(42)),
  ])
  sequence_value(sequence_call("type", [ordinary]), "object")
  sequence_value(additive_select(ordinary, "ok"), 42)
  let brackets = "[".repeat(40) + "]".repeat(40)
  let valid = json_input_call("\"" + brackets + "\"")
  let deep = json_input_call("[".repeat(40) + "0" + "]".repeat(40))
  let limits = { ..sequence_limits(), depth: 32, }
  for handmade in [false, true] {
    assert_eq(
      ordering_program(valid, handmade).evaluate(limits~),
      Json::string(brackets),
    )
    try ordering_program(deep, handmade).evaluate(limits~) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
    } noraise {
      _ => fail("JSON nesting escaped the configured depth bound")
    }
  }
}
