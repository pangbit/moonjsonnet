// Shared bounded review: SPEC-OBJECT-HEAD-2026-10-22.md.
// Reuse object-fields-ex visibility proofs; only consumer transfer is new.

///|
fn object_head_summary(value : OrderingExpr) -> OrderingExpr {
  let obj = sequence_var("o")
  sequence_local(
    [("o", value)],
    ordering_array([
      sequence_call("length", [obj]),
      sequence_call("type", [obj]),
      sequence_call("length", [
        sequence_call("objectFieldsEx", [obj, reflect_bool(false)]),
      ]),
      sequence_call("length", [
        sequence_call("objectFieldsEx", [obj, reflect_bool(true)]),
      ]),
    ]),
  )
}

///|
test "object length and type consume visible key sets without reading values" {
  let bad = ordering_error("unread-value")
  let key = reflect_string
  sequence_value(object_head_summary(reflect_object([])), [0, "object", 0, 0])
  sequence_value(object_head_summary(reflect_object([(key("h"), 2, bad)])), [
    0, "object", 0, 1,
  ])
  let base = reflect_object([
    (key("a"), 1, bad),
    (key("h"), 2, bad),
    (key("x"), 1, bad),
  ])
  let overlay = reflect_object([
    (key("a"), 2, bad),
    (key("h"), 3, bad),
    (key("x"), 1, bad),
    (key("z"), 1, bad),
  ])
  sequence_value(object_head_summary(base), [2, "object", 2, 3])
  sequence_value(object_head_summary(ordering_binary(base, "+", overlay)), [
    3, "object", 3, 4,
  ])
  let omitted = ordering_leaf("null", Literal(Json::null()))
  sequence_value(
    object_head_summary(
      reflect_object([
        (key(""), 1, bad),
        (omitted, 1, ordering_error("omitted-value")),
      ]),
    ),
    [1, "object", 1, 1],
  )
}

///|
test "object summaries require construction and preserve static and overload boundaries" {
  let computed = reflect_object([
    (ordering_error("key-required"), 1, ordering_error("unused-value")),
  ])
  for name in ["length", "type"] {
    sequence_failure(
      sequence_call(name, [ordering_error("head-required")]),
      @moonjsonnet.Runtime,
      Some("head-required"),
    )
    sequence_failure(
      sequence_call(name, [computed]),
      @moonjsonnet.Runtime,
      Some("key-required"),
    )
    let invalid = reflect_object([
      (
        reflect_string("h"),
        2,
        ordering_leaf("object_head_missing", Var("object_head_missing")),
      ),
    ])
    for handmade in [false, true] {
      try
        ordering_program(
          ordering_unused(sequence_call(name, [invalid])),
          handmade,
        )
      catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
      } noraise {
        _ => fail("hidden unused field escaped static checking")
      }
    }
  }
  // Array/String/Function have their own length overloads and are not wrong
  // object-type inputs. Only the documented unsupported scalar kinds fail.
  for
    value in [
      ordering_leaf("null", Literal(Json::null())),
      reflect_bool(true),
      sequence_num(1),
    ] {
    sequence_failure(sequence_call("length", [value]), @moonjsonnet.Type, None)
  }
}
