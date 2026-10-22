// Independent rule criteria: SPEC-CONDITIONAL-REVIEW.md. Handmade trees below
// do not originate in the source parser or an exported source AST.

///|
fn conditional_ast(kind : @moonjsonnet.AstKind) -> @moonjsonnet.Ast {
  { kind, loc: { file: "conditional-entry", line: 1, column: 1, }, end: None, }
}

///|
fn conditional_local(
  name : String,
  value : @moonjsonnet.Ast,
  body : @moonjsonnet.Ast,
) -> @moonjsonnet.Ast {
  conditional_ast(Local([{ name, value, range: None, }], body))
}

///|
fn conditional_field(
  name : String,
  value : @moonjsonnet.Ast,
) -> @moonjsonnet.AstField {
  {
    key: conditional_ast(Literal(Json::string(name))),
    value,
    visibility: 1,
    additive: false,
  }
}

///|
fn conditional_native(name : String) -> @moonjsonnet.Ast {
  conditional_ast(
    Call(
      conditional_ast(
        Call(
          conditional_ast(
            Index(
              conditional_ast(Var("std")),
              conditional_ast(Literal("native")),
            ),
          ),
          [(None, conditional_ast(Literal(Json::string(name))))],
          false,
        ),
      ),
      [],
      false,
    ),
  )
}

///|
fn conditional_programs(
  source : String,
  tree : @moonjsonnet.Ast,
) -> Array[@moonjsonnet.Program] raise {
  [
    @moonjsonnet.Program::parse(source, filename="conditional-entry"),
    @moonjsonnet.Program::from_ast(tree),
  ]
}

///|
fn conditional_static(source : String, tree : @moonjsonnet.Ast) -> Unit raise {
  try @moonjsonnet.Program::parse(source, filename="conditional-entry") catch {
    @moonjsonnet.Error(d) => {
      assert_eq(d.kind, @moonjsonnet.Static)
      assert_eq(d.location.file, "conditional-entry")
    }
  } noraise {
    _ => fail("invalid conditional source scope accepted")
  }
  try @moonjsonnet.Program::from_ast(tree) catch {
    @moonjsonnet.Error(d) => {
      assert_eq(d.kind, @moonjsonnet.Static)
      assert_eq(d.location.file, "conditional-entry")
    }
  } noraise {
    _ => fail("invalid conditional handmade scope accepted")
  }
}

///|
test "conditional validates condition then and else scopes even when unused" {
  let sources = [
    "if missing then 0 else 0", "if false then missing else 0", "if true then 0 else missing",
  ]
  for role in 0..<3 {
    let children = [
      conditional_ast(Literal(Json::boolean(role != 1))),
      conditional_ast(Literal(0)),
      conditional_ast(Literal(0)),
    ]
    children[role] = conditional_ast(Var("missing"))
    let tree = conditional_ast(If(children[0], children[1], children[2]))
    conditional_static(sources[role], tree)
    conditional_static(
      "local unused=(" + sources[role] + ");42",
      conditional_local("unused", tree, conditional_ast(Literal(42))),
    )
  }
  let x = conditional_ast(Var("x"))
  for
    program in conditional_programs(
      "local x=true; if x then x else x",
      conditional_local(
        "x",
        conditional_ast(Literal(true)),
        conditional_ast(If(x, x, x)),
      ),
    ) {
    assert_eq(program.evaluate(), true)
  }
  for
    source in ["if true 1 else 2", "if true then else 2", "if true then 1 else"] {
    try @moonjsonnet.Program::parse(source) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Syntax)
    } noraise {
      _ => fail("malformed conditional source accepted")
    }
  }
}

///|
test "conditional preserves object context and isolates sibling local scopes" {
  let x = conditional_ast(Var("x"))
  let yes = conditional_ast(Literal(true))
  let no = conditional_ast(Literal(false))
  for
    (source, tree) in [
      (
        "if (local x=true;x) then x else false",
        conditional_ast(If(conditional_local("x", yes, x), x, no)),
      ),
      (
        "if true then (local x=1;x) else x",
        conditional_ast(
          If(yes, conditional_local("x", conditional_ast(Literal(1)), x), x),
        ),
      ),
      (
        "if x then true else (local x=false;x)",
        conditional_ast(If(x, yes, conditional_local("x", no, x))),
      ),
    ] {
    conditional_static(source, tree)
  }
  for name in ["self", "super"] {
    let access = conditional_ast(
      Index(conditional_ast(Var(name)), conditional_ast(Literal("flag"))),
    )
    let sources = [
      "if " + name + ".flag then 0 else 0",
      "if false then " + name + ".flag else 0",
      "if true then 0 else " + name + ".flag",
    ]
    for role in 0..<3 {
      let children = [
        conditional_ast(Literal(Json::boolean(role != 1))),
        conditional_ast(Literal(0)),
        conditional_ast(Literal(0)),
      ]
      children[role] = access
      conditional_static(
        sources[role],
        conditional_ast(If(children[0], children[1], children[2])),
      )
    }
  }
  for flag in [true, false] {
    let base = conditional_ast(
      Obj(
        [
          conditional_field("a", conditional_ast(Literal(7))),
          conditional_field(
            "flag",
            conditional_ast(Literal(Json::boolean(flag))),
          ),
        ],
        [],
        [],
      ),
    )
    let selection = conditional_ast(
      If(
        conditional_ast(
          Index(conditional_ast(Var("self")), conditional_ast(Literal("flag"))),
        ),
        conditional_ast(
          Index(conditional_ast(Var("super")), conditional_ast(Literal("a"))),
        ),
        conditional_ast(
          Index(conditional_ast(Var("self")), conditional_ast(Literal("a"))),
        ),
      ),
    )
    let derived = conditional_ast(
      Obj(
        [
          conditional_field("a", conditional_ast(Literal(9))),
          conditional_field("value", selection),
        ],
        [],
        [],
      ),
    )
    let tree = conditional_ast(
      Index(
        conditional_ast(Binary("+", base, derived)),
        conditional_ast(Literal("value")),
      ),
    )
    let source = "({a:7,flag:" +
      flag.to_string() +
      "}+{a:9,value:if self.flag then super.a else self.a}).value"
    for program in conditional_programs(source, tree) {
      assert_eq(
        program.evaluate(),
        if flag {
          Json::number(7)
        } else {
          Json::number(9)
        },
      )
    }
  }
  for
    program in conditional_programs(
      "local x=7; if (local x=true;x) then x else x",
      conditional_local(
        "x",
        conditional_ast(Literal(7)),
        conditional_ast(If(conditional_local("x", yes, x), x, x)),
      ),
    ) {
    assert_eq(program.evaluate(), 7)
  }
}
