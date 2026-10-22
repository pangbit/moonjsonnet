///|
test "parsed parameters share a thunk only within one execution" {
  let node = @moonjsonnet.Program::parse("std.native('tick')()")
  let program = @moonjsonnet.Program::parse(
    "function(x) [x,x,std.extVar('x'),std.extVar('x')]",
  )
  let mut calls = 0
  let native : @moonjsonnet.NativeFunction = {
    params: [],
    callback: fn(_) {
      calls += 1
      Json::number(calls.to_double())
    },
  }
  for n in [0, 2] {
    let result = program.evaluate(
      ext_programs=Map([("x", node)]),
      tla_programs=Map([("x", node)]),
      native_functions=Map([("tick", native)]),
    )
    assert_eq(
      result,
      Json::array(
        [n + 1, n + 1, n + 2, n + 2].map(n => Json::number(n.to_double())),
      ),
    )
  }
  assert_eq(calls, 4)
}

///|
test "parsed parameter bindings override code and JSON across output entrypoints" {
  let number = @moonjsonnet.Program::parse("42")
  let ext_programs = Map([("x", number)])
  let tla_programs = Map([("x", number)])
  assert_eq(
    @moonjsonnet.evaluate(
      "std.extVar('x')",
      ext_vars=Map([("x", 1)]),
      ext_code=Map([("x", "invalid !")]),
      ext_programs~,
    ),
    42,
  )
  assert_eq(
    @moonjsonnet.evaluate(
      "function(x) x",
      tla_vars=Map([("x", 1)]),
      tla_code=Map([("x", "invalid !")]),
      tla_programs~,
    ),
    42,
  )
  assert_eq(
    @moonjsonnet.evaluate_text("std.extVar('x')", ext_programs~),
    "42\n",
  )
  assert_eq(@moonjsonnet.evaluate_stream("function(x) [x]", tla_programs~), [
    "42\n",
  ])
  assert_eq(
    @moonjsonnet.evaluate_multi("{a:std.extVar('x')}", ext_programs~)["a"],
    "42\n",
  )
  assert_eq(
    @moonjsonnet.Program::parse("function(x) x").evaluate_text(tla_programs~),
    "42\n",
  )
  assert_eq(
    @moonjsonnet.Program::parse("[std.extVar('x')]").evaluate_stream(
      ext_programs~,
    ),
    ["42\n"],
  )
  assert_eq(
    @moonjsonnet.Program::parse("function(x) {a:x}").evaluate_multi(
      tla_programs~,
    )["a"],
    "42\n",
  )
}

///|
test "parsed parameter retains diagnostics and import origin with synthetic thisFile" {
  let requests = []
  let resolver : (String, String) -> @moonjsonnet.Source raise = (from, path) => {
    requests.push((from, path))
    { id: "resolved/dep", text: "std.thisFile", }
  }
  let node = @moonjsonnet.Program::parse(
    "[std.thisFile,import 'dep']",
    filename="nodes/source.jsonnet",
  )
  assert_eq(
    @moonjsonnet.evaluate(
      "std.extVar('x')",
      ext_programs=Map([("x", node)]),
      resolver~,
    ),
    ["<extvar:x>", "resolved/dep"],
  )
  assert_eq(requests, [("nodes/source.jsonnet", "dep")])
  let anonymous = @moonjsonnet.Program::parse(
    "import 'dep'",
    filename="diagnostic",
    anonymous=true,
  )
  assert_eq(
    @moonjsonnet.evaluate(
      "function(x) x",
      tla_programs=Map([("x", anonymous)]),
      resolver~,
    ),
    Json::string("resolved/dep"),
  )
  assert_eq(requests.last(), Some(("", "dep")))
  let broken = @moonjsonnet.Program::parse(
    "\nerror 'node failure'",
    filename="nodes/error.jsonnet",
  )
  try
    @moonjsonnet.evaluate("std.extVar('x')", ext_programs=Map([("x", broken)]))
  catch {
    @moonjsonnet.Error(d) => {
      assert_eq(d.kind, @moonjsonnet.Runtime)
      assert_eq(d.location.file, "nodes/error.jsonnet")
      assert_eq(d.location.line, 2)
      assert_eq(d.message, "node failure")
    }
  } noraise {
    _ => fail("expected parameter error")
  }
}

///|
test "parsed parameter budgets are lazy and checked against current execution" {
  let source = @moonjsonnet.Program::parse("[1,2,3,4,5,6,7,8,9,10]")
  let ext_programs = Map([("x", source)])
  let limits = { ..@moonjsonnet.Limits::default(), source_bytes: 16, }
  assert_eq(@moonjsonnet.evaluate("42", ext_programs~, limits~), 42)
  try @moonjsonnet.evaluate("std.extVar('x')", ext_programs~, limits~) catch {
    @moonjsonnet.Error(d) => {
      assert_eq(d.kind, @moonjsonnet.Limit)
      assert_eq(d.location.file, "<extvar:x>")
    }
  } noraise {
    _ => fail("expected parameter byte budget")
  }
  let deep = @moonjsonnet.Program::parse("[[[[[42]]]]]")
  let tla_programs = Map([("x", deep)])
  let limits = { ..@moonjsonnet.Limits::default(), depth: 4, }
  assert_eq(@moonjsonnet.evaluate("function(x) 42", tla_programs~, limits~), 42)
  try @moonjsonnet.evaluate("function(x) x", tla_programs~, limits~) catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected parameter AST depth budget")
  }
  assert_eq(@moonjsonnet.evaluate("function(x) x", tla_programs~), [[[[[42]]]]])
}

///|
test "parsed parameter failure and container mutation do not escape an execution" {
  let node = @moonjsonnet.Program::parse("[std.extVar('answer')]")
  let program = @moonjsonnet.Program::parse("std.extVar('x')")
  try program.evaluate(ext_programs=Map([("x", node)])) catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
  } noraise {
    _ => fail("expected missing nested external")
  }
  assert_eq(
    program.evaluate(
      ext_programs=Map([("x", node)]),
      ext_vars=Map([("answer", 42)]),
    ),
    [42],
  )
  let array = @moonjsonnet.Program::parse("[1,2,3]")
  for _ in 0..<2 {
    assert_eq(
      @moonjsonnet.evaluate(
        "local a=std.extVar('x'); [std.removeAt(a,0),a]",
        ext_programs=Map([("x", array)]),
      ),
      [[2, 3], [1, 2, 3]],
    )
  }
}
