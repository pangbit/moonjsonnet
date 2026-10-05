// Diagnostic token names and rendering follow the pinned Go parser/lexer.
// Copyright Google Inc.; Apache-2.0; see NOTICE.

///|
fn operator_char(c : Char) -> Bool {
  match c {
    '!'
    | '$'
    | ':'
    | '~'
    | '+'
    | '-'
    | '&'
    | '|'
    | '^'
    | '='
    | '<'
    | '>'
    | '*'
    | '/'
    | '%' => true
    _ => false
  }
}

///|
fn Token::is_operator(self : Token) -> Bool {
  self.value is None &&
  self.text != "<eof>" &&
  self.text != "$" &&
  self.text.to_array().get(0) is Some(c) &&
  operator_char(c)
}

///|
fn token_kind_name(text : String) -> String {
  match text {
    "<eof>" => "end of file"
    "(" | ")" | "[" | "]" | "{" | "}" | "," | ";" | "." | "$" =>
      "\"" + text + "\""
    _ => text
  }
}

///|
fn Token::describe(self : Token) -> String {
  if self.text == "<eof>" {
    return "end of file"
  }
  let (kind, data) = if self.text == "<number>" {
    ("NUMBER", self.raw)
  } else if self.text == "<block>" {
    (
      "STRING_BLOCK",
      match self.value {
        Some(String(s)) => s
        _ => ""
      },
    )
  } else if self.text == "<string>" {
    let verbatim = self.raw.has_prefix("@")
    let single = self.raw.has_prefix("'") || self.raw.has_prefix("@'")
    let kind = (if verbatim { "VERBATIM_STRING_" } else { "STRING_" }) +
      (if single { "SINGLE" } else { "DOUBLE" })
    let data = if verbatim {
      match self.value {
        Some(String(s)) => s
        _ => ""
      }
    } else {
      self.raw[1:self.raw.length() - 1].to_owned()
    }
    (kind, data)
  } else if is_name(self.text) {
    ("IDENTIFIER", self.text)
  } else if self.is_operator() {
    ("OPERATOR", self.text)
  } else {
    return "\"" + self.text + "\""
  }
  if data.is_empty() {
    kind
  } else {
    "(" + kind + ", \"" + data + "\")"
  }
}

///|
fn Parser::end_list(
  self : Parser,
  close : String,
  element : String,
  describe? : Bool = true,
) -> Unit raise JsonnetError {
  if !self.eat(close) {
    raise problem(
      Syntax,
      self.peek().loc,
      "Expected a comma before next " +
      element +
      (if describe { ", got " + self.peek().describe() } else { "" }),
    )
  }
}
