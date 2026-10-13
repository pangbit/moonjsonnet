// Portions adapted from google/go-jsonnet v0.21.0 (Apache-2.0).
// https://github.com/google/go-jsonnet/tree/67968688d9952f50662e979fab1bef889d0d3e57
// Source: cmd/jsonnetfmt/cmd.go
// Copyright 2019 Google Inc. All rights reserved.
// Modifications: Ported CLI option ordering and file-mode flow to the bounded POSIX MoonBit host.
// License and retained attribution: LICENSE and NOTICE at the module root.

// CLI option order and file behavior follow fixed go-jsonnet v0.21.0.
// Copyright Google Inc.; Apache-2.0; see NOTICE.

///|
priv struct Config {
  paths : Array[String]
  output : String?
  exec : Bool
  in_place : Bool
  test_only : Bool
  root : String
  options : @moonjsonnet.FormatOptions
}

///|
priv enum Action {
  Run(Config)
  Help
  Version
  UsageFailure(String)
}

///|
suberror CliError {
  Message(String)
  SyntaxMessage(Bytes)
}

///|
fn simplify_args(given : Array[String]) -> Array[String] {
  let result = []
  let mut options = true
  for arg in given {
    if arg == "--" {
      options = false
    }
    let bytes = @utf8.encode(arg)
    if options && bytes.length() > 2 && bytes[0] == 45 && bytes[1] != 45 {
      for byte in bytes[1:] {
        result.push("-" + byte.to_int().to_char().unwrap().to_string())
      }
    } else {
      result.push(arg)
    }
  }
  result
}

///|
fn integer(value : String, option : String) -> Int raise CliError {
  let digits = if value.has_prefix("+") || value.has_prefix("-") {
    value[1:]
  } else {
    value[:]
  }
  if digits.is_empty() || !digits.iter().all(c => c >= '0' && c <= '9') {
    raise Message("Invalid integer \"" + value + "\"\n")
  }
  let n = @string.parse_int64(value, base=10) catch {
    _ => raise Message("Invalid integer \"" + value + "\"\n")
  }
  if n < 0 {
    raise Message(
      "ERROR: invalid " + option + " value: " + n.to_string() + "\n",
    )
  }
  if n > 2147483647L {
    2147483647
  } else {
    n.to_int()
  }
}

///|
fn parse_args(given : Array[String]) -> Action raise CliError {
  let args = simplify_args(given)
  let mut config : Config = {
    paths: [],
    output: None,
    exec: false,
    in_place: false,
    test_only: false,
    root: ".",
    options: @moonjsonnet.FormatOptions::default(),
  }
  let mut options = true
  let mut i = 0
  while i < args.length() {
    let arg = args[i]
    i += 1
    if options && arg == "--" {
      options = false
      continue
    }
    if !options || arg == "-" || !arg.has_prefix("-") {
      config.paths.push(arg)
      continue
    }
    match arg {
      "-h" | "--help" => return Help
      "-v" | "--version" => return Version
      "-e" | "--exec" => config = { ..config, exec: true, }
      "-i" | "--in-place" => config = { ..config, in_place: true, }
      "--test" => config = { ..config, test_only: true, }
      "-c" | "--create-output-dirs" => () // Go always creates dirs for -o.
      "--pretty-field-names" | "--no-pretty-field-names" =>
        config = {
          ..config,
          options: {
            ..config.options,
            pretty_field_names: arg == "--pretty-field-names",
          },
        }
      "--pad-arrays" | "--no-pad-arrays" =>
        config = {
          ..config,
          options: { ..config.options, pad_arrays: arg == "--pad-arrays", },
        }
      "--pad-objects" | "--no-pad-objects" =>
        config = {
          ..config,
          options: { ..config.options, pad_objects: arg == "--pad-objects", },
        }
      "--sort-imports" | "--no-sort-imports" =>
        config = {
          ..config,
          options: { ..config.options, sort_imports: arg == "--sort-imports", },
        }
      "--use-implicit-plus" | "--no-use-implicit-plus" =>
        config = {
          ..config,
          options: {
            ..config.options,
            use_implicit_plus: arg == "--use-implicit-plus",
          },
        }
      "-o"
      | "--output-file"
      | "-n"
      | "--indent"
      | "--max-blank-lines"
      | "--string-style"
      | "--comment-style"
      | "--root" => {
        guard i < args.length() else {
          raise Message("Expected another commandline argument.\n")
        }
        let value = args[i]
        i += 1
        match arg {
          "-o" | "--output-file" => {
            if value.is_empty() {
              raise Message("ERROR: -o argument was empty string\n")
            }
            config = { ..config, output: Some(value), }
          }
          "--root" => {
            if value.is_empty() {
              raise Message("ERROR: --root argument was empty string\n")
            }
            config = { ..config, root: value, }
          }
          "-n" | "--indent" =>
            config = {
              ..config,
              options: { ..config.options, indent: integer(value, "--indent"), },
            }
          "--max-blank-lines" =>
            config = {
              ..config,
              options: {
                ..config.options,
                max_blank_lines: integer(value, arg),
              },
            }
          "--string-style" => {
            let style : @moonjsonnet.FormatStringStyle = match value {
              "d" => DoubleQuotes
              "s" => SingleQuotes
              "l" => PreserveQuotes
              _ =>
                raise Message(
                  "ERROR: invalid --string-style value: " + value + "\n",
                )
            }
            config = {
              ..config,
              options: { ..config.options, string_style: style, },
            }
          }
          "--comment-style" => {
            let style : @moonjsonnet.FormatCommentStyle = match value {
              "h" => HashComments
              "s" => SlashComments
              "l" => PreserveComments
              _ =>
                raise Message(
                  "ERROR: invalid --comment-style value: " + value + "\n",
                )
            }
            config = {
              ..config,
              options: { ..config.options, comment_style: style, },
            }
          }
          _ => ()
        }
      }
      _ => raise Message("ERROR: unrecognized argument: " + arg + "\n")
    }
  }
  let want = if config.exec { "code" } else { "filename" }
  if config.paths.is_empty() {
    return UsageFailure("must give " + want)
  }
  if !config.in_place && !config.test_only && config.paths.length() > 1 {
    raise Message("ERROR: only one " + want + " is allowed\n")
  }
  Run(config)
}
