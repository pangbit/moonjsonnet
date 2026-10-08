///|
test "external code values use a clean environment and memoized thunks" {
  let events : Array[String] = []
  let code = Map([
    ("x", "std.trace('once', {a: 40+2, hidden::error 'hidden'})"),
    ("f", "function(x) x+std.extVar('x').a"),
    ("unused", "not valid Jsonnet !"),
  ])
  assert_eq(
    @moonjsonnet.evaluate(
      "local x=100; [std.extVar('x'),std.extVar('x'),std.extVar('f')(1)]",
      ext_code=code,
      trace=fn(_, message) { events.push(message) },
    ),
    [{ "a": 42 }, { "a": 42 }, 43],
  )
  assert_eq(events, ["once"])
  assert_eq(
    @moonjsonnet.evaluate(
      "std.extVar('x')",
      ext_vars=Map([("x", 1)]),
      ext_code=Map([("x", "2")]),
    ),
    2,
  )
  assert_eq(
    @moonjsonnet.evaluate("std.extVar('')", ext_code=Map([("", "42")])),
    42,
  )
  assert_eq(
    @moonjsonnet.evaluate(
      "std.extVar('x')",
      ext_vars=Map([("x", Json::string("local x=1; x"))]),
    ),
    Json::string("local x=1; x"),
  )
}

///|
test "parameter code diagnostics imports thisFile and shared host callbacks" {
  let requests : Array[(String, String)] = []
  let events : Array[(@moonjsonnet.Location, String)] = []
  let native : @moonjsonnet.NativeFunction = {
    params: [],
    callback: fn(_) { 42 },
  }
  let resolver : (String, String) -> @moonjsonnet.Source raise = fn(
    from,
    path,
  ) {
    requests.push((from, path))
    {
      id: "lib.jsonnet",
      text: "{value:std.native('answer')(),file:std.thisFile}",
    }
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "function(p) [std.thisFile,std.extVar('x'),p]",
      filename="entry.jsonnet",
      ext_code=Map([
        ("x", "std.trace('parameter', [std.thisFile, import 'lib'])"),
      ]),
      tla_code=Map([("p", "[std.thisFile,import 'lib',importbin 'bytes']")]),
      resolver~,
      binary_resolver=fn(from, path) {
        requests.push((from, path))
        { id: "bytes", bytes: b"\xff", }
      },
      native_functions=Map([("answer", native)]),
      trace=fn(loc, s) { events.push((loc, s)) },
    ),
    [
      "entry.jsonnet",
      ["<extvar:x>", { "value": 42, "file": "lib.jsonnet" }],
      ["<top-level-arg:p>", { "value": 42, "file": "lib.jsonnet" }, [255]],
    ],
  )
  assert_eq(requests, [("", "lib"), ("", "bytes")])
  assert_eq(events[0].0.file, "<extvar:x>")
  assert_eq(events[0].1, "parameter")
  for
    (code, kind, line) in [
      ("\nerror 'bad'", @moonjsonnet.Runtime, 2),
      ("\nmissing", @moonjsonnet.Static, 2),
      ("\n{", @moonjsonnet.Syntax, 2),
    ] {
    try
      @moonjsonnet.evaluate("std.extVar('x')", ext_code=Map([("x", code)]))
    catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, kind)
        assert_eq(d.location.file, "<extvar:x>")
        assert_eq(d.location.line, line)
      }
    } noraise {
      _ => fail("expected parameter error")
    }
  }
}

