///|
test "manifest numbers use shortest fixed decimal text" {
  let cases = [
    ("0.1", "0.1"),
    ("-0", "-0"),
    ("0", "0"),
    ("1e-8", "0.00000001"),
    ("-1.23e-7", "-0.000000123"),
    ("1e21", "1" + "0".repeat(21)),
    ("1.234e30", "1234" + "0".repeat(27)),
    ("1.2345678901234567", "1.2345678901234567"),
    ("1000000000000000100", "1000000000000000100"),
    ("5e-324", "0." + "0".repeat(323) + "5"),
    ("-5e-324", "-0." + "0".repeat(323) + "5"),
    ("1.7976931348623157e308", "17976931348623157" + "0".repeat(292)),
  ]
  for (source, expected) in cases {
    assert_eq(
      @moonjsonnet.evaluate("std.manifestJson(\{source})"),
      Json::string(expected),
    )
  }
}

///|
test "nested manifests retain sorting visibility and shortest numbers" {
  assert_eq(
    @moonjsonnet.evaluate(
      "std.manifestJson({z::error 'hidden',b:-0,a:[0.1,1e-8]})",
    ),
    Json::string(
      "{\n    \"a\": [\n        0.1,\n        0.00000001\n    ],\n    \"b\": -0\n}",
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
test "expanded manifest numbers respect the intermediate output limit" {
  let limits = @moonjsonnet.Limits::default()
  let source = "std.length(std.manifestJson(5e-324))"
  assert_eq(
    @moonjsonnet.evaluate(source, limits={ ..limits, output_bytes: 326, }),
    Json::number(326),
  )
  try
    @moonjsonnet.evaluate(source, limits={ ..limits, output_bytes: 325, })
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected expanded number output limit")
  }
}
