// Fixed Jsonnet v0.21.0 std.jsonnet: repeat 198-203, count 254, find 1655-1660.
// Literal constructor/search-transfer expectations, source and handmade AST.
// Neutral transfer_* evaluation helpers add separate Runtime-marker checks.
// makeArray/join/concatenation and ==/filter judgments are explicit children.

///|
fn repeat_search_call(
  name : String,
  array : OrderingExpr,
  target : OrderingExpr,
) -> OrderingExpr {
  if name == "count" {
    sequence_call(name, [array, target])
  } else {
    sequence_call(name, [target, array])
  }
}

///|
test "RS1 repeat retains literal String Array cardinalities and Unicode data" {
  let cases : Array[(OrderingExpr, Int32, Json)] = [
    (reflect_string("blah"), 2, "blahblah"),
    (reflect_string("A\u0000e\u0301😀"), 0, ""),
    (reflect_string("A\u0000e\u0301😀"), 1, "A\u0000e\u0301😀"),
    (
      reflect_string("A\u0000e\u0301😀"),
      2,
      "A\u0000e\u0301😀A\u0000e\u0301😀",
    ),
    (reflect_string(""), 3, ""),
    (ordering_array([]), 3, []),
    (ordering_array([sequence_num(3), sequence_num(1)]), 0, []),
    (ordering_array([sequence_num(3), sequence_num(1)]), 1, [3, 1]),
    (ordering_array([sequence_num(3), sequence_num(1)]), 3, [3, 1, 3, 1, 3, 1]),
  ]
  for (what, count, expected) in cases {
    transfer_value(
      sequence_call("repeat", [what, sequence_num(count)]),
      expected,
    )
  }
  let negative_zero = ordering_leaf("-0", Unary("-", sequence_num(0).tree))
  transfer_value(
    sequence_call("repeat", [reflect_string("x"), negative_zero]),
    "",
  )
  transfer_value(
    sequence_call("repeat", [ordering_array([sequence_num(1)]), negative_zero]),
    [],
  )
}

///|
test "RS2 repeat keeps Array payloads lazy through empty length and selection" {
  let input = ordering_array([ordering_error("repeat-payload"), sequence_num(8)])
  transfer_value(sequence_call("repeat", [input, sequence_num(0)]), [])
  let repeated = sequence_call("repeat", [input, sequence_num(2)])
  transfer_value(sequence_call("length", [repeated]), 4)
  transfer_value(make_index(repeated, 1), 8)
  transfer_value(make_index(repeated, 3), 8)
  transfer_error(make_index(repeated, 0), "repeat-payload")
  let function = make_function(
    ["x"],
    ordering_binary(sequence_var("x"), "+", sequence_num(2)),
  )
  transfer_value(
    shared_mode_call(
      make_index(
        sequence_call("repeat", [ordering_array([function]), sequence_num(2)]),
        1,
      ),
      [(None, sequence_num(5))],
    ),
    7,
  )
}

///|
test "RS3 count and find transfer all equality matches and zero based positions" {
  let null = ordering_leaf("null", Literal(Json::null()))
  let mixed = ordering_array([
    null,
    reflect_bool(false),
    sequence_num(1),
    reflect_string("1"),
    null,
    reflect_bool(false),
  ])
  let cases : Array[(OrderingExpr, OrderingExpr, Json, Json)] = [
    (mixed, null, 2, [0, 4]),
    (mixed, reflect_bool(false), 2, [1, 5]),
    (mixed, sequence_num(1), 1, [2]),
    (mixed, reflect_string("1"), 1, [3]),
    (mixed, reflect_bool(true), 0, []),
    (
      ordering_array([sequence_num(4), sequence_num(4), sequence_num(4)]),
      sequence_num(4),
      3,
      [0, 1, 2],
    ),
    (
      ordering_array([
        reflect_string("😀"),
        reflect_string("e\u0301"),
        reflect_string("😀"),
      ]),
      reflect_string("😀"),
      2,
      [0, 2],
    ),
    (
      ordering_array([
        ordering_array([sequence_num(2)]),
        ordering_array([sequence_num(1)]),
        ordering_array([sequence_num(2)]),
      ]),
      ordering_array([sequence_num(2)]),
      2,
      [0, 2],
    ),
  ]
  for (array, target, count, indices) in cases {
    transfer_value(repeat_search_call("count", array, target), count)
    transfer_value(repeat_search_call("find", array, target), indices)
  }
}

