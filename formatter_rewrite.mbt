// Portions adapted from google/go-jsonnet v0.21.0 (Apache-2.0).
// https://github.com/google/go-jsonnet/tree/67968688d9952f50662e979fab1bef889d0d3e57
// Source: internal/formatter/pretty_field_names.go
// Source: internal/formatter/no_redundant_slice_colon.go
// Source: internal/formatter/remove_plus_object.go
// Source: internal/formatter/add_plus_object.go
// Source: internal/formatter/fix_parens.go
// Copyright 2019 Google Inc. All rights reserved.
// Modifications: Adapted syntax rewrite passes to local token ranges without evaluating Jsonnet.
// License and retained attribution: LICENSE and NOTICE at the module root.

///|
fn format_name(token : Token) -> String? {
  match token.value {
    Some(String(name)) if is_name(name) &&
      name.to_array().all(c => identifier_start(c) || digit(c)) => Some(name)
    _ => None
  }
}

///|
fn format_rewrite(
  tokens : Array[Token],
  root : Expr,
  options : FormatOptions,
) -> Array[Token] {
  let layout = format_layout(tokens)
  let edited = tokens.copy()
  let skip = Array::make(tokens.length(), false)
  let insert_plus = Array::make(tokens.length(), false)
  format_plus_edits(root, tokens, skip, insert_plus, options.use_implicit_plus)
  for i, token in tokens {
    let end = layout.close[i]
    if token.text == "[" &&
      end == i + 2 &&
      tokens[i + 1].text == "<string>" &&
      options.pretty_field_names {
      let key = tokens[i + 1]
      let field = end + 1 < tokens.length() &&
        (
          tokens[end + 1].text.has_prefix(":") ||
          tokens[end + 1].text.has_prefix("+:") ||
          (tokens[end + 1].text == "(" && layout.parameter[end + 1])
        )
      if field || (layout.index[i] && format_name(key) is Some(_)) {
        if field {
          skip[i] = true
        } else {
          edited[i] = { ..token, text: ".", raw: ".", }
          // Go replaces RightBracketFodder with the string's opening fodder,
          // so comments before the removed closing bracket are discarded.
          edited[end] = { ..tokens[end], leading: [], }
        }
        skip[end] = true
        if format_name(key) is Some(name) {
          edited[i + 1] = { ..key, text: name, raw: name, value: None, }
        }
      }
    }
    if token.text == "[" && layout.index[i] && end > i + 1 {
      let last = tokens[end - 1]
      if last.text == "::" {
        edited[end - 1] = { ..last, text: ":", raw: ":", }
      } else if last.text == ":" {
        // Only remove the second colon of a slice; the first is required.
        for j = i + 1; j < end - 1; {
          if tokens[j].text == ":" {
            skip[end - 1] = true
            break
          }
          let close = layout.close[j]
          continue if close > j { close + 1 } else { j + 1 }
        }
      }
    }
    if token.text == "(" &&
      end > i + 2 &&
      tokens[i + 1].text == "(" &&
      layout.close[i + 1] == end - 1 {
      let previous = if i == 0 { "" } else { tokens[i - 1].text }
      let call = i > 0 &&
        (
          is_name(previous) ||
          previous == ")" ||
          previous == "]" ||
          previous == "}" ||
          previous == "function" ||
          tokens[i - 1].value is Some(_)
        )
      if !call {
        skip[i + 1] = true
        skip[end - 1] = true
      }
    }
  }
  let result : Array[Token] = []
  let pending : Array[Trivia] = []
  for i, token in edited {
    pending.append(token.leading)
    if !skip[i] {
      if insert_plus[i] {
        result.push({
          ..token,
          text: "+",
          raw: "+",
          value: None,
          leading: pending.copy(),
        })
        pending.clear()
      }
      result.push({ ..token, leading: pending.copy(), })
      pending.clear()
    }
  }
  result
}

///|
fn format_trailing_fodder(tokens : Array[Token]) -> Array[Token] {
  let layout = format_layout(tokens)
  let result = tokens.copy()
  for open, token in tokens {
    let close = layout.close[open]
    if close <= open + 1 ||
      !(token.text == "{" ||
      (token.text == "[" && !layout.index[open] && !layout.field_key[open])) ||
      tokens[close - 1].text != "," ||
      !tokens[close - 1].has_newline() {
      continue
    }
    let comma = result[close - 1]
    let closing = result[close]
    let after = closing.leading.copy()
    if comma.leading.last() is Some({ kind: Whitespace, raw: left, .. }) &&
      left.contains("\n") &&
      after.get(0) is Some({ kind: Whitespace, raw: right, .. }) &&
      right.find("\n") is Some(n) {
      after[0] = {
        ..after[0],
        raw: right[:n].to_owned() + right[n + 1:].to_owned(),
      }
    }
    result[close - 1] = { ..comma, leading: [], }
    result[close] = { ..closing, leading: comma.leading + after, }
  }
  result
}
