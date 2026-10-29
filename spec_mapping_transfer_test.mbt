// Fixed Jsonnet v0.21.0: std.jsonnet 281-287 and 832-840.
// Literal constructor-transfer oracles, evaluated as source and handmade AST.
// filterMap assumes Boolean predicates; nonboolean membership remains unadjudicated.

///|
fn transfer_limits() -> @moonjsonnet.Limits {
  { ..@moonjsonnet.Limits::default(), steps: 50000, }
}

///|
fn transfer_value(call : OrderingExpr, expected : Json) -> Unit raise {
  for handmade in [false, true] {
    assert_eq(
      ordering_program(call, handmade).evaluate(limits=transfer_limits()),
      expected,
    )
  }
}

///|
fn transfer_reject(call : OrderingExpr) -> Unit raise {
  for handmade in [false, true] {
    try
      ordering_program(call, handmade).evaluate(limits=transfer_limits())
    catch {
      @moonjsonnet.Error(_) => ()
    } noraise {
      _ => fail("mapping constructor accepted invalid input")
    }
  }
}

///|
fn transfer_error(call : OrderingExpr, marker : String) -> Unit raise {
  transfer_value(ordering_unused(call), 42)
  for handmade in [false, true] {
    try
      ordering_program(call, handmade).evaluate(limits=transfer_limits())
    catch {
      @moonjsonnet.Error(d) => {
        // Extra embedding diagnostics, separate from required language failure.
        assert_eq(d.kind, @moonjsonnet.Runtime)
        assert_eq(d.message, marker)
      }
    } noraise {
      _ => fail("mapping constructor suppressed its sole required error")
    }
  }
}

///|
fn transfer_index(func : OrderingExpr, arr : OrderingExpr) -> OrderingExpr {
  sequence_call("mapWithIndex", [func, arr])
}

///|
fn transfer_filter(
  predicate : OrderingExpr,
  mapper : OrderingExpr,
  arr : OrderingExpr,
) -> OrderingExpr {
  sequence_call("filterMap", [predicate, mapper, arr])
}

///|
fn transfer_if(
  condition : OrderingExpr,
  yes : OrderingExpr,
  no : OrderingExpr,
) -> OrderingExpr {
  {
    source: "if (" +
    condition.source +
    ") then (" +
    yes.source +
    ") else (" +
    no.source +
    ")",
    tree: ordering_ast(If(condition.tree, yes.tree, no.tree)),
  }
}

///|
test "MT1 mapWithIndex transfers array positions and String codepoints into an Array" {
  let pair = make_function(
    ["i", "x"],
    ordering_array([sequence_var("i"), sequence_var("x")]),
  )
  transfer_value(
    transfer_index(
      pair,
      ordering_array([
        reflect_string("b"),
        reflect_string("a"),
        reflect_string("b"),
      ]),
    ),
    [[0, "b"], [1, "a"], [2, "b"]],
  )
  transfer_value(transfer_index(pair, reflect_string("A\u0000e\u0301😀")), [
    [0, "A"],
    [1, "\u0000"],
    [2, "e"],
    [3, "\u0301"],
    [4, "😀"],
  ])
  // A callback result can itself be a Function; selection does not manifest it.
  let returns_function = make_function(
    ["i", "x"],
    make_function(
      ["y"],
      ordering_binary(sequence_var("x"), "+", sequence_var("y")),
    ),
  )
  transfer_value(
    shared_mode_call(
      make_index(
        transfer_index(returns_function, ordering_array([sequence_num(4)])),
        0,
      ),
      [(None, sequence_num(3))],
    ),
    7,
  )
}

///|
test "MT2 filterMap transfers Boolean membership before key only projection" {
  let x = sequence_var("x")
  let predicate = make_function(["x"], filter_field(x, "keep"))
  let input = ordering_array([
    filter_record(reflect_bool(true), sequence_num(20)),
    filter_record(reflect_bool(false), sequence_num(10)),
    filter_record(reflect_bool(true), sequence_num(20)),
  ])
  let mapper = make_function(
    ["x"],
    transfer_if(
      filter_field(x, "keep"),
      filter_field(x, "value"),
      ordering_error("excluded-mapper"),
    ),
  )
  transfer_value(transfer_filter(predicate, mapper, input), [20, 20])
  transfer_value(
    transfer_filter(
      make_function(["x"], reflect_bool(false)),
      make_function(["x"], ordering_error("all-excluded-mapper")),
      ordering_array([ordering_error("ignored-element")]),
    ),
    [],
  )
}

