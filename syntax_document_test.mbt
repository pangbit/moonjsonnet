///|
test "syntax documents admit and export flat deep trees independently" {
  let limits = { ..@moonjsonnet.SyntaxLimits::default(), parser_depth: 8, }
  let source = "0" + "+1".repeat(3999)
  let document = @moonjsonnet.SyntaxDocument::parse(
    source,
    filename="deep",
    limits~,
  )
  assert_eq(document.text(), source)
  let formatted = document.format(limits~)
  assert_eq(formatted, "0" + " + 1".repeat(3999) + "\n")
  assert_eq(@moonjsonnet.format_syntax_source(formatted, limits~), formatted)
  let mut current = document.ast()
  let mut depth = 0
  while current.kind is Binary("+", left, right) {
    assert_true(right.kind is NumberLiteral("1"))
    current = left
    depth += 1
  }
  assert_eq(depth, 3999)
  assert_true(current.kind is NumberLiteral("0"))
  assert_eq(current.loc.file, "deep")
  for
    parse in [
      () => ignore(@moonjsonnet.Program::parse(source)),
      () => ignore(@moonjsonnet.ParsedSource::parse(source)),
      () => ignore(@moonjsonnet.Program::from_ast(document.ast())),
    ] {
    try parse() catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
    } noraise {
      _ => fail("syntax admission must not expand evaluator admission")
    }
  }
}

///|
test "syntax source budgets count complete tree nodes and UTF8 bytes" {
  let defaults = @moonjsonnet.SyntaxLimits::default()
  let source = "[1+2]"
  let exact = { ..defaults, tree_depth: 3, nodes: 4, source_bytes: 5, }
  let document = @moonjsonnet.SyntaxDocument::parse(source, limits=exact)
  assert_eq(document.format(limits=exact), "[1 + 2]\n")
  for
    constrained in [
      { ..exact, tree_depth: 2, },
      { ..exact, nodes: 3, },
      { ..exact, source_bytes: 4, },
    ] {
    for
      operation in [
        () => {
          ignore(@moonjsonnet.SyntaxDocument::parse(source, limits=constrained))
        },
        () => ignore(document.format(limits=constrained)),
      ] {
      try operation() catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
      } noraise {
        _ => fail("complete syntax budget ignored")
      }
    }
  }
  assert_eq(
    @moonjsonnet.SyntaxDocument::parse("'中'", limits={
      ..defaults,
      source_bytes: 5,
    }).text(),
    "'中'",
  )
  try
    @moonjsonnet.SyntaxDocument::parse("'中'", limits={
      ..defaults,
      source_bytes: 4,
    })
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.message, "source byte limit exceeded")
  } noraise {
    _ => fail("source budget must use UTF8 bytes")
  }
  // Object assertions, defaults and comprehension clauses count too.
  for
    (source, nodes) in [
      ("{assert true: 'message', a: 1}", 5),
      ("function(x=1) x", 3),
      ("[x for x in [1] if true]", 5),
    ] {
    ignore(
      @moonjsonnet.SyntaxDocument::parse(source, limits={ ..defaults, nodes, }),
    )
    try
      @moonjsonnet.SyntaxDocument::parse(source, limits={
        ..defaults,
        nodes: nodes - 1,
      })
    catch {
      @moonjsonnet.Error(d) =>
        assert_eq(d.message, "syntax tree node limit exceeded")
    } noraise {
      _ => fail("syntax child omitted from admission")
    }
  }
}

///|
test "syntax formatting retains recursive parser and work output limits" {
  let defaults = @moonjsonnet.SyntaxLimits::default()
  for
    constrained in [
      { ..defaults, parser_depth: 0, },
      { ..defaults, parser_depth: 513, },
      { ..defaults, tree_depth: 0, },
      { ..defaults, tree_depth: 16385, },
      { ..defaults, nodes: 0, },
      { ..defaults, steps: 0, },
      { ..defaults, source_bytes: 0, },
      { ..defaults, output_bytes: 0, },
    ] {
    try @moonjsonnet.format_syntax_source("42", limits=constrained) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
    } noraise {
      _ => fail("invalid syntax budget accepted")
    }
  }
  let nested = "[".repeat(16) + "1" + "]".repeat(16)
  try
    @moonjsonnet.SyntaxDocument::parse(nested, limits={
      ..defaults,
      parser_depth: 8,
    })
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("recursive parser budget ignored")
  }
  for
    (source, constrained, message) in [
      ("[1,2]", { ..defaults, steps: 1, }, "format step limit exceeded"),
      (
        "42",
        { ..defaults, output_bytes: 2, },
        "format output byte limit exceeded",
      ),
    ] {
    try @moonjsonnet.format_syntax_source(source, limits=constrained) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
    } noraise {
      _ => fail(message)
    }
  }
  assert_eq(
    @moonjsonnet.format_syntax_source("42", limits={
      ..defaults,
      output_bytes: 3,
    }),
    "42\n",
  )
  try @moonjsonnet.SyntaxDocument::parse("[1,") catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Syntax)
  } noraise {
    _ => fail("invalid syntax accepted")
  }
}

///|
test "syntax documents retain source and isolate exports without evaluation" {
  let source = "/*head*/ [import 'missing', unknown, @'中'] //tail\r\n"
  let document = @moonjsonnet.SyntaxDocument::parse(source, filename="syntax")
  let parts = document.parts()
  assert_eq(parts.map(p => p.text).join(""), source)
  parts.clear()
  assert_eq(document.parts().map(p => p.text).join(""), source)
  let ast = document.ast()
  guard ast.kind is Arr(items) else { fail("array syntax") }
  items.clear()
  guard document.ast().kind is Arr(items) else { fail("array syntax") }
  assert_eq(items.length(), 3)
  assert_eq(document.text(), source)
  let formatted = document.format()
  assert_eq(formatted, "/*head*/ [import 'missing', unknown, @'中']  //tail\n")
  assert_eq(document.text(), source)
  assert_eq(@moonjsonnet.format_syntax_source(formatted), formatted)
}