///|
test "RS4 repeat count and find preserve required names no defaults and function aliases" {
  let input = ordering_array([sequence_num(2), sequence_num(1), sequence_num(2)])
  let cases : Array[(String, Array[(String?, OrderingExpr)], Json)] = [
    (
      "repeat",
      [(Some("count"), sequence_num(2)), (Some("what"), reflect_string("ab"))],
      "abab",
    ),
    ("count", [(Some("x"), sequence_num(2)), (Some("arr"), input)], 2),
    ("find", [(Some("arr"), input), (Some("value"), sequence_num(2))], [0, 2]),
  ]
  for (name, args, expected) in cases {
    let function = filter_field(sequence_var("std"), name)
    transfer_value(rounding_apply(name, args), expected)
    transfer_value(
      sequence_local(
        [("f", function)],
        shared_mode_call(sequence_var("f"), args),
      ),
      expected,
    )
    transfer_value(sequence_call("length", [function]), 2)
    transfer_reject(sequence_call(name, []))
    transfer_reject(rounding_apply(name, [args[0]]))
    transfer_reject(rounding_apply(name, [args[1]]))
    let unknown = args.copy()
    unknown.push((Some("unknown"), sequence_num(0)))
    transfer_reject(rounding_apply(name, unknown))
  }
  transfer_reject(
    sequence_call("repeat", [
      reflect_string("x"),
      sequence_num(1),
      sequence_num(0),
    ]),
  )
  transfer_reject(
    sequence_call("count", [input, sequence_num(2), sequence_num(0)]),
  )
  transfer_reject(
    sequence_call("find", [sequence_num(2), input, sequence_num(0)]),
  )
}

///|
test "RS5 repeat and search constructors retain their complete outer guards" {
  let null = ordering_leaf("null", Literal(Json::null()))
  let function = make_function([], sequence_num(7))
  for
    invalid in [
      null,
      reflect_bool(false),
      sequence_num(1),
      reflect_object([]),
      function,
    ] {
    for count in [0, 1] {
      transfer_reject(sequence_call("repeat", [invalid, sequence_num(count)]))
    }
  }
  let invalid_counts = [
    null,
    reflect_bool(false),
    reflect_string("2"),
    ordering_array([]),
    reflect_object([]),
    function,
    sequence_num(-1),
    token_number("1.5"),
  ]
  for invalid in invalid_counts {
    for
      what in [
        reflect_string(""),
        ordering_array([]),
        reflect_string("x"),
        ordering_array([sequence_num(1)]),
      ] {
      transfer_reject(sequence_call("repeat", [what, invalid]))
    }
  }
  for name in ["count", "find"] {
    for
      invalid in [
        null,
        reflect_bool(false),
        sequence_num(1),
        reflect_string(""),
        reflect_object([]),
        function,
      ] {
      transfer_reject(repeat_search_call(name, invalid, sequence_num(1)))
    }
  }
}

///|
test "RS6 empty count and find never require the target value" {
  let unused_function = make_function([], ordering_error("unused-target-body"))
  for
    target in [
      ordering_error("unused-target"),
      unused_function,
      ordering_array([ordering_error("unused-target-field")]),
    ] {
    transfer_value(repeat_search_call("count", ordering_array([]), target), 0)
    transfer_value(repeat_search_call("find", ordering_array([]), target), [])
  }
  for name in ["count", "find"] {
    transfer_error(
      repeat_search_call(name, ordering_error("search-array"), sequence_num(1)),
      "search-array",
    )
    transfer_error(
      repeat_search_call(
        name,
        ordering_array([sequence_num(1)]),
        ordering_error("search-target"),
      ),
      "search-target",
    )
  }
}

