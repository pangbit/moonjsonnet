// Independent criteria: SPEC-ASSERTION-SUPER-REVIEW.md. Reuse neutral AST
// builders from spec_assertion_self_test.mbt; all new trees are handmade.

///|
fn assertion_super_call(target : @moonjsonnet.Ast) -> @moonjsonnet.Ast {
  assertion_self_ast(Call(target, [], false))
}

///|
fn assertion_super_extract(field : String) -> @moonjsonnet.Ast {
  assertion_self_local(
    [("saved", assertion_self_index("super", field))],
    assertion_self_invoke(assertion_super_call(assertion_self_var("saved"))),
  )
}

///|
fn assertion_super_tree(
  problem : String,
  expected : Int32,
  body : @moonjsonnet.Ast,
) -> @moonjsonnet.Ast {
  let fields = [("n", assertion_self_ast(Literal(1)))]
  if problem == "error" {
    fields.push(
      (
        "problem",
        assertion_self_ast(
          Fail(assertion_self_ast(Literal("assertion-super-marker"))),
        ),
      ),
    )
  }
  let context = [
    assertion_self_index("super", "n"),
    assertion_self_index("self", "n"),
  ]
  let probe = assertion_self_ast(
    Func(
      [],
      assertion_self_ast(
        If(
          assertion_self_native(
            "note",
            [assertion_self_ast(Literal("condition")), ..context],
          ),
          assertion_self_ast(Arr(context)),
          assertion_self_ast(Literal(null)),
        ),
      ),
    ),
  )
  let message = assertion_self_ast(
    Func(
      [],
      assertion_self_ast(
        If(
          assertion_self_native(
            "note",
            [assertion_self_ast(Literal("message")), ..context],
          ),
          assertion_self_index("super", "problem"),
          assertion_self_ast(Literal(null)),
        ),
      ),
    ),
  )
  let poison = assertion_self_ast(
    Func(
      [],
      assertion_self_ast(
        Fail(assertion_self_ast(Literal("newer-function-marker"))),
      ),
    ),
  )
  let condition = assertion_self_local(
    [("saved", assertion_self_index("super", "probe"))],
    assertion_self_invoke(
      assertion_self_ast(
        Binary(
          "==",
          assertion_super_call(assertion_self_var("saved")),
          assertion_self_ast(
            Arr([
              assertion_self_ast(Literal(1)),
              assertion_self_index("self", "expected"),
            ]),
          ),
        ),
      ),
    ),
  )
  assertion_self_local(
    [
      ("a", assertion_self_object(fields)),
      (
        "b",
        assertion_self_ast(
          Binary(
            "+",
            assertion_self_var("a"),
            assertion_self_object([
              ("n", assertion_self_ast(Literal(2))),
              ("probe", probe),
              ("message", message),
              ("problem", assertion_self_ast(Literal("newer-B"))),
            ]),
          ),
        ),
      ),
      (
        "c",
        assertion_self_ast(
          Binary(
            "+",
            assertion_self_var("b"),
            assertion_self_object(
              [
                ("n", assertion_self_ast(Literal(3))),
                ("expected", assertion_self_ast(Literal(3))),
                ("probe", poison),
                ("message", poison),
                ("problem", assertion_self_ast(Literal("newer-C"))),
                (
                  "value",
                  assertion_self_native("payload", [
                    assertion_self_index("self", "n"),
                  ]),
                ),
              ],
              checks=[(condition, Some(assertion_super_extract("message")))],
            ),
          ),
        ),
      ),
      (
        "d",
        assertion_self_ast(
          Binary(
            "+",
            assertion_self_var("c"),
            assertion_self_object([
              ("n", assertion_self_ast(Literal(4))),
              (
                "expected",
                assertion_self_ast(Literal(Json::number(expected.to_double()))),
              ),
              ("probe", poison),
              ("message", poison),
              ("problem", assertion_self_ast(Literal("newer-D"))),
            ]),
          ),
        ),
      ),
    ],
    body,
  )
}

