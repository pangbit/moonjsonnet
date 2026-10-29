// Fixed std.jsonnet 1468-1530: six source-defined set transfers.
// Normal binary/member operands are sorted and unique under the same keyF.
// Literal source/handmade-AST expectations; sort/comparison/call are child premises.
// uniq/set source admission also follows the established foldl/sort judgments.

///|
fn sets_apply(
  name : String,
  args : Array[OrderingExpr],
  key : OrderingExpr?,
) -> OrderingExpr {
  let supplied = args.copy()
  if key is Some(value) {
    supplied.push(value)
  }
  sequence_call(name, supplied)
}

///|
fn sets_numbers(values : Array[Int]) -> OrderingExpr {
  ordering_array(values.map(sequence_num))
}

///|
fn sets_item(key : Int, id : String) -> OrderingExpr {
  reflect_object([
    (reflect_string("k"), 1, sequence_num(key)),
    (reflect_string("id"), 1, reflect_string(id)),
    (reflect_string("payload"), 1, ordering_error("unused-set-payload")),
  ])
}

///|
fn sets_key() -> OrderingExpr {
  make_function(["x"], additive_select(sequence_var("x"), "k"))
}

///|
fn sets_ids(value : OrderingExpr) -> OrderingExpr {
  sequence_call("map", [
    make_function(["x"], additive_select(sequence_var("x"), "id")),
    value,
  ])
}

///|
test "SC1 uniq removes only successive duplicates and set sorts identity keys" {
  for
    (input, unique, sorted) in [
      (sets_numbers([]), Json::array([]), Json::array([])),
      (sets_numbers([2]), [2], [2]),
      (sets_numbers([2, 2, 1, 1, 2, 3, 3]), [2, 1, 2, 3], [1, 2, 3]),
    ] {
    transfer_value(sets_apply("uniq", [input], None), unique)
    transfer_value(sets_apply("set", [input], None), sorted)
  }
  let strings = ordering_array([
    reflect_string("😀"),
    reflect_string("é"),
    reflect_string("é"),
    reflect_string("e\u0301"),
    reflect_string("A"),
    reflect_string("\u0000"),
  ])
  transfer_value(sets_apply("uniq", [strings], None), [
    "😀", "é", "e\u0301", "A", "\u0000",
  ])
  transfer_value(sets_apply("set", [strings], None), [
    "\u0000", "A", "e\u0301", "é", "😀",
  ])
}

///|
test "SC2 uniq and stable set retain the first representative of equal keys" {
  let input = ordering_array([
    sets_item(2, "b0"),
    sets_item(2, "b1"),
    sets_item(1, "a0"),
    sets_item(2, "b2"),
    sets_item(1, "a1"),
    sets_item(3, "c0"),
  ])
  transfer_value(sets_ids(sets_apply("uniq", [input], Some(sets_key()))), [
    "b0", "a0", "b2", "a1", "c0",
  ])
  transfer_value(sets_ids(sets_apply("set", [input], Some(sets_key()))), [
    "a0", "b0", "c0",
  ])
}

///|
test "SC3 binary set operations cover equality ordering and both exhausted sides" {
  let cases : Array[(OrderingExpr, OrderingExpr, Json, Json, Json)] = [
    (
      sets_numbers([1, 3, 5, 7]),
      sets_numbers([2, 3, 4, 7, 9]),
      [1, 2, 3, 4, 5, 7, 9],
      [3, 7],
      [1, 5],
    ),
    (sets_numbers([2, 4]), sets_numbers([1, 2]), [1, 2, 4], [2], [4]),
    (sets_numbers([]), sets_numbers([]), [], [], []),
    (sets_numbers([]), sets_numbers([2]), [2], [], []),
    (sets_numbers([2]), sets_numbers([]), [2], [], [2]),
    (sets_numbers([2]), sets_numbers([2]), [2], [2], []),
  ]
  for (a, b, union, intersection, difference) in cases {
    transfer_value(sets_apply("setUnion", [a, b], None), union)
    transfer_value(sets_apply("setInter", [a, b], None), intersection)
    transfer_value(sets_apply("setDiff", [a, b], None), difference)
  }
}

