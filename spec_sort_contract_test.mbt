// Independent continuation: SPEC-SORT-DEMAND-2026-10-25.md.
// Source and handmade AST entries share only neutral builders, never an oracle.

///|
fn sort_contract_optional(
  default_value : OrderingExpr,
  body : OrderingExpr,
) -> OrderingExpr {
  {
    source: "function(x,extra=(" +
    default_value.source +
    "))(" +
    body.source +
    ")",
    tree: ordering_ast(
      Func(
        [
          { name: "x", default_value: None, range: None, },
          {
            name: "extra",
            default_value: Some(default_value.tree),
            range: None,
          },
        ],
        body.tree,
      ),
    ),
  }
}

///|
fn sort_contract_ids(value : OrderingExpr, size : Int32) -> OrderingExpr {
  let fields : Array[OrderingExpr] = []
  for i in 0..<size {
    fields.push(additive_select(make_index(sequence_var("sorted"), i), "id"))
  }
  sequence_local([("sorted", value)], ordering_array(fields))
}

///|
test "sort contract admits its documented signature defaults closures and static unique names" {
  let sort = additive_select(sequence_var("std"), "sort")
  sequence_value(
    ordering_array([
      sequence_call("type", [sort]),
      sequence_call("length", [sort]),
    ]),
    ["function", 2],
  )
  let values = ordering_array([
    sequence_num(2),
    sequence_num(1),
    sequence_num(3),
  ])
  let identity = make_function(["x"], sequence_var("x"))
  for key in [None, Some(identity)] {
    for named in [false, true] {
      sequence_value(sort_demand_call(values, key, named), [1, 2, 3])
    }
  }
  let unused_default = sort_contract_optional(
    ordering_error("sort-unused-key-default"),
    sequence_var("x"),
  )
  sequence_value(sort_demand_call(values, Some(unused_default), true), [1, 2, 3])
  let used_default = sort_contract_optional(
    sequence_num(0),
    ordering_binary(
      ordering_leaf("-x", Unary("-", sequence_var("x").tree)),
      "+",
      sequence_var("extra"),
    ),
  )
  sequence_value(sort_demand_call(values, Some(used_default), false), [3, 2, 1])
  sequence_value(
    sequence_local(
      [("direction", sequence_num(-1))],
      sort_demand_call(
        values,
        Some(
          make_function(
            ["x"],
            ordering_binary(sequence_var("x"), "*", sequence_var("direction")),
          ),
        ),
        true,
      ),
    ),
    [3, 2, 1],
  )
  let duplicate = rounding_apply("sort", [
    (Some("arr"), values),
    (Some("keyF"), identity),
    (Some("keyF"), identity),
  ])
  pair_reject(duplicate)
  pair_reject(ordering_unused(duplicate))
  // A required key application rejects each non-Function head without children.
  for
    invalid in [
      ordering_leaf("null", Literal(Json::null())),
      reflect_bool(false),
      sequence_num(7),
      reflect_string("function"),
      ordering_array([ordering_error("sort-invalid-key-array-child")]),
      merge_patch_object([
        ("unread", ordering_error("sort-invalid-key-object-child")),
      ]),
    ] {
    sequence_failure(
      sort_demand_call(values, Some(invalid), true),
      @moonjsonnet.Type,
      None,
    )
  }
  for
    invalid in [
      make_function([], sequence_num(0)),
      make_function(["x", "y"], sequence_var("x")),
    ] {
    sequence_failure(
      sort_demand_call(values, Some(invalid), false),
      @moonjsonnet.Runtime,
      None,
    )
  }
}

///|
test "sort contract orders exact finite Numbers Unicode scalars and recursive Array keys" {
  let large = ordering_leaf("9007199254740992", Literal(9007199254740992.0))
  let negative_large = ordering_leaf(
    "-9007199254740992",
    Unary("-", large.tree),
  )
  sequence_value(
    sort_demand_call(
      ordering_array([
        large,
        ordering_leaf("0.5", Literal(0.5)),
        sequence_num(0),
        negative_large,
        ordering_leaf("-0.5", Unary("-", ordering_ast(Literal(0.5)))),
      ]),
      None,
      false,
    ),
    [-9007199254740992.0, -0.5, 0, 0.5, 9007199254740992.0],
  )
  sequence_value(
    sort_demand_call(
      ordering_array([
        reflect_string("𐀀"),
        reflect_string("￿"),
        reflect_string("😀"),
        reflect_string("a\u0000"),
        reflect_string("a"),
        reflect_string(""),
        reflect_string("é"),
        reflect_string("e\u0301"),
      ]),
      None,
      true,
    ),
    ["", "a", "a\u0000", "e\u0301", "é", "￿", "𐀀", "😀"],
  )
  sequence_value(
    sort_demand_call(
      ordering_array([
        ordering_array([
          sequence_num(1),
          ordering_array([sequence_num(0), sequence_num(0)]),
        ]),
        ordering_array([sequence_num(1), ordering_array([])]),
        ordering_array([sequence_num(0)]),
        ordering_array([]),
        ordering_array([sequence_num(1), ordering_array([sequence_num(0)])]),
        ordering_array([sequence_num(1)]),
      ]),
      None,
      false,
    ),
    [[], [0], [1], [1, []], [1, [0]], [1, [0, 0]]],
  )
}

