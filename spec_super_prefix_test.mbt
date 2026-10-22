// Oracles precede execution in SPEC-SUPER-PREFIX-REVIEW.md. All trees are
// handmade, without parser/export round trips or reference-derived values.

///|
fn prefix_ast(kind : @moonjsonnet.AstKind) -> @moonjsonnet.Ast {
  { kind, loc: { file: "super-prefix-entry", line: 1, column: 1, }, end: None, }
}

///|
fn prefix_var(name : String) -> @moonjsonnet.Ast {
  prefix_ast(Var(name))
}

///|
fn prefix_index(name : String, field : String) -> @moonjsonnet.Ast {
  prefix_ast(Index(prefix_var(name), prefix_ast(Literal(Json::string(field)))))
}

///|
fn prefix_call(target : @moonjsonnet.Ast) -> @moonjsonnet.Ast {
  prefix_ast(Call(target, [], false))
}

///|
fn prefix_object(
  fields : Array[(String, @moonjsonnet.Ast)],
  hidden? : Array[String] = [],
) -> @moonjsonnet.Ast {
  prefix_ast(
    Obj(
      fields.map(pair => {
        key: prefix_ast(Literal(Json::string(pair.0))),
        value: pair.1,
        visibility: if hidden.contains(pair.0) {
          2
        } else {
          1
        },
        additive: false,
      }),
      [],
      [],
    ),
  )
}

///|
fn prefix_local(
  bindings : Array[(String, @moonjsonnet.Ast)],
  body : @moonjsonnet.Ast,
) -> @moonjsonnet.Ast {
  prefix_ast(
    Local(
      bindings.map(pair => { name: pair.0, value: pair.1, range: None, }),
      body,
    ),
  )
}

///|
fn prefix_extend(
  base : String,
  fields : Array[(String, @moonjsonnet.Ast)],
) -> @moonjsonnet.Ast {
  prefix_ast(Binary("+", prefix_var(base), prefix_object(fields)))
}

///|
fn prefix_program(
  source : String,
  tree : @moonjsonnet.Ast,
  handmade : Bool,
) -> @moonjsonnet.Program raise @moonjsonnet.JsonnetError {
  if handmade {
    @moonjsonnet.Program::from_ast(tree)
  } else {
    @moonjsonnet.Program::parse(source, filename="super-prefix-entry")
  }
}

///|
test "super functions retain their defining prefix with final derived self" {
  let source = "local a={n:1,v:self.n}," +
    "b=a+{n:2,v:super.v+10,f:function()[super.v,self.n]}," +
    "c=b+{n:3,v:super.v+100,outer:function()super.f()}," +
    "d=c+{n:4,v:999},saved=c.f,holder={n:99,v:999,f:saved};" +
    "[b.v,c.v,d.v,c.outer(),d.outer(),saved(),holder.f(),d.f()]"
  let tree = prefix_local(
    [
      (
        "a",
        prefix_object([
          ("n", prefix_ast(Literal(1))),
          ("v", prefix_index("self", "n")),
        ]),
      ),
      (
        "b",
        prefix_extend("a", [
          ("n", prefix_ast(Literal(2))),
          (
            "v",
            prefix_ast(
              Binary("+", prefix_index("super", "v"), prefix_ast(Literal(10))),
            ),
          ),
          (
            "f",
            prefix_ast(
              Func(
                [],
                prefix_ast(
                  Arr([prefix_index("super", "v"), prefix_index("self", "n")]),
                ),
              ),
            ),
          ),
        ]),
      ),
      (
        "c",
        prefix_extend("b", [
          ("n", prefix_ast(Literal(3))),
          (
            "v",
            prefix_ast(
              Binary("+", prefix_index("super", "v"), prefix_ast(Literal(100))),
            ),
          ),
          (
            "outer",
            prefix_ast(Func([], prefix_call(prefix_index("super", "f")))),
          ),
        ]),
      ),
      (
        "d",
        prefix_extend("c", [
          ("n", prefix_ast(Literal(4))),
          ("v", prefix_ast(Literal(999))),
        ]),
      ),
      ("saved", prefix_index("c", "f")),
      (
        "holder",
        prefix_object([
          ("n", prefix_ast(Literal(99))),
          ("v", prefix_ast(Literal(999))),
          ("f", prefix_var("saved")),
        ]),
      ),
    ],
    prefix_ast(
      Arr([
        prefix_index("b", "v"),
        prefix_index("c", "v"),
        prefix_index("d", "v"),
        prefix_call(prefix_index("c", "outer")),
        prefix_call(prefix_index("d", "outer")),
        prefix_call(prefix_var("saved")),
        prefix_call(prefix_index("holder", "f")),
        prefix_call(prefix_index("d", "f")),
      ]),
    ),
  )
  for handmade in [false, true] {
    let program = prefix_program(source, tree, handmade)
    assert_eq(program.evaluate(), [
      12,
      113,
      999,
      [3, 3],
      [4, 4],
      [3, 3],
      [3, 3],
      [4, 4],
    ])
  }
}

