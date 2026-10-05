// Numeric token boundaries and messages follow go-jsonnet's lexer.
// Copyright Google Inc.; Apache-2.0; see NOTICE.

///|
// Go's QuoteRuneToASCII notation, including replacement rune for EOF.
fn quote_lex_char(c : Char?) -> String {
  let c = c.unwrap_or('\ufffd')
  let escaped = match c {
    '\'' => "\\'"
    '\\' => "\\\\"
    '\u0007' => "\\a"
    '\b' => "\\b"
    '\u000c' => "\\f"
    '\n' => "\\n"
    '\r' => "\\r"
    '\t' => "\\t"
    '\u000b' => "\\v"
    _ => {
      let cp = c.to_int()
      if cp >= 0x20 && cp < 0x7f {
        c.to_string()
      } else {
        let (prefix, width) = if cp < 0x20 || cp == 0x7f {
          ("\\x", 2)
        } else if cp < 0x10000 {
          ("\\u", 4)
        } else {
          ("\\U", 8)
        }
        let hex = cp.to_string(radix=16)
        prefix + "0".repeat(width - hex.length()) + hex
      }
    }
  }
  "'" + escaped + "'"
}

///|
fn number_end(
  chars : Array[Char],
  start : Int,
  loc : Location,
) -> Int raise Error {
  let mut i = start + 1
  if chars[start] != '0' {
    while chars.get(i) is Some(c) && digit(c) {
      i += 1
    }
  }
  let require_digit = fn(index : Int, context : String) raise Error {
    if !(chars.get(index) is Some(c) && digit(c)) {
      // Everything consumed inside a numeric token is ASCII.
      raise problem(
        Syntax,
        { ..loc, column: loc.column + index - start, },
        "Couldn't lex number, junk after " +
        context +
        ": " +
        quote_lex_char(chars.get(index)),
      )
    }
  }
  if chars.get(i) == Some('.') {
    i += 1
    require_digit(i, "decimal point")
    while chars.get(i) is Some(c) && digit(c) {
      i += 1
    }
  }
  if chars.get(i) == Some('e') || chars.get(i) == Some('E') {
    i += 1
    if chars.get(i) == Some('+') || chars.get(i) == Some('-') {
      i += 1
      require_digit(i, "exponent sign")
    } else {
      require_digit(i, "'E'")
    }
    while chars.get(i) is Some(c) && digit(c) {
      i += 1
    }
  }
  i
}
