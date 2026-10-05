///|
fn Vm::eval(
  self : Vm,
  expr : Expr,
  env : Env,
  tail? : Bool = false,
) -> Value raise {
  self.tick(expr.loc)
  if self.depth >= self.limits.depth {
    raise problem(Limit, expr.loc, "evaluation depth limit exceeded")
  }
  self.depth += 1
  defer {
    self.depth -= 1
  }
  self.eval_inner(expr, env, tail~)
}

///|
fn Vm::eval_inner(
  self : Vm,
  expr : Expr,
  env : Env,
  tail~ : Bool,
) -> Value raise {
  let mut expr = expr
  let mut env = env
  let mut tail = tail
  let frame_base = self.frames.length()
  // The loop owns any strict function frame added above its entry frame.
  defer (while self.frames.length() > frame_base {
    ignore(self.frames.pop())
  })
  while true {
    self.tick(expr.loc)
    let loc = expr.loc
    return match expr.kind {
      Literal(j) => self.from_json(j, loc)
      Var(n) =>
        match env.lookup(n) {
          Some(t) => self.force(t, loc)
          None => raise problem(Static, loc, "unknown variable '\{n}'")
        }
      Local(bs, body) => {
        env = self.bind(bs, env)
        expr = body
        continue
      }
      If(c, yes, no) => {
        expr = if boolean(self.eval(c, env), c.loc) { yes } else { no }
        continue
      }
      Func(ps, body) => Closure(ps, body, env)
      Call(f, args, strict) => {
        let function = self.eval(f, env)
        let thunks = args.map(pair => (pair.0, self.store(Pending(pair.1, env))))
        if tail && self.frames.last() == Some(true) {
          ignore(self.frames.pop())
        }
        if strict && function is Closure(params, body, outer) {
          let scope = try {
            let scope = self.call_env(params, thunks, outer, loc)
            for (n, _) in params {
              ignore(self.force(scope.names[n], loc))
            }
            scope
          } catch {
            Error(d) => {
              d.context.push(loc)
              raise Error(d)
            }
            e => raise e
          }
          expr = body
          env = scope
          self.push_frame(loc, true)
          tail = true
          continue
        }
        self.call(function, thunks, loc, strict~) catch {
          Error(d) => {
            d.context.push(loc)
            raise Error(d)
          }
          e => raise e
        }
      }
      Arr(items) => ArrayValue(items.map(e => self.store(Pending(e, env))))
      Obj(fields, locals, assertions) => {
        let fs : Map[String, LayerField] = Map([])
        for f in fields {
          match self.eval(f.key, env) {
            Nil => ()
            Str(k) => {
              if fs.contains(k) {
                raise problem(Runtime, f.key.loc, "duplicate field '\{k}'")
              }
              fs[k] = { field: f, env, }
            }
            _ =>
              raise problem(
                Type,
                f.key.loc,
                "field name must be string or null",
              )
          }
        }
        self.object_value([{ fields: fs, locals, assertions, env, }])
      }
      ArrayComp(body, clauses) => {
        let out = []
        self.comprehend(clauses, 0, env, loc, scope => {
          out.push(self.store(Pending(body, scope)))
        })
        ArrayValue(out)
      }
      ObjectComp(key, body, clauses, locals) => {
        let fs : Map[String, LayerField] = Map([])
        self.comprehend(clauses, 0, env, loc, scope => {
          match self.eval(key, scope) {
            Nil => ()
            Str(k) => {
              if fs.contains(k) {
                raise problem(Runtime, key.loc, "duplicate field '\{k}'")
              }
              fs[k] = {
                field: {
                  key,
                  value: {
                    kind: Local(locals, body),
                    loc: body.loc,
                    end: body.end,
                  },
                  visibility: 1,
                  additive: false,
                },
                env: scope,
              }
            }
            _ =>
              raise problem(Type, key.loc, "field name must be string or null")
          }
        })
        self.object_value([{ fields: fs, locals: [], assertions: [], env, }])
      }
      Index(a, b) => self.index(self.eval(a, env), self.eval(b, env), loc)
      Slice(a, start, end, step) => {
        let v = self.eval(a, env)
        let bound = fn(e : Expr?) raise {
          match e {
            Some(x) => self.eval(x, env)
            None => Nil
          }
        }
        self.slice(v, bound(start), bound(end), bound(step), loc)
      }
      Unary(op, e) => {
        let v = self.eval(e, env)
        match op {
          "!" => Bool(!boolean(v, loc))
          "-" => Num(-number_value(v, loc))
          "+" => Num(number_value(v, loc))
          _ => Num(reference_int64(number_value(v, loc)).lnot().to_double())
        }
      }
      Binary(op, a, b) => {
        let left = self.eval(a, env)
        if op == "&&" {
          Bool(boolean(left, loc) && boolean(self.eval(b, env), loc))
        } else if op == "||" {
          Bool(boolean(left, loc) || boolean(self.eval(b, env), loc))
        } else {
          self.binary(op, left, self.eval(b, env), loc)
        }
      }
      Assert(c, m, body) => {
        self.assertion(c, m, env)
        expr = body
        continue
      }
      Fail(e) => raise problem(Runtime, loc, text_value(self.eval(e, env), loc))
      ImportFile(path, raw) => self.import_file(path, raw, env.import_from, loc)
      ImportBinary(path) => self.import_binary(path, env.import_from, loc)
      StandardFunction(name) => Builtin(name)
      StandardValue(json) => self.from_json(json, loc)
    }
  } nobreak {
    abort("unreachable evaluator loop")
  }
}

