// Fixed stdlib.html 247-250 and spec.html 2820-2836: standard IEEE mathematics.
// Independent wide mathematical intervals; no Go oracle or arbitrary ULP promise.
// Normal calls use source and handmade AST. atan2(0,0) and zero text are ungraded.

///|
fn inverse_trig_intervals(
  cases : Array[(OrderingExpr, Double, Double)],
) -> Unit raise {
  let failures : Array[String] = []
  for (call, lower, upper) in cases {
    for handmade in [false, true] {
      let value = ordering_program(call, handmade).evaluate(
        limits=transfer_limits(),
      )
      guard value is Number(actual, ..) else {
        fail("inverse trig returned a nonnumber")
      }
      if !(lower < actual && actual < upper) {
        failures.push(
          call.source +
          " handmade=" +
          handmade.to_string() +
          " actual=" +
          actual.to_string() +
          " expected=(" +
          lower.to_string() +
          "," +
          upper.to_string() +
          ")",
        )
      }
    }
  }
  if !failures.is_empty() {
    fail(failures.join("; "))
  }
}

///|
test "IT1 inverse unary functions preserve exact zeros endpoints and interior mathematical bounds" {
  for (name, input) in [("asin", 0), ("acos", 1), ("atan", 0)] {
    transfer_value(sequence_call(name, [sequence_num(input)]), 0)
  }
  let cases : Array[(String, String, Double, Double, Double)] = [
    ("asin", "1", 1.0, 1.570, 1.571),
    ("asin", "-1", -1.0, -1.571, -1.570),
    ("asin", "0.5", 0.5, 0.523, 0.524),
    ("asin", "-0.5", -0.5, -0.524, -0.523),
    ("acos", "0", 0.0, 1.570, 1.571),
    ("acos", "-1", -1.0, 3.141, 3.142),
    ("acos", "0.5", 0.5, 1.047, 1.048),
    ("acos", "-0.5", -0.5, 2.094, 2.095),
    ("atan", "1", 1.0, 0.785, 0.786),
    ("atan", "-1", -1.0, -0.786, -0.785),
    ("atan", "1.7976931348623157e308", 1.7976931348623157e308, 1.570, 1.571),
    ("atan", "-1.7976931348623157e308", -1.7976931348623157e308, -1.571, -1.570),
  ]
  inverse_trig_intervals(
    cases.map(c => (sequence_call(c.0, [comparison_number(c.1, c.2)]), c.3, c.4)),
  )
}

///|
test "IT2 atan2 preserves quadrants nonzero axes and extreme finite directions" {
  transfer_value(sequence_call("atan2", [sequence_num(0), sequence_num(1)]), 0)
  let cases : Array[(OrderingExpr, OrderingExpr, Double, Double)] = [
    (sequence_num(1), sequence_num(1), 0.785, 0.786),
    (sequence_num(1), sequence_num(-1), 2.356, 2.357),
    (sequence_num(-1), sequence_num(-1), -2.357, -2.356),
    (sequence_num(-1), sequence_num(1), -0.786, -0.785),
    (sequence_num(1), sequence_num(0), 1.570, 1.571),
    (sequence_num(-1), sequence_num(0), -1.571, -1.570),
  ]
  inverse_trig_intervals(
    cases.map(c => (sequence_call("atan2", [c.0, c.1]), c.2, c.3)),
  )
  // The negative axis has magnitude pi; no new signed-zero branch convention.
  inverse_trig_intervals([
    (
      sequence_call("abs", [
        sequence_call("atan2", [sequence_num(0), sequence_num(-1)]),
      ]),
      3.141,
      3.142,
    ),
  ])
  let maximum = comparison_number(
    "1.7976931348623157e308", 1.7976931348623157e308,
  )
  let negative = comparison_number(
    "-1.7976931348623157e308", -1.7976931348623157e308,
  )
  inverse_trig_intervals([
    (sequence_call("atan2", [maximum, maximum]), 0.785, 0.786),
    (sequence_call("atan2", [maximum, negative]), 2.356, 2.357),
    (sequence_call("atan2", [negative, negative]), -2.357, -2.356),
    (sequence_call("atan2", [negative, maximum]), -0.786, -0.785),
    (
      sequence_call("atan2", [maximum, comparison_number("5e-324", 5.0e-324)]),
      1.570,
      1.571,
    ),
    (
      sequence_call("atan2", [negative, comparison_number("5e-324", 5.0e-324)]),
      -1.571,
      -1.570,
    ),
  ])
}

