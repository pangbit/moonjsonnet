///|
test "foundation type returns every documented tag" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.type(x=null),std.type(false),std.type(1),std.type('你😀'),std.type([]),std.type({}),std.type(function()0)]",
    ),
    ["null", "boolean", "number", "string", "array", "object", "function"],
  )
}

///|
test "foundation isNumber accepts every value type and finite numeric boundaries" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.isNumber(v=null),std.isNumber(false),std.isNumber('1'),std.isNumber([]),std.isNumber({}),std.isNumber(function()0),std.isNumber(-0),std.isNumber(5e-324),std.isNumber(1.7976931348623157e308)]",
    ),
    [false, false, false, false, false, false, true, true, true],
  )
}

///|
test "foundation type and isNumber inspect no nested payload assertion or function" {
  assert_eq(
    @moonjsonnet.evaluate(
      "local a=[error 'payload']; local o={assert false,x:error 'field'}; local f(x=error 'default')=error 'body'; [std.type(a),std.type(o),std.type(f),std.isNumber(a),std.isNumber(o),std.isNumber(f)]",
    ),
    ["array", "object", "function", false, false, false],
  )
  let native : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => fail("type reflection called native function"),
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.type(std.native('f')),std.isNumber(std.native('f'))]",
      native_functions=Map([("f", native)]),
    ),
    ["function", false],
  )
}

///|
test "foundation type and isNumber demand the outer expression" {
  for source in ["std.type(error 'outer')", "std.isNumber(error 'outer')"] {
    assert_eq(foundation_runtime_error(source).message, "outer")
  }
}

///|
fn foundation_runtime_error(source : String) -> @moonjsonnet.Diagnostic raise {
  try @moonjsonnet.evaluate(source) catch {
    @moonjsonnet.Error(d) => {
      assert_true(d.kind == @moonjsonnet.Runtime || d.kind == @moonjsonnet.Type)
      d
    }
  } noraise {
    _ => fail("expected runtime/type failure: " + source)
  }
}
