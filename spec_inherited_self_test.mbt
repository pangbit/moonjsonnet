// Independent criteria: SPEC-INHERITED-SELF-REVIEW.md. Trees below are handmade;
// neither their structure nor expected values come from exported source ASTs.

///|
fn receiver_ast(kind : @moonjsonnet.AstKind) -> @moonjsonnet.Ast {
  {
    kind,
    loc: { file: "inherited-self-entry", line: 1, column: 1, },
    end: None,
  }
}

///|
fn receiver_var(name : String) -> @moonjsonnet.Ast {
  receiver_ast(Var(name))
}

///|
fn receiver_index(target : @moonjsonnet.Ast, name : String) -> @moonjsonnet.Ast {
  receiver_ast(Index(target, receiver_ast(Literal(Json::string(name)))))
}

///|
fn receiver_call(target : @moonjsonnet.Ast) -> @moonjsonnet.Ast {
  receiver_ast(Call(target, [], false))
}

///|
fn receiver_object(
  fields : Array[(String, @moonjsonnet.Ast)],
) -> @moonjsonnet.Ast {
  receiver_ast(
    Obj(
      fields.map(pair => {
        key: receiver_ast(Literal(Json::string(pair.0))),
        value: pair.1,
        visibility: 1,
        additive: false,
      }),
      [],
      [],
    ),
  )
}

///|
fn receiver_local(
  bindings : Array[(String, @moonjsonnet.Ast)],
  body : @moonjsonnet.Ast,
) -> @moonjsonnet.Ast {
  receiver_ast(
    Local(
      bindings.map(pair => { name: pair.0, value: pair.1, range: None, }),
      body,
    ),
  )
}

///|
fn receiver_extend(name : String, n : Int) -> @moonjsonnet.Ast {
  receiver_ast(
    Binary(
      "+",
      receiver_var(name),
      receiver_object([
        ("n", receiver_ast(Literal(Json::number(n.to_double())))),
      ]),
    ),
  )
}

///|
fn receiver_native(
  name : String,
  args : Array[@moonjsonnet.Ast],
) -> @moonjsonnet.Ast {
  receiver_ast(
    Call(
      receiver_ast(
        Call(
          receiver_index(receiver_var("std"), "native"),
          [(None, receiver_ast(Literal(Json::string(name))))],
          false,
        ),
      ),
      args.map(arg => (None, arg)),
      false,
    ),
  )
}

///|
fn receiver_program(
  source : String,
  tree : @moonjsonnet.Ast,
  handmade : Bool,
) -> @moonjsonnet.Program raise @moonjsonnet.JsonnetError {
  if handmade {
    @moonjsonnet.Program::from_ast(tree)
  } else {
    @moonjsonnet.Program::parse(source, filename="inherited-self-entry")
  }
}

///|
test "inherited detached functions retain distinct warmed receivers after rehosting" {
  let source = "local base={n:1,f:function()self.n},before=base.f," +
    "left=base+{n:2},right=base+{n:3},last=left+{n:4}," +
    "fl=left.f,fr=right.f,fg=last.f,holder={n:99,g:fl};" +
    "if before()==1 then [before(),fl(),fr(),fl(),before(),fg(),fr(),base.f(),holder.g()]" +
    " else error 'warm-up'"
  let values = [
    receiver_call(receiver_var("before")),
    receiver_call(receiver_var("fl")),
    receiver_call(receiver_var("fr")),
    receiver_call(receiver_var("fl")),
    receiver_call(receiver_var("before")),
    receiver_call(receiver_var("fg")),
    receiver_call(receiver_var("fr")),
    receiver_call(receiver_index(receiver_var("base"), "f")),
    receiver_call(receiver_index(receiver_var("holder"), "g")),
  ]
  let tree = receiver_local(
    [
      (
        "base",
        receiver_object([
          ("n", receiver_ast(Literal(1))),
          (
            "f",
            receiver_ast(Func([], receiver_index(receiver_var("self"), "n"))),
          ),
        ]),
      ),
      ("before", receiver_index(receiver_var("base"), "f")),
      ("left", receiver_extend("base", 2)),
      ("right", receiver_extend("base", 3)),
      ("last", receiver_extend("left", 4)),
      ("fl", receiver_index(receiver_var("left"), "f")),
      ("fr", receiver_index(receiver_var("right"), "f")),
      ("fg", receiver_index(receiver_var("last"), "f")),
      (
        "holder",
        receiver_object([
          ("n", receiver_ast(Literal(99))),
          ("g", receiver_var("fl")),
        ]),
      ),
    ],
    receiver_ast(
      If(
        receiver_ast(
          Binary(
            "==",
            receiver_call(receiver_var("before")),
            receiver_ast(Literal(1)),
          ),
        ),
        receiver_ast(Arr(values)),
        receiver_ast(Fail(receiver_ast(Literal("warm-up")))),
      ),
    ),
  )
  for handmade in [false, true] {
    let program = receiver_program(source, tree, handmade)
    assert_eq(program.evaluate(), [1, 2, 3, 2, 1, 4, 3, 1, 2])
  }
}

