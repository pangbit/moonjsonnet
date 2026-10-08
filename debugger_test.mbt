///|
test "debugger supports breakpoints inspection continue and clear" {
  let source = "local x=21;\nx*2"
  let program = @moonjsonnet.Program::parse(source, filename="debug.jsonnet")
  let debugger = @moonjsonnet.Debugger::new()
  assert_eq(
    debugger.set_breakpoint(program, 2, column=1),
    "debug.jsonnet:2:1-4",
  )
  let bps = debugger.active_breakpoints()
  bps.clear()
  assert_eq(debugger.active_breakpoints(), ["debug.jsonnet:2:1-4"])
  let stopped : Array[String] = []
  let result = debugger.run(program, on_stop=stop => {
    assert_eq(stop.reason, @moonjsonnet.DebugStopReason::Breakpoint)
    assert_eq(stop.context.variables(), ["$std", "std", "x"])
    assert_true(stop.context.peek("x") is None)
    assert_eq(stop.context.lookup("x").json(), 21)
    stopped.push(stop.context.source_range().unwrap().format())
    Continue
  })
  assert_eq(result, "42\n")
  assert_eq(stopped, ["debug.jsonnet:2:1-4"])
  debugger.clear_breakpoints("other")
  assert_eq(debugger.active_breakpoints().length(), 1)
  debugger.clear_breakpoints("debug.jsonnet")
  assert_eq(debugger.active_breakpoints(), [])
  try debugger.set_breakpoint(program, 99) catch {
    @moonjsonnet.Error(d) => assert_eq(d.message, "breakpoint location invalid")
  } noraise {
    _ => fail("invalid breakpoint accepted")
  }
}

///|
test "debugger steps over literals and finishes selected expressions" {
  let program = @moonjsonnet.Program::parse(
    "local f(x)=x+1;[f(20),f(41)]",
    filename="entry",
  )
  let debugger = @moonjsonnet.Debugger::new()
  let ranges : Array[String] = []
  let result = debugger.run(program, start_with_step=true, on_stop=stop => {
    assert_eq(stop.reason, @moonjsonnet.DebugStopReason::Step)
    ranges.push(stop.context.source_range().unwrap().format())
    if stop.context.node().kind is Call(_, _, _) {
      Finish
    } else {
      Step
    }
  })
  assert_eq(result, "[\n   21,\n   42\n]\n")
  assert_eq(ranges, [
    "entry:1:1-29", "entry:1:16-29", "entry:1:17-22", "entry:1:23-28",
  ])
}

///|
test "debugger exceptions termination recovery and previous hooks" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let mut previous_calls = 0
  evaluator.set_eval_hook(hook={
    before: _ => previous_calls += 1,
    after: (_, _) => (),
  })
  let debugger = @moonjsonnet.Debugger::new(evaluator~)
  let mut exceptions = 0
  let failure = @moonjsonnet.Program::parse("error 'failed'", filename="entry")
  try
    debugger.run(failure, on_stop=stop => {
      assert_eq(stop.reason, @moonjsonnet.DebugStopReason::Exception)
      guard stop.outcome is Some(Failure(d)) else { fail("exception outcome") }
      assert_eq(d.message, "failed")
      exceptions += 1
      Continue
    })
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.message, "failed")
  } noraise {
    _ => fail("debugger swallowed exception")
  }
  assert_eq(exceptions, 1)
  assert_eq(previous_calls, 0)
  let good = @moonjsonnet.Program::parse("local x=42;x", filename="entry")
  try debugger.run(good, start_with_step=true, on_stop=_ => Terminate) catch {
    @moonjsonnet.Error(d) => assert_eq(d.message, "debugger terminated")
  } noraise {
    _ => fail("termination ignored")
  }
  assert_eq(debugger.run(good, on_stop=_ => Continue), "42\n")
  assert_eq(previous_calls, 0)
  assert_eq(evaluator.evaluate(good), 42)
  assert_true(previous_calls > 0)
}

///|
test "debugger callback rejects reentry and retains caller configuration" {
  let evaluator = @moonjsonnet.Evaluator::new()
  evaluator.ext_var("x", 42)
  let debugger = @moonjsonnet.Debugger::new(evaluator~)
  let program = @moonjsonnet.Program::parse("std.extVar('x')", filename="entry")
  assert_eq(
    debugger.run(program, start_with_step=true, on_stop=_ => {
      try debugger.run(program, on_stop=_ => Continue) catch {
        @moonjsonnet.Error(d) =>
          assert_eq(d.message, "debugger is already executing")
      } noraise {
        _ => fail("debugger reentry accepted")
      }
      Continue
    }),
    "42\n",
  )
  assert_eq(evaluator.evaluate(program), 42)
}

///|
test "breakpoint enumeration follows lowered order and preserves owned ranges" {
  let program = @moonjsonnet.Program::parse(
    "local x=21;\n((x*2))",
    filename="entry",
  )
  let locations = @moonjsonnet.Debugger::breakpoint_locations(program)
  assert_eq(locations.map(range => range.format()), [
    "entry:(1:1)-(2:8)", "entry:2:3-6", "entry:2:3-4", "entry:2:5-6", "entry:1:9-11",
  ])
  locations.clear()
  assert_eq(@moonjsonnet.Debugger::breakpoint_locations(program).length(), 5)
}

///|
test "assert failures expose their lowered error breakpoint and parent exception" {
  let program = @moonjsonnet.Program::parse(
    "assert false : 'bad';42",
    filename="entry",
  )
  let debugger = @moonjsonnet.Debugger::new()
  ignore(debugger.set_breakpoint(program, 1, column=1))
  let reasons : Array[@moonjsonnet.DebugStopReason] = []
  let ranges : Array[String?] = []
  try
    debugger.run(program, on_stop=stop => {
      reasons.push(stop.reason)
      ranges.push(stop.context.source_range().map(range => range.format()))
      Continue
    })
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.message, "bad")
  } noraise {
    _ => fail("assert failure was swallowed")
  }
  assert_eq(reasons, [Breakpoint, Exception, Exception])
  assert_eq(ranges, [Some("entry:1:1-24"), Some("entry:1:1-24"), None])
}

///|
test "Finish preserves object comprehension breakpoints and capture scopes" {
  let program = @moonjsonnet.Program::parse(
    "local n=2;\n{[std.toString(x)]: x*2 for x in [1,n] if x>0}",
    filename="entry",
  )
  let debugger = @moonjsonnet.Debugger::new()
  ignore(debugger.set_breakpoint(program, 2, column=1))
  let reasons : Array[@moonjsonnet.DebugStopReason] = []
  let names : Array[Array[String]] = []
  let output = debugger.run(program, on_stop=stop => {
    reasons.push(stop.reason)
    names.push(stop.context.variables())
    if reasons.length() <= 2 {
      Finish
    } else {
      Continue
    }
  })
  assert_eq(@json.parse(output), { "1": 2, "2": 4 })
  assert_eq(reasons, [Breakpoint, Breakpoint, Step, Breakpoint])
  assert_eq(names, [
    ["$std", "n", "std"],
    ["$std", "n", "std"],
    ["std", "x"],
    ["std", "x"],
  ])
}