///|
test "IT3 atan2 retains the original quadrant when a finite coordinate ratio underflows" {
  let tiny = comparison_number("1e-300", 1.0e-300)
  let negative_tiny = comparison_number("-1e-300", -1.0e-300)
  let huge = comparison_number("1e300", 1.0e300)
  let negative_huge = comparison_number("-1e300", -1.0e300)
  let minimum = comparison_number("5e-324", 5.0e-324)
  let negative_minimum = comparison_number("-5e-324", -5.0e-324)
  let large = comparison_number("1e308", 1.0e308)
  let negative_large = comparison_number("-1e308", -1.0e308)
  // Every source/AST case runs before interval failures are reported with values.
  inverse_trig_intervals([
    (sequence_call("atan2", [negative_tiny, negative_huge]), -3.142, -3.141),
    (sequence_call("atan2", [tiny, negative_huge]), 3.141, 3.142),
    (sequence_call("atan2", [negative_minimum, negative_large]), -3.142, -3.141),
    (sequence_call("atan2", [minimum, negative_large]), 3.141, 3.142),
    (sequence_call("atan2", [negative_tiny, huge]), -0.001, 0.001),
    (sequence_call("atan2", [tiny, huge]), -0.001, 0.001),
    (sequence_call("atan2", [negative_minimum, large]), -0.001, 0.001),
    (sequence_call("atan2", [minimum, large]), -0.001, 0.001),
  ])
}

///|
test "IT4 inverse trig required names arity and aliases preserve binding and original inputs" {
  for
    (name, input, repeated) in [
      ("asin", 0, Json::array([0, 0, 0])),
      ("acos", 1, Json::array([0, 1, 1])),
      ("atan", 0, Json::array([0, 0, 0])),
    ] {
    let function = additive_select(sequence_var("std"), name)
    transfer_value(sequence_call("length", [function]), 1)
    for label in [None, Some("x")] {
      transfer_value(rounding_apply(name, [(label, sequence_num(input))]), 0)
      transfer_value(
        sequence_local(
          [
            ("original", sequence_num(input)),
            ("copied", sequence_var("original")),
            ("f", function),
          ],
          ordering_array([
            shared_mode_call(sequence_var("f"), [
              (label, sequence_var("copied")),
            ]),
            sequence_var("original"),
            sequence_var("copied"),
          ]),
        ),
        repeated,
      )
    }
    let safe = sequence_num(1)
    let invalid : Array[Array[(String?, OrderingExpr)]] = [
      [],
      [(None, safe), (None, safe)],
      [(Some("v"), safe)],
      [(Some("x"), safe), (Some("unknown"), safe)],
      [(None, safe), (Some("x"), safe)],
    ]
    for args in invalid {
      transfer_reject(rounding_apply(name, args))
      transfer_reject(
        sequence_local(
          [("f", function)],
          shared_mode_call(sequence_var("f"), args),
        ),
      )
    }
  }
  let function = additive_select(sequence_var("std"), "atan2")
  transfer_value(sequence_call("length", [function]), 2)
  let forms : Array[Array[(String?, OrderingExpr)]] = [
    [(None, sequence_num(0)), (None, sequence_num(1))],
    [(Some("y"), sequence_num(0)), (Some("x"), sequence_num(1))],
    [(Some("x"), sequence_num(1)), (Some("y"), sequence_num(0))],
    [(None, sequence_num(0)), (Some("x"), sequence_num(1))],
  ]
  for args in forms {
    transfer_value(rounding_apply("atan2", args), 0)
    transfer_value(
      sequence_local(
        [("f", function)],
        shared_mode_call(sequence_var("f"), args),
      ),
      0,
    )
  }
  transfer_value(
    sequence_local(
      [("y", sequence_num(0)), ("x", sequence_num(1)), ("f", function)],
      ordering_array([
        shared_mode_call(sequence_var("f"), [
          (Some("x"), sequence_var("x")),
          (Some("y"), sequence_var("y")),
        ]),
        sequence_var("y"),
        sequence_var("x"),
      ]),
    ),
    [0, 0, 1],
  )
  let safe = sequence_num(1)
  let invalid : Array[Array[(String?, OrderingExpr)]] = [
    [],
    [(None, safe)],
    [(Some("x"), safe)],
    [(Some("y"), safe)],
    [(None, safe), (None, safe), (None, safe)],
    [(Some("z"), safe), (Some("x"), safe)],
    [(None, safe), (Some("y"), safe), (Some("x"), safe)],
  ]
  for args in invalid {
    transfer_reject(rounding_apply("atan2", args))
    transfer_reject(
      sequence_local(
        [("f", function)],
        shared_mode_call(sequence_var("f"), args),
      ),
    )
  }
  for name in ["asin", "acos", "atan", "atan2"] {
    let args = if name == "atan2" {
      [(Some("y"), safe), (Some("x"), safe), (Some("y"), safe)]
    } else {
      [(Some("x"), safe), (Some("x"), safe)]
    }
    for handmade in [false, true] {
      try
        ordering_program(ordering_unused(rounding_apply(name, args)), handmade)
      catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
      } noraise {
        _ => fail("duplicate inverse trig names escaped static admission")
      }
    }
  }
}

