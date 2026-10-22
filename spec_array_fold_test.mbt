///|
test "array folds use documented order named arguments and Unicode sequences" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.foldl(init=10,arr=[1,2,3],func=function(a,b)a-b),std.foldr(init=0,func=function(x,a)x-a,arr=[1,2,3]),std.foldl(function(a,c)a+c,'你😀',''),std.foldr(function(c,a)a+c,'你😀',''),std.foldl(function(a=7,b=9)a+b,[1,2],0)]",
    ),
    [4, 2, "你😀", "😀你", 3],
  )
}

///|
test "array foldl empty input never uses its callback" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.foldl(error 'unused function',[],42),std.foldl(error 'unused function','',42)]",
    ),
    [42, 42],
  )
  assert_eq(
    array_contract_error("std.foldl(error 'function',[],error 'initial')").message,
    "initial",
  )
}

///|
test "array foldr empty input never uses its callback" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.foldr(error 'unused function',[],42),std.foldr(error 'unused function','',42)]",
    ),
    [42, 42],
  )
  assert_eq(
    array_contract_error("std.foldr(error 'function',[],error 'initial')").message,
    "initial",
  )
}

///|
test "array foldl allows its first callback to ignore the initial thunk" {
  assert_eq(
    @moonjsonnet.evaluate(
      "std.foldl(function(a,b)b,[1,2],error 'unused initial')",
    ),
    2,
  )
  let mut initialized = 0
  let init : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      initialized += 1
      Json::number(0)
    },
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "std.foldl(function(a,b)b,[1,2],std.native('init')())",
      native_functions=Map([("init", init)]),
    ),
    2,
  )
  assert_eq(initialized, 0)
}

///|
test "array foldr allows its first callback to ignore the initial thunk" {
  assert_eq(
    @moonjsonnet.evaluate(
      "std.foldr(function(x,a)x,[1,2],error 'unused initial')",
    ),
    1,
  )
  let mut initialized = 0
  let init : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      initialized += 1
      Json::number(0)
    },
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "std.foldr(function(x,a)x,[1,2],std.native('init')())",
      native_functions=Map([("init", init)]),
    ),
    1,
  )
  assert_eq(initialized, 0)
}

///|
test "array folds retain strict intermediate heads and lazy nested payloads" {
  for
    source in [
      "std.foldl(function(a,x)if x==2 then error 'middle' else 42,[1,2,3],0)", "std.foldr(function(x,a)if x==2 then error 'middle' else 42,[1,2,3],0)",
    ] {
    assert_eq(array_contract_error(source).message, "middle")
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.type(std.foldl(function(a,x){assert false,value:x},[1],0)),std.length(std.foldr(function(x,a)[error 'payload'],[1],0)),std.foldl(function(a,unused)a,[error 'element'],7),std.foldr(function(unused,a)a,[error 'element'],7)]",
    ),
    ["object", 1, 7, 7],
  )
}

///|
test "array folds callback traversal follows left and right order" {
  for
    (name, func, expected) in [
      ("foldl", "function(a,x)std.native('visit')(x)+a", "[1,2,3]"),
      ("foldr", "function(x,a)std.native('visit')(x)+a", "[3,2,1]"),
    ] {
    let seen : Array[Json] = []
    let callback : @moonjsonnet.NativeFunction = {
      params: ["x"],
      callback: args => {
        seen.push(args[0])
        args[0]
      },
    }
    assert_eq(
      @moonjsonnet.evaluate(
        "std." + name + "(" + func + ",[1,2,3],0)",
        native_functions=Map([("visit", callback)]),
      ),
      6,
    )
    assert_eq(Json::array(seen), @json.parse(expected))
  }
}

///|
test "array folds preserve source and initial arrays" {
  assert_eq(
    @moonjsonnet.evaluate(
      "local a=[1,2]; local init=[0]; [std.foldl(function(acc,x)acc+[x],a,init),std.foldr(function(x,acc)[x]+acc,a,init),a,init]",
    ),
    [[0, 1, 2], [1, 2, 0], [1, 2], [0]],
  )
}

///|
test "array folds reject demanded callback sequence and initial errors" {
  for name in ["foldl", "foldr"] {
    for value in ["null", "true", "1"] {
      ignore(
        array_contract_error("std." + name + "(function(a,b)a," + value + ",0)"),
      )
      ignore(array_contract_error("std." + name + "(" + value + ",[1],0)"))
    }
    ignore(
      array_contract_error(
        "std." + name + "(function(a,b)a,[],error 'initial')",
      ),
    )
    ignore(array_contract_error("std." + name + "(function()0,[1],0)"))
  }
}
