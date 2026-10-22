///|
test "object reflection distinguishes missing hidden null and omitted keys" {
  assert_eq(
    @moonjsonnet.evaluate(
      "local o={a:null,h::error 'hidden',['']:3,[null]:error 'omitted'}; [std.objectHas(o=o,f='a'),std.objectHas(o,'missing'),std.objectHas(o,'h'),std.objectHasAll(f='h',o=o),std.objectHasAll(o,'missing'),std.objectHas(o,''),std.objectFields(o=o),std.objectFieldsAll(o=o)]",
    ),
    [true, false, false, true, false, true, ["", "a"], ["", "a", "h"]],
  )
}

///|
test "object visibility inheritance follows all nine fixed separator combinations" {
  for
    (left, right, shown) in [
      (":", ":", true),
      (":", "::", false),
      (":", ":::", true),
      ("::", ":", false),
      ("::", "::", false),
      ("::", ":::", true),
      (":::", ":", true),
      (":::", "::", false),
      (":::", ":::", true),
    ] {
    let source = "local o={x" +
      left +
      "1}+{x" +
      right +
      "2}; [std.objectHas(o,'x'),std.objectHasAll(o,'x'),std.objectFields(o),std.objectFieldsAll(o),std.get(o,'x',7,false),std.get(o,'x'),std.objectValues(o)]"
    let expected = if shown {
      "[true,true,[\"x\"],[\"x\"],2,2,[2]]"
    } else {
      "[false,true,[],[\"x\"],7,2,[]]"
    }
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
}

///|
test "object fields sort unique inherited names by Unicode codepoint without values" {
  assert_eq(
    @moonjsonnet.evaluate(
      "local o={'':error 'value',A:error 'value',a:error 'value',aa:error 'value',b:error 'value','é':error 'value','\\uE000':error 'value','😀':error 'value',hidden::error 'hidden'}+{a:error 'override'}; [std.objectFields(o),std.objectFieldsAll(o)]",
    ),
    @json.parse(
      "[[\"\",\"A\",\"a\",\"aa\",\"b\",\"é\",\"\\uE000\",\"😀\"],[\"\",\"A\",\"a\",\"aa\",\"b\",\"hidden\",\"é\",\"\\uE000\",\"😀\"]]",
    ),
  )
}

///|
test "object reflection and missing lookup do not execute assertions or fields" {
  let mut checks = 0
  let mut reads = 0
  let check : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      checks += 1
      Json::boolean(false)
    },
  }
  let read : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      reads += 1
      Json::number(1)
    },
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "local o={assert std.native('check')(),a:std.native('read')(),h::error 'hidden'}; [std.objectHas(o,'a'),std.objectHasAll(o,'h'),std.objectFields(o),std.objectFieldsAll(o),std.length(std.objectValues(o)),std.get(o,'missing',99)]",
      native_functions=Map([("check", check), ("read", read)]),
    ),
    [true, true, ["a"], ["a", "h"], 1, 99],
  )
  assert_eq((checks, reads), (0, 0))
}

///|
test "object contracts report unambiguous object and field-name type errors" {
  for value in ["null", "true", "1", "'object'", "[]", "function()0"] {
    for name in ["objectHas", "objectHasAll", "get"] {
      assert_eq(
        object_contract_error("std." + name + "(" + value + ",'x')").kind,
        @moonjsonnet.Type,
      )
    }
    for name in ["objectFields", "objectFieldsAll", "objectValues"] {
      assert_eq(
        object_contract_error("std." + name + "(" + value + ")").kind,
        @moonjsonnet.Type,
      )
    }
  }
  for value in ["null", "true", "1", "[]", "{}", "function()0"] {
    for name in ["objectHas", "objectHasAll", "get"] {
      assert_eq(
        object_contract_error("std." + name + "({}," + value + ")").kind,
        @moonjsonnet.Type,
      )
    }
  }
}

///|
test "object reflection still demands construction and computed field names" {
  for name in ["objectHas", "objectHasAll", "get"] {
    assert_eq(
      object_contract_error("std." + name + "({[error 'computed name']:1},'x')").message,
      "computed name",
    )
  }
  for name in ["objectFields", "objectFieldsAll", "objectValues"] {
    assert_eq(
      object_contract_error("std." + name + "({[error 'computed name']:1})").message,
      "computed name",
    )
  }
}