///|
fn assertion_super_source(problem : String, expected : Int32) -> String {
  "local a={n:1" +
  (if problem == "error" {
    ",problem:error 'assertion-super-marker'"
  } else {
    ""
  }) +
  "},b=a+{n:2,probe:function()if std.native('note')('condition',super.n,self.n) then [super.n,self.n] else null," +
  "message:function()if std.native('note')('message',super.n,self.n) then super.problem else null,problem:'newer-B'}," +
  "c=b+{n:3,expected:3,probe:function()error 'newer-function-marker',message:function()error 'newer-function-marker',problem:'newer-C'," +
  "assert (local saved=super.probe;(function()saved()==[1,self.expected])()):" +
  "(local saved=super.message;(function()saved())()),value:std.native('payload')(self.n)}," +
  "d=c+{n:4,expected:" +
  expected.to_string() +
  ",probe:function()error 'newer-function-marker',message:function()error 'newer-function-marker',problem:'newer-D'};"
}

///|
fn assertion_super_natives(
  events : Array[Json],
) -> Map[String, @moonjsonnet.NativeFunction] {
  Map([
    (
      "note",
      {
        params: ["phase", "prior", "current"],
        callback: args => {
          events.push(Json::array(args.copy()))
          true
        },
      },
    ),
    (
      "payload",
      {
        params: ["n"],
        callback: args => {
          events.push(Json::array([Json::string("payload"), args[0]]))
          args[0]
        },
      },
    ),
  ])
}

///|
test "inherited assertions extract lower functions with separate super prefixes" {
  let source = assertion_super_source("error", 4) + "d.value"
  let tree = assertion_super_tree(
    "error",
    4,
    assertion_self_index("d", "value"),
  )
  for handmade in [false, true] {
    let events : Array[Json] = []
    let program = assertion_self_program(source, tree, handmade)
    assert_eq(
      program.evaluate(native_functions=assertion_super_natives(events)),
      4,
    )
    assert_eq(events, [["condition", 1, 4], ["payload", 4]])
  }
}

///|
test "assertion message super errors stay lazy and cannot borrow newer fields" {
  for problem in ["missing", "error"] {
    for mode in ["metadata", "unused", "forced"] {
      let suffix = match mode {
        "metadata" => "std.type(d)"
        "unused" => "(local unused=d.value;42)"
        _ => "d.value"
      }
      let type_of_d = assertion_self_ast(
        Call(
          assertion_self_index("std", "type"),
          [(None, assertion_self_var("d"))],
          false,
        ),
      )
      let body = match mode {
        "metadata" => type_of_d
        "unused" =>
          assertion_self_local(
            [("unused", assertion_self_index("d", "value"))],
            assertion_self_ast(Literal(42)),
          )
        _ => assertion_self_index("d", "value")
      }
      let source = assertion_super_source(problem, 0) +
        "if std.type(d)=='object' then " +
        suffix +
        " else null"
      let tree = assertion_super_tree(
        problem,
        0,
        assertion_self_ast(
          If(
            assertion_self_ast(
              Binary("==", type_of_d, assertion_self_ast(Literal("object"))),
            ),
            body,
            assertion_self_ast(Literal(null)),
          ),
        ),
      )
      for handmade in [false, true] {
        let events : Array[Json] = []
        let program = assertion_self_program(source, tree, handmade)
        assert_eq(events, [])
        if mode == "forced" {
          try
            program.evaluate(native_functions=assertion_super_natives(events))
          catch {
            @moonjsonnet.Error(d) => {
              assert_eq(d.kind, @moonjsonnet.Runtime)
              assert_eq(d.location.file, "assertion-self-entry")
              if problem == "error" {
                assert_eq(d.message, "assertion-super-marker")
              }
            }
          } noraise {
            _ => fail("assertion message borrowed a newer problem field")
          }
          assert_eq(events, [["condition", 1, 4], ["message", 1, 4]])
        } else {
          let expected : Json = if mode == "metadata" { "object" } else { 42 }
          assert_eq(
            program.evaluate(native_functions=assertion_super_natives(events)),
            expected,
          )
          assert_eq(events, [])
        }
      }
    }
  }
}
