// String style and escaping follow the pinned Go formatter/parser.
// Copyright Google Inc.; Apache-2.0; see NOTICE.

///|
fn format_string(
  token : Token,
  style : FormatStringStyle,
) -> String raise JsonnetError {
  if style == PreserveQuotes ||
    token.text != "<string>" ||
    token.raw.has_prefix("@") {
    return token.raw
  }
  guard token.literal_kind() is Literal(String(value)) else { return token.raw }
  let single = value.contains("'")
  let double = value.contains("\"")
  if single && double {
    return token.raw
  }
  let use_single = if single {
    false
  } else if double {
    true
  } else {
    style == SingleQuotes
  }
  let quote = if use_single { '\'' } else { '"' }
  let out = StringBuilder()
  out.write_char(quote)
  for c in value.to_array() {
    match c {
      '\\' => out.write_string("\\\\")
      '\n' => out.write_string("\\n")
      '\r' => out.write_string("\\r")
      '\t' => out.write_string("\\t")
      '\u{8}' => out.write_string("\\b")
      '\u{c}' => out.write_string("\\f")
      _ => {
        let code = c.to_int()
        if c == quote {
          out.write_char('\\')
        }
        if code < 32 || (code >= 127 && code <= 159) {
          let hex = "0123456789abcdef"
          out.write_string("\\u00")
          out.write_char(hex[(code >> 4) & 15].to_char().unwrap())
          out.write_char(hex[code & 15].to_char().unwrap())
        } else {
          out.write_char(c)
        }
      }
    }
  }
  out.write_char(quote)
  out.to_string()
}

///|
fn format_comment(
  raw : String,
  style : FormatCommentStyle,
  first : Bool,
) -> String {
  if style == HashComments && raw.has_prefix("//") {
    "#" + raw[2:].to_owned()
  } else if style == SlashComments &&
    raw.has_prefix("#") &&
    !(first && raw.has_prefix("#!")) {
    "//" + raw[1:].to_owned()
  } else {
    raw
  }
}
