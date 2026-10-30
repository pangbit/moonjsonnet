// Fixed independent public contracts: SPEC-JSON-CONTRACTS-2026-10-23.md.

///|
fn json_render(name : String, value : OrderingExpr) -> OrderingExpr {
  rounding_apply(
    name,
    if name == "manifestJsonEx" {
      [(None, value), (None, reflect_string("  "))]
    } else {
      [(None, value)]
    },
  )
}

///|
fn json_string_result(value : OrderingExpr, handmade : Bool) -> String raise {
  let result = ordering_program(value, handmade).evaluate(
    limits=sequence_limits(),
  )
  guard result is String(text) else {
    fail("JSON renderer did not return String")
  }
  text
}

///|
fn json_unused_style_cases() -> Array[(OrderingExpr, String)] {
  let bad_indent = ordering_error("json-unused-indent")
  let bad_newline = ordering_error("json-unused-newline")
  let bad_separator = ordering_error("json-unused-separator")
  let result : Array[(OrderingExpr, String)] = []
  for
    (value, expected) in [
      (sequence_num(1), "1"),
      (reflect_bool(true), "true"),
      (ordering_leaf("null", Literal(Json::null())), "null"),
      (reflect_string("x"), "\"x\""),
    ] {
    result.push(
      (
        rounding_apply("manifestJsonEx", [
          (Some("value"), value),
          (Some("indent"), bad_indent),
          (Some("newline"), bad_newline),
          (Some("key_val_sep"), bad_separator),
        ]),
        expected,
      ),
    )
  }
  for
    (value, expected) in [
      (ordering_array([]), "[  ]"),
      (reflect_object([]), "{  }"),
      (
        reflect_object([
          (reflect_string("hidden"), 2, ordering_error("json-hidden")),
        ]),
        "{  }",
      ),
    ] {
    result.push(
      (
        rounding_apply("manifestJsonEx", [
          (Some("value"), value),
          (Some("indent"), bad_indent),
          (Some("newline"), reflect_string(" ")),
          (Some("key_val_sep"), bad_separator),
        ]),
        expected,
      ),
    )
  }
  for
    (value, expected) in [
      (ordering_array([sequence_num(1)]), "[1]"),
      (ordering_array([reflect_object([])]), "[{}]"),
    ] {
    result.push(
      (
        rounding_apply("manifestJsonEx", [
          (Some("value"), value),
          (Some("indent"), reflect_string("")),
          (Some("newline"), reflect_string("")),
          (Some("key_val_sep"), bad_separator),
        ]),
        expected,
      ),
    )
  }
  result
}

///|
test "parseJson converts independent JSON fixtures through source and handmade calls" {
  let fixtures : Array[(String, Json)] = [
    ("null", Json::null()),
    (" true \n", true),
    ("-12.5", -12.5),
    ("[]", []),
    ("{}", {}),
    ("\"line\\n\\u0000é😀\"", "line\n\u0000é😀"),
    (
      "{\"service\":\"web\",\"ports\":[80,443],\"flags\":[true,false,null],\"meta\":{\"region\":\"华北\"}}",
      {
        "service": "web",
        "ports": [80, 443],
        "flags": [true, false, Json::null()],
        "meta": { "region": "华北" },
      },
    ),
  ]
  for (data, expected) in fixtures {
    for named in [false, true] {
      sequence_value(
        rounding_apply("parseJson", [
          (if named { Some("str") } else { None }, reflect_string(data)),
        ]),
        expected,
      )
    }
  }
}

///|
test "parseJson distinguishes data errors required heads and unused calls" {
  for
    data in [
      "", "[1,]", "{\"x\":}", "01", "1 2", "\"unterminated", "\"\\q\"", "{\"x\":1}//comment",
    ] {
    sequence_failure(
      rounding_apply("parseJson", [(None, reflect_string(data))]),
      @moonjsonnet.Runtime,
      None,
    )
  }
  let unread = ordering_error("json-parse-unread")
  for
    value in [
      ordering_leaf("null", Literal(Json::null())),
      reflect_bool(true),
      sequence_num(1),
      ordering_array([unread]),
      reflect_object([(reflect_string("x"), 1, unread)]),
      value_head_function(unread, unread),
    ] {
    sequence_failure(
      rounding_apply("parseJson", [(None, value)]),
      @moonjsonnet.Type,
      None,
    )
  }
  sequence_failure(
    rounding_apply("parseJson", [(None, ordering_error("json-input-required"))]),
    @moonjsonnet.Runtime,
    Some("json-input-required"),
  )
  sequence_failure(
    sequence_call("type", [
      rounding_apply("parseJson", [(None, reflect_string("1e309"))]),
    ]),
    @moonjsonnet.Runtime,
    None,
  )
}

