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
    String(s) => s
    _ => fallback
  }
}

///|
fn run(input : Json) -> Json raise {
  let evaluator = @moonjsonnet.Evaluator::new()
  let results : Array[Json] = []
  let diagnostics : Array[Json] = []
  let traces : Array[Json] = []
  let imported : Map[String, @moonjsonnet.Program] = Map([])
  let mut calls = 0
  let mut reads = 0
  let mut files = field(input, "files", Json::object(Map([])))
  let contents : Map[String, String] = Map([])
  let resolver : (String, String) -> @moonjsonnet.Source raise = (_, path) => {
    if contents.get(path) is Some(source) {
      return { id: path, text: source, }
    }
    reads += 1
    guard field(files, path, Json::null()) is String(source) else {
      fail("missing import: " + path)
    }
    contents[path] = source
    { id: path, text: source, }
  }
  evaluator.set_importer(resolver~)
  evaluator.set_trace(fn(_, message) {
    traces.push(Json::string("0:" + message))
  })
  guard field(input, "steps", Json::null()) is Array(steps) else {
    fail("missing steps")
  }
  for step in steps {
    let name = text(step, "name", "x")
    match text(step, "op", "") {
      "ext_var" => evaluator.ext_var(name, field(step, "value", Json::null()))
      "ext_code" => evaluator.ext_code(name, text(step, "source", ""))
      "ext_program" =>
        evaluator.ext_program(
          name,
          @moonjsonnet.Program::parse(
            text(step, "source", ""),
            filename="parameter",
          ),
        )
      "ext_reset" => evaluator.ext_reset()
      "tla_var" => evaluator.tla_var(name, field(step, "value", Json::null()))
      "tla_code" => evaluator.tla_code(name, text(step, "source", ""))
      "tla_program" =>
        evaluator.tla_program(
          name,
          @moonjsonnet.Program::parse(
            text(step, "source", ""),
            filename="parameter",
          ),
        )
      "tla_reset" => evaluator.tla_reset()
      "files" => files = field(step, "value", Json::null())
      "importer" => {
        contents.clear()
        evaluator.set_importer(resolver~)
      }
      "trace" => {
        let label = text(step, "label", "0")
        evaluator.set_trace(fn(_, message) {
          traces.push(Json::string(label + ":" + message))
        })
      }
      "native" => {
        let value = field(step, "value", 42)
        let increment = field(step, "increment", Json::boolean(false)) ==
          Json::boolean(true)
        evaluator.native_function("tick", {
          params: [],
          callback: fn(_) {
            calls += 1
            if increment {
              Json::number(calls.to_double())
            } else {
              value
            }
          },
        })
      }
      "string_output" =>
        evaluator.set_string_output(
          field(step, "value", Json::boolean(false)) == Json::boolean(true),
        )
      "resolve" | "data" | "program" | "ast" | "dependencies" => {
        let mut error = ""
        let value = try {
          let from = text(step, "from", "entry")
          let path = text(step, "path", "main")
          match text(step, "op", "") {
            "resolve" => Json::string(evaluator.resolve_import(from, path))
            "data" => {
              let source = evaluator.import_data(from, path)
              {
                "id": source.id,
                "bytes": Json::array(
                  source.bytes
                  .iter()
                  .map(b => Json::number(b.to_int().to_double()))
                  .collect(),
                ),
              }
            }
            "program" => {
              let (program, id) = evaluator.import_program(from, path)
              imported[name] = program
              { "id": id, "nil": false }
            }
            "ast" => {
              let (program, id) = evaluator.import_ast(from, path)
              if program is Some(program) {
                imported[name] = program
              } else {
                ignore(imported.remove(name))
              }
              { "id": id, "nil": program is None }
            }
            _ => {
              let paths = match field(step, "paths", Json::null()) {
                Array(paths) =>
                  paths.map(value => {
                    match value {
                      String(s) => s
                      _ => ""
                    }
                  })
                _ => []
              }
              Json::array(
                evaluator.find_dependencies(from, paths).map(Json::string),
              )
            }
          }
        } catch {
          @moonjsonnet.Error(d) => {
            error = d.format()
            Json::null()
          }
        }
        diagnostics.push(Json::string(error))
        results.push({
          "value": value,
          "error": !error.is_empty(),
          "calls": calls,
          "reads": reads,
          "trace": Json::array(traces.copy()),
        })
      }
      "evaluate" | "evaluate_imported" => {
        let mut error = ""
        let value = try {
          let program = if text(step, "op", "") == "evaluate_imported" {
            imported[name]
          } else {
            @moonjsonnet.Program::parse(
              text(step, "source", ""),
              filename="entry",
            )
          }
          match text(step, "mode", "json") {
            "text" => Json::string(evaluator.evaluate_text(program))
            "stream" =>
              Json::array(evaluator.evaluate_stream(program).map(Json::string))
            "multi" =>
              Json::object(
                evaluator.evaluate_multi(program).map((_, v) => Json::string(v)),
              )
            _ => evaluator.evaluate(program)
          }
        } catch {
          @moonjsonnet.Error(d) => {
            error = d.format()
            Json::null()
          }
        }
        diagnostics.push(Json::string(error))
        results.push({
          "value": value,
          "error": !error.is_empty(),
          "calls": calls,
          "reads": reads,
          "trace": Json::array(traces.copy()),
        })
      }
      _ => fail("unknown action")
    }
  }
  {
    "result": results,
    "diagnostics": diagnostics,
    "error": "",
    "requests": [],
    "trace": "",
    "native_calls": 0,
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
      fail("cannot write output")
    }
  } catch {
    e => {
      @posix.stderr(e.to_string())
      @posix.exit(2)
    }
  }
}
