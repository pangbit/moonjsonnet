// Go 1.24.0 encoding/json scanner transition/error rules.
// Copyright The Go Authors; BSD-3-Clause, see licenses/GO-BSD-3-Clause.txt.

///|
priv enum JsonDiagnosticState {
  Value
  ValueOrEmpty
  Key
  KeyOrEmpty
  EndValue
  EndTop
  Quoted
  Escape
  Hex(Int32)
  Negative
  Zero
  Integer
  Dot
  Fraction
  Exponent
  ExponentSign
  ExponentDigits
  Literal(Bytes, Int32, String)
}

///|
priv struct JsonDiagnosticScanner {
  mut state : JsonDiagnosticState
  // Object key = 0, object value = 1, array value = 2.
  stack : Array[Int32]
}

///|
fn json_space(c : Byte) -> Bool {
  c == 32 || c == 9 || c == 10 || c == 13
}

///|
fn json_error_character(c : Byte, context : String) -> String {
  let quote = if c == 39 {
    "'\\''"
  } else if c == 34 {
    "'\"'"
  } else {
    let quoted = lint_quote(c.to_int().to_char().unwrap().to_string())
    "'" + quoted[1:quoted.length() - 1].to_owned() + "'"
  }
  "invalid character " + quote + " " + context
}

///|
fn JsonDiagnosticScanner::close(self : JsonDiagnosticScanner) -> Unit {
  ignore(self.stack.pop())
  self.state = if self.stack.is_empty() { EndTop } else { EndValue }
}

///|
fn JsonDiagnosticScanner::step(
  self : JsonDiagnosticScanner,
  c : Byte,
) -> String? {
  // A numeric terminator is reprocessed by EndValue, and then by EndTop.
  // These transitions are constant depth and never recurse with source length.
  while true {
    match self.state {
      ValueOrEmpty => {
        if json_space(c) {
          return None
        }
        self.state = if c == 93 { EndValue } else { Value }
        continue
      }
      KeyOrEmpty => {
        if json_space(c) {
          return None
        }
        if c == 125 {
          self.stack[self.stack.length() - 1] = 1
          self.state = EndValue
        } else {
          self.state = Key
        }
        continue
      }
      Value => {
        if json_space(c) {
          return None
        }
        self.state = match c {
          123 => {
            self.stack.push(0)
            KeyOrEmpty
          }
          91 => {
            self.stack.push(2)
            ValueOrEmpty
          }
          34 => Quoted
          45 => Negative
          48 => Zero
          116 => Literal(b"true", 1, "true")
          102 => Literal(b"false", 1, "false")
          110 => Literal(b"null", 1, "null")
          _ if c >= 49 && c <= 57 => Integer
          _ =>
            return Some(
              json_error_character(c, "looking for beginning of value"),
            )
        }
        return None
      }
      Key => {
        if json_space(c) {
          return None
        }
        if c != 34 {
          return Some(
            json_error_character(
              c, "looking for beginning of object key string",
            ),
          )
        }
        self.state = Quoted
        return None
      }
      EndValue => {
        if self.stack.is_empty() {
          self.state = EndTop
          continue
        }
        if json_space(c) {
          return None
        }
        let last = self.stack.length() - 1
        match self.stack[last] {
          0 => {
            if c != 58 {
              return Some(json_error_character(c, "after object key"))
            }
            self.stack[last] = 1
            self.state = Value
          }
          1 =>
            if c == 44 {
              self.stack[last] = 0
              self.state = Key
            } else if c == 125 {
              self.close()
            } else {
              return Some(
                json_error_character(c, "after object key:value pair"),
              )
            }
          _ =>
            if c == 44 {
              self.state = Value
            } else if c == 93 {
              self.close()
            } else {
              return Some(json_error_character(c, "after array element"))
            }
        }
        return None
      }
      EndTop =>
        return if json_space(c) {
          None
        } else {
          Some(json_error_character(c, "after top-level value"))
        }
      Quoted => {
        if c == 34 {
          self.state = EndValue
        } else if c == 92 {
          self.state = Escape
        } else if c < 32 {
          return Some(json_error_character(c, "in string literal"))
        }
        return None
      }
      Escape => {
        self.state = match c {
          98 | 102 | 110 | 114 | 116 | 92 | 47 | 34 => Quoted
          117 => Hex(4)
          _ => return Some(json_error_character(c, "in string escape code"))
        }
        return None
      }
      Hex(left) => {
        if !((c >= 48 && c <= 57) ||
          (c >= 97 && c <= 102) ||
          (c >= 65 && c <= 70)) {
          return Some(
            json_error_character(c, "in \\u hexadecimal character escape"),
          )
        }
        self.state = if left == 1 { Quoted } else { Hex(left - 1) }
        return None
      }
      Negative => {
        self.state = if c == 48 {
          Zero
        } else if c >= 49 && c <= 57 {
          Integer
        } else {
          return Some(json_error_character(c, "in numeric literal"))
        }
        return None
      }
      Integer => {
        if c >= 48 && c <= 57 {
          return None
        }
        self.state = Zero
        continue
      }
      Zero => {
        if c == 46 {
          self.state = Dot
          return None
        }
        if c == 101 || c == 69 {
          self.state = Exponent
          return None
        }
        self.state = EndValue
        continue
      }
      Dot => {
        if c < 48 || c > 57 {
          return Some(
            json_error_character(c, "after decimal point in numeric literal"),
          )
        }
        self.state = Fraction
        return None
      }
      Fraction => {
        if c >= 48 && c <= 57 {
          return None
        }
        if c == 101 || c == 69 {
          self.state = Exponent
          return None
        }
        self.state = EndValue
        continue
      }
      Exponent => {
        self.state = ExponentSign
        if c == 43 || c == 45 {
          return None
        }
        continue
      }
      ExponentSign => {
        if c < 48 || c > 57 {
          return Some(json_error_character(c, "in exponent of numeric literal"))
        }
        self.state = ExponentDigits
        return None
      }
      ExponentDigits => {
        if c >= 48 && c <= 57 {
          return None
        }
        self.state = EndValue
        continue
      }
      Literal(word, index, name) => {
        if c != word[index] {
          return Some(
            json_error_character(
              c,
              "in literal " +
              name +
              " (expecting '" +
              word[index].to_int().to_char().unwrap().to_string() +
              "')",
            ),
          )
        }
        self.state = if index == word.length() - 1 {
          EndValue
        } else {
          Literal(word, index + 1, name)
        }
        return None
      }
    }
  } nobreak {
    abort("unreachable JSON diagnostic scanner")
  }
}

///|
fn Vm::json_syntax_error(
  self : Vm,
  source : String,
  loc : Location,
) -> String raise {
  let scanner : JsonDiagnosticScanner = { state: Value, stack: [], }
  for c in @utf8.encode(source) {
    self.tick(loc)
    if scanner.step(c) is Some(error) {
      return error
    }
  }
  if scanner.state is EndTop {
    return "invalid JSON"
  }
  if scanner.step(32) is Some(error) {
    return error
  }
  if scanner.state is EndTop {
    "invalid JSON"
  } else {
    "unexpected end of JSON input"
  }
}
