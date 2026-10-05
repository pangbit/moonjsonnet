///|
test "binding ranges survive copies without replacing initializer locations" {
  let program = @moonjsonnet.Program::parse(
    "local x=1e309;x",
    filename="binding",
  )
  let tree = program.ast()
  let copy = tree.clone()
  guard tree.kind is Local(bs, _) && copy.kind is Local(copied, _) else {
    fail("bindings")
  }
  assert_eq(bs[0].name, "x")
  assert_eq(bs[0].range.unwrap().format(), "binding:1:7-14")
  assert_eq(bs[0].value.source_range().unwrap().format(), "binding:1:9-14")
  assert_eq(copied[0].range, bs[0].range)
  let roundtrip = @moonjsonnet.Program::from_ast(copy)
  copied[0] = {
    ..copied[0],
    range: None,
    value: @moonjsonnet.Program::parse("42").ast(),
  }
  assert_eq(@moonjsonnet.Program::from_ast(copy).evaluate(), 42)
  assert_true(bs[0].value.kind is NumberLiteral("1e309"))
  for p in [program, roundtrip] {
    guard p.ast().kind is Local(saved, _) else { fail("saved bindings") }
    assert_eq(saved[0].range, bs[0].range)
    try p.evaluate() catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.message, "overflow")
        assert_eq(d.location, { file: "binding", line: 1, column: 9, })
      }
    } noraise {
      _ => fail("expected overflow")
    }
  }
}

///|
test "manual binding ranges validate shape and may be absent" {
  let tree = @moonjsonnet.Program::parse("local x=42;x", filename="manual").ast()
  guard tree.kind is Local(bs, _) else { fail("binding") }
  let begin = bs[0].range.unwrap().begin
  for
    end in [
      { ..begin, file: "other", },
      { ..begin, column: 0, },
      { ..begin, column: 6, },
      { ..begin, line: 0, },
    ] {
    bs[0] = { ..bs[0], range: Some({ begin, end, }), }
    try @moonjsonnet.Program::from_ast(tree) catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Static)
        assert_eq(d.message, "invalid AST source range")
      }
    } noraise {
      _ => fail("invalid declaration range accepted")
    }
  }
  bs[0] = { ..bs[0], range: None, }
  assert_eq(@moonjsonnet.Program::from_ast(tree).evaluate(), 42)
}

///|
test "unused locals report declaration names across objects and comprehensions" {
  for
    source in [
      "local x=1e309;42", "{local x=42,a:null}", "{local x=42,[k]:null for k in ['a']}",
    ] {
    let diagnostics = @moonjsonnet.lint([{ id: "entry", text: source, }])
    assert_eq(diagnostics.length(), 1)
    assert_eq(diagnostics[0].message, "Unused variable: x")
    assert_eq(
      diagnostics[0].location.column,
      if source.has_prefix("{") {
        8
      } else {
        7
      },
    )
  }
  let local_tree = @moonjsonnet.Program::parse("local f(x)=x;42").ast()
  guard local_tree.kind is Local(bs, _) else { fail("function binding") }
  assert_eq(bs[0].range, None)
  assert_eq(bs[0].value.loc.column, 7)
  let issues = @moonjsonnet.lint([{ id: "entry", text: "local f(x)=x;42", }])
  assert_eq(issues[0].location, { file: "", line: 0, column: 0, })
  let object = @moonjsonnet.Program::parse(
    "{local f(x)=x,a:42}",
    filename="entry",
  ).ast()
  guard object.kind is Obj(_, bs, _) else { fail("object function binding") }
  assert_eq(bs[0].range.unwrap().format(), "entry:1:8-14")
  let unknown = @moonjsonnet.lint([{ id: "entry", text: "{local x=1,[x]:42}", }])
  assert_eq(unknown[0].message, "Unknown variable: x")
  assert_eq(unknown[0].location.column, 13)
}
