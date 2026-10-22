///|
test "foundation abs uses the fixed numeric definition" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.abs(n=-3.5),std.abs(3.5),std.abs(0),std.abs(-0),std.abs(-5e-324),std.abs(-1.7976931348623157e308)]",
    ),
    [3.5, 3.5, 0, 0, 5.0e-324, 1.7976931348623157e308],
  )
}

///|
test "foundation sign uses the fixed numeric definition" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.sign(n=-1.7976931348623157e308),std.sign(-5e-324),std.sign(0),std.sign(-0),std.sign(5e-324),std.sign(1.7976931348623157e308)]",
    ),
    [-1, -1, 0, 0, 1, 1],
  )
}

///|
test "foundation min compares finite values without narrowing" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.min(b=3,a=-2),std.min(2,2),std.min(-0,0),std.min(-1.7976931348623157e308,1.7976931348623157e308),std.min(-5e-324,0)]",
    ),
    [-2, 2, 0, -1.7976931348623157e308, -5.0e-324],
  )
}

///|
test "foundation max compares finite values without narrowing" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.max(b=3,a=-2),std.max(2,2),std.max(0,-0),std.max(-1.7976931348623157e308,1.7976931348623157e308),std.max(5e-324,0)]",
    ),
    [3, 2, 0, 1.7976931348623157e308, 5.0e-324],
  )
}

///|
test "foundation pow covers finite real values and underflow" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.pow(n=10,x=2),std.pow(-2,3),std.pow(-2,4),std.pow(4,0.5),std.pow(2,-3),std.pow(2,0),std.pow(0,3),std.pow(1e308,1),std.pow(1e-300,2)]",
    ),
    [1024, -8, 16, 2, 0.125, 1, 0, 1.0e308, 0],
  )
}

///|
test "foundation numeric functions reject all nonnumeric value types" {
  for value in ["null", "true", "'1'", "[]", "{}", "function()0"] {
    for name in ["abs", "sign"] {
      ignore(foundation_runtime_error("std." + name + "(" + value + ")"))
    }
    for name in ["min", "max", "pow"] {
      ignore(foundation_runtime_error("std." + name + "(" + value + ",2)"))
      ignore(foundation_runtime_error("std." + name + "(2," + value + ")"))
    }
  }
}

///|
test "foundation min and max stop before the second argument when the first is invalid" {
  for name in ["min", "max"] {
    let error = foundation_runtime_error(
      "std." + name + "('bad',error 'second was forced')",
    )
    assert_true(error.message != "second was forced")
  }
}

///|
test "foundation pow rejects nonfinite results at the producing expression" {
  for
    source in [
      "std.pow(1e308,2)", "std.type(std.pow(1e308,2))", "std.isNumber(std.pow(1e308,2))",
      "std.pow(-1,0.5)", "std.pow(0,-1)", "std.abs(std.pow(1e308,2))", "std.sign(std.pow(1e308,2))",
      "std.min(0,std.pow(1e308,2))", "std.max(0,std.pow(1e308,2))",
    ] {
    assert_eq(foundation_runtime_error(source).kind, @moonjsonnet.Runtime)
  }
}

///|
test "foundation numeric operations demand their needed arguments" {
  for
    source in [
      "std.abs(error 'needed')", "std.sign(error 'needed')", "std.min(1,error 'needed')",
      "std.max(error 'needed',1)", "std.pow(error 'needed',2)", "std.pow(2,error 'needed')",
    ] {
    assert_eq(foundation_runtime_error(source).message, "needed")
  }
}
