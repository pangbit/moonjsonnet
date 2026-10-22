// Handmade ASTs are independent of parser acceptance and source round trips.

///|
fn forms_ast(kind : @moonjsonnet.AstKind) -> @moonjsonnet.Ast {
  { kind, loc: { file: "forms-ast", line: 1, column: 1, }, end: None, }
}

///|
test "handmade AST duplicate local groups reject ordinary and empty comprehension scopes" {
  let one = forms_ast(Literal(1))
  let duplicates : Array[@moonjsonnet.AstBinding] = [
    { name: "x", value: one, range: None, },
    { name: "x", value: one, range: None, },
  ]
  for
    kind in [
      @moonjsonnet.AstKind::Local(duplicates, one),
      Obj([], duplicates, []),
      ObjectComp(
        forms_ast(Var("v")),
        one,
        [For("v", forms_ast(Arr([])))],
        duplicates,
      ),
      If(forms_ast(Literal(false)), forms_ast(Local(duplicates, one)), one),
    ] {
    try @moonjsonnet.Program::from_ast(forms_ast(kind)) catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Static)
        assert_eq(d.location.file, "forms-ast")
      }
    } noraise {
      _ => fail("duplicate synthetic group accepted")
    }
  }
}

///|
test "handmade AST comprehension key and domain scope reject inaccessible bindings" {
  let one = forms_ast(Literal(1))
  let empty = forms_ast(Arr([]))
  for
    kind in [
      @moonjsonnet.AstKind::ObjectComp(
        forms_ast(Var("k")),
        one,
        [For("x", empty)],
        [{ name: "k", value: forms_ast(Literal("a")), range: None, }],
      ),
      ObjectComp(
        forms_ast(Var("x")),
        one,
        [For("x", forms_ast(Var("y"))), For("y", empty)],
        [],
      ),
      ArrayComp(forms_ast(Var("x")), [
        For("x", forms_ast(Var("y"))),
        For("y", empty),
      ]),
    ] {
    try @moonjsonnet.Program::from_ast(forms_ast(kind)) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
    } noraise {
      _ => fail("synthetic comprehension captured unavailable binding")
    }
  }
}

///|
test "handmade AST recursive locals and null comprehension keys stay lazy" {
  let one = forms_ast(Literal(1))
  let forward = forms_ast(
    Local(
      [
        { name: "a", value: forms_ast(Var("b")), range: None, },
        { name: "b", value: forms_ast(Literal(42)), range: None, },
      ],
      forms_ast(Var("a")),
    ),
  )
  assert_eq(@moonjsonnet.Program::from_ast(forward).evaluate(), 42)
  let no_field = forms_ast(
    ObjectComp(
      forms_ast(Literal(null)),
      forms_ast(Fail(forms_ast(Literal("body")))),
      [For("x", forms_ast(Arr([one, one])))],
      [],
    ),
  )
  assert_eq(@moonjsonnet.Program::from_ast(no_field).evaluate(), {})
}

///|
test "handmade AST dynamic duplicate keys are runtime and literal duplicates static" {
  let one = forms_ast(Literal(1))
  let key = forms_ast(Literal("same"))
  let comp = @moonjsonnet.Program::from_ast(
    forms_ast(ObjectComp(key, one, [For("x", forms_ast(Arr([one, one])))], [])),
  )
  try comp.evaluate() catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
  } noraise {
    _ => fail("duplicate comprehension key accepted")
  }
  let fields : Array[@moonjsonnet.AstField] = [
    { key, value: one, visibility: 1, additive: false, },
    { key, value: one, visibility: 1, additive: false, },
  ]
  try @moonjsonnet.Program::from_ast(forms_ast(Obj(fields, [], []))) catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
  } noraise {
    _ => fail("duplicate literal AST field accepted")
  }
}
