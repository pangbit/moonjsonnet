// Fixed spec.html 2820-2836: standard mathematical behavior on IEEE doubles.
// Independent literal/broad mathematical bounds, not Go outputs or ULP promises.
// Public calls use source and handmade AST; generic call/comparison rules are children.

///|
test "NM1 native math retains exact elementary values and binary square roots" {
  let cases : Array[(String, String, Double, Double)] = [
    ("sqrt", "0", 0.0, 0.0),
    ("sqrt", "1", 1.0, 1.0),
    ("sqrt", "4", 4.0, 2.0),
    ("sqrt", "9", 9.0, 3.0),
    ("sqrt", "0.25", 0.25, 0.5),
    ("sqrt", "5e-324", 5.0e-324, 2.2227587494850775e-162),
    (
      "sqrt", "2.2250738585072014e-308", 2.2250738585072014e-308, 1.4916681462400413e-154,
    ),
    (
      "sqrt", "4.49423283715579e307", 4.49423283715579e307, 6.703903964971299e153,
    ),
    ("exp", "0", 0.0, 1.0),
    ("exp", "-1000", -1000.0, 0.0),
    ("log", "1", 1.0, 0.0),
    ("sin", "0", 0.0, 0.0),
    ("cos", "0", 0.0, 1.0),
  ]
  for (name, source, input, expected) in cases {
    transfer_value(
      sequence_call(name, [comparison_number(source, input)]),
      Json::number(expected),
    )
  }
}

///|
test "NM2 logarithm and trigonometric bounds use independent mathematical intervals" {
  // 0.6931 < ln(2) < 0.6932 bounds powers of two; Taylor bounds cover +/-1.
  let intervals : Array[(String, String, Double, OrderingExpr, OrderingExpr)] = [
    ("log", "5e-324", 5.0e-324, sequence_num(-745), sequence_num(-744)),
    (
      "log",
      "1.1125369292536007e-308",
      1.1125369292536007e-308,
      sequence_num(-710),
      sequence_num(-709),
    ),
    (
      "log",
      "2.2250738585072014e-308",
      2.2250738585072014e-308,
      sequence_num(-709),
      sequence_num(-708),
    ),
    (
      "log",
      "1.7976931348623157e308",
      1.7976931348623157e308,
      sequence_num(709),
      sequence_num(710),
    ),
    (
      "sin",
      "1",
      1.0,
      comparison_number("0.8", 0.8),
      comparison_number("0.9", 0.9),
    ),
    (
      "sin",
      "-1",
      -1.0,
      comparison_number("-0.9", -0.9),
      comparison_number("-0.8", -0.8),
    ),
    (
      "cos",
      "1",
      1.0,
      comparison_number("0.5", 0.5),
      comparison_number("0.6", 0.6),
    ),
    (
      "cos",
      "-1",
      -1.0,
      comparison_number("0.5", 0.5),
      comparison_number("0.6", 0.6),
    ),
  ]
  for (name, source, input, lower, upper) in intervals {
    let result = sequence_var("result")
    transfer_value(
      sequence_local(
        [("result", sequence_call(name, [comparison_number(source, input)]))],
        ordering_array([
          ordering_binary(lower, "<", result),
          ordering_binary(result, "<", upper),
        ]),
      ),
      [true, true],
    )
  }
  // These large-input witnesses establish finite/range behavior, not phase accuracy.
  for name in ["sin", "cos"] {
    for
      (source, input) in [
        ("1e20", 1.0e20),
        ("-1e20", -1.0e20),
        ("1.7976931348623157e308", 1.7976931348623157e308),
        ("-1.7976931348623157e308", -1.7976931348623157e308),
      ] {
      let result = sequence_var("result")
      transfer_value(
        sequence_local(
          [("result", sequence_call(name, [comparison_number(source, input)]))],
          ordering_array([
            sequence_call("type", [result]),
            ordering_binary(sequence_num(-1), "<=", result),
            ordering_binary(result, "<=", sequence_num(1)),
          ]),
        ),
        ["number", true, true],
      )
    }
  }
}

///|
test "NM3 native math required x binding and aliases preserve literal results and inputs" {
  let cases : Array[(String, Int, Json, Json)] = [
    ("sqrt", 0, 0, [0, 0, 0, 0]),
    ("exp", 0, 1, [1, 1, 0, 0]),
    ("log", 1, 0, [0, 0, 1, 1]),
    ("sin", 0, 0, [0, 0, 0, 0]),
    ("cos", 0, 1, [1, 1, 0, 0]),
  ]
  for (name, input, expected, repeated) in cases {
    let function = additive_select(sequence_var("std"), name)
    transfer_value(sequence_call("length", [function]), 1)
    for label in [None, Some("x")] {
      transfer_value(
        rounding_apply(name, [(label, sequence_num(input))]),
        expected,
      )
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
            shared_mode_call(sequence_var("f"), [
              (label, sequence_var("original")),
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
    let duplicate = rounding_apply(name, [(Some("x"), safe), (Some("x"), safe)])
    for handmade in [false, true] {
      try ordering_program(ordering_unused(duplicate), handmade) catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
      } noraise {
        _ => fail("duplicate native math names escaped static admission")
      }
    }
  }
}

///|
test "NM4 native math rejects nonnumber heads without reading nested payload errors" {
  let unread = ordering_error("native-math-unread")
  let nonnumbers = [
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
  for name in ["sqrt", "exp", "log", "sin", "cos"] {
    for input in nonnumbers {
      for handmade in [false, true] {
        try
          ordering_program(sequence_call(name, [input]), handmade).evaluate(
            limits=transfer_limits(),
          )
        catch {
          // Extra embedding distinction from the nested Runtime error.
          @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Type)
        } noraise {
          _ => fail("native math accepted a nonnumber head")
        }
      }
    }
  }
}

///|
test "NM5 native domains overflow and sole outer errors fail at their producers" {
  for
    call in [
      sequence_call("sqrt", [sequence_num(-1)]),
      sequence_call("log", [sequence_num(0)]),
      sequence_call("log", [sequence_num(-1)]),
      sequence_call("exp", [sequence_num(1000)]),
    ] {
    for
      demanded in [
        call,
        sequence_call("type", [call]),
        ordering_binary(call, "+", sequence_num(0)),
      ] {
      transfer_reject(demanded)
    }
    transfer_value(ordering_unused(call), 42)
  }
  for name in ["sqrt", "exp", "log", "sin", "cos"] {
    let marker = "native-math-outer-" + name
    // Runtime and exact markers are extra embedding diagnostics, not priority rules.
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
}

///|
test "NM6 unused native math calls parameters fields and shortcuts remain lazy" {
  let calls = [
    sequence_call("sqrt", [sequence_num(-1)]),
    sequence_call("exp", [sequence_num(1000)]),
    sequence_call("log", [sequence_num(0)]),
  ]
  for name in ["sqrt", "exp", "log", "sin", "cos"] {
    calls.push(sequence_call(name, [ordering_error("native-math-unused")]))
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
      reflect_object([(reflect_string("unused"), 2, call)]),
      Json::object(Map([])),
    )
  }
}
