///|
test "syntax diagnostics recover token ranges without changing stored data" {
  for
    (source, expected) in [
      ("[1 2]", "entry:1:4-5 Expected a comma before next array element"),
      ("[1,", "entry:1:4 Unexpected end of file"),
      ("\"unterminated", "entry:1:1 Unterminated String"),
      ("[1 '中']", "entry:1:4-9 Expected a comma before next array element"),
      ("import 'a'+'b'", "entry:1:8-15 Computed imports are not allowed"),
      ("importstr ('a')", "entry:1:11-16 Computed imports are not allowed"),
      ("importbin [42]", "entry:1:11-15 Computed imports are not allowed"),
    ] {
    try @moonjsonnet.SyntaxDocument::parse(source, filename="entry") catch {
      @moonjsonnet.Error(d) => {
        let previous = d.format()
        assert_eq(d.format_syntax(source), expected)
        assert_eq(d.format(), previous)
      }
    } noraise {
      _ => fail("expected syntax diagnostic")
    }
  }
  let loc : @moonjsonnet.Location = { file: "entry", line: 1, column: 1, }
  let diagnostic : @moonjsonnet.Diagnostic = {
    kind: @moonjsonnet.Runtime,
    message: "failed",
    location: loc,
    context: [loc],
    trace: [],
  }
  assert_eq(diagnostic.format_syntax("42"), "entry:1:1 failed")
  let diagnostic = { ..diagnostic, kind: @moonjsonnet.Syntax, }
  assert_eq(diagnostic.format_syntax(" ".repeat(1048577)), "entry:1:1 failed")
}

///|
test "syntax diagnostic bytes preserve malformed UTF8 and semantic newlines" {
  let source = "'é中\\u12xz'"
  try @moonjsonnet.SyntaxDocument::parse(source, filename="entry") catch {
    @moonjsonnet.Error(d) => {
      let expected = @utf8.encode(
        "entry:1:1-14 entry:1:1-14 Unicode escape sequence was malformed: ",
      ).to_array()
      expected.append([0xc3, 0xa9, 0xe4, 0xb8])
      assert_eq(d.format_syntax_bytes(source), Bytes::from_array(expected))
      assert_true(d.format_syntax(source).has_suffix("é��"))
    }
  } noraise {
    _ => fail("expected malformed Unicode")
  }
  let source = "'\\\n'"
  try @moonjsonnet.SyntaxDocument::parse(source, filename="entry") catch {
    @moonjsonnet.Error(d) =>
      assert_eq(
        d.format_syntax_bytes(source),
        @utf8.encode(d.format_syntax(source)),
      )
  } noraise {
    _ => fail("expected unknown newline escape")
  }
  let loc : @moonjsonnet.Location = { file: "", line: 1, column: 1, }
  let d : @moonjsonnet.Diagnostic = {
    kind: @moonjsonnet.Syntax,
    message: "failed",
    location: loc,
    context: [],
    trace: [],
  }
  assert_eq(d.format_syntax(""), "1:1 failed")
  assert_eq(d.format_syntax_bytes(""), b"1:1 failed")
}
