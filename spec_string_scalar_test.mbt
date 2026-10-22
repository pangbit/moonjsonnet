///|
test "char and codepoint round trip scalar identifiers including NUL and non BMP" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.codepoint(std.char(0)),std.codepoint(std.char(65)),std.codepoint(std.char(233)),std.codepoint(std.char(20320)),std.codepoint(std.char(128512)),std.codepoint(std.char(65533)),std.codepoint(std.char(1114111)),std.char(128512),std.length(std.char(1114111)),std.codepoint('\\u0000')]",
    ),
    [0, 65, 233, 20320, 128512, 65533, 1114111, "😀", 1, 0],
  )
}

///|
test "char rejects fractional identifiers at the actual conversion" {
  for n in ["0.5", "65.5", "1114110.5", "5e-324"] {
    ignore(string_contract_error("std.char(" + n + ")"))
    ignore(string_contract_error("std.type(std.char(" + n + "))"))
    ignore(string_contract_error("std.codepoint(std.char(" + n + "))"))
  }
}

///|
test "char and codepoint reject nonnumeric or nonstring heads without payloads" {
  for
    value in [
      "null", "true", "'1'", "[error 'payload']", "{assert false,a:1}", "function()error 'body'",
    ] {
    assert_eq(
      string_contract_error("std.char(" + value + ")").kind,
      @moonjsonnet.Type,
    )
  }
  for
    value in [
      "null", "true", "1", "[error 'payload']", "{assert false,a:1}", "function()error 'body'",
    ] {
    assert_eq(
      string_contract_error("std.codepoint(" + value + ")").kind,
      @moonjsonnet.Type,
    )
  }
}

///|
test "codepoint counts codepoints rather than graphemes and propagates needed errors" {
  for text in ["''", "'e\\u0301'", "'😀a'", "'👩‍💻'"] {
    assert_eq(
      string_contract_error("std.codepoint(" + text + ")").kind,
      @moonjsonnet.Runtime,
    )
  }
  assert_eq(
    string_contract_error("std.char(error 'identifier')").message,
    "identifier",
  )
  assert_eq(
    string_contract_error("std.codepoint(error 'text')").message,
    "text",
  )
  assert_eq(
    string_contract_error("std.char(std.sum([1e308,1e308]))").message,
    "Overflow",
  )
}
