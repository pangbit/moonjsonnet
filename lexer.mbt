///|
priv struct Token {
  text : String
  value : Json?
  loc : Location
}

///|
fn identifier_start(c : Char) -> Bool {
  c == '_' || (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

///|
fn digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///|
fn lex(source : String, file : String) -> Array[Token] raise Error {
  let chars = source.to_array()
  let out : Array[Token] = []
  let mut i = 0
  let mut line = 1
  let mut column = 1
  while i < chars.length() {
    let c = chars[i]
    let loc : Location = { file, line, column, }
    let start = i
    if c == ' ' || c == '\t' || c == '\r' || c == '\n' {
      i += 1
    } else if c == '#' || (c == '/' && chars.get(i + 1) == Some('/')) {
      while i < chars.length() && chars[i] != '\n' {
        i += 1
      }
    } else if c == '/' && chars.get(i + 1) == Some('*') {
      i += 2
      while i + 1 < chars.length() && !(chars[i] == '*' && chars[i + 1] == '/') {
        i += 1
      }
      if i + 1 >= chars.length() {
        raise problem(Syntax, loc, "unterminated comment")
      }
      i += 2
    } else if c == '"' || c == '\'' || c == '@' {
      let verbatim = c == '@'
      if verbatim {
        i += 1
      }
      guard i < chars.length() && (chars[i] == '"' || chars[i] == '\'') else {
        raise problem(Syntax, loc, "expected quote")
      }
      let quote = chars[i]
      i += 1
      let b = StringBuilder()
      let mut closed = false
      while i < chars.length() {
        let ch = chars[i]
        i += 1
        if ch == quote {
          if verbatim && chars.get(i) == Some(quote) {
            b.write_char(quote)
            i += 1
          } else {
            closed = true
            break
          }
        } else if ch == '\\' && !verbatim {
          guard i < chars.length() else {
            raise problem(Syntax, loc, "unterminated escape")
          }
          let esc = chars[i]
          i += 1
          match esc {
            '"' | '\'' | '\\' | '/' => b.write_char(esc)
            'n' => b.write_char('\n')
            'r' => b.write_char('\r')
            't' => b.write_char('\t')
            'b' => b.write_char('\b')
            'f' => b.write_char('\u000c')
            'u' => {
              // Delegate scalar/pair validation to the core JSON decoder.
              let escaped = StringBuilder()
              escaped.write_string("\"\\u")
              for _ in 0..<4 {
                guard i < chars.length() else {
                  raise problem(Syntax, loc, "short unicode escape")
                }
                escaped.write_char(chars[i])
                i += 1
              }
              if chars.get(i) == Some('\\') && chars.get(i + 1) == Some('u') {
                escaped.write_string("\\u")
                i += 2
                for _ in 0..<4 {
                  guard i < chars.length() else {
                    raise problem(Syntax, loc, "short unicode escape")
                  }
                  escaped.write_char(chars[i])
                  i += 1
                }
              }
              escaped.write_char('"')
              let decoded = @json.parse(escaped.to_string()) catch {
                _ =>
                  raise problem(
                    Unsupported,
                    loc,
                    "invalid or unpaired Unicode escape",
                  )
              }
              if decoded is String(s) {
                b.write_string(s)
              }
            }
            _ => raise problem(Syntax, loc, "invalid escape")
          }
        } else {
          b.write_char(ch)
        }
      }
      if !closed {
        raise problem(Syntax, loc, "unterminated string")
      }
      out.push({
        text: "string",
        value: Some(Json::string(b.to_string())),
        loc,
      })
    } else if identifier_start(c) {
      let b = StringBuilder()
      while i < chars.length() &&
            (identifier_start(chars[i]) || digit(chars[i])) {
        b.write_char(chars[i])
        i += 1
      }
      out.push({ text: b.to_string(), value: None, loc, })
    } else if digit(c) {
      let b = StringBuilder()
      while i < chars.length() &&
            (
              digit(chars[i]) ||
              chars[i] == '.' ||
              chars[i] == 'e' ||
              chars[i] == 'E' ||
              (
                (chars[i] == '+' || chars[i] == '-') &&
                (chars.get(i - 1) == Some('e') || chars.get(i - 1) == Some('E'))
              )
            ) {
        b.write_char(chars[i])
        i += 1
      }
      let n = @json.parse(b.to_string()) catch {
        _ => raise problem(Syntax, loc, "invalid number")
      }
      guard n is Number(v, ..) else {
        raise problem(Syntax, loc, "invalid number")
      }
      if v.is_inf() || v.is_nan() {
        raise problem(Runtime, loc, "non-finite number")
      }
      out.push({ text: "number", value: Some(n), loc, })
    } else {
      let b = StringBuilder()
      b.write_char(c)
      i += 1
      if c == ':' && chars.get(i) == Some(':') {
        b.write_char(':')
        i += 1
        if chars.get(i) == Some(':') {
          b.write_char(':')
          i += 1
        }
      } else if (c == '=' || c == '!' || c == '<' || c == '>') &&
        chars.get(i) == Some('=') {
        b.write_char('=')
        i += 1
      } else if (c == '&' || c == '|' || c == '<' || c == '>') &&
        chars.get(i) == Some(c) {
        b.write_char(c)
        i += 1
      }
      out.push({ text: b.to_string(), value: None, loc, })
    }
    for j in start..<i {
      if chars[j] == '\n' {
        line += 1
        column = 1
      } else {
        column += 1
      }
    }
  }
  out.push({ text: "EOF", value: None, loc: { file, line, column, }, })
  out
}