///|
test "sort contract compares only required key prefixes and rejects demanded incompatible keys" {
  let unread = ordering_error("sort-long-key-tail")
  let sorted = sort_demand_call(
    ordering_array([
      ordering_array([sequence_num(0), unread]),
      ordering_array([sequence_num(0)]),
    ]),
    None,
    false,
  )
  sequence_value(sequence_call("length", [sorted]), 2)
  sequence_value(make_index(sorted, 0), [0])
  sequence_value(sequence_call("length", [make_index(sorted, 1)]), 2)
  sequence_failure(
    make_index(make_index(sorted, 1), 1),
    @moonjsonnet.Runtime,
    Some("sort-long-key-tail"),
  )
  sequence_value(
    make_index(
      sort_demand_call(
        ordering_array([
          ordering_array([ordering_array([]), unread]),
          ordering_array([ordering_array([])]),
        ]),
        None,
        true,
      ),
      0,
    ),
    [[]],
  )
  // A noncomparable child outside the common prefix must not be inspected.
  sequence_value(
    sort_demand_call(
      ordering_array([ordering_array([reflect_bool(true)]), ordering_array([])]),
      None,
      false,
    ),
    [[], [true]],
  )
  let two = ordering_array([sequence_num(2), sequence_num(1)])
  for
    invalid in [
      ordering_leaf("null", Literal(Json::null())),
      reflect_bool(false),
      merge_patch_object([("unread", ordering_error("sort-object-key-payload"))]),
      make_function([], ordering_error("sort-function-key-body")),
      ordering_array([reflect_bool(true)]),
      ordering_array([ordering_array([merge_patch_object([])])]),
    ] {
    sequence_failure(
      sequence_call("type", [
        sort_demand_call(two, Some(make_function(["x"], invalid)), false),
      ]),
      @moonjsonnet.Type,
      None,
    )
  }
  for
    mixed in [
      ordering_array([sequence_num(1), reflect_string("a")]),
      ordering_array([
        ordering_array([sequence_num(1)]),
        ordering_array([reflect_string("a")]),
      ]),
    ] {
    sequence_failure(
      sequence_call("type", [sort_demand_call(mixed, None, false)]),
      @moonjsonnet.Type,
      None,
    )
  }
  // Primitive length failures are independent of the non-Array source extensions.
  for
    invalid in [
      ordering_leaf("null", Literal(Json::null())),
      reflect_bool(true),
      sequence_num(1),
    ] {
    sequence_failure(
      sort_demand_call(invalid, None, false),
      @moonjsonnet.Type,
      None,
    )
  }
}

///|
test "sort contract requires Array then key then comparison without unrelated payload demand" {
  for handmade in [false, true] {
    for stage in 0..<4 {
      let marker = "sort-required-phase-" + stage.to_string()
      let payloads = ordering_array([
        rewrite_gate(reflect_string("element"), sequence_num(2)),
        rewrite_gate(reflect_string("element"), sequence_num(1)),
      ])
      let input = if stage == 0 {
        ordering_error(marker)
      } else {
        rewrite_gate(reflect_string("array"), payloads)
      }
      let key_value = if stage == 1 {
        ordering_error(marker)
      } else {
        make_function(
          ["x"],
          if stage == 2 {
            rewrite_gate(reflect_string("body"), ordering_error(marker))
          } else if stage == 3 {
            ordering_array([
              rewrite_gate(reflect_string("comparison"), ordering_error(marker)),
            ])
          } else {
            sequence_num(0)
          },
        )
      }
      let key = rewrite_gate(reflect_string("key"), key_value)
      let counts : Map[String, Int32] = Map([])
      let value = sequence_call("length", [
        sort_demand_call(input, Some(key), true),
      ])
      try
        ordering_program(additive_probe_scope(value), handmade).evaluate(
          native_functions=rewrite_natives(counts),
          limits=sequence_limits(),
        )
      catch {
        @moonjsonnet.Error(d) => {
          assert_eq(d.kind, @moonjsonnet.Runtime)
          assert_eq(d.message, marker)
        }
      } noraise {
        _ => fail("required sort phase error was skipped")
      }
      assert_eq(counts.get("element").unwrap_or(0), 0)
      if stage == 0 {
        assert_eq(counts.length(), 0)
      } else {
        assert_eq(counts.get("array").unwrap_or(0), 1)
        assert_eq(counts.get("key").unwrap_or(0), 1)
      }
      if stage == 2 {
        assert_true(counts.get("body").unwrap_or(0) > 0)
      }
      if stage == 3 {
        assert_true(counts.get("comparison").unwrap_or(0) > 0)
      }
    }
  }
}

