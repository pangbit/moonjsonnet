///|
fn object_contract_error(source : String) -> @moonjsonnet.Diagnostic raise {
  try @moonjsonnet.evaluate(source) catch {
    @moonjsonnet.Error(d) => d
  } noraise {
    _ => fail("expected object-contract failure: " + source)
  }
}

///|
test "object contracts require documented arguments and reject excess arguments" {
  for
    source in [
      "std.objectHas({})", "std.objectHasAll({})", "std.objectFields()", "std.objectFieldsAll()",
      "std.objectValues()", "std.get({})", "std.objectHas({},'x',true)", "std.objectHasAll({},'x',true)",
      "std.objectFields({},true)", "std.objectFieldsAll({},true)", "std.objectValues({},true)",
      "std.get({},'x',null,true,0)",
    ] {
    assert_eq(object_contract_error(source).kind, @moonjsonnet.Runtime)
  }
}

///|
test "object contract binding errors do not evaluate rejected arguments or unused calls" {
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
      "objectHas", "objectHasAll", "objectFields", "objectFieldsAll", "get", "objectValues",
    ] {
    try
      @moonjsonnet.evaluate(
        "std." + name + "(unknown=std.native('visit')())",
        native_functions=Map([("visit", visit)]),
      )
    catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
    } noraise {
      _ => fail("unknown name accepted")
    }
    assert_eq(calls, 0)
    assert_eq(
      @moonjsonnet.evaluate("if false then std." + name + "() else 42"),
      42,
    )
  }
}
