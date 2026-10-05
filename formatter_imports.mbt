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
  before : String
  after : String
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
// Split after the first physical line ending outside a comment. Never split
// within a multiline block comment. The remainder belongs to the next binding
// or import group; adjacent comments travel with the previous import.
fn format_split_import_trivia(trivia : Array[Trivia]) -> (String, String) {
  let before = StringBuilder()
  let after = StringBuilder()
  let mut split = false
  for part in trivia {
    if split {
      after.write_string(part.raw)
    } else if part.kind == BlockComment && part.raw.contains("\n") {
      // Go represents a multiline comment as a paragraph, with an implicit
      // line ending before it. It starts a new import group.
      before.write_string("\n")
      after.write_string(part.raw)
      split = true
    } else if part.kind == Whitespace && part.raw.find("\n") is Some(i) {
      before.write_string(part.raw[:i + 1].to_owned())
      after.write_string(part.raw[i + 1:].to_owned())
      split = true
    } else {
      before.write_string(part.raw)
    }
  }
  let before = before.to_string()
  (
    if before.has_suffix("\n") {
      before
    } else {
      before + "\n"
    },
    after.to_string(),
  )
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
  let out = StringBuilder()
  out.write_string(format_trivia_text(tokens[0].leading))
  let entries : Array[FormatImportEntry] = []
  for n, statement in locals {
    let mut before = format_trivia_text(tokens[statement.bindings[0]].leading)
    let mut next_group = ""
    for b, start in statement.bindings {
      let next = if b + 1 < statement.bindings.length() {
        statement.bindings[b + 1]
      } else {
        statement.end + 1
      }
      let (after, next_before) = format_split_import_trivia(
        tokens[next].leading,
      )
      guard tokens[start + 3].value is Some(String(key)) else { continue }
      entries.push({
        name: tokens[start].text,
        key: @utf8.encode(key),
        start,
        before,
        after,
      })
      let paragraph = next_before.trim_start()
      before = if paragraph.has_prefix("//") ||
        paragraph.has_prefix("#") ||
        (paragraph.has_prefix("/*") && paragraph.contains("\n")) {
        "\n" + next_before
      } else {
        next_before
      }
      next_group = next_before
    }
    let boundary = n + 1 == locals.length() ||
      next_group.contains("\n") ||
      !next_group.trim().is_empty()
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
        out.write_string(entry.before)
        for i in entry.start..<=(entry.start + 4) {
          if i > entry.start {
            out.write_string(format_trivia_text(tokens[i].leading))
          }
          out.write_string(
            if i == entry.start + 4 {
              ";"
            } else {
              tokens[i].raw
            },
          )
        }
        out.write_string(entry.after)
      }
      out.write_string(next_group)
      entries.clear()
    }
  }
  for i in end..<tokens.length() {
    if i > end {
      out.write_string(format_trivia_text(tokens[i].leading))
    }
    out.write_string(tokens[i].raw)
  }
  // Rebase locations after moving imports so inline-comment classification
  // continues to describe the new lexical order.
  lex(out.to_string(), tokens[0].loc.file, retain_trivia=true) catch {
    Error(d) => raise Error(d)
    e => raise problem(Runtime, tokens[0].loc, e.to_string())
  }
}
