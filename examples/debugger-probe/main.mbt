///|
fn field(input : Json, key : String, fallback : Json) -> Json {
  match input {
    Object(fields) => fields.get(key).unwrap_or(fallback)
    _ => fallback
  }
}

///|
fn integer(input : Json, key : String, fallback : Int) -> Int {
  match field(input, key, null) {
    Number(n, ..) => n.to_int()
    _ => fallback
  }
}

///|
fn run(input : Json) -> Json raise {
  guard input is { "source": String(source), .. } else {
    fail("debugger input")
  }
  let program = @moonjsonnet.Program::parse(source, filename="entry")
  let debugger = @moonjsonnet.Debugger::new()
  let breakpoint = debugger.set_breakpoint(
    program,
    integer(input, "line", 1),
    column=integer(input, "column", 1),
  ) catch {
    _ => ""
  }
  let stops : Array[Json] = []
  let diagnostics : Array[String] = []
  let mut command_index = 0
  let mut failed = false
  let output = debugger.run(program, on_stop=stop => {
    if stops.length() >= 100 {
      fail("too many debugger stops")
    }
    let range = stop.context
      .source_range()
      .unwrap_or({
        begin: { file: "", line: 0, column: 0, },
        end: { file: "", line: 0, column: 0, },
      })
    let values : Map[String, Json] = Map([])
    if field(input, "lookups", []) is Array(names) {
      for name in names {
        guard name is String(name) else { fail("lookup name") }
        values[name] = stop.context.lookup(name).json() catch {
            _ => { "error": true }
          }
      }
    }
    if stop.outcome is Some(Failure(d)) {
      diagnostics.push(d.format())
    }
    stops.push({
      "reason": match stop.reason {
        Step => "step"
        Breakpoint => "breakpoint"
        Exception => "exception"
      },
      "range": [
        range.begin.line,
        range.begin.column,
        range.end.line,
        range.end.column,
      ],
      "variables": stop.context.variables(),
      "values": Json::object(values),
    })
    let command = if field(input, "commands", []) is Array(commands) {
      commands.get(command_index).unwrap_or(Json::string("continue"))
    } else {
      Json::string("continue")
    }
    command_index += 1
    match command {
      String("step") => Step
      String("finish") => Finish
      String("terminate") => Terminate
      _ => Continue
    }
  }) catch {
    @moonjsonnet.Error(d) => {
      failed = true
      diagnostics.push(d.format())
      ""
    }
  }
  let active = debugger.active_breakpoints().map(_ => true)
  debugger.clear_breakpoints("entry")
  let result : Map[String, Json] = Map([
    ("output", Json::string(output)),
    ("error", Json::boolean(failed)),
    ("stops", Json::array(stops)),
    ("set", Json::boolean(!breakpoint.is_empty())),
    ("active", Json::number(active.length().to_double())),
    (
      "cleared",
      Json::number(debugger.active_breakpoints().length().to_double()),
    ),
  ])
  if field(input, "locations", false) == Json::boolean(true) {
    result["locations"] = Json::array(
      @moonjsonnet.Debugger::breakpoint_locations(program).map(range => {
        Json::array([
          Json::number(range.begin.line.to_double()),
          Json::number(range.begin.column.to_double()),
          Json::number(range.end.line.to_double()),
          Json::number(range.end.column.to_double()),
        ])
      }),
    )
  }
  { "result": Json::object(result), "diagnostics": diagnostics }
}

///|
fn main {
  try {
    let (status, bytes) = @posix.read_stdin(1048576)
    guard status == 0 else { fail("debugger input read") }
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
