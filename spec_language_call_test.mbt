// Independent oracle: SPEC-LANGUAGE-CALL-REVIEW.md. Handmade ASTs below do not
// obtain their structure from a source parser or the implementation's output.

///|
fn call_ast(kind : @moonjsonnet.AstKind) -> @moonjsonnet.Ast {
  { kind, loc: { file: "call-ast", line: 1, column: 1, }, end: None, }
}

///|
fn call_native(name : String) -> @moonjsonnet.Ast {
  call_ast(
    Call(
      call_ast(
        Call(
          call_ast(Index(call_ast(Var("std")), call_ast(Literal("native")))),
          [(None, call_ast(Literal(Json::string(name))))],
          false,
        ),
      ),
      [],
      false,
    ),
  )
}

///|
test "handmade calls bind default closures in formal and caller scopes" {
  let function = call_ast(
    Func(
      [
        { name: "a", default_value: Some(call_ast(Var("x"))), range: None, },
        {
          name: "g",
          default_value: Some(call_ast(Func([], call_ast(Var("a"))))),
          range: None,
        },
      ],
      call_ast(Call(call_ast(Var("g")), [], false)),
    ),
  )
  let tree = call_ast(
    Local(
      [
        { name: "x", value: call_ast(Literal(10)), range: None, },
        { name: "f", value: function, range: None, },
      ],
      call_ast(
        Local(
          [{ name: "a", value: call_ast(Literal(99)), range: None, }],
          call_ast(
            Arr([
              call_ast(Call(call_ast(Var("f")), [], false)),
              call_ast(
                Call(call_ast(Var("f")), [(None, call_ast(Literal(20)))], false),
              ),
              call_ast(
                Call(
                  call_ast(Var("f")),
                  [(Some("g"), call_ast(Func([], call_ast(Var("a")))))],
                  false,
                ),
              ),
            ]),
          ),
        ),
      ),
    ),
  )
  assert_eq(@moonjsonnet.Program::from_ast(tree).evaluate(), [10, 20, 99])
  assert_eq(
    @moonjsonnet.evaluate(
      "local x=10,f(a=x,g=function()a)=g(); local a=99; [f(),f(20),f(g=function()a)]",
    ),
    [10, 20, 99],
  )
}

///|
fn call_recursive_default(next : String) -> @moonjsonnet.Ast {
  call_ast(
    Func(
      [{ name: "n", default_value: None, range: None, }],
      call_ast(
        If(
          call_ast(Binary("==", call_ast(Var("n")), call_ast(Literal(0)))),
          call_ast(Var("x")),
          call_ast(
            Call(
              call_ast(Var(next)),
              [
                (
                  None,
                  call_ast(
                    Binary("-", call_ast(Var("n")), call_ast(Literal(1))),
                  ),
                ),
              ],
              false,
            ),
          ),
        ),
      ),
    ),
  )
}

///|
test "handmade mutually recursive function defaults capture the same formal environment" {
  let function = call_ast(
    Func(
      [
        {
          name: "f",
          default_value: Some(call_recursive_default("g")),
          range: None,
        },
        {
          name: "g",
          default_value: Some(call_recursive_default("f")),
          range: None,
        },
        { name: "x", default_value: Some(call_ast(Literal(42))), range: None, },
      ],
      call_ast(Call(call_ast(Var("f")), [(None, call_ast(Literal(3)))], false)),
    ),
  )
  let tree = call_ast(
    Local(
      [{ name: "x", value: call_ast(Literal(100)), range: None, }],
      call_ast(
        Arr([
          call_ast(Call(function, [], false)),
          call_ast(Call(function, [(Some("x"), call_ast(Literal(7)))], false)),
        ]),
      ),
    ),
  )
  assert_eq(@moonjsonnet.Program::from_ast(tree).evaluate(), [42, 7])
  assert_eq(
    @moonjsonnet.evaluate(
      "local x=100,run(f=function(n)if n==0 then x else g(n-1),g=function(n)if n==0 then x else f(n-1),x=42)=f(3); [run(),run(x=7)]",
    ),
    [42, 7],
  )
}

