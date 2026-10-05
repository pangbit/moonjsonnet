///|
fn main {
  run(@env.args()) catch {
    @moonjsonnet.Error(d) => {
      @posix.stderr(d.format(max_trace=20) + "\n")
      @posix.exit(1)
    }
    e => {
      @posix.stderr("ERROR: " + e.to_string() + "\n")
      @posix.exit(1)
    }
  }
}

///|
fn run(given : Array[String]) -> Unit raise {
  // Match Go's byte-wise short option expansion before the first delimiter.
  let args = []
  let mut options = true
  for arg in given[1:] {
    if arg == "--" {
      options = false
    }
    let bytes = @utf8.encode(arg)
    if options && bytes.length() > 2 && bytes[0] == 45 && bytes[1] != 45 {
      for byte in bytes[1:] {
        args.push("-" + byte.to_int().to_char().unwrap().to_string())
      }
    } else {
      args.push(arg)
    }
  }
  let paths = []
  let jpaths = []
  if @env.get_env_var("JSONNET_PATH") is Some(value) && !value.is_empty() {
    let parts = value.split(":").map(s => s.to_owned()).collect()
    for i = parts.length() - 1; i >= 0; i = i - 1 {
      jpaths.push(parts[i])
    }
  }
  let mut root = "."
  let mut output : String? = None
  options = true
  let mut i = 0
  while i < args.length() {
    let arg = args[i]
    i += 1
    if options && arg == "--" {
      options = false
      continue
    }
    if !options || arg == "-" || !arg.has_prefix("-") {
      paths.push(arg)
      continue
    }
    if arg == "--help" || arg == "-h" {
      println(
        "Usage: moonjsonnet-deps [-J/--jpath DIR] [-o/--output-file FILE] [--root DIR] [--] FILE...\nList sorted transitive import dependencies without evaluation. Entry files are excluded. JSONNET_PATH is supported; reads remain confined to --root.",
      )
      return
    }
    if arg == "--version" || arg == "-v" {
      println("moonjsonnet-deps 0.1.0 (Jsonnet v0.21.0 subset)")
      return
    }
    if arg != "-J" &&
      arg != "--jpath" &&
      arg != "-o" &&
      arg != "--output-file" &&
      arg != "--root" {
      fail("unknown option: " + arg)
    }
    guard i < args.length() else { fail("missing value for " + arg) }
    let value = args[i]
    i += 1
    if value.is_empty() {
      fail("empty value for " + arg)
    }
    match arg {
      "-J" | "--jpath" => jpaths.push(value)
      "--root" => root = value
      _ => output = Some(value)
    }
  }
  if paths.is_empty() {
    fail("missing input; use --help")
  }
  let host = @fs.FileHost::new(root, jpaths~)
  // Go's tool checks the entry paths before using the importer. Match its
  // no-library-fallback entry rule, without decoding arbitrary raw bytes here.
  let entries = @fs.FileHost::new(root)
  for path in paths {
    ignore(entries.resolve_binary("", path))
  }
  let dependencies = host.find_dependencies(paths)
  let text = if dependencies.is_empty() {
    ""
  } else {
    dependencies.join("\n") + "\n"
  }
  let ok = match output {
    Some(path) => @posix.write(path, text)
    None => @posix.stdout(text)
  }
  if !ok {
    fail("cannot write dependency output")
  }
}
