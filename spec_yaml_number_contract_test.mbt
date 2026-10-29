// Frozen Number-clause criteria: SPEC-YAML-DEMAND-2026-10-25.md.
// Literal text is independent of product formatters; Stream flags are explicit.

///|
fn yaml_number_value(source : String, value : Double) -> OrderingExpr {
  ordering_leaf(source, Literal(Json::number(value)))
}

///|
fn yaml_number_doc(
  value : OrderingExpr,
  indent? : Bool = false,
) -> OrderingExpr {
  yaml_demand_doc(value, reflect_bool(indent), reflect_bool(true))
}

///|
fn yaml_number_stream(
  values : Array[OrderingExpr],
  ending : Bool,
) -> OrderingExpr {
  yaml_demand_stream(
    ordering_array(values),
    reflect_bool(false),
    reflect_bool(true),
    reflect_bool(ending),
  )
}

///|
test "YN1 YAML Number scalars follow independently declared finite text" {
  sequence_value(
    yaml_number_doc(ordering_leaf("-0", Unary("-", sequence_num(0).tree))),
    "-0",
  )
  for
    (source, value, expected) in [
      ("0.1", 0.1, "0.10000000000000001"),
      ("-0.1", -0.1, "-0.10000000000000001"),
      ("0.5", 0.5, "0.5"),
      ("-1.25", -1.25, "-1.25"),
      ("0", 0.0, "0"),
      ("1", 1.0, "1"),
      ("9007199254740991", 9007199254740991.0, "9007199254740991"),
      ("9007199254740992", 9007199254740992.0, "9007199254740992"),
      ("1000000000000000100", 1000000000000000100.0, "1000000000000000128"),
      ("1e21", 1.0e21, "1000000000000000000000"),
      ("1.234e30", 1.234e30, "1233999999999999958672482500608"),
      ("1e-8", 1.0e-8, "1e-08"),
      ("1e-20", 1.0e-20, "9.9999999999999995e-21"),
      (
        "2.2250738585072014e-308", 2.2250738585072014e-308, "2.2250738585072014e-308",
      ),
      ("5e-324", 5.0e-324, "4.9406564584124654e-324"),
      ("-5e-324", -5.0e-324, "-4.9406564584124654e-324"),
      (
        "1.7976931348623157e308", 1.7976931348623157e308, "179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858368",
      ),
      (
        "-1.7976931348623157e308", -1.7976931348623157e308, "-179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858368",
      ),
    ] {
    sequence_value(
      yaml_number_doc(yaml_number_value(source, value)),
      Json::string(expected),
    )
  }
}

///|
test "YN2 YAML nested Number text preserves existing document layouts" {
  let object = reflect_object([
    (reflect_string("z"), 2, ordering_error("yaml-number-hidden")),
    (
      reflect_string("b"),
      1,
      ordering_leaf("-0", Unary("-", sequence_num(0).tree)),
    ),
    (
      reflect_string("a"),
      1,
      ordering_array([
        yaml_number_value("0.1", 0.1),
        yaml_number_value("1e-8", 1.0e-8),
      ]),
    ),
  ])
  for
    (indent, expected) in [
      (false, "\"a\":\n- 0.10000000000000001\n- 1e-08\n\"b\": -0"),
      (true, "\"a\":\n  - 0.10000000000000001\n  - 1e-08\n\"b\": -0"),
    ] {
    sequence_value(yaml_number_doc(object, indent~), Json::string(expected))
  }
  sequence_value(
    yaml_number_doc(
      ordering_array([
        ordering_array([yaml_number_value("0.1", 0.1)]),
        reflect_object([
          (reflect_string("n"), 1, yaml_number_value("1e-8", 1.0e-8)),
        ]),
      ]),
    ),
    "-\n  - 0.10000000000000001\n- \"n\": 1e-08",
  )
}

