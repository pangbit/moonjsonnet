// Portions adapted from google/go-jsonnet v0.21.0 (Apache-2.0).
// https://github.com/google/go-jsonnet/tree/67968688d9952f50662e979fab1bef889d0d3e57
// Source: internal/parser/lexer.go
// Copyright 2016 Google Inc. All rights reserved.
// Modifications: Adapted token classification, numeric scanning and errors to MoonBit source spans.
// License and retained attribution: LICENSE and NOTICE at the module root.

// Rune quoting also adapts Go 1.24.0 src/strconv/quote.go to MoonBit Char.
// Copyright 2009 The Go Authors. All rights reserved.
// BSD 3-Clause terms: licenses/GO-BSD-3-Clause.txt; see NOTICE.

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
fn number_end(chars : Array[Char], start : Int) -> Int {
  let mut i = start + 1
  if chars[start] != '0' {
    while chars.get(i) is Some(c) && digit(c) {
      i += 1
    }
  }
  // A suffix extends the token only if it forms a complete JSON number.
  // Otherwise the next token starts here (e.g. the dot in 1.field).
  if chars.get(i) == Some('.') && chars.get(i + 1) is Some(c) && digit(c) {
    i += 1
    while chars.get(i) is Some(c) && digit(c) {
      i += 1
    }
  }
  if chars.get(i) == Some('e') || chars.get(i) == Some('E') {
    let mut exponent = i + 1
    if chars.get(exponent) == Some('+') || chars.get(exponent) == Some('-') {
      exponent += 1
    }
    if chars.get(exponent) is Some(c) && digit(c) {
      i = exponent + 1
      while chars.get(i) is Some(c) && digit(c) {
        i += 1
      }
    }
  }
  i
}
