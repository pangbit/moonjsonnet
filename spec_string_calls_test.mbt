///|
fn string_contract_error(source : String) -> @moonjsonnet.Diagnostic raise {
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
    _ => fail("expected string-contract runtime failure: " + source)
  }
}

///|
test "string public signatures have required parameters and documented names" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.char(n=128512),std.codepoint(str='😀'),std.substr(len=2,from=1,str='你😀a'),std.findSubstr(str='😀a😀',pat='😀'),std.stringChars(str='你😀'),std.startsWith(b='你',a='你😀'),std.endsWith(b='😀',a='你😀')]",
    ),
    ["😀", 128512, "😀a", [0, 2], ["你", "😀"], true, true],
  )
  for
    source in [
      "std.char()", "std.codepoint()", "std.substr('a',0)", "std.findSubstr('a')",
      "std.stringChars()", "std.startsWith('a')", "std.endsWith('a')", "std.char(1,2)",
      "std.codepoint('a',2)", "std.substr('a',0,1,2)", "std.findSubstr('a','a',2)",
      "std.stringChars('a',2)", "std.startsWith('a','a',2)", "std.endsWith('a','a',2)",
    ] {
    assert_eq(string_contract_error(source).kind, @moonjsonnet.Runtime)
  }
}

///|
test "string public binding rejects unknown names before their values" {
  let mut calls = 0
  let visit : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      calls += 1
      Json::number(0)
    },
  }
  for
    name in [
      "char", "codepoint", "substr", "findSubstr", "stringChars", "startsWith", "endsWith",
    ] {
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
  }
  assert_eq(calls, 0)
}

///|
test "unselected string and Unicode calls preserve language laziness" {
  for
    call in [
      "std.char(0.5)", "std.codepoint(error 'unused')", "std.substr(error 'unused',0,1)",
      "std.findSubstr(error 'unused','a')", "std.stringChars(error 'unused')", "std.startsWith(error 'unused','a')",
      "std.endsWith('a',error 'unused')",
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
        ",value:42}).value,(function(unused)42)(" +
        call +
        ")]",
      ),
      [42, true, false, 42, 42],
    )
  }
}
