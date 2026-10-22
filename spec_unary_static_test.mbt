// Oracles: SPEC-UNARY-STATIC-REVIEW.md. These trees are handmade, not exported
// source ASTs. Runtime Type probes are boundaries of the static rule only.

///|
fn unary_static_ast(kind : @moonjsonnet.AstKind) -> @moonjsonnet.Ast {
  { kind, loc: { file: "unary-static-entry", line: 1, column: 1, }, end: None, }
}

///|
fn unary_static_unused(value : @moonjsonnet.Ast) -> @moonjsonnet.Ast {
  unary_static_ast(
    Local(
      [{ name: "unused", value, range: None, }],
      unary_static_ast(Literal(42)),
    ),
  )
}

///|
fn unary_static_program(
  source : String,
  tree : @moonjsonnet.Ast,
  handmade : Bool,
) -> @moonjsonnet.Program raise @moonjsonnet.JsonnetError {
  if handmade {
    @moonjsonnet.Program::from_ast(tree)
  } else {
    @moonjsonnet.Program::parse(source, filename="unary-static-entry")
  }
}

///|
fn unary_static_access(name : String) -> @moonjsonnet.Ast {
  unary_static_ast(
    Index(unary_static_ast(Var(name)), unary_static_ast(Literal("n"))),
  )
}

///|
fn unary_static_field(
  name : String,
  value : @moonjsonnet.Ast,
) -> @moonjsonnet.AstField {
  {
    key: unary_static_ast(Literal(Json::string(name))),
    value,
    visibility: 1,
    additive: false,
  }
}

///|
test "unary delegates unchanged operand scope for all four symbols" {
  for op in ["-", "+", "!", "~"] {
    let missing = unary_static_ast(Unary(op, unary_static_ast(Var("missing"))))
    let invalid = [
      (op + " missing", missing),
      ("local unused=" + op + " missing;42", unary_static_unused(missing)),
      (
        "if false then " + op + " missing else 42",
        unary_static_ast(
          If(
            unary_static_ast(Literal(false)),
            missing,
            unary_static_ast(Literal(42)),
          ),
        ),
      ),
    ]
    for name in ["self", "super"] {
      invalid.push(
        (
          op + " " + name + ".n",
          unary_static_ast(Unary(op, unary_static_access(name))),
        ),
      )
    }
    for (source, tree) in invalid {
      for handmade in [false, true] {
        try unary_static_program(source, tree, handmade) catch {
          @moonjsonnet.Error(d) => {
            assert_eq(d.kind, @moonjsonnet.Static)
            assert_eq(d.location.file, "unary-static-entry")
          }
        } noraise {
          _ => fail("invalid unary operand escaped static checking")
        }
      }
    }
    let bound = unary_static_ast(
      Local(
        [{ name: "n", value: unary_static_ast(Literal(0)), range: None, }],
        unary_static_unused(
          unary_static_ast(Unary(op, unary_static_ast(Var("n")))),
        ),
      ),
    )
    let own = unary_static_ast(
      Obj(
        [
          unary_static_field("n", unary_static_ast(Literal(0))),
          unary_static_field(
            "u",
            unary_static_ast(Unary(op, unary_static_access("self"))),
          ),
        ],
        [],
        [],
      ),
    )
    let inherited = unary_static_ast(
      Binary(
        "+",
        unary_static_ast(
          Obj([unary_static_field("n", unary_static_ast(Literal(0)))], [], []),
        ),
        unary_static_ast(
          Obj(
            [
              unary_static_field(
                "u",
                unary_static_ast(Unary(op, unary_static_access("super"))),
              ),
            ],
            [],
            [],
          ),
        ),
      ),
    )
    for
      (source, tree) in [
        ("local n=0;local unused=" + op + " n;42", bound),
        ("local unused={n:0,u:" + op + " self.n};42", unary_static_unused(own)),
        (
          "local unused={n:0}+{u:" + op + " super.n};42",
          unary_static_unused(inherited),
        ),
      ] {
      for handmade in [false, true] {
        let program = unary_static_program(source, tree, handmade)
        assert_eq(program.evaluate(), 42)
      }
    }
  }
}

///|
test "unary operand callbacks stay lazy before demanded type rejection" {
  let operand = unary_static_ast(
    Call(
      unary_static_ast(
        Call(
          unary_static_ast(
            Index(
              unary_static_ast(Var("std")),
              unary_static_ast(Literal("native")),
            ),
          ),
          [(None, unary_static_ast(Literal("operand")))],
          false,
        ),
      ),
      [],
      false,
    ),
  )
  for op in ["-", "+", "!", "~"] {
    let operation = unary_static_ast(Unary(op, operand))
    for
      (source, tree, demanded) in [
        (
          "local unused=" + op + " std.native('operand')();42",
          unary_static_unused(operation),
          false,
        ),
        (
          "if false then " + op + " std.native('operand')() else 42",
          unary_static_ast(
            If(
              unary_static_ast(Literal(false)),
              operation,
              unary_static_ast(Literal(42)),
            ),
          ),
          false,
        ),
        (op + " std.native('operand')()", operation, true),
      ] {
      for handmade in [false, true] {
        let mut calls = 0
        let natives : Map[String, @moonjsonnet.NativeFunction] = Map([
          (
            "operand",
            {
              params: [],
              callback: _ => {
                calls += 1
                null
              },
            },
          ),
        ])
        let program = unary_static_program(source, tree, handmade)
        assert_eq(calls, 0)
        if demanded {
          try program.evaluate(native_functions=natives) catch {
            @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Type)
          } noraise {
            _ => fail("unary null operand returned a value")
          }
        } else {
          assert_eq(program.evaluate(native_functions=natives), 42)
        }
        assert_eq(calls, if demanded { 1 } else { 0 })
      }
    }
  }
}

///|
test "unary missing source operands reject syntax before program creation" {
  for source in ["-", "+", "!", "~"] {
    try
      @moonjsonnet.Program::parse(source, filename="unary-static-entry")
    catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Syntax)
        assert_eq(d.location.file, "unary-static-entry")
      }
    } noraise {
      _ => fail("bare unary prefix created a Program")
    }
  }
}
