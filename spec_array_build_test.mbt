///|
test "array makeArray uses integer indices named arguments and callback defaults" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.makeArray(func=function(i)i*i,sz=3),std.makeArray(0,function(i)error 'body'),std.makeArray(-0,function(i)i),std.makeArray(2,function(i=error 'default')i),std.type(std.makeArray(1,function(i)function()error 'body')[0])]",
    ),
    [[0, 1, 4], [], [], [0, 1], "function"],
  )
}

///|
test "array makeArray validates size and function heads even at zero" {
  for value in ["null", "true", "'2'", "[]", "{}", "function()0"] {
    ignore(array_contract_error("std.makeArray(" + value + ",function(i)i)"))
  }
  for value in ["null", "true", "'2'", "[]", "{}"] {
    ignore(array_contract_error("std.makeArray(0," + value + ")"))
  }
  assert_eq(
    array_contract_error("std.makeArray(0,error 'function head')").message,
    "function head",
  )
}

///|
test "array makeArray defers callback bodies and initializes in demand order once" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.length(std.makeArray(3,function(i)error 'body')),std.makeArray(3,function(i)if i==1 then 21 else error 'unused')[1]]",
    ),
    [3, 21],
  )
  let seen : Array[Json] = []
  let callback : @moonjsonnet.NativeFunction = {
    params: ["i"],
    callback: args => {
      seen.push(args[0])
      args[0]
    },
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "local a=std.makeArray(3,function(i)std.native('visit')(i)); [std.length(a),a[2],a[0],a[2]]",
      native_functions=Map([("visit", callback)]),
    ),
    [3, 2, 0, 2],
  )
  assert_eq(Json::array(seen), [2, 0])
}

///|
test "array makeArray allocation limit does not run initializer bodies" {
  let mut calls = 0
  let callback : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      calls += 1
      Json::number(0)
    },
  }
  let program = @moonjsonnet.Program::parse(
    "std.length(std.makeArray(1000000,function(i)std.native('visit')()))",
    filename="make-array-limit.jsonnet",
  )
  try
    program.evaluate(
      limits={ ..@moonjsonnet.Limits::default(), steps: 5000, },
      native_functions=Map([("visit", callback)]),
    )
  catch {
    @moonjsonnet.Error(d) => {
      assert_eq(d.kind, @moonjsonnet.Limit)
      assert_eq(d.location.file, "make-array-limit.jsonnet")
    }
  } noraise {
    _ => fail("expected constructor allocation limit")
  }
  assert_eq(calls, 0)
}

///|
fn array_contract_error(source : String) -> @moonjsonnet.Diagnostic raise {
  try @moonjsonnet.evaluate(source) catch {
    @moonjsonnet.Error(d) => {
      assert_true(
        d.kind == @moonjsonnet.Runtime ||
        d.kind == @moonjsonnet.Type ||
        d.kind == @moonjsonnet.Assertion,
      )
      d
    }
  } noraise {
    _ => fail("expected runtime/type/assertion failure: " + source)
  }
}
