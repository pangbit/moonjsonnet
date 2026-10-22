// Normative sources are pinned to google/jsonnet
// bbb38f1020be1f5aed560928fb839b2c448cefb4. See the P0 matrix in
// docs/development/SPEC-CONFORMANCE.md. Inputs are synthetic and public.

///|
test "P0 YAML propagates nested errors and rejects function values" {
  for
    source in [
      "std.manifestYamlDoc({a:[1,error 'nested']})", "std.manifestYamlDoc({a:{b:error 'nested'}})",
      "std.manifestYamlStream([{a:1},{b:[error 'nested']}])", "std.manifestYamlDoc(function()0)",
      "std.manifestYamlDoc({a:function(x)x})", "std.manifestYamlDoc([1,std.id])",
      "std.manifestYamlStream([{},function()0])",
    ] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
    } noraise {
      _ => fail("expected YAML error: " + source)
    }
  }
}
