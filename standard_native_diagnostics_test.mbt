///|
test "standard error messages preserve types and raw byte offsets" {
  for
    (source, expected) in [
      ("std.avg([])", "Cannot calculate average of an empty array."),
      ("std.substr('x',-1.0000005,1)", "Index must be a finite integer"),
      (
        "std.base64DecodeBytes('AAAAéxx')", "failed to decode: illegal base64 data at input byte 4",
      ),
      (
        "std.base64DecodeBytes('AA=\\n')", "failed to decode: illegal base64 data at input byte 4",
      ),
      ("std.maxArray([{},{}])", "Unexpected type object"),
      (
        "std.manifestJsonEx({a:[function(x)x]},'')", "tried to manifest function at [a 0]",
      ),
      (
        "std.manifestToml({a:[1,{b:null}]})", "Tried to manifest \"null\" at [a 1 b]",
      ),
      (
        "std.parseYaml('{a: &anchor [*anchor]}')", "failed to parse YAML: error converting YAML to JSON: yaml: anchor 'anchor' value contains itself",
      ),
    ] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_eq(d.message, expected)
    } noraise {
      _ => fail("expected native error")
    }
  }
}

///|
test "source standard formatting and YAML retain laziness and explicit budgets" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.isString('x'),std.split('x','x'),'%s'%1, std.base64DecodeBytes('Zg==\\r\\n\\r\\n')]",
    ).stringify(),
    "[true,[\"\",\"\"],\"1\",[102]]",
  )
  let limits = @moonjsonnet.Limits::default()
  for source in ["std.parseYaml('&a [*a]')", "std.format('%1000s','x')"] {
    try @moonjsonnet.evaluate(source, limits={ ..limits, steps: 20, }) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
    } noraise {
      _ => fail("expected bounded evaluation")
    }
  }
}