///|
test "JSON manifests preserve declared defaults custom separators visible data and scalar roots" {
  let object = reflect_object([
    (reflect_string("b"), 1, reflect_string("é😀\n\u0000")),
    (
      reflect_string("a"),
      1,
      ordering_array([
        sequence_num(1),
        reflect_bool(true),
        ordering_leaf("null", Literal(Json::null())),
      ]),
    ),
    (reflect_string("hidden"), 2, ordering_error("json-hidden-value")),
  ])
  let expected : Json = { "a": [1, true, Json::null()], "b": "é😀\n\u0000" }
  for name in ["manifestJson", "manifestJsonEx", "manifestJsonMinified"] {
    for handmade in [false, true] {
      let text = json_string_result(json_render(name, object), handmade)
      assert_eq(@json.parse(text), expected)
      assert_true(!text.has_suffix("\n"))
      for
        (scalar, value) in [
          (reflect_bool(false), Json::boolean(false)),
          (sequence_num(7), Json::number(7)),
          (reflect_string("x"), Json::string("x")),
        ] {
        assert_eq(
          @json.parse(json_string_result(json_render(name, scalar), handmade)),
          value,
        )
      }
    }
    let named = rounding_apply(
      name,
      if name == "manifestJsonEx" {
        [(Some("value"), object), (Some("indent"), reflect_string("\t"))]
      } else {
        [(Some("value"), object)]
      },
    )
    for handmade in [false, true] {
      assert_eq(@json.parse(json_string_result(named, handmade)), expected)
    }
  }
  let small = reflect_object([
    (reflect_string("a"), 1, ordering_array([sequence_num(1)])),
  ])
  for handmade in [false, true] {
    assert_eq(
      json_string_result(json_render("manifestJson", small), handmade),
      "{\n    \"a\": [\n        1\n    ]\n}",
    )
    assert_eq(
      json_string_result(json_render("manifestJsonMinified", small), handmade),
      "{\"a\":[1]}",
    )
    let custom = rounding_apply("manifestJsonEx", [
      (Some("value"), small),
      (Some("indent"), reflect_string("")),
      (Some("newline"), reflect_string(" ")),
      (Some("key_val_sep"), reflect_string(" : ")),
    ])
    assert_eq(json_string_result(custom, handmade), "{ \"a\" : [ 1 ] }")
  }
}

///|
test "JSON manifestation demands visible values and only required formatting options" {
  for name in ["manifestJson", "manifestJsonEx", "manifestJsonMinified"] {
    let bad = ordering_error("json-visible-required")
    for
      value in [
        bad,
        ordering_array([bad]),
        reflect_object([(reflect_string("field"), 1, bad)]),
      ] {
      sequence_failure(
        json_render(name, value),
        @moonjsonnet.Runtime,
        Some("json-visible-required"),
      )
    }
    let function = make_function(
      [],
      ordering_error("json-function-body-unread"),
    )
    let call = json_render(name, ordering_array([function]))
    for handmade in [false, true] {
      try
        ordering_program(call, handmade).evaluate(limits=sequence_limits())
      catch {
        @moonjsonnet.Error(d) => {
          assert_eq(d.kind, @moonjsonnet.Runtime)
          assert_true(d.message != "json-function-body-unread")
        }
      } noraise {
        _ => fail("JSON manifestation accepted a Function")
      }
    }
    pair_reject(json_render(name, sequence_var("json_missing")))
  }
  for
    (value, indent, newline, separator, marker) in [
      (
        ordering_array([sequence_num(1)]),
        ordering_error("json-indent-required"),
        reflect_string("\n"),
        reflect_string(":"),
        "json-indent-required",
      ),
      (
        ordering_array([]),
        reflect_string(""),
        ordering_error("json-newline-required"),
        reflect_string(":"),
        "json-newline-required",
      ),
      (
        reflect_object([(reflect_string("a"), 1, sequence_num(1))]),
        reflect_string(""),
        reflect_string("\n"),
        ordering_error("json-separator-required"),
        "json-separator-required",
      ),
    ] {
    sequence_failure(
      rounding_apply("manifestJsonEx", [
        (None, value),
        (None, indent),
        (None, newline),
        (None, separator),
      ]),
      @moonjsonnet.Runtime,
      Some(marker),
    )
  }
  for
    name in [
      "parseJson", "manifestJson", "manifestJsonEx", "manifestJsonMinified",
    ] {
    let valid = if name == "parseJson" {
      reflect_string("{}")
    } else {
      sequence_num(1)
    }
    let required : Array[(String?, OrderingExpr)] = if name == "manifestJsonEx" {
      [(None, valid), (None, reflect_string(""))]
    } else {
      [(None, valid)]
    }
    let wrong = required.copy()
    wrong.push(
      (
        Some("not_a_param"),
        rewrite_gate(reflect_string("binding"), sequence_num(7)),
      ),
    )
    for args in [[], wrong] {
      let value = additive_probe_scope(rounding_apply(name, args))
      for handmade in [false, true] {
        let counts : Map[String, Int32] = Map([])
        try
          ordering_program(value, handmade).evaluate(
            native_functions=rewrite_natives(counts),
            limits=sequence_limits(),
          )
        catch {
          @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
        } noraise {
          _ => fail("invalid JSON interface binding succeeded")
        }
        assert_eq(counts.length(), 0)
      }
    }
  }
}

///|
test "source manifestJsonEx skips unused formatting option expressions" {
  for (value, expected) in json_unused_style_cases() {
    assert_eq(json_string_result(value, false), expected)
  }
}

///|
test "handmade manifestJsonEx skips unused formatting option expressions" {
  for (value, expected) in json_unused_style_cases() {
    assert_eq(json_string_result(value, true), expected)
  }
}
