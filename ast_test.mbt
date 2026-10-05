///|
test "semantic AST round trip covers expression forms and source identities" {
  for
    source in [
      "[null,true,false,1,'é']", "local f(x=2)=if x>0 then x*21 else error 'bad'; f() tailstrict",
      "assert 1==1:'bad'; [~1,!false,-2,+3][1:4:2]", "{local x=21, assert self.a==42:'bad',a:x*2, hidden::1, visible:::2}",
      "({x:1}+{x+:2,y:super.x,z:'x' in super})", "[[x,y] for x in [1,2] if x>1 for y in [3]]",
      "{local a=21,[x]:a*2 for x in ['answer']}", "{this:std.thisFile, code:import 'code', text:importstr 'text', bytes:importbin 'raw'}",
    ] {
    let original = @moonjsonnet.Program::parse(source, filename="origin")
    let copy = @moonjsonnet.Program::from_ast(original.ast().clone())
    let resolver : (String, String) -> @moonjsonnet.Source raise = (_, path) => {
      id: path,
      text: if path == "code" {
        "42"
      } else {
        "hello"
      },
    }
    let binary_resolver : (String, String) -> @moonjsonnet.BinarySource raise = (
      _,
      path,
    ) => { id: path, bytes: b"\xff\x00", }
    assert_eq(
      copy.evaluate(resolver~, binary_resolver~),
      original.evaluate(resolver~, binary_resolver~),
    )
  }
}

///|
test "AST edits and copies do not mutate validated programs or other copies" {
  let original = @moonjsonnet.Program::parse("[21]", filename="origin")
  let tree = original.ast()
  let clone = tree.clone()
  guard tree.kind is Arr(items) else { fail("array AST") }
  items[0] = { ..items[0], kind: @moonjsonnet.AstKind::Literal(42), }
  let edited = @moonjsonnet.Program::from_ast(tree)
  items.clear()
  assert_eq(original.evaluate(), [21])
  assert_eq(edited.evaluate(), [42])
  assert_eq(@moonjsonnet.Program::from_ast(clone).evaluate(), [21])
  let loc : @moonjsonnet.Location = { file: "synthetic", line: 9, column: 4, }
  let variable : @moonjsonnet.Ast = { kind: Var("x"), loc, end: None, }
  ignore(variable.clone())
  let program = @moonjsonnet.Program::from_ast({
    kind: Local(
      [
        {
          name: "x",
          value: { kind: Literal(42), loc, end: None, },
          range: None,
        },
      ],
      variable,
    ),
    loc,
    end: None,
  })
  assert_eq(program.evaluate(), 42)
  assert_eq(
    @moonjsonnet.evaluate("std.extVar('x')", ext_programs=Map([("x", program)])),
    42,
  )
}

///|
test "AST construction validates names scopes operators and shapes" {
  let loc : @moonjsonnet.Location = { file: "edited", line: 7, column: 2, }
  let one : @moonjsonnet.Ast = { kind: Literal(1), loc, end: None, }
  for
    kind in [
      @moonjsonnet.AstKind::Var("unknown"),
      Var("bad-name"),
      Local([{ name: "if", value: one, range: None, }], one),
      Local(
        [
          { name: "x", value: one, range: None, },
          { name: "x", value: one, range: None, },
        ],
        one,
      ),
      Func([("x", None), ("x", None)], one),
      Call(one, [(Some("x"), one), (None, one)], false),
      Call(one, [(Some("x"), one), (Some("x"), one)], false),
      Unary("bad", one),
      Binary("bad", one, one),
      Literal([1]),
      ArrayComp(one, []),
      ArrayComp(one, [When(one)]),
      Obj([{ key: one, value: one, visibility: 0, additive: false, }], [], []),
    ] {
    try @moonjsonnet.Program::from_ast({ kind, loc, end: None, }) catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Static)
        assert_eq(d.location, loc)
      }
    } noraise {
      _ => fail("invalid AST accepted")
    }
  }
}

///|
test "AST conversion bounds cycles width and later execution depth" {
  let loc : @moonjsonnet.Location = { file: "cycle", line: 1, column: 1, }
  let items : Array[@moonjsonnet.Ast] = []
  let tree : @moonjsonnet.Ast = { kind: Arr(items), loc, end: None, }
  items.push(tree)
  try
    @moonjsonnet.Program::from_ast(tree, limits={
      ..@moonjsonnet.Limits::default(),
      depth: 10,
    })
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("cyclic AST accepted")
  }
  items.clear()
  let one : @moonjsonnet.Ast = { kind: Literal(1), loc, end: None, }
  items.push(one)
  items.push(one)
  try tree.clone(limits={ ..@moonjsonnet.Limits::default(), steps: 2, }) catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("AST node budget ignored")
  }
  let program = @moonjsonnet.Program::from_ast(tree)
  try
    program.evaluate(limits={ ..@moonjsonnet.Limits::default(), depth: 1, })
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("execution depth ignored")
  }
}

///|
test "AST metadata retains diagnostics and permits explicit anonymous entry" {
  let tree = @moonjsonnet.Program::parse("std.thisFile", filename="original").ast()
  assert_eq(
    @moonjsonnet.Program::from_ast(tree, filename="edited").evaluate(),
    Json::string("edited"),
  )
  assert_eq(
    @moonjsonnet.Program::from_ast(tree, anonymous=true).evaluate(),
    Json::string(""),
  )
  let failure = @moonjsonnet.Program::parse("error 'boom'", filename="original").ast()
  try
    @moonjsonnet.Program::from_ast(failure, filename="edited").evaluate()
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.location.file, "original")
  } noraise {
    _ => fail("expected failure")
  }
}
