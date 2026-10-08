///|
test "formatter changes layout without evaluating source" {
  let source = "# heading\n{ \"a\" : [1,2], x: import 'missing', y: unknown }"
  let document = @moonjsonnet.ParsedSource::parse(source)
  assert_eq(
    document.format(),
    "// heading\n{ a: [1, 2], x: import 'missing', y: unknown }\n",
  )
  assert_eq(document.text(), source)
  assert_eq(
    @moonjsonnet.format_source("error 'not executed'"),
    "error 'not executed'\n",
  )
}

///|
test "formatter preserves evaluation and is idempotent across syntax families" {
  let sources = [
    " [1,2, 3,] ", "{\"a\":1,'b-c':2,hidden::3, add+:4}", "[- -1,+ +2,!!false,~ ~1]",
    "assert true:'ok';42", "local a=1,b=2;a+b", "local f(x=1,y=2)=x+y;f(y=3)", "(function(x=1,y=2) [x,y])()",
    "{f(x=1):x}.f()", "{['x']:1,[\"y-z\"]:2}", "{'a':1}['a']", "[[1,2,3][::],[1,2,3][:2:]]",
    "[x+y for x in [1,2] if x>0 for y in [3]]", "{local y=1,[x]:y for x in ['a']}",
    "[\n1,2,\n3\n]", "{\na:1,b:2\n}", "[{a:\n1}]", "[1,// one\n2]", "[local a=1,b=2; a+b,\n4]",
    "(function(x) x)([\n1,2])", "['a\\u0062\\/\\n\\t\\u007f\\u009f中😀', @'it''s']",
  ]
  for source in sources {
    let formatted = @moonjsonnet.format_source(source)
    assert_eq(@moonjsonnet.evaluate(formatted), @moonjsonnet.evaluate(source))
    assert_eq(@moonjsonnet.format_source(formatted), formatted)
  }
}

///|
test "formatter options and stripping precedence" {
  let options = @moonjsonnet.FormatOptions::default()
  assert_eq(
    @moonjsonnet.format_source("# hi\n['abc',{a:1}]", options={
      ..options,
      string_style: DoubleQuotes,
      pad_arrays: true,
      pad_objects: false,
    }),
    "// hi\n[ \"abc\", {a: 1} ]\n",
  )
  assert_eq(
    @moonjsonnet.format_source("# hi\n42 // end", options={
      ..options,
      strip_all_but_comments: true,
      strip_everything: true,
    }),
    "// hi\nnull\n",
  )
  assert_eq(
    @moonjsonnet.format_source("# hi\n[1,\n2]", options={
      ..options,
      strip_comments: true,
      strip_everything: true,
      strip_all_but_comments: true,
    }),
    "[\n  1,\n  2,\n]\n",
  )
}

///|
test "formatter enforces resource limits and propagates parse errors" {
  let limits = @moonjsonnet.Limits::default()
  for
    (source, constrained) in [
      ("42", { ..limits, output_bytes: 2, }),
      ("[1,2]", { ..limits, steps: 1, }),
      ("42", { ..limits, source_bytes: 1, }),
      ("[[[1]]]", { ..limits, depth: 2, }),
    ] {
    try @moonjsonnet.format_source(source, limits=constrained) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
    } noraise {
      _ => fail("expected format limit")
    }
  }
  try @moonjsonnet.format_source("[1,") catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Syntax)
  } noraise {
    _ => fail("expected syntax error")
  }
}

///|
test "formatter stripping distinguishes paragraph and interstitial line endings" {
  let options = {
    ..@moonjsonnet.FormatOptions::default(),
    strip_comments: true,
  }
  for
    (source, expected) in [
      ("[1,\n/* x */\n2]", "[\n  1,\n  \n  2,\n]\n"),
      ("[1,\n/* x\n * y */\n2]", "[\n  1,\n  2,\n]\n"),
      ("[1,\n// x\n2]", "[\n  1,\n  2,\n]\n"),
    ] {
    let formatted = @moonjsonnet.format_source(source, options~)
    assert_eq(formatted, expected)
    assert_eq(@moonjsonnet.evaluate(formatted), @moonjsonnet.evaluate(source))
  }
  assert_eq(
    @moonjsonnet.format_source("1 + /* one\n more */ 2", options={
      ..options,
      indent: 0,
    }),
    "1 +\n2\n",
  )
}

