///|
fn Vm::import_file(
  self : Vm,
  path : String,
  raw : Bool,
  from : String,
  loc : Location,
) -> Value raise {
  let request = (from, path)
  let source = match self.sources.get(request) {
    Some(s) => s
    None => {
      if self.accessed_sources.length() >= self.limits.imports {
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
      s
    }
  }
  if !self.accessed_sources.contains((from, path, false)) {
    self.account_import(
      from,
      path,
      false,
      @utf8.encode(source.text).length(),
      loc,
    )
    self.sources[request] = source
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
  let expression = try {
    if self.parsed_imports.get(source.id) is Some(expr) {
      check_ast_depth(expr, self.limits.depth)
      expr
    } else {
      let expr = parse(source.text, source.id, self.limits.depth)
      self.parsed_imports[source.id] = expr
      expr
    }
  } catch {
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
fn Vm::base_env(
  self : Vm,
  file? : String = "<input>",
  import_from? : String,
) -> Env raise {
  let import_from = import_from.unwrap_or(file)
  let env : Env = {
    parent: None,
    names: Map([]),
    import_from,
    debug_visible: None,
  }
  let loc : Location = { file, line: 1, column: 1, }
  let fields : Map[String, LayerField] = Map([])
  for name in builtin_names() {
    fields[name] = {
      field: {
        key: { kind: Literal(Json::string(name)), loc, end: None, },
        value: { kind: StandardFunction(name), loc, end: None, },
        visibility: 2,
        additive: false,
      },
      env,
    }
  }
  fields["thisFile"] = {
    field: {
      key: { kind: Literal(Json::string("thisFile")), loc, end: None, },
      value: { kind: StandardValue(Json::string(file)), loc, end: None, },
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
  {
    parent: None,
    names: Map([("std", self.store(Ready(value)))]),
    import_from,
    debug_visible: Some(_tick => ["$std", "std"]),
  }
}

///|
fn Vm::import_binary(
  self : Vm,
  path : String,
  from : String,
  loc : Location,
) -> Value raise {
  let request = (from, path)
  let source = match self.binary_sources.get(request) {
    Some(s) => s
    None => {
      if self.accessed_sources.length() >= self.limits.imports {
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
      s
    }
  }
  if !self.accessed_sources.contains((from, path, true)) {
    self.account_import(from, path, true, source.bytes.length(), loc)
    self.binary_sources[request] = source
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
