// Fixed three-group preparation: SPEC-OBJECT-CONSTRUCTION-2026-10-23.md.
// Source and handmade AST use neutral builders, never parser-exported trees.

///|
fn construction_bad_payload(label : String) -> OrderingExpr {
  ordering_binary(sequence_num(1), "-", reflect_string(label))
}

///|
fn construction_duplicate() -> OrderingExpr {
  sequence_local(
    [("construction_key", reflect_string("same"))],
    reflect_object([
      (reflect_string("early"), 1, construction_bad_payload("early-payload")),
      (
        sequence_var("construction_key"),
        1,
        construction_bad_payload("first-duplicate-payload"),
      ),
      (
        sequence_var("construction_key"),
        1,
        construction_bad_payload("second-duplicate-payload"),
      ),
    ]),
  )
}

///|
fn construction_summary(object : OrderingExpr) -> OrderingExpr {
  let value = sequence_var("construction_object")
  sequence_local(
    [("construction_object", object)],
    ordering_array([
      sequence_call("type", [value]),
      sequence_call("objectFieldsAll", [value]),
      sequence_call("length", [value]),
    ]),
  )
}

///|
test "ordinary repeated null keys omit fields while all stored payloads stay lazy" {
  let nil = ordering_leaf("null", Literal(Json::null()))
  let object = sequence_local(
    [("construction_null", nil)],
    reflect_object([
      (
        sequence_var("construction_null"),
        1,
        construction_bad_payload("omitted-first"),
      ),
      (
        sequence_var("construction_null"),
        1,
        construction_bad_payload("omitted-second"),
      ),
      (reflect_string("kept"), 1, construction_bad_payload("kept-payload")),
    ]),
  )
  sequence_value(construction_summary(object), ["object", ["kept"], 1])
  let invalid_key : OrderingExpr = {
    source: "if true then null else construction_missing",
    tree: ordering_ast(
      If(
        ordering_ast(Literal(true)),
        nil.tree,
        sequence_var("construction_missing").tree,
      ),
    ),
  }
  // Even a key branch that would not run must be statically valid.
  pair_reject(
    reflect_object([(invalid_key, 1, construction_bad_payload("unused"))]),
  )
}

///|
test "ordinary dynamic duplicates fail construction before shape or early field demand" {
  let object = construction_duplicate()
  for
    observer in [
      sequence_call("type", [object]),
      sequence_call("objectFieldsAll", [object]),
      pair_expr("[]", object, reflect_string("early")),
    ] {
    // The helper first verifies successful creation and an unused 42 wrapper.
    // Stored payloads would fail Type, so Runtime identifies the collision path.
    sequence_failure(observer, @moonjsonnet.Runtime, None)
  }
}

///|
test "right object overlays cannot repair a left construction failure" {
  let right = reflect_object([
    (reflect_string("same"), 1, sequence_num(42)),
    (reflect_string("early"), 1, sequence_num(42)),
  ])
  let wrong_key = reflect_object([
    (sequence_num(7), 1, ordering_error("invalid-left-body")),
  ])
  for
    (left, kind) in [
      (construction_duplicate(), @moonjsonnet.Runtime),
      (wrong_key, @moonjsonnet.Type),
    ] {
    sequence_failure(
      sequence_call("type", [ordering_binary(left, "+", right)]),
      kind,
      None,
    )
  }
  // A repeated name across two valid layers is allowed; neither value is read.
  let valid_left = reflect_object([
    (reflect_string("same"), 1, construction_bad_payload("stored-left")),
  ])
  let valid_right = reflect_object([
    (reflect_string("same"), 1, construction_bad_payload("stored-right")),
  ])
  sequence_value(
    construction_summary(ordering_binary(valid_left, "+", valid_right)),
    ["object", ["same"], 1],
  )
}