///|
test "handmade application rejects invalid bindings before any native demand" {
  let mut calls = 0
  let tick : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      calls += 1
      42
    },
  }
  let argument = call_native("tick")
  let function = call_ast(
    Func(
      [
        { name: "req", default_value: None, range: None, },
        { name: "opt", default_value: Some(argument), range: None, },
      ],
      argument,
    ),
  )
  let cases : Array[Array[(String?, @moonjsonnet.Ast)]] = [
    [],
    [(Some("req"), argument), (Some("unknown"), argument)],
    [(None, argument), (Some("req"), argument)],
    [(None, argument), (None, argument), (None, argument)],
  ]
  for arguments in cases {
    let program = @moonjsonnet.Program::from_ast(
      call_ast(Call(function, arguments, false)),
    )
    try program.evaluate(native_functions=Map([("tick", tick)])) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
    } noraise {
      _ => fail("invalid handmade application succeeded")
    }
    assert_eq(calls, 0)
  }
}

///|
test "callee errors and nonfunctions precede argument callbacks in source and handmade AST" {
  let events : Array[String] = []
  let head : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      events.push("head")
      7
    },
  }
  let tick : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      events.push("argument")
      42
    },
  }
  let natives = Map([("head", head), ("tick", tick)])
  let object = call_ast(Obj([], [], [(call_ast(Literal(false)), None)]))
  for
    (source, target, kind, expected_events) in [
      (
        "(std.native('head')())(unknown=std.native('tick')())",
        call_native("head"),
        @moonjsonnet.Type,
        ["head"],
      ),
      (
        "(error 'callee')(unknown=std.native('tick')())",
        call_ast(Fail(call_ast(Literal("callee")))),
        @moonjsonnet.Runtime,
        [],
      ),
      (
        "({assert false})(unknown=std.native('tick')())",
        object,
        @moonjsonnet.Type,
        [],
      ),
    ] {
    let synthetic = @moonjsonnet.Program::from_ast(
      call_ast(Call(target, [(Some("unknown"), call_native("tick"))], false)),
    )
    for entry in [@moonjsonnet.Program::parse(source), synthetic] {
      events.clear()
      try entry.evaluate(native_functions=natives) catch {
        @moonjsonnet.Error(d) => {
          assert_eq(d.kind, kind)
          if kind == @moonjsonnet.Runtime {
            assert_eq(d.message, "callee")
          }
        }
      } noraise {
        _ => fail("invalid callee succeeded")
      }
      assert_eq(events, expected_events)
    }
  }
}

///|
test "unselected invalid calls skip callee and argument construction demands" {
  let mut calls = 0
  let tick : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      calls += 1
      7
    },
  }
  let unused = call_ast(
    Call(call_native("tick"), [(Some("unknown"), call_native("tick"))], false),
  )
  let tree = call_ast(
    Local(
      [{ name: "unused", value: unused, range: None, }],
      call_ast(Literal(42)),
    ),
  )
  for
    entry in [
      @moonjsonnet.Program::parse(
        "local unused=(std.native('tick')())(unknown=std.native('tick')());42",
      ),
      @moonjsonnet.Program::from_ast(tree),
    ] {
    assert_eq(entry.evaluate(native_functions=Map([("tick", tick)])), 42)
    assert_eq(calls, 0)
  }
}

///|
test "handmade duplicate names and undefined supplied expressions reject before application" {
  let function = call_ast(
    Func(
      [{ name: "a", default_value: None, range: None, }],
      call_ast(Literal(42)),
    ),
  )
  for
    expression in [
      call_ast(
        Call(
          function,
          [(Some("a"), call_ast(Literal(1))), (Some("a"), call_ast(Literal(2)))],
          false,
        ),
      ),
      call_ast(
        Call(
          call_ast(Func([], call_ast(Literal(42)))),
          [(Some("unknown"), call_ast(Var("missing")))],
          false,
        ),
      ),
    ] {
    let unused = call_ast(
      If(call_ast(Literal(false)), expression, call_ast(Literal(42))),
    )
    try @moonjsonnet.Program::from_ast(unused) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
    } noraise {
      _ => fail("semantic invalidity escaped handmade AST validation")
    }
  }
  for
    source in [
      "if false then (function(a)42)(a=1,a=2) else 42", "if false then (function()42)(unknown=missing) else 42",
    ] {
    try @moonjsonnet.Program::parse(source) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
    } noraise {
      _ => fail("semantic invalidity escaped source validation")
    }
  }
}

///|
test "malformed call and default expressions reject as source syntax errors" {
  for source in ["(function(a)a)(a=)", "(function(a=)a)()", "(function(a)a)(1"] {
    try @moonjsonnet.Program::parse(source, filename="call-source") catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Syntax)
        assert_eq(d.location.file, "call-source")
      }
    } noraise {
      _ => fail("malformed call source accepted")
    }
  }
}
