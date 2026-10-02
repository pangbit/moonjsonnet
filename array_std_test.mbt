///|
test "array source functions preserve lazy values and short circuit" {
  for
    (source, expected) in [
      (
        "[std.all([]),std.any([]),std.all([true,true]),std.any([false,true])]", "[true,false,true,true]",
      ),
      (
        "[std.all([false,error 'unused']),std.any([true,error 'unused'])]", "[false,true]",
      ),
      ("std.flattenArrays([[1],[],[2,3]])", "[1,2,3]"),
      ("std.flattenArrays([[1,error 'unused'],[3]])[0]", "1"),
      (
        "std.flattenDeepArray([1,[2,[],[3]],null,{a:4}])", "[1,2,3,null,{\"a\":4}]",
      ),
      ("std.flattenDeepArray({x:error 'unused'})[0] != null", "true"),
      (
        "std.filterMap(filter_func=function(x)x%2==0,map_func=function(x)x*x,arr=[1,2,3,4])",
        "[4,16]",
      ),
      ("std.filterMap(function(x)true,function(x)0,[error 'unused'])[0]", "0"),
      ("std.count([1,2,1,{a:1}],1)", "2"),
      ("std.repeat('你😀',2)", "\"你😀你😀\""),
      ("std.repeat([1,2],3)", "[1,2,1,2,1,2]"),
      ("std.length(std.repeat([error 'unused'],3))", "3"),
      ("std.find({a:1},[{a:1,h::0},{a:2},{a:1}])", "[0,2]"),
      ("std.deepJoin(['a',['你',[],['😀']],'b'])", "\"a你😀b\""),
      (
        "[std.min(2,3),std.max(-1,-2),std.clamp(9,0,5),std.clamp(-1,0,error 'unused')]",
        "[2,-1,5,0]",
      ),
      (
        "[std.__compare([1,2],[1,3]),std.__compare('你','😀'),std.__compare_array([],[]),std.__array_less([1],[2]),std.__array_greater([2],[1]),std.__array_less_or_equal([1],[1]),std.__array_greater_or_equal([1],[1])]",
        "[-1,-1,0,true,true,true,true]",
      ),
    ] {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
}

///|
test "array source functions validate inputs and budget" {
  for
    source in [
      "std.all([1])", "std.any([null])", "std.all('')", "std.flattenArrays([[1],2])",
      "std.filterMap(1,function(x)x,[])", "std.filterMap(function(x)true,1,[])",
      "std.filterMap(function(x)true,function(x)x,'x')", "std.count('abc','a')",
      "std.repeat({},2)", "std.repeat([],1.5)", "std.find(1,'a')", "std.deepJoin(['a',null])",
      "std.min('a','b')", "std.__compare(true,false)", "std.__compare(1,'1')",
    ] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_true(d.kind != @moonjsonnet.Unsupported)
    } noraise {
      _ => fail("expected error: " + source)
    }
  }
  let limits = @moonjsonnet.Limits::default()
  try
    @moonjsonnet.evaluate("std.all(std.makeArray(10000,function(i)true))", limits={
      ..limits,
      steps: 1000,
    })
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected budget limit")
  }
}
