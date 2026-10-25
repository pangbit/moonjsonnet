// Fixed String-key oracle and direct-entry bounds: SPEC-JSON-CONTRACTS-2026-10-23.md.
// parseJson is an unaffected control, not a native_result caller.

///|
fn data_key_call(entry : String, text : String) -> OrderingExpr {
  match entry {
    "native" =>
      shared_mode_call(sequence_call("native", [reflect_string("data")]), [])
    "json" => json_input_call(text)
    "yaml" => yaml_parse_call(text)
    _ => abort("unlisted data entry")
  }
}

///|
fn data_key_value(
  value : OrderingExpr,
  payload : Json,
  expected : Json,
) -> Unit raise {
  for handmade in [false, true] {
    let functions : Map[String, @moonjsonnet.NativeFunction] = Map([
      ("data", { params: [], callback: _ => payload, }),
    ])
    assert_eq(
      ordering_program(value, handmade).evaluate(
        native_functions=functions,
        limits=sequence_limits(),
      ),
      expected,
    )
  }
}

///|
fn data_key_failure(value : OrderingExpr, payload : Json) -> Unit raise {
  for handmade in [false, true] {
    let functions : Map[String, @moonjsonnet.NativeFunction] = Map([
      ("data", { params: [], callback: _ => payload, }),
    ])
    assert_eq(
      ordering_program(ordering_unused(value), handmade).evaluate(
        native_functions=functions,
        limits=sequence_limits(),
      ),
      42,
    )
    try
      ordering_program(value, handmade).evaluate(
        native_functions=functions,
        limits=sequence_limits(),
      )
    catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
    } noraise {
      _ => fail("converted nonfinite data was accepted")
    }
  }
}

///|
test "native self String key retains its returned data value" {
  let value = data_key_call("native", "")
  let selected = additive_select(value, "self")
  data_key_value(sequence_call("type", [selected]), { "self": 7 }, "number")
  data_key_value(selected, { "self": 7 }, 7)
  data_key_value(value, { "self": 7 }, { "self": 7 })
}

///|
test "native super String key retains its returned data value" {
  let value = data_key_call("native", "")
  let selected = additive_select(value, "super")
  data_key_value(sequence_call("type", [selected]), { "super": 8 }, "number")
  data_key_value(selected, { "super": 8 }, 8)
  data_key_value(value, { "super": 8 }, { "super": 8 })
}

///|
test "parseYaml preserves self and super in JSON compatible Mapping data" {
  let value = yaml_parse_call("{\"self\":7,\"super\":8}")
  sequence_value(
    sequence_call("type", [additive_select(value, "self")]),
    "number",
  )
  sequence_value(additive_select(value, "self"), 7)
  sequence_value(additive_select(value, "super"), 8)
  sequence_value(value, { "self": 7, "super": 8 })
}

///|
test "converted dollar opaque and code looking keys remain inert Strings" {
  sequence_value(json_input_call("{\"self\":7,\"super\":8,\"$\":9}"), {
    "self": 7,
    "super": 8,
    "$": 9,
  })
  let text =
    #|{"$":1,"$std":2,"std":3,"local":4,"":5,"$native:0":6,"$native:1":7,"$native:$native:0":8,"a.b":9,"é😀":10,"a\u0000b":11,"error 'data'":12,"import 'not-a-file'":13}
  let payload : Json = {
    "$": 1,
    "$std": 2,
    "std": 3,
    "local": 4,
    "": 5,
    "$native:0": 6,
    "$native:1": 7,
    "$native:$native:0": 8,
    "a.b": 9,
    "é😀": 10,
    "a\u0000b": 11,
    "error 'data'": 12,
    "import 'not-a-file'": 13,
  }
  for entry in ["native", "json", "yaml"] {
    data_key_value(data_key_call(entry, text), payload, {
      "$": 1,
      "$std": 2,
      "std": 3,
      "local": 4,
      "": 5,
      "$native:0": 6,
      "$native:1": 7,
      "$native:$native:0": 8,
      "a.b": 9,
      "é😀": 10,
      "a\u0000b": 11,
      "error 'data'": 12,
      "import 'not-a-file'": 13,
    })
  }
}

///|
test "returned data keys survive nested access captured closures and simple overlays" {
  let text =
    #|{"self":7,"super":8,"$":9,"child":{"self":17,"super":18,"$":19},"rows":[{"self":27,"super":28}]}
  let payload : Json = {
    "self": 7,
    "super": 8,
    "$": 9,
    "child": { "self": 17, "super": 18, "$": 19 },
    "rows": [{ "self": 27, "super": 28 }],
  }
  for entry in ["json", "native", "yaml"] {
    let data = sequence_var("data")
    let child = additive_select(data, "child")
    let closure = make_function(
      [],
      ordering_array([
        additive_select(data, "self"),
        additive_select(data, "super"),
        additive_select(data, "$"),
        additive_select(child, "self"),
        additive_select(child, "super"),
        additive_select(child, "$"),
      ]),
    )
    let derived = ordering_binary(
      data,
      "+",
      reflect_object([(reflect_string("self"), 1, sequence_num(70))]),
    )
    let result = sequence_local(
      [
        ("data", data_key_call(entry, text)),
        ("f", closure),
        ("derived", derived),
      ],
      ordering_array([
        shared_mode_call(sequence_var("f"), []),
        additive_select(sequence_var("derived"), "self"),
        additive_select(sequence_var("derived"), "super"),
        additive_select(data, "self"),
        sequence_call("map", [
          make_function(["row"], additive_select(sequence_var("row"), "self")),
          additive_select(data, "rows"),
        ]),
      ]),
    )
    data_key_value(result, payload, [[7, 8, 9, 17, 18, 19], 70, 8, 7, [27]])
  }
}

///|
test "reserved data keys still require eager finite conversion only when the call is used" {
  for name in ["self", "super", "$"] {
    for number in [1.0 / 0.0, -1.0 / 0.0, 0.0 / 0.0] {
      let payload = Json::object(Map([(name, Json::number(number))]))
      data_key_failure(
        sequence_call("type", [data_key_call("native", "")]),
        payload,
      )
    }
    data_key_failure(
      sequence_call("type", [
        json_input_call("{" + Json::string(name).stringify() + ":1e309}"),
      ]),
      null,
    )
    for scalar in [".inf", "-.inf", ".nan"] {
      data_key_failure(
        sequence_call("type", [
          yaml_parse_call("'" + name + "': " + scalar + "\n"),
        ]),
        null,
      )
    }
  }
}