///|
test "RS7 count and find require later comparisons even after an earlier match" {
  for name in ["count", "find"] {
    let late_element = repeat_search_call(
      name,
      ordering_array([sequence_num(1), ordering_error("search-tail")]),
      sequence_num(1),
    )
    transfer_error(late_element, "search-tail")
    transfer_error(sequence_call("type", [late_element]), "search-tail")
    // The equality child needs the nested member; an error is not a false match.
    let comparison = repeat_search_call(
      name,
      ordering_array([ordering_array([ordering_error("search-equality")])]),
      ordering_array([sequence_num(1)]),
    )
    transfer_error(comparison, "search-equality")
  }
  let indices = repeat_search_call(
    "find",
    ordering_array([sequence_num(1), ordering_error("find-tail")]),
    sequence_num(1),
  )
  transfer_error(sequence_call("length", [indices]), "find-tail")
  transfer_error(make_index(indices, 0), "find-tail")
}

///|
test "RS8 repeat requires its heads while unused repeat and search calls stay lazy" {
  transfer_error(
    sequence_call("repeat", [ordering_error("repeat-what"), sequence_num(0)]),
    "repeat-what",
  )
  transfer_error(
    sequence_call("repeat", [reflect_string(""), ordering_error("repeat-count")]),
    "repeat-count",
  )
  let calls = [
    sequence_call("repeat", [
      ordering_error("unused-repeat-what"),
      sequence_num(1),
    ]),
    sequence_call("repeat", [
      reflect_string("x"),
      ordering_error("unused-repeat-count"),
    ]),
    sequence_call("repeat", [reflect_string("x"), sequence_num(-1)]),
    repeat_search_call(
      "count",
      ordering_error("unused-count-array"),
      sequence_num(1),
    ),
    repeat_search_call(
      "count",
      ordering_array([sequence_num(1)]),
      ordering_error("unused-count-target"),
    ),
    repeat_search_call(
      "find",
      ordering_error("unused-find-array"),
      sequence_num(1),
    ),
    repeat_search_call(
      "find",
      ordering_array([sequence_num(1)]),
      ordering_error("unused-find-target"),
    ),
  ]
  for call in calls {
    transfer_value(ordering_unused(call), 42)
    transfer_value(transfer_if(reflect_bool(false), call, sequence_num(42)), 42)
    transfer_value(ordering_binary(reflect_bool(false), "&&", call), false)
    transfer_value(ordering_binary(reflect_bool(true), "||", call), true)
  }
}

///|
test "RS9 repeat count and find preserve original values and repeated result aliases" {
  transfer_value(
    sequence_local(
      [
        ("a", ordering_array([sequence_num(3), sequence_num(1)])),
        ("s", reflect_string("e\u0301😀")),
        ("b", sequence_call("repeat", [sequence_var("a"), sequence_num(2)])),
        ("t", sequence_call("repeat", [sequence_var("s"), sequence_num(2)])),
      ],
      ordering_array([
        sequence_var("a"),
        sequence_var("b"),
        sequence_var("a"),
        sequence_var("b"),
        sequence_var("s"),
        sequence_var("t"),
        sequence_var("s"),
      ]),
    ),
    [
      [3, 1],
      [3, 1, 3, 1],
      [3, 1],
      [3, 1, 3, 1],
      "e\u0301😀",
      "e\u0301😀e\u0301😀",
      "e\u0301😀",
    ],
  )
  transfer_value(
    sequence_local(
      [
        (
          "a",
          ordering_array([sequence_num(2), sequence_num(1), sequence_num(2)]),
        ),
        ("x", sequence_num(2)),
        ("n", repeat_search_call("count", sequence_var("a"), sequence_var("x"))),
        (
          "indices",
          repeat_search_call("find", sequence_var("a"), sequence_var("x")),
        ),
      ],
      ordering_array([
        sequence_var("a"),
        sequence_var("x"),
        sequence_var("n"),
        sequence_var("indices"),
        sequence_var("a"),
        sequence_var("x"),
        sequence_var("n"),
        sequence_var("indices"),
      ]),
    ),
    [[2, 1, 2], 2, 2, [0, 2], [2, 1, 2], 2, 2, [0, 2]],
  )
}