///|
test "MT3 mapping constructors bind required names positional calls and aliases" {
  let pair = make_function(
    ["i", "x"],
    ordering_array([sequence_var("i"), sequence_var("x")]),
  )
  let yes = make_function(["x"], reflect_bool(true))
  let identity = make_function(["x"], sequence_var("x"))
  let input = ordering_array([sequence_num(4), sequence_num(5)])
  let cases : Array[(String, Array[(String?, OrderingExpr)], Json, Int)] = [
    (
      "mapWithIndex",
      [(Some("arr"), input), (Some("func"), pair)],
      [[0, 4], [1, 5]],
      2,
    ),
    (
      "filterMap",
      [
        (Some("arr"), input),
        (Some("map_func"), identity),
        (Some("filter_func"), yes),
      ],
      [4, 5],
      3,
    ),
  ]
  for (name, args, expected, arity) in cases {
    let function = filter_field(sequence_var("std"), name)
    transfer_value(rounding_apply(name, args), expected)
    transfer_value(
      sequence_local(
        [("f", function)],
        shared_mode_call(sequence_var("f"), args),
      ),
      expected,
    )
    transfer_value(
      sequence_call("length", [function]),
      Json::number(arity.to_double()),
    )
    transfer_reject(sequence_call(name, []))
    // Missing each named parameter witnesses the absence of defaults.
    for missing = 0; missing < args.length(); missing = missing + 1 {
      let supplied : Array[(String?, OrderingExpr)] = []
      for index = 0; index < args.length(); index = index + 1 {
        if index != missing {
          supplied.push(args[index])
        }
      }
      transfer_reject(rounding_apply(name, supplied))
    }
    let unknown = args.copy()
    unknown.push((Some("unknown"), sequence_num(1)))
    transfer_reject(rounding_apply(name, unknown))
  }
  transfer_reject(sequence_call("mapWithIndex", [pair, input, sequence_num(1)]))
  transfer_reject(
    sequence_call("filterMap", [yes, identity, input, sequence_num(1)]),
  )
}

///|
test "MT4 mapping constructor guards reject every wrong outer value kind" {
  let null = ordering_leaf("null", Literal(Json::null()))
  let yes = make_function(["x"], reflect_bool(true))
  let identity = make_function(["x"], sequence_var("x"))
  let indexed = make_function(["i", "x"], sequence_var("x"))
  let empty = ordering_array([])
  for
    invalid in [
      null,
      reflect_bool(false),
      sequence_num(1),
      reflect_string("x"),
      empty,
      reflect_object([]),
    ] {
    transfer_reject(transfer_index(invalid, empty))
    transfer_reject(transfer_filter(invalid, identity, empty))
    transfer_reject(transfer_filter(yes, invalid, empty))
  }
  for
    invalid in [
      null,
      reflect_bool(false),
      sequence_num(1),
      reflect_object([]),
      make_function([], sequence_num(1)),
    ] {
    transfer_reject(transfer_index(indexed, invalid))
    transfer_reject(transfer_filter(yes, identity, invalid))
  }
  transfer_reject(transfer_filter(yes, identity, reflect_string("abc")))
}

///|
test "MT5 empty constructors defer callback arity until membership or output needs it" {
  for params in [[], ["x"], ["i", "x", "extra"]] {
    let wrong_arity = make_function(params, sequence_num(7))
    for empty in [ordering_array([]), reflect_string("")] {
      transfer_value(transfer_index(wrong_arity, empty), [])
    }
    for input in [ordering_array([sequence_num(7)]), reflect_string("😀")] {
      let result = transfer_index(wrong_arity, input)
      transfer_value(sequence_call("length", [result]), 1)
      transfer_reject(make_index(result, 0))
    }
  }
  let yes = make_function(["x"], reflect_bool(true))
  let no = make_function(["x"], reflect_bool(false))
  let identity = make_function(["x"], sequence_var("x"))
  let one = ordering_array([sequence_num(7)])
  for params in [[], ["x", "extra"]] {
    let wrong_arity = make_function(params, reflect_bool(true))
    transfer_value(
      transfer_filter(wrong_arity, wrong_arity, ordering_array([])),
      [],
    )
    transfer_reject(
      sequence_call("length", [transfer_filter(wrong_arity, identity, one)]),
    )
    transfer_value(transfer_filter(no, wrong_arity, one), [])
    let result = transfer_filter(yes, wrong_arity, one)
    transfer_value(sequence_call("length", [result]), 1)
    transfer_reject(make_index(result, 0))
  }
}

///|
test "MT6 mapWithIndex length index only callbacks and selected results retain laziness" {
  let input = ordering_array([
    ordering_error("mapped-payload"),
    sequence_num(7),
    sequence_num(8),
  ])
  transfer_value(
    transfer_index(make_function(["i", "x"], sequence_var("i")), input),
    [0, 1, 2],
  )
  let result = transfer_index(
    make_function(["i", "x"], sequence_var("x")),
    input,
  )
  transfer_value(sequence_call("length", [result]), 3)
  transfer_value(make_index(result, 1), 7)
  transfer_error(make_index(result, 0), "mapped-payload")
  transfer_value(
    sequence_call("length", [
      transfer_index(
        make_function(["i", "x"], ordering_error("unused-index-map")),
        input,
      ),
    ]),
    3,
  )
}

