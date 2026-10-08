///|
priv struct FormatOutput {
  out : StringBuilder
  limits : Limits
  loc : Location
  mut bytes : Int
  mut steps : Int
  mut line_start : Bool
  mut column : Int
}

///|
fn FormatOutput::write(
  self : FormatOutput,
  text : String,
) -> Unit raise JsonnetError {
  let size = @utf8.encode(text).length()
  if size > self.limits.output_bytes - self.bytes {
    raise problem(Limit, self.loc, "format output byte limit exceeded")
  }
  self.bytes += size
  self.out.write_string(text)
  if !text.is_empty() {
    self.line_start = text.has_suffix("\n")
    for c in text.to_array() {
      self.column = if c == '\n' {
        0
      } else {
        self.column + @utf8.encode(c.to_string()).length()
      }
    }
  }
}

///|
fn FormatOutput::tick(self : FormatOutput) -> Unit raise JsonnetError {
  self.steps += 1
  if self.steps > self.limits.steps {
    raise problem(Limit, self.loc, "format step limit exceeded")
  }
}

///|
fn FormatOutput::indent(
  self : FormatOutput,
  spaces : Int,
) -> Unit raise JsonnetError {
  if self.line_start {
    if spaces > self.limits.output_bytes - self.bytes {
      raise problem(Limit, self.loc, "format output byte limit exceeded")
    }
    for _ in 0..<spaces {
      self.write(" ")
    }
  }
}

///|
priv struct FormatGroup {
  open : String
  parameter : Bool
  index : Bool
  expanded : Bool
}

///|
priv struct FormatLocal {
  depth : Int
  in_object : Bool
  mut equal_pending : Bool
}