///|
test "SC4 set key identity selects left representatives and Boolean membership" {
  let a = ordering_array([
    sets_item(1, "a1"),
    sets_item(3, "a3"),
    sets_item(5, "a5"),
  ])
  let b = ordering_array([
    sets_item(2, "b2"),
    sets_item(3, "b3"),
    sets_item(4, "b4"),
  ])
  for
    (name, expected) in [
      ("setUnion", Json::array(["a1", "b2", "a3", "b4", "a5"])),
      ("setInter", ["a3"]),
      ("setDiff", ["a1", "a5"]),
    ] {
    transfer_value(
      sets_ids(sets_apply(name, [a, b], Some(sets_key()))),
      expected,
    )
  }
  transfer_value(
    sets_apply("setMember", [sets_item(3, "target"), a], Some(sets_key())),
    true,
  )
  transfer_value(
    sets_apply("setMember", [sets_item(4, "absent"), a], Some(sets_key())),
    false,
  )
  for
    (value, expected) in [
      (0, false),
      (1, true),
      (3, true),
      (4, false),
      (8, false),
    ] {
    transfer_value(
      sets_apply(
        "setMember",
        [sequence_num(value), sets_numbers([1, 3, 7])],
        None,
      ),
      Json::boolean(expected),
    )
  }
}

///|
test "SC5 empty and singleton branches skip unused key expressions and applications" {
  let empty = sets_numbers([])
  let one = ordering_array([ordering_error("unused-set-element")])
  for
    key in [
      ordering_error("unused-key-head"),
      sequence_num(7),
      make_function([], sequence_num(7)),
      make_function(["x"], ordering_error("unused-key-body")),
    ] {
    for name in ["uniq", "set"] {
      transfer_value(sets_apply(name, [empty], Some(key)), [])
      transfer_value(
        sequence_call("length", [sets_apply(name, [one], Some(key))]),
        1,
      )
    }
    for args in [[empty, one], [one, empty]] {
      transfer_value(
        sequence_call("length", [sets_apply("setUnion", args, Some(key))]),
        1,
      )
      transfer_value(sets_apply("setInter", args, Some(key)), [])
    }
    transfer_value(sets_apply("setDiff", [empty, one], Some(key)), [])
    transfer_value(
      sequence_call("length", [sets_apply("setDiff", [one, empty], Some(key))]),
      1,
    )
    transfer_value(
      sets_apply(
        "setMember",
        [ordering_error("unused-member-target"), empty],
        Some(key),
      ),
      false,
    )
  }
}

///|
test "SC6 required key applications reject invalid heads arity and isolated failures" {
  let cases : Array[(String, Array[OrderingExpr])] = [
    ("uniq", [sets_numbers([1, 2])]),
    ("set", [sets_numbers([2, 1])]),
    ("setUnion", [sets_numbers([1]), sets_numbers([2])]),
    ("setInter", [sets_numbers([1]), sets_numbers([2])]),
    ("setDiff", [sets_numbers([1]), sets_numbers([2])]),
    ("setMember", [sequence_num(1), sets_numbers([2])]),
  ]
  let invalid = [
    ordering_leaf("null", Literal(Json::null())),
    reflect_bool(false),
    sequence_num(1),
    reflect_string("key"),
    ordering_array([]),
    reflect_object([]),
    make_function([], sequence_num(7)),
    make_function(["x", "extra"], sequence_num(7)),
  ]
  let sole_body_error = make_function(
    ["x"],
    transfer_if(
      ordering_binary(sequence_var("x"), "==", sequence_num(1)),
      ordering_error("required-key-body"),
      sequence_var("x"),
    ),
  )
  for (name, args) in cases {
    for key in invalid {
      transfer_reject(sets_apply(name, args, Some(key)))
    }
    transfer_error(
      sets_apply(name, args, Some(ordering_error("required-key-head"))),
      "required-key-head",
    )
    transfer_error(
      sets_apply(name, args, Some(sole_body_error)),
      "required-key-body",
    )
  }
}

