// Top-level import grouping follows the pinned Go formatter's SortImports.
// Copyright Google Inc.; Apache-2.0; see NOTICE.

///|
priv struct FormatImportLocal {
  bindings : Array[Int]
  end : Int
}

///|
priv struct FormatImportEntry {
  name : String
  key : Bytes
  start : Int
  before : Array[Trivia]
  after : Array[Trivia]
}

///|
fn format_import_local(
  tokens : Array[Token],
  start : Int,
) -> FormatImportLocal? {
  if tokens[start].text != "local" {
    return None
  }
  let bindings : Array[Int] = []
  for i = start + 1; i + 4 < tokens.length(); i = i + 5 {
    if !is_name(tokens[i].text) ||
      tokens[i + 1].text != "=" ||
      tokens[i + 2].text != "import" ||
      tokens[i + 3].text != "<string>" {
      return None
    }
    bindings.push(i)
    if tokens[i + 4].text == ";" {
      return Some({ bindings, end: i + 4, })
    }
    if tokens[i + 4].text != "," {
      return None
    }
  }
  None
}

///|
fn format_trivia_text(trivia : Array[Trivia]) -> String {
  trivia.map(t => t.raw).join("")
}

///|
fn format_import_newline(loc : Location) -> Trivia {
  { kind: Whitespace, raw: "\n", range: { begin: loc, end: loc, }, margin: 0, }
}

///|
// Split after the first physical line ending outside a comment. Never split
// within a multiline block comment. The remainder belongs to the next binding
// or import group; adjacent comments travel with the previous import.
fn format_split_import_trivia(
  trivia : Array[Trivia],
  loc : Location,
) -> (Array[Trivia], Array[Trivia]) {
  let before : Array[Trivia] = []
  let after : Array[Trivia] = []
  let mut split = false
  for part in trivia {
    if split {
      after.push(part)
    } else if part.kind == BlockComment && part.raw.contains("\n") {
      // Go represents a multiline comment as a paragraph, with an implicit
      // line ending before it. It starts a new import group.
      before.push(format_import_newline(loc))
      after.push(part)
      split = true
    } else if part.kind == Whitespace && part.raw.find("\n") is Some(i) {
      before.push({ ..part, raw: part.raw[:i + 1].to_owned(), })
      after.push({ ..part, raw: part.raw[i + 1:].to_owned(), })
      split = true
    } else {
      before.push(part)
    }
  }
  if !format_trivia_text(before).has_suffix("\n") {
    before.push(format_import_newline(loc))
  }
  (before, after)
}

///|
fn format_sort_imports(
  tokens : Array[Token],
) -> Array[Token] raise JsonnetError {
  let locals : Array[FormatImportLocal] = []
  let mut end = 0
  while format_import_local(tokens, end) is Some(statement) {
    locals.push(statement)
    end = statement.end + 1
  }
  if locals.is_empty() {
    return tokens
  }
  let out : FormatImportOutput = {
    out: StringBuilder(),
    margins: Map([]),
    offset: 0,
  }
  out.write_trivia(tokens[0].leading)
  let entries : Array[FormatImportEntry] = []
  for n, statement in locals {
    let mut before = tokens[statement.bindings[0]].leading.copy()
    let mut next_group : Array[Trivia] = []
    for b, start in statement.bindings {
      let next = if b + 1 < statement.bindings.length() {
        statement.bindings[b + 1]
      } else {
        statement.end + 1
      }
      let (after, next_before) = format_split_import_trivia(
        tokens[next].leading,
        tokens[next].loc,
      )
      guard tokens[start + 3].value is Some(String(key)) else { continue }
      entries.push({
        name: tokens[start].text,
        key: @utf8.encode(key),
        start,
        before,
        after,
      })
      let paragraph = format_trivia_text(next_before).trim_start()
      before = if paragraph.has_prefix("//") ||
        paragraph.has_prefix("#") ||
        (paragraph.has_prefix("/*") && paragraph.contains("\n")) {
        [format_import_newline(tokens[next].loc)] + next_before
      } else {
        next_before
      }
      next_group = next_before
    }
    let boundary = n + 1 == locals.length() ||
      format_trivia_text(next_group).contains("\n") ||
      !format_trivia_text(next_group).trim().is_empty()
    if boundary {
      let names : Map[String, Bool] = Map([])
      let mut duplicated = false
      for entry in entries {
        if names.contains(entry.name) {
          duplicated = true
        }
        names[entry.name] = true
      }
      if !duplicated {
        format_import_sort(entries)
      }
      for entry in entries {
        out.write_string("local ")
        out.write_trivia(entry.before)
        for i in entry.start..<=(entry.start + 4) {
          if i > entry.start {
            out.write_trivia(tokens[i].leading)
          }
          out.write_string(
            if i == entry.start + 4 {
              ";"
            } else {
              tokens[i].raw
            },
          )
        }
        out.write_trivia(entry.after)
      }
      out.write_trivia(next_group)
      // Go ensures a clean line ending after the final interstitial in the
      // next group's opening fodder, even when it originally preceded local.
      let last_line = format_trivia_text(next_group)
        .split("\n")
        .collect()
        .last()
        .unwrap_or("")
      if last_line.trim().has_suffix("*/") {
        out.write_string("\n")
      }
      entries.clear()
    }
  }
  for i in end..<tokens.length() {
    if i > end {
      out.write_trivia(tokens[i].leading)
    }
    out.write_string(tokens[i].raw)
  }
  // Rebase locations after moving imports so inline-comment classification
  // continues to describe the new lexical order.
  let result = lex(out.out.to_string(), tokens[0].loc.file, retain_trivia=true) catch {
    Error(d) => raise Error(d)
    e => raise problem(Runtime, tokens[0].loc, e.to_string())
  }
  out.restore_margins(result)
  result
}
