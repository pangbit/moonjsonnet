///|
fn run(args : Array[String]) -> Unit raise {
  let mut input : String? = None
  let mut output : String? = None
  let mut root = "."
  let ext : Map[String, Json] = Map([])
  let ext_code : Map[String, String] = Map([])
  let tla : Map[String, Json] = Map([])
  let tla_code : Map[String, String] = Map([])
  let mut limits = @moonjsonnet.Limits::default()
  let mut i = 1
  while i < args.length() {
    let arg = args[i]
    if arg == "--help" || arg == "-h" {
      println(
        "Usage: moonjsonnet [--root DIR] [-V/--ext-str NAME[=VALUE]] [--ext-code NAME[=CODE]] [-A/--tla-str NAME[=VALUE]] [--tla-code NAME[=CODE]] [--ext-str-file/--ext-code-file/--tla-str-file/--tla-code-file NAME=FILE] [-o FILE] [--max-steps N] [--max-depth N] [--max-source-bytes N] [--max-import-bytes N] [--max-imports N] [--max-output-bytes N] INPUT",
      )
      return
    }
    if arg == "--version" {
      println("moonjsonnet 0.1.0 (Jsonnet v0.21.0 subset)")
      return
    }
    if arg.has_prefix("-") {
      guard i + 1 < args.length() else { fail("missing value for \{arg}") }
      i += 1
      let value = args[i]
      match arg {
        "--root" => root = value
        "-o" | "--output" => output = Some(value)
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
    } else {
      if input is Some(_) {
        fail("only one input file is supported")
      }
      input = Some(arg)
    }
    i += 1
  }
  guard input is Some(path) else { fail("missing input; use --help") }
  let result = @fs.evaluate_file(
    path,
    root~,
    ext_vars=ext,
    ext_code~,
    tla_vars=tla,
    tla_code~,
    limits~,
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
      @posix.exit(2)
    }
  }
}
