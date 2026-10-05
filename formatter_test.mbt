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
