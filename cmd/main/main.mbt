///|
priv struct CliDiagnostics {
  mut max_trace : Int32
  formatter : @moonjsonnet.DiagnosticFormatter
  mut entry_name : (String, String)?
  trace_names : Map[String, String]
}

///|
fn run(args : Array[String], diagnostics : CliDiagnostics) -> Unit raise {
  let args = simplify_args(args)
  let inputs : Array[String] = []
  let jpaths : Array[String] = []
  if @env.get_env_var("JSONNET_PATH") is Some(value) && !value.is_empty() {
    let paths = value.split(":").map(s => s.to_owned()).collect()
    for i = paths.length() - 1; i >= 0; i = i - 1 {
      jpaths.push(paths[i])
    }
  }
  let mut output : String? = None
  let mut root = "."
  let mut exec = false
  let mut string_output = false
  let mut stream = false
  let mut multi : String? = None
  let mut create_dirs = false
  let mut options = true
  let ext : Map[String, Json] = Map([])
  let ext_code : Map[String, String] = Map([])
  let tla : Map[String, Json] = Map([])
  let tla_code : Map[String, String] = Map([])
  let mut limits = @moonjsonnet.Limits::default()
  let mut i = 1
  while i < args.length() {
    let arg = args[i]
    if options && arg == "--" {
      options = false
      i += 1
      continue
    }
    if !options || arg == "-" || !arg.has_prefix("-") {
      inputs.push(arg)
      i += 1
      continue
    }
    if arg == "--help" || arg == "-h" {
      ignore(@posix.stdout(cli_usage()))
      return
    }
    if arg == "--version" || arg == "-v" {
      println("moonjsonnet 0.2.2 (Jsonnet v0.21.0 subset)")
      return
    }
    if arg == "-e" || arg == "--exec" {
      exec = true
      i += 1
      continue
    }
    if arg == "-S" || arg == "--string" {
      string_output = true
      i += 1
      continue
    }
    if arg == "-y" || arg == "--yaml-stream" {
      stream = true
      i += 1
      continue
    }
    if arg == "-c" || arg == "--create-output-dirs" {
      create_dirs = true
      i += 1
      continue
    }
    if arg.has_prefix("-") {
      match arg {
        "--root"
        | "-t"
        | "--max-trace"
        | "-s"
        | "--max-stack"
        | "-J"
        | "--jpath"
        | "-m"
        | "--multi"
        | "-o"
        | "--output"
        | "--output-file"
        | "-V"
        | "--ext-str"
        | "--ext-code"
        | "--ext-str-file"
        | "--ext-code-file"
        | "-A"
        | "--tla-str"
        | "--tla-code"
        | "--tla-str-file"
        | "--tla-code-file"
        | "--max-steps"
        | "--max-depth"
        | "--max-source-bytes"
        | "--max-import-bytes"
        | "--max-imports"
        | "--max-output-bytes" => ()
        _ => raise Message("ERROR: unrecognized argument: " + arg + "\n")
      }
      guard i + 1 < args.length() else {
        raise Message("Expected another commandline argument.\n")
      }
      i += 1
      let value = args[i]
      match arg {
        "--root" => root = value
        "-t" | "--max-trace" => diagnostics.max_trace = trace_limit(value)
        "-s" | "--max-stack" =>
          limits = { ..limits, stack: decimal_limit(value, "--max-stack", 1), }
        "-J" | "--jpath" => {
          if value.is_empty() {
            raise Message("ERROR: -J argument was empty string\n")
          }
          jpaths.push(value)
        }
        "-m" | "--multi" => {
          if value.is_empty() {
            raise Message("ERROR: -m argument was empty string\n")
          }
          multi = Some(if value.has_suffix("/") { value } else { value + "/" })
        }
        "-o" | "--output" | "--output-file" => {
          if value.is_empty() {
            raise Message("ERROR: -o argument was empty string\n")
          }
          output = Some(value)
        }
        "-V"
        | "--ext-str"
        | "--ext-code"
        | "--ext-str-file"
        | "--ext-code-file"
        | "-A"
        | "--tla-str"
        | "--tla-code"
        | "--tla-str-file"
        | "--tla-code-file" => {
          let is_file = arg.has_suffix("-file")
          let (name, v) = match value.find("=") {
            Some(eq) => (value[:eq].to_owned(), value[eq + 1:].to_owned())
            None => {
              if is_file {
                raise Message(
                  "ERROR: argument not in form <var>=<file> \"" + value + "\"\n",
                )
              }
              guard @env.get_env_var(value) is Some(v) else {
                raise Message(
                  "ERROR: environment variable " + value + " was undefined\n",
                )
              }
              (value, v)
            }
          }
          let is_string = arg == "-V" || arg == "-A" || arg.contains("-str")
          let values = if arg == "-A" || arg.has_prefix("--tla-") {
            tla
          } else {
            ext
          }
          let codes = if arg == "-A" || arg.has_prefix("--tla-") {
            tla_code
          } else {
            ext_code
          }
          if is_file {
            ignore(values.remove(name))
            let mode = if is_string { "importstr" } else { "import" }
            codes[name] = mode + " @'" + v.replace_all(old="'", new="''") + "'"
          } else if is_string {
            ignore(codes.remove(name))
            values[name] = Json::string(v)
          } else {
            ignore(values.remove(name))
            codes[name] = v
          }
        }
        "--max-steps" => limits = { ..limits, steps: @string.parse_int(value), }
        "--max-depth" => limits = { ..limits, depth: @string.parse_int(value), }
        "--max-source-bytes" =>
          limits = { ..limits, source_bytes: @string.parse_int(value), }
        "--max-import-bytes" =>
          limits = { ..limits, import_bytes: @string.parse_int(value), }
        "--max-imports" =>
          limits = { ..limits, imports: @string.parse_int(value), }
        "--max-output-bytes" =>
          limits = { ..limits, output_bytes: @string.parse_int(value), }
        _ => raise Message("ERROR: unrecognized argument: " + arg + "\n")
      }
    }
    i += 1
  }
  let want = if exec { "code" } else { "filename" }
  if inputs.is_empty() {
    raise UsageFailure("must give " + want)
  }
  if inputs.length() != 1 {
    raise Message("ERROR: only one " + want + " is allowed\n")
  }
  let path = inputs[0]
  let host = @fs.FileHost::new(root, jpaths~, max_bytes=limits.source_bytes)
  let anonymous = exec || path == "-"
  let source : @moonjsonnet.Source = if exec {
    { id: "<cmdline>", text: path, }
  } else if path == "-" {
    let (status, bytes) = @posix.read_stdin(limits.source_bytes)
    if status != 0 {
      if status == 1 && @posix.io_error("<stdin>", input=true) is Some(message) {
        raise Message(message + "\n")
      }
      raise @moonjsonnet.Error({
        kind: if status == 3 || status == 2 {
          @moonjsonnet.Limit
        } else {
          @moonjsonnet.Import
        },
        message: "cannot read stdin within source byte limit",
        location: { file: "<stdin>", line: 1, column: 1, },
        context: [],
        trace: [],
      })
    }
    let text = @utf8.decode(bytes) catch {
      _ =>
        raise @moonjsonnet.Error({
          kind: @moonjsonnet.Import,
          message: "stdin is not valid UTF-8",
          location: { file: "<stdin>", line: 1, column: 1, },
          context: [],
          trace: [],
        })
    }
    { id: "<stdin>", text, }
  } else {
    load_input(host, path)
  }
  diagnostics.formatter.set_source(source)
  if !anonymous {
    // Keep the entry's existing identity and record its invocation path for
    // diagnostics and import lookup. Pinned Go cleans only relative spellings.
    let display = if path.has_prefix("/") {
      path
    } else {
      output_parent(path + "/x")
    }
    diagnostics.entry_name = Some((source.id, display))
    diagnostics.trace_names[source.id] = display
    diagnostics.formatter.set_source({ id: display, text: source.text, })
  }
  for name, text in ext_code {
    diagnostics.formatter.set_source({ id: "<extvar:" + name + ">", text, })
  }
  for name, text in tla_code {
    diagnostics.formatter.set_source({
      id: "<top-level-arg:" + name + ">",
      text,
    })
  }
  let resolver = fn(from : String, path : String) raise {
    @posix.clear_io_error()
    let source = host.resolve(
      import_origin(host, from, diagnostics.trace_names),
      path,
    ) catch {
      @moonjsonnet.Error(d) => raise import_failure(d, from, path, jpaths)
    }
    let id = import_trace_name(
      host,
      from,
      path,
      source.id,
      diagnostics.trace_names,
      jpaths,
    )
    let source = { ..source, id, }
    diagnostics.formatter.set_source(source)
    source
  }
  let binary_resolver = fn(from : String, path : String) raise {
    @posix.clear_io_error()
    let source = host.resolve_binary(
      import_origin(host, from, diagnostics.trace_names),
      path,
    ) catch {
      @moonjsonnet.Error(d) => raise import_failure(d, from, path, jpaths)
    }
    let id = import_trace_name(
      host,
      from,
      path,
      source.id,
      diagnostics.trace_names,
      jpaths,
    )
    { ..source, id, }
  }
  let trace = fn(location, message) {
    @posix.stderr(source_trace(location, message, diagnostics.trace_names))
  }
  if multi is Some(directory) {
    let files = @moonjsonnet.evaluate_multi(
      source.text,
      string_output~,
      filename=source.id,
      anonymous~,
      ext_vars=ext,
      ext_code~,
      tla_vars=tla,
      tla_code~,
      trace~,
      limits~,
      resolver~,
      binary_resolver~,
    )
    write_multi(files, directory, output, create_dirs, limits.output_bytes, {
      file: source.id,
      line: 1,
      column: 1,
    })
    return
  }
  let result = if stream {
    let documents = @moonjsonnet.evaluate_stream(
      source.text,
      filename=source.id,
      anonymous~,
      ext_vars=ext,
      ext_code~,
      tla_vars=tla,
      tla_code~,
      trace~,
      limits~,
      resolver~,
      binary_resolver~,
    )
    let output = StringBuilder()
    let mut bytes = 0
    let write = fn(text : String) raise {
      let size = @utf8.encode(text).length()
      if size > limits.output_bytes - bytes {
        raise @moonjsonnet.Error({
          kind: @moonjsonnet.Limit,
          message: "stream output byte limit exceeded",
          location: { file: source.id, line: 1, column: 1, },
          context: [],
          trace: [],
        })
      }
      bytes += size
      output.write_string(text)
    }
    for document in documents {
      write("---\n")
      write(document)
    }
    if !documents.is_empty() {
      write("...\n")
    }
    output.to_string()
  } else {
    @moonjsonnet.evaluate_text(
      source.text,
      string_output~,
      filename=source.id,
      anonymous~,
      ext_vars=ext,
      ext_code~,
      tla_vars=tla,
      tla_code~,
      trace~,
      limits~,
      resolver~,
      binary_resolver~,
    )
  }
  match output {
    None =>
      if !@posix.stdout(result) {
        io_failure("/dev/stdout", "cannot write stdout")
      }
    Some(path) => {
      if create_dirs && !stream && !@posix.mkdir_all(output_parent(path)) {
        io_failure(
          output_parent(path),
          "cannot create output directories: " + path,
        )
      }
      if !@posix.write(path, result) {
        io_failure(path, "cannot write output: " + path)
      }
    }
  }
}

