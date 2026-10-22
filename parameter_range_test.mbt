///|
test "parameter metadata survives independent AST edits and program copies" {
  let program = @moonjsonnet.Program::parse(
    "function(x=42) x",
    filename="params",
  )
  let tree = program.ast()
  let copy = tree.clone()
  guard tree.kind is Func(ps, _) && copy.kind is Func(copied, _) else {
    fail("parameters")
  }
  let parameter : @moonjsonnet.AstParameter = ps[0]
  assert_eq(parameter.name, "x")
  assert_eq(parameter.range.unwrap().format(), "params:1:10-14")
  assert_eq(
    parameter.default_value.unwrap().source_range().unwrap().format(),
    "params:1:12-14",
  )
  let roundtrip = @moonjsonnet.Program::from_ast(copy)
  copied[0] = {
    ..copied[0],
    default_value: Some(@moonjsonnet.Program::parse("21").ast()),
    range: None,
  }
  assert_eq(@moonjsonnet.Program::from_ast(copy).evaluate(), 21)
  assert_eq(program.evaluate(), 42)
  assert_eq(roundtrip.evaluate(), 42)
  guard roundtrip.ast().kind is Func(saved, _) else { fail("parameters") }
  assert_eq(saved[0].range, parameter.range)
  assert_true(ps[0].default_value.unwrap().kind is NumberLiteral("42"))
}

///|
test "repeated formal names are static errors independent of invocation" {
  for
    source in [
      "std.length(function(x,x) x)", "std.length(function(x=1,x) x)", "(function(x,x) x)(42)",
      "(function(x,x) x)(1,42)", "(function(x,x) x)(x=42)", "(function(x=42,x=1) x)()",
      "(function(x=42,x=error 'unused') x)()", "(function(x,x) x)(error 'unused',42) tailstrict",
      "{f(x,x):x}.f(1,42)", "local f(x,x)=x;f(1,42)", "(function(x=1,x) x)()", "(function(x,x=1) x)()",
      "(function(x,x) x)(1,x=2)", "(function(x,x) x)(1,2,3)", "(function(x,x) x)(y=42)",
    ] {
    try @moonjsonnet.Program::parse(source) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
    } noraise {
      _ => fail("duplicate formal parameters accepted")
    }
  }
}

///|
test "manual parameter ranges validate without forcing defaults" {
  let tree = @moonjsonnet.Program::parse(
    "function(x=1e309) 42",
    filename="params",
  ).ast()
  guard tree.kind is Func(ps, _) else { fail("parameters") }
  let begin = ps[0].range.unwrap().begin
  ps[0] = { ..ps[0], range: Some({ begin, end: { ..begin, column: 1, }, }), }
  try @moonjsonnet.Program::from_ast(tree) catch {
    @moonjsonnet.Error(d) => assert_eq(d.message, "invalid AST source range")
  } noraise {
    _ => fail("invalid parameter range accepted")
  }
  ps[0] = { ..ps[0], range: None, }
  assert_eq(@moonjsonnet.Program::from_ast(tree).evaluate(), 42)
  ps.push(ps[0])
  try @moonjsonnet.Program::from_ast(tree) catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
  } noraise {
    _ => fail("duplicate AST parameters accepted")
  }
}
