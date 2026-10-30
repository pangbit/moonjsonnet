// Independent oracle: SPEC-OBJECT-REFLECTION-EX-2026-10-22.md.
// Only neutral builders are shared; all object/call trees below are handmade.

///|
fn reflect_string(value : String) -> OrderingExpr {
  ordering_leaf(Json::string(value).stringify(), Literal(Json::string(value)))
}

///|
fn reflect_bool(value : Bool) -> OrderingExpr {
  ordering_leaf(value.to_string(), Literal(Json::boolean(value)))
}

///|
fn reflect_object(
  fields : Array[(OrderingExpr, Int32, OrderingExpr)],
) -> OrderingExpr {
  {
    source: "{" +
    fields
    .map(f => {
      let separator = match f.1 {
        2 => "::"
        3 => ":::"
        _ => ":"
      }
      "[" + f.0.source + "]" + separator + "(" + f.2.source + ")"
    })
    .join(",") +
    "}",
    tree: ordering_ast(
      Obj(
        fields.map(f => {
          key: f.0.tree,
          value: f.2.tree,
          visibility: f.1,
          additive: false,
        }),
        [],
        [],
      ),
    ),
  }
}

///|
fn reflect_observe(obj : OrderingExpr, names : Array[String]) -> OrderingExpr {
  let o = sequence_var("o")
  let calls = [
    sequence_call("objectFieldsEx", [o, reflect_bool(false)]),
    sequence_call("objectFieldsEx", [o, reflect_bool(true)]),
    sequence_call("objectFields", [o]),
    sequence_call("objectFieldsAll", [o]),
  ]
  for name in names {
    let key = reflect_string(name)
    calls.push(
      ordering_array([
        sequence_call("objectHasEx", [o, key, reflect_bool(false)]),
        sequence_call("objectHasEx", [o, key, reflect_bool(true)]),
        sequence_call("objectHas", [o, key]),
        sequence_call("objectHasAll", [o, key]),
      ]),
    )
  }
  sequence_local([("o", obj)], ordering_array(calls))
}

///|
test "object Ex queries preserve inherited key sets without reading payloads" {
  let empty = reflect_object([])
  sequence_value(reflect_observe(empty, ["missing"]), [
    [],
    [],
    [],
    [],
    [false, false, false, false],
  ])
  let bad = ordering_error("field-payload")
  let key = reflect_string
  let base = reflect_object([
    (key("a"), 1, bad),
    (key("h"), 2, bad),
    (key("x"), 3, bad),
  ])
  let middle = reflect_object([
    (key("a"), 2, bad),
    (key("h"), 1, bad),
    (key("x"), 2, bad),
    (key("new"), 1, bad),
  ])
  let top = reflect_object([
    (key("h"), 3, bad),
    (key("x"), 1, bad),
    (key("n"), 1, ordering_leaf("null", Literal(Json::null()))),
    (ordering_leaf("null", Literal(Json::null())), 1, ordering_error("omitted")),
  ])
  let derived = ordering_binary(ordering_binary(base, "+", middle), "+", top)
  sequence_value(
    reflect_observe(derived, ["a", "h", "n", "new", "x", "missing"]),
    [
      ["h", "n", "new"],
      ["a", "h", "n", "new", "x"],
      ["h", "n", "new"],
      ["a", "h", "n", "new", "x"],
      [false, true, false, true],
      [true, true, true, true],
      [true, true, true, true],
      [true, true, true, true],
      [false, true, false, true],
      [false, false, false, false],
    ],
  )
  let hidden_only = reflect_object([(key("h"), 2, bad)])
  sequence_value(reflect_observe(hidden_only, ["h"]), [
    [],
    ["h"],
    [],
    ["h"],
    [false, true, false, true],
  ])
  // Reading the reflected field is a different operation and must force it.
  let obj = reflect_object([(key("a"), 1, bad)])
  let read : OrderingExpr = {
    source: "(" + obj.source + ")[" + key("a").source + "]",
    tree: ordering_ast(Index(obj.tree, key("a").tree)),
  }
  sequence_failure(read, @moonjsonnet.Runtime, Some("field-payload"))
}

///|
test "object Ex exact Unicode names sort uniquely without normalization" {
  let bad = ordering_error("unicode-payload")
  let key = reflect_string
  let base = reflect_object([
    (key("😀"), 1, bad),
    (key("é"), 1, bad),
    (key("e\u0301"), 2, bad),
    (key("\u0000"), 1, bad),
    (key(""), 1, bad),
    (key("\ue000"), 1, bad),
  ])
  let top = reflect_object([(key("é"), 1, bad), (key("e\u0301"), 3, bad)])
  sequence_value(
    reflect_observe(ordering_binary(base, "+", top), [
      "e\u0301", "é", "e", "\u0000", "\u0000x",
    ]),
    [
      ["", "\u0000", "e\u0301", "é", "\ue000", "😀"],
      ["", "\u0000", "e\u0301", "é", "\ue000", "😀"],
      ["", "\u0000", "e\u0301", "é", "\ue000", "😀"],
      ["", "\u0000", "e\u0301", "é", "\ue000", "😀"],
      [true, true, true, true],
      [true, true, true, true],
      [false, false, false, false],
      [true, true, true, true],
      [false, false, false, false],
    ],
  )
}

///|
test "object Ex queries require heads names and flags but retain lazy values" {
  let empty = reflect_object([])
  let key = reflect_string("missing")
  let yes = reflect_bool(true)
  let zero = sequence_num(0)
  let array = ordering_array([])
  for
    failed in [
      sequence_call("objectFieldsEx", [array, yes]),
      sequence_call("objectHasEx", [array, key, yes]),
      sequence_call("objectFieldsEx", [empty, zero]),
      sequence_call("objectHasEx", [empty, key, zero]),
      sequence_call("objectHasEx", [empty, zero, yes]),
    ] {
    sequence_failure(failed, @moonjsonnet.Type, None)
  }
  let failed_head = ordering_error("required-object")
  let failed_name = ordering_error("required-name")
  let failed_flag = ordering_error("required-flag")
  let computed = reflect_object([(ordering_error("required-key"), 1, zero)])
  for
    (failed, marker) in [
      (sequence_call("objectFieldsEx", [failed_head, yes]), "required-object"),
      (sequence_call("objectHasEx", [failed_head, key, yes]), "required-object"),
      (sequence_call("objectHasEx", [empty, failed_name, yes]), "required-name"),
      (sequence_call("objectFieldsEx", [empty, failed_flag]), "required-flag"),
      (sequence_call("objectHasEx", [empty, key, failed_flag]), "required-flag"),
      (sequence_call("objectFieldsEx", [computed, yes]), "required-key"),
      (sequence_call("objectHasEx", [computed, key, yes]), "required-key"),
    ] {
    sequence_failure(failed, @moonjsonnet.Runtime, Some(marker))
  }
  let invalid = reflect_object([
    (
      reflect_string("unused"),
      2,
      ordering_leaf("reflection_missing", Var("reflection_missing")),
    ),
  ])
  for
    value in [
      sequence_call("objectFieldsEx", [invalid, yes]),
      sequence_call("objectHasEx", [invalid, key, yes]),
    ] {
    for handmade in [false, true] {
      try ordering_program(ordering_unused(value), handmade) catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
      } noraise {
        _ => fail("hidden unused child escaped static checking")
      }
    }
  }
}
