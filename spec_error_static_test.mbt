// Independent expectations: SPEC-ERROR-STATIC-REVIEW.md. Trees are handmade;
// no source parser or exported source AST supplies their structure.

///|
fn error_static_ast(kind : @moonjsonnet.AstKind) -> @moonjsonnet.Ast {
  { kind, loc: { file: "error-static-entry", line: 1, column: 1, }, end: None, }
}

///|
fn error_static_unused(value : @moonjsonnet.Ast) -> @moonjsonnet.Ast {
  error_static_ast(
    Local(
      [{ name: "unused", value, range: None, }],
      error_static_ast(Literal(42)),
    ),
  )
}

///|
fn error_static_field(
  name : String,
  value : @moonjsonnet.Ast,
) -> @moonjsonnet.AstField {
  {
    key: error_static_ast(Literal(Json::string(name))),
    value,
    visibility: 1,
    additive: false,
  }
}

///|
fn error_static_access(name : String) -> @moonjsonnet.Ast {
  error_static_ast(
    Index(error_static_ast(Var(name)), error_static_ast(Literal("message"))),
  )
}

///|
fn error_static_program(
  source : String,
  tree : @moonjsonnet.Ast,
  handmade : Bool,
) -> @moonjsonnet.Program raise @moonjsonnet.JsonnetError {
  if handmade {
    @moonjsonnet.Program::from_ast(tree)
  } else {
    @moonjsonnet.Program::parse(source, filename="error-static-entry")
  }
}

///|
test "error delegates operand scope even in unused expressions" {
  let missing = error_static_ast(Fail(error_static_ast(Var("missing"))))
  let invalid = [
    ("error missing", missing),
    ("local unused=error missing;42", error_static_unused(missing)),
    (
      "if false then error missing else 42",
      error_static_ast(
        If(
          error_static_ast(Literal(false)),
          missing,
          error_static_ast(Literal(42)),
        ),
      ),
    ),
  ]
  for name in ["self", "super"] {
    invalid.push(
      (
        "error " + name + ".message",
        error_static_ast(Fail(error_static_access(name))),
      ),
    )
  }
  for (source, tree) in invalid {
    for handmade in [false, true] {
      try error_static_program(source, tree, handmade) catch {
        @moonjsonnet.Error(d) => {
          assert_eq(d.kind, @moonjsonnet.Static)
          assert_eq(d.location.file, "error-static-entry")
        }
      } noraise {
        _ => fail("invalid error operand escaped static checking")
      }
    }
  }
  let bound = error_static_ast(
    Local(
      [
        {
          name: "message",
          value: error_static_ast(Literal("bound")),
          range: None,
        },
      ],
      error_static_unused(
        error_static_ast(Fail(error_static_ast(Var("message")))),
      ),
    ),
  )
  let own = error_static_ast(
    Obj(
      [
        error_static_field("message", error_static_ast(Literal("self"))),
        error_static_field(
          "fault",
          error_static_ast(Fail(error_static_access("self"))),
        ),
      ],
      [],
      [],
    ),
  )
  let inherited = error_static_ast(
    Binary(
      "+",
      error_static_ast(
        Obj(
          [error_static_field("message", error_static_ast(Literal("base")))],
          [],
          [],
        ),
      ),
      error_static_ast(
        Obj(
          [
            error_static_field(
              "fault",
              error_static_ast(Fail(error_static_access("super"))),
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
      ("local message='bound';local unused=error message;42", bound),
      (
        "local unused=error 42;42",
        error_static_unused(
          error_static_ast(Fail(error_static_ast(Literal(42)))),
        ),
      ),
      (
        "local unused={message:'self',fault:error self.message};42",
        error_static_unused(own),
      ),
      (
        "local unused={message:'base'}+{fault:error super.message};42",
        error_static_unused(inherited),
      ),
    ] {
    for handmade in [false, true] {
      let program = error_static_program(source, tree, handmade)
      assert_eq(program.evaluate(), 42)
    }
  }
}

///|
test "error operand callbacks stay lazy until runtime demand" {
  let operand = error_static_ast(
    Call(
      error_static_ast(
        Call(
          error_static_ast(
            Index(
              error_static_ast(Var("std")),
              error_static_ast(Literal("native")),
            ),
          ),
          [(None, error_static_ast(Literal("message")))],
          false,
        ),
      ),
      [],
      false,
    ),
  )
  let error = error_static_ast(Fail(operand))
  for
    (source, tree, demanded) in [
      (
        "local unused=error std.native('message')();42",
        error_static_unused(error),
        false,
      ),
      (
        "if false then error std.native('message')() else 42",
        error_static_ast(
          If(
            error_static_ast(Literal(false)),
            error,
            error_static_ast(Literal(42)),
          ),
        ),
        false,
      ),
      ("error std.native('message')()", error, true),
    ] {
    for handmade in [false, true] {
      let mut calls = 0
      let natives : Map[String, @moonjsonnet.NativeFunction] = Map([
        (
          "message",
          {
            params: [],
            callback: _ => {
              calls += 1
              Json::string("operand marker")
            },
          },
        ),
      ])
      let program = error_static_program(source, tree, handmade)
      assert_eq(calls, 0)
      if demanded {
        try program.evaluate(native_functions=natives) catch {
          @moonjsonnet.Error(d) => {
            assert_eq(d.kind, @moonjsonnet.Runtime)
            assert_eq(d.message, "operand marker")
          }
        } noraise {
          _ => fail("demanded error returned a value")
        }
      } else {
        assert_eq(program.evaluate(native_functions=natives), 42)
      }
      assert_eq(calls, if demanded { 1 } else { 0 })
    }
  }
}