///|
test "YN3 YAML Number streams preserve explicit false and true end markers" {
  let values = [
    yaml_number_value("0.1", 0.1),
    ordering_leaf("-0", Unary("-", sequence_num(0).tree)),
    yaml_number_value("1e-8", 1.0e-8),
  ]
  for
    (ending, expected) in [
      (false, "---\n0.10000000000000001\n---\n-0\n---\n1e-08\n"),
      (true, "---\n0.10000000000000001\n---\n-0\n---\n1e-08\n...\n"),
    ] {
    sequence_value(yaml_number_stream(values, ending), Json::string(expected))
  }
  let object = reflect_object([
    (reflect_string("n"), 1, yaml_number_value("0.1", 0.1)),
  ])
  sequence_value(
    yaml_number_stream([object], false),
    "---\n\"n\": 0.10000000000000001\n",
  )
  sequence_value(
    yaml_number_stream([yaml_number_value("0.5", 0.5)], true),
    "---\n0.5\n...\n",
  )
}

///|
test "YN4 YAML Number Doc and explicit Stream obey scalar coercion identity" {
  for
    (source, value, expected) in [
      ("0.1", 0.1, "0.10000000000000001"),
      ("1e-8", 1.0e-8, "1e-08"),
      ("1000000000000000100", 1000000000000000100.0, "1000000000000000128"),
    ] {
    let number = yaml_number_value(source, value)
    let coerced = ordering_binary(reflect_string(""), "+", number)
    sequence_value(coerced, Json::string(expected))
    sequence_value(sequence_call("toString", [number]), Json::string(expected))
    sequence_value(yaml_number_doc(number), Json::string(expected))
    sequence_value(
      ordering_binary(yaml_number_doc(number), "==", coerced),
      true,
    )
    let stream = yaml_number_stream([number], false)
    sequence_value(stream, Json::string("---\n" + expected + "\n"))
    let wrapped = ordering_binary(
      ordering_binary(reflect_string("---\n"), "+", coerced),
      "+",
      reflect_string("\n"),
    )
    sequence_value(ordering_binary(stream, "==", wrapped), true)
  }
}

///|
test "YN5 YAML Number demand skips unused options and propagates required errors" {
  let exact = yaml_number_value("0.5", 0.5)
  sequence_value(
    yaml_demand_doc(
      exact,
      ordering_error("yaml-unused-indent"),
      ordering_error("yaml-unused-quote"),
    ),
    "0.5",
  )
  for (ending, expected) in [(false, "---\n0.5\n"), (true, "---\n0.5\n...\n")] {
    sequence_value(
      yaml_demand_stream(
        ordering_array([exact]),
        ordering_error("yaml-unused-indent"),
        ordering_error("yaml-unused-quote"),
        reflect_bool(ending),
      ),
      Json::string(expected),
    )
  }
  let bad = ordering_error("yaml-number-required")
  let large = yaml_number_value("1e308", 1.0e308)
  let overflow = ordering_binary(large, "+", large)
  for
    (failure, marker) in [(bad, Some("yaml-number-required")), (overflow, None)] {
    for
      value in [
        failure,
        ordering_array([exact, failure]),
        reflect_object([(reflect_string("n"), 1, failure)]),
      ] {
      // The neutral helper also verifies the unused whole call returns 42.
      sequence_failure(yaml_number_doc(value), @moonjsonnet.Runtime, marker)
      for ending in [false, true] {
        sequence_failure(
          yaml_number_stream([exact, value], ending),
          @moonjsonnet.Runtime,
          marker,
        )
      }
    }
  }
}

///|
test "YN6 YAML Number byte budgets include document indentation and stream markers" {
  let fraction = yaml_number_value("0.1", 0.1)
  let tiny = yaml_number_value("1e-8", 1.0e-8)
  let object = reflect_object([
    (reflect_string("n"), 1, ordering_array([fraction, tiny])),
  ])
  for
    (rendered, expected) in [
      (yaml_number_doc(fraction), "0.10000000000000001"),
      (
        yaml_number_doc(yaml_number_value("5e-324", 5.0e-324)),
        "4.9406564584124654e-324",
      ),
      (
        yaml_number_doc(object, indent=true),
        "\"n\":\n  - 0.10000000000000001\n  - 1e-08",
      ),
      (
        yaml_number_stream([fraction, tiny], false),
        "---\n0.10000000000000001\n---\n1e-08\n",
      ),
      (
        yaml_number_stream([fraction, tiny], true),
        "---\n0.10000000000000001\n---\n1e-08\n...\n",
      ),
    ] {
    let bytes = expected.length()
    let call = sequence_call("length", [rendered])
    // Expected text is ASCII; std.length avoids outer JSON String quoting.
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
        _ => fail("YAML Number output accepted a one-byte-short budget")
      }
    }
  }
}
