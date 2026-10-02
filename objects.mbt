///|
fn Vm::object_value(self : Vm, layers : Array[Layer]) -> Value {
  let id = self.objects.length()
  self.objects.push({
    layers,
    cache: Map([]),
    scopes: Map([]),
    assertion_state: 0,
  })
  ObjectValue(id, layers.length())
}

///|
fn Vm::scope(self : Vm, id : Int, layer : Int, outer : Env) -> Env {
  let obj = self.objects[id]
  let env = outer.child()
  env.names["self"] = self.store(Ready(ObjectValue(id, obj.layers.length())))
  env.names["super"] = self.store(Ready(ObjectValue(id, layer)))
  if env.lookup("$") is None {
    env.names["$"] = env.names["self"]
  }
  self.bind(obj.layers[layer].locals, env)
}

///|
fn Vm::layer_scope(self : Vm, id : Int, layer : Int) -> Env {
  let obj = self.objects[id]
  match obj.scopes.get(layer) {
    Some(e) => e
    None => {
      let e = self.scope(id, layer, obj.layers[layer].env)
      obj.scopes[layer] = e
      e
    }
  }
}

///|
fn Vm::check_assertions(self : Vm, id : Int, loc : Location) -> Unit raise {
  let obj = self.objects[id]
  if obj.assertion_state != 0 {
    return
  }
  obj.assertion_state = 1
  errdefer {
    obj.assertion_state = 0
  }
  for i in 0..<obj.layers.length() {
    let env = self.layer_scope(id, i)
    for (cond, msg) in obj.layers[i].assertions {
      self.assertion(cond, msg, env)
    }
  }
  obj.assertion_state = 2
  self.tick(loc)
}

///|
fn Vm::has_field(self : Vm, id : Int, top : Int, name : String) -> Bool {
  for i in 0..<top {
    if self.objects[id].layers[i].fields.contains(name) {
      return true
    }
  }
  false
}

///|
fn Vm::visible(self : Vm, id : Int, top : Int, name : String) -> Bool {
  let mut visible = true
  for i in 0..<top {
    if self.objects[id].layers[i].fields.get(name) is Some(f) {
      if f.field.visibility == 2 {
        visible = false
      }
      if f.field.visibility == 3 {
        visible = true
      }
    }
  }
  visible
}

///|
fn Vm::keys(self : Vm, id : Int, top : Int, hidden : Bool) -> Array[String] {
  let seen : Map[String, Bool] = Map([])
  for i in 0..<top {
    for k, _ in self.objects[id].layers[i].fields {
      seen[k] = true
    }
  }
  let out = seen
    .keys()
    .filter(k => hidden || self.visible(id, top, k))
    .collect()
  out.sort_by(compare_unicode)
  out
}

///|
fn Vm::field(
  self : Vm,
  id : Int,
  top : Int,
  name : String,
  loc : Location,
) -> Value raise {
  self.tick(loc)
  self.check_assertions(id, loc)
  let obj = self.objects[id]
  let mut layer = top - 1
  while layer >= 0 {
    if obj.layers[layer].fields.get(name) is Some(f) {
      let cache_key = (layer, name)
      if obj.cache.get(cache_key) is Some(t) {
        return self.force(t, loc)
      }
      // Install a busy thunk before evaluating additive fields as well.
      let t = self.store(Busy)
      obj.cache[cache_key] = t
      let env = if obj.layers[layer].locals.is_empty() {
        self.scope(id, layer, f.env)
      } else {
        self.layer_scope(id, layer)
      }
      let v = try {
        let rhs = self.eval(f.field.value, env)
        if f.field.additive && self.has_field(id, layer, name) {
          self.binary("+", self.field(id, layer, name, loc), rhs, loc)
        } else {
          rhs
        }
      } catch {
        e => self.failure(t, e)
      }
      self.thunks[t] = Ready(v)
      return v
    }
    layer -= 1
  }
  raise problem(Runtime, loc, "field '\{name}' does not exist")
}

///|
fn Vm::assertion(self : Vm, cond : Expr, msg : Expr?, env : Env) -> Unit raise {
  if !boolean(self.eval(cond, env), cond.loc) {
    let message = match msg {
      Some(m) => text_value(self.eval(m, env), m.loc)
      None => "assertion failed"
    }
    raise problem(Assertion, cond.loc, message)
  }
}
