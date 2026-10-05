///|
test "parser diagnoses token kinds while preserving literal spelling" {
  for
    (source, message) in [
      ("local", "Expected token IDENTIFIER but got end of file"),
      (
        "local 12.50e2=1;42", "Expected token IDENTIFIER but got (NUMBER, \"12.50e2\")",
      ),
      (
        "local 'a\\nb'=1;42", "Expected token IDENTIFIER but got (STRING_SINGLE, \"a\\nb\")",
      ),
      (
        "local @'a''b'=1;42", "Expected token IDENTIFIER but got (VERBATIM_STRING_SINGLE, \"a'b\")",
      ),
      ("local +=1;42", "Expected token IDENTIFIER but got (OPERATOR, \"+=\")"),
      (
        "function(true) 42", "Expected token IDENTIFIER but got \"true\" while parsing parameter",
      ),
      ("[1 2]", "Expected a comma before next array element"),
      ("42 43", "Did not expect: (NUMBER, \"43\")"),
      ("", "Unexpected end of file"),
    ] {
    try @moonjsonnet.Program::parse(source, filename="error.jsonnet") catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.message, message)
        assert_eq(d.location.file, "error.jsonnet")
      }
    } noraise {
      _ => fail("expected parse error")
    }
  }
}

///|
test "operator boundaries retain unary suffixes comments and field visibility" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[1+-2,1- -2,!!true,~-1,1+/*comment*/2,1+//comment\n2]",
    ),
    [-1, 3, true, 0, 3, 3],
  )
  assert_eq(@moonjsonnet.evaluate("({a:1}+{a+:2}).a"), 3)
  assert_eq(@moonjsonnet.evaluate("({a::1}+{a+:::2}).a"), 3)
  assert_eq(@moonjsonnet.evaluate("42"), 42)
  for source in ["import 'a'+'b'", "importstr ('a')", "importbin [42]"] {
    try @moonjsonnet.Program::parse(source) catch {
      @moonjsonnet.Error(d) =>
        assert_eq(d.message, "Computed imports are not allowed")
    } noraise {
      _ => fail("expected computed import rejection")
    }
  }
}
