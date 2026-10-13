// Portions adapted from google/go-jsonnet v0.21.0 (Apache-2.0).
// https://github.com/google/go-jsonnet/tree/67968688d9952f50662e979fab1bef889d0d3e57
// Source: internal/parser/string_util.go
// Copyright 2016 Google Inc. All rights reserved.
// Modifications: Ported string decoding to MoonBit and deferred it until token consumption.
// License and retained attribution: LICENSE and NOTICE at the module root.

// Go v0.21.0 internal/parser/string_util.go unescape semantics.
// Copyright Google Inc.; Apache-2.0; see NOTICE.

///|
fn literal_hex(bytes : Bytes, start : Int) -> Int? {
  let mut value = 0
  for i in start..<(start + 4) {
    let b = bytes[i].to_int()
    let digit = if b >= 48 && b <= 57 {
      b - 48
    } else if b >= 65 && b <= 70 {
      b - 55
    } else if b >= 97 && b <= 102 {
      b - 87
    } else {
      return None
    }
    value = value * 16 + digit
  }
  Some(value)
}

///|
fn unescape_literal(raw : String, loc : Location) -> String raise JsonnetError {
  let bytes = @utf8.encode(raw)
  let out = StringBuilder()
  let mut i = 0
  let error = fn(message) { problem(Syntax, loc, message) }
  while i < bytes.length() {
    if bytes[i] != b'\\' {
      let start = i
      while i < bytes.length() && bytes[i] != b'\\' {
        i += 1
      }
      out.write_string(@utf8.decode_lossy(bytes[start:i]))
      continue
    }
    i += 1
    if i == bytes.length() {
      raise error("Truncated escape sequence in string literal.")
    }
    let esc = bytes[i]
    i += 1
    match esc {
      b'"' | b'\'' | b'\\' | b'/' =>
        out.write_char(esc.to_int().to_char().unwrap())
      b'b' => out.write_char('\b')
      b'f' => out.write_char('\u000c')
      b'n' => out.write_char('\n')
      b'r' => out.write_char('\r')
      b't' => out.write_char('\t')
      b'u' => {
        if i + 4 > bytes.length() {
          raise error("Truncated unicode escape sequence in string literal.")
        }
        let mut code = literal_hex(bytes, i).unwrap_or_else(() => {
          raise error(
            "Unicode escape sequence was malformed: " +
            decode_go_utf8(bytes[:4].to_owned()),
          )
        })
        i += 4
        if code >= 0xd800 && code <= 0xdfff {
          if i + 6 > bytes.length() {
            raise error(
              "Truncated unicode surrogate pair escape sequence in string literal.",
            )
          }
          if bytes[i] != b'\\' || bytes[i + 1] != b'u' {
            raise error(
              "Unicode surrogate pair escape sequence missing low surrogate in string literal.",
            )
          }
          i += 2
          let low = literal_hex(bytes, i).unwrap_or_else(() => {
            raise error(
              "Unicode low surrogate escape sequence was malformed: " +
              decode_go_utf8(bytes[:4].to_owned()),
            )
          })
          i += 4
          code = if code <= 0xdbff && low >= 0xdc00 && low <= 0xdfff {
            0x10000 + (code - 0xd800) * 1024 + low - 0xdc00
          } else {
            0xfffd
          }
        }
        out.write_char(code.to_char().unwrap())
      }
      _ => {
        let c = @utf8.decode_lossy(bytes[i - 1:]).to_array()[0]
        raise error(
          "Unknown escape sequence in string literal: \\" + c.to_string(),
        )
      }
    }
  }
  out.to_string()
}
