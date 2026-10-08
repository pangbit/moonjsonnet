///|
fn field(input : Json, key : String, fallback : Json) -> Json {
  match input {
    Object(fields) => fields.get(key).unwrap_or(fallback)
    _ => fallback
  }
}

///|
fn text(input : Json, key : String, fallback : String) -> String {
  match field(input, key, Json::string(fallback)) {
    String(value) => value
    _ => fallback
  }
}

///|
fn run(input : Json) -> Json raise {
  let source = text(input, "Source", text(input, "source", ""))
  let filename = text(input, "Filename", text(input, "filename", "entry"))
  let formatter = @moonjsonnet.DiagnosticFormatter::new()
  formatter.set_source({ id: filename, text: source, })
  if field(input, "trace_size", null) is Number(size, ..) {
    formatter.set_max_trace(size.to_int())
  }
  let colors : Array[Json] = []
  if field(input, "color", false) == Json::boolean(true) {
    formatter.set_color(color=fragment => {
      colors.push(Json::string(fragment))
      "<color>" + fragment + "</color>"
    })
  }
  let evaluator = @moonjsonnet.Evaluator::new()
  evaluator.set_diagnostic_formatter(formatter~)
  let files = field(input, "files", {})
  if files is Object(files) {
    for name, value in files {
      if value is String(source) {
        formatter.set_source({ id: name, text: source, })
      }
    }
  }
  evaluator.set_importer(resolver=(_, path) => {
    guard field(files, path, null) is String(source) else {
      fail("missing import: " + path)
    }
    { id: path, text: source, }
  })
  for
    (key, setter) in [
      ("ext_code", fn(name, source) raise { evaluator.ext_code(name, source) }),
      ("tla_code", fn(name, source) raise { evaluator.tla_code(name, source) }),
    ] {
    if field(input, key, {}) is Object(bindings) {
      for name, value in bindings {
        guard value is String(source) else { fail("parameter") }
        setter(name, source)
      }
    }
  }
  evaluator.set_string_output(
    field(input, "string_output", false) == Json::boolean(true),
  )
  let mut failed = false
  let frames : Array[Json] = []
  let bytes : Array[Json] = []
  let output = try {
    let program = @moonjsonnet.Program::parse(source, filename~)
    match text(input, "mode", "text") {
      "stream" =>
        Json::array(evaluator.evaluate_stream(program).map(Json::string))
      "multi" => {
        let values : Map[String, Json] = Map([])
        for name, value in evaluator.evaluate_multi(program) {
          values[name] = Json::string(value)
        }
        Json::object(values)
      }
      _ => Json::string(evaluator.evaluate_text(program))
    }
  } catch {
    @moonjsonnet.Error(d) => {
      failed = true
      for frame in d.trace {
        frames.push({ "location": frame.location.format(), "name": frame.name })
      }
      for byte in evaluator.format_error_bytes(d) {
        bytes.push(Json::number(byte.to_int().to_double()))
      }
      Json::null()
    }
  }
  {
    "error": failed,
    "output": output,
    "bytes": bytes,
    "frames": frames,
    "color_calls": colors,
  }
}

///|
fn main {
  try {
    let (status, bytes) = @posix.read_stdin(1048576)
    guard status == 0 else { fail("diagnostic input read") }
    ignore(
      @posix.stdout(run(@json.parse(@utf8.decode(bytes))).stringify() + "\n"),
    )
  } catch {
    e => {
      @posix.stderr(e.to_string())
      @posix.exit(1)
    }
  }
}
