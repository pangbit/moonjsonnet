// Independent expectations precede execution in SPEC-ASSERTION-SELF-REVIEW.md.
// Trees are handmade; parser/export output never supplies their structure.

///|
fn assertion_self_ast(kind : @moonjsonnet.AstKind) -> @moonjsonnet.Ast {
  {
    kind,
    loc: { file: "assertion-self-entry", line: 1, column: 1, },
    end: None,
  }
}

///|
fn assertion_self_var(name : String) -> @moonjsonnet.Ast {
  assertion_self_ast(Var(name))
}

///|
fn assertion_self_index(name : String, field : String) -> @moonjsonnet.Ast {
  assertion_self_ast(
    Index(
      assertion_self_var(name),
      assertion_self_ast(Literal(Json::string(field))),
    ),
  )
}

///|
fn assertion_self_native(
  name : String,
  args : Array[@moonjsonnet.Ast],
) -> @moonjsonnet.Ast {
  let target = assertion_self_ast(
    Call(
      assertion_self_index("std", "native"),
      [(None, assertion_self_ast(Literal(Json::string(name))))],
      false,
    ),
  )
  assertion_self_ast(Call(target, args.map(arg => (None, arg)), false))
}

///|
fn assertion_self_invoke(body : @moonjsonnet.Ast) -> @moonjsonnet.Ast {
  assertion_self_ast(Call(assertion_self_ast(Func([], body)), [], false))
}

///|
fn assertion_self_object(
  fields : Array[(String, @moonjsonnet.Ast)],
  checks? : Array[(@moonjsonnet.Ast, @moonjsonnet.Ast?)] = [],
) -> @moonjsonnet.Ast {
  assertion_self_ast(
    Obj(
      fields.map(pair => {
        key: assertion_self_ast(Literal(Json::string(pair.0))),
        value: pair.1,
        visibility: 1,
        additive: false,
      }),
      [],
      checks,
    ),
  )
}

///|
fn assertion_self_local(
  bindings : Array[(String, @moonjsonnet.Ast)],
  body : @moonjsonnet.Ast,
) -> @moonjsonnet.Ast {
  assertion_self_ast(
    Local(
      bindings.map(pair => { name: pair.0, value: pair.1, range: None, }),
      body,
    ),
  )
}

///|
fn assertion_self_tree(
  required : Int,
  label : String,
  body : @moonjsonnet.Ast,
  condition_error? : Bool = false,
) -> @moonjsonnet.Ast {
  let context = [
    assertion_self_index("self", "n"),
    assertion_self_index("self", "required"),
    assertion_self_index("self", "label"),
  ]
  let condition = assertion_self_invoke(
    assertion_self_ast(
      If(
        assertion_self_native("condition", context),
        if condition_error {
          assertion_self_ast(
            Fail(assertion_self_ast(Literal("condition-self-marker"))),
          )
        } else {
          assertion_self_ast(
            Binary(
              "==",
              assertion_self_index("self", "n"),
              assertion_self_index("self", "required"),
            ),
          )
        },
        assertion_self_ast(Literal(false)),
      ),
    ),
  )
  let message = assertion_self_invoke(assertion_self_native("message", context))
  let original = assertion_self_object(
    [
      ("n", assertion_self_ast(Literal(2))),
      ("required", assertion_self_ast(Literal(2))),
      ("label", assertion_self_ast(Literal("original"))),
      (
        "value",
        assertion_self_native("payload", [
          assertion_self_index("self", "n"),
          assertion_self_index("self", "label"),
        ]),
      ),
    ],
    checks=[(condition, Some(message))],
  )
  let derived = assertion_self_ast(
    Binary(
      "+",
      assertion_self_var("original"),
      assertion_self_object([
        ("n", assertion_self_ast(Literal(3))),
        (
          "required",
          assertion_self_ast(Literal(Json::number(required.to_double()))),
        ),
        ("label", assertion_self_ast(Literal(Json::string(label)))),
      ]),
    ),
  )
  assertion_self_local([("original", original), ("derived", derived)], body)
}

///|
fn assertion_self_source(
  required : Int,
  label : String,
  condition_error? : Bool = false,
) -> String {
  "local original={n:2,required:2,label:'original'," +
  "assert (function()if std.native('condition')(self.n,self.required,self.label) then " +
  (if condition_error {
    "error 'condition-self-marker'"
  } else {
    "self.n==self.required"
  }) +
  " else false)():(function()std.native('message')(self.n,self.required,self.label))()," +
  "value:std.native('payload')(self.n,self.label)}," +
  "derived=original+{n:3,required:" +
  required.to_string() +
  ",label:'" +
  label +
  "'};"
}

///|
fn assertion_self_natives(
  events : Array[Json],
) -> Map[String, @moonjsonnet.NativeFunction] {
  Map([
    (
      "condition",
      {
        params: ["n", "required", "label"],
        callback: args => {
          events.push(
            Json::array([Json::string("condition"), args[0], args[1], args[2]]),
          )
          true
        },
      },
    ),
    (
      "message",
      {
        params: ["n", "required", "label"],
        callback: args => {
          events.push(
            Json::array([Json::string("message"), args[0], args[1], args[2]]),
          )
          "assertion-self-marker"
        },
      },
    ),
    (
      "payload",
      {
        params: ["n", "label"],
        callback: args => {
          events.push(Json::array([Json::string("payload"), args[0], args[1]]))
          args[0]
        },
      },
    ),
  ])
}

