///|
fn main {
  run(@env.args()) catch {
    @moonjsonnet.Error(d) => {
      @posix.stderr(d.format() + "\n")
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
    match arg {
      "--help" | "-h" => {
        println(
          "Usage: moonjsonnet-lint [-J/--jpath DIR] [--root DIR] [--] FILE...\nChecks syntax, imports, unused locals, eager cycles and inferred types without execution.\nJSONNET_PATH is supported. Diagnostic range parity remains incomplete.\nExit: 0 no findings; 1 input/resource failure; 2 findings.",
        )
        return
      }
      "--version" | "-v" => {
        println("moonjsonnet-lint 0.1.0 (Jsonnet v0.21.0 subset)")
        return
      }
      "-J" | "--jpath" | "--root" => {
        guard i < args.length() else { fail("missing value for " + arg) }
        let value = args[i]
        i += 1
        guard !value.is_empty() else { fail("empty value for " + arg) }
        if arg == "--root" {
          root = value
        } else {
          jpaths.push(value)
        }
      }
      _ => fail("unknown option: " + arg)
    }
  }
  guard !paths.is_empty() else { fail("missing input; use --help") }
  let host = @fs.FileHost::new(root, jpaths~)
  let sources = paths.map(path => host.load(path))
  let issues = @moonjsonnet.lint(sources, resolver=(from, path) => {
    host.resolve_binary(from, path)
  })
  for d in issues {
    @posix.stderr(d.format() + "\n")
  }
  if !issues.is_empty() {
    @posix.stderr("Problems found!\n")
    @posix.exit(2)
  }
}
