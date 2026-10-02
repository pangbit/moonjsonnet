///|
test "function length counts required parameters without evaluating defaults" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.length(function()0), std.length(function(a,b)a), std.length(function(a,b=2)a), std.length(function(a=1,b)b), std.length(function(a=error 'unused')a), std.length(std.foldl)]",
    ),
    @json.parse("[0,2,1,1,0,3]"),
  )
}

///|
test "foldl is left associative and preserves lazy elements and fields" {
  let cases = [
    ("std.foldl(func=function(a,b)a-b,arr=[1,2,3],init=10)", "4"),
    ("std.foldl(function(a,b)a+b,'你😀','')", "\"你😀\""),
    ("std.foldl(function(a,b)a,[error 'unused',error 'unused'],7)", "7"),
    ("std.foldl(function(a,b)b,[],{x:error 'unused',y:2}).y", "2"),
    (
      "std.foldl(function(a,b)if b==1 then {x:error 'unused'} else 7,[1,2],0)", "7",
    ),
    ("std.foldl(function(a,b=9)a+b,[1,2],0)", "3"),
    ("std.foldl(function(a,b)a+b,[],5)", "5"),
    ("std.foldl(function(a,b)a+b,'',5)", "5"),
  ]
  for (source, expected) in cases {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
}

///|
test "foldl forces its arguments and every intermediate result" {
  let cases = [
    (
      "std.foldl(function(a,b)b,[1,2],error 'forced init')",
      @moonjsonnet.Runtime,
    ),
    ("std.foldl(error 'forced function',[],1)", @moonjsonnet.Runtime),
    ("std.foldl(function(a,b)b,[],error 'forced init')", @moonjsonnet.Runtime),
    ("std.foldl(function(a,b)a,error 'forced array',0)", @moonjsonnet.Runtime),
    (
      "std.foldl(function(a,b)if b==1 then error 'intermediate' else b,[1,2],0)",
      @moonjsonnet.Runtime,
    ),
    ("std.foldl(1,[],0)", @moonjsonnet.Type),
    ("std.foldl(function(a,b)b,{},0)", @moonjsonnet.Type),
    ("std.foldl(function(a)a,[1],0)", @moonjsonnet.Runtime),
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
test "foldl iterates without accumulating evaluator stack depth" {
  assert_eq(
    @moonjsonnet.evaluate("std.foldl(function(a,b)a+b,std.range(1,2000),0)"),
    Json::number(2001000),
  )
}

///|
test "foldl still consumes the step budget" {
  let limits = @moonjsonnet.Limits::default()
  try
    @moonjsonnet.evaluate(
      "std.foldl(function(a,b)a+b,[1,2,3,4,5,6,7,8,9,10],0)",
      limits={ ..limits, steps: 60, },
    )
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected fold step limit")
  }
}
