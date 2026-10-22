///|
test "array flatMap returns flattened arrays or concatenated Unicode strings" {
  assert_eq(
    @moonjsonnet.evaluate(
      "local a=[1,2,3]; [std.flatMap(arr=a,func=function(x)if x==2 then [] else [x,x]),a,std.flatMap(function(c)c+c,'你😀'),std.flatMap(function(x)error 'body',[]),std.flatMap(function(c)error 'body','')]",
    ),
    [[1, 1, 3, 3], [1, 2, 3], "你你😀😀", [], ""],
  )
}

///|
test "array flatMap validates the function before demanding its input" {
  let mut reads = 0
  let input : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      reads += 1
      Json::array([])
    },
  }
  try
    @moonjsonnet.evaluate(
      "std.flatMap(0,std.native('input')())",
      native_functions=Map([("input", input)]),
    )
  catch {
    @moonjsonnet.Error(d) =>
      assert_true(d.kind == @moonjsonnet.Type || d.kind == @moonjsonnet.Runtime)
  } noraise {
    _ => fail("nonfunction callback accepted")
  }
  assert_eq(reads, 0)
}

///|
test "array flatMap demands callback heads but keeps result payloads lazy" {
  assert_eq(
    array_contract_error("std.type(std.flatMap(function(x)error 'body',[1]))").message,
    "body",
  )
  assert_eq(
    array_contract_error("std.flatMap(error 'function',[])").message,
    "function",
  )
  assert_eq(
    @moonjsonnet.evaluate(
      "std.flatMap(function(unused)[],[error 'unused input'])",
    ),
    [],
  )
  let seen : Array[Json] = []
  let visit : @moonjsonnet.NativeFunction = {
    params: ["x"],
    callback: args => {
      seen.push(args[0])
      Json::boolean(true)
    },
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "local a=[1,2]; local b=std.flatMap(function(x)if std.native('visit')(x) then [error 'payload'] else [],a); [std.length(b),a]",
      native_functions=Map([("visit", visit)]),
    ),
    [2, [1, 2]],
  )
  assert_eq(Json::array(seen), [1, 2])
}

///|
test "array flatMap string callbacks traverse codepoints in order" {
  let seen : Array[Json] = []
  let visit : @moonjsonnet.NativeFunction = {
    params: ["c"],
    callback: args => {
      seen.push(args[0])
      args[0]
    },
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "std.flatMap(function(c)std.native('visit')(c),'你😀')",
      native_functions=Map([("visit", visit)]),
    ),
    Json::string("你😀"),
  )
  assert_eq(Json::array(seen), ["你", "😀"])
}

///|
test "array flatMap rejects invalid sequences and numeric callback results" {
  for value in ["null", "true", "1", "{}", "function()0"] {
    ignore(array_contract_error("std.flatMap(function(x)[]," + value + ")"))
  }
  for
    source in [
      "std.flatMap(function(x)1,[1])", "std.flatMap(function(x)1,'a')", "std.flatMap(function()[],[1])",
    ] {
    ignore(array_contract_error(source))
  }
}