///|
fn format_tokens(
  tokens : Array[Token],
  root : Expr,
  options : FormatOptions,
  limits : Limits,
  loc : Location,
) -> String raise JsonnetError {
  let tokens = format_rewrite(tokens, root, options)
  let tokens = if options.sort_imports {
    format_sort_imports(tokens)
  } else {
    tokens
  }
  let tokens = format_trailing_fodder(tokens)
  let writer : FormatOutput = {
    out: StringBuilder(),
    limits,
    loc,
    bytes: 0,
    steps: 0,
    line_start: true,
    column: 0,
  }
  let groups : Array[FormatGroup] = []
  let locals : Array[FormatLocal] = []
  let layout = format_layout(tokens)
  let expression = parse_tokens(tokens, limits.depth) catch {
    Error(d) => raise Error(d)
    e => raise problem(Runtime, loc, e.to_string())
  }
  let indent_plan = format_indent_plan(tokens, expression, layout, writer)
  let columns = Array::make(tokens.length(), 0)
  let mut previous = ""
  let mut ends_expr = false
  let mut tight_after = false
  let mut first_comment = true
  let mut last_line = 0
  let assertions : Array[Int] = []
  let only_comments = !options.strip_comments && options.strip_all_but_comments
  let strip_all = !options.strip_comments &&
    !only_comments &&
    options.strip_everything
  for i, token in tokens {
    writer.tick()
    let t = token.text
    let closing = t == ")" || t == "]" || t == "}"
    let mut spaces = if options.indent > 0 && !only_comments {
      indent_plan.line_up[i].resolve(
        columns,
        options.indent,
        limits.output_bytes,
      )
    } else if options.indent > 0 || (layout.newline[i] && !token.has_newline()) {
      0
    } else {
      token.loc.column - 1
    }
    let block_base = if options.indent > 0 && !only_comments {
      indent_plan.base[i].resolve(columns, options.indent, limits.output_bytes)
    } else {
      spaces
    }
    if layout.trailing_comma[i] && !only_comments {
      writer.write(",")
    }
    let mut newline_count = 0
    let mut interstitial = false
    let mut comment_column : Int? = None
    for trivia in token.leading {
      writer.tick()
      match trivia.kind {
        Whitespace =>
          if !strip_all && !only_comments && !options.strip_comments {
            newline_count += trivia.raw
              .to_array()
              .filter(c => c == '\n')
              .length()
          }
        LineComment | BlockComment => {
          if strip_all || options.strip_comments {
            continue
          }
          let paragraph = trivia.kind == BlockComment &&
            trivia.raw.contains("\n")
          let inline = !paragraph &&
            last_line == trivia.range.begin.line &&
            last_line > 0
          let original_newline = newline_count > 0
          if only_comments && inline && trivia.kind == LineComment {
            continue
          }
          if newline_count > 0 {
            let count = if options.max_blank_lines > 0 &&
              options.max_blank_lines < newline_count - 1 {
              options.max_blank_lines + 1
            } else {
              newline_count
            }
            if writer.bytes > 0 {
              for n in 0..<count {
                if n > 0 || !writer.line_start {
                  writer.write("\n")
                }
              }
            }
            newline_count = 0
          } else if (only_comments || paragraph) && !writer.line_start {
            writer.write("\n")
          }
          let comment_indent = if options.indent > 0 {
            if closing &&
              groups.last() is Some({ expanded: true, .. }) &&
              spaces <= limits.output_bytes - options.indent {
              spaces + options.indent
            } else {
              spaces
            }
          } else if paragraph && !original_newline {
            // A paragraph that originally flowed after a token acquires an
            // implicit line ending. Go takes its indent from the following
            // physical line, or zero when that line ending is also implicit.
            if trivia.range.end.line == token.loc.line {
              0
            } else {
              token.loc.column - 1
            }
          } else {
            trivia.range.begin.column - 1
          }
          let follows_comment = interstitial && !writer.line_start
          writer.indent(comment_indent)
          if follows_comment {
            writer.write(" ")
          } else if !writer.line_start && !previous.is_empty() && inline {
            let crowded = t != ";" &&
              t != "," &&
              t != "." &&
              t != ")" &&
              !(t == "(" && ends_expr) &&
              !t.has_prefix(":") &&
              !t.has_prefix("+:") &&
              !(t == "]" && groups.last() is Some({ index: true, .. })) &&
              previous != "." &&
              previous != "(" &&
              (previous != "[" || options.pad_arrays) &&
              (previous != "{" || options.pad_objects)
            if trivia.kind == LineComment {
              writer.write("  ")
            } else if crowded {
              writer.write(" ")
            }
          }
          let comment = format_comment(
            trivia.raw.trim_end().to_owned(),
            options.comment_style,
            first_comment,
          )
          if !paragraph && trivia.kind == BlockComment && comment_column is None {
            comment_column = Some(writer.column)
          }
          if paragraph {
            for line in format_comment_lines(trivia) {
              if !line.is_empty() {
                writer.indent(comment_indent)
                writer.write(line)
              }
              writer.write("\n")
            }
            if options.indent <= 0 && trivia.range.end.line == token.loc.line {
              spaces = 0
            }
          } else {
            writer.write(comment)
          }
          first_comment = false
          if trivia.kind == LineComment ||
            trivia.raw.contains("\n") ||
            only_comments {
            if !paragraph {
              writer.write("\n")
            }
          } else {
            interstitial = true
          }
        }
        TokenText => ()
      }
    }
    if only_comments {
      if !(t == "," && !token.has_newline() && token.loc.line > last_line) {
        last_line = token.end.line
      }
      continue
    }
    if options.strip_comments {
      let lines = format_stripped_lines(
        token,
        previous.is_empty(),
        layout.newline[i],
        options.max_blank_lines,
      )
      for n, (count, original_indent) in lines {
        for _ in 0..<count {
          writer.write("\n")
        }
        let indent = if options.indent > 0 { spaces } else { original_indent }
        if n + 1 < lines.length() {
          writer.indent(indent)
        } else if options.indent <= 0 {
          spaces = indent
        }
      }
    }
    if t == "<eof>" {
      if !writer.line_start {
        writer.write("\n")
      }
      break
    }
    if layout.skip[i] {
      continue
    }
    if !strip_all &&
      !options.strip_comments &&
      layout.newline[i] &&
      newline_count == 0 &&
      !writer.line_start {
      newline_count = 1
    }
    if newline_count > 0 && (writer.bytes > 0 || !previous.is_empty()) {
      let count = if options.max_blank_lines > 0 &&
        options.max_blank_lines < newline_count - 1 {
        options.max_blank_lines + 1
      } else {
        newline_count
      }
      for n in 0..<count {
        if n > 0 || !writer.line_start {
          writer.write("\n")
        }
      }
    }
    let inside = groups.last()
    let local_equal = t == "=" &&
      locals.last() is Some(scope) &&
      scope.equal_pending &&
      scope.depth == groups.length()
    let compact_equal = t == "=" &&
      !local_equal &&
      inside is Some({ open: "(", .. })
    let prefix = (t == "+" || t == "-" || t == "!" || t == "~") && !ends_expr
    let compact_colon = (t == ":" || t == "::") &&
      inside is Some({ index: true, .. })
    let empty_close = closing &&
      (
        (previous == "(" && t == ")") ||
        (previous == "[" && t == "]") ||
        (previous == "{" && t == "}")
      )
    if t == "assert" {
      assertions.push(groups.length())
    }
    if closing {
      while assertions.last() == Some(groups.length()) {
        ignore(assertions.pop())
      }
    }
    if (t == "," || t == ";") && assertions.last() == Some(groups.length()) {
      ignore(assertions.pop())
    }
    let assertion_colon = t == ":" && assertions.last() == Some(groups.length())
    if assertion_colon {
      ignore(assertions.pop())
    }
    let spaced = if previous.is_empty() || writer.line_start || empty_close {
      false
    } else if t == "," || t == ";" || t == "." || t == ")" {
      false
    } else if t == "]" {
      inside is Some({ index: false, .. }) && options.pad_arrays
    } else if t == "}" {
      options.pad_objects
    } else if assertion_colon {
      true
    } else if t == ":" ||
      t == "::" ||
      t == ":::" ||
      t == "+:" ||
      t == "+::" ||
      t == "+:::" {
      false
    } else if compact_equal {
      false
    } else if t == "(" {
      if previous == "[" {
        inside is Some({ index: false, .. }) && options.pad_arrays
      } else {
        !ends_expr && previous != "function" && previous != "(" && !tight_after
      }
    } else if t == "[" && ends_expr {
      false
    } else if tight_after || previous == "." || previous == "(" {
      false
    } else if previous == "[" {
      inside is Some({ index: false, .. }) && options.pad_arrays
    } else if previous == "{" {
      options.pad_objects
    } else {
      true
    }
    let comment_space = interstitial &&
      !writer.line_start &&
      !closing &&
      t != "," &&
      t != ";" &&
      !t.has_prefix(":") &&
      !t.has_prefix("+:") &&
      t != "." &&
      !(t == "(" && ends_expr) &&
      previous != "."
    writer.indent(spaces)
    if spaced || comment_space {
      writer.write(" ")
    }
    // Opening interstitial comments belong to the expression's fodder. Their
    // width does not move the expression's continuation anchor.
    columns[i] = comment_column.unwrap_or(writer.column)
    let mut raw = format_string(token, options.string_style)
    if options.pretty_field_names &&
      token.text == "<string>" &&
      tokens.get(i + 1) is Some(next) &&
      (
        next.text == ":" ||
        next.text == "::" ||
        next.text == ":::" ||
        next.text == "+:" ||
        next.text == "+::" ||
        next.text == "+:::" ||
        (next.text == "(" && layout.parameter[i + 1])
      ) {
      if token.value is Some(String(name)) &&
        is_name(name) &&
        name.to_array().all(c => identifier_start(c) || digit(c)) {
        raw = name
      }
    }
    if t == "<block>" {
      writer.write_block(token, options.indent, block_base)
    } else {
      writer.write(raw)
    }
    if locals.last() is Some(scope) && scope.depth == groups.length() {
      if local_equal {
        scope.equal_pending = false
      }
      if t == ";" || (t == "," && scope.in_object) {
        ignore(locals.pop())
      } else if t == "," {
        scope.equal_pending = true
      }
    }
    if t == "local" {
      locals.push({
        depth: groups.length(),
        in_object: inside is Some({ open: "{", .. }) &&
        (previous == "{" || previous == ","),
        equal_pending: true,
      })
    }
    if t == "(" || t == "[" || t == "{" {
      groups.push({
        open: t,
        parameter: layout.parameter[i],
        index: layout.index[i] || layout.field_key[i],
        expanded: layout.expanded[i],
      })
      ends_expr = false
    } else if closing {
      let group = groups.pop().unwrap()
      ends_expr = !group.parameter
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
    tight_after = prefix || compact_equal || compact_colon
    previous = t
    if !(t == "," && !token.has_newline() && token.loc.line > last_line) {
      last_line = token.end.line
    }
  }
  if only_comments {
    writer.write("null\n")
  }
  writer.out.to_string()
}
