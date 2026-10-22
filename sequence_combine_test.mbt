///|
test "flatMap concatenates arrays and code point strings" {
  let cases = [
    ("std.flatMap(function(x)if x==2 then [] else [x,x],[1,2,3])", "[1,1,3,3]"),
    (
      "std.flatMap(arr='你😀a',func=function(c)if c=='😀' then '' else c+c)",
      "\"你你aa\"",
    ),
    ("std.flatMap(function(x)error 'unused',[])", "[]"),
    ("std.flatMap(function(x)error 'unused','')", "\"\""),
    ("std.flatMap(function(x,y=2)[x+y],[1,2])", "[3,4]"),
    ("std.flatMap(function(x)[[x]],[1,2])", "[[1],[2]]"),
  ]
  for (source, expected) in cases {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
}

///|
test "flatMap preserves input and returned array element laziness" {
  let cases = [
    ("std.flatMap(function(x)[7],[error 'unused'])", "[7]"),
    ("std.length(std.flatMap(function(x)[error 'unused'],[1,2]))", "2"),
    ("std.flatMap(function(x)[x,error 'unused'],[1])[0]", "1"),
    ("local a=[1,2]; [std.flatMap(function(x)[x,x],a),a]", "[[1,1,2,2],[1,2]]"),
  ]
  for (source, expected) in cases {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
}

///|
test "foldr evaluates from right to left with element before accumulator" {
  let cases = [
    ("std.foldr(func=function(x,a)x-a,arr=[1,2,3],init=0)", "2"),
    ("std.foldr(function(x,a)a+x,'你😀a','')", "\"a😀你\""),
    ("std.foldr(function(x,a)a,[error 'unused'],7)", "7"),
    (
      "std.foldr(function(x,a)if x==2 then {v:error 'unused'} else 7,[1,2],0)", "7",
    ),
    ("std.foldr(function(x,a)a,[],{x:error 'unused',y:2}).y", "2"),
    ("std.foldr(function(x,a)a,'',5)", "5"),
    ("std.foldr(function(x,a=9)x+a,[1,2],0)", "3"),
    ("std.foldr(function(x,a)x+a,std.range(1,2000),0)", "2001000"),
  ]
  for (source, expected) in cases {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
}

///|
test "sequence combinators force results and validate empty input contracts" {
  let cases = [
    ("std.flatMap(1,[])", @moonjsonnet.Type),
    ("std.flatMap(function(x)x,{})", @moonjsonnet.Type),
    ("std.flatMap(function(x)null,[1])", @moonjsonnet.Type),
    ("std.flatMap(function(x)null,'a')", @moonjsonnet.Type),
    ("std.flatMap(function(x)'a',[1])", @moonjsonnet.Type),
    ("std.flatMap(function(x)[],'a')", @moonjsonnet.Type),
    ("std.flatMap(function(x,y)[x],[1])", @moonjsonnet.Runtime),
    (
      "std.flatMap(function(x)if x==1 then [1] else error 'forced',[1,2])[0]",
      @moonjsonnet.Runtime,
    ),
    ("std.foldr(1,[1],0)", @moonjsonnet.Type),
    ("std.foldr(function(x,a)a,{},0)", @moonjsonnet.Type),
    ("std.foldr(function(x,a)a,[],error 'forced init')", @moonjsonnet.Runtime),
    (
      "std.foldr(function(x,a)if x==2 then error 'forced' else 7,[1,2],0)",
      @moonjsonnet.Runtime,
    ),
    ("std.foldr(function(x)x,[1],0)", @moonjsonnet.Runtime),
    ("std.flatMap(f=function(x)[x],arr=[])", @moonjsonnet.Runtime),
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
      "[std.objectHas(std,'flatMap'),std.objectHasAll(std,'foldr'),std.length(std.flatMap),std.length(std.foldr)]",
    ),
    @json.parse("[false,true,2,3]"),
  )
}

///|
test "sequence combinators enforce allocation and intermediate string budgets" {
  let limits = @moonjsonnet.Limits::default()
  for
    source in [
      "local a=std.makeArray(30,function(i)i); std.length(std.flatMap(function(x)a,a))",
      "std.foldr(function(x,a)a,std.range(1,100),0)",
    ] {
    try @moonjsonnet.evaluate(source, limits={ ..limits, steps: 200, }) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
    } noraise {
      _ => fail("expected step limit")
    }
  }
  try
    @moonjsonnet.evaluate(
      "std.length(std.flatMap(function(c)'😀😀','abcd'))",
      limits={ ..limits, output_bytes: 24, },
    )
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected intermediate UTF-8 output limit")
  }
}
