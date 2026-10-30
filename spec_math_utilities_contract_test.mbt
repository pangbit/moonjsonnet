// Pinned Jsonnet bbb38f1020be1f5aed560928fb839b2c448cefb4.
// Public math signatures and IEEE mathematical functions; no source-body alias.
// Exact ordinary dyadics and broad tangent intervals, not an all-input ULP claim.
// No Array+Array, object assertions, inherited receivers or reference execution.

///|
test "MU1 hypot preserves ordinary positional lengths and sign symmetry" {
  let cases : Array[(Int32, Int32, Int32)] = [
    (0, 0, 0),
    (3, 0, 3),
    (0, -4, 4),
    (3, 4, 5),
    (-3, 4, 5),
    (3, -4, 5),
    (-3, -4, 5),
    (5, 12, 13),
  ]
  string_utilities_values(
    cases.map(c => {
      (
        sequence_call("hypot", [sequence_num(c.0), sequence_num(c.1)]),
        Json::number(c.2.to_double()),
      )
    }),
  )
}

///|
test "MU2 hypot uses documented a b names through direct and aliased calls" {
  let function = additive_select(sequence_var("std"), "hypot")
  let forms : Array[Array[(String?, OrderingExpr)]] = [
    [(Some("a"), sequence_num(3)), (Some("b"), sequence_num(4))],
    [(Some("b"), sequence_num(4)), (Some("a"), sequence_num(3))],
    [(None, sequence_num(3)), (Some("b"), sequence_num(4))],
  ]
  let cases : Array[(OrderingExpr, Json)] = []
  for args in forms {
    cases.push((rounding_apply("hypot", args), Json::number(5)))
    cases.push(
      (
        sequence_local(
          [("f", function)],
          shared_mode_call(sequence_var("f"), args),
        ),
        Json::number(5),
      ),
    )
  }
  // Collect all six calls through both entries before reporting binding failures.
  string_utilities_values(cases)
}

///|
test "MU3 mantissa and exponent decompose ordinary nonzero binary fractions" {
  // The pair is the normalized signed fraction m and exponent e in x=m*2^e.
  // Zero spelling and all-value accuracy are not inferred from these witnesses.
  let cases : Array[(String, Double, Double, Int32)] = [
    ("1", 1.0, 0.5, 1),
    ("2", 2.0, 0.5, 2),
    ("3", 3.0, 0.75, 2),
    ("8", 8.0, 0.5, 4),
    ("-0.25", -0.25, -0.5, -1),
    ("0.75", 0.75, 0.75, 0),
    ("-6", -6.0, -0.75, 3),
    ("1024", 1024.0, 0.5, 11),
  ]
  let expected : Array[(OrderingExpr, Json)] = []
  for (source, input, fraction, exponent) in cases {
    let value = comparison_number(source, input)
    expected.push((sequence_call("mantissa", [value]), Json::number(fraction)))
    expected.push(
      (sequence_call("exponent", [value]), Json::number(exponent.to_double())),
    )
  }
  string_utilities_values(expected)
}

///|
test "MU4 tan retains zero and independent ordinary radian bounds" {
  transfer_value(sequence_call("tan", [sequence_num(0)]), 0)
  // Alternating sine/cosine series on |x|<=1 give these deliberately wide bounds.
  // Host comparison avoids depending on the printed Jsonnet greater-than rule.
  inverse_trig_intervals([
    (sequence_call("tan", [comparison_number("0.5", 0.5)]), 0.54, 0.55),
    (sequence_call("tan", [comparison_number("-0.5", -0.5)]), -0.55, -0.54),
    (sequence_call("tan", [sequence_num(1)]), 1.55, 1.56),
    (sequence_call("tan", [sequence_num(-1)]), -1.56, -1.55),
  ])
}

///|
test "MU5 math utility names arities and invalid bindings follow ordinary calls" {
  for
    (name, input, expected) in [
      ("mantissa", 8, Json::number(0.5)),
      ("exponent", 8, Json::number(4)),
      ("tan", 0, Json::number(0)),
    ] {
    let function = additive_select(sequence_var("std"), name)
    transfer_value(sequence_call("length", [function]), 1)
    for label in [None, Some("x")] {
      transfer_value(
        rounding_apply(name, [(label, sequence_num(input))]),
        expected,
      )
      transfer_value(
        sequence_local(
          [("f", function)],
          shared_mode_call(sequence_var("f"), [(label, sequence_num(input))]),
        ),
        expected,
      )
    }
    let safe = sequence_num(input)
    let invalid : Array[Array[(String?, OrderingExpr)]] = [
      [],
      [(None, safe), (None, safe)],
      [(Some("unknown"), safe)],
      [(None, safe), (Some("x"), safe)],
    ]
    for args in invalid {
      transfer_reject(rounding_apply(name, args))
    }
  }
  let safe = sequence_num(3)
  transfer_value(
    sequence_call("length", [additive_select(sequence_var("std"), "hypot")]),
    2,
  )
  let invalid : Array[Array[(String?, OrderingExpr)]] = [
    [],
    [(None, safe)],
    [(None, safe), (None, safe), (None, safe)],
    [(Some("unknown"), safe), (None, safe)],
    [(None, safe), (Some("a"), safe), (Some("b"), safe)],
  ]
  for args in invalid {
    transfer_reject(rounding_apply("hypot", args))
  }
  for
    (name, label) in [
      ("hypot", "a"),
      ("mantissa", "x"),
      ("exponent", "x"),
      ("tan", "x"),
    ] {
    let duplicate = rounding_apply(name, [
      (Some(label), safe),
      (Some(label), safe),
    ])
    for handmade in [false, true] {
      try ordering_program(ordering_unused(duplicate), handmade) catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
      } noraise {
        _ => fail("duplicate math utility names escaped static admission")
      }
    }
  }
}

