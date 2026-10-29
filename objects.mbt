///|
fn Vm::object_value(self : Vm, layers : Array[Layer]) -> Value {
  let obj = {
    layers,
    cache: Map([]),
    scopes: Map([]),
    assertion_state: 0,
    assertion_error: None,
    standard: false,
  }
  let id = if self.free_objects.pop() is Some(id) {
    self.objects[id] = obj
    id
  } else {
    let id = self.objects.length()
    self.objects.push(obj)
    id
  }
  ObjectValue(id, layers.length())
}

///|
fn Vm::scope(self : Vm, id : Int, layer : Int, outer : Env) -> Env {
  let obj = self.objects[id]
  let env = outer
    .child()
    .trace_context("object <" + outer.diagnostic_context.1 + ">")
  env.names["self"] = self.store(Ready(ObjectValue(id, obj.layers.length())))
  env.names["super"] = self.store(Ready(ObjectValue(id, layer)))
  if obj.standard {
    env.names["$std"] = env.names["self"]
  }
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
  if obj.assertion_error is Some(error) {
    raise copy_evaluation_error(error)
  }
  if obj.assertion_state != 0 {
    return
  }
  obj.assertion_state = 1
  errdefer {
    obj.assertion_state = 0
  }
  try {
    for i in 0..<obj.layers.length() {
      let env = self.layer_scope(id, i)
      for index, (cond, msg) in obj.layers[i].assertions {
        self.push_frame(cond.loc, false)
        defer self.pop_frame()
        self.assertion(
          cond,
          msg,
          env,
          default_message="Object assertion failed.",
          failure_frame={
            location: Source(
              obj.layers[i].assertion_sites
              .get(index)
              .bind(site => site)
              .unwrap_or({
                begin: cond.loc,
                end: diagnostic_expr_end(msg.unwrap_or(cond)),
              }),
            ),
            name: "",
          },
        )
      }
    }
  } catch {
    e => {
      if self.persistent {
        obj.assertion_error = Some(copy_evaluation_error(e))
      }
      raise copy_evaluation_error(e)
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
      // Publish the cache slot before building its scope, then retain the whole
      // field computation so recursive demands execute its actual body.
      let t = self.store(Busy)
      obj.cache[cache_key] = t
      let env = if obj.layers[layer].locals.is_empty() {
        self.scope(id, layer, f.env)
      } else {
        self.layer_scope(id, layer)
      }
      self.thunks[t] = Running(FieldCall(id, layer, name, f, env, loc))
      let v = self.field_value(id, layer, name, f, env, loc) catch {
        e => self.failure(t, e)
      }
      self.thunks[t] = Ready(v)
      return v
    }
    layer -= 1
  }
  raise problem(
    if obj.standard {
      Unsupported
    } else {
      Runtime
    },
    loc,
    "Field does not exist: " + name,
  )
}

///|
fn Vm::field_value(
  self : Vm,
  id : Int,
  layer : Int,
  name : String,
  field : LayerField,
  env : Env,
  loc : Location,
) -> Value raise {
  if field.field.value.kind is StandardFunction(function_name) &&
    inherited_standard_function(function_name) &&
    !self.objects[id].standard &&
    self.has_field(id, layer, function_name) {
    // A native value cannot capture an inherited source method's final self.
    // Keep the canonical library fast, and read its source field in this object.
    return self.field(id, layer, function_name, loc)
  }
  if field.field.additive {
    self.push_frame(loc, false)
    self.current_trace = Some({
      location: Source({
        begin: field.field.value.loc,
        end: diagnostic_expr_end(field.field.value),
      }),
      name: "+:",
    })
  }
  defer (if field.field.additive { self.pop_frame() })
  let rhs = match field.field.value.kind {
    StandardFunction(_) | StandardValue(_) => self.eval(field.field.value, env)
    _ => self.eval_frame(field.field.value, env)
  }
  if field.field.additive && self.has_field(id, layer, name) {
    self.binary("+", self.field(id, layer, name, loc), rhs, loc)
  } else {
    rhs
  }
}

///|
fn Vm::assertion(
  self : Vm,
  cond : Expr,
  msg : Expr?,
  env : Env,
  failure_frame? : TraceFrame,
  condition_frame? : TraceFrame,
  default_message? : String = "Assertion failed",
) -> Unit raise {
  let condition = self.eval(cond, env)
  let holds = boolean(condition, cond.loc) catch {
    Error(d) => {
      self.current_trace = match condition_frame {
        Some(frame) => Some(frame)
        None => failure_frame
      }
      raise Error(self.traced(d))
    }
    e => raise e
  }
  if !holds {
    let events : Array[EvalHookFrame] = []
    if failure_frame is Some({ location: Source(range), .. }) {
      self.hook_before(
        {
          kind: Fail(
            msg.unwrap_or({
              kind: Literal(Json::string(default_message)),
              loc: range.begin,
              end: None,
            }),
          ),
          loc: range.begin,
          end: Some(range.end),
        },
        env,
        events,
      )
    }
    let error : Error = try {
      let message = match msg {
        Some(m) => self.coerce_string(self.eval(m, env), m.loc)
        None => default_message
      }
      if failure_frame is Some(frame) {
        self.current_trace = Some(frame)
      }
      self.trace_problem(Assertion, cond.loc, message)
    } catch {
      e => e
    }
    self.hook_after(events, None, Some(error))
    raise error
  }
}
