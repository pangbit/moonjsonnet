///|
priv struct ImportReader {
  sources : Map[(String, String), Source]
  binary_sources : Map[(String, String), BinarySource]
  resolver : ((String, String) -> Source raise)?
  binary_resolver : ((String, String) -> BinarySource raise)?
  limits : Limits
}

///|
// Runtime callbacks retain this snapshot, not the owning Evaluator. Capturing
// the Evaluator itself would create a reference-count cycle through state: Vm.
fn Evaluator::reader(self : Evaluator) -> ImportReader {
  {
    sources: self.sources,
    binary_sources: self.binary_sources,
    resolver: self.resolver,
    binary_resolver: self.binary_resolver,
    limits: self.limits,
  }
}

///|
fn[T] Evaluator::query(
  self : Evaluator,
  from : String,
  action : () -> T raise,
) -> T raise JsonnetError {
  self.idle()
  let loc : Location = { file: from, line: 1, column: 1, }
  check_limits(self.limits, loc)
  self.busy = true
  defer {
    self.busy = false
  }
  action() catch {
    Error(d) => raise Error(d)
    e => raise problem(Import, loc, e.to_string())
  }
}

///|
// Queries and execution use the same immutable source identities. A binary
// callback, when present, is authoritative; text-only callbacks are UTF-8 encoded.
fn ImportReader::load_data(
  self : ImportReader,
  from : String,
  path : String,
) -> BinarySource raise {
  let key = (from, path)
  let loc : Location = { file: from, line: 1, column: 1, }
  let source = match self.binary_sources.get(key) {
    Some(source) => source
    None =>
      if self.sources.get(key) is Some(source) {
        { id: source.id, bytes: @utf8.encode(source.text), }
      } else if self.binary_resolver is Some(resolve) {
        resolve(from, path)
      } else if self.resolver is Some(resolve) {
        let source = resolve(from, path)
        { id: source.id, bytes: @utf8.encode(source.text), }
      } else {
        raise problem(Import, loc, "imports disabled: no resolver supplied")
      }
  }
  if source.bytes.length() > self.limits.source_bytes ||
    source.bytes.length() > self.limits.import_bytes {
    raise problem(Limit, loc, "import byte limit exceeded")
  }
  self.binary_sources[key] = source
  source
}

///|
fn ImportReader::load_text(
  self : ImportReader,
  from : String,
  path : String,
) -> Source raise {
  let source = self.load_data(from, path)
  let text = @utf8.decode(source.bytes) catch {
    _ =>
      raise problem(
        Import,
        { file: source.id, line: 1, column: 1, },
        "invalid UTF-8",
      )
  }
  { id: source.id, text, }
}

///|
/// Resolve an imported identity without parsing or evaluating its contents.
/// Source bytes are cached immediately and shared with later queries/evaluation.
pub fn Evaluator::resolve_import(
  self : Evaluator,
  imported_from : String,
  imported_path : String,
) -> String raise JsonnetError {
  self.query(imported_from, () => {
    self.reader().load_data(imported_from, imported_path).id
  })
}

///|
/// Fetch raw imported bytes and their resolved identity without UTF-8 decoding.
/// Unlike a String result, BinarySource can preserve invalid UTF-8 and NUL bytes.
pub fn Evaluator::import_data(
  self : Evaluator,
  imported_from : String,
  imported_path : String,
) -> BinarySource raise JsonnetError {
  self.query(imported_from, () => {
    self.reader().load_data(imported_from, imported_path)
  })
}

///|
/// Parse and validate an imported program, returning its AST wrapper and identity.
/// This neither executes the program nor applies TLA/ext/native configuration.
///
/// ```mbt check
/// test {
///   let evaluator = @moonjsonnet.Evaluator::new()
///   evaluator.set_importer(binary_resolver=fn(_, _) {
///     { id: "lib/answer", bytes: b"42", }
///   })
///   let (program, identity) = evaluator.import_program("", "answer")
///   assert_eq(identity, "lib/answer")
///   assert_eq(evaluator.evaluate(program), 42)
/// }
/// ```
pub fn Evaluator::import_program(
  self : Evaluator,
  imported_from : String,
  imported_path : String,
) -> (Program, String) raise JsonnetError {
  self.query(imported_from, () => {
    let source = self.reader().load_data(imported_from, imported_path)
    let expression = if self.parsed_imports.get(source.id) is Some(expression) {
      check_ast_depth(expression, self.limits.depth)
      expression
    } else {
      let text = @utf8.decode(source.bytes) catch {
        _ =>
          raise problem(
            Import,
            { file: source.id, line: 1, column: 1, },
            "invalid UTF-8",
          )
      }
      let expression = parse(text, source.id, self.limits.depth)
      self.parsed_imports[source.id] = expression
      expression
    }
    (
      {
        expression,
        filename: source.id,
        anonymous: false,
        source_bytes: source.bytes.length(),
      },
      source.id,
    )
  })
}

///|
/// Scan dependencies without evaluation, sharing source/AST caches with this
/// evaluator. Runtime values, ext/TLA configuration and callbacks are not forced.
pub fn Evaluator::find_dependencies(
  self : Evaluator,
  imported_from : String,
  imported_paths : Array[String],
) -> Array[String] raise JsonnetError {
  let reader = self.reader()
  self.query(imported_from, () => {
    find_dependencies_with_cache(
      imported_from,
      imported_paths,
      resolver=(from, path) => reader.load_data(from, path),
      limits=self.limits,
      parsed=self.parsed_imports,
    )
  })
}
