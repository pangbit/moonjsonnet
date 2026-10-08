///|
fn io_failure(path : String, fallback : String) -> Unit raise CliError {
  raise Message(@posix.io_error(path).unwrap_or("ERROR: " + fallback) + "\n")
}

///|
fn load_input(host : @fs.FileHost, path : String) -> @moonjsonnet.Source raise {
  @posix.clear_io_error()
  host.load(path) catch {
    @moonjsonnet.Error(d) => {
      if d.kind == @moonjsonnet.Import &&
        @posix.io_error(path, input=true) is Some(message) {
        raise Message(message + "\n")
      }
      raise @moonjsonnet.Error(d)
    }
  }
}

///|
// Translate ordinary host I/O failures only at the CLI boundary. Library and
// host-policy categories remain intact; the VM captures the active import frame.
fn import_io_path(
  from : String,
  path : String,
  actual : String,
  jpaths : Array[String],
) -> String {
  let candidates = [
    if path.has_prefix("/") || from.is_empty() {
      path
    } else {
      output_parent(from) + "/" + path
    },
  ]
  if !path.has_prefix("/") {
    for i = jpaths.length() - 1; i >= 0; i = i - 1 {
      candidates.push(jpaths[i] + "/" + path)
    }
  }
  let cwd = @env.current_dir().unwrap_or(".")
  for candidate in candidates {
    let clean = output_parent(candidate + "/x")
    let absolute = if clean.has_prefix("/") {
      clean
    } else {
      output_parent(cwd + "/" + clean + "/x")
    }
    if absolute == actual {
      return clean
    }
  }
  actual
}

///|
fn import_failure(
  d : @moonjsonnet.Diagnostic,
  from : String,
  path : String,
  jpaths : Array[String],
) -> @moonjsonnet.JsonnetError {
  if d.kind == @moonjsonnet.Import && !path.contains("\u0000") {
    let message = if d.message == "no match locally or in Jsonnet library paths" {
      Some(
        "couldn't open import " +
        @quote.quote(path) +
        ": no match locally or in the Jsonnet library paths",
      )
    } else {
      @posix.io_error(import_io_path(from, path, d.location.file, jpaths))
    }
    if message is Some(message) {
      return @moonjsonnet.Error({
        ..d,
        kind: @moonjsonnet.Runtime,
        message,
        trace: [],
      })
    }
  }
  @moonjsonnet.Error(d)
}
