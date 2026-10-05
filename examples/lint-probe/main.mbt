///|
fn field(value : Json, key : String, fallback : Json) -> Json {
  match value {
    Object(fields) => fields.get(key).unwrap_or(fallback)
    _ => fallback
  }
}

///|
fn text(value : Json) -> String raise {
  guard value is String(s) else { fail("expected string") }
  s
}

///|
fn run(input : Json) -> Json raise {
  guard field(input, "snippets", []) is Array(snippets) else {
    fail("snippets")
  }
  let sources = snippets.map(s => @moonjsonnet.Source::{
    id: text(field(s, "id", null)),
    text: text(field(s, "text", null)),
  })
  let files = field(input, "files", {})
  let resolver : (String, String) -> @moonjsonnet.BinarySource raise = (
    from,
    path,
  ) => {
    let id = match from.rev_find("/") {
      Some(i) => from[:i + 1].to_owned() + path
      None => path
    }
    guard field(files, id, null) is String(source) else {
      raise @moonjsonnet.Error({
        kind: Import,
        location: { file: from, line: 1, column: 1, },
        message: "missing import: " + id,
        context: [],
      })
    }
    { id, bytes: @utf8.encode(source), }
  }
  let issues = @moonjsonnet.lint(sources, resolver~)
  {
    "messages": Json::array(issues.map(d => Json::string(d.message))),
    "diagnostics": Json::array(issues.map(d => Json::string(d.format()))),
    "found": !issues.is_empty(),
  }
}

///|
fn main {
  try {
    let (status, bytes) = @posix.read_stdin(4194304)
    guard status == 0 else { fail("read fixture") }
    guard @posix.stdout(
      run(@json.parse(@utf8.decode(bytes))).stringify() + "\n",
    ) else {
      fail("write result")
    }
  } catch {
    e => {
      @posix.stderr(e.to_string())
      @posix.exit(2)
    }
  }
}