///|
test "top-level arguments defaults named calls and one application" {
  assert_eq(
    @moonjsonnet.evaluate("std.length", tla_vars=Map([("x", [1, 2, 3])])),
    3,
  )
  let native : @moonjsonnet.NativeFunction = {
    params: ["x"],
    callback: args => args[0],
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "std.native('id')",
      native_functions=Map([("id", native)]),
      tla_code=Map([("x", "{answer:42}")]),
    ),
    { "answer": 42 },
  )
  assert_eq(
    @moonjsonnet.evaluate(
      "function(a,b=a+1,c=error 'unused') [a,b]",
      tla_code=Map([("a", "40+2")]),
    ),
    [42, 43],
  )
  assert_eq(
    @moonjsonnet.evaluate(
      "function(a) a",
      tla_vars=Map([("a", { "é😀": [true, null] })]),
    ),
    { "é😀": [true, null] },
  )
  assert_eq(
    @moonjsonnet.evaluate(
      "function(a) a(21)",
      tla_code=Map([("a", "function(x) x*2")]),
    ),
    42,
  )
  assert_eq(
    @moonjsonnet.evaluate(
      "function(a) a",
      tla_vars=Map([("a", 1)]),
      tla_code=Map([("a", "2")]),
    ),
    2,
  )
  assert_eq(@moonjsonnet.evaluate("function(a=42) a"), 42)
  assert_eq(
    @moonjsonnet.evaluate(
      "{x:42}",
      tla_code=Map([("unknown", "invalid code !")]),
    ),
    { "x": 42 },
  )
  assert_eq(
    @moonjsonnet.evaluate(
      "function(a) 42",
      tla_code=Map([("a", "invalid code !")]),
    ),
    42,
  )
  assert_eq(
    @moonjsonnet.evaluate(
      "function(a) a",
      tla_code=Map([("a", "std.extVar('x')+1")]),
      ext_code=Map([("x", "41")]),
    ),
    42,
  )
  for source in ["function(a) a", "function() function()42"] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(_) => ()
    } noraise {
      _ => fail("expected missing argument or returned-function error")
    }
  }
  try
    @moonjsonnet.evaluate(
      "function()42",
      tla_code=Map([("unknown", "error 'unused'")]),
    )
  catch {
    @moonjsonnet.Error(d) => {
      assert_eq(d.kind, @moonjsonnet.Runtime)
      assert_eq(d.message, "function has no parameter unknown")
    }
  } noraise {
    _ => fail("expected unknown argument")
  }
}

///|
test "parameters retain laziness isolate scopes and reset per evaluation" {
  let events : Array[String] = []
  let trace = fn(_, s) { events.push(s) }
  assert_eq(
    @moonjsonnet.evaluate(
      "function(a,b) [a,a]",
      tla_code=Map([("a", "std.trace('once',42)"), ("b", "error 'unused'")]),
      trace~,
    ),
    [42, 42],
  )
  assert_eq(events, ["once"])
  for
    (source, ext, tla, file) in [
      ("local x=42; std.extVar('a')", Map([("a", "x")]), Map([]), "<extvar:a>"),
      (
        "function(a,b) b",
        Map([]),
        Map([("a", "42"), ("b", "a")]),
        "<top-level-arg:b>",
      ),
    ] {
    try @moonjsonnet.evaluate(source, ext_code=ext, tla_code=tla) catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Static)
        assert_eq(d.location.file, file)
      }
    } noraise {
      _ => fail("expected clean parameter scope")
    }
  }
  try
    @moonjsonnet.evaluate(
      "std.extVar('cycle')",
      ext_code=Map([("cycle", "std.extVar('cycle')")]),
    )
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
  } noraise {
    _ => fail("expected cyclic parameter error")
  }
  for _ in 0..<2 {
    assert_eq(
      @moonjsonnet.evaluate(
        "std.extVar('a')",
        ext_code=Map([("a", "std.trace('fresh',42)")]),
        trace~,
      ),
      42,
    )
  }
  assert_eq(events, ["once", "fresh", "fresh"])
  try @moonjsonnet.evaluate("std.extVar('a')") catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
  } noraise {
    _ => fail("expected fresh registration map")
  }
}

///|
test "parameter source evaluation and import budgets remain bounded" {
  let limits = @moonjsonnet.Limits::default()
  for
    (code, restricted) in [
      ("'" + "x".repeat(100) + "'", { ..limits, source_bytes: 50, }),
      ("local f(x)=f(x+1); f(0)", { ..limits, depth: 20, }),
      ("std.range(0,100)", { ..limits, steps: 100, }),
      ("'" + "x".repeat(100) + "'", { ..limits, output_bytes: 50, }),
    ] {
    try
      @moonjsonnet.evaluate(
        "function(a) a",
        tla_code=Map([("a", code)]),
        limits=restricted,
      )
    catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
    } noraise {
      _ => fail("expected parameter resource limit")
    }
  }
  try
    @moonjsonnet.evaluate(
      "std.extVar('a')",
      ext_code=Map([("a", "import 'lib'")]),
      resolver=fn(_, _) { { id: "lib", text: "42", } },
      limits={ ..limits, import_bytes: 1, },
    )
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected shared import byte budget")
  }
}
