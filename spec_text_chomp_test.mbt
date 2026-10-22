// Fixed spec.html Lexing strips the final newline from a chomped block;
// CRLF is one line ending and preceding line endings remain byte-exact.

///|
test "text-block chomp removes the complete final CRLF" {
  guard @moonjsonnet.evaluate("|||-\r\n  x\r\n|||") is String(text) else {
    fail("text-block result")
  }
  assert_eq(@utf8.encode(text), b"x")
}

///|
test "text-block chomp removes only one final line ending" {
  for
    (source, expected) in [
      ("|||-\r\n\r\n  x\r\n\r\n|||", b"\r\nx\r\n"),
      ("|||-\r\n  x\r\n\r\n\r\n|||", b"x\r\n\r\n"),
      ("|||-\n  x\n  y\r\n|||", b"x\ny"),
      ("|||-\n  x\r\r\n|||", b"x\r"),
    ] {
    guard @moonjsonnet.evaluate(source) is String(text) else {
      fail("text-block result")
    }
    assert_eq(@utf8.encode(text), expected)
  }
}

///|
test "text-block LF chomp and mixed preceding endings are preserved" {
  for
    (source, expected) in [
      ("|||-\n  x\n|||", b"x"),
      ("|||-\n  x\n\n|||", b"x\n"),
      ("|||-\r\n  x\r\n  y\n|||", b"x\r\ny"),
      ("|||-\n  x\ry\n|||", b"x\ry"),
      ("|||\r\n  x\r\n|||", b"x\r\n"),
    ] {
    guard @moonjsonnet.evaluate(source) is String(text) else {
      fail("text-block result")
    }
    assert_eq(@utf8.encode(text), expected)
  }
}

///|
test "chomp canonicalizes the value without changing retained source bytes" {
  let source = "/*head*/ |||-\r\n  x\r\n||| //tail\r\n"
  let parsed = @moonjsonnet.ParsedSource::parse(
    source,
    filename="chomp.jsonnet",
  )
  assert_eq(@utf8.encode(parsed.text()), @utf8.encode(source))
  assert_eq(
    @utf8.encode(parsed.parts().map(p => p.text).join("")),
    @utf8.encode(source),
  )
  guard parsed.ast().kind is Literal(String(text)) else {
    fail("text-block AST")
  }
  assert_eq(@utf8.encode(text), b"x")
  guard @moonjsonnet.Program::from_ast(parsed.ast()).evaluate() is String(text) else {
    fail("text-block result")
  }
  assert_eq(@utf8.encode(text), b"x")
}
