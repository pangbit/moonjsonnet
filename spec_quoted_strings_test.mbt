// Fixed criteria: SPEC-QUOTED-STRINGS-2026-10-23.md.
// Handmade Literal ASTs check canonical values, not lexical acceptance.

///|
fn quoted_value(source : String, expected : String) -> Unit raise {
  sequence_value(
    ordering_leaf(source, Literal(Json::string(expected))),
    Json::string(expected),
  )
}

///|
fn quoted_syntax(source : String) -> Unit raise {
  for
    text in [
      source,
      "local unused=(" + source + ");42",
      "if true then 42 else (" + source + ")",
    ] {
    try @moonjsonnet.Program::parse(text, filename="quoted-source") catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Syntax)
    } noraise {
      _ => fail("malformed quoted source was admitted before demand")
    }
  }
}

///|
test "ordinary quotes decode literal escape expectations and preserve line endings" {
  // The single-quoted nine-escape table is reused from string_literal_test.
  for
    (raw, expected) in [
      ("\\\"", "\""),
      ("\\'", "'"),
      ("\\\\", "\\"),
      ("\\/", "/"),
      ("\\b", "\b"),
      ("\\f", "\u000c"),
      ("\\n", "\n"),
      ("\\r", "\r"),
      ("\\t", "\t"),
    ] {
    quoted_value("\"" + raw + "\"", expected)
  }
  for
    (source, expected) in [
      ("''", ""),
      ("\"\"", ""),
      ("'\"'", "\""),
      ("\"'\"", "'"),
      ("'a\\'b'", "a'b"),
      ("\"a\\\"b\"", "a\"b"),
      ("'\\\\\\''", "\\'"),
      ("\"\\\\\\\"\"", "\\\""),
    ] {
    quoted_value(source, expected)
  }
  for quote in ["'", "\""] {
    for
      (raw, expected) in [
        ("\\u0000", "\u0000"),
        ("\\u007F", "\u007f"),
        ("\\u00e9", "é"),
        ("\\u4E2d", "中"),
        ("\\uD7fF", "\uD7FF"),
        ("\\uE000", "\uE000"),
        ("\\uffff", "\uFFFF"),
        ("\\u0041F", "AF"),
        ("é中😀e\u0301", "é中😀e\u0301"),
        ("a\nb", "a\nb"),
        ("a\r\nb", "a\r\nb"),
        ("/*not a comment*/ // # ||| @", "/*not a comment*/ // # ||| @"),
      ] {
      quoted_value(quote + raw + quote, expected)
    }
  }
}

///|
test "verbatim quotes preserve every payload character except doubled end quotes" {
  for quote in ["'", "\""] {
    for
      raw in [
        "", "\\n\\u0041\\q\\u12xz", "tail\\", "é中😀e\u0301", "a\nb", "a\r\nb",
        "\u0000\t\b\u000c\r", "/* // # ||| */",
      ] {
      quoted_value("@" + quote + raw + quote, raw)
    }
  }
  for
    (source, expected) in [
      ("@''''", "'"),
      ("@\"\"\"\"", "\""),
      ("@'a''b'", "a'b"),
      ("@\"a\"\"b\"", "a\"b"),
      ("@'\"\"'", "\"\""),
      ("@\"''\"", "''"),
      ("@'\\'", "\\"),
      ("@\"\\\"", "\\"),
    ] {
    quoted_value(source, expected)
  }
  let source = "['x'/*gap*/,@'y''z',\"n\\n\",@\"\\n\"]"
  sequence_value(
    {
      source,
      tree: ordering_ast(
        Arr([
          ordering_ast(Literal("x")),
          ordering_ast(Literal("y'z")),
          ordering_ast(Literal("n\n")),
          ordering_ast(Literal("\\n")),
        ]),
      ),
    },
    ["x", "y'z", "n\n", "\\n"],
  )
}

///|
test "quoted source rejects malformed spellings before demand while AST string data stays opaque" {
  for
    source in [
      "\"", "@'", "@\"", "\"abc\\", "@'a''", "@\"a\"\"", "@", "@ x", "@ \"x\"", "@\n'x'",
      "@//c\n'x'", "@1",
    ] {
    quoted_syntax(source)
  }
  for quote in ["'", "\""] {
    for
      raw in [
        "\\q", "\\a", "\\v", "\\0", "\\x41", "\\U00000041", "\\\n", "\\\r\n", "\\u",
        "\\u0", "\\u00", "\\u000", "\\ug000", "\\u0g00", "\\u00g0", "\\u000g", "\\u-001",
        "\\u１２３４",
      ] {
      quoted_syntax(quote + raw + quote)
    }
  }
  // Adjacent ordinary strings or separate @ strings do not imply concat.
  for source in ["'a''b'", "\"a\"\"b\"", "'a'@'b'", "@'a'@'b'", "'a'x"] {
    quoted_syntax(source)
  }
  for raw in ["\\q", "\\u12xz", "\\u", "trailing\\"] {
    let tree = ordering_ast(Literal(Json::string(raw)))
    assert_eq(
      @moonjsonnet.Program::from_ast(tree).evaluate(limits=sequence_limits()),
      Json::string(raw),
    )
  }
  for
    source in [
      "'quote-demand'", "\"quote-demand\"", "@'quote-demand'", "@\"quote-demand\"",
    ] {
    sequence_failure(
      {
        source: "error (" + source + ")",
        tree: ordering_ast(Fail(ordering_ast(Literal("quote-demand")))),
      },
      @moonjsonnet.Runtime,
      Some("quote-demand"),
    )
  }
}
