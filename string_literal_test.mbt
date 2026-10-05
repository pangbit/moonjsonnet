///|
test "string literals decode Go escapes and surrogate replacement" {
  assert_eq(
    @moonjsonnet.evaluate(
      "['\\uD83D\\uDE00','\\uD800\\u0041','\\uDC00\\uDC00','\\uDBFF\\uDFFF']",
    ),
    ["😀", "�", "�", "\u{10ffff}"],
  )
  assert_eq(
    @moonjsonnet.evaluate(
      "['\\\"','\\\'','\\\\','\\/','\\b','\\f','\\n','\\r','\\t']",
    ),
    ["\"", "'", "\\", "/", "\b", "\u000c", "\n", "\r", "\t"],
  )
  assert_eq(
    @moonjsonnet.evaluate("'a\uFEFF\\nb\uFEFF'"),
    Json::string("a\uFEFF\nb\uFEFF"),
  )
  assert_eq(@moonjsonnet.evaluate("@'\\uD800'"), Json::string("\\uD800"))
  let requests : Array[String] = []
  assert_eq(
    @moonjsonnet.evaluate("import '\\u0061'", resolver=fn(_, path) {
      requests.push(path)
      { id: path, text: "'\\u0062'", }
    }),
    Json::string("b"),
  )
  assert_eq(requests, ["a"])
}

///|
test "full lexing precedes string decoding but later syntax does not" {
  for
    (source, message, column) in [
      ("['\\q', ?]", "Could not lex the character '?'", 8),
      (
        "['\\q' 42]", "entry:1:2-6 Unknown escape sequence in string literal: \\q",
        2,
      ),
      (
        "local '\\q'=1;42", "Expected token IDENTIFIER but got (STRING_SINGLE, \"\\q\")",
        7,
      ),
      (
        "'\\u12xz'", "entry:1:1-9 Unicode escape sequence was malformed: \\u12",
        1,
      ),
      (
        "'é中\\u12xz'", "entry:1:1-14 Unicode escape sequence was malformed: é��",
        1,
      ),
      (
        "'\\uD800'", "entry:1:1-9 Truncated unicode surrogate pair escape sequence in string literal.",
        1,
      ),
      (
        "'\\uD800123456'", "entry:1:1-15 Unicode surrogate pair escape sequence missing low surrogate in string literal.",
        1,
      ),
    ] {
    try @moonjsonnet.Program::parse(source, filename="entry") catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.message, message)
        assert_eq(d.location, { file: "entry", line: 1, column, })
      }
    } noraise {
      _ => fail("expected error")
    }
  }
}
