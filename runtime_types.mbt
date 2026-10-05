///|
priv enum Value {
  Nil
  Bool(Bool)
  Num(Double)
  Str(String)
  ArrayValue(Array[Int])
  ObjectValue(Int, Int)
  Closure(Array[(String, Expr?)], Expr, Env)
  Builtin(String)
  Native(NativeFunction)
}

///|
priv struct Env {
  parent : Env?
  names : Map[String, Int]
  import_from : String
}

///|
fn Env::child(self : Env) -> Env {
  { parent: Some(self), names: Map([]), import_from: self.import_from, }
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
  Code(String, Location)
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
  locals : Array[(String, Expr)]
  assertions : Array[(Expr, Expr?)]
  env : Env
}

///|
priv struct ObjectData {
  layers : Array[Layer]
  cache : Map[(Int, String), Int]
  scopes : Map[Int, Env]
  mut assertion_state : Int
  mut standard : Bool
}

///|
priv struct Vm {
  library : Expr
  thunks : Array[Thunk]
  objects : Array[ObjectData]
  limits : Limits
  ext : Map[String, Int]
  native_functions : Map[String, NativeFunction]
  trace : (Location, String) -> Unit
  resolver : ((String, String) -> Source raise)?
  binary_resolver : ((String, String) -> BinarySource raise)?
  binary_sources : Map[(String, String), BinarySource]
  binary_imports : Map[String, Int]
  sources : Map[(String, String), Source]
  imports : Map[(String, Bool), Int]
  mut steps : Int
  mut depth : Int
  frames : Array[Bool]
  mut imported_bytes : Int
  mut output_bytes : Int
}

///|
fn Vm::tick(self : Vm, loc : Location) -> Unit raise {
  if self.steps >= self.limits.steps {
    raise problem(Limit, loc, "evaluation step limit exceeded")
  }
  self.steps += 1
}

///|
fn Vm::store(self : Vm, t : Thunk) -> Int {
  let id = self.thunks.length()
  self.thunks.push(t)
  id
}

///|
fn Vm::force(self : Vm, id : Int, loc : Location) -> Value raise {
  self.tick(loc)
  match self.thunks[id] {
    Ready(v) => v
    Busy => raise problem(Runtime, loc, "cyclic evaluation of a lazy value")
    Failed(e) => raise e
    Pending(expr, env) => {
      self.thunks[id] = Busy
      let v = self.eval_frame(expr, env) catch { e => self.failure(id, e) }
      self.thunks[id] = Ready(v)
      v
    }
    Code(source, origin) => {
      self.thunks[id] = Busy
      let v = try {
        if @utf8.encode(source).length() > self.limits.source_bytes {
          raise problem(Limit, origin, "parameter source byte limit exceeded")
        }
        let expr = parse(source, origin.file, self.limits.depth)
        self.eval_frame(expr, self.base_env(file=origin.file, import_from=""))
      } catch {
        e => self.failure(id, e)
      }
      self.thunks[id] = Ready(v)
      v
    }
  }
}

///|
fn Vm::failure(self : Vm, id : Int, error : Error) -> Value raise {
  self.thunks[id] = Failed(error)
  raise error
}

///|
fn Vm::bind(self : Vm, bindings : Array[(String, Expr)], outer : Env) -> Env {
  let env = outer.child()
  for (name, expr) in bindings {
    env.names[name] = self.store(Pending(expr, env))
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
      let env : Env = { parent: None, names: Map([]), import_from: "", }
      let fs : Map[String, LayerField] = Map([])
      for k, v in o {
        fs[k] = {
          field: {
            key: { kind: Literal(Json::string(k)), loc, },
            value: { kind: Literal(v), loc, },
            visibility: 1,
            additive: false,
          },
          env,
        }
      }
      self.object_value([{ fields: fs, locals: [], assertions: [], env, }])
    }
  }
}

///|
fn finite(n : Double, loc : Location) -> Value raise {
  if n.is_inf() || n.is_nan() {
    raise problem(Runtime, loc, "non-finite numeric result")
  }
  Num(n)
}

///|
fn boolean(v : Value, loc : Location) -> Bool raise {
  match v {
    Bool(b) => b
    _ => raise problem(Type, loc, "expected boolean")
  }
}

///|
fn text_value(v : Value, loc : Location) -> String raise {
  match v {
    Str(s) => s
    _ => raise problem(Type, loc, "expected string")
  }
}

///|
fn number_value(v : Value, loc : Location) -> Double raise {
  match v {
    Num(n) => n
    _ => raise problem(Type, loc, "expected number")
  }
}

///|
fn array_value(v : Value, loc : Location) -> Array[Int] raise {
  match v {
    ArrayValue(a) => a
    _ => raise problem(Type, loc, "expected array")
  }
}
