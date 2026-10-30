// Independent bounded public scope: SPEC-PARSE-YAML-2026-10-25.md.
// Best-effort JSON-compatible collections, not a complete YAML dialect contract.

///|
fn yaml_parse_call(data : String, named~ : Bool = false) -> OrderingExpr {
  rounding_apply("parseYaml", [
    (if named { Some("str") } else { None }, reflect_string(data)),
  ])
}

///|
test "parseYaml public example and JSON compatible collection roots retain literal values" {
  let cases : Array[(String, Json)] = [
    ("foo: bar", { "foo": "bar" }),
    ("{}", {}),
    ("[]", []),
    (
      "[null,true,false,0,-2,0.5,\"text\"]",
      [null, true, false, 0, -2, 0.5, "text"],
    ),
    (
      "{\"a\":[1,{\"b\":false}],\"empty\":{}}",
      { "a": [1, { "b": false }], "empty": {} },
    ),
    (
      "list:\n  - 1\n  - 2\nname: \"value\"\n",
      { "list": [1, 2], "name": "value" },
    ),
    ("# bounded collection\n- 1\n- {x: 2}\n", [1, { "x": 2 }]),
  ]
  for (data, expected) in cases {
    for named in [false, true] {
      sequence_value(yaml_parse_call(data, named~), expected)
    }
  }
}

///|
test "parseYaml has one required str and rejects bindings before supplied demand" {
  let function = additive_select(sequence_var("std"), "parseYaml")
  sequence_value(sequence_call("length", [function]), 1)
  sequence_value(
    sequence_local(
      [("f", function)],
      shared_mode_call(sequence_var("f"), [
        (Some("str"), reflect_string("foo: bar")),
      ]),
    ),
    { "foo": "bar" },
  )
  let bad = ordering_error("binding-must-skip")
  for
    args in [
      [],
      [(Some("unknown"), bad)],
      [(None, bad), (None, bad)],
      [(None, bad), (Some("str"), bad)],
    ] {
    deletion_binding_reject(rounding_apply("parseYaml", args))
  }
}

///|
test "parseYaml requires only its String head and leaves unused calls and payloads dormant" {
  for
    input in [
      ordering_leaf("null", Literal(Json::null())),
      reflect_bool(true),
      sequence_num(1),
      ordering_array([ordering_error("array-item-unused")]),
      reflect_object([(reflect_string("x"), 1, ordering_error("field-unused"))]),
      make_function([], ordering_error("body-uncalled")),
    ] {
    sequence_failure(
      sequence_call("type", [sequence_call("parseYaml", [input])]),
      @moonjsonnet.Type,
      None,
    )
  }
  sequence_failure(
    sequence_call("type", [
      sequence_call("parseYaml", [ordering_error("yaml-input-required")]),
    ]),
    @moonjsonnet.Runtime,
    Some("yaml-input-required"),
  )
}

///|
test "parseYaml rejects scalar document roots instead of extending its public root domain" {
  for
    data in [
      "a", "1", "-2", "0.5", "true", "false", "null", "~", "\"text\"", "'text'",
      "|\n  text\n", ">-\n  text\n",
    ] {
    for named in [false, true] {
      sequence_failure(
        sequence_call("type", [yaml_parse_call(data, named~)]),
        @moonjsonnet.Runtime,
        None,
      )
    }
  }
}

///|
test "parseYaml propagates admitted collection syntax and nonfinite failures before type inspection" {
  for
    data in [
      "{\"ok\":1,\"bad\":[2}", "[1,{\"bad\":2}", "[.inf]", "{value: .nan}",
    ] {
    sequence_failure(
      sequence_call("type", [yaml_parse_call(data)]),
      @moonjsonnet.Runtime,
      None,
    )
  }
  sequence_value(yaml_parse_call("{value: \".inf\"}"), { "value": ".inf" })
}

///|
test "parseYaml decodes collection String data without executing Jsonnet expressions" {
  sequence_value(
    yaml_parse_call("{\"😀\":[\"e\\u0301\",\"\\u0000\"],\"\":\"empty key\"}"),
    { "😀": ["e\u0301", "\u0000"], "": "empty key" },
  )
  sequence_value(
    yaml_parse_call(
      "{code: \"error 'data'\",file: \"import 'not-a-file'\",call: \"std.native('never')()\"}",
    ),
    {
      "code": "error 'data'",
      "file": "import 'not-a-file'",
      "call": "std.native('never')()",
    },
  )
}
