///|
fn Vm::import_file(
  self : Vm,
  path : String,
  raw : Bool,
  loc : Location,
) -> Value raise {
  let from = self.import_origin(loc.file)
  let request = (from, path)
  let source = match self.sources.get(request) {
    Some(s) => s
    None => {
      if self.sources.length() + self.binary_sources.length() >=
        self.limits.imports {
        raise problem(Limit, loc, "import count limit exceeded")
      }
      guard self.resolver is Some(resolve) else {
        raise problem(Import, loc, "imports disabled: no resolver supplied")
      }
      let s = resolve(from, path) catch {
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
  let t = self.store(Pending(expression, self.base_env(file=source.id)))
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
fn Vm::base_env(self : Vm, file? : String = "<input>") -> Env raise {
  let env : Env = { parent: None, names: Map([]), }
  let loc : Location = { file, line: 1, column: 1, }
  let fields : Map[String, LayerField] = Map([])
  for name in builtin_names() {
    fields[name] = {
      field: {
        key: { kind: Literal(Json::string(name)), loc, },
        value: { kind: StandardFunction(name), loc, },
        visibility: 2,
        additive: false,
      },
      env,
    }
  }
  fields["thisFile"] = {
    field: {
      key: { kind: Literal(Json::string("thisFile")), loc, },
      value: { kind: Literal(Json::string(file)), loc, },
      visibility: 2,
      additive: false,
    },
    env,
  }
  guard self.eval(self.library, env) is ObjectValue(library_id, _) else {
    raise problem(Runtime, loc, "standard library must be an object")
  }
  let layers = self.objects[library_id].layers.copy()
  layers.push({ fields, locals: [], assertions: [], env, })
  let value = self.object_value(layers)
  if value is ObjectValue(id, _) {
    self.objects[id].standard = true
  }
  { parent: None, names: Map([("std", self.store(Ready(value)))]), }
}

///|
fn Vm::import_binary(self : Vm, path : String, loc : Location) -> Value raise {
  let from = self.import_origin(loc.file)
  let request = (from, path)
  let source = match self.binary_sources.get(request) {
    Some(s) => s
    None => {
      if self.sources.length() + self.binary_sources.length() >=
        self.limits.imports {
        raise problem(Limit, loc, "import count limit exceeded")
      }
      guard self.binary_resolver is Some(resolve) else {
        raise problem(
          Import,
          loc,
          "binary imports disabled: no binary resolver supplied",
        )
      }
      let s = resolve(from, path) catch {
        Error(d) => {
          d.context.push(loc)
          raise Error(d)
        }
        e => raise problem(Import, loc, e.to_string())
      }
      let size = s.bytes.length()
      if size > self.limits.source_bytes ||
        size > self.limits.import_bytes - self.imported_bytes {
        raise problem(Limit, loc, "import byte limit exceeded")
      }
      self.imported_bytes += size
      self.binary_sources[request] = s
      s
    }
  }
  if self.binary_imports.get(source.id) is Some(t) {
    return self.force(t, loc)
  }
  let items = []
  for b in source.bytes {
    self.tick(loc)
    items.push(self.store(Ready(Num(b.to_int().to_double()))))
  }
  let value = ArrayValue(items)
  self.binary_imports[source.id] = self.store(Ready(value))
  value
}
