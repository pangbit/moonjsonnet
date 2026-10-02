///|
fn run(args : Array[String]) -> Unit raise {
  let mut input : String? = None
  let mut output : String? = None
  let mut root = "."
  let ext : Map[String, Json] = Map([])
  let mut limits = @moonjsonnet.Limits::default()
  let mut i = 1
  while i < args.length() {
    let arg = args[i]
    if arg == "--help" || arg == "-h" {
      println(
        "Usage: moonjsonnet [--root DIR] [--ext-str NAME=VALUE] [--ext-code NAME=JSON] [-o FILE] [--max-steps N] [--max-depth N] [--max-source-bytes N] [--max-import-bytes N] [--max-imports N] [--max-output-bytes N] INPUT",
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
        "--ext-str" | "--ext-code" => {
          guard value.find("=") is Some(eq) else { fail("expected NAME=VALUE") }
          let name = value[:eq].to_owned()
          let v = value[eq + 1:].to_owned()
          if name.is_empty() {
            fail("external variable name must not be empty")
          }
          ext[name] = if arg == "--ext-str" {
            Json::string(v)
          } else {
            @json.parse(v)
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
  let result = @fs.evaluate_file(path, root~, ext_vars=ext, limits~).stringify()
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