///|
fn main {
  let diagnostics : CliDiagnostics = {
    max_trace: 20,
    formatter: @moonjsonnet.DiagnosticFormatter::new(),
    entry_name: None,
    trace_names: Map([]),
  }
  if @posix.stdout_is_terminal() &&
    @env.get_env_var("TERM").unwrap_or("") != "dumb" &&
    @env.get_env_var("NO_COLOR").unwrap_or("").is_empty() {
    diagnostics.formatter.set_color(color=fragment => {
      "\u001b[31m" + fragment + "\u001b[0m"
    })
  }
  run(@env.args(), diagnostics) catch {
    Message(message) => {
      ignore(@posix.write_output(2, message))
      @posix.exit(1)
    }
    UsageFailure(message) => {
      ignore(@posix.write_output(2, "ERROR: " + message + "\n\n" + cli_usage()))
      @posix.exit(1)
    }
    @moonjsonnet.Error(d) => {
      let d = entry_diagnostic(d, diagnostics.entry_name)
      if (d.kind == @moonjsonnet.Import || d.kind == @moonjsonnet.Limit) &&
        d.message != "max stack frames exceeded." {
        @posix.stderr(d.format(max_trace=diagnostics.max_trace))
      } else {
        diagnostics.formatter.set_max_trace(diagnostics.max_trace)
        @posix.stderr_bytes(diagnostics.formatter.format_bytes(d))
      }
      @posix.exit(1)
    }
    e => {
      @posix.stderr("moonjsonnet: \{e}")
      @posix.exit(1)
    }
  }
}