///|
test "super reaches hidden prior fields while self remains the final receiver" {
  let source = "local a={n:1,h::self.n},b=a+{read:super.h},c=b+{n:7,h:99};" +
    "[b.read,c.read,c.h]"
  let tree = prefix_local(
    [
      (
        "a",
        prefix_object(
          [("n", prefix_ast(Literal(1))), ("h", prefix_index("self", "n"))],
          hidden=["h"],
        ),
      ),
      ("b", prefix_extend("a", [("read", prefix_index("super", "h"))])),
      (
        "c",
        prefix_extend("b", [
          ("n", prefix_ast(Literal(7))),
          ("h", prefix_ast(Literal(99))),
        ]),
      ),
    ],
    prefix_ast(
      Arr([
        prefix_index("b", "read"),
        prefix_index("c", "read"),
        prefix_index("c", "h"),
      ]),
    ),
  )
  for handmade in [false, true] {
    let program = prefix_program(source, tree, handmade)
    assert_eq(program.evaluate(), [1, 7, 99])
  }
}

///|
test "super missing and hidden error fields fail only on actual function demand" {
  let entered = prefix_call(
    prefix_ast(
      Call(
        prefix_index("std", "native"),
        [(None, prefix_ast(Literal("entered")))],
        false,
      ),
    ),
  )
  let function = prefix_ast(
    Func(
      [],
      prefix_ast(
        If(entered, prefix_index("super", "x"), prefix_ast(Literal(null))),
      ),
    ),
  )
  for explicit_error in [false, true] {
    let base_source = if explicit_error {
      "{x::error 'lower-super-marker'}"
    } else {
      "{}"
    }
    let base = if explicit_error {
      prefix_object(
        [("x", prefix_ast(Fail(prefix_ast(Literal("lower-super-marker")))))],
        hidden=["x"],
      )
    } else {
      prefix_object([])
    }
    let bindings = [
      ("a", base),
      (
        "b",
        prefix_extend("a", [("x", prefix_ast(Literal(42))), ("f", function)]),
      ),
      ("c", prefix_extend("b", [("x", prefix_ast(Literal(99)))])),
      ("held", prefix_index("c", "f")),
    ]
    let source_prefix = "local a=" +
      base_source +
      ",b=a+{x:42,f:function()if std.native('entered')() then super.x else null}," +
      "c=b+{x:99},held=c.f;if c.x==99 then "
    for mode in ["metadata", "unused", "forced"] {
      let suffix = match mode {
        "metadata" => "std.type(held)"
        "unused" => "(local unused=held();42)"
        _ => "held()"
      }
      let source = source_prefix + suffix + " else null"
      let body = match mode {
        "metadata" =>
          prefix_ast(
            Call(
              prefix_index("std", "type"),
              [(None, prefix_var("held"))],
              false,
            ),
          )
        "unused" =>
          prefix_local(
            [("unused", prefix_call(prefix_var("held")))],
            prefix_ast(Literal(42)),
          )
        _ => prefix_call(prefix_var("held"))
      }
      let tree = prefix_local(
        bindings,
        prefix_ast(
          If(
            prefix_ast(
              Binary("==", prefix_index("c", "x"), prefix_ast(Literal(99))),
            ),
            body,
            prefix_ast(Literal(null)),
          ),
        ),
      )
      for handmade in [false, true] {
        let events : Array[String] = []
        let natives : Map[String, @moonjsonnet.NativeFunction] = Map([
          (
            "entered",
            {
              params: [],
              callback: _ => {
                events.push("body")
                true
              },
            },
          ),
        ])
        let program = prefix_program(source, tree, handmade)
        assert_eq(events, [])
        if mode == "forced" {
          try program.evaluate(native_functions=natives) catch {
            @moonjsonnet.Error(d) => {
              assert_eq(d.kind, @moonjsonnet.Runtime)
              assert_eq(d.location.file, "super-prefix-entry")
              if explicit_error {
                assert_eq(d.message, "lower-super-marker")
              }
            }
          } noraise {
            _ =>
              fail(
                "super borrowed a current/newer field or its current-field guard failed",
              )
          }
          assert_eq(events, ["body"])
        } else {
          let expected : Json = if mode == "metadata" { "function" } else { 42 }
          assert_eq(program.evaluate(native_functions=natives), expected)
          assert_eq(events, [])
        }
      }
    }
  }
}
