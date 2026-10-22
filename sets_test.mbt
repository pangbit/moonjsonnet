///|
test "source standard library sets and merge patch" {
  for
    (source, expected) in [
      ("std.uniq([1,1,2,1])", "[1,2,1]"),
      ("std.uniq('aa你你😀')", "[\"a\",\"你\",\"😀\"]"),
      ("std.set(arr=[3,1,2,1])", "[1,2,3]"),
      ("std.setUnion([1,3],[2,3])", "[1,2,3]"),
      ("std.setInter([1,2,3],[2,4])", "[2]"),
      ("std.setDiff([1,2,3],[2,4])", "[1,3]"),
      ("[std.setMember(2,[1,2]),std.setMember(3,[1,2])]", "[true,false]"),
      (
        "std.set([{k:2,v:'b'},{k:1,v:'a'},{k:2,v:'c'}],keyF=function(x)x.k)", "[{\"k\":1,\"v\":\"a\"},{\"k\":2,\"v\":\"b\"}]",
      ),
      (
        "std.mergePatch({a:1,b:{x:2,y:3},c:[1]}, {a:null,b:{x:4},c:[2],d:5})", "{\"b\":{\"x\":4,\"y\":3},\"c\":[2],\"d\":5}",
      ),
      ("std.mergePatch([1],{a:{b:null,c:2}})", "{\"a\":{\"c\":2}}"),
      ("std.mergePatch({a::1,b:2},{c::3})", "{\"b\":2}"),
    ] {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
}

///|
test "source standard library preserves laziness and reflection" {
  for
    (source, expected) in [
      ("std.mergePatch(error 'unused',7)", "7"),
      ("std.mergePatch({bad:error 'unused',good:1},{bad:null}).good", "1"),
      ("std.mergePatch({bad:error 'unused',good:1},{}).good", "1"),
      ("std.uniq([error 'unused'],keyF=error 'unused') != null", "true"),
      ("std.length(std.setUnion([], [error 'unused']))", "1"),
      ("std.length(std.setDiff([error 'unused'], []))", "1"),
      ("std.setInter([],[error 'unused'])", "[]"),
      (
        "[std.objectHas(std,'set'),std.objectHasAll(std,'set'),std.length(std.set),std.length(std.setInter),std.length(std.mergePatch)]",
        "[false,true,2,3,2]",
      ),
      ("local s=std { sort(arr,keyF=function(x)x):: [9,9] }; s.set([1])", "[9]"),
    ] {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
  let result = @moonjsonnet.evaluate(
    "[std.thisFile,import 'child']",
    filename="parent",
    resolver=fn(_, _) {
      { id: "child", text: "[std.thisFile,std.set([2,1,2])]", }
    },
  )
  assert_eq(result, @json.parse("[\"parent\",[\"child\",[1,2]]]"))
}

///|
test "source standard library errors and resource budget" {
  for
    source in [
      "std.set([{}]) + std.set([{},{}])", "std.uniq([1,2],keyF=null)", "std.setInter([],error 'forced')",
      "std.mergePatch()", "std.setInter(a=[],c=[])", "std.mergePatch({},error 'forced')",
    ] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_true(d.kind != @moonjsonnet.Unsupported)
    } noraise {
      _ => fail("expected error: " + source)
    }
  }
  let limits = @moonjsonnet.Limits::default()
  try
    @moonjsonnet.evaluate("std.setInter(std.range(1,100),std.range(1,100))", limits={
      ..limits,
      steps: 100,
    })
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected budget limit")
  }
}
