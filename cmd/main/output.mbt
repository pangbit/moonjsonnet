///|
// POSIX filepath.Dir followed by lexical cleaning, as used by Go's MkdirAll.
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
fn write_multi(
  files : Map[String, String],
  directory : String,
  manifest : String?,
  create_dirs : Bool,
  limit : Int,
  loc : @moonjsonnet.Location,
) -> Unit raise {
  let keys = files.keys().collect()
  keys.sort_by((a, b) => @utf8.encode(a).lexical_compare(@utf8.encode(b)))
  let mut bytes = 0
  for key in keys {
    let size = @utf8.encode(directory + key).length() + 1
    if size > limit - bytes {
      raise @moonjsonnet.Error({
        kind: @moonjsonnet.Limit,
        message: "multi output filename list exceeds output limit",
        location: loc,
        context: [],
        trace: [],
      })
    }
    bytes += size
  }
  let fd = match manifest {
    None => 1
    Some(path) => @posix.open_output(path)
  }
  if fd < 0 {
    fail("cannot open output filename list")
  }
  let mut closed = false
  defer (if manifest is Some(_) && !closed { ignore(@posix.close_output(fd)) })
  for key in keys {
    let filename = directory + key
    // Go lists each filename before reading/writing it, preserving partial
    // progress on I/O errors. Evaluation errors are already resolved here.
    if !@posix.write_output(fd, filename + "\n") {
      fail("cannot write output filename list")
    }
    match @posix.output_same(filename, files[key]) {
      1 => ()
      0 => {
        if create_dirs && !@posix.mkdir_all(output_parent(filename)) {
          fail("cannot create output directories: " + filename)
        }
        if !@posix.write(filename, files[key]) {
          fail("cannot write output: " + filename)
        }
      }
      _ => fail("cannot read existing output: " + filename)
    }
  }
  if manifest is Some(_) {
    let ok = @posix.close_output(fd)
    closed = true
    if !ok {
      fail("cannot close output filename list")
    }
  }
}
