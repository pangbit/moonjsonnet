///|
fn object(input : Json, key : String) -> Map[String, Json] {
  match input {
    Object(fields) =>
      match fields.get(key) {
        Some(Object(value)) => value
        _ => Map([])
      }
    _ => Map([])
  }
}

///|
fn string(input : Json, key : String, fallback : String) -> String {
  match input {
    Object(fields) =>
      match fields.get(key) {
        Some(String(value)) => value
        _ => fallback
      }
    _ => fallback
  }
}

///|
fn programs(
  input : Json,
  key : String,
) -> Map[String, @moonjsonnet.Program] raise {
  let result = Map([])
  for name, entry in object(input, key) {
    result[name] = @moonjsonnet.Program::parse(
      string(entry, "source", ""),
      filename=string(entry, "filename", "node"),
    )
  }
  result
}

///|
fn code(input : Json, key : String) -> Map[String, String] {
  let result = Map([])
  for name, value in object(input, key) {
    if value is String(text) {
      result[name] = text
    }
  }
  result
}

///|
fn run(input : Json) -> Json {
  let requests : Array[Json] = []
  let traces = StringBuilder()
  let mut calls = 0
  let mut error = ""
  let result = try {
    let program = @moonjsonnet.Program::parse(
      string(input, "source", ""),
      filename="main",
    )
    let ext_vars = object(input, "ext_vars")
    let ext_code = code(input, "ext_code")
    let ext_programs = programs(input, "ext_programs")
    let tla_vars = object(input, "tla_vars")
    let tla_code = code(input, "tla_code")
    let tla_programs = programs(input, "tla_programs")
    let native : @moonjsonnet.NativeFunction = {
      params: [],
      callback: fn(_) {
        calls += 1
        42
      },
    }
    let native_functions = Map([("tick", native)])
    let trace = fn(loc : @moonjsonnet.Location, message : String) {
      traces.write_string("TRACE: \{loc.file}:\{loc.line} \{message}\n")
    }
    let resolver : (String, String) -> @moonjsonnet.Source raise = (from, path) => {
      requests.push([Json::string(from), Json::string(path)])
      guard object(input, "imports").get(path) is Some(String(text)) else {
        fail("missing import: " + path)
      }
      { id: "resolved/" + path, text, }
    }
    let binary_resolver : (String, String) -> @moonjsonnet.BinarySource raise = (
      from,
      path,
    ) => {
      let source = resolver(from, path)
      { id: source.id, bytes: @utf8.encode(source.text), }
    }
    match string(input, "mode", "json") {
      "text" | "raw" =>
        Json::string(
          program.evaluate_text(
            ext_vars~,
            ext_code~,
            ext_programs~,
            tla_vars~,
            tla_code~,
            tla_programs~,
            native_functions~,
            trace~,
            resolver~,
            binary_resolver~,
            string_output=string(input, "mode", "") == "raw",
          ),
        )
      "stream" =>
        Json::array(
          program
          .evaluate_stream(
            ext_vars~,
            ext_code~,
            ext_programs~,
            tla_vars~,
            tla_code~,
            tla_programs~,
            native_functions~,
            trace~,
            resolver~,
            binary_resolver~,
          )
          .map(Json::string),
        )
      "multi" | "multi-raw" =>
        Json::object(
          program
          .evaluate_multi(
            ext_vars~,
            ext_code~,
            ext_programs~,
            tla_vars~,
            tla_code~,
            tla_programs~,
            native_functions~,
            trace~,
            resolver~,
            binary_resolver~,
            string_output=string(input, "mode", "") == "multi-raw",
          )
          .map((_, value) => Json::string(value)),
        )
      _ =>
        program.evaluate(
          ext_vars~,
          ext_code~,
          ext_programs~,
          tla_vars~,
          tla_code~,
          tla_programs~,
          native_functions~,
          trace~,
          resolver~,
          binary_resolver~,
        )
    }
  } catch {
    @moonjsonnet.Error(d) => {
      error = d.format()
      Json::null()
    }
    e => {
      error = e.to_string()
      Json::null()
    }
  }
  {
    "result": result,
    "error": error,
    "requests": requests,
    "trace": traces.to_string(),
    "native_calls": calls,
  }
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
