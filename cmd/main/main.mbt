///|
fn run(args : Array[String]) -> Unit raise {
  let args = simplify_args(args)
  let inputs : Array[String] = []
  let mut output : String? = None
  let mut root = "."
  let mut exec = false
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
        "Usage: moonjsonnet [-e/--exec] [--root DIR] [-V/--ext-str NAME[=VALUE]] [--ext-code NAME[=CODE]] [-A/--tla-str NAME[=VALUE]] [--tla-code NAME[=CODE]] [--ext-str-file/--ext-code-file/--tla-str-file/--tla-code-file NAME=FILE] [-o/--output-file FILE] [--max-steps N] [--max-depth N] [--max-source-bytes N] [--max-import-bytes N] [--max-imports N] [--max-output-bytes N] [--] INPUT\nINPUT is a file, - for stdin, or code with -e. Combined short options expand before --.",
      )
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
    if arg.has_prefix("-") {
      guard i + 1 < args.length() else { fail("missing value for \{arg}") }
      i += 1
      let value = args[i]
      match arg {
        "--root" => root = value
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
  let host = @fs.FileHost::new(root, max_bytes=limits.source_bytes)
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
      })
    }
    let text = @utf8.decode(bytes) catch {
      _ =>
        raise @moonjsonnet.Error({
          kind: @moonjsonnet.Import,
          message: "stdin is not valid UTF-8",
          location: { file: "<stdin>", line: 1, column: 1, },
          context: [],
        })
    }
    { id: "<stdin>", text, }
  } else {
    host.resolve("", path)
  }
  let result = @moonjsonnet.evaluate(
    source.text,
    filename=source.id,
    anonymous~,
    ext_vars=ext,
    ext_code~,
    tla_vars=tla,
    tla_code~,
    limits~,
    resolver=(from, path) => host.resolve(from, path),
    binary_resolver=(from, path) => host.resolve_binary(from, path),
  ).stringify()
  match output {
    None => println(result)
    Some(path) =>
      if !@posix.write(path, result + "\n") {
        fail("cannot write output: \{path}")
      }
  }
}

///|
fn main {
  run(@env.args()) catch {
    @moonjsonnet.Error(d) => {
      @posix.stderr(d.to_string())
      @posix.exit(1)
    }
    e => {
      @posix.stderr("moonjsonnet: \{e}")
      @posix.exit(1)
    }
  }
}
