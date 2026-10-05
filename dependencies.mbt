///|
priv struct DependencyScan {
  resolver : (String, String) -> BinarySource raise
  limits : Limits
  requests : Map[(String, String), BinarySource]
  parsed : Map[String, Expr]
  found : Map[String, Bool]
  mut bytes : Int
  mut steps : Int
}

///|
/// Return sorted unique transitive import identities, excluding every entry.
/// No Jsonnet code is evaluated. The resolver serves bytes for all three import
/// forms; only code imports are decoded and parsed. Each call has fresh caches.
/// Like Go v0.21.0 FindDependencies, an identity seen as raw data suppresses
/// later code traversal, and object assertions are not traversed.
///
/// ```mbt check
/// test {
///   let files = Map([
///     ("main", b"if false then import 'data' else 1"),
///     ("data", b"42"),
///   ])
///   let dependencies = @moonjsonnet.find_dependencies("", ["main"], resolver=fn(
///     _,
///     path,
///   ) {
///     { id: path, bytes: files[path], }
///   })
///   assert_eq(dependencies, ["data"])
/// }
/// ```
pub fn find_dependencies(
  imported_from : String,
  imported_paths : Array[String],
  resolver~ : (String, String) -> BinarySource raise,
  limits? : Limits = Limits::default(),
) -> Array[String] raise JsonnetError {
  find_dependencies_with_cache(
    imported_from,
    imported_paths,
    resolver~,
    limits~,
    parsed=Map([]),
  )
}

///|
fn find_dependencies_with_cache(
  imported_from : String,
  imported_paths : Array[String],
  resolver~ : (String, String) -> BinarySource raise,
  limits~ : Limits,
  parsed~ : Map[String, Expr],
) -> Array[String] raise JsonnetError {
  let loc : Location = { file: imported_from, line: 1, column: 1, }
  try {
    check_limits(limits, loc)
    let scan : DependencyScan = {
      resolver,
      limits,
      requests: Map([]),
      parsed,
      found: Map([]),
      bytes: 0,
      steps: 0,
    }
    let roots = []
    for path in imported_paths {
      let source = scan.load(imported_from, path, loc)
      roots.push((source.id, scan.code(source)))
      scan.found[source.id] = true
    }
    for (id, expr) in roots {
      // An explicit work stack permits cyclic and deep dependency graphs without
      // turning graph depth into native call-stack depth.
      let pending = [(id, expr)]
      while pending.pop() is Some((from, expr)) {
        if scan.steps >= limits.steps {
          raise problem(Limit, expr.loc, "dependency scan step limit exceeded")
        }
        scan.steps += 1
        let request = match expr.kind {
          ImportFile(path, raw) => Some((path, !raw))
          ImportBinary(path) => Some((path, false))
          _ => None
        }
        if request is Some((path, is_code)) {
          let source = scan.load(from, path, expr.loc)
          // Go parses code before testing whether the identity was already seen.
          let child = if is_code { Some(scan.code(source)) } else { None }
          if !scan.found.contains(source.id) {
            scan.found[source.id] = true
            if child is Some(child) {
              pending.push((source.id, child))
            }
          }
        } else {
          let children = dependency_children(expr)
          for i = children.length() - 1; i >= 0; i = i - 1 {
            pending.push((from, children[i]))
          }
        }
      }
    }
    for (id, _) in roots {
      ignore(scan.found.remove(id))
    }
    let result = scan.found.keys().collect()
    result.sort_by(compare_unicode)
    let mut size = 0
    for id in result {
      let bytes = @utf8.encode(id).length()
      if bytes >= limits.output_bytes - size {
        raise problem(Limit, loc, "dependency output byte limit exceeded")
      }
      size += bytes + 1
    }
    result
  } catch {
    Error(d) => raise Error(d)
    e =>
      raise Error({
        kind: Import,
        location: loc,
        message: e.to_string(),
        context: [],
      })
  }
}

///|
fn DependencyScan::load(
  self : DependencyScan,
  from : String,
  path : String,
  loc : Location,
) -> BinarySource raise {
  if self.requests.get((from, path)) is Some(source) {
    return source
  }
  if self.requests.length() >= self.limits.imports {
    raise problem(Limit, loc, "import count limit exceeded")
  }
  let source = (self.resolver)(from, path) catch {
    Error(d) => {
      d.context.push(loc)
      raise Error(d)
    }
    e => raise problem(Import, loc, e.to_string())
  }
  let size = source.bytes.length()
  if size > self.limits.source_bytes ||
    size > self.limits.import_bytes - self.bytes {
    raise problem(Limit, loc, "import byte limit exceeded")
  }
  self.bytes += size
  self.requests[(from, path)] = source
  source
}

///|
fn DependencyScan::code(
  self : DependencyScan,
  source : BinarySource,
) -> Expr raise {
  if self.parsed.get(source.id) is Some(expr) {
    check_ast_depth(expr, self.limits.depth)
    return expr
  }
  let text = @utf8.decode(source.bytes) catch {
    _ =>
      raise problem(
        Import,
        { file: source.id, line: 1, column: 1, },
        "invalid UTF-8",
      )
  }
  let expr = parse(text, source.id, self.limits.depth)
  self.parsed[source.id] = expr
  expr
}
