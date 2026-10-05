///|
test "number token boundaries and lexical junk locations match Go" {
  for
    (source, message, column) in [
      ("01", "Did not expect: (NUMBER, \"1\")", 2),
      ("1.2.3", "Expected token IDENTIFIER but got (NUMBER, \"3\")", 5),
      ("1.", "Couldn't lex number, junk after decimal point: '\\ufffd'", 3),
      ("1e", "Couldn't lex number, junk after 'E': '\\ufffd'", 3),
      ("1e+中", "Couldn't lex number, junk after exponent sign: '\\u4e2d'", 4),
      ("['中', 1e+]", "Couldn't lex number, junk after exponent sign: ']'", 12),
      ("/*中*/ ?", "Could not lex the character '?'", 9),
      ("😀", "Could not lex the character '\\U0001f600'", 1),
      ("@中", "Couldn't lex verbatim string, junk after '@': 20013", 1),
    ] {
    try @moonjsonnet.Program::parse(source, filename="lex") catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Syntax)
        assert_eq(d.message, message)
        assert_eq(d.location, { file: "lex", line: 1, column, })
      }
    } noraise {
      _ => fail("expected lexical or parse failure")
    }
  }
  assert_eq(@moonjsonnet.evaluate("[0,10,0.5,1e2,1e-2,0E+2]"), [
    0, 10, 0.5, 100, 0.01, 0,
  ])
}

///|
test "unterminated lexical constructs report their opening location" {
  for
    (source, message) in [
      ("/* text", "Multi-line comment has no terminating */"),
      ("'abc", "Unterminated String"),
      ("@'abc", "Unterminated String"),
      ("'abc\\", "Unterminated String"),
      ("||| x", "Text block requires new line after |||."),
      ("|||\ntext", "Text block's first line must start with whitespace"),
      ("|||\n  text", "Unexpected EOF"),
      ("|||\n  text\n bad", "Text block not terminated with |||"),
    ] {
    try @moonjsonnet.Program::parse("\n  " + source, filename="lex") catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.message, message)
        assert_eq(d.location, { file: "lex", line: 2, column: 3, })
      }
    } noraise {
      _ => fail("expected lexical failure")
    }
  }
}
