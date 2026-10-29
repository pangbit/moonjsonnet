///|
test "manifest numbers use ordinary numeric String coercion text" {
  let cases = [
    ("0.1", "0.10000000000000001"),
    ("-0", "-0"),
    ("0", "0"),
    ("1e-8", "1e-08"),
    ("-1.23e-7", "-1.23e-07"),
    ("1e21", "1" + "0".repeat(21)),
    ("1.234e30", "1233999999999999958672482500608"),
    ("1.2345678901234567", "1.2345678901234567"),
    ("1000000000000000100", "1000000000000000128"),
    ("5e-324", "4.9406564584124654e-324"),
    ("-5e-324", "-4.9406564584124654e-324"),
    (
      "1.7976931348623157e308", "179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858368",
    ),
  ]
  for (source, expected) in cases {
    assert_eq(
      @moonjsonnet.evaluate("std.manifestJson(\{source})"),
      Json::string(expected),
    )
  }
}

///|
test "nested manifests retain sorting visibility and coercion number text" {
  assert_eq(
    @moonjsonnet.evaluate(
      "std.manifestJson({z::error 'hidden',b:-0,a:[0.1,1e-8]})",
    ),
    Json::string(
      "{\n    \"a\": [\n        0.10000000000000001,\n        1e-08\n    ],\n    \"b\": -0\n}",
    ),
  )
}

///|
test "string coercion keeps its separate numeric representation" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.toString(0.1),std.toString(1e-8),std.toString(-0),std.toString({x:0.1}),'x'+0.1,'%s'%0.1]",
    ),
    @json.parse(
      "[\"0.10000000000000001\",\"1e-08\",\"-0\",\"{\\\"x\\\": 0.10000000000000001}\",\"x0.10000000000000001\",\"0.10000000000000001\"]",
    ),
  )
}

///|
test "scientific manifest numbers respect the intermediate output limit" {
  let limits = @moonjsonnet.Limits::default()
  let source = "std.length(std.manifestJson(5e-324))"
  assert_eq(
    @moonjsonnet.evaluate(source, limits={ ..limits, output_bytes: 23, }),
    Json::number(23),
  )
  try
    @moonjsonnet.evaluate(source, limits={ ..limits, output_bytes: 22, })
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected scientific number output limit")
  }
}
