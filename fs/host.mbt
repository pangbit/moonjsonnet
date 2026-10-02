///|
/// A POSIX import host restricted to one canonical directory.
pub struct FileHost {
  root : String
  max_bytes : Int
  cache : Map[String, @moonjsonnet.Source]
  binary_cache : Map[String, @moonjsonnet.BinarySource]
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
pub fn FileHost::new(
  root : String,
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
  { root, max_bytes, cache: Map([]), binary_cache: Map([]), }
}

///|
/// Resolve relative to the importing file (or root when `from` is empty).
/// Canonical paths outside the root, including symlink escapes, are rejected.
pub fn FileHost::resolve(
  self : FileHost,
  from : String,
  path : String,
) -> @moonjsonnet.Source raise @moonjsonnet.JsonnetError {
  let source = self.resolve_binary(from, path)
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
      Some(i) => from[:i].to_owned()
      None => self.root
    }
  }
  let requested = if path.has_prefix("/") { path } else { base + "/" + path }
  guard @posix.canonical(requested) is Some(canonical) else {
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
    return source
  }
  let relative = canonical[prefix.length():].to_owned()
  let (status, bytes) = @posix.read_bytes(self.root, relative, self.max_bytes)
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
  source
}

///|
/// Load and evaluate a file under `root`. Entry paths are relative to `root`.
pub fn evaluate_file(
  path : String,
  root? : String = ".",
  ext_vars? : Map[String, Json] = Map([]),
  limits? : @moonjsonnet.Limits = @moonjsonnet.Limits::default(),
) -> Json raise @moonjsonnet.JsonnetError {
  let host = FileHost::new(root, max_bytes=limits.source_bytes)
  let source = host.resolve("", path)
  @moonjsonnet.evaluate(
    source.text,
    filename=source.id,
    ext_vars~,
    limits~,
    resolver=(from, path) => host.resolve(from, path),
    binary_resolver=(from, path) => host.resolve_binary(from, path),
  )
}
