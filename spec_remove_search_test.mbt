// Independent fixed source criteria: SPEC-REMOVE-SEARCH-2026-10-25.md.
// This file does not settle B0 or use a reference implementation as an oracle.

///|
fn remove_search_call(
  arr : OrderingExpr,
  elem : OrderingExpr,
  named~ : Bool = false,
) -> OrderingExpr {
  rounding_apply(
    "remove",
    if named {
      [(Some("elem"), elem), (Some("arr"), arr)]
    } else {
      [(None, arr), (None, elem)]
    },
  )
}

///|
fn remove_search_error(value : OrderingExpr, marker : String) -> Unit raise {
  for handmade in [false, true] {
    assert_eq(
      ordering_program(ordering_unused(value), handmade).evaluate(
        limits=sequence_limits(),
      ),
      42,
    )
    let program = ordering_program(value, handmade)
    try program.evaluate(limits=sequence_limits()) catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Runtime)
        assert_eq(d.message, marker)
      }
    } noraise {
      actual =>
        fail("required search error " + marker + ", got " + actual.stringify())
    }
  }
}

///|
test "remove empty arrays skip target evaluation through positional and named calls" {
  let arr = ordering_array([])
  let elem = ordering_error("unused-empty-target")
  for named in [false, true] {
    let removed = remove_search_call(arr, elem, named~)
    sequence_value(removed, [])
    sequence_value(sequence_call("length", [removed]), 0)
    sequence_value(sequence_call("type", [removed]), "array")
  }
  sequence_value(
    sequence_local(
      [("original", arr)],
      ordering_array([
        remove_search_call(sequence_var("original"), elem),
        sequence_var("original"),
      ]),
    ),
    [[], []],
  )
}

///|
test "remove completes every find comparison before returning a result head" {
  let tail = ordering_error("tail-required")
  for
    arr in [
      ordering_array([sequence_num(1), tail]),
      ordering_array([sequence_num(0), sequence_num(1), tail]),
      ordering_array([sequence_num(1), sequence_num(1), tail]),
    ] {
    for named in [false, true] {
      let result = remove_search_call(arr, sequence_num(1), named~)
      remove_search_error(sequence_call("length", [result]), "tail-required")
      remove_search_error(sequence_call("type", [result]), "tail-required")
    }
  }
  remove_search_error(
    remove_search_call(
      ordering_array([ordering_error("head-required"), sequence_num(1)]),
      sequence_num(1),
    ),
    "head-required",
  )
}

///|
test "remove preserves first deletion values aliases nested laziness and control flow gates" {
  let values = ordering_array([
    sequence_num(1),
    sequence_num(2),
    sequence_num(1),
    sequence_num(3),
  ])
  for named in [false, true] {
    sequence_value(remove_search_call(values, sequence_num(1), named~), [
      2, 1, 3,
    ])
    sequence_value(remove_search_call(values, sequence_num(9), named~), [
      1, 2, 1, 3,
    ])
  }
  sequence_value(
    sequence_local(
      [("original", values)],
      ordering_array([
        remove_search_call(sequence_var("original"), sequence_num(1)),
        sequence_var("original"),
      ]),
    ),
    [[2, 1, 3], [1, 2, 1, 3]],
  )
  let bad = ordering_error("unread-nested-payload")
  for
    retained in [
      ordering_array([bad]),
      reflect_object([(reflect_string("field"), 1, bad)]),
    ] {
    sequence_value(
      sequence_call("length", [
        remove_search_call(
          ordering_array([sequence_num(1), retained]),
          sequence_num(1),
        ),
      ]),
      1,
    )
  }
  remove_search_error(
    remove_search_call(
      ordering_array([sequence_num(1)]),
      ordering_error("target-required"),
    ),
    "target-required",
  )
  remove_search_error(
    remove_search_call(ordering_error("array-required"), sequence_num(1)),
    "array-required",
  )
  let required = sequence_call("length", [
    remove_search_call(
      ordering_array([sequence_num(1), ordering_error("skipped-search")]),
      sequence_num(1),
    ),
  ])
  let predicate = ordering_binary(required, "==", sequence_num(0))
  let yes : OrderingExpr = {
    source: "if true then 7 else (" + required.source + ")",
    tree: ordering_ast(
      If(reflect_bool(true).tree, sequence_num(7).tree, required.tree),
    ),
  }
  let no : OrderingExpr = {
    source: "if false then (" + required.source + ") else 7",
    tree: ordering_ast(
      If(reflect_bool(false).tree, required.tree, sequence_num(7).tree),
    ),
  }
  sequence_value(
    ordering_array([
      ordering_binary(reflect_bool(false), "&&", predicate),
      ordering_binary(reflect_bool(true), "||", predicate),
      yes,
      no,
      ordering_unused(required),
    ]),
    [false, true, 7, 7, 42],
  )
  let invalid_condition : OrderingExpr = {
    source: "if 1 then (" + required.source + ") else 7",
    tree: ordering_ast(
      If(sequence_num(1).tree, required.tree, sequence_num(7).tree),
    ),
  }
  sequence_failure(invalid_condition, @moonjsonnet.Type, None)
}
