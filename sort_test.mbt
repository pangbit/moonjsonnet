///|
test "sort supports defaults named keys stability and array ordering" {
  let cases = [
    ("std.sort([3,-1,2,2])", "[-1,2,2,3]"),
    ("std.sort('abc')", "[\"a\",\"b\",\"c\"]"),
    ("std.sort(arr=['😀','你','a'])", "[\"a\",\"你\",\"😀\"]"),
    ("std.sort([[1,2],[],[1],[0]])", "[[],[0],[1],[1,2]]"),
    (
      "[x.id for x in std.sort(keyF=function(x)x.k,arr=[{k:1,id:'a'},{k:0,id:'b'},{k:1,id:'c'}])]",
      "[\"b\",\"a\",\"c\"]",
    ),
    ("std.sort([1,3,2],function(x)-x)", "[3,2,1]"),
    ("local a=[3,1,2]; [std.sort(a),a]", "[[1,2,3],[3,1,2]]"),
    (
      "[std.sort([]),std.length(std.sort),std.objectHas(std,'sort'),std.objectHasAll(std,'sort')]",
      "[[],2,false,true]",
    ),
    ("std.length(std.sort([{}]))", "1"),
  ]
  for (source, expected) in cases {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
}

///|
test "sort forces keys but preserves original element laziness" {
  let cases = [
    ("std.length(std.sort([error 'unused',error 'unused'],function(x)0))", "2"),
    ("std.sort([{k:2,v:error 'unused'},{k:1,v:7}],function(x)x.k)[0].v", "7"),
    ("std.sort([1,2],function(x)[-x,error 'unused'])[0]", "2"),
    ("std.sort([],function(x,y)error 'unused')", "[]"),
    ("std.sort([2,1],function(x,y=0)x+y)", "[1,2]"),
  ]
  for (source, expected) in cases {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
}

///|
test "sort validates key results callback and argument binding" {
  let cases = [
    ("std.sort(true)", @moonjsonnet.Type),
    ("std.sort([2,1],null)", @moonjsonnet.Type),
    ("std.sort([true,false])", @moonjsonnet.Type),
    ("std.sort([1,'a'])", @moonjsonnet.Type),
    ("std.sort([{},{}])", @moonjsonnet.Type),
    ("std.sort([1,2],function(x)null)", @moonjsonnet.Type),
    ("std.length(std.sort([1,error 'forced']))", @moonjsonnet.Runtime),
    (
      "std.length(std.sort([1,2],function(x)error 'forced key'))",
      @moonjsonnet.Runtime,
    ),
    ("std.sort([1,2],function(x,y)x)", @moonjsonnet.Runtime),
    ("std.sort()", @moonjsonnet.Runtime),
    ("std.sort(keyF=function(x)x)", @moonjsonnet.Runtime),
    ("std.sort(xs=[])", @moonjsonnet.Runtime),
    ("std.sort([],arr=[])", @moonjsonnet.Runtime),
    ("std.sort([],function(x)x,0)", @moonjsonnet.Runtime),
  ]
  for (source, kind) in cases {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, kind)
    } noraise {
      _ => fail("expected error: \{source}")
    }
  }
}

///|
test "sort scales iteratively and respects the step budget" {
  assert_eq(
    @moonjsonnet.evaluate(
      "std.sort(std.reverse(std.range(1,2000)))==std.range(1,2000)",
    ),
    Json::boolean(true),
  )
  assert_eq(
    @moonjsonnet.evaluate(
      "std.sort(std.range(1,100),function(x)0)==std.range(1,100)",
    ),
    Json::boolean(true),
  )
  let limits = @moonjsonnet.Limits::default()
  try
    @moonjsonnet.evaluate(
      "std.length(std.sort(std.range(1,100),function(x)0))",
      limits={ ..limits, steps: 1000, },
    )
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected sorting step limit")
  }
}