///|
test "MU6 math utilities reject nonnumber heads and isolated required errors" {
  let unread = ordering_error("math-utilities-required")
  let wrong = [
    ordering_leaf("null", Literal(Json::null())),
    reflect_bool(true),
    reflect_bool(false),
    reflect_string("1"),
    ordering_array([unread]),
    reflect_object([(reflect_string("x"), 1, unread)]),
    value_head_function(unread, unread),
  ]
  for input in wrong {
    for name in ["mantissa", "exponent", "tan"] {
      transfer_reject(sequence_call(name, [input]))
    }
    transfer_reject(sequence_call("hypot", [input, sequence_num(4)]))
    transfer_reject(sequence_call("hypot", [sequence_num(3), input]))
  }
  let overflow = ordering_binary(
    comparison_number("1e308", 1.0e308),
    "+",
    comparison_number("1e308", 1.0e308),
  )
  for input in [unread, overflow] {
    let calls = [
      sequence_call("mantissa", [input]),
      sequence_call("exponent", [input]),
      sequence_call("tan", [input]),
      sequence_call("hypot", [input, sequence_num(0)]),
      sequence_call("hypot", [sequence_num(0), input]),
    ]
    for call in calls {
      transfer_reject(call)
      transfer_reject(sequence_call("type", [call]))
    }
  }
  // Failure classification/text and competing-error precedence are not prescribed.
}

///|
test "MU7 hypot avoids needless square overflow but rejects nonfinite results" {
  let huge = comparison_number("1e308", 1.0e308)
  string_utilities_values([
    (sequence_call("hypot", [huge, sequence_num(0)]), Json::number(1.0e308)),
    (sequence_call("hypot", [sequence_num(0), huge]), Json::number(1.0e308)),
  ])
  let too_large = comparison_number("1.7e308", 1.7e308)
  let call = sequence_call("hypot", [too_large, too_large])
  transfer_reject(call)
  transfer_reject(sequence_call("type", [call]))
}

///|
test "MU8 unused math calls stay lazy and repeated aliases preserve inputs" {
  for name in ["hypot", "mantissa", "exponent", "tan"] {
    let args = if name == "hypot" {
      [ordering_error("math-unused"), sequence_num(0)]
    } else {
      [ordering_error("math-unused")]
    }
    for call in [sequence_call(name, args), rounding_apply(name, [])] {
      transfer_value(ordering_unused(call), 42)
      transfer_value(
        transfer_if(reflect_bool(false), call, sequence_num(42)),
        42,
      )
      transfer_value(
        transfer_if(reflect_bool(true), sequence_num(42), call),
        42,
      )
      transfer_value(ordering_binary(reflect_bool(false), "&&", call), false)
      transfer_value(ordering_binary(reflect_bool(true), "||", call), true)
      transfer_value(
        value_head_call(make_function(["unused"], sequence_num(42)), [call]),
        42,
      )
      transfer_value(
        reflect_object([(reflect_string("unused"), 2, call)]),
        Json::object(Map([])),
      )
    }
  }
  for
    (name, input, expected) in [
      ("mantissa", 8, Json::number(0.5)),
      ("exponent", 8, Json::number(4)),
      ("tan", 0, Json::number(0)),
    ] {
    transfer_value(
      sequence_local(
        [("original", sequence_num(input)), ("copy", sequence_var("original"))],
        ordering_array([
          sequence_call(name, [sequence_var("copy")]),
          sequence_call(name, [sequence_var("original")]),
          sequence_var("copy"),
          sequence_var("original"),
        ]),
      ),
      Json::array([
        expected,
        expected,
        Json::number(input.to_double()),
        Json::number(input.to_double()),
      ]),
    )
  }
  transfer_value(
    sequence_local(
      [("a", sequence_num(3)), ("b", sequence_num(4))],
      ordering_array([
        sequence_call("hypot", [sequence_var("a"), sequence_var("b")]),
        sequence_call("hypot", [sequence_var("b"), sequence_var("a")]),
        sequence_var("a"),
        sequence_var("b"),
      ]),
    ),
    [5, 5, 3, 4],
  )
}
