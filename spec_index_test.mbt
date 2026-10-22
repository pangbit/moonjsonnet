// Normative sources are pinned to google/jsonnet
// bbb38f1020be1f5aed560928fb839b2c448cefb4. See the P0 matrix in
// docs/development/SPEC-CONFORMANCE.md. Inputs are synthetic and public.

///|
test "P0 indices require integers before conversion for arrays and Unicode strings" {
  for
    source in [
      "[10,20][0.5]", "[10,20][-0.5]", "'你😀a'[1.5]", "'你😀a'[-0.5]", "[error 'element must stay lazy'][0.5]",
      "[1][1e300]", "[1][-1e300]", "[][0]", "'你😀a'[3]", "[10,20][2]",
    ] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Runtime)
        assert_true(d.message != "element must stay lazy")
      }
    } noraise {
      _ => fail("expected index error: " + source)
    }
  }
  assert_eq(
    @moonjsonnet.evaluate("[[10,20][0],[10,20][1.0],[10][-0.0],'你😀a'[1]]"),
    @json.parse("[10,20,10,\"😀\"]"),
  )
}

///|
test "P0 slicing defers array indexing and keeps strings strict" {
  for
    (source, expected) in [
      ("std.length([0,1,2][0.5:2.5:0.5])", "4"),
      ("std.length(std.slice([0,1,2],0.5,2.5,0.5))", "4"),
      ("[0,1,2][::0.5][0]", "0"),
      ("[0,1,2][:1.5]", "[0,1]"),
      ("std.length([error 'unused',1][::0.5])", "4"),
      ("'你😀a'[3.5:]", "\"\""),
    ] {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
  for
    source in [
      "[0,1,2][0.5:2.5:0.5][0]", "[0,1,2][::0.5][1]", "std.length('你😀a'[0.5:2.5:0.5])",
    ] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
    } noraise {
      _ => fail("expected forced slice index error: " + source)
    }
  }
}
