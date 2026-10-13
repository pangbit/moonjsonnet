// Portions adapted from google/go-jsonnet v0.21.0 (Apache-2.0).
// https://github.com/google/go-jsonnet/tree/67968688d9952f50662e979fab1bef889d0d3e57
// Source: internal/formatter/strip.go
// Source: internal/parser/lexer.go
// Source: ast/fodder.go
// Copyright 2019 Google Inc. All rights reserved.
// Copyright 2016 Google Inc. All rights reserved.
// Copyright 2018 Google Inc. All rights reserved.
// Modifications: Adapted stripping and fodder classification to local token/trivia containers.
// License and retained attribution: LICENSE and NOTICE at the module root.

// Fodder classification and stripping follow go-jsonnet v0.21.0 lexer.go,
// ast/fodder.go and internal/formatter/strip.go. Apache-2.0; see NOTICE.

///|
priv enum FormatStripFodder {
  RetainedLineEnd(Int, Int)
  RemovedParagraph
  RemovedInterstitial
}

///|
fn format_whitespace(raw : String) -> (Int, Int) {
  let mut lines = 0
  let mut indent = 0
  for c in raw.to_array() {
    match c {
      '\n' => {
        lines += 1
        indent = 0
      }
      ' ' => indent += 1
      '\t' => indent += 8
      _ => ()
    }
  }
  (lines, indent)
}

///|
fn format_stripped_lines(
  token : Token,
  first : Bool,
  ensure_newline : Bool,
  max_blank_lines : Int,
) -> Array[(Int, Int)] {
  let fodder : Array[FormatStripFodder] = []
  let mut fresh_line = first
  let trivia = token.leading
  for i = 0; i < trivia.length(); {
    let part = trivia[i]
    if part.kind == Whitespace {
      let (lines, indent) = format_whitespace(part.raw)
      // Whitespace directly before EOF is discarded by Go's outer lexer loop.
      if lines > 0 && !(token.text == "<eof>" && i + 1 == trivia.length()) {
        fodder.push(RetainedLineEnd(lines, indent))
      }
      if lines > 0 {
        fresh_line = true
      }
      continue i + 1
    }
    let next = trivia.get(i + 1)
    let (lines, indent, advance) = match next {
      Some({ kind: Whitespace, raw, .. }) => {
        let (lines, indent) = format_whitespace(raw)
        (lines, indent, 2)
      }
      _ => (0, 0, 1)
    }
    if part.kind == LineComment {
      if fresh_line {
        fodder.push(RemovedParagraph)
      } else {
        fodder.push(RetainedLineEnd(if lines > 0 { lines } else { 1 }, indent))
      }
    } else if part.kind == BlockComment {
      if part.raw.contains("\n") {
        if !(fodder.last() is Some(RetainedLineEnd(_, _) | RemovedParagraph)) {
          fodder.push(RetainedLineEnd(1, if lines > 0 { indent } else { 0 }))
        }
        fodder.push(RemovedParagraph)
      } else {
        fodder.push(RemovedInterstitial)
        if lines > 0 {
          fodder.push(RetainedLineEnd(lines, indent))
        }
      }
    }
    fresh_line = lines > 0
    continue i + advance
  }
  let mut start = 0
  if first {
    while start < fodder.length() && fodder[start] is RetainedLineEnd(_, _) {
      start += 1
    }
  }
  // FixNewlines runs before StripComments. Paragraphs already have a clean
  // endline; an interstitial needs a distinct line-end element.
  if ensure_newline &&
    !(fodder.last() is Some(RetainedLineEnd(_, _) | RemovedParagraph)) {
    fodder.push(RetainedLineEnd(1, 0))
  }
  let lines : Array[(Int, Int)] = []
  for element in fodder[start:] {
    if element is RetainedLineEnd(count, indent) {
      lines.push(
        (
          if max_blank_lines > 0 && count - 1 > max_blank_lines {
            max_blank_lines + 1
          } else {
            count
          },
          indent,
        ),
      )
    }
  }
  if token.text == "<eof>" && !lines.is_empty() {
    let last = lines.length() - 1
    lines[last] = (1, lines[last].1)
  }
  lines
}
