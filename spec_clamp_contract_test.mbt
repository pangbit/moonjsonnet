// Pinned Jsonnet bbb38f1020be1f5aed560928fb839b2c448cefb4, std.clamp.
// Ordinary ordered numeric ranges agree with documentation and source.
// CL3 follows the explicit source branch; the documentation's numeric
// max/min equivalence is not treated as a strictness or error-order promise.
// Literal results and independent source/handmade-AST callers; no product patch.

///|
test "CL1 clamp preserves literal finite ranges endpoints and equal bounds" {
  let cases : Array[(Int32, Int32, Int32, Int32)] = [
    (-3, 0, 5, 0),
    (0, 0, 5, 0),
    (4, 0, 5, 4),
    (5, 0, 5, 5),
    (7, 0, 5, 5),
    (-9, -5, -2, -5),
    (-3, -5, -2, -3),
    (0, -5, -2, -2),
    (-1, 0, 0, 0),
    (0, 0, 0, 0),
    (1, 0, 0, 0),
  ]
  for (x, lower, upper, expected) in cases {
    transfer_value(
      sequence_call("clamp", [
        sequence_num(x),
        sequence_num(lower),
        sequence_num(upper),
      ]),
      Json::number(expected.to_double()),
    )
  }
  let quarter = ordering_leaf("0.25", Literal(Json::number(0.25)))
  let half = ordering_leaf("0.5", Literal(Json::number(0.5)))
  transfer_value(sequence_call("clamp", [quarter, sequence_num(0), half]), 0.25)
  transfer_value(sequence_call("clamp", [sequence_num(1), quarter, half]), 0.5)
  transfer_value(sequence_call("clamp", [sequence_num(0), quarter, half]), 0.25)
}

///|
test "CL2 clamp retains required public names through direct and aliased calls" {
  let function = ordering_leaf(
    "std.clamp",
    Index(sequence_var("std").tree, reflect_string("clamp").tree),
  )
  transfer_value(sequence_call("length", [function]), 3)
  let forms : Array[Array[(String?, OrderingExpr)]] = [
    [(None, sequence_num(7)), (None, sequence_num(0)), (None, sequence_num(5))],
    [
      (Some("x"), sequence_num(7)),
      (Some("minVal"), sequence_num(0)),
      (Some("maxVal"), sequence_num(5)),
    ],
    [
      (Some("maxVal"), sequence_num(5)),
      (Some("x"), sequence_num(7)),
      (Some("minVal"), sequence_num(0)),
    ],
    [
      (None, sequence_num(7)),
      (Some("maxVal"), sequence_num(5)),
      (Some("minVal"), sequence_num(0)),
    ],
  ]
  for args in forms {
    transfer_value(rounding_apply("clamp", args), 5)
    transfer_value(
      sequence_local(
        [("f", function)],
        shared_mode_call(sequence_var("f"), args),
      ),
      5,
    )
  }
  let zero = sequence_num(0)
  let invalid : Array[Array[(String?, OrderingExpr)]] = [
    [],
    [(None, zero)],
    [(None, zero), (None, zero)],
    [(None, zero), (None, zero), (None, zero), (None, zero)],
    [(Some("minVal"), zero), (Some("maxVal"), zero)],
    [(Some("x"), zero), (Some("maxVal"), zero)],
    [(Some("x"), zero), (Some("minVal"), zero)],
    [(Some("x"), zero), (Some("min"), zero), (Some("maxVal"), zero)],
    [(None, zero), (None, zero), (None, zero), (Some("unknown"), zero)],
    [
      (None, zero),
      (Some("x"), zero),
      (Some("minVal"), zero),
      (Some("maxVal"), zero),
    ],
  ]
  for args in invalid {
    transfer_reject(rounding_apply("clamp", args))
    transfer_reject(
      sequence_local(
        [("f", function)],
        shared_mode_call(sequence_var("f"), args),
      ),
    )
  }
}

///|
test "CL3 clamp source lower branch skips the upper argument and other paths demand it" {
  let unread = ordering_error("clamp-unused-upper")
  let upper_values = [
    unread,
    ordering_leaf("null", Literal(Json::null())),
    reflect_bool(false),
    reflect_string("not a numeric upper bound"),
    ordering_array([unread]),
    reflect_object([(reflect_string("payload"), 1, unread)]),
    value_head_function(unread, unread),
  ]
  for upper in upper_values {
    let call = sequence_call("clamp", [sequence_num(-1), sequence_num(0), upper])
    transfer_value(call, 0)
    transfer_value(sequence_call("type", [call]), "number")
    transfer_value(
      rounding_apply("clamp", [
        (Some("maxVal"), upper),
        (Some("minVal"), sequence_num(0)),
        (Some("x"), sequence_num(-1)),
      ]),
      0,
    )
  }
  let needed = ordering_error("clamp-required-argument")
  for
    args in [
      [needed, sequence_num(0), sequence_num(5)],
      [sequence_num(1), needed, sequence_num(5)],
      [sequence_num(0), sequence_num(0), needed],
      [sequence_num(1), sequence_num(0), needed],
    ] {
    let call = sequence_call("clamp", args)
    transfer_reject(call)
    transfer_reject(sequence_call("type", [call]))
  }
}

///|
test "CL4 clamp rejects demanded mixed heads while unused calls and aliases remain safe" {
  let unread = ordering_error("clamp-unread-payload")
  let invalid = [
    ordering_leaf("null", Literal(Json::null())),
    reflect_bool(false),
    reflect_bool(true),
    reflect_string(""),
    ordering_array([unread]),
    reflect_object([(reflect_string("payload"), 1, unread)]),
    value_head_function(unread, unread),
  ]
  for value in invalid {
    // Each demanded comparison pairs this head with a Number. Rejection
    // establishes neither a payload-forcing order nor a diagnostic winner.
    for
      args in [
        [value, sequence_num(0), sequence_num(5)],
        [sequence_num(1), value, sequence_num(5)],
        [sequence_num(1), sequence_num(0), value],
      ] {
      let call = sequence_call("clamp", args)
      transfer_reject(call)
      transfer_value(ordering_unused(call), 42)
    }
  }
  let unused = sequence_call("clamp", [unread, unread, unread])
  transfer_value(ordering_unused(unused), 42)
  transfer_value(transfer_if(reflect_bool(false), unused, sequence_num(9)), 9)
  transfer_value(ordering_binary(reflect_bool(false), "&&", unused), false)
  transfer_value(ordering_binary(reflect_bool(true), "||", unused), true)
  transfer_value(
    sequence_local(
      [("original", sequence_num(7)), ("alias", sequence_var("original"))],
      ordering_array([
        sequence_call("clamp", [
          sequence_var("alias"),
          sequence_num(0),
          sequence_num(5),
        ]),
        sequence_call("clamp", [
          sequence_var("alias"),
          sequence_num(0),
          sequence_num(9),
        ]),
        sequence_var("original"),
        sequence_var("alias"),
      ]),
    ),
    [5, 7, 7, 7],
  )
}