///|
test "SC7 constant keys can ignore erroneous elements while selected results stay lazy" {
  let constant = make_function(["unused"], sequence_num(0))
  let left = ordering_array([ordering_error("left-representative")])
  let right = ordering_array([ordering_error("right-discarded")])
  let two = ordering_array([
    ordering_error("left-representative"),
    ordering_error("right-discarded"),
  ])
  for name in ["uniq", "set"] {
    let result = sets_apply(name, [two], Some(constant))
    transfer_value(sequence_call("length", [result]), 1)
    transfer_error(make_index(result, 0), "left-representative")
  }
  for name in ["setUnion", "setInter"] {
    let result = sets_apply(name, [left, right], Some(constant))
    transfer_value(sequence_call("length", [result]), 1)
    transfer_error(make_index(result, 0), "left-representative")
  }
  transfer_value(sets_apply("setDiff", [left, right], Some(constant)), [])
  transfer_value(
    sets_apply(
      "setMember",
      [ordering_error("unused-target"), right],
      Some(constant),
    ),
    true,
  )
}

///|
test "SC8 set constructors require input heads including tailstrict empty cases" {
  for name in ["uniq", "set"] {
    transfer_error(
      sets_apply(name, [ordering_error("set-array-head")], None),
      "set-array-head",
    )
  }
  for name in ["setUnion", "setInter", "setDiff"] {
    transfer_error(
      sets_apply(
        name,
        [ordering_error("left-array-head"), sets_numbers([])],
        None,
      ),
      "left-array-head",
    )
    transfer_error(
      sets_apply(
        name,
        [sets_numbers([]), ordering_error("right-array-head")],
        None,
      ),
      "right-array-head",
    )
  }
  transfer_error(
    sets_apply(
      "setMember",
      [sequence_num(1), ordering_error("member-array-head")],
      None,
    ),
    "member-array-head",
  )
}

///|
test "SC9 exhausted suffixes and membership retain the fixed branch demand" {
  let key = make_function(
    ["x"],
    transfer_if(
      ordering_binary(sequence_var("x"), "==", sequence_num(9)),
      ordering_error("unused-suffix-key"),
      sequence_var("x"),
    ),
  )
  transfer_value(
    sets_apply("setUnion", [sets_numbers([1]), sets_numbers([1, 9])], Some(key)),
    [1, 9],
  )
  transfer_value(
    sets_apply("setInter", [sets_numbers([1]), sets_numbers([1, 9])], Some(key)),
    [1],
  )
  transfer_value(
    sets_apply("setDiff", [sets_numbers([1, 9]), sets_numbers([1])], Some(key)),
    [9],
  )
  let tail = ordering_array([
    sequence_num(1),
    ordering_error("unused-member-tail"),
  ])
  transfer_value(sets_apply("setMember", [sequence_num(1), tail], None), true)
  transfer_value(sets_apply("setMember", [sequence_num(0), tail], None), false)
  transfer_error(
    sets_apply(
      "setMember",
      [
        sequence_num(2),
        ordering_array([sequence_num(1), ordering_error("needed-member-tail")]),
      ],
      None,
    ),
    "needed-member-tail",
  )
  let union = sets_apply("setUnion", [sets_numbers([1]), tail], None)
  transfer_value(sequence_call("length", [union]), 2)
  transfer_value(make_index(union, 0), 1)
  transfer_error(make_index(union, 1), "unused-member-tail")
}

