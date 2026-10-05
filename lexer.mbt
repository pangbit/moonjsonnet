///|
priv struct Token {
  text : String
  value : Json?
  loc : Location
  raw : String
  end : Location
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
    let count = out.length()
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
        raise problem(Syntax, loc, "Multi-line comment has no terminating */")
      }
      i += 2
    } else if c == '|' &&
      chars.get(i + 1) == Some('|') &&
      chars.get(i + 2) == Some('|') {
      i += 3
      let chomp = chars.get(i) == Some('-')
      if chomp {
        i += 1
      }
      while chars.get(i) == Some(' ') ||
            chars.get(i) == Some('\t') ||
            chars.get(i) == Some('\r') {
        i += 1
      }
      guard chars.get(i) == Some('\n') else {
        raise problem(Syntax, loc, "Text block requires new line after |||.")
      }
      i += 1
      let content : Array[Char] = []
      while chars.get(i) == Some('\n') {
        content.push('\n')
        i += 1
      }
      let indent_start = i
      while chars.get(i) == Some(' ') || chars.get(i) == Some('\t') {
        i += 1
      }
      let indent = chars[indent_start:i].to_owned()
      guard !indent.is_empty() else {
        raise problem(
          Syntax,
          loc,
          "Text block's first line must start with whitespace",
        )
      }
      while true {
        while chars.get(i) != Some('\n') {
          guard i < chars.length() else {
            raise problem(Syntax, loc, "Unexpected EOF")
          }
          content.push(chars[i])
          i += 1
        }
        content.push('\n')
        i += 1
        while chars.get(i) == Some('\n') {
          content.push('\n')
          i += 1
        }
        let mut matches = true
        for j, ch in indent {
          if chars.get(i + j) != Some(ch) {
            matches = false
            break
          }
        }
        if matches {
          i += indent.length()
          continue
        }
        while chars.get(i) == Some(' ') || chars.get(i) == Some('\t') {
          i += 1
        }
        guard chars.get(i) == Some('|') &&
          chars.get(i + 1) == Some('|') &&
          chars.get(i + 2) == Some('|') else {
          raise problem(Syntax, loc, "Text block not terminated with |||")
        }
        i += 3
        break
      }
      if chomp {
        ignore(content.pop())
      }
      let b = StringBuilder()
      for ch in content {
        b.write_char(ch)
      }
      out.push({
        text: "<block>",
        value: Some(Json::string(b.to_string())),
        loc,
        raw: "",
        end: loc,
      })
    } else if c == '"' || c == '\'' || c == '@' {
      let verbatim = c == '@'
      if verbatim {
        i += 1
      }
      guard i < chars.length() && (chars[i] == '"' || chars[i] == '\'') else {
        let code = match chars.get(i) {
          Some(c) => c.to_int()
          None => -1
        }
        raise problem(
          Syntax,
          loc,
          "Couldn't lex verbatim string, junk after '@': \{code}",
        )
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
            raise problem(Syntax, loc, "Unterminated String")
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
              let mut code = 0
              for _ in 0..<4 {
                guard i < chars.length() else {
                  raise problem(Syntax, loc, "short unicode escape")
                }
                escaped.write_char(chars[i])
                let c = chars[i].to_int()
                code = code * 16 +
                  (if c >= 48 && c <= 57 {
                    c - 48
                  } else if c >= 65 && c <= 70 {
                    c - 55
                  } else if c >= 97 && c <= 102 {
                    c - 87
                  } else {
                    0
                  })
                i += 1
              }
              if code >= 0xd800 &&
                code <= 0xdbff &&
                chars.get(i) == Some('\\') &&
                chars.get(i + 1) == Some('u') {
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
                    Syntax,
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
        raise problem(Syntax, loc, "Unterminated String")
      }
      out.push({
        text: "<string>",
        value: Some(Json::string(b.to_string())),
        loc,
        raw: "",
        end: loc,
      })
    } else if identifier_start(c) {
      let b = StringBuilder()
      while i < chars.length() &&
            (identifier_start(chars[i]) || digit(chars[i])) {
        b.write_char(chars[i])
        i += 1
      }
      out.push({ text: b.to_string(), value: None, loc, raw: "", end: loc, })
    } else if digit(c) {
      i = number_end(chars, start, loc)
      let b = StringBuilder()
      for j in start..<i {
        b.write_char(chars[j])
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
      out.push({ text: "<number>", value: Some(n), loc, raw: "", end: loc, })
    } else {
      if !operator_char(c) &&
        c != '{' &&
        c != '}' &&
        c != '[' &&
        c != ']' &&
        c != '(' &&
        c != ')' &&
        c != ',' &&
        c != ';' &&
        c != '.' {
        raise problem(
          Syntax,
          loc,
          "Could not lex the character " + quote_lex_char(Some(c)),
        )
      }
      let b = StringBuilder()
      i += 1
      if operator_char(c) {
        while i < chars.length() && operator_char(chars[i]) {
          if chars[i] == '/' &&
            (chars.get(i + 1) == Some('/') || chars.get(i + 1) == Some('*')) {
            break
          }
          if chars[i] == '|' &&
            chars.get(i + 1) == Some('|') &&
            chars.get(i + 2) == Some('|') {
            break
          }
          i += 1
        }
        while i > start + 1 &&
              (
                chars[i - 1] == '+' ||
                chars[i - 1] == '-' ||
                chars[i - 1] == '~' ||
                chars[i - 1] == '!' ||
                chars[i - 1] == '$'
              ) {
          i -= 1
        }
      }
      for j in start..<i {
        b.write_char(chars[j])
      }
      out.push({ text: b.to_string(), value: None, loc, raw: "", end: loc, })
    }
    if out.length() > count {
      let raw = StringBuilder()
      for j in start..<i {
        raw.write_char(chars[j])
      }
      out[count] = { ..out[count], raw: raw.to_string(), }
    }
    for j in start..<i {
      if chars[j] == '\n' {
        line += 1
        column = 1
      } else {
        let cp = chars[j].to_int()
        column += if cp < 0x80 {
          1
        } else if cp < 0x800 {
          2
        } else if cp < 0x10000 {
          3
        } else {
          4
        }
      }
    }
    if out.length() > count {
      out[count] = { ..out[count], end: { file, line, column, }, }
    }
  }
  out.push({
    text: "<eof>",
    value: None,
    loc: { file, line, column, },
    raw: "",
    end: { file, line, column, },
  })
  out
}
