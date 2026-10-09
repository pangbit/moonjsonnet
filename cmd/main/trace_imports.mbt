///|
fn trace_path(base : String, path : String) -> String {
  if path.has_prefix("/") {
    return path
  }
  let joined = if base.is_empty() { path } else { base + "/" + path }
  output_parent(joined + "/x")
}

///|
// Read the host's successful attempt, without probing or reopening the file.
// Source.id and the host's canonical caches remain untouched.
fn import_trace_name(
  host : @fs.FileHost,
  from : String,
  path : String,
  id : String,
  names : Map[String, String],
  jpaths : Array[String],
) -> String {
  let base = match from.rev_find("/") {
    Some(0) => "/"
    Some(i) => from[:i].to_owned()
    None => host.root
  }
  let shown = names.get(from).unwrap_or(from)
  let directory = match shown.rev_find("/") {
    Some(0) => "/"
    Some(i) => shown[:i].to_owned()
    None => ""
  }
  let candidates = [(trace_path(base, path), trace_path(directory, path))]
  if !path.has_prefix("/") {
    for i = jpaths.length() - 1; i >= 0; i = i - 1 {
      let dir = jpaths[i]
      let base = if dir.has_prefix("/") { dir } else { host.root + "/" + dir }
      candidates.push((trace_path(base, path), trace_path(dir, path)))
    }
  }
  for (requested, display) in candidates {
    if host.attempts.get(requested) is Some(Some(source)) && source.id == id {
      return display
    }
  }
  id
}

///|
fn source_trace(
  location : @moonjsonnet.Location,
  message : String,
  names : Map[String, String],
) -> String {
  entry_trace(
    location,
    message,
    names.get(location.file).map(display => (location.file, display)),
  )
}