///|
fn Vm::comprehend(
  self : Vm,
  clauses : Array[Clause],
  index : Int,
  env : Env,
  loc : Location,
  emit : (Env) -> Unit raise,
) -> Unit raise {
  self.tick(loc)
  if index >= self.limits.depth {
    raise problem(Limit, loc, "comprehension depth limit exceeded")
  }
  if index == clauses.length() {
    emit(env)
    return
  }
  match clauses[index] {
    For(n, expr) => {
      let a = array_value(self.eval(expr, env), expr.loc)
      for t in a {
        let scope = env.child()
        scope.names[n] = t
        self.comprehend(clauses, index + 1, scope, loc, emit)
      }
    }
    When(expr) =>
      if boolean(self.eval(expr, env), expr.loc) {
        self.comprehend(clauses, index + 1, env, loc, emit)
      }
  }
}

///|
fn Vm::call(
  self : Vm,
  function : Value,
  args : Array[(String?, Int)],
  loc : Location,
  strict? : Bool = false,
) -> Value raise {
  self.tick(loc)
  match function {
    Native(f) => self.call_native(f, args, loc)
    Builtin(name) => self.builtin(name, args, loc)
    Closure(params, body, outer) => {
      let env = self.call_env(params, args, outer, loc)
      if strict {
        for (n, _) in params {
          ignore(self.force(env.names[n], loc))
        }
      }
      self.eval_frame(body, env, trimmable=strict)
    }
    _ => raise problem(Type, loc, "expected function")
  }
}

///|
fn Vm::call_env(
  self : Vm,
  params : Array[(String, Expr?)],
  args : Array[(String?, Int)],
  outer : Env,
  loc : Location,
) -> Env raise {
  let env = outer.child()
  let assigned : Map[String, Bool] = Map([])
  for i, (name, t) in args {
    let n = match name {
      Some(n) => {
        if !params.any(p => p.0 == n) {
          raise problem(Runtime, loc, "unknown argument '\{n}'")
        }
        n
      }
      None => {
        if i >= params.length() {
          raise problem(Runtime, loc, "too many arguments")
        }
        params[i].0
      }
    }
    if assigned.contains(n) {
      raise problem(Runtime, loc, "duplicate argument '\{n}'")
    }
    assigned[n] = true
    env.names[n] = t
  }
  for (n, d) in params {
    if !assigned.contains(n) {
      match d {
        Some(e) => env.names[n] = self.store(Pending(e, env))
        None => raise problem(Runtime, loc, "missing argument '\{n}'")
      }
    }
  }
  env
}

///|
fn Vm::index(
  self : Vm,
  target : Value,
  key : Value,
  loc : Location,
) -> Value raise {
  match target {
    ObjectValue(id, top) => self.field(id, top, text_value(key, loc), loc)
    ArrayValue(a) => {
      let i = array_index(key, a.length(), loc)
      self.force(a[i], loc)
    }
    Str(s) => {
      let chars = s.to_array()
      let i = array_index(key, chars.length(), loc)
      Str(chars[i].to_string())
    }
    _ => raise problem(Type, loc, "expected object, array or string")
  }
}

///|
fn array_index(key : Value, length : Int, loc : Location) -> Int raise {
  let number = number_value(key, loc)
  let n = if number.is_nan() { 0.0 } else { number.trunc() }
  if n < 0 || n >= length.to_double() {
    raise problem(Runtime, loc, "index out of bounds")
  }
  n.to_int()
}
