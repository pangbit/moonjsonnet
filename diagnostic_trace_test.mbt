///|
test "named and synthetic diagnostic frames retain original assertion spans" {
  let program = @moonjsonnet.Program::parse(
    "local x={assert false:'failed',a:42};x",
    filename="entry",
  )
  let ranges = program.assertion_ranges()
  let copied = @moonjsonnet.Program::from_ast(
    program.ast(),
    assertion_ranges=ranges,
  )
  let diagnostics : Array[@moonjsonnet.Diagnostic] = []
  for program in [program, copied] {
    try program.evaluate() catch {
      @moonjsonnet.Error(d) => diagnostics.push(d)
    } noraise {
      _ => fail("assertion should fail")
    }
  }
  assert_eq(diagnostics[0].trace, diagnostics[1].trace)
  assert_eq(diagnostics[0].trace.map(frame => frame.location.format()), [
    "During manifestation", "Checking object assertions", "entry:1:10-31",
  ])
  ranges.clear()
  assert_true(!program.assertion_ranges().is_empty())
  assert_true(!copied.assertion_ranges().is_empty())
  let malformed = program.assertion_ranges()
  let key = malformed.keys().collect()[0]
  let range = malformed[key]
  malformed[key] = { ..range, end: { ..range.end, line: 0, }, }
  try
    @moonjsonnet.Program::from_ast(program.ast(), assertion_ranges=malformed)
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.message, "invalid AST source range")
  } noraise {
    _ => fail("invalid annotation accepted")
  }
}

///|
test "diagnostic formatter cropping source color and byte rendering" {
  let formatter = @moonjsonnet.DiagnosticFormatter::new()
  let location : @moonjsonnet.Location = { file: "entry", line: 1, column: 1, }
  let diagnostic : @moonjsonnet.Diagnostic = {
    kind: Runtime,
    message: "failed",
    location,
    context: [],
    trace: [
      { location: Synthetic("outer"), name: "", },
      { location: Synthetic("middle"), name: "", },
      {
        location: Source({ begin: location, end: { ..location, column: 3, }, }),
        name: "function <f>",
      },
    ],
  }
  let full = "RUNTIME ERROR: failed\n\tentry:1:1-3\tfunction <f>\n\tmiddle\t\n\touter\t\n"
  assert_eq(formatter.format(diagnostic), full)
  formatter.set_max_trace(1)
  assert_eq(
    formatter.format(diagnostic),
    "RUNTIME ERROR: failed\n\t...\n\touter\t\n",
  )
  formatter.set_max_trace(-1)
  assert_eq(formatter.format(diagnostic), full)
  assert_eq(formatter.format_bytes(diagnostic), @utf8.encode(full))
  let colors : Array[String] = []
  formatter.set_color(color=part => {
    colors.push(part)
    "<c>" + part + "</c>"
  })
  let source = "[1 2]"
  formatter.set_source({ id: "entry", text: source, })
  try @moonjsonnet.Program::parse(source, filename="entry") catch {
    @moonjsonnet.Error(d) => {
      assert_eq(
        formatter.format(d),
        "entry:1:4-5 Expected a comma before next array element\n\n[1 <c>2</c>]\n\n",
      )
      assert_eq(colors, ["2"])
      formatter.clear_sources()
      assert_eq(
        formatter.format(d),
        "entry:1:4-5 Expected a comma before next array element\n\n",
      )
    }
  } noraise {
    _ => fail("syntax error")
  }
  assert_eq(diagnostic.trace.length(), 3)
}

///|
test "retained assertion diagnostics and hook views own independent traces" {
  let evaluator = @moonjsonnet.Evaluator::new()
  evaluator.set_importer(resolver=(_, _) => {
    id: "library",
    text: "{assert false:'failed',a:42}",
  })
  let program = @moonjsonnet.Program::parse("import 'library'")
  let diagnostics : Array[@moonjsonnet.Diagnostic] = []
  for _ in 0..<2 {
    try evaluator.evaluate(program) catch {
      @moonjsonnet.Error(d) => diagnostics.push(d)
    } noraise {
      _ => fail("assertion error")
    }
  }
  let saved = diagnostics[1].trace.copy()
  diagnostics[0].trace.clear()
  assert_eq(diagnostics[1].trace, saved)
  let formatter = @moonjsonnet.DiagnosticFormatter::new()
  formatter.set_max_trace(1)
  evaluator.set_diagnostic_formatter(formatter~)
  assert_true(evaluator.format_error(diagnostics[1]).contains("\t...\n"))
  assert_eq(
    evaluator.format_error_bytes(diagnostics[1]),
    @utf8.encode(evaluator.format_error(diagnostics[1])),
  )
  evaluator.set_diagnostic_formatter()
  evaluator.set_eval_hook(hook={
    before: _ => (),
    after: (_, outcome) => if outcome is Failure(d) { d.trace.clear() },
  })
  try
    evaluator.evaluate(@moonjsonnet.Program::parse("error 'new failure'"))
  catch {
    @moonjsonnet.Error(d) => assert_true(!d.trace.is_empty())
  } noraise {
    _ => fail("runtime error")
  }
}

///|
test "host hook exceptions snapshot active trace and permit recovery" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let program = @moonjsonnet.Program::parse(
    "local f()=42;f()",
    filename="entry",
  )
  for before in [true, false] {
    evaluator.set_eval_hook(hook={
      before: ctx => {
        if before && ctx.node().kind is Call(_, _, _) {
          fail("host failure")
        }
      },
      after: (ctx, _) => {
        if !before && ctx.node().kind is Call(_, _, _) {
          fail("host failure")
        }
      },
    })
    try evaluator.evaluate(program) catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Runtime)
        assert_eq(d.trace.last().unwrap().location.format(), "entry:1:14-17")
        assert_eq(
          d.trace[0].location,
          @moonjsonnet.Synthetic("During evaluation"),
        )
      }
    } noraise {
      _ => fail("host error swallowed")
    }
    evaluator.set_eval_hook()
    assert_eq(evaluator.evaluate(program), 42)
  }
}
