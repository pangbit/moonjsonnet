// Fixed source-defined projection criteria: SPEC-OBJECT-REMOVE-KEY-2026-10-25.md.
// Source strings and public ASTs are built separately; every expected value is literal.

///|
fn remove_key_call(
  obj : OrderingExpr,
  key : OrderingExpr,
  named? : Bool = false,
) -> OrderingExpr {
  if !named {
    return sequence_call("objectRemoveKey", [obj, key])
  }
  {
    source: "std.objectRemoveKey(key=(" +
    key.source +
    "),obj=(" +
    obj.source +
    "))",
    tree: ordering_ast(
      Call(
        additive_select(sequence_var("std"), "objectRemoveKey").tree,
        [(Some("key"), key.tree), (Some("obj"), obj.tree)],
        false,
      ),
    ),
  }
}

///|
test "objectRemoveKey retained fields read the original self after dependency removal" {
  let original = reflect_object([
    (reflect_string("a"), 1, sequence_num(1)),
    (reflect_string("b"), 1, additive_select(sequence_var("self"), "a")),
  ])
  for named in [false, true] {
    sequence_value(
      additive_select(
        remove_key_call(original, reflect_string("a"), named~),
        "b",
      ),
      1,
    )
  }
}

///|
test "objectRemoveKey preserves inherited values closures and immutable aliases under overlays" {
  let original = ordering_binary(
    reflect_object([(reflect_string("a"), 1, sequence_num(1))]),
    "+",
    reflect_object([
      (reflect_string("a"), 1, sequence_num(2)),
      (reflect_string("b"), 1, additive_select(sequence_var("self"), "a")),
      (reflect_string("c"), 1, additive_select(sequence_var("super"), "a")),
      (
        reflect_string("f"),
        1,
        make_function([], additive_select(sequence_var("self"), "a")),
      ),
    ]),
  )
  let o = sequence_var("o")
  let r = sequence_var("r")
  let overlay = sequence_var("overlay")
  sequence_value(
    sequence_local(
      [
        ("o", original),
        ("r", remove_key_call(o, reflect_string("a"))),
        (
          "overlay",
          ordering_binary(
            r,
            "+",
            reflect_object([(reflect_string("a"), 1, sequence_num(99))]),
          ),
        ),
      ],
      ordering_array([
        additive_select(o, "b"),
        additive_select(r, "b"),
        additive_select(r, "c"),
        value_head_call(additive_select(r, "f"), []),
        additive_select(overlay, "b"),
        additive_select(overlay, "c"),
        value_head_call(additive_select(overlay, "f"), []),
        additive_select(o, "a"),
        additive_select(o, "b"),
      ]),
    ),
    [2, 2, 1, 2, 2, 1, 2, 2, 2],
  )
}

///|
test "objectRemoveKey projects visible keys and preserves exact empty and Unicode names" {
  let bad = ordering_error("unselected-projection-payload")
  let original = reflect_object([
    (reflect_string("drop"), 1, bad),
    (reflect_string("h"), 2, bad),
    (reflect_string("keep"), 1, sequence_num(7)),
    (reflect_string("v"), 3, sequence_num(8)),
    (reflect_string(""), 1, sequence_num(9)),
    (reflect_string("😀"), 1, sequence_num(10)),
  ])
  let o = sequence_var("o")
  let r = sequence_var("r")
  sequence_value(
    sequence_local(
      [("o", original), ("r", remove_key_call(o, reflect_string("drop")))],
      ordering_array([
        sequence_call("objectFieldsAll", [r]),
        sequence_call("length", [r]),
        additive_select(r, "keep"),
        additive_select(r, "v"),
        additive_select(r, ""),
        additive_select(r, "😀"),
        sequence_call("objectFieldsAll", [o]),
      ]),
    ),
    [
      ["", "keep", "v", "😀"],
      4,
      7,
      8,
      9,
      10,
      ["", "drop", "h", "keep", "v", "😀"],
    ],
  )
  let names = reflect_object([
    (reflect_string(""), 1, sequence_num(1)),
    (reflect_string("é"), 1, sequence_num(2)),
    (reflect_string("e\u0301"), 1, sequence_num(3)),
    (reflect_string("😀"), 1, sequence_num(4)),
  ])
  let cases : Array[(String, Json)] = [
    ("", ["e\u0301", "é", "😀"]),
    ("é", ["", "e\u0301", "😀"]),
    ("e\u0301", ["", "é", "😀"]),
    ("😀", ["", "e\u0301", "é"]),
  ]
  for (key, expected) in cases {
    sequence_value(
      sequence_call("objectFieldsAll", [
        remove_key_call(names, reflect_string(key)),
      ]),
      expected,
    )
  }
}

