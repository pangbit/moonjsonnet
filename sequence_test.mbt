///|
test "makeArray preserves lazy elements and named arguments" {
  let cases = [
    ("std.makeArray(4, function(i) i*i)", "[0,1,4,9]"),
    ("std.makeArray(func=function(i) i+1, sz=2)", "[1,2]"),
    ("std.makeArray(0, function(i) error 'unused')", "[]"),
    ("std.length(std.makeArray(2, function(a,b) a))", "2"),
    ("std.makeArray(0, function(a,b=1) a)", "[]"),
    ("std.makeArray(2, function(i) if i==0 then 7 else error 'unused')[0]", "7"),
    ("std.length(std.makeArray(3, function(i) error 'unused'))", "3"),
    ("local x=4; std.makeArray(2, function(i) x+i)", "[4,5]"),
  ]
  for (source, expected) in cases {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
}

///|
test "mapWithIndex uses code point indices and lazy values" {
  let cases = [
    (
      "std.mapWithIndex(function(i,x) [i,x], ['a','b'])", "[[0,\"a\"],[1,\"b\"]]",
    ),
    (
      "std.mapWithIndex(arr='你😀', func=function(i,x) [i,x])", "[[0,\"你\"],[1,\"😀\"]]",
    ),
    ("std.mapWithIndex(function(i,x) error 'unused', [])", "[]"),
    ("std.mapWithIndex(function(i,x) i, [error 'unused'])[0]", "0"),
    ("std.mapWithIndex(function(i,x) x, [1,error 'unused'])[0]", "1"),
    ("std.length(std.mapWithIndex(function(i,x) error 'unused', [1,2]))", "2"),
  ]
  for (source, expected) in cases {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
}

///|
test "reverse preserves lazy elements and leaves its input unchanged" {
  let cases = [
    ("std.reverse([])", "[]"),
    ("std.reverse(arr=[1,2,3])", "[3,2,1]"),
    ("std.reverse([error 'unused',2])[0]", "2"),
    ("local a=[1,2,3]; [std.reverse(a),a]", "[[3,2,1],[1,2,3]]"),
    ("std.reverse(std.makeArray(3, function(i) i))", "[2,1,0]"),
  ]
  for (source, expected) in cases {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
}

///|
test "reverse String input follows fixed source codepoint indexing" {
  // Fixed bbb38f std.jsonnet 1428-1430 uses length and lazy indexed elements.
  assert_eq(@moonjsonnet.evaluate("std.reverse('ab')"), ["b", "a"])
}

///|
test "reverse empty Object input follows fixed source length" {
  // Zero visible fields produce makeArray(0, ...); no numeric index is read.
  assert_eq(@moonjsonnet.evaluate("std.reverse({})"), [])
}

///|
test "sequence functions validate arguments and remain hidden" {
  let cases = [
    ("std.makeArray(-1, function(i) i)", @moonjsonnet.Runtime),
    ("std.makeArray(1.5,function(i)i)", @moonjsonnet.Runtime),
    ("std.makeArray(2147483648,function(i)i)", @moonjsonnet.Runtime),
    ("std.makeArray('2',function(i)i)", @moonjsonnet.Type),
    ("std.makeArray(0,1)", @moonjsonnet.Type),
    ("std.makeArray(1,function(a,b)a)[0]", @moonjsonnet.Runtime),
    ("std.mapWithIndex(1,[])", @moonjsonnet.Runtime),
    ("std.mapWithIndex(function(i,x)x,{})", @moonjsonnet.Runtime),
    ("std.mapWithIndex(function(x)x,[1])[0]", @moonjsonnet.Runtime),
    ("std.reverse(xs=[])", @moonjsonnet.Runtime),
  ]
  for (source, kind) in cases {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, kind)
    } noraise {
      _ => fail("expected error: \{source}")
    }
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.objectHas(std,'makeArray'), std.objectHasAll(std,'makeArray'), std.length(std.makeArray), std.length(std.mapWithIndex), std.length(std.reverse)]",
    ),
    @json.parse("[false,true,2,2,1]"),
  )
}

///|
test "sequence allocation respects the step limit" {
  let limits = @moonjsonnet.Limits::default()
  for
    source in [
      "std.length(std.makeArray(10000,function(i)i))", "local a=std.makeArray(30,function(i)i); std.length(std.mapWithIndex(function(i,x)x,a))",
      "local a=std.makeArray(30,function(i)i); std.length(std.reverse(a))",
    ] {
    try @moonjsonnet.evaluate(source, limits={ ..limits, steps: 60, }) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
    } noraise {
      _ => fail("expected allocation limit: \{source}")
    }
  }
}
