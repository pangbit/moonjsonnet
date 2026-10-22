// Normative sources are pinned to google/jsonnet
// bbb38f1020be1f5aed560928fb839b2c448cefb4. See the P0 matrix in
// docs/development/SPEC-CONFORMANCE.md. Inputs are synthetic and public.

///|
test "P0 aggregate overflow errors when the operation is evaluated" {
  for
    source in [
      "std.sum([1e308,1e308])", "std.avg([-1e308,-1e308])", "local inf=std.sum([1e308,1e308]); std.sum([inf,-inf])",
      "std.sum([1e308,1e308]) > 0", "std.type(std.sum([1e308,1e308]))", "std.avg([1e308,1e308,-1e308])",
      "std.manifestJson(std.sum([1e308,1e308]))",
    ] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
    } noraise {
      _ => fail("expected overflow error: " + source)
    }
  }
  // The first invalid addition must fail before a later operand is forced,
  // even if a later finite operand would cancel the overflowing sum.
  try
    @moonjsonnet.evaluate("std.sum([1e308,1e308,error 'later operand'])")
  catch {
    @moonjsonnet.Error(d) => {
      assert_eq(d.kind, @moonjsonnet.Runtime)
      assert_true(d.message != "later operand")
      assert_true(d.message.contains("Overflow"))
    }
  } noraise {
    _ => fail("expected overflow at the addition")
  }
}

///|
test "P0 lazy boundaries and finite aggregate results remain valid" {
  for
    (source, expected) in [
      ("local unused=std.sum([1e308,1e308]); 42", "42"),
      ("false && std.sum([1e308,1e308]) > 0", "false"),
      ("true || std.sum([1e308,1e308]) > 0", "true"),
      ("{bad::std.sum([1e308,1e308]),good:1}", "{\"good\":1}"),
      ("if false then [10,20][0.5] else 42", "42"),
      ("std.length(std.removeAt([error 'unused',2],1))", "1"),
      ("std.length(std.remove([1,error 'unused'],1))", "1"),
      (
        "[std.sum([]),std.sum([1,2,3]),std.avg([1,2,3]),std.sum([1e308,-1e308])]",
        "[0,6,2,0]",
      ),
      ("local unused=std.manifestYamlDoc({a:error 'unused'}); 42", "42"),
      (
        "std.manifestYamlDoc({hidden::error 'unused',a:[1,2]})", "\"\\\"a\\\":\\n- 1\\n- 2\"",
      ),
    ] {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
}