///|
fn assertion_self_program(
  source : String,
  tree : @moonjsonnet.Ast,
  handmade : Bool,
) -> @moonjsonnet.Program raise @moonjsonnet.JsonnetError {
  if handmade {
    @moonjsonnet.Program::from_ast(tree)
  } else {
    @moonjsonnet.Program::parse(source, filename="assertion-self-entry")
  }
}

///|
fn assertion_self_after_original() -> @moonjsonnet.Ast {
  assertion_self_ast(
    If(
      assertion_self_ast(
        Binary(
          "==",
          assertion_self_index("original", "value"),
          assertion_self_ast(Literal(2)),
        ),
      ),
      assertion_self_index("derived", "value"),
      assertion_self_ast(Literal(null)),
    ),
  )
}

///|
test "inherited assertion condition closures bind each compatible receiver self" {
  let source = assertion_self_source(3, "compatible") +
    "if original.value==2 then derived.value else null"
  let tree = assertion_self_tree(
    3,
    "compatible",
    assertion_self_after_original(),
  )
  for handmade in [false, true] {
    let events : Array[Json] = []
    let program = assertion_self_program(source, tree, handmade)
    assert_eq(events, [])
    assert_eq(
      program.evaluate(native_functions=assertion_self_natives(events)),
      3,
    )
    assert_eq(events, [
      ["condition", 2, 2, "original"],
      ["payload", 2, "original"],
      ["condition", 3, 3, "compatible"],
      ["payload", 3, "compatible"],
    ])
  }
}

///|
test "a checked original cannot authorize derived assertion or message closures" {
  let source = assertion_self_source(2, "bad") +
    "if original.value==2 then derived.value else null"
  let tree = assertion_self_tree(2, "bad", assertion_self_after_original())
  for handmade in [false, true] {
    let events : Array[Json] = []
    let program = assertion_self_program(source, tree, handmade)
    assert_eq(events, [])
    try
      program.evaluate(native_functions=assertion_self_natives(events))
    catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Assertion)
        assert_eq(d.location.file, "assertion-self-entry")
        assert_eq(d.message, "assertion-self-marker")
      }
    } noraise {
      _ => fail("derived receiver inherited a stale successful assertion")
    }
    assert_eq(events, [
      ["condition", 2, 2, "original"],
      ["payload", 2, "original"],
      ["condition", 3, 2, "bad"],
      ["message", 3, 2, "bad"],
    ])
  }
}

///|
test "inherited assertion condition errors wait for field demand and bypass messages" {
  for mode in ["metadata", "unused", "forced"] {
    let suffix = match mode {
      "metadata" => "std.type(derived)"
      "unused" => "(local unused=derived.value;42)"
      _ => "derived.value"
    }
    let body = match mode {
      "metadata" =>
        assertion_self_ast(
          Call(
            assertion_self_index("std", "type"),
            [(None, assertion_self_var("derived"))],
            false,
          ),
        )
      "unused" =>
        assertion_self_local(
          [("unused", assertion_self_index("derived", "value"))],
          assertion_self_ast(Literal(42)),
        )
      _ => assertion_self_index("derived", "value")
    }
    let source = assertion_self_source(2, "bad", condition_error=true) +
      "if std.type(derived)=='object' then " +
      suffix +
      " else null"
    let tree = assertion_self_tree(
      2,
      "bad",
      assertion_self_ast(
        If(
          assertion_self_ast(
            Binary(
              "==",
              assertion_self_ast(
                Call(
                  assertion_self_index("std", "type"),
                  [(None, assertion_self_var("derived"))],
                  false,
                ),
              ),
              assertion_self_ast(Literal("object")),
            ),
          ),
          body,
          assertion_self_ast(Literal(null)),
        ),
      ),
      condition_error=true,
    )
    for handmade in [false, true] {
      let events : Array[Json] = []
      let program = assertion_self_program(source, tree, handmade)
      assert_eq(events, [])
      if mode == "forced" {
        try
          program.evaluate(native_functions=assertion_self_natives(events))
        catch {
          @moonjsonnet.Error(d) => {
            assert_eq(d.kind, @moonjsonnet.Runtime)
            assert_eq(d.location.file, "assertion-self-entry")
            assert_eq(d.message, "condition-self-marker")
          }
        } noraise {
          _ =>
            fail("demanded inherited assertion condition error was suppressed")
        }
        assert_eq(events, [["condition", 3, 2, "bad"]])
      } else {
        let expected : Json = if mode == "metadata" { "object" } else { 42 }
        assert_eq(
          program.evaluate(native_functions=assertion_self_natives(events)),
          expected,
        )
        assert_eq(events, [])
      }
    }
  }
}
