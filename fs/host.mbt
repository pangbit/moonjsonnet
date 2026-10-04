///|
/// A POSIX import host restricted to one canonical directory.
pub struct FileHost {
  root : String
  max_bytes : Int
  jpaths : Array[String]
  cache : Map[String, @moonjsonnet.Source]
  binary_cache : Map[String, @moonjsonnet.BinarySource]
  attempts : Map[String, @moonjsonnet.BinarySource?]
}

///|
fn diagnostic(
  kind : @moonjsonnet.ErrorKind,
  file : String,
  message : String,
) -> @moonjsonnet.JsonnetError {
  @moonjsonnet.Error({
    kind,
    message,
    location: { file, line: 1, column: 1, },
    context: [],
  })
}

///|
/// Canonicalize the allowed root. Use a fresh host to observe file changes.
/// Library paths are relative to root; the last path has highest priority.
pub fn FileHost::new(
  root : String,
  jpaths? : Array[String] = [],
  max_bytes? : Int = 1048576,
) -> FileHost raise @moonjsonnet.JsonnetError {
  guard max_bytes > 0 && max_bytes < 2147483647 else {
    raise diagnostic(
      @moonjsonnet.Limit,
      root,
      "file byte limit must be positive and below INT_MAX",
    )
  }
  guard @posix.canonical(root) is Some(root) else {
    raise diagnostic(
      @moonjsonnet.Import,
      root,
      "cannot canonicalize allowed root",
    )
  }
  {
    root,
    max_bytes,
    jpaths: jpaths.copy(),
    cache: Map([]),
    binary_cache: Map([]),
    attempts: Map([]),
  }
}

///|
/// Resolve locally, then search library paths from right to left.
/// Canonical paths outside the root, including symlink escapes, are rejected.
pub fn FileHost::resolve(
  self : FileHost,
  from : String,
  path : String,
) -> @moonjsonnet.Source raise @moonjsonnet.JsonnetError {
  self.decode_source(self.resolve_binary(from, path))
}

///|
/// Load an entry file relative to root, without searching library paths.
///
/// ```mbt check
/// test {
///   let host = @fs.FileHost::new(@env.current_dir().unwrap(), jpaths=["lib"])
///   assert_true(!host.load("moon.mod").text.is_empty())
/// }
/// ```
pub fn FileHost::load(
  self : FileHost,
  path : String,
) -> @moonjsonnet.Source raise @moonjsonnet.JsonnetError {
  match self.try_path(self.root, path) {
    Some(source) => self.decode_source(source)
    None =>
      raise diagnostic(@moonjsonnet.Import, path, "cannot resolve entry file")
  }
}

///|
fn FileHost::decode_source(
  self : FileHost,
  source : @moonjsonnet.BinarySource,
) -> @moonjsonnet.Source raise @moonjsonnet.JsonnetError {
  if self.cache.get(source.id) is Some(cached) {
    return cached
  }
  let text = @utf8.decode(source.bytes) catch {
    _ => raise diagnostic(@moonjsonnet.Import, source.id, "invalid UTF-8")
  }
  let result : @moonjsonnet.Source = { id: source.id, text, }
  self.cache[source.id] = result
  result
}

///|
/// Resolve arbitrary bytes with the same canonical root and cache guarantees.
pub fn FileHost::resolve_binary(
  self : FileHost,
  from : String,
  path : String,
) -> @moonjsonnet.BinarySource raise @moonjsonnet.JsonnetError {
  let base = if from.is_empty() {
    self.root
  } else {
    match from.rev_find("/") {
      Some(i) => if i == 0 { "/" } else { from[:i].to_owned() }
      None => self.root
    }
  }
  if self.try_path(base, path) is Some(source) {
    return source
  }
  if !path.has_prefix("/") {
    for i = self.jpaths.length() - 1; i >= 0; i = i - 1 {
      let dir = self.jpaths[i]
      let base = if dir.has_prefix("/") { dir } else { self.root + "/" + dir }
      if self.try_path(base, path) is Some(source) {
        return source
      }
    }
  }
  raise diagnostic(
    @moonjsonnet.Import,
    path,
    "no match locally or in Jsonnet library paths",
  )
}

///|
// Go's filepath.Join cleans dot components before filesystem lookup.
fn joined_path(base : String, path : String) -> String {
  if path.has_prefix("/") {
    return path
  }
  let requested = base + "/" + path
  let absolute = requested.has_prefix("/")
  let parts : Array[String] = []
  for part in requested.split("/") {
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
fn FileHost::try_path(
  self : FileHost,
  base : String,
  path : String,
) -> @moonjsonnet.BinarySource? raise @moonjsonnet.JsonnetError {
  let requested = joined_path(base, path)
  if self.attempts.get(requested) is Some(result) {
    return result
  }
  let (status, canonical) = @posix.canonical_result(requested)
  if status == 6 {
    self.attempts[requested] = None
    return None
  }
  if status != 0 {
    raise diagnostic(@moonjsonnet.Import, requested, "cannot resolve file")
  }
  let prefix = if self.root == "/" { "/" } else { self.root + "/" }
  if !canonical.has_prefix(prefix) {
    raise diagnostic(
      @moonjsonnet.Import,
      requested,
      "import escapes allowed root",
    )
  }
  if self.binary_cache.get(canonical) is Some(source) {
    self.attempts[requested] = Some(source)
    return Some(source)
  }
  let relative = canonical[prefix.length():].to_owned()
  let (status, bytes) = @posix.read_bytes(self.root, relative, self.max_bytes)
  if status == 6 {
    self.attempts[requested] = None
    return None
  }
  if status != 0 {
    raise diagnostic(
      if status == 3 {
        @moonjsonnet.Limit
      } else {
        @moonjsonnet.Import
      },
      canonical,
      match status {
        3 => "file byte limit exceeded"
        4 => "expected regular file"
        5 => "invalid UTF-8"
        _ => "cannot open file within allowed root"
      },
    )
  }
  let source : @moonjsonnet.BinarySource = { id: canonical, bytes, }
  self.binary_cache[canonical] = source
  self.attempts[requested] = Some(source)
  Some(source)
}

///|
/// Load and evaluate a file under `root`. Entry paths are relative to `root`.
pub fn evaluate_file(
  path : String,
  root? : String = ".",
  jpaths? : Array[String] = [],
  ext_vars? : Map[String, Json] = Map([]),
  ext_code? : Map[String, String] = Map([]),
  tla_vars? : Map[String, Json] = Map([]),
  tla_code? : Map[String, String] = Map([]),
  native_functions? : Map[String, @moonjsonnet.NativeFunction] = Map([]),
  trace? : (@moonjsonnet.Location, String) -> Unit,
  limits? : @moonjsonnet.Limits = @moonjsonnet.Limits::default(),
) -> Json raise @moonjsonnet.JsonnetError {
  let host = FileHost::new(root, jpaths~, max_bytes=limits.source_bytes)
  let source = host.load(path)
  @moonjsonnet.evaluate(
    source.text,
    filename=source.id,
    ext_vars~,
    ext_code~,
    tla_vars~,
    tla_code~,
    native_functions~,
    trace?,
    limits~,
    resolver=(from, path) => host.resolve(from, path),
    binary_resolver=(from, path) => host.resolve_binary(from, path),
  )
}
