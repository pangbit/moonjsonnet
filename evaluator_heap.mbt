///|
// IDs remain stable while reachable from an import. Unreachable slots release
// their values and are reused; repeated entry evaluations cannot grow the arena
// merely by leaving dead thunks/objects behind. No Jsonnet code runs here.
fn Vm::retain_imports(self : Vm) -> Unit {
  // Go retries failed evaluations instead of retaining their exception contexts.
  for id, original in self.retries {
    self.thunks[id] = original
  }
  self.retries.clear()
  for obj in self.objects {
    let failed = obj.cache
      .keys()
      .filter(key => {
        self.thunks[obj.cache[key]] is Failed(_) ||
        self.thunks[obj.cache[key]] is Busy ||
        self.thunks[obj.cache[key]] is Running(_) ||
        self.thunks[obj.cache[key]] is RunningParameter(_, _)
      })
      .collect()
    for key in failed {
      ignore(obj.cache.remove(key))
    }
  }
  self.ext.clear()
  self.binary_imports.clear()
  let thunks = Array::make(self.thunks.length(), false)
  let objects = Array::make(self.objects.length(), false)
  let pending : Array[(Bool, Int32)] = self.imports
    .values()
    .map(id => (false, id))
    .collect()
  while pending.pop() is Some((is_object, id)) {
    if is_object {
      if objects[id] {
        continue
      }
      objects[id] = true
      let obj = self.objects[id]
      for _, id in obj.cache {
        pending.push((false, id))
      }
      for _, env in obj.scopes {
        retain_environment(env, pending)
      }
      for layer in obj.layers {
        retain_environment(layer.env, pending)
        for _, field in layer.fields {
          retain_environment(field.env, pending)
        }
      }
    } else {
      if thunks[id] {
        continue
      }
      thunks[id] = true
      match self.thunks[id] {
        Pending(_, env) => retain_environment(env, pending)
        GeneratedCall(function, arguments, _) => {
          for id in arguments {
            pending.push((false, id))
          }
          match function {
            Closure(_, _, env) => retain_environment(env, pending)
            _ => ()
          }
        }
        Ready(ArrayValue(items)) =>
          for id in items {
            pending.push((false, id))
          }
        Ready(ObjectValue(id, _)) => pending.push((true, id))
        Ready(Closure(_, _, env)) => retain_environment(env, pending)
        _ => ()
      }
    }
  }
  self.free_thunks.clear()
  self.free_objects.clear()
  for id, retained in thunks {
    if !retained {
      self.thunks[id] = Ready(Nil)
      self.free_thunks.push(id)
    }
  }
  for id, retained in objects {
    if !retained {
      self.objects[id] = {
        layers: [],
        cache: Map([]),
        scopes: Map([]),
        assertion_state: 0,
        assertion_error: None,
        standard: false,
      }
      self.free_objects.push(id)
    }
  }
}

///|
// Import callers append context frames. Cached assertion errors own a snapshot,
// so later callers cannot append into the retained error or earlier results.
fn copy_evaluation_error(error : Error) -> Error {
  match error {
    Error(d) =>
      Error({ ..d, context: d.context.copy(), trace: d.trace.copy(), })
    _ => error
  }
}

///|
fn retain_environment(env : Env, pending : Array[(Bool, Int32)]) -> Unit {
  let mut next = Some(env)
  while next is Some(current) {
    for _, id in current.names {
      pending.push((false, id))
    }
    next = current.parent
  }
}

///|
fn Vm::account_import(
  self : Vm,
  from : String,
  path : String,
  binary : Bool,
  size : Int32,
  loc : Location,
) -> Unit raise {
  let key = (from, path, binary)
  if self.accessed_sources.contains(key) {
    return
  }
  if self.accessed_sources.length() >= self.limits.imports {
    raise problem(Limit, loc, "import count limit exceeded")
  }
  if size > self.limits.source_bytes ||
    size > self.limits.import_bytes - self.imported_bytes {
    raise problem(Limit, loc, "import byte limit exceeded")
  }
  self.imported_bytes += size
  self.accessed_sources[key] = ()
}