///|
test "IT5 inverse trig rejects every nonnumber head without nested payload demand" {
  let unread = ordering_error("inverse-trig-unread")
  let wrong = [
    ordering_leaf("null", Literal(Json::null())),
    reflect_bool(true),
    reflect_string("1"),
    ordering_array([unread]),
    reflect_object([
      (reflect_string("visible"), 1, unread),
      (reflect_string("hidden"), 2, unread),
    ]),
    value_head_function(unread, unread),
  ]
  for input in wrong {
    let calls = [
      sequence_call("asin", [input]),
      sequence_call("acos", [input]),
      sequence_call("atan", [input]),
      sequence_call("atan2", [input, sequence_num(1)]),
      sequence_call("atan2", [sequence_num(1), input]),
    ]
    for call in calls {
      for handmade in [false, true] {
        try
          ordering_program(call, handmade).evaluate(limits=transfer_limits())
        catch {
          // Extra embedding distinction from the unread Runtime payload error.
          @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Type)
        } noraise {
          _ => fail("inverse trig accepted a nonnumber head")
        }
      }
    }
  }
}

///|
test "IT6 inverse trig domain failures and isolated outer errors occur when required" {
  for name in ["asin", "acos"] {
    for
      (source, input) in [
        ("1.0000000000000002", 1.0000000000000002),
        ("-1.0000000000000002", -1.0000000000000002),
        ("1.7976931348623157e308", 1.7976931348623157e308),
        ("-1.7976931348623157e308", -1.7976931348623157e308),
      ] {
      let call = sequence_call(name, [comparison_number(source, input)])
      for
        demanded in [
          call,
          sequence_call("type", [call]),
          ordering_binary(call, "+", sequence_num(0)),
        ] {
        transfer_reject(demanded)
      }
    }
  }
  for name in ["asin", "acos", "atan"] {
    let marker = "inverse-trig-outer-" + name
    // Runtime and marker checks supplement the language failure requirement.
    transfer_error(
      rounding_apply(name, [(Some("x"), ordering_error(marker))]),
      marker,
    )
    transfer_error(
      sequence_local(
        [("f", additive_select(sequence_var("std"), name))],
        shared_mode_call(sequence_var("f"), [(None, ordering_error(marker))]),
      ),
      marker,
    )
  }
  for
    (y, x, marker) in [
      (ordering_error("atan2-y"), sequence_num(1), "atan2-y"),
      (sequence_num(1), ordering_error("atan2-x"), "atan2-x"),
    ] {
    transfer_error(
      rounding_apply("atan2", [(Some("x"), x), (Some("y"), y)]),
      marker,
    )
    transfer_error(
      sequence_local(
        [("f", additive_select(sequence_var("std"), "atan2"))],
        shared_mode_call(sequence_var("f"), [(None, y), (None, x)]),
      ),
      marker,
    )
  }
}

///|
test "IT7 unused inverse trig calls arguments fields and branches preserve laziness" {
  let calls = [
    sequence_call("asin", [sequence_num(2)]),
    sequence_call("acos", [sequence_num(-2)]),
    sequence_call("atan2", [ordering_error("unused-y"), sequence_num(1)]),
    sequence_call("atan2", [sequence_num(1), ordering_error("unused-x")]),
  ]
  for name in ["asin", "acos", "atan"] {
    calls.push(sequence_call(name, [ordering_error("unused-inverse")]))
  }
  for name in ["asin", "acos", "atan", "atan2"] {
    calls.push(rounding_apply(name, []))
    calls.push(rounding_apply(name, [(Some("unknown"), sequence_num(1))]))
  }
  for call in calls {
    transfer_value(ordering_unused(call), 42)
    transfer_value(transfer_if(reflect_bool(false), call, sequence_num(42)), 42)
    transfer_value(transfer_if(reflect_bool(true), sequence_num(42), call), 42)
    transfer_value(ordering_binary(reflect_bool(false), "&&", call), false)
    transfer_value(ordering_binary(reflect_bool(true), "||", call), true)
    transfer_value(
      value_head_call(make_function(["unused"], sequence_num(42)), [call]),
      42,
    )
    transfer_value(
      reflect_object([(reflect_string("hidden"), 2, call)]),
      Json::object(Map([])),
    )
  }
}