///|
test "retrieving inherited closures defers their bodies until detached invocation" {
  let prefix = "local base={f:function()std.native('body')(self.n)}," +
    "derived=base+{n:7},saved=derived.f;"
  let bindings = [
    (
      "base",
      receiver_object([
        (
          "f",
          receiver_ast(
            Func(
              [],
              receiver_native("body", [
                receiver_index(receiver_var("self"), "n"),
              ]),
            ),
          ),
        ),
      ]),
    ),
    ("derived", receiver_extend("base", 7)),
    ("saved", receiver_index(receiver_var("derived"), "f")),
  ]
  for demanded in [false, true] {
    let source = prefix +
      (if demanded { "saved()" } else { "[std.type(base.f),std.type(saved)]" })
    let body = if demanded {
      receiver_call(receiver_var("saved"))
    } else {
      receiver_ast(
        Arr([
          receiver_ast(
            Call(
              receiver_index(receiver_var("std"), "type"),
              [(None, receiver_index(receiver_var("base"), "f"))],
              false,
            ),
          ),
          receiver_ast(
            Call(
              receiver_index(receiver_var("std"), "type"),
              [(None, receiver_var("saved"))],
              false,
            ),
          ),
        ]),
      )
    }
    let tree = receiver_local(bindings, body)
    for handmade in [false, true] {
      let events : Array[Json] = []
      let natives : Map[String, @moonjsonnet.NativeFunction] = Map([
        (
          "body",
          {
            params: ["value"],
            callback: args => {
              events.push(args[0])
              args[0]
            },
          },
        ),
      ])
      let program = receiver_program(source, tree, handmade)
      assert_eq(events, [])
      let expected : Json = if demanded { 7 } else { ["function", "function"] }
      assert_eq(program.evaluate(native_functions=natives), expected)
      assert_eq(events, if demanded { [Json::number(7)] } else { [] })
    }
  }
}

///|
test "a healthy derived receiver does not repair the original detached closure" {
  let source = "local base={f:function()self.n},original=base.f,derived=base+{n:7};" +
    "if derived.f()==7 then if std.native('checked')() then original() else null else null"
  let tree = receiver_local(
    [
      (
        "base",
        receiver_object([
          (
            "f",
            receiver_ast(Func([], receiver_index(receiver_var("self"), "n"))),
          ),
        ]),
      ),
      ("original", receiver_index(receiver_var("base"), "f")),
      ("derived", receiver_extend("base", 7)),
    ],
    receiver_ast(
      If(
        receiver_ast(
          Binary(
            "==",
            receiver_call(receiver_index(receiver_var("derived"), "f")),
            receiver_ast(Literal(7)),
          ),
        ),
        receiver_ast(
          If(
            receiver_native("checked", []),
            receiver_call(receiver_var("original")),
            receiver_ast(Literal(null)),
          ),
        ),
        receiver_ast(Literal(null)),
      ),
    ),
  )
  for handmade in [false, true] {
    let events : Array[String] = []
    let natives : Map[String, @moonjsonnet.NativeFunction] = Map([
      (
        "checked",
        {
          params: [],
          callback: _ => {
            events.push("derived-ok")
            true
          },
        },
      ),
    ])
    let program = receiver_program(source, tree, handmade)
    assert_eq(events, [])
    try program.evaluate(native_functions=natives) catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Runtime)
        assert_eq(d.location.file, "inherited-self-entry")
      }
    } noraise {
      _ =>
        fail(
          "original missing receiver field was replaced or the derived control failed",
        )
    }
    assert_eq(events, ["derived-ok"])
  }
}
