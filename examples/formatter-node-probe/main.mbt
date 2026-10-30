///|
fn options(style : Int32) -> @moonjsonnet.FormatOptions {
  let defaults = @moonjsonnet.FormatOptions::default()
  match style {
    1 => { ..defaults, string_style: DoubleQuotes, }
    2 => { ..defaults, indent: 4, }
    3 => { ..defaults, pretty_field_names: false, }
    4 => { ..defaults, pad_arrays: true, }
    5 => { ..defaults, strip_comments: true, }
    6 => { ..defaults, strip_everything: true, }
    7 => { ..defaults, sort_imports: false, }
    _ => defaults
  }
}

///|
fn edit(tree : @moonjsonnet.RawAst, mode : String) -> Unit raise {
  if mode == "append" {
    let original = tree.root.parts.copy()
    tree.root.parts.clear()
    for part in original {
      if part is Text(text) && text.kind is TokenText && text.text == "]" {
        tree.root.parts.push(Text({ ..text, text: ",", }))
        tree.root.parts.push(
          Child({
            kind: Number,
            range: None,
            parts: [Text({ ..text, text: "3", })],
          }),
        )
      }
      tree.root.parts.push(part)
    }
    return
  }
  if mode == "remove" {
    let positions : Array[Int32] = []
    for i, part in tree.root.parts {
      if part is Child(_) {
        positions.push(i)
      }
    }
    guard positions.length() >= 2 else { fail("array children") }
    let retained = tree.root.parts[:positions[0]].to_owned()
    retained.append(tree.root.parts[positions[1]:].to_owned())
    tree.root.parts.clear()
    tree.root.parts.append(retained)
    return
  }
  let stack = [tree.root]
  let mut changed = false
  while stack.pop() is Some(node) {
    let children : Array[@moonjsonnet.RawNode] = []
    for i, part in node.parts {
      match part {
        Child(child) => children.push(child)
        Text(text) => {
          let replacement = if mode == "number" &&
            !changed &&
            text.kind is TokenText &&
            text.text == "1" {
            changed = true
            "42"
          } else if mode == "string" &&
            text.kind is TokenText &&
            text.text == "'abc'" {
            "'中\\n'"
          } else if mode == "rename" &&
            text.kind is TokenText &&
            text.text == "z" {
            "b"
          } else if mode == "comments" && text.kind is BlockComment {
            text.text.replace(old="head", new="added")
          } else {
            text.text
          }
          node.parts[i] = Text({ ..text, text: replacement, })
        }
      }
    }
    for i = children.length() - 1; i >= 0; i = i - 1 {
      stack.push(children[i])
    }
  }
  if mode == "comments" {
    for i, part in tree.final_fodder {
      tree.final_fodder[i] = {
        ..part,
        text: part.text.replace(old="tail", new="changed"),
      }
    }
  }
}

///|
fn run(input : Json) -> Json raise {
  guard input
    is {
      "source": String(source),
      "mode": String(mode),
      "style": Number(style, ..),
      ..
    } else {
    fail("node input")
  }
  let raw = @moonjsonnet.RawAst::parse(source, filename="entry")
  let independent = raw.clone()
  edit(raw, mode)
  assert_eq(independent.text(), source)
  let original = raw.text()
  let options = options(style.to_int())
  let result = raw.format(options~)
  assert_eq(raw.text(), original)
  ignore(@moonjsonnet.SyntaxDocument::parse(result))
  let idempotent = @moonjsonnet.format_syntax_source(result, options~) == result
  { "result": result, "error": "", "valid": true, "idempotent": idempotent }
}

///|
fn main {
  try {
    let (status, bytes) = @posix.read_stdin(1048576)
    guard status == 0 else { fail("node input read") }
    let input = @json.parse(@utf8.decode(bytes))
    ignore(@posix.stdout(run(input).stringify() + "\n"))
  } catch {
    e => {
      @posix.stderr(e.to_string())
      @posix.exit(1)
    }
  }
}
