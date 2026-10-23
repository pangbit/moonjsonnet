///|
test "array extrema use Go defaults named arguments and stable ties" {
  for
    (source, expected) in [
      ("[std.minArray([3,1,2]),std.maxArray([3,1,2])]", "[1,3]"),
      (
        "[std.minArray([],onEmpty=null),std.maxArray([],onEmpty={x:1})]", "[null,{\"x\":1}]",
      ),
      (
        "local a=[{k:2,v:'a'},{k:1,v:'b'},{k:2,v:'c'}]; [std.minArray(a,keyF=function(x)x.k),std.maxArray(arr=a,keyF=function(x)x.k)]",
        "[{\"k\":1,\"v\":\"b\"},{\"k\":2,\"v\":\"a\"}]",
      ),
      ("std.minArray([[2],[1,4],[1,3]])", "[1,3]"),
      (
        "std.maxArray([{k:1,bad:error 'unused'},{k:2,bad:error 'unused'}],function(x)x.k).k",
        "2",
      ),
      ("std.minArray([{}])", "{}"),
      ("std.maxArray([],keyF=function(a,b)a,onEmpty=0)", "0"),
      (
        "[std.length(std.minArray),std.length(std.maxArray),std.objectHas(std,'minArray')]",
        "[3,3,false]",
      ),
    ] {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
  for
    source in [
      "std.minArray([])", "std.maxArray([])", "std.minArray([],keyF=1,onEmpty=2)",
      "std.maxArray('abc')", "std.minArray([1],onEmpty=error 'forced')", "std.maxArray([error 'forced'],function(x)0)",
      "std.minArray([1],function(a,b)a)", "std.maxArray([{},{}])", "std.minArray([1],unused=2)",
    ] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_true(d.kind != @moonjsonnet.Unsupported)
    } noraise {
      _ => fail("expected error: " + source)
    }
  }
}

///|
test "member traverses matches while contains short circuits with recursive equality" {
  assert_eq(
    @moonjsonnet.evaluate("std['$flatMapArray'](function(x)[x,x],[1,2])"),
    @json.parse("[1,1,2,2]"),
  )
  for
    (source, expected) in [
      (
        "[std.member([1,2],2),std.contains([1,2],3),std.member('你😀','😀'),std.member('','')]",
        "[true,false,true,false]",
      ),
      ("std.contains([1,error 'unused'],1)", "true"),
      (
        "[std.member(arr=[{a:1,h::2}],x={a:1}),std.contains(arr=[{a:1}],elem={a:1})]",
        "[true,true]",
      ),
      ("std.contains([function()1,2],2)", "true"),
      ("std.member([],error 'forced')", "false"),
      ("std.contains([],error 'forced')", "false"),
    ] {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
  // Preserve the original mixed input: count must expose member's tail error,
  // while the separate contains control above retains its short circuit.
  try
    @moonjsonnet.evaluate(
      "[std.member([1,error 'unused'],1),std.contains([1,error 'unused'],1)]",
    )
  catch {
    @moonjsonnet.Error(d) => {
      assert_eq(d.kind, @moonjsonnet.Runtime)
      assert_eq(d.message, "unused")
    }
  } noraise {
    _ => fail("member suppressed the required post-match error")
  }
  for
    source in [
      "std.member('abc',1)", "std.contains('abc','a')", "std.member([function()1],function()1)",
      "std.contains({},1)", "std['$flatMapArray'](function(x)[x],'a')",
    ] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_true(d.kind != @moonjsonnet.Unsupported)
    } noraise {
      _ => fail("expected error: " + source)
    }
  }
}
