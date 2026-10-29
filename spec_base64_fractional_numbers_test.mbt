// Fixed Jsonnet bbb38f1020be1f5aed560928fb839b2c448cefb4 documents numeric
// inputs in 0..255. Its source Base64 bit operations use C++ safeDoubleToInt64,
// which truncates in-range fractions. Expected encodings below are literals.

///|
test "base64 converts in-range Number fractions to bytes toward zero" {
  let cases : Array[(String, Double, String)] = [
    ("5e-324", 5.0e-324, "AA=="),
    ("0.5", 0.5, "AA=="),
    ("1.5", 1.5, "AQ=="),
    ("254.5", 254.5, "/g=="),
    ("254.99999999999997", 254.99999999999997, "/g=="),
  ]
  for (text, number, encoded) in cases {
    sequence_value(
      base64_contract_call(ordering_array([deletion_number(text, number)])),
      Json::string(encoded),
    )
  }
  sequence_value(
    base64_contract_call(
      ordering_array([deletion_number("0.5", 0.5), deletion_number("1.5", 1.5)]),
      named=true,
    ),
    "AAE=",
  )
  sequence_value(
    base64_contract_call(
      ordering_array([
        deletion_number("102.75", 102.75),
        deletion_number("111.5", 111.5),
        deletion_number("111.25", 111.25),
      ]),
    ),
    "Zm9v",
  )
}

///|
test "base64 checks original numeric bounds while UTF8 decoding still requires integers" {
  for
    (text, number) in [
      ("-5e-324", -5.0e-324),
      ("-0.5", -0.5),
      ("255.00000000000003", 255.00000000000003),
      ("255.5", 255.5),
    ] {
    sequence_failure(
      base64_contract_call(ordering_array([deletion_number(text, number)])),
      @moonjsonnet.Runtime,
      None,
    )
  }
  sequence_failure(
    base64_contract_call(ordering_array([reflect_string("1.5")])),
    @moonjsonnet.Runtime,
    None,
  )
  for (text, number) in [("0.5", 0.5), ("254.5", 254.5)] {
    sequence_failure(
      sequence_call("decodeUTF8", [
        ordering_array([deletion_number(text, number)]),
      ]),
      @moonjsonnet.Runtime,
      None,
    )
  }
}

///|
test "base64 fractional conversion preserves required errors and original array values" {
  sequence_failure(
    base64_contract_call(
      ordering_array([
        deletion_number("0.5", 0.5),
        ordering_error("required fractional tail"),
      ]),
    ),
    @moonjsonnet.Runtime,
    Some("required fractional tail"),
  )
  let input = sequence_var("input")
  sequence_value(
    sequence_local(
      [
        (
          "input",
          ordering_array([
            deletion_number("0.5", 0.5),
            deletion_number("1.5", 1.5),
          ]),
        ),
      ],
      ordering_array([
        base64_contract_call(input),
        base64_contract_call(input, named=true),
        input,
      ]),
    ),
    ["AAE=", "AAE=", [0.5, 1.5]],
  )
}