///|
test "MT7 filterMap needs all Boolean memberships but only demanded mapped values" {
  let x = sequence_var("x")
  let predicate = make_function(["x"], filter_field(x, "keep"))
  let late_membership = transfer_filter(
    predicate,
    make_function(["x"], sequence_num(42)),
    ordering_array([
      filter_record(reflect_bool(true), sequence_num(20)),
      filter_record(ordering_error("late-membership"), sequence_num(30)),
    ]),
  )
  // These witness required membership, not an exact callback order or count.
  transfer_error(sequence_call("length", [late_membership]), "late-membership")
  transfer_error(make_index(late_membership, 0), "late-membership")
  let selected = transfer_filter(
    predicate,
    make_function(
      ["x"],
      transfer_if(
        ordering_binary(filter_field(x, "value"), "==", sequence_num(20)),
        reflect_string("safe"),
        ordering_error("late-map"),
      ),
    ),
    ordering_array([
      filter_record(reflect_bool(true), sequence_num(20)),
      filter_record(reflect_bool(true), sequence_num(30)),
    ]),
  )
  transfer_value(sequence_call("length", [selected]), 2)
  transfer_value(make_index(selected, 0), "safe")
  transfer_error(make_index(selected, 1), "late-map")
}

///|
test "MT8 mapping constructors propagate isolated required outer and callback errors" {
  let empty = ordering_array([])
  let yes = make_function(["x"], reflect_bool(true))
  let identity = make_function(["x"], sequence_var("x"))
  let indexed = make_function(["i", "x"], sequence_var("x"))
  for
    (call, marker) in [
      (transfer_index(ordering_error("index-func"), empty), "index-func"),
      (transfer_index(indexed, ordering_error("index-array")), "index-array"),
      (
        transfer_filter(ordering_error("filter-func"), identity, empty),
        "filter-func",
      ),
      (transfer_filter(yes, ordering_error("map-func"), empty), "map-func"),
      (
        transfer_filter(yes, identity, ordering_error("filter-array")),
        "filter-array",
      ),
      (
        make_index(
          transfer_index(
            make_function(["i", "x"], ordering_error("index-callback")),
            ordering_array([sequence_num(1)]),
          ),
          0,
        ),
        "index-callback",
      ),
    ] {
    transfer_error(call, marker)
  }
}

///|
test "MT9 unused mapping calls remain lazy under locals branches and short circuits" {
  let empty = ordering_array([])
  let yes = make_function(["x"], reflect_bool(true))
  let identity = make_function(["x"], sequence_var("x"))
  let indexed = make_function(["i", "x"], sequence_var("x"))
  for
    call in [
      transfer_index(ordering_error("unused-index-func"), empty),
      transfer_index(indexed, ordering_error("unused-index-array")),
      transfer_filter(ordering_error("unused-filter-func"), identity, empty),
      transfer_filter(yes, ordering_error("unused-map-func"), empty),
      transfer_filter(yes, identity, ordering_error("unused-filter-array")),
    ] {
    transfer_value(ordering_unused(call), 42)
    transfer_value(transfer_if(reflect_bool(false), call, sequence_num(42)), 42)
    transfer_value(ordering_binary(reflect_bool(false), "&&", call), false)
    transfer_value(ordering_binary(reflect_bool(true), "||", call), true)
  }
}

///|
test "MT10 mapping constructors preserve original Array String and repeated result aliases" {
  let indexed = make_function(["i", "x"], sequence_var("i"))
  let pair = make_function(
    ["i", "x"],
    ordering_array([sequence_var("i"), sequence_var("x")]),
  )
  transfer_value(
    sequence_local(
      [
        ("a", ordering_array([sequence_num(10), sequence_num(20)])),
        ("s", reflect_string("e\u0301😀")),
        ("b", transfer_index(indexed, sequence_var("a"))),
        ("t", transfer_index(pair, sequence_var("s"))),
      ],
      ordering_array([
        sequence_var("a"),
        sequence_var("b"),
        sequence_var("a"),
        sequence_var("s"),
        sequence_var("t"),
        sequence_var("s"),
      ]),
    ),
    [
      [10, 20],
      [0, 1],
      [10, 20],
      "e\u0301😀",
      [[0, "e"], [1, "\u0301"], [2, "😀"]],
      "e\u0301😀",
    ],
  )
  let x = sequence_var("x")
  transfer_value(
    sequence_local(
      [
        (
          "a",
          ordering_array([sequence_num(2), sequence_num(1), sequence_num(2)]),
        ),
        (
          "b",
          transfer_filter(
            make_function(["x"], ordering_binary(x, "==", sequence_num(2))),
            make_function(["x"], ordering_binary(x, "+", sequence_num(10))),
            sequence_var("a"),
          ),
        ),
      ],
      ordering_array([
        sequence_var("a"),
        sequence_var("b"),
        sequence_var("a"),
        sequence_var("b"),
      ]),
    ),
    [[2, 1, 2], [12, 12], [2, 1, 2], [12, 12]],
  )
}
