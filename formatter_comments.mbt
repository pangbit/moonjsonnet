// Paragraph normalization follows the pinned Go lexer; see NOTICE.

///|
fn format_comment_lines(trivia : Trivia) -> Array[String] {
  trivia.raw
  .split("\n")
  .map(line => {
    let chars = line.to_array()
    let mut start = 0
    while start < chars.length() &&
          start < trivia.margin &&
          (chars[start] == ' ' || chars[start] == '\t' || chars[start] == '\r') {
      start += 1
    }
    let mut end = chars.length()
    while end > start &&
          (
            chars[end - 1] == ' ' ||
            chars[end - 1] == '\t' ||
            chars[end - 1] == '\r'
          ) {
      end -= 1
    }
    String::from_array(chars[start:end].to_owned())
  })
  .collect()
}

///|
// Import sorting re-lexes moved text, but a paragraph's margin belongs to the
// original comment. Track its offset while serializing, then restore metadata.
priv struct FormatImportOutput {
  out : StringBuilder
  margins : Map[Int, Int]
  mut offset : Int
}

///|
fn FormatImportOutput::write_string(
  self : FormatImportOutput,
  raw : String,
) -> Unit {
  self.out.write_string(raw)
  self.offset += raw.length()
}

///|
fn FormatImportOutput::write_trivia(
  self : FormatImportOutput,
  parts : Array[Trivia],
) -> Unit {
  for part in parts {
    if part.kind == BlockComment {
      self.margins[self.offset] = part.margin
    }
    self.write_string(part.raw)
  }
}

///|
fn FormatImportOutput::restore_margins(
  self : FormatImportOutput,
  tokens : Array[Token],
) -> Unit {
  let mut offset = 0
  for token in tokens {
    for i, part in token.leading {
      if self.margins.get(offset) is Some(margin) {
        token.leading[i] = { ..part, margin, }
      }
      offset += part.raw.length()
    }
    offset += token.raw.length()
  }
}
