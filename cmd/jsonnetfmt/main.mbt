// Portions adapted from google/go-jsonnet v0.21.0 (Apache-2.0).
// https://github.com/google/go-jsonnet/tree/67968688d9952f50662e979fab1bef889d0d3e57
// Source: cmd/jsonnetfmt/cmd.go
// Copyright 2019 Google Inc. All rights reserved.
// Modifications: Ported CLI option ordering and file-mode flow to the bounded POSIX MoonBit host.
// License and retained attribution: LICENSE and NOTICE at the module root.

///|
fn version() -> String {
  "moonjsonnet reformatter 0.1.0 (Jsonnet v0.21.0 subset)\n"
}

///|
fn stderr(message : String) -> Unit {
  @posix.stderr(
    if message.has_suffix("\n") {
      message[:message.length() - 1].to_owned()
    } else {
      message
    },
  )
}

///|
fn usage() -> String {
  version() +
  "\njsonnetfmt {<option>} { <filename> }\n\n" +
  "  -h / --help                This message\n" +
  "  -e / --exec                Treat filename as code\n" +
  "  -o / --output-file FILE    Write to file, creating parent directories\n" +
  "  -c / --create-output-dirs  Accepted for Go CLI compatibility\n" +
  "  -i / --in-place            Update files in place\n" +
  "  --test                    Exit 2 when formatting would change a file\n" +
  "  -n / --indent N           Spaces per level (default 2, 0 preserves)\n" +
  "  --max-blank-lines N       Vertical spacing (default 2, 0 preserves)\n" +
  "  --string-style d|s|l      Double, single, or leave quotes\n" +
  "  --comment-style h|s|l     Hash, slash, or leave comments\n" +
  "  --[no-]pretty-field-names\n  --[no-]pad-arrays\n" +
  "  --[no-]pad-objects\n  --[no-]sort-imports\n  --[no-]use-implicit-plus\n" +
  "  --root DIR                Confine input files (default current directory)\n" +
  "  -v / --version            Print version\n\n" +
  "Use - for stdin, -- to stop option processing; short groups are expanded.\n"
}

///|
fn output_parent(path : String) -> String {
  let parent = match path.rev_find("/") {
    Some(i) => path[:i].to_owned()
    None => "."
  }
  let absolute = path.has_prefix("/")
  let parts : Array[String] = []
  for part in parent.split("/") {
    match part.to_owned() {
      "" | "." => ()
      ".." =>
        if parts.last() is Some(last) && last != ".." {
          ignore(parts.pop())
        } else if !absolute {
          parts.push("..")
        }
      part => parts.push(part)
    }
  }
  if absolute {
    "/" + parts.join("/")
  } else if parts.is_empty() {
    "."
  } else {
    parts.join("/")
  }
}

///|
fn write_output(
  text : String,
  path : String?,
  create_dirs : Bool,
) -> Unit raise CliError {
  match path {
    None =>
      if !@posix.stdout(text) {
        raise Message("ERROR: cannot write stdout\n")
      }
    Some(path) => {
      if create_dirs && !@posix.mkdir_all(output_parent(path)) {
        raise Message("ERROR: cannot create output directories: " + path + "\n")
      }
      if !@posix.write(path, text) {
        raise Message("ERROR: cannot write output: " + path + "\n")
      }
    }
  }
}

///|
fn read_input(path : String, config : Config) -> (String, String) raise {
  if config.exec {
    return (path, "<cmdline>")
  }
  if path == "-" {
    let (status, bytes) = @posix.read_stdin(
      @moonjsonnet.SyntaxLimits::default().source_bytes,
    )
    if status == 3 {
      raise Message("ERROR: stdin source byte limit exceeded\n")
    }
    if status != 0 {
      raise Message("ERROR: cannot read stdin\n")
    }
    let source = @utf8.decode(bytes) catch {
      _ => raise Message("ERROR: invalid UTF-8 in stdin\n")
    }
    return (source, "<stdin>")
  }
  (@fs.FileHost::new(config.root).load(path).text, path)
}

///|
fn run(config : Config) -> Unit raise {
  for path in config.paths {
    if config.in_place {
      if path == "-" {
        raise Message("ERROR: cannot use --in-place with stdin\n")
      }
      if config.exec {
        raise Message("ERROR: cannot use --in-place with --exec\n")
      }
    }
    let (source, filename) = read_input(path, config)
    let output = @moonjsonnet.format_syntax_source(
      source,
      filename~,
      options=config.options,
    ) catch {
      @moonjsonnet.Error(d) =>
        raise SyntaxMessage(d.format_syntax_bytes(source))
    }
    if config.in_place || config.test_only {
      if output != source {
        if config.in_place {
          // Resolve again before writing so --root works from another cwd.
          let identity = @fs.FileHost::new(config.root).load(path).id
          write_output(output, Some(identity), false)
        } else {
          @posix.exit(2)
          return
        }
      }
    } else {
      write_output(output, config.output, true)
    }
  }
}

///|
fn main {
  try {
    match parse_args(@env.args()[1:].to_owned()) {
      Help => ignore(@posix.stdout(usage()))
      Version => ignore(@posix.stdout(version()))
      UsageFailure(message) => {
        stderr("ERROR: " + message + "\n\n" + usage())
        @posix.exit(1)
      }
      Run(config) => run(config)
    }
  } catch {
    SyntaxMessage(message) => {
      @posix.stderr_bytes(message)
      @posix.exit(1)
    }
    Message(message) => {
      stderr(message)
      @posix.exit(1)
    }
    @moonjsonnet.Error(d) => {
      @posix.stderr(d.format_syntax(""))
      @posix.exit(1)
    }
    e => {
      @posix.stderr("ERROR: " + e.to_string())
      @posix.exit(1)
    }
  }
}
