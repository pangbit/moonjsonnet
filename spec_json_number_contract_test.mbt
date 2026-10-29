// Frozen Number-branch criteria: SPEC-JSON-CONTRACTS-2026-10-23.md.
// Literal text oracles are independent of both product numeric renderers.

///|
fn json_number_value(source : String, value : Double) -> OrderingExpr {
  ordering_leaf(source, Literal(Json::number(value)))
}

///|
fn json_number_call(
  name : String,
  value : OrderingExpr,
  named? : Bool = false,
) -> OrderingExpr {
  rounding_apply(
    name,
    if name == "manifestJsonEx" {
      [
        (if named { Some("value") } else { None }, value),
        (if named { Some("indent") } else { None }, reflect_string("  ")),
      ]
    } else {
      [(if named { Some("value") } else { None }, value)]
    },
  )
}

///|
fn json_number_text(value : OrderingExpr, expected : String) -> Unit raise {
  for name in ["manifestJsonEx", "manifestJson", "manifestJsonMinified"] {
    sequence_value(json_number_call(name, value), Json::string(expected))
  }
}

///|
test "JN1 JSON Number scalar text and wrapper bindings use declared literals" {
  for
    (source, value, expected) in [
      ("0.1", 0.1, "0.10000000000000001"),
      ("0.2", 0.2, "0.20000000000000001"),
      ("0.5", 0.5, "0.5"),
      ("1.25", 1.25, "1.25"),
      ("-1.25", -1.25, "-1.25"),
    ] {
    for name in ["manifestJsonEx", "manifestJson", "manifestJsonMinified"] {
      for named in [false, true] {
        sequence_value(
          json_number_call(name, json_number_value(source, value), named~),
          Json::string(expected),
        )
      }
    }
  }
}

///|
test "JN2 JSON Number preserves signed zero and finite integral boundaries" {
  let negative_zero = ordering_leaf("-0", Unary("-", sequence_num(0).tree))
  json_number_text(negative_zero, "-0")
  for
    (source, value, expected) in [
      ("0", 0.0, "0"),
      ("-1", -1.0, "-1"),
      ("9007199254740991", 9007199254740991.0, "9007199254740991"),
      ("9007199254740992", 9007199254740992.0, "9007199254740992"),
      ("1000000000000000100", 1000000000000000100.0, "1000000000000000128"),
      ("1e21", 1.0e21, "1000000000000000000000"),
      (
        "1.7976931348623157e308", 1.7976931348623157e308, "179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858368",
      ),
      (
        "-1.7976931348623157e308", -1.7976931348623157e308, "-179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858368",
      ),
    ] {
    json_number_text(json_number_value(source, value), expected)
  }
}

///|
test "JN3 JSON Number tiny finite values retain coercion scientific text" {
  for
    (source, value, expected) in [
      ("1e-8", 1.0e-8, "1e-08"),
      ("1e-20", 1.0e-20, "9.9999999999999995e-21"),
      (
        "2.2250738585072014e-308", 2.2250738585072014e-308, "2.2250738585072014e-308",
      ),
      ("5e-324", 5.0e-324, "4.9406564584124654e-324"),
      ("-5e-324", -5.0e-324, "-4.9406564584124654e-324"),
    ] {
    json_number_text(json_number_value(source, value), expected)
  }
}

///|
test "JN4 JSON Number branch obeys the fixed empty String coercion identity" {
  for
    (source, value, expected) in [
      ("0.1", 0.1, "0.10000000000000001"),
      ("1e-8", 1.0e-8, "1e-08"),
      ("1000000000000000100", 1000000000000000100.0, "1000000000000000128"),
    ] {
    let number = json_number_value(source, value)
    let coercion = ordering_binary(reflect_string(""), "+", number)
    // The relation supplements literal oracles; product output never supplies
    // the expected text for another product path.
    sequence_value(coercion, Json::string(expected))
    sequence_value(sequence_call("toString", [number]), Json::string(expected))
    for name in ["manifestJsonEx", "manifestJson", "manifestJsonMinified"] {
      sequence_value(
        ordering_binary(json_number_call(name, number), "==", coercion),
        true,
      )
    }
  }
}

