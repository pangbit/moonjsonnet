///|
test "lexical trivia retains exact source and token boundaries" {
  let sources = [
    "", " \t\r\n", "#!/usr/bin/env jsonnet\r\n{a:42} // tail\r\n", "#only", "/*only*/",
    "42/*end*/", "42 # no newline", " /*a*/ /*b*/\n[1.20E+003, @'it''s', @\"a\"\"b\", '\\u0041']\t",
    "/*😀*/\r\n'中' //😀\r\n", "1/*mid*/+ //next\n2", "|||\n  a\n  b\n|||\n",
    "|||-\n\n  x\n||| #end", "local x=42; x tailstrict", "if false then 1e309 else null",
    "'/* string */ # text // text'", "'line\nbreak'", "'\\q'",
  ]
  for source in sources {
    let tokens = lex(source, "source", retain_trivia=true)
    let restored = StringBuilder()
    let mut previous : Location = { file: "source", line: 1, column: 1, }
    for token in tokens {
      for trivia in token.leading {
        assert_eq(trivia.range.begin, previous)
        assert_true(!trivia.raw.is_empty())
        if trivia.kind == Whitespace {
          assert_true(
            trivia.raw
            .to_array()
            .all(c => c == ' ' || c == '\t' || c == '\r' || c == '\n'),
          )
        }
        restored.write_string(trivia.raw)
        previous = trivia.range.end
      }
      assert_eq(token.loc, previous)
      restored.write_string(token.raw)
      previous = token.end
    }
    assert_eq(restored.to_string(), source)
    assert_eq(tokens.last().unwrap().text, "<eof>")
  }
}

///|
test "trivia class and Unicode byte coordinates remain separate from literals" {
  let tokens = lex("/*中*/\r\n #x\n'😀'//end", "source", retain_trivia=true)
  let first = tokens[0]
  assert_eq(first.leading.length(), 4)
  assert_true(first.leading[0].kind == BlockComment)
  assert_eq(first.leading[0].range.format(), "source:1:1-8")
  assert_eq(first.leading[1].raw, "\r\n ")
  assert_true(first.leading[2].kind == LineComment)
  assert_eq(first.loc, { file: "source", line: 3, column: 1, })
  assert_eq(first.raw, "'😀'")
  assert_eq(first.end.column, 7)
  assert_eq(tokens[1].leading[0].raw, "//end")
}
