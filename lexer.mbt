// Portions adapted from google/go-jsonnet v0.21.0 (Apache-2.0).
// https://github.com/google/go-jsonnet/tree/67968688d9952f50662e979fab1bef889d0d3e57
// Source: internal/parser/lexer.go
// Copyright 2016 Google Inc. All rights reserved.
// Modifications: Adapted token classification, numeric scanning and errors to MoonBit source spans.
// License and retained attribution: LICENSE and NOTICE at the module root.

///|
priv struct Token {
  text : String
  value : Json?
  loc : Location
  raw : String
  end : Location
  leading : Array[Trivia]
}

///|
priv struct Trivia {
  kind : SourcePartKind
  raw : String
  range : SourceRange
  // Formatting retains this margin when imports move and are re-lexed.
  margin : Int32
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
fn lex(
  source : String,
  file : String,
  retain_trivia~ : Bool = false,
) -> Array[Token] raise Error {
  let chars = source.to_array()
  let out : Array[Token] = []
  let mut i = 0
  let mut line = 1
  let mut column = 1
  let mut leading : Array[Trivia] = []
  while i < chars.length() {
    let c = chars[i]
    let loc : Location = { file, line, column, }
    let start = i
    let count = out.length()
    if c == ' ' || c == '\t' || c == '\r' || c == '\n' {
      while i < chars.length() &&
            (
              chars[i] == ' ' ||
              chars[i] == '\t' ||
              chars[i] == '\r' ||
              chars[i] == '\n'
            ) {
        i += 1
      }
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
      while chars.get(i) == Some('\n') ||
            (chars.get(i) == Some('\r') && chars.get(i + 1) == Some('\n')) {
        if chars.get(i) == Some('\r') {
          content.push('\r')
          i += 1
        }
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
        while chars.get(i) == Some('\n') ||
              (chars.get(i) == Some('\r') && chars.get(i + 1) == Some('\n')) {
          if chars.get(i) == Some('\r') {
            content.push('\r')
            i += 1
          }
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
        if content.get(content.length() - 1) == Some('\r') {
          ignore(content.pop())
        }
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
        leading: [],
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
          b.write_char('\\')
          b.write_char(esc)
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
        leading: [],
      })
    } else if identifier_start(c) {
      let b = StringBuilder()
      while i < chars.length() &&
            (identifier_start(chars[i]) || digit(chars[i])) {
        b.write_char(chars[i])
        i += 1
      }
      out.push({
        text: b.to_string(),
        value: None,
        loc,
        raw: "",
        end: loc,
        leading: [],
      })
    } else if digit(c) {
      i = number_end(chars, start)
      out.push({
        text: "<number>",
        value: None,
        loc,
        raw: "",
        end: loc,
        leading: [],
      })
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
      out.push({
        text: b.to_string(),
        value: None,
        loc,
        raw: "",
        end: loc,
        leading: [],
      })
    }
    let raw = if out.length() > count || retain_trivia {
      let builder = StringBuilder()
      for j in start..<i {
        builder.write_char(chars[j])
      }
      builder.to_string()
    } else {
      ""
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
      out[count] = { ..out[count], raw, end: { file, line, column, }, leading, }
      leading = []
    } else if retain_trivia {
      leading.push({
        kind: if c == '#' || (c == '/' && chars.get(start + 1) == Some('/')) {
          LineComment
        } else if c == '/' {
          BlockComment
        } else {
          Whitespace
        },
        raw,
        range: { begin: loc, end: { file, line, column, }, },
        margin: loc.column - 1,
      })
    }
  }
  out.push({
    text: "<eof>",
    value: None,
    loc: { file, line, column, },
    raw: "",
    end: { file, line, column, },
    leading,
  })
  out
}
