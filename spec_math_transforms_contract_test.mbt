// Fixed std.jsonnet 267-271 and stdlib.html 237-238,251-252.
// Literal source/handmade-AST oracles; IEEE arithmetic, fixed pi and log are children.
// No arbitrary ULP tolerance, signed-zero text or general log-accuracy claim.

///|
test "MX1 degree and radian transforms retain literal common units and finite underflow" {
  let cases : Array[(String, String, Double, Double)] = [
    ("deg2rad", "0", 0.0, 0.0),
    ("deg2rad", "-0", -0.0, 0.0),
    ("deg2rad", "90", 90.0, 1.5707963267948966),
    ("deg2rad", "-90", -90.0, -1.5707963267948966),
    ("deg2rad", "180", 180.0, 3.141592653589793),
    ("deg2rad", "-180", -180.0, -3.141592653589793),
    ("deg2rad", "5e-324", 5.0e-324, 0.0),
    ("rad2deg", "0", 0.0, 0.0),
    ("rad2deg", "-0", -0.0, 0.0),
    ("rad2deg", "1.5707963267948966", 1.5707963267948966, 90.0),
    ("rad2deg", "-1.5707963267948966", -1.5707963267948966, -90.0),
    ("rad2deg", "3.141592653589793", 3.141592653589793, 180.0),
    ("rad2deg", "-3.141592653589793", -3.141592653589793, -180.0),
  ]
  for (name, source, number, expected) in cases {
    transfer_value(
      sequence_call(name, [ordering_leaf(source, Literal(Json::number(number)))]),
      Json::number(expected),
    )
  }
}

///|
test "MX2 logarithm transforms retain independent literal base identities" {
  let cases : Array[(String, String, Double, Double)] = [
    ("log2", "1", 1.0, 0.0),
    ("log2", "2", 2.0, 1.0),
    ("log2", "4", 4.0, 2.0),
    ("log2", "0.5", 0.5, -1.0),
    ("log10", "1", 1.0, 0.0),
    ("log10", "10", 10.0, 1.0),
  ]
  for (name, source, number, expected) in cases {
    transfer_value(
      sequence_call(name, [ordering_leaf(source, Literal(Json::number(number)))]),
      Json::number(expected),
    )
  }
}

///|
test "MX3 required x accepts positional named and aliased calls without changing inputs" {
  let cases : Array[(String, Int, Json)] = [
    ("deg2rad", 0, [0, 0, 0, 0]),
    ("rad2deg", 0, [0, 0, 0, 0]),
    ("log2", 1, [0, 0, 1, 1]),
    ("log10", 1, [0, 0, 1, 1]),
  ]
  for (name, input, expected) in cases {
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
            shared_mode_call(sequence_var("f"), [
              (label, sequence_var("original")),
            ]),
            sequence_var("original"),
            sequence_var("copied"),
          ]),
        ),
        expected,
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
    // Ordinary named uniqueness is an established static-admission child rule.
    let duplicate = rounding_apply(name, [(Some("x"), safe), (Some("x"), safe)])
    for handmade in [false, true] {
      try ordering_program(ordering_unused(duplicate), handmade) catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
      } noraise {
        _ =>
          fail(
            "duplicate math transform named arguments escaped static admission",
          )
      }
    }
  }
}

///|
test "MX4 math transforms reject every nonnumber head without reading nested errors" {
  let unread = ordering_error("math-transform-unread")
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
  for name in ["deg2rad", "rad2deg", "log2", "log10"] {
    for input in nonnumbers {
      for handmade in [false, true] {
        try
          ordering_program(sequence_call(name, [input]), handmade).evaluate(
            limits=transfer_limits(),
          )
        catch {
          // Type is an extra embedding distinction from the nested Runtime error.
          @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Type)
        } noraise {
          _ => fail("math transform accepted a nonnumber head")
        }
      }
    }
  }
}

///|
test "MX5 invalid log domains and intermediate angle overflow fail at their producers" {
  let invalid = [
    sequence_call("log2", [sequence_num(0)]),
    sequence_call("log2", [sequence_num(-1)]),
    sequence_call("log10", [sequence_num(0)]),
    sequence_call("log10", [sequence_num(-1)]),
    sequence_call("deg2rad", [
      ordering_leaf("1e308", Literal(Json::number(1.0e308))),
    ]),
    sequence_call("rad2deg", [
      ordering_leaf("1e306", Literal(Json::number(1.0e306))),
    ]),
  ]
  for call in invalid {
    // Both observers force the producer but cannot expose a nonfinite payload.
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
}

///|
test "MX6 sole outer errors propagate and unused math calls remain lazy" {
  for name in ["deg2rad", "rad2deg", "log2", "log10"] {
    let marker = "math-transform-outer-" + name
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
    for
      call in [
        required,
        rounding_apply(name, []),
        rounding_apply(name, [(Some("unknown"), sequence_num(1))]),
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
