///|
fn Vm::import_file(
  self : Vm,
  path : String,
  raw : Bool,
  loc : Location,
) -> Value raise {
  let request = (loc.file, path)
  let source = match self.sources.get(request) {
    Some(s) => s
    None => {
      if self.sources.length() >= self.limits.imports {
        raise problem(Limit, loc, "import count limit exceeded")
      }
      guard self.resolver is Some(resolve) else {
        raise problem(Import, loc, "imports disabled: no resolver supplied")
      }
      let s = resolve(loc.file, path) catch {
        Error(d) => {
          d.context.push(loc)
          raise Error(d)
        }
        e => raise problem(Import, loc, e.to_string())
      }
      let size = @utf8.encode(s.text).length()
      if size > self.limits.source_bytes ||
        size > self.limits.import_bytes - self.imported_bytes {
        raise problem(Limit, loc, "import byte limit exceeded")
      }
      self.imported_bytes += size
      self.sources[request] = s
      s
    }
  }
  let key = (source.id, raw)
  if self.imports.get(key) is Some(t) {
    if self.thunks[t] is Busy {
      raise problem(Import, loc, "cyclic import '\{source.id}'")
    }
    return self.force(t, loc)
  }
  if raw {
    let v = Str(source.text)
    self.imports[key] = self.store(Ready(v))
    return v
  }
  let expression = parse(source.text, source.id, self.limits.depth) catch {
    Error(d) => {
      d.context.push(loc)
      raise Error(d)
    }
    e => raise e
  }
  let t = self.store(Pending(expression, self.base_env()))
  self.imports[key] = t
  self.force(t, loc) catch {
    Error(d) => {
      d.context.push(loc)
      raise Error(d)
    }
    e => raise e
  }
}

///|
fn Vm::base_env(self : Vm) -> Env {
  { parent: None, names: Map([("std", self.store(Ready(Std)))]), }
}
