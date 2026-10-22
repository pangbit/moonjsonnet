///|
test "substr selects codepoints and clips ordinary suffix boundaries" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.substr('你😀e\\u0301a',1,2),std.substr('你😀e\\u0301a',2,2),std.substr('',0,0),std.substr('abc',3,1),std.substr('abc',4,2),std.substr('abc',1e308,2)]",
    ),
    @json.parse("[\"😀e\",\"é\",\"\",\"\",\"\",\"\"]"),
  )
}

///|
test "substr clamps large finite lengths before allocation or integer conversion" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.substr('你😀a',1,2147483648),std.substr('abc',1,9007199254740992),std.substr('abc',1,1e308),std.substr('abc',1e308,1e308)]",
    ),
    ["😀a", "bc", "bc", ""],
  )
}

///|
test "substr empty generated sizes do not validate nonexistent character indices" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.substr('abc',0.5,0),std.substr('abc',-1,0),std.substr('abc',-0.5,0),std.substr('abc',4.5,1),std.substr('',0,0.5)]",
    ),
    ["", "", "", "", ""],
  )
}

///|
test "substr first type guard does not demand later arguments" {
  let mut calls = 0
  let visit : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      calls += 1
      Json::number(0)
    },
  }
  try
    @moonjsonnet.evaluate(
      "std.substr(null,std.native('visit')(),std.native('visit')())",
      native_functions=Map([("visit", visit)]),
    )
  catch {
    @moonjsonnet.Error(d) =>
      assert_true(
        d.kind == @moonjsonnet.Runtime || d.kind == @moonjsonnet.Assertion,
      )
  } noraise {
    _ => fail("expected first parameter guard error")
  }
  assert_eq(calls, 0)
}

///|
test "substr second type guard does not demand the length" {
  let mut calls = 0
  let visit : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      calls += 1
      Json::number(1)
    },
  }
  try
    @moonjsonnet.evaluate(
      "std.substr('abc',null,std.native('visit')())",
      native_functions=Map([("visit", visit)]),
    )
  catch {
    @moonjsonnet.Error(d) =>
      assert_true(
        d.kind == @moonjsonnet.Runtime || d.kind == @moonjsonnet.Assertion,
      )
  } noraise {
    _ => fail("expected second parameter guard error")
  }
  assert_eq(calls, 0)
}

///|
test "substr rejects needed type length and character-index errors" {
  for value in ["null", "true", "[]", "{}", "function()0"] {
    ignore(string_contract_error("std.substr(" + value + ",0,1)"))
    ignore(string_contract_error("std.substr('a'," + value + ",1)"))
    ignore(string_contract_error("std.substr('a',0," + value + ")"))
  }
  for
    source in [
      "std.substr('abc',0,-1)", "std.substr('',0,-0.5)", "std.substr('abc',0.5,1)",
      "std.substr('abc',-1,1)",
    ] {
    ignore(string_contract_error(source))
  }
}
