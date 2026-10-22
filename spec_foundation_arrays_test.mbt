///|
test "foundation range follows inclusive unit steps and required named parameters" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.range(to=2,from=-1),std.range(2,2),std.range(2,1)]",
    ),
    [[-1, 0, 1, 2], [2], []],
  )
}

///|
test "foundation range supports integral-sized fractional intervals" {
  assert_eq(
    @moonjsonnet.evaluate("[std.range(0.5,2.5),std.range(-2.5,-0.5)]"),
    [[0.5, 1.5, 2.5], [-2.5, -1.5, -0.5]],
  )
}

///|
test "foundation range does not narrow large finite endpoints" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.range(2147483648,2147483650),std.range(1e308,1e308),std.range(-1e308,-1e308)]",
    ),
    [[2147483648.0, 2147483649.0, 2147483650.0], [1.0e308], [-1.0e308]],
  )
  let mut starts = 0
  let callback : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      starts += 1
      Json::number(2147483648.0)
    },
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "local a=std.range(std.native('start')(),2147483649); local b=a[:]; [std.length(a),a[0],a[1],b[0],a[0]]",
      native_functions=Map([("start", callback)]),
    ),
    [2, 2147483648.0, 2147483649.0, 2147483648.0, 2147483648.0],
  )
  assert_eq(starts, 1)
}

///|
test "foundation range rejects operand type errors and producing overflow" {
  for value in ["null", "true", "'1'", "[]", "{}", "function()0"] {
    ignore(foundation_runtime_error("std.range(" + value + ",2)"))
    ignore(foundation_runtime_error("std.range(0," + value + ")"))
  }
  assert_eq(
    foundation_runtime_error("std.range(-1e308,1e308)").kind,
    @moonjsonnet.Runtime,
  )
}

///|
test "foundation map maps arrays and Unicode strings with unchanged inputs" {
  assert_eq(
    @moonjsonnet.evaluate(
      "local a=[1,2,3]; [std.map(arr=a,func=function(x)x*x),a,std.map(function(c)c+c,'你😀'),std.map(function(x)error 'unused',[]),std.map(function(x)error 'unused','')]",
    ),
    [[1, 4, 9], [1, 2, 3], ["你你", "😀😀"], [], []],
  )
  assert_eq(@moonjsonnet.evaluate("std.map(function(x)1,'你😀')"), [1, 1])
}

///|
test "foundation map validates function sequence and demanded callback results" {
  for
    source in [
      "std.map(1,[])", "std.map(function(x)x,{})", "std.map(function(x)x,0)", "std.map(function(x)x,null)",
      "std.map(function(x)error 'called',[1])[0]", "std.map(function()0,[1])[0]",
    ] {
    ignore(foundation_runtime_error(source))
  }
}

///|
test "foundation map delays payloads callbacks and unused result elements" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.length(std.map(function(x)error 'callback',[error 'element'])),std.map(function(unused)42,[error 'element'])[0],std.map(function(x)x,[7,error 'unused'])[0],std.type(std.map(function(x)error 'unused',[1])),std.length(std.map(function(x)error 'unused','你😀'))]",
    ),
    [1, 42, 7, "array", 2],
  )
  let mut calls = 0
  let callback : @moonjsonnet.NativeFunction = {
    params: ["value"],
    callback: args => {
      calls += 1
      args[0]
    },
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "local a=[10,20]; local b=std.map(function(x)std.native('once')(x),a); [std.length(b),b[0],b[0],a]",
      native_functions=Map([("once", callback)]),
    ),
    [2, 10, 10, [10, 20]],
  )
  assert_eq(calls, 1)
}

///|
test "foundation filter selects original elements with unchanged input" {
  assert_eq(
    @moonjsonnet.evaluate(
      "local a=[1,2,3,4]; [std.filter(arr=a,func=function(x)x%2==0),a,std.filter(function(x)error 'unused',[]),std.filter(function(x)true,[{x:1}]) ]",
    ),
    [[2, 4], [1, 2, 3, 4], [], [{ "x": 1 }]],
  )
}

///|
test "foundation filter requires array function and boolean predicate" {
  for
    source in [
      "std.filter(1,[])", "std.filter(function(x)true,'')", "std.filter(function(x)true,{})",
      "std.filter(function(x)true,null)", "std.filter(function(x)0,[1])", "std.filter(function(x)error 'predicate',[1])",
      "std.filter(function()true,[1])",
    ] {
    ignore(foundation_runtime_error(source))
  }
}

///|
test "foundation filter evaluates predicates without forcing unused payloads" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.filter(function(unused)false,[error 'unused']),std.length(std.filter(function(unused)true,[error 'retained'])),std.filter(function(x)x.k,[{k:false,bad:error 'unused'},{k:true,value:7}])[0].value]",
    ),
    [[], 1, 7],
  )
  let mut predicates = 0
  let callback : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      predicates += 1
      Json::boolean(true)
    },
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "local a=[error 'retained',7]; local b=std.filter(function(unused)std.native('keep')(),a); [std.length(b),b[1],a[1],std.length(a)]",
      native_functions=Map([("keep", callback)]),
    ),
    [2, 7, 7, 2],
  )
  assert_eq(predicates, 2)
}
