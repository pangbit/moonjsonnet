// Raw token boundaries only. Ordinary escape decoding happens on consumption.

///|
test "quoted tokens terminate independently while doubled verbatim quotes stay inside" {
  let cases : Array[(String, Array[String])] = [
    ("'a''b'", ["'a'", "'b'"]),
    ("\"a\"\"b\"", ["\"a\"", "\"b\""]),
    ("@'a''b'", ["@'a''b'"]),
    ("@\"a\"\"b\"", ["@\"a\"\"b\""]),
    ("'a'@'b'", ["'a'", "@'b'"]),
    ("@'a'@'b'", ["@'a'", "@'b'"]),
    ("'a'x", ["'a'", "x"]),
    ("@'a'+\"b\"", ["@'a'", "+", "\"b\""]),
    ("\"a\\\"b\"+1", ["\"a\\\"b\"", "+", "1"]),
    ("@'tail\\'+1", ["@'tail\\'", "+", "1"]),
    ("'/*// # ||| @ */'/*tail*/+1", ["'/*// # ||| @ */'", "+", "1"]),
    ("@\"/*// # ||| @ */\"//tail\n+1", ["@\"/*// # ||| @ */\"", "+", "1"]),
    ("@'x'#tail\n'a'", ["@'x'", "'a'"]),
    ("'a\r\nb'/*tail*/+1", ["'a\r\nb'", "+", "1"]),
  ]
  for (source, expected) in cases {
    for retain in [false, true] {
      let tokens = lex(source, "quoted-token", retain_trivia=retain)
      assert_eq(tokens.filter(t => t.text != "<eof>").map(t => t.raw), expected)
      if retain {
        let restored = tokens
          .map(t => t.leading.map(p => p.raw).join("") + t.raw)
          .join("")
        assert_eq(restored, source)
      }
    }
  }
}
