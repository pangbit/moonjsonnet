///|
test "foundation functions have no public default arguments" {
  for
    source in [
      "std.type()", "std.isNumber()", "std.abs()", "std.sign()", "std.min(1)", "std.max(1)",
      "std.pow(2)", "std.range(0)", "std.map(function(x)x)", "std.filter(function(x)true)",
      "std.type(1,2)", "std.isNumber(1,2)", "std.abs(1,2)", "std.sign(1,2)", "std.min(1,2,3)",
      "std.max(1,2,3)", "std.pow(1,2,3)", "std.range(0,1,2)", "std.map(function(x)x,[],0)",
      "std.filter(function(x)true,[],0)",
    ] {
    ignore(foundation_runtime_error(source))
  }
}

///|
test "foundation argument binding rejects unknown names without evaluating values" {
  let mut calls = 0
  let callback : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      calls += 1
      Json::number(17)
    },
  }
  for
    name in [
      "type", "isNumber", "abs", "sign", "min", "max", "pow", "range", "map", "filter",
    ] {
    try
      @moonjsonnet.evaluate(
        "std." + name + "(unknown=std.native('touch')())",
        native_functions=Map([("touch", callback)]),
      )
    catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
    } noraise {
      _ => fail("unknown parameter was accepted for " + name)
    }
    assert_eq(
      @moonjsonnet.evaluate(
        "if false then std." + name + "(unknown=std.native('touch')()) else 42",
        native_functions=Map([("touch", callback)]),
      ),
      42,
    )
    assert_eq(
      @moonjsonnet.evaluate("if false then std." + name + "() else 42"),
      42,
    )
    assert_eq(calls, 0)
  }
}

///|
test "foundation unselected calls keep invalid computations lazy" {
  for
    call in [
      "std.type(error 'unused')", "std.isNumber(error 'unused')", "std.abs(error 'unused')",
      "std.sign(error 'unused')", "std.min(error 'unused',0)", "std.max(0,error 'unused')",
      "std.pow(1e308,2)", "std.range(-1e308,1e308)", "std.map(function(x)error 'unused',[1])",
      "std.filter(function(x)error 'unused',[1])",
    ] {
    assert_eq(
      @moonjsonnet.evaluate(
        "local unused=" +
        call +
        "; [if false then " +
        call +
        " else 42,true || " +
        call +
        ",false && " +
        call +
        ",({hidden::" +
        call +
        ",good:42}).good,(function(unused)42)(" +
        call +
        ")]",
      ),
      [42, true, false, 42, 42],
    )
  }
}