///|
test "formatter keeps multiline computed keys parseable and preserves values" {
  let options = @moonjsonnet.FormatOptions::default()
  let sources = [
    "{[if true then\n 'key'\n]: 42}", "{[if false then\n 'key'\n]: 42}", "{[if true then\n 'key' else 'other'\n]:: 42}",
    "{[('a' +\n 'b')\n]+: [1,2]}", "{[('a' +\n 'b')\n](x=1): x}.ab()", "{[['key'][0]\n]: [\n1,2\n]}",
    "{local value=42, ['key' +\n 'name']: value}", "[0, [\n1,2\n]][[\n0,1\n][0]:]",
  ]
  for source in sources {
    for
      style in [
        options,
        { ..options, pretty_field_names: false, },
        { ..options, strip_comments: true, },
      ] {
      let formatted = @moonjsonnet.format_source(source, options=style)
      ignore(@moonjsonnet.ParsedSource::parse(formatted))
      assert_eq(@moonjsonnet.evaluate(formatted), @moonjsonnet.evaluate(source))
      assert_eq(@moonjsonnet.format_source(formatted, options=style), formatted)
    }
  }
}

///|
test "formatter retains blank lines before paragraph comments" {
  for
    (source, expected) in [
      (
        "{}\n\n// a\n\n// b\n\n/* C\n\n*/\n", "{}\n\n// a\n\n// b\n\n/* C\n\n*/\n",
      ),
      ("[\n1,\n\n// second\n2\n]", "[\n  1,\n\n  // second\n  2,\n]\n"),
      (
        "local z=import 'z';\n\n// next group\nlocal a=import 'a';[z,a]", "local z = import 'z';\n\n// next group\nlocal a = import 'a';\n[z, a]\n",
      ),
    ] {
    let formatted = @moonjsonnet.format_source(source)
    assert_eq(formatted, expected)
    ignore(@moonjsonnet.ParsedSource::parse(formatted))
    assert_eq(@moonjsonnet.format_source(formatted), formatted)
  }
}

///|
test "formatter keeps compact argument rows and aligns comma fodder" {
  for
    (source, expected) in [
      ("f(\n1,2)", "f(\n  1, 2\n)\n"),
      ("function(\nx,y) x+y", "function(\n  x, y\n) x + y\n"),
      ("foo(\nbar()\n,\nbaz=qux\n)", "foo(\n  bar()\n  ,\n  baz=qux\n)\n"),
      ("foo(1 // before comma\n,2)", "foo(1  // before comma\n    , 2)\n"),
    ] {
    let formatted = @moonjsonnet.format_source(source)
    assert_eq(formatted, expected)
    ignore(@moonjsonnet.ParsedSource::parse(formatted))
    assert_eq(@moonjsonnet.format_source(formatted), formatted)
  }
  let source = "(function(\nx,y) x+y)(\n1,2)"
  assert_eq(
    @moonjsonnet.evaluate(@moonjsonnet.format_source(source)),
    @moonjsonnet.evaluate(source),
  )
}

///|
test "formatter retains AST depth budgets for flat expression chains" {
  let limits = @moonjsonnet.Limits::default()
  let within = "0" + "+1".repeat(limits.depth - 1)
  ignore(@moonjsonnet.ParsedSource::parse(@moonjsonnet.format_source(within)))
  let beyond = within + "+1"
  try @moonjsonnet.format_source(beyond) catch {
    @moonjsonnet.Error(d) => {
      assert_eq(d.kind, @moonjsonnet.Limit)
      assert_eq(d.message, "syntax tree depth limit exceeded")
    }
  } noraise {
    _ => fail("flat AST chains must retain the configured depth limit")
  }
  let expanded = { ..limits, depth: limits.depth + 1, }
  let formatted = @moonjsonnet.format_source(beyond, limits=expanded)
  ignore(@moonjsonnet.ParsedSource::parse(formatted, limits=expanded))
}
