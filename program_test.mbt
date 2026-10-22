///|
test "program parsing validates statics without evaluating runtime code" {
  for
    (source, kind) in [
      ("local", @moonjsonnet.Syntax),
      ("missing", @moonjsonnet.Static),
    ] {
    try @moonjsonnet.Program::parse(source, filename="parsed.jsonnet") catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, kind)
        assert_eq(d.location.file, "parsed.jsonnet")
      }
    } noraise {
      _ => fail("expected parse error")
    }
  }
  let program = @moonjsonnet.Program::parse(
    "error 'deferred'",
    filename="parsed.jsonnet",
  )
  for _ in 0..<2 {
    try program.evaluate() catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Runtime)
        assert_eq(d.message, "deferred")
        assert_eq(d.location.file, "parsed.jsonnet")
      }
    } noraise {
      _ => fail("expected runtime error")
    }
  }
  ignore(@moonjsonnet.Program::parse("import 'unavailable'"))
}

///|
test "program arguments and failures are independent on repeated execution" {
  let program = @moonjsonnet.Program::parse("function(n=2) std.extVar('x') * n")
  assert_eq(program.evaluate(ext_vars=Map([("x", 21)])), 42)
  assert_eq(
    program.evaluate(ext_code=Map([("x", "6*7")]), tla_code=Map([("n", "3")])),
    126,
  )
  try program.evaluate() catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
  } noraise {
    _ => fail("expected missing external variable")
  }
  assert_eq(
    program.evaluate(ext_vars=Map([("x", 5)]), tla_vars=Map([("n", 3)])),
    15,
  )
}

///|
test "program output methods share formatting but not output budgets" {
  let program = @moonjsonnet.Program::parse("[std.extVar('x'), 'é']")
  for _ in 0..<2 {
    assert_eq(
      program
      .evaluate(ext_vars=Map([("x", 42)]), limits={
        ..@moonjsonnet.Limits::default(),
        output_bytes: 9,
      })
      .stringify(),
      "[42,\"é\"]",
    )
    assert_eq(
      program.evaluate_text(ext_vars=Map([("x", 42)])),
      "[\n   42,\n   \"é\"\n]\n",
    )
    assert_eq(program.evaluate_stream(ext_vars=Map([("x", 42)])), [
      "42\n", "\"é\"\n",
    ])
  }
  let files = @moonjsonnet.Program::parse("{a:std.extVar('x'),b:'raw'}")
  assert_eq(files.evaluate_multi(ext_vars=Map([("x", 42)]))["a"], "42\n")
  assert_eq(
    files.evaluate_multi(
      ext_vars=Map([("x", Json::string("value"))]),
      string_output=true,
    )["a"],
    "value",
  )
  let raw = @moonjsonnet.Program::parse("'a\\u0000é'")
  assert_eq(raw.evaluate_text(string_output=true), "a\u0000é\n")
}

///|
test "program preserves source origin and resets import caches" {
  let mut calls = 0
  let mut content = "1"
  let origins = []
  let resolver : (String, String) -> @moonjsonnet.Source raise = (from, path) => {
    calls += 1
    origins.push((from, path))
    { id: "lib/dep", text: content, }
  }
  let named = @moonjsonnet.Program::parse(
    "[std.thisFile,import 'dep',import 'dep']",
    filename="dir/main",
  )
  assert_eq(named.evaluate(resolver~).stringify(), "[\"dir/main\",1,1]")
  assert_eq(calls, 1)
  content = "2"
  assert_eq(named.evaluate(resolver~).stringify(), "[\"dir/main\",2,2]")
  assert_eq(calls, 2)
  assert_eq(origins, [("dir/main", "dep"), ("dir/main", "dep")])
  let anonymous = @moonjsonnet.Program::parse(
    "[std.thisFile,import 'dep']",
    filename="diagnostic",
    anonymous=true,
  )
  content = "std.thisFile"
  assert_eq(anonymous.evaluate(resolver~).stringify(), "[\"\",\"lib/dep\"]")
  assert_eq(origins.last(), Some(("", "dep")))
  content = "local"
  try named.evaluate(resolver~) catch {
    @moonjsonnet.Error(d) => assert_eq(d.location.file, "lib/dep")
  } noraise {
    _ => fail("expected imported syntax error")
  }
  content = "3"
  assert_eq(named.evaluate(resolver~).stringify(), "[\"dir/main\",3,3]")
}

///|
test "program native functions traces and binary imports use each call configuration" {
  let program = @moonjsonnet.Program::parse(
    "std.trace('call', std.native('f')(importbin 'bytes'))",
    filename="native.jsonnet",
  )
  let traces = []
  for n in [1, 2] {
    let native : @moonjsonnet.NativeFunction = {
      params: ["x"],
      callback: _ => Json::number(n.to_double()),
    }
    assert_eq(
      program.evaluate(
        native_functions=Map([("f", native)]),
        trace=fn(loc, text) { traces.push((loc.file, text)) },
        binary_resolver=fn(_, path) { { id: path, bytes: b"\xff", } },
      ),
      Json::number(n.to_double()),
    )
  }
  assert_eq(traces, [("native.jsonnet", "call"), ("native.jsonnet", "call")])
}

///|
test "program execution rechecks byte and AST budgets and recovers after limits" {
  let limits = @moonjsonnet.Limits::default()
  let program = @moonjsonnet.Program::parse("local x=42; [x,x]", limits~)
  for
    bound in [
      { ..limits, source_bytes: 1, },
      { ..limits, depth: 1, },
      { ..limits, stack: 1, },
      { ..limits, steps: 1, },
      { ..limits, output_bytes: 1, },
    ] {
    try program.evaluate(limits=bound) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
    } noraise {
      _ => fail("expected current execution limit")
    }
    assert_eq(program.evaluate().stringify(), "[42,42]")
  }
  for
    bound in [
      { ..limits, depth: 1, },
      { ..limits, source_bytes: 1, },
      { ..limits, steps: 0, },
    ] {
    try @moonjsonnet.Program::parse("[42]", limits=bound) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
    } noraise {
      _ => fail("expected creation limit")
    }
  }
}

///|
test "program object and array mutation cannot contaminate later evaluations" {
  for
    (source, expected) in [
      ("local a=[1,2,3]; [std.removeAt(a,0),a]", "[[2,3],[1,2,3]]"),
      ("local o={local x=21,a:x*2,b:self.a}; o+{a:1}", "{\"a\":1,\"b\":1}"),
      (
        "local f(n)=if n==0 then 42 else f(n-1) tailstrict; f(1000) tailstrict",
        "42",
      ),
    ] {
    let program = @moonjsonnet.Program::parse(source)
    for _ in 0..<3 {
      assert_eq(program.evaluate().stringify(), expected)
    }
  }
}
