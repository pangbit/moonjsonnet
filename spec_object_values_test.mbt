///|
test "objectValues selects sorted inherited values with self and super" {
  assert_eq(
    @moonjsonnet.evaluate(
      "local base={a:1,v:self.a,h::error 'hidden'}; local o=base+{a:2,z:super.a}; [std.objectValues(o=o),std.objectFields(o),std.objectFields(base),base.a]",
    ),
    [[2, 2, 1], ["a", "v", "z"], ["a", "v"], 1],
  )
}

///|
test "objectValues empty and hidden-only results avoid source assertions and bodies" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.objectValues({assert false}),std.objectValues({assert false,h::error 'hidden'}),std.length(std.objectValues({assert false,a:error 'value'})),std.type(std.objectValues({a:function()error 'body'})[0])]",
    ),
    [[], [], 1, "function"],
  )
}

///|
test "objectValues selected fields check assertions but preserve nested laziness" {
  for
    source in [
      "std.objectValues({assert false,a:1})[0]", "std.objectValues(({assert false,a:1}+{b:2}))[1]",
    ] {
    assert_eq(object_contract_error(source).kind, @moonjsonnet.Assertion)
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.objectValues({a:1,h::function()error 'body'}),std.length(std.objectValues({a:[error 'payload']})[0]),std.type(std.objectValues({a:{assert false,b:1}})[0])]",
    ),
    [[1], 1, "object"],
  )
}

///|
test "objectValues follows element demand order and shares selected source thunks" {
  let seen : Array[Json] = []
  let visit : @moonjsonnet.NativeFunction = {
    params: ["name"],
    callback: args => {
      seen.push(args[0])
      args[0]
    },
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "local o={a:std.native('visit')('a'),b:std.native('visit')('b'),h::std.native('visit')('h')}; local v=std.objectValues(o); [std.length(v),v[1],std.get(o,'b'),v[0],v[1]]",
      native_functions=Map([("visit", visit)]),
    ),
    [2, "b", "b", "a", "b"],
  )
  assert_eq(Json::array(seen), ["b", "a"])
}
