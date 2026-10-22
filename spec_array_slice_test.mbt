///|
test "array slice explicit null defaults and named bounds preserve inputs" {
  assert_eq(
    @moonjsonnet.evaluate(
      "local a=[1,2,3,4]; [std.slice(step=2,end=null,index=1,indexable=a),std.slice(a,null,null,null),std.slice(a,-2,null,null),std.slice(a,-1e308,1e308,2),a,std.slice('你😀a',-2,null,null)]",
    ),
    [[2, 4], [1, 2, 3, 4], [3, 4], [1, 3], [1, 2, 3, 4], "😀a"],
  )
}

///|
test "array slice does not compute an unused overflowing progression" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.slice([error 'payload'],1e308,1.5e308,1e308),std.slice([7],0,1e308,1e308)]",
    ),
    [[], [7]],
  )
}

///|
test "array slice retains source validation even for empty input" {
  for
    source in [
      "std.slice([],null,null,0)", "std.slice([],null,null,-1)", "std.slice([],null,null,'1')",
      "std.slice([],true,null,1)", "std.slice([],null,'end',1)", "std.slice(1,null,null,1)",
      "std.slice({},null,null,1)",
    ] {
    ignore(array_contract_error(source))
  }
  assert_eq(
    array_contract_error("std.slice([],0,error 'end',1)").message,
    "end",
  )
}

///|
test "array slice shares selected thunks once and does not mutate its input" {
  let mut calls = 0
  let visit : @moonjsonnet.NativeFunction = {
    params: ["i"],
    callback: args => {
      calls += 1
      args[0]
    },
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "local a=std.makeArray(3,function(i)std.native('visit')(i)); local b=std.slice(a,1,null,1); [std.length(b),b[0],a[1],b[0],std.length(a)]",
      native_functions=Map([("visit", visit)]),
    ),
    [2, 1, 1, 1, 3],
  )
  assert_eq(calls, 1)
}

///|
test "array combinators have required parameters and reject unbound names lazily" {
  for
    source in [
      "std.makeArray(1)", "std.foldl(function(a,b)a,[])", "std.foldr(function(a,b)a,[])",
      "std.flatMap(function(x)[])", "std.slice([],0,1)", "std.makeArray(0,function(i)i,1)",
      "std.foldl(function(a,b)a,[],0,1)", "std.foldr(function(a,b)a,[],0,1)", "std.flatMap(function(x)[],[],0)",
      "std.slice([],0,1,1,0)",
    ] {
    ignore(array_contract_error(source))
  }
  let mut calls = 0
  let visit : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      calls += 1
      Json::number(0)
    },
  }
  for name in ["makeArray", "foldl", "foldr", "flatMap", "slice"] {
    try
      @moonjsonnet.evaluate(
        "std." + name + "(unknown=std.native('visit')())",
        native_functions=Map([("visit", visit)]),
      )
    catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
    } noraise {
      _ => fail("unknown parameter accepted")
    }
    assert_eq(
      @moonjsonnet.evaluate("if false then std." + name + "() else 42"),
      42,
    )
    assert_eq(calls, 0)
  }
}