///|
test "JN5 nested JSON Number text preserves wrapper and custom layouts" {
  let object = reflect_object([
    (reflect_string("z"), 2, ordering_error("json-number-hidden")),
    (
      reflect_string("b"),
      1,
      ordering_leaf("-0", Unary("-", sequence_num(0).tree)),
    ),
    (
      reflect_string("a"),
      1,
      ordering_array([
        json_number_value("0.1", 0.1),
        json_number_value("1e-8", 1.0e-8),
      ]),
    ),
  ])
  for
    (name, expected) in [
      (
        "manifestJsonEx", "{\n  \"a\": [\n    0.10000000000000001,\n    1e-08\n  ],\n  \"b\": -0\n}",
      ),
      (
        "manifestJson", "{\n    \"a\": [\n        0.10000000000000001,\n        1e-08\n    ],\n    \"b\": -0\n}",
      ),
      ("manifestJsonMinified", "{\"a\":[0.10000000000000001,1e-08],\"b\":-0}"),
    ] {
    sequence_value(json_number_call(name, object), Json::string(expected))
  }
  sequence_value(
    rounding_apply("manifestJsonEx", [
      (Some("value"), object),
      (Some("indent"), reflect_string("")),
      (Some("newline"), reflect_string(" ")),
      (Some("key_val_sep"), reflect_string(" : ")),
    ]),
    "{ \"a\" : [ 0.10000000000000001, 1e-08 ], \"b\" : -0 }",
  )
}

///|
test "JN6 JSON Number demand preserves unused styles and required failures" {
  let bad = ordering_error("json-number-required")
  let styled = rounding_apply("manifestJsonEx", [
    (Some("value"), json_number_value("0.5", 0.5)),
    (Some("indent"), ordering_error("json-number-unused-indent")),
    (Some("newline"), ordering_error("json-number-unused-newline")),
    (Some("key_val_sep"), ordering_error("json-number-unused-separator")),
  ])
  sequence_value(styled, "0.5")
  let large = json_number_value("1e308", 1.0e308)
  let overflow = ordering_binary(large, "+", large)
  for name in ["manifestJsonEx", "manifestJson", "manifestJsonMinified"] {
    for
      value in [
        bad,
        ordering_array([bad]),
        reflect_object([(reflect_string("n"), 1, bad)]),
      ] {
      // sequence_failure independently checks the unused whole call first.
      sequence_failure(
        json_number_call(name, value),
        @moonjsonnet.Runtime,
        Some("json-number-required"),
      )
    }
    for
      value in [
        overflow,
        ordering_array([overflow]),
        reflect_object([(reflect_string("n"), 1, overflow)]),
      ] {
      sequence_failure(
        json_number_call(name, value),
        @moonjsonnet.Runtime,
        None,
      )
    }
  }
}

///|
test "JN7 JSON Number byte limits include scalar text and enclosing punctuation" {
  for
    (value, expected) in [
      (json_number_value("0.1", 0.1), "0.10000000000000001"),
      (json_number_value("5e-324", 5.0e-324), "4.9406564584124654e-324"),
      (ordering_array([json_number_value("0.1", 0.1)]), "[0.10000000000000001]"),
      (
        reflect_object([(reflect_string("n"), 1, json_number_value("0.1", 0.1))]),
        "{\"n\":0.10000000000000001}",
      ),
    ] {
    let call = sequence_call("length", [
      json_number_call("manifestJsonMinified", value),
    ])
    // All declared text is ASCII. Observing its length avoids charging the
    // outer JSON String quotes/escapes to this intermediate output budget.
    let bytes = expected.length()
    for handmade in [false, true] {
      let program = ordering_program(call, handmade)
      assert_eq(
        program.evaluate(limits={ ..sequence_limits(), output_bytes: bytes, }),
        Json::number(bytes.to_double()),
      )
      try
        program.evaluate(limits={
          ..sequence_limits(),
          output_bytes: bytes - 1,
        })
      catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
      } noraise {
        _ => fail("JSON Number output accepted a one-byte-short budget")
      }
    }
  }
}
