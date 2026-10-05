///|
fn field(input : Json, key : String) -> Json {
  match input {
    Object(fields) => fields.get(key).unwrap_or(Json::null())
    _ => Json::null()
  }
}

///|
fn number(input : Json, key : String, fallback : Int) -> Int {
  match field(input, key) {
    Number(n, ..) => n.to_int()
    _ => fallback
  }
}

///|
fn flag(input : Json, key : String, fallback : Bool) -> Bool {
  match field(input, key) {
    True => true
    False => false
    _ => fallback
  }
}

///|
fn run(input : Json) -> Json {
  let mut error = ""
  let mut valid = false
  let mut idempotent = false
  let result = try {
    guard field(input, "source") is String(source) else {
      fail("expected source")
    }
    let opts = field(input, "options")
    let defaults = @moonjsonnet.FormatOptions::default()
    let options : @moonjsonnet.FormatOptions = {
      indent: number(opts, "Indent", defaults.indent),
      max_blank_lines: number(opts, "MaxBlankLines", defaults.max_blank_lines),
      string_style: match number(opts, "StringStyle", 1) {
        0 => DoubleQuotes
        1 => SingleQuotes
        _ => PreserveQuotes
      },
      comment_style: match number(opts, "CommentStyle", 1) {
        0 => HashComments
        1 => SlashComments
        _ => PreserveComments
      },
      pretty_field_names: flag(
        opts,
        "PrettyFieldNames",
        defaults.pretty_field_names,
      ),
      pad_arrays: flag(opts, "PadArrays", defaults.pad_arrays),
      pad_objects: flag(opts, "PadObjects", defaults.pad_objects),
      sort_imports: flag(opts, "SortImports", defaults.sort_imports),
      use_implicit_plus: flag(
        opts,
        "UseImplicitPlus",
        defaults.use_implicit_plus,
      ),
      strip_everything: flag(opts, "StripEverything", defaults.strip_everything),
      strip_comments: flag(opts, "StripComments", defaults.strip_comments),
      strip_all_but_comments: flag(
        opts,
        "StripAllButComments",
        defaults.strip_all_but_comments,
      ),
    }
    let result = @moonjsonnet.format_source(source, filename="entry", options~)
    ignore(@moonjsonnet.ParsedSource::parse(result))
    valid = true
    idempotent = @moonjsonnet.format_source(result, filename="entry", options~) ==
      result
    result
  } catch {
    @moonjsonnet.Error(d) => {
      error = d.format()
      ""
    }
    e => {
      error = e.to_string()
      ""
    }
  }
  { "result": result, "error": error, "valid": valid, "idempotent": idempotent }
}

///|
fn main {
  try {
    let (status, bytes) = @posix.read_stdin(1048576)
    guard status == 0 else { fail("cannot read fixture") }
    guard @posix.stdout(
      run(@json.parse(@utf8.decode(bytes))).stringify() + "\n",
    ) else {
      fail("cannot write result")
    }
  } catch {
    e => {
      @posix.stderr(e.to_string())
      @posix.exit(2)
    }
  }
}
