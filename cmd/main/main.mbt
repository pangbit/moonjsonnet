///|
priv struct CliDiagnostics {
  mut max_trace : Int
  formatter : @moonjsonnet.DiagnosticFormatter
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
      println(
        "Usage: moonjsonnet [-e/--exec] [-S/--string] [-y/--yaml-stream] [-m/--multi DIR] [-c/--create-output-dirs] [--root DIR] [-V/--ext-str NAME[=VALUE]] [--ext-code NAME[=CODE]] [-A/--tla-str NAME[=VALUE]] [--tla-code NAME[=CODE]] [--ext-str-file/--ext-code-file/--tla-str-file/--tla-code-file NAME=FILE] [-o/--output-file FILE] [--max-steps N] [--max-depth N] [--max-source-bytes N] [--max-import-bytes N] [--max-imports N] [--max-output-bytes N] [--] INPUT\nINPUT is a file, - for stdin, or code with -e. Combined short options expand before --.",
      )
      println(
        "-J/--jpath DIR adds a library path (rightmost wins). JSONNET_PATH adds colon-separated paths (leftmost wins), below -J. All imports remain confined to --root.",
      )
      println(
        "-t/--max-trace N crops error context (default 20; 0 is unlimited).",
      )
      println("-s/--max-stack N limits runtime frames (default 500; positive).")
      return
    }
    if arg == "--version" || arg == "-v" {
      println("moonjsonnet 0.1.0 (Jsonnet v0.21.0 subset)")
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
      guard i + 1 < args.length() else { fail("missing value for \{arg}") }
      i += 1
      let value = args[i]
      match arg {
        "--root" => root = value
        "-t" | "--max-trace" => diagnostics.max_trace = trace_limit(value)
        "-s" | "--max-stack" =>
          limits = { ..limits, stack: decimal_limit(value, "--max-stack", 1), }
        "-J" | "--jpath" => {
          if value.is_empty() {
            fail("jpath must not be empty")
          }
          jpaths.push(value)
        }
        "-m" | "--multi" => {
          if value.is_empty() {
            fail("multi directory must not be empty")
          }
          multi = Some(if value.has_suffix("/") { value } else { value + "/" })
        }
        "-o" | "--output" | "--output-file" => {
          if value.is_empty() {
            fail("output filename must not be empty")
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
                fail("expected NAME=FILE")
              }
              guard @env.get_env_var(value) is Some(v) else {
                fail("environment variable \{value} was undefined")
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
        _ => fail("unknown option: \{arg}")
      }
    }
    i += 1
  }
  if inputs.is_empty() {
    fail("missing input; use --help")
  }
  if inputs.length() != 1 {
    fail("only one input is supported")
  }
  let path = inputs[0]
  let host = @fs.FileHost::new(root, jpaths~, max_bytes=limits.source_bytes)
  let anonymous = exec || path == "-"
  let source : @moonjsonnet.Source = if exec {
    { id: "<cmdline>", text: path, }
  } else if path == "-" {
    let (status, bytes) = @posix.read_stdin(limits.source_bytes)
    if status != 0 {
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
    host.load(path)
  }
  diagnostics.formatter.set_source(source)
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
    let source = host.resolve(from, path)
    diagnostics.formatter.set_source(source)
    source
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
      limits~,
      resolver~,
      binary_resolver=(from, path) => host.resolve_binary(from, path),
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
      limits~,
      resolver~,
      binary_resolver=(from, path) => host.resolve_binary(from, path),
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
      limits~,
      resolver~,
      binary_resolver=(from, path) => host.resolve_binary(from, path),
    )
  }
  match output {
    None => if !@posix.stdout(result) { fail("cannot write stdout") }
    Some(path) => {
      if create_dirs && !stream && !@posix.mkdir_all(output_parent(path)) {
        fail("cannot create output directories: " + path)
      }
      if !@posix.write(path, result) {
        fail("cannot write output: \{path}")
      }
    }
  }
}

///|
fn main {
  let diagnostics : CliDiagnostics = {
    max_trace: 20,
    formatter: @moonjsonnet.DiagnosticFormatter::new(),
  }
  if @posix.stdout_is_terminal() &&
    @env.get_env_var("TERM").unwrap_or("") != "dumb" &&
    @env.get_env_var("NO_COLOR").unwrap_or("").is_empty() {
    diagnostics.formatter.set_color(color=fragment => {
      "\u001b[31m" + fragment + "\u001b[0m"
    })
  }
  run(@env.args(), diagnostics) catch {
    @moonjsonnet.Error(d) => {
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
