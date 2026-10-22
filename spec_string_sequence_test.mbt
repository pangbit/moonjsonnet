///|
test "stringChars splits Unicode codepoints and rejects primitive nonstrings" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.stringChars('你😀e\\u0301\\u0000'),std.stringChars('')]",
    ),
    @json.parse("[[\"你\",\"😀\",\"e\",\"́\",\"\\u0000\"],[]]"),
  )
  for value in ["null", "true", "1"] {
    ignore(string_contract_error("std.stringChars(" + value + ")"))
  }
}

///|
test "stringChars shares its required outer input across length and selections" {
  let mut calls = 0
  let input : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      calls += 1
      Json::string("你😀")
    },
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "local a=std.stringChars(std.native('input')()); [std.length(a),a[1],a[0],a[1]]",
      native_functions=Map([("input", input)]),
    ),
    [2, "😀", "你", "😀"],
  )
  assert_eq(calls, 1)
}

///|
test "findSubstr returns overlapping codepoint offsets and source empty boundaries" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.findSubstr('aa','aaaa'),std.findSubstr('😀','😀a😀'),std.findSubstr('e\\u0301','😀e\\u0301e\\u0301'),std.findSubstr('é','e\\u0301'),std.findSubstr('','a'),std.findSubstr('a',''),std.findSubstr('long','a')]",
    ),
    [[0, 1, 2], [0, 2], [1, 3], [], [], [], []],
  )
}

///|
test "findSubstr validates both string domains and stops before an unused haystack" {
  for value in ["null", "true", "1", "[]", "{}", "function()0"] {
    ignore(string_contract_error("std.findSubstr(" + value + ",'a')"))
    ignore(string_contract_error("std.findSubstr('a'," + value + ")"))
  }
  let mut calls = 0
  let input : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      calls += 1
      Json::string("text")
    },
  }
  try
    @moonjsonnet.evaluate(
      "std.findSubstr(0,std.native('input')())",
      native_functions=Map([("input", input)]),
    )
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
  } noraise {
    _ => fail("expected invalid pattern")
  }
  assert_eq(calls, 0)
}

///|
test "string prefix and suffix compare codepoint sequences including empties" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.startsWith('你😀a','你😀'),std.endsWith('你😀a','😀a'),std.startsWith('',''),std.endsWith('',''),std.startsWith('a',''),std.endsWith('a',''),std.startsWith('a','ab'),std.endsWith('a','ab'),std.startsWith('é','e\\u0301'),std.endsWith('e\\u0301','é'),std.startsWith('A','a')]",
    ),
    [true, true, true, true, true, true, false, false, false, false, false],
  )
}

///|
test "string prefix and suffix reject primitive length errors and needed outer errors" {
  for name in ["startsWith", "endsWith"] {
    for value in ["null", "true", "1"] {
      ignore(string_contract_error("std." + name + "(" + value + ",'a')"))
      ignore(string_contract_error("std." + name + "('a'," + value + ")"))
    }
    assert_eq(
      string_contract_error("std." + name + "(error 'first','a')").message,
      "first",
    )
    assert_eq(
      string_contract_error("std." + name + "('a',error 'second')").message,
      "second",
    )
  }
}
