// Fixed std.jsonnet 1760,1770-1771 and stdlib.html 254,257-258.
// Literal oracles for floor(IEEE binary64(x + 0.5)) and its equality predicates.
// Source and handmade AST use ordinary std calls. Fractional parity is excluded.

///|
fn rounding_contract_values(cases : Array[(OrderingExpr, Json)]) -> Unit raise {
  let failures : Array[String] = []
  for (call, expected) in cases {
    for handmade in [false, true] {
      let actual = ordering_program(call, handmade).evaluate(
        limits=transfer_limits(),
      )
      if actual != expected {
        failures.push(
          call.source +
          " handmade=" +
          handmade.to_string() +
          " actual=" +
          actual.stringify() +
          " expected=" +
          expected.stringify(),
        )
      }
    }
  }
  if !failures.is_empty() {
    fail(failures.join("; "))
  }
}

///|
test "RP1 round follows literal half upward and ordinary finite cases" {
  let cases : Array[(String, Double, Double)] = [
    ("0", 0.0, 0.0),
    ("-0", -0.0, 0.0),
    ("1", 1.0, 1.0),
    ("-1", -1.0, -1.0),
    ("0.1", 0.1, 0.0),
    ("-0.1", -0.1, 0.0),
    ("0.25", 0.25, 0.0),
    ("-0.25", -0.25, 0.0),
    ("0.5", 0.5, 1.0),
    ("-0.5", -0.5, 0.0),
    ("1.5", 1.5, 2.0),
    ("-1.5", -1.5, -1.0),
    ("2.5", 2.5, 3.0),
    ("-2.5", -2.5, -2.0),
    ("2.75", 2.75, 3.0),
    ("-2.75", -2.75, -3.0),
  ]
  rounding_contract_values(
    cases.map(c => {
      (sequence_call("round", [comparison_number(c.0, c.1)]), Json::number(c.2))
    }),
  )
}

///|
test "RP2 integer and decimal predicates compare the defined rounded value" {
  let cases : Array[(String, Double, Bool, Bool)] = [
    ("0", 0.0, true, false),
    ("-0", -0.0, true, false),
    ("1", 1.0, true, false),
    ("-2", -2.0, true, false),
    ("0.5", 0.5, false, true),
    ("-0.5", -0.5, false, true),
    ("2.75", 2.75, false, true),
    ("-2.75", -2.75, false, true),
    ("4503599627370496", 4503599627370496.0, true, false),
    ("4503599627370497", 4503599627370497.0, false, true),
    ("-4503599627370497", -4503599627370497.0, false, true),
    ("4503599627370498", 4503599627370498.0, true, false),
  ]
  let observations : Array[(OrderingExpr, Json)] = []
  for (source, input, integer, decimal) in cases {
    observations.push(
      (
        sequence_call("isInteger", [comparison_number(source, input)]),
        Json::boolean(integer),
      ),
    )
    observations.push(
      (
        sequence_call("isDecimal", [comparison_number(source, input)]),
        Json::boolean(decimal),
      ),
    )
  }
  rounding_contract_values(observations)
}

///|
test "RP3 IEEE addition boundaries subnormals and finite extrema retain literal outcomes" {
  // Exact midpoint/significand reasoning supplies these literals, not std.round.
  // Numeric zero is tested without imposing a new signed-zero String policy.
  let cases : Array[(String, Double, Double, Bool, Bool)] = [
    ("0.49999999999999994", 0.49999999999999994, 1.0, false, true),
    ("0.5000000000000001", 0.5000000000000001, 1.0, false, true),
    ("-0.5000000000000001", -0.5000000000000001, -1.0, false, true),
    ("4503599627370496", 4503599627370496.0, 4503599627370496.0, true, false),
    ("4503599627370497", 4503599627370497.0, 4503599627370498.0, false, true),
    ("-4503599627370497", -4503599627370497.0, -4503599627370496.0, false, true),
    ("9007199254740992", 9007199254740992.0, 9007199254740992.0, true, false),
    ("5e-324", 5.0e-324, 0.0, false, true),
    ("-5e-324", -5.0e-324, 0.0, false, true),
    ("2.2250738585072014e-308", 2.2250738585072014e-308, 0.0, false, true),
    ("-2.2250738585072014e-308", -2.2250738585072014e-308, 0.0, false, true),
    (
      "1.7976931348623157e308", 1.7976931348623157e308, 1.7976931348623157e308, true,
      false,
    ),
    (
      "-1.7976931348623157e308", -1.7976931348623157e308, -1.7976931348623157e308,
      true, false,
    ),
  ]
  let observations : Array[(OrderingExpr, Json)] = []
  for (source, input, rounded, integer, decimal) in cases {
    let value = comparison_number(source, input)
    observations.push((sequence_call("round", [value]), Json::number(rounded)))
    observations.push(
      (sequence_call("isInteger", [value]), Json::boolean(integer)),
    )
    observations.push(
      (sequence_call("isDecimal", [value]), Json::boolean(decimal)),
    )
  }
  rounding_contract_values(observations)
}