///|
test "sort contract retains every item and stable ties across both source and native width seams" {
  for n in [2, 3, 7, 8, 9, 29, 30, 31, 32, 33, 63, 64, 65] {
    let rows : Array[OrderingExpr] = []
    for i in 0..<n {
      rows.push(
        merge_patch_object([
          ("key", sequence_num((n - i - 1) % 4)),
          ("id", sequence_num(i)),
          ("unread", ordering_error("sort-stability-unread-field")),
        ]),
      )
    }
    let expected : Array[Json] = []
    // Group membership and original indices define the oracle, not a sorting algorithm.
    for group in 0..<4 {
      for i in 0..<n {
        if (n - i - 1) % 4 == group {
          expected.push(Json::number(i.to_double()))
        }
      }
    }
    sequence_value(
      sort_contract_ids(
        sort_demand_call(
          ordering_array(rows),
          Some(make_function(["x"], additive_select(sequence_var("x"), "key"))),
          true,
        ),
        n,
      ),
      Json::array(expected),
    )
  }
  let negative_zero = ordering_leaf("-0", Unary("-", sequence_num(0).tree))
  let rows = ordering_array([
    merge_patch_object([("id", reflect_string("a")), ("key", negative_zero)]),
    merge_patch_object([("id", reflect_string("b")), ("key", sequence_num(0))]),
    merge_patch_object([("id", reflect_string("c")), ("key", negative_zero)]),
  ])
  sequence_value(
    sort_contract_ids(
      sort_demand_call(
        rows,
        Some(make_function(["x"], additive_select(sequence_var("x"), "key"))),
        false,
      ),
      3,
    ),
    ["a", "b", "c"],
  )
}

///|
test "sort contract preserves mixed lazy payload heads and shared original Array elements" {
  let unread = ordering_error("sort-mixed-unread-child")
  let payloads = ordering_array([
    make_function([], unread),
    merge_patch_object([("unread", unread)]),
    ordering_array([unread]),
    reflect_bool(true),
    ordering_leaf("null", Literal(Json::null())),
    sequence_num(7),
    reflect_string("text"),
  ])
  let sorted = sort_demand_call(
    payloads,
    Some(make_function(["x"], sequence_num(0))),
    false,
  )
  let types : Array[OrderingExpr] = []
  for i in 0..<7 {
    types.push(sequence_call("type", [make_index(sequence_var("sorted"), i)]))
  }
  sequence_value(sequence_local([("sorted", sorted)], ordering_array(types)), [
    "function", "object", "array", "boolean", "null", "number", "string",
  ])
  for handmade in [false, true] {
    let values = rewrite_gate(
      reflect_string("array"),
      ordering_array([
        rewrite_gate(reflect_string("left"), sequence_num(2)),
        rewrite_gate(reflect_string("right"), sequence_num(1)),
      ]),
    )
    let counts : Map[String, Int32] = Map([])
    let body = sequence_local(
      [
        ("original", values),
        (
          "sorted",
          sort_demand_call(
            sequence_var("original"),
            Some(make_function(["x"], sequence_num(0))),
            true,
          ),
        ),
      ],
      ordering_array([
        sequence_call("length", [sequence_var("sorted")]),
        make_index(sequence_var("sorted"), 0),
        make_index(sequence_var("sorted"), 0),
        make_index(sequence_var("original"), 0),
        make_index(sequence_var("sorted"), 1),
      ]),
    )
    assert_eq(
      ordering_program(additive_probe_scope(body), handmade).evaluate(
        native_functions=rewrite_natives(counts),
        limits=sequence_limits(),
      ),
      Json::array([2, 2, 2, 2, 1]),
    )
    assert_eq(counts, Map([("array", 1), ("left", 1), ("right", 1)]))
  }
}
