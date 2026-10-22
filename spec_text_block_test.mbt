// Fixed spec.html Lexing preserves empty text-block lines and original line
// endings. Sources below contain actual CR/LF bytes after MoonBit decoding.

///|
test "text blocks preserve a leading CRLF blank line byte for byte" {
  let value = @moonjsonnet.evaluate("|||\r\n\r\n  x\r\n|||")
  guard value is String(text) else { fail("text-block result") }
  assert_eq(@utf8.encode(text), b"\r\nx\r\n")
}

///|
test "text blocks preserve interior and consecutive CRLF blank lines" {
  for
    (source, expected) in [
      ("|||\r\n  x\r\n\r\n  y\r\n|||", b"x\r\n\r\ny\r\n"),
      ("|||\r\n\r\n\r\n\tx\r\n\r\n\ty\r\n|||", b"\r\n\r\nx\r\n\r\ny\r\n"),
      ("|||\n\r\n  x\n\r\n  y\r\n|||", b"\r\nx\n\r\ny\r\n"),
    ] {
    guard @moonjsonnet.evaluate(source) is String(text) else {
      fail("text-block result")
    }
    assert_eq(@utf8.encode(text), expected)
  }
}

///|
test "text-block LF controls and nonempty CRLF lines are not normalized" {
  for
    (source, expected) in [
      ("|||\n\n  x\n\n  y\n|||", b"\nx\n\ny\n"),
      ("|||\r\n  x\r\n|||", b"x\r\n"),
      ("|||\n  x\ry\n|||", b"x\ry\n"),
      ("|||-\n  x\n|||", b"x"),
    ] {
    guard @moonjsonnet.evaluate(source) is String(text) else {
      fail("text-block result")
    }
    assert_eq(@utf8.encode(text), expected)
  }
}
