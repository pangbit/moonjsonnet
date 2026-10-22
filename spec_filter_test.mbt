// Frozen Boolean-domain and payload oracle: SPEC-FILTER-2026-10-22.md.
// No nonboolean predicate rejection is counted as normative acceptance.

///|
fn filter_field(value : OrderingExpr, name : String) -> OrderingExpr {
  let key = reflect_string(name)
  {
    source: "(" + value.source + ")[" + key.source + "]",
    tree: ordering_ast(Index(value.tree, key.tree)),
  }
}

///|
fn filter_call(func : OrderingExpr, arr : OrderingExpr) -> OrderingExpr {
  sequence_call("filter", [func, arr])
}

///|
fn filter_record(keep : OrderingExpr, value : OrderingExpr) -> OrderingExpr {
  reflect_object([
    (reflect_string("keep"), 1, keep),
    (reflect_string("value"), 1, value),
    (reflect_string("poison"), 1, ordering_error("unread-field")),
  ])
}

///|
test "filter Boolean masks retain original order duplicates and unchanged input" {
  let predicate = make_function(["x"], filter_field(sequence_var("x"), "keep"))
  let project = make_function(["x"], filter_field(sequence_var("x"), "value"))
  let cases : Array[(Array[Bool], Json)] = [
    ([false, false, false], []),
    ([false, false, true], [20]),
    ([false, true, false], [10]),
    ([false, true, true], [10, 20]),
    ([true, false, false], [20]),
    ([true, false, true], [20, 20]),
    ([true, true, false], [20, 10]),
    ([true, true, true], [20, 10, 20]),
  ]
  for (mask, expected) in cases {
    let input = ordering_array([
      filter_record(reflect_bool(mask[0]), sequence_num(20)),
      filter_record(reflect_bool(mask[1]), sequence_num(10)),
      filter_record(reflect_bool(mask[2]), sequence_num(20)),
    ])
    let value = sequence_local(
      [("a", input), ("b", filter_call(predicate, sequence_var("a")))],
      ordering_array([
        sequence_call("map", [project, sequence_var("b")]),
        sequence_call("map", [project, sequence_var("a")]),
      ]),
    )
    sequence_value(value, Json::array([expected, [20, 10, 20]]))
  }
}

///|
test "filter classifies members without reading excluded or retained payloads" {
  let yes = make_function(["unused"], reflect_bool(true))
  let no = make_function(["unused"], reflect_bool(false))
  let input = ordering_array([
    ordering_error("retained-payload"),
    sequence_num(7),
    ordering_error("other-retained-payload"),
  ])
  sequence_value(filter_call(no, input), [])
  let retained = filter_call(yes, input)
  sequence_value(
    sequence_local(
      [("a", input), ("b", retained)],
      ordering_array([
        sequence_call("length", [sequence_var("b")]),
        make_index(sequence_var("b"), 1),
        make_index(sequence_var("a"), 1),
        sequence_call("length", [sequence_var("a")]),
      ]),
    ),
    [3, 7, 7, 3],
  )
  sequence_failure(
    make_index(retained, 0),
    @moonjsonnet.Runtime,
    Some("retained-payload"),
  )
  let func = make_function(["x"], filter_field(sequence_var("x"), "keep"))
  let needs_classification = filter_call(
    func,
    ordering_array([
      filter_record(reflect_bool(true), ordering_error("premature-payload")),
      filter_record(ordering_error("membership-required"), sequence_num(9)),
    ]),
  )
  // Every membership must be known to form the array head. No relative
  // callback order is asserted; only one predicate fails, before any payload.
  sequence_failure(
    sequence_call("length", [needs_classification]),
    @moonjsonnet.Runtime,
    Some("membership-required"),
  )
  sequence_failure(
    filter_field(make_index(needs_classification, 0), "value"),
    @moonjsonnet.Runtime,
    Some("membership-required"),
  )
}

///|
test "filter validates empty heads and invokes predicates only when needed" {
  let empty = ordering_array([])
  let yes = make_function(["x"], reflect_bool(true))
  for
    invalid in [
      ordering_leaf("null", Literal(Json::null())),
      reflect_bool(false),
      sequence_num(1),
      reflect_string("function"),
      empty,
      reflect_object([]),
    ] {
    sequence_failure(filter_call(invalid, empty), @moonjsonnet.Type, None)
  }
  for
    invalid in [
      ordering_leaf("null", Literal(Json::null())),
      reflect_bool(false),
      sequence_num(1),
      reflect_string("array"),
      reflect_object([]),
      yes,
    ] {
    sequence_failure(filter_call(yes, invalid), @moonjsonnet.Type, None)
  }
  sequence_failure(
    filter_call(ordering_error("function-head"), empty),
    @moonjsonnet.Runtime,
    Some("function-head"),
  )
  sequence_failure(
    filter_call(yes, ordering_error("array-head")),
    @moonjsonnet.Runtime,
    Some("array-head"),
  )
  let dormant = make_function([], ordering_error("uncalled-predicate"))
  sequence_value(filter_call(dormant, empty), [])
  // A number-returning Function is never applied on empty input. This does
  // not adjudicate a nonboolean result from an actual predicate application.
  sequence_value(filter_call(make_function([], sequence_num(1)), empty), [])
  let wrong_arity = filter_call(
    make_function([], reflect_bool(true)),
    ordering_array([sequence_num(1)]),
  )
  sequence_failure(
    sequence_call("length", [wrong_arity]),
    @moonjsonnet.Runtime,
    None,
  )
  let unknown = make_function(
    ["x"],
    ordering_leaf("filter_missing", Var("filter_missing")),
  )
  for handmade in [false, true] {
    try
      ordering_program(ordering_unused(filter_call(unknown, empty)), handmade)
    catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
    } noraise {
      _ => fail("empty unused predicate escaped static checking")
    }
  }
}
