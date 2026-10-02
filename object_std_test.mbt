///|
test "object standard functions preserve hidden fields and lazy values" {
  for
    (source, expected) in [
      (
        "local o={a:1,b::2}; [std.objectFieldsEx(obj=o,hidden=false),std.objectFieldsEx(o,true),std.objectHasEx(obj=o,fname='b',hidden=true),std.objectHasEx(o,'b',false)]",
        "[[\"a\"],[\"a\",\"b\"],true,false]",
      ),
      (
        "local o={a:1,b::2}; [std.get(o,'a',error 'unused'),std.get(o,'b'),std.get(o,'b',inc_hidden=false),std.get(o,'c',3)]",
        "[1,2,null,3]",
      ),
      ("std.objectValues({z:3,a:1,b::2})", "[1,3]"),
      ("std.objectValuesAll({z:3,a:1,b::2})", "[1,2,3]"),
      (
        "std.objectKeysValues({z:3,a:1,b::2})", "[{\"key\":\"a\",\"value\":1},{\"key\":\"z\",\"value\":3}]",
      ),
      (
        "std.objectKeysValuesAll({b::2,a:1})", "[{\"key\":\"a\",\"value\":1},{\"key\":\"b\",\"value\":2}]",
      ),
      ("std.length(std.objectValues({a:error 'unused'}))", "1"),
      ("std.objectKeysValues({a:error 'unused'})[0].key", "\"a\""),
      ("std.objectRemoveKey({a:error 'unused',b:2,h::3},'a')", "{\"b\":2}"),
      (
        "std.mapWithKey(function(k,v) k+v,{a:1,b:2,h::3})", "{\"a\":\"a1\",\"b\":\"b2\"}",
      ),
      ("std.mapWithKey(function(k,v)k,{a:error 'unused'}).a", "\"a\""),
      (
        "std.prune({a:null,b:[],c:{x:[],h::1},d:[{},null,[],0,false,''],e:{x:1}})",
        "{\"d\":[0,false,\"\"],\"e\":{\"x\":1}}",
      ),
      (
        "[std.prune(null),std.prune(false),std.prune(0),std.prune('')]", "[null,false,0,\"\"]",
      ),
      (
        "local o={a:1,b:self.a}+{a:2}; [std.objectValues(o),std.mapWithKey(function(k,v)v,o)]",
        "[[2,2],{\"a\":2,\"b\":2}]",
      ),
    ] {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
}

///|
test "equality source functions and object argument contracts" {
  for
    (source, expected) in [
      (
        "[std.equals([1,{a:2,h::3}],[1,{a:2}]),std.equals([1],[2]),std.equals({},[]),std.primitiveEquals([],{}),std.primitiveEquals(null,null),std.primitiveEquals(1,true)]",
        "[true,false,false,false,true,false]",
      ),
      (
        "[std.equals([1,error 'unused'],[2,error 'unused']),std.equals({a:error 'unused'},{b:1})]",
        "[false,false]",
      ),
      (
        "[std.length(std.get),std.length(std.prune),std.length(std.mapWithKey),std.length(std.objectHasEx),std.length(std.equals)]",
        "[2,1,2,3,2]",
      ),
    ] {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
  for
    source in [
      "std.objectFieldsEx({},0)", "std.objectHasEx({},1,true)", "std.objectHasEx([], 'x', true)",
      "std.objectFieldsEx({},error 'forced')", "std.get({},'x',inc_hidden=0)", "std.mapWithKey(1,{})",
      "std.mapWithKey(function(k,v)v,[])", "std.primitiveEquals([] ,[])", "std.primitiveEquals({}, {})",
      "std.equals(function()1,function()1)", "std.objectRemoveKey({a:1,b:self.a},'a').b",
    ] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_true(d.kind != @moonjsonnet.Unsupported)
    } noraise {
      _ => fail("expected error: " + source)
    }
  }
}

///|
test "objectRemoveKey keeps hidden fields and rebinds self without mutating input" {
  for
    (source, expected) in [
      (
        "local o={a:1,h::2}; local r=std.objectRemoveKey(o,'a'); [std.objectFieldsAll(r),r.h,o.a]",
        "[[\"h\"],2,1]",
      ),
      ("local o={a:1,b:self.a}; (std.objectRemoveKey(o,'a')+{a:4}).b", "4"),
      ("std.objectRemoveKey({assert false, a:1,b:2},'a')", "{\"b\":2}"),
      ("local x=3; std.objectRemoveKey({local y=x,a:y,b:y+1},'a')", "{\"b\":4}"),
    ] {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
}
