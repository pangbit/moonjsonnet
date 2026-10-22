// These probes concern conditional transfer/demand, not acceptance of the
// native API or all child expressions. ErrorKind names are embedding categories.

///|
test "conditional rejects every nonboolean condition before either branch" {
  let latent = conditional_native("latent")
  let cases : Array[(String, @moonjsonnet.Ast)] = [
    ("null", conditional_ast(Literal(null))),
    ("1", conditional_ast(Literal(1))),
    ("'true'", conditional_ast(Literal("true"))),
    ("[std.native('latent')()]", conditional_ast(Arr([latent]))),
    (
      "{x:std.native('latent')()}",
      conditional_ast(Obj([conditional_field("x", latent)], [], [])),
    ),
    ("function()std.native('latent')()", conditional_ast(Func([], latent))),
  ]
  for (condition, tree) in cases {
    let source = "if (" +
      condition +
      ") then std.native('yes')() else std.native('no')()"
    for
      program in conditional_programs(
        source,
        conditional_ast(
          If(tree, conditional_native("yes"), conditional_native("no")),
        ),
      ) {
      let events : Array[String] = []
      let natives : Map[String, @moonjsonnet.NativeFunction] = Map([])
      for name in ["latent", "yes", "no"] {
        natives[name] = {
          params: [],
          callback: _ => {
            events.push(name)
            42
          },
        }
      }
      try program.evaluate(native_functions=natives) catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Type)
      } noraise {
        _ => fail("nonboolean condition was coerced")
      }
      assert_eq(events, [])
    }
  }
}

///|
test "conditional demands condition then selected branch and preserves failures" {
  let tree = conditional_ast(
    If(
      conditional_native("condition"),
      conditional_native("yes"),
      conditional_native("no"),
    ),
  )
  let source = "if std.native('condition')() then std.native('yes')() else std.native('no')()"
  for choice in [true, false] {
    let selected = if choice { "yes" } else { "no" }
    for failure in ["none", "condition", selected] {
      for program in conditional_programs(source, tree) {
        let events : Array[String] = []
        let natives : Map[String, @moonjsonnet.NativeFunction] = Map([])
        for name in ["condition", "yes", "no"] {
          natives[name] = {
            params: [],
            callback: _ => {
              events.push(name)
              if name == failure {
                fail("conditional marker " + name)
              }
              if name == "condition" {
                Json::boolean(choice)
              } else if name == "yes" {
                Json::number(7)
              } else {
                Json::number(9)
              }
            },
          }
        }
        if failure == "none" {
          assert_eq(
            program.evaluate(native_functions=natives),
            if choice {
              Json::number(7)
            } else {
              Json::number(9)
            },
          )
        } else {
          try program.evaluate(native_functions=natives) catch {
            @moonjsonnet.Error(d) => {
              assert_eq(d.kind, @moonjsonnet.Runtime)
              assert_true(d.message.contains("conditional marker " + failure))
            }
          } noraise {
            _ => fail("required conditional child failure was swallowed")
          }
        }
        assert_eq(
          events,
          if failure == "condition" {
            ["condition"]
          } else {
            ["condition", selected]
          },
        )
      }
    }
  }
  let events : Array[String] = []
  let natives : Map[String, @moonjsonnet.NativeFunction] = Map([])
  for name in ["condition", "yes", "no"] {
    natives[name] = {
      params: [],
      callback: _ => {
        events.push(name)
        fail("unused conditional")
      },
    }
  }
  let unused = conditional_local("unused", tree, conditional_ast(Literal(42)))
  for
    program in conditional_programs("local unused=(" + source + ");42", unused) {
    assert_eq(program.evaluate(native_functions=natives), 42)
    assert_eq(events, [])
  }
}

///|
test "conditional transfers all value kinds without manifesting a selected closure" {
  let values : Array[(String, @moonjsonnet.Ast, Json)] = [
    ("null", conditional_ast(Literal(null)), null),
    ("true", conditional_ast(Literal(true)), true),
    ("42", conditional_ast(Literal(42)), 42),
    ("'你😀'", conditional_ast(Literal("你😀")), "你😀"),
    ("[42]", conditional_ast(Arr([conditional_ast(Literal(42))])), [42]),
    (
      "{answer:42}",
      conditional_ast(
        Obj([conditional_field("answer", conditional_ast(Literal(42)))], [], []),
      ),
      { "answer": 42 },
    ),
  ]
  for choice in [true, false] {
    for (value_source, value, expected) in values {
      let wrong = conditional_native("unselected")
      let tree = conditional_ast(
        If(
          conditional_ast(Literal(Json::boolean(choice))),
          if choice {
            value
          } else {
            wrong
          },
          if choice {
            wrong
          } else {
            value
          },
        ),
      )
      let source = "if " +
        choice.to_string() +
        " then (" +
        (if choice { value_source } else { "std.native('unselected')()" }) +
        ") else (" +
        (if choice { "std.native('unselected')()" } else { value_source }) +
        ")"
      for program in conditional_programs(source, tree) {
        let mut calls = 0
        let natives : Map[String, @moonjsonnet.NativeFunction] = Map([
          (
            "unselected",
            {
              params: [],
              callback: _ => {
                calls += 1
                fail("unselected branch")
              },
            },
          ),
        ])
        assert_eq(program.evaluate(native_functions=natives), expected)
        assert_eq(calls, 0)
      }
    }
    let function = conditional_ast(Func([], conditional_native("body")))
    let wrong = conditional_native("unselected")
    let selected = conditional_ast(
      If(
        conditional_ast(Literal(Json::boolean(choice))),
        if choice {
          function
        } else {
          wrong
        },
        if choice {
          wrong
        } else {
          function
        },
      ),
    )
    let tree = conditional_ast(Call(selected, [], false))
    let source = "(if " +
      choice.to_string() +
      " then (" +
      (if choice {
        "function()std.native('body')()"
      } else {
        "std.native('unselected')()"
      }) +
      ") else (" +
      (if choice {
        "std.native('unselected')()"
      } else {
        "function()std.native('body')()"
      }) +
      "))()"
    for program in conditional_programs(source, tree) {
      let events : Array[String] = []
      let natives : Map[String, @moonjsonnet.NativeFunction] = Map([
        (
          "body",
          {
            params: [],
            callback: _ => {
              events.push("body")
              42
            },
          },
        ),
        (
          "unselected",
          {
            params: [],
            callback: _ => {
              events.push("unselected")
              fail("unselected branch")
            },
          },
        ),
      ])
      assert_eq(program.evaluate(native_functions=natives), 42)
      assert_eq(events, ["body"])
    }
  }
}
