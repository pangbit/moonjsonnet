///|
test "get applies documented defaults and named hidden-field selection" {
  assert_eq(
    @moonjsonnet.evaluate(
      "local o={a:1,h::2,n:null,'':3}; [std.get(o,'missing'),std.get(o,'h'),std.get(o,'h',7,false),std.get(inc_hidden=false,default=error 'unused',f='a',o=o),std.get(o,'n',error 'not missing'),std.get(o,'')]",
    ),
    [null, 2, 7, 1, null, 3],
  )
}

///|
test "get evaluates defaults only for missing or excluded fields" {
  let mut fallbacks = 0
  let fallback : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      fallbacks += 1
      Json::number(9)
    },
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "local o={a:1,n:null,h::error 'excluded'}; [std.get(o,'a',std.native('fallback')()),std.get(o,'n',std.native('fallback')()),std.get(o,'h',std.native('fallback')(),false),std.get(o,'missing',std.native('fallback')())]",
      native_functions=Map([("fallback", fallback)]),
    ),
    [1, null, 9, 9],
  )
  assert_eq(fallbacks, 2)
}

///|
test "get preserves selected errors and lazy returned container or function heads" {
  assert_eq(
    object_contract_error("std.get({},'missing',error 'default')").message,
    "default",
  )
  assert_eq(
    object_contract_error("std.get({a:error 'field'},'a',error 'default')").message,
    "field",
  )
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.get({h::error 'field'},'h',7,false),std.length(std.get({},'x',[error 'payload'])),std.type(std.get({},'x',function()error 'body')),std.type(std.get({a:{assert false,b:1}},'a')),std.type(std.get({a:function()error 'body'},'a'))]",
    ),
    [7, 1, "function", "object", "function"],
  )
}

///|
test "get validates the hidden flag before choosing a field or fallback" {
  for value in ["null", "1", "'true'", "[]", "{}", "function()true"] {
    assert_eq(
      object_contract_error(
        "std.get({a:error 'field'},'a',error 'default',inc_hidden=" +
        value +
        ")",
      ).kind,
      @moonjsonnet.Type,
    )
  }
  assert_eq(
    object_contract_error("std.get({},'missing',42,inc_hidden=error 'flag')").message,
    "flag",
  )
}

///|
test "get indexes present fields with inherited assertions and rebound self" {
  for
    source in [
      "std.get({assert false,a:1},'a')", "std.get({assert false,h::2},'h')", "std.get({assert false,n:null},'n',7)",
      "std.get(({assert false,a:1}+{b:2}),'b')",
    ] {
    assert_eq(object_contract_error(source).kind, @moonjsonnet.Assertion)
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.get({assert false,a:1},'missing',7),std.get({assert false,h::2},'h',8,false),std.get(({assert self.x==2,x:1}+{x:2}),'x')]",
    ),
    [7, 8, 2],
  )
}

///|
test "get and objectValues share field caches and check derived assertions once" {
  let mut checks = 0
  let mut reads = 0
  let check : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      checks += 1
      Json::boolean(true)
    },
  }
  let read : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      reads += 1
      Json::number(7)
    },
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "local base={assert std.native('check')(),a:std.native('read')(),x:1,y:self.x}; local o=base+{x:2,z:super.x}; [std.get(o,'a'),std.objectValues(o)[0],o.a,std.get(o,'y'),std.get(o,'z'),std.objectFields(base),std.objectFields(o)]",
      native_functions=Map([("check", check), ("read", read)]),
    ),
    [7, 7, 7, 2, 1, ["a", "x", "y"], ["a", "x", "y", "z"]],
  )
  assert_eq((checks, reads), (1, 1))
}