///|
test "RP4 required x bindings aliases and original inputs retain ordinary call rules" {
  for
    (name, expected) in [
      ("round", Json::number(2)),
      ("isInteger", Json::boolean(true)),
      ("isDecimal", Json::boolean(false)),
    ] {
    let function = additive_select(sequence_var("std"), name)
    transfer_value(sequence_call("length", [function]), 1)
    for label in [None, Some("x")] {
      transfer_value(rounding_apply(name, [(label, sequence_num(2))]), expected)
      let aliased_expr = sequence_var("copied")
      transfer_value(
        sequence_local(
          [
            ("original", sequence_num(2)),
            ("copied", sequence_var("original")),
            ("f", function),
          ],
          ordering_array([
            shared_mode_call(sequence_var("f"), [(label, aliased_expr)]),
            shared_mode_call(sequence_var("f"), [
              (label, sequence_var("original")),
            ]),
            sequence_var("original"),
            aliased_expr,
          ]),
        ),
        Json::array([expected, expected, 2, 2]),
      )
    }
    let safe = sequence_num(2)
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
    // Static named uniqueness is an established ordinary-call child rule.
    let duplicate = rounding_apply(name, [(Some("x"), safe), (Some("x"), safe)])
    for handmade in [false, true] {
      try ordering_program(ordering_unused(duplicate), handmade) catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
      } noraise {
        _ => fail("duplicate rounding named arguments escaped static admission")
      }
    }
  }
}

///|
test "RP5 rounding predicates reject every nonnumber head without requiring payload errors" {
  let unread = ordering_error("rounding-unread-payload")
  let nonnumbers = [
    ordering_leaf("null", Literal(Json::null())),
    reflect_bool(false),
    reflect_bool(true),
    reflect_string(""),
    reflect_string("2"),
    ordering_array([]),
    ordering_array([unread]),
    reflect_object([]),
    reflect_object([
      (reflect_string("visible"), 1, unread),
      (reflect_string("hidden"), 2, unread),
    ]),
    make_function([], unread),
    value_head_function(unread, unread),
  ]
  for name in ["round", "isInteger", "isDecimal"] {
    for input in nonnumbers {
      for handmade in [false, true] {
        try
          ordering_program(sequence_call(name, [input]), handmade).evaluate(
            limits=transfer_limits(),
          )
        catch {
          // Type versus nested Runtime is an extra embedding diagnostic assertion.
          @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Type)
        } noraise {
          _ => fail("rounding predicate accepted a nonnumber head")
        }
      }
    }
  }
}

///|
test "RP6 sole required errors and nonfinite producers cannot be hidden by rounding consumers" {
  let maximum = comparison_number(
    "1.7976931348623157e308", 1.7976931348623157e308,
  )
  let overflow = ordering_binary(maximum, "+", maximum)
  for name in ["round", "isInteger", "isDecimal"] {
    let marker = "rounding-outer-" + name
    let required = rounding_apply(name, [(Some("x"), ordering_error(marker))])
    // Runtime and marker checks supplement the required language failure.
    transfer_error(required, marker)
    transfer_error(
      sequence_local(
        [("f", additive_select(sequence_var("std"), name))],
        shared_mode_call(sequence_var("f"), [(None, ordering_error(marker))]),
      ),
      marker,
    )
    let call = sequence_call(name, [overflow])
    transfer_reject(call)
    transfer_reject(sequence_call("type", [call]))
    transfer_value(ordering_unused(call), 42)
  }
}

///|
test "RP7 unused calls arguments fields and branches retain lazy demand" {
  for name in ["round", "isInteger", "isDecimal"] {
    for
      call in [
        sequence_call(name, [ordering_error("rounding-unused")]),
        sequence_call(name, [reflect_string("invalid")]),
        rounding_apply(name, []),
        rounding_apply(name, [(Some("unknown"), sequence_num(2))]),
      ] {
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
}