///|
test "objectRemoveKey shape and unused calls leave all value payloads dormant" {
  let original = reflect_object([
    (reflect_string("drop"), 1, ordering_error("removed-value")),
    (reflect_string("h"), 2, ordering_error("hidden-value")),
    (reflect_string("keep"), 1, ordering_error("retained-value")),
  ])
  let result = remove_key_call(original, reflect_string("drop"))
  sequence_value(
    ordering_array([
      sequence_call("type", [result]),
      sequence_call("objectFields", [result]),
      sequence_call("length", [result]),
    ]),
    ["object", ["keep"], 1],
  )
  sequence_value(
    ordering_unused(
      remove_key_call(
        ordering_error("unused-object"),
        ordering_error("unused-key"),
      ),
    ),
    42,
  )
  sequence_failure(
    additive_select(result, "keep"),
    @moonjsonnet.Runtime,
    Some("retained-value"),
  )
}

///|
test "objectRemoveKey only demands a key when a visible field must be filtered" {
  for
    empty in [
      reflect_object([]),
      reflect_object([
        (reflect_string("h"), 2, ordering_error("hidden-payload")),
      ]),
    ] {
    sequence_value(
      remove_key_call(empty, ordering_error("key-required")),
      Json::object(Map([])),
    )
  }
  sequence_failure(
    remove_key_call(
      reflect_object([(reflect_string("a"), 1, ordering_error("value-unread"))]),
      ordering_error("key-required"),
    ),
    @moonjsonnet.Runtime,
    Some("key-required"),
  )
}

///|
test "objectRemoveKey compares nonstring keys without coercion or nested payload demand" {
  let obj = reflect_object([(reflect_string("a"), 1, sequence_num(1))])
  let bad = ordering_error("nonstring-key-payload")
  for
    key in [
      ordering_leaf("null", Literal(null)),
      reflect_bool(false),
      sequence_num(0),
      ordering_array([bad]),
      reflect_object([(reflect_string("x"), 1, bad)]),
      make_function([], bad),
    ] {
    sequence_value(
      remove_key_call(obj, key),
      Json::object(Map([("a", Json::number(1))])),
    )
  }
}

///|
test "objectRemoveKey retained reads demand original flat assertions but empty projections do not" {
  let original : OrderingExpr = {
    source: "{assert false,drop:1,keep:2}",
    tree: assertion_self_object(
      [("drop", sequence_num(1).tree), ("keep", sequence_num(2).tree)],
      checks=[(reflect_bool(false).tree, None)],
    ),
  }
  let result = remove_key_call(original, reflect_string("drop"))
  sequence_value(sequence_call("objectFieldsAll", [result]), ["keep"])
  sequence_failure(
    additive_select(result, "keep"),
    @moonjsonnet.Assertion,
    None,
  )
  let only : OrderingExpr = {
    source: "{assert false,only:1}",
    tree: assertion_self_object([("only", sequence_num(1).tree)], checks=[
      (reflect_bool(false).tree, None),
    ]),
  }
  sequence_value(
    remove_key_call(only, reflect_string("only")),
    Json::object(Map([])),
  )
}

///|
test "objectRemoveKey requires object construction and valid bindings while retaining static checks" {
  for
    value in [
      ordering_leaf("null", Literal(null)),
      reflect_bool(true),
      sequence_num(1),
      reflect_string("object"),
      ordering_array([ordering_error("unread-array")]),
      make_function([], ordering_error("unread-function")),
    ] {
    sequence_failure(
      remove_key_call(value, reflect_string("a")),
      @moonjsonnet.Type,
      None,
    )
  }
  for
    (obj, marker) in [
      (ordering_error("object-required"), "object-required"),
      (
        reflect_object([
          (
            ordering_error("computed-key-required"),
            1,
            ordering_error("unread-body"),
          ),
        ]),
        "computed-key-required",
      ),
    ] {
    sequence_failure(
      remove_key_call(obj, reflect_string("a")),
      @moonjsonnet.Runtime,
      Some(marker),
    )
  }
  for
    args in [
      [],
      [reflect_object([])],
      [reflect_object([]), reflect_string("a"), sequence_num(0)],
    ] {
    sequence_failure(
      sequence_call("objectRemoveKey", args),
      @moonjsonnet.Runtime,
      None,
    )
  }
  for
    value in [
      remove_key_call(sequence_var("remove_missing_name"), reflect_string("a")),
      remove_key_call(reflect_object([]), sequence_var("remove_missing_name")),
    ] {
    for handmade in [false, true] {
      try ordering_program(ordering_unused(value), handmade) catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
      } noraise {
        _ => fail("an unused projection must not hide a static free name")
      }
    }
  }
}
