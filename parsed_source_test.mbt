///|
test "parsed source retains original text while deferring scope validation" {
  let source = "#!/usr/bin/env jsonnet\r\n/*中*/ unknown + @'it''s' //tail"
  let parsed = @moonjsonnet.ParsedSource::parse(source, filename="source")
  let parts = parsed.parts()
  assert_eq(parts.map(p => p.text).join(""), source)
  assert_eq(parsed.text(), source)
  assert_true(parts[0].kind is LineComment)
  assert_eq(parts.last().unwrap().text, "//tail")
  let saved = parts[0].text
  parts[0] = { ..parts[0], text: "changed", }
  assert_eq(parsed.parts()[0].text, saved)
  assert_eq(parsed.text(), source)
  try @moonjsonnet.Program::from_ast(parsed.ast()) catch {
    @moonjsonnet.Error(d) => assert_eq(d.message, "Unknown variable: unknown")
  } noraise {
    _ => fail("scope validation skipped by Program")
  }
}

///|
test "parsed source views preserve evaluation and remain isolated" {
  let source = "[1.20E+003, @'it''s', |||-\n  hi\n|||] #end\n"
  let parsed = @moonjsonnet.ParsedSource::parse(source)
  let view = parsed.ast()
  guard view.kind is Arr(xs) else { fail("array") }
  xs[0] = @moonjsonnet.Program::parse("42").ast()
  assert_eq(@moonjsonnet.Program::from_ast(view).evaluate(), [42, "it's", "hi"])
  assert_eq(@moonjsonnet.Program::from_ast(parsed.ast()).evaluate(), [
    1200, "it's", "hi",
  ])
  assert_eq(parsed.text(), source)
}

///|
test "parsed source enforces source and depth limits without executing" {
  let defaults = @moonjsonnet.Limits::default()
  for
    (source, limits) in [
      ("/*12345*/42", { ..defaults, source_bytes: 4, }),
      ("[[[[42]]]]", { ..defaults, depth: 2, }),
    ] {
    try @moonjsonnet.ParsedSource::parse(source, limits~) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
    } noraise {
      _ => fail("expected limit")
    }
  }
  let source = "if false then import 'missing' else error 'not executed'"
  assert_eq(@moonjsonnet.ParsedSource::parse(source).text(), source)
}
