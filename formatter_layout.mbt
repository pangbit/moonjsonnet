// Portions adapted from google/go-jsonnet v0.21.0 (Apache-2.0).
// https://github.com/google/go-jsonnet/tree/67968688d9952f50662e979fab1bef889d0d3e57
// Source: internal/formatter/fix_newlines.go
// Source: internal/formatter/fix_trailing_commas.go
// Source: internal/formatter/enforce_max_blank_lines.go
// Copyright 2019 Google Inc. All rights reserved.
// Modifications: Adapted layout and trailing-comma passes to local token/trivia containers.
// License and retained attribution: LICENSE and NOTICE at the module root.

///|
priv struct FormatLayout {
  close : Array[Int]
  index : Array[Bool]
  field_key : Array[Bool]
  parameter : Array[Bool]
  expanded : Array[Bool]
  newline : Array[Bool]
  skip : Array[Bool]
  trailing_comma : Array[Bool]
}

///|
fn Token::has_newline(self : Token) -> Bool {
  self.leading.any(t => t.raw.contains("\n"))
}

///|
fn format_layout(tokens : Array[Token]) -> FormatLayout {
  let n = tokens.length()
  let layout : FormatLayout = {
    close: Array::make(n, -1),
    index: Array::make(n, false),
    field_key: Array::make(n, false),
    parameter: Array::make(n, false),
    expanded: Array::make(n, false),
    newline: Array::make(n, false),
    skip: Array::make(n, false),
    trailing_comma: Array::make(n, false),
  }
  let stack : Array[Int] = []
  let mut ends_expr = false
  for i, token in tokens {
    let t = token.text
    if t == "(" || t == "[" || t == "{" {
      layout.index[i] = t == "[" && ends_expr
      layout.parameter[i] = t == "(" &&
        i > 0 &&
        tokens[i - 1].text == "function"
      // At an object member boundary, brackets enclose a computed key,
      // not an array. A multiline key must never receive a trailing comma.
      layout.field_key[i] = t == "[" &&
        stack.last() is Some(parent) &&
        tokens[parent].text == "{" &&
        i > 0 &&
        (tokens[i - 1].text == "{" || tokens[i - 1].text == ",")
      stack.push(i)
      ends_expr = false
    } else if t == ")" || t == "]" || t == "}" {
      let start = stack.pop().unwrap()
      layout.close[start] = i
      layout.close[i] = start
      ends_expr = !layout.parameter[start]
    } else {
      ends_expr = token.value is Some(_) ||
        t == "<number>" ||
        is_name(t) ||
        t == "true" ||
        t == "false" ||
        t == "null" ||
        t == "self" ||
        t == "super" ||
        t == "$"
    }
  }
  for start, token in tokens {
    let end = layout.close[start]
    if end <= start {
      continue
    }
    if token.text == "(" &&
      end + 1 < n &&
      (
        tokens[end + 1].text == "=" ||
        tokens[end + 1].text == ":" ||
        tokens[end + 1].text == "::" ||
        tokens[end + 1].text == ":::"
      ) {
      layout.parameter[start] = true
    }
    let boundaries : Array[Int] = []
    let mut comprehension = false
    let mut local_depth = 0
    for i = start + 1; i < end; {
      let t = tokens[i].text
      if t == "local" && token.text != "{" {
        local_depth += 1
      }
      if t == ";" && local_depth > 0 {
        local_depth -= 1
      }
      if t == "," && local_depth == 0 && i + 1 < end {
        boundaries.push(i + 1)
      }
      if token.text == "(" && t == "," && tokens[i].has_newline() {
        layout.newline[i] = true
      }
      if t == "for" || t == "if" {
        // A comprehension has a top-level 'for'; its later clauses are
        // added below only after that marker is found.
        if t == "for" {
          comprehension = true
          if i > start + 1 && tokens[i - 1].text == "," {
            layout.skip[i - 1] = true
          }
        }
        if comprehension {
          boundaries.push(i)
        }
      }
      let close = layout.close[i]
      continue if close > i { close + 1 } else { i + 1 }
    }
    let outer_newline = tokens[start + 1].has_newline() ||
      tokens[end].has_newline()
    let inner_newline = boundaries.any(i => tokens[i].has_newline())
    let container = token.text == "{" ||
      (token.text == "[" && !layout.index[start] && !layout.field_key[start])
    if container && (outer_newline || inner_newline) {
      layout.expanded[start] = true
      layout.newline[start + 1] = true
      layout.newline[end] = true
      for i in boundaries {
        layout.newline[i] = true
      }
    } else if token.text == "(" {
      if outer_newline {
        layout.expanded[start] = true
        layout.newline[start + 1] = true
        layout.newline[end] = true
      }
      if inner_newline {
        for i in boundaries {
          layout.newline[i] = true
        }
      }
    }
    if container && end > start + 1 && !comprehension {
      if layout.expanded[start] {
        layout.trailing_comma[end] = tokens[end - 1].text != ","
      } else if tokens[end - 1].text == "," {
        layout.skip[end - 1] = true
      }
    }
  }
  layout
}
