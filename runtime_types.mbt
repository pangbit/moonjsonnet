///|
priv enum Value {
  Nil
  Bool(Bool)
  Num(Double)
  Str(String)
  ArrayValue(Array[Int])
  ObjectValue(Int, Int)
  Closure(Array[ExprParameter], Expr, Env)
  Builtin(String)
  Native(NativeFunction)
}

///|
priv struct Env {
  parent : Env?
  names : Map[String, Int]
  import_from : String
  debug_visible : ((() -> Unit raise) -> Array[String] raise)?
  diagnostic_context : (String, String)
  diagnostic_suppressed : Bool
}

///|
fn Env::child(self : Env) -> Env {
  {
    parent: Some(self),
    names: Map([]),
    import_from: self.import_from,
    debug_visible: None,
    diagnostic_context: self.diagnostic_context,
    diagnostic_suppressed: self.diagnostic_suppressed,
  }
}

///|
fn Env::lookup(self : Env, name : String) -> Int? {
  match self.names.get(name) {
    Some(id) => Some(id)
    None =>
      match self.parent {
        Some(p) => p.lookup(name)
        None => None
      }
  }
}

///|
priv enum Thunk {
  Pending(Expr, Env)
  GeneratedCall(Value, Array[Int], Location)
  FieldCall(Int, Int, String, LayerField, Env, Location)
  Code(String, Location)
  ParsedParameter(Program, Location)
  RunningParameter(Expr, Env)
  Running(Thunk)
  Ready(Value)
  Busy
  Failed(Error)
}

///|
priv struct LayerField {
  field : Field
  env : Env
}

///|
priv struct Layer {
  fields : Map[String, LayerField]
  locals : Array[ExprBinding]
  assertions : Array[(Expr, Expr?)]
  assertion_sites : Array[SourceRange?]
  env : Env
}

///|
priv struct ObjectData {
  layers : Array[Layer]
  cache : Map[(Int, String), Int]
  scopes : Map[Int, Env]
  mut assertion_state : Int
  mut assertion_error : Error?
  mut standard : Bool
}

///|
priv struct Vm {
  library : Expr
  thunks : Array[Thunk]
  objects : Array[ObjectData]
  free_thunks : Array[Int]
  free_objects : Array[Int]
  persistent : Bool
  retries : Map[Int, Thunk]
  accessed_sources : Map[(String, String, Bool), Unit]
  parsed_imports : Map[String, Expr]
  limits : Limits
  ext : Map[String, Int]
  native_functions : Map[String, NativeFunction]
  trace : (Location, String) -> Unit
  eval_hook : EvalHook?
  mut hooks_suppressed : Bool
  hook_stack : Array[EvalHookFrame]
  mut hook_serial : Int
  mut hook_failure_environment : Env?
  resolver : ((String, String) -> Source raise)?
  binary_resolver : ((String, String) -> BinarySource raise)?
  binary_sources : Map[(String, String), BinarySource]
  binary_imports : Map[String, Int]
  sources : Map[(String, String), Source]
  imports : Map[(String, Bool), Int]
  mut steps : Int
  mut depth : Int
  frames : Array[RuntimeFrame]
  mut current_trace : TraceFrame?
  mut imported_bytes : Int
  mut output_bytes : Int
}

///|
fn Vm::tick(self : Vm, loc : Location) -> Unit raise {
  if self.steps >= self.limits.steps {
    raise self.trace_problem(Limit, loc, "evaluation step limit exceeded")
  }
  self.steps += 1
}

///|
fn Vm::store(self : Vm, t : Thunk) -> Int {
  if self.free_thunks.pop() is Some(id) {
    self.thunks[id] = t
    return id
  }
  let id = self.thunks.length()
  self.thunks.push(t)
  id
}

///|
fn Vm::force(self : Vm, id : Int, loc : Location) -> Value raise {
  self.tick(loc)
  let thunk = self.thunks[id]
  self.force_thunk(
    id,
    thunk,
    loc,
    owner=!(thunk is Running(_) || thunk is RunningParameter(_, _)),
  )
}

