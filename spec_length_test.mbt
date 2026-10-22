// Fixed stdlib.html#std-length says parameter count, including parameters
// with defaults. The core specification omits a function-length rule; it does
// not define a competing required-only count.

///|
test "function length counts all declared parameters without forcing defaults" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.length(function(a,b=1)a),std.length(function(a=error 'unused',b=2)a),std.length(function()error 'body'),std.length({method(x,y=0):x}.method)]",
    ),
    [2, 2, 0, 2],
  )
  assert_eq(
    @moonjsonnet.evaluate("local f(a,b=error 'unused')=a; [std.length(f),f(7)]"),
    [2, 7],
  )
}

///|
test "function length includes source and builtin optional parameters" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.length(std.sort),std.length(std.minArray),std.length(std.maxArray),std.length(std.manifestJsonEx),std.length(std.manifestYamlDoc),std.length(std.manifestYamlStream),std.length(std.get)]",
    ),
    [2, 3, 3, 4, 3, 4, 4],
  )
}

///|
test "length keeps native functions and nonfunction contracts separate" {
  let native : @moonjsonnet.NativeFunction = {
    params: ["a", "b"],
    callback: _ => fail("length must not call the native function"),
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.length(std.native('f')),std.length([error 'unused']),std.length('你😀'),std.length({a:1,h::error 'hidden'})]",
      native_functions=Map([("f", native)]),
    ),
    [2, 1, 2, 1],
  )
  for
    source in [
      "std.length(null)", "std.length(true)", "std.length(false)", "std.length(1)",
    ] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Type)
    } noraise {
      _ => fail("expected length type error")
    }
  }
}

///|
test "length reflection keeps call defaults overrides and argument laziness" {
  assert_eq(
    @moonjsonnet.evaluate(
      "local f(a,b=3)=a+b; [std.length(f),f(7),f(7,4),f(a=7,b=4),(function(unused)42)(error 'unforced')]",
    ),
    [2, 10, 11, 11, 42],
  )
  let mut defaults = 0
  let callback : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      defaults += 1
      5
    },
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "local f(x=std.native('default')())=x; [std.length(f),f(),f(7)]",
      native_functions=Map([("default", callback)]),
    ),
    [1, 5, 7],
  )
  assert_eq(defaults, 1)
}