///|
test "SC10 six set signatures retain identity defaults named forms and aliases" {
  let identity = make_function(["x"], sequence_var("x"))
  let cases : Array[(String, Array[(String, OrderingExpr)], Json)] = [
    ("uniq", [("arr", sets_numbers([2, 2, 1]))], [2, 1]),
    ("set", [("arr", sets_numbers([2, 1, 2]))], [1, 2]),
    (
      "setUnion",
      [("a", sets_numbers([1, 3])), ("b", sets_numbers([2, 3]))],
      [1, 2, 3],
    ),
    (
      "setInter",
      [("a", sets_numbers([1, 3])), ("b", sets_numbers([2, 3]))],
      [3],
    ),
    ("setDiff", [("a", sets_numbers([1, 3])), ("b", sets_numbers([2, 3]))], [1]),
    ("setMember", [("x", sequence_num(3)), ("arr", sets_numbers([1, 3]))], true),
  ]
  for (name, required, expected) in cases {
    let function = additive_select(sequence_var("std"), name)
    transfer_value(
      sequence_call("length", [function]),
      Json::number((required.length() + 1).to_double()),
    )
    let named : Array[(String?, OrderingExpr)] = []
    for i = required.length() - 1; i >= 0; i = i - 1 {
      named.push((Some(required[i].0), required[i].1))
    }
    transfer_value(rounding_apply(name, named), expected)
    transfer_value(
      sequence_local(
        [("f", function)],
        shared_mode_call(sequence_var("f"), named),
      ),
      expected,
    )
    let explicit = named.copy()
    explicit.push((Some("keyF"), identity))
    transfer_value(rounding_apply(name, explicit), expected)
    let positional = required.map(arg => arg.1)
    transfer_value(sets_apply(name, positional, Some(identity)), expected)
    let mixed = positional.map(arg => (None, arg))
    mixed.push((Some("keyF"), identity))
    transfer_value(rounding_apply(name, mixed), expected)
    if required.length() == 2 {
      transfer_value(
        rounding_apply(name, [
          (None, required[0].1),
          (Some(required[1].0), required[1].1),
          (Some("keyF"), identity),
        ]),
        expected,
      )
    }
  }
}

///|
test "SC11 set binding rejects safe invalid calls and leaves unused calls dormant" {
  let cases : Array[(String, Array[(String, OrderingExpr)])] = [
    ("uniq", [("arr", sets_numbers([]))]),
    ("set", [("arr", sets_numbers([]))]),
    ("setUnion", [("a", sets_numbers([])), ("b", sets_numbers([]))]),
    ("setInter", [("a", sets_numbers([])), ("b", sets_numbers([]))]),
    ("setDiff", [("a", sets_numbers([])), ("b", sets_numbers([]))]),
    ("setMember", [("x", sequence_num(1)), ("arr", sets_numbers([]))]),
  ]
  let identity = make_function(["x"], sequence_var("x"))
  for (name, required) in cases {
    for missing = 0; missing < required.length(); missing = missing + 1 {
      let args : Array[(String?, OrderingExpr)] = [(Some("keyF"), identity)]
      for i = 0; i < required.length(); i = i + 1 {
        if i != missing {
          args.push((Some(required[i].0), required[i].1))
        }
      }
      transfer_reject(rounding_apply(name, args))
    }
    let named = required.map(arg => (Some(arg.0), arg.1))
    named.push((Some("unknown"), sequence_num(0)))
    transfer_reject(rounding_apply(name, named))
    let extra = required.map(arg => arg.1)
    extra.push(identity)
    extra.push(sequence_num(0))
    transfer_reject(sequence_call(name, extra))
    let mixed_duplicate : Array[(String?, OrderingExpr)] = [
      (None, required[0].1),
    ]
    for arg in required {
      mixed_duplicate.push((Some(arg.0), arg.1))
    }
    transfer_reject(rounding_apply(name, mixed_duplicate))
    let duplicate = required.map(arg => (Some(arg.0), arg.1))
    duplicate.push((Some(required[0].0), required[0].1))
    for handmade in [false, true] {
      try
        ordering_program(
          ordering_unused(rounding_apply(name, duplicate)),
          handmade,
        )
      catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
      } noraise {
        _ => fail("duplicate set names escaped static admission")
      }
    }
    let bad = required.map(arg => arg.1)
    bad[0] = ordering_error("unused-set-call")
    let call = sets_apply(name, bad, None)
    transfer_value(ordering_unused(call), 42)
    transfer_value(transfer_if(reflect_bool(false), call, sequence_num(42)), 42)
  }
}