///|
// Re-enter the original computation, retaining its real frame and ordinary
// depth/step budgets. A running marker is never substituted with a fake limit.
fn Vm::force_thunk(
  self : Vm,
  id : Int,
  thunk : Thunk,
  loc : Location,
  owner~ : Bool,
) -> Value raise {
  match thunk {
    Ready(v) => v
    Busy => raise problem(Runtime, loc, "cyclic evaluation of a lazy value")
    Running(original) => self.force_thunk(id, original, loc, owner=false)
    RunningParameter(expr, env) => {
      let value = self.eval_frame(expr, env) catch { e => self.failure(id, e) }
      self.thunks[id] = Ready(value)
      if owner {
        ignore(self.retries.remove(id))
      }
      value
    }
    Failed(e) => raise e
    Pending(expr, env) => {
      if self.persistent && !self.retries.contains(id) {
        self.retries[id] = thunk
      }
      self.thunks[id] = Running(thunk)
      let v = self.eval_frame(expr, env) catch { e => self.failure(id, e) }
      self.thunks[id] = Ready(v)
      if owner {
        ignore(self.retries.remove(id))
      }
      v
    }
    GeneratedCall(function, args, origin) => {
      if self.persistent && !self.retries.contains(id) {
        self.retries[id] = thunk
      }
      self.thunks[id] = Running(thunk)
      let v = try {
        self.push_frame(origin, false)
        defer self.pop_frame()
        if self.depth >= self.limits.depth {
          raise self.trace_problem(
            Limit,
            origin,
            "evaluation depth limit exceeded",
          )
        }
        self.depth += 1
        defer {
          self.depth -= 1
        }
        self.tick(origin)
        self.current_trace = Some({ location: Synthetic(""), name: "", })
        self.call(function, args.map(arg => (None, arg)), origin) catch {
          Error(d) => raise Error(self.traced(d))
          e => raise self.trace_problem(Runtime, origin, e.to_string())
        }
      } catch {
        e => self.failure(id, e)
      }
      self.thunks[id] = Ready(v)
      if owner {
        ignore(self.retries.remove(id))
      }
      v
    }
    FieldCall(object, layer, name, field, env, origin) => {
      let value = self.field_value(object, layer, name, field, env, origin) catch {
        e => self.failure(id, e)
      }
      self.thunks[id] = Ready(value)
      value
    }
    Code(source, origin) => {
      if self.persistent {
        self.retries[id] = self.thunks[id]
      }
      self.thunks[id] = Busy
      let v = try {
        if @utf8.encode(source).length() > self.limits.source_bytes {
          raise problem(Limit, origin, "parameter source byte limit exceeded")
        }
        let expr = parse(source, origin.file, self.limits.depth)
        let env = self.base_env(file=origin.file, import_from="")
        self.thunks[id] = RunningParameter(expr, env)
        self.eval_frame(expr, env)
      } catch {
        e => self.failure(id, e)
      }
      self.thunks[id] = Ready(v)
      if owner {
        ignore(self.retries.remove(id))
      }
      v
    }
    ParsedParameter(program, origin) => {
      if self.persistent {
        self.retries[id] = self.thunks[id]
      }
      self.thunks[id] = Busy
      let v = try {
        if program.source_bytes > self.limits.source_bytes {
          raise problem(Limit, origin, "parameter source byte limit exceeded")
        }
        check_ast_depth(program.expression, self.limits.depth)
        let env = self.base_env(
          file=origin.file,
          import_from=if program.anonymous { "" } else { program.filename },
        )
        self.thunks[id] = RunningParameter(program.expression, env)
        self.eval_frame(program.expression, env)
      } catch {
        e => self.failure(id, e)
      }
      self.thunks[id] = Ready(v)
      if owner {
        ignore(self.retries.remove(id))
      }
      v
    }
  }
}

///|
fn[T] Vm::failure(self : Vm, id : Int, error : Error) -> T raise {
  self.thunks[id] = Failed(error)
  raise error
}

///|
fn Vm::bind(
  self : Vm,
  bindings : Array[ExprBinding],
  outer : Env,
  debug_expression? : Expr,
) -> Env {
  let env = outer.child()
  let captured = match debug_expression {
    Some(expression) =>
      env.debug_capture([expression], extra=bindings.map(b => b.name))
    None => env
  }
  for { name, value: expr, .. } in bindings {
    let captured = if debug_expression is Some(_) {
      captured.trace_context(
        "thunk <" + name + "> from <" + outer.diagnostic_context.0 + ">",
        bound=name,
      )
    } else {
      captured
    }
    env.names[name] = self.store(Pending(expr, captured))
  }
  env
}

///|
fn Vm::from_json(self : Vm, json : Json, loc : Location) -> Value raise {
  if self.depth >= self.limits.depth {
    raise problem(Limit, loc, "JSON value depth limit exceeded")
  }
  self.depth += 1
  defer {
    self.depth -= 1
  }
  self.tick(loc)
  match json {
    Null => Nil
    True => Bool(true)
    False => Bool(false)
    Number(n, ..) => finite(n, loc)
    String(s) => Str(s)
    Array(a) =>
      ArrayValue(a.map(x => self.store(Ready(self.from_json(x, loc)))))
    Object(o) => {
      let env : Env = {
        parent: None,
        names: Map([]),
        import_from: "",
        debug_visible: None,
        diagnostic_context: ("$", "anonymous"),
        diagnostic_suppressed: false,
      }
      let fs : Map[String, LayerField] = Map([])
      for k, v in o {
        fs[k] = {
          field: {
            key: { kind: Literal(Json::string(k)), loc, end: None, },
            value: { kind: Literal(v), loc, end: None, },
            visibility: 1,
            additive: false,
          },
          env,
        }
      }
      self.object_value([
        { fields: fs, locals: [], assertions: [], assertion_sites: [], env, },
      ])
    }
  }
}

///|
fn finite(n : Double, loc : Location) -> Value raise {
  if n.is_nan() {
    raise problem(Runtime, loc, "Not a number")
  }
  if n.is_inf() {
    raise problem(Runtime, loc, "Overflow")
  }
  Num(n)
}

///|
fn boolean(v : Value, loc : Location) -> Bool raise {
  match v {
    Bool(b) => b
    _ =>
      raise problem(
        Type,
        loc,
        "Unexpected type " + value_type(v) + ", expected boolean",
      )
  }
}

///|
fn text_value(v : Value, loc : Location) -> String raise {
  match v {
    Str(s) => s
    _ =>
      raise problem(
        Type,
        loc,
        "Unexpected type " + value_type(v) + ", expected string",
      )
  }
}

///|
fn number_value(v : Value, loc : Location) -> Double raise {
  match v {
    Num(n) => n
    _ =>
      raise problem(
        Type,
        loc,
        "Unexpected type " + value_type(v) + ", expected number",
      )
  }
}

///|
fn array_value(v : Value, loc : Location) -> Array[Int] raise {
  match v {
    ArrayValue(a) => a
    _ =>
      raise problem(
        Type,
        loc,
        "Unexpected type " + value_type(v) + ", expected array",
      )
  }
}