///|
test "SC12 set operations preserve original Arrays key payloads and repeated aliases" {
  for (name, expected) in [("uniq", Json::array([2, 1, 2])), ("set", [1, 2])] {
    transfer_value(
      sequence_local(
        [
          ("a", sets_numbers([2, 2, 1, 2])),
          ("r", sets_apply(name, [sequence_var("a")], None)),
        ],
        ordering_array([
          sequence_var("a"),
          sequence_var("r"),
          sequence_var("a"),
          sequence_var("r"),
        ]),
      ),
      Json::array([[2, 2, 1, 2], expected, [2, 2, 1, 2], expected]),
    )
  }
  for
    (name, expected) in [
      ("setUnion", Json::array([1, 2, 3])),
      ("setInter", [3]),
      ("setDiff", [1]),
    ] {
    transfer_value(
      sequence_local(
        [
          ("a", sets_numbers([1, 3])),
          ("b", sets_numbers([2, 3])),
          ("r", sets_apply(name, [sequence_var("a"), sequence_var("b")], None)),
        ],
        ordering_array([
          sequence_var("a"),
          sequence_var("b"),
          sequence_var("r"),
          sequence_var("r"),
        ]),
      ),
      Json::array([[1, 3], [2, 3], expected, expected]),
    )
  }
  let retained = sets_apply(
    "set",
    [ordering_array([sets_item(2, "b"), sets_item(1, "a")])],
    Some(sets_key()),
  )
  transfer_value(sets_ids(retained), ["a", "b"])
  transfer_error(
    additive_select(make_index(retained, 0), "payload"),
    "unused-set-payload",
  )
  transfer_value(
    sequence_local(
      [
        ("x", sequence_num(3)),
        ("a", sets_numbers([1, 3])),
        (
          "r",
          sets_apply("setMember", [sequence_var("x"), sequence_var("a")], None),
        ),
      ],
      ordering_array([
        sequence_var("x"),
        sequence_var("a"),
        sequence_var("r"),
        sequence_var("r"),
      ]),
    ),
    [3, [1, 3], true, true],
  )
}

///|
test "SC13 uniq and set retain established String Object and Function source admission" {
  let strings : Array[(String, Json, Json)] = [
    ("", [], []),
    ("😀", ["😀"], ["😀"]),
    ("éé😀a", ["é", "😀", "a"], ["a", "é", "😀"]),
  ]
  for (input, unique, sorted) in strings {
    transfer_value(sets_apply("uniq", [reflect_string(input)], None), unique)
    transfer_value(sets_apply("set", [reflect_string(input)], None), sorted)
  }
  let empty_heads = [reflect_object([]), make_function([], sequence_num(7))]
  let single_heads = [
    reflect_object([(reflect_string("a"), 1, sequence_num(7))]),
    make_function(["x"], sequence_num(7)),
  ]
  let two_heads = [
    reflect_object([
      (reflect_string("a"), 1, sequence_num(7)),
      (reflect_string("b"), 1, sequence_num(8)),
    ]),
    make_function(["x", "y"], sequence_num(7)),
  ]
  let constant = make_function(["unused"], sequence_num(0))
  for name in ["uniq", "set"] {
    for input in empty_heads {
      transfer_value(
        sets_apply(name, [input], Some(ordering_error("unused-empty-key"))),
        [],
      )
    }
    for input in single_heads {
      let result = sets_apply(
        name,
        [input],
        Some(ordering_error("unused-single-key")),
      )
      transfer_value(sequence_call("length", [result]), 1)
      transfer_reject(make_index(result, 0))
    }
    for input in two_heads {
      let result = sets_apply(name, [input], Some(constant))
      transfer_value(sequence_call("length", [result]), 1)
      transfer_reject(make_index(result, 0))
      transfer_reject(
        sequence_call("length", [sets_apply(name, [input], None)]),
      )
    }
    for
      invalid in [
        ordering_leaf("null", Literal(Json::null())),
        reflect_bool(false),
        sequence_num(1),
      ] {
      transfer_reject(sets_apply(name, [invalid], None))
    }
  }
}
