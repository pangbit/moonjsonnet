///|
fn Vm::eval(
  self : Vm,
  expr : Expr,
  env : Env,
  tail? : Bool = false,
  preserve_binding? : Bool = false,
) -> Value raise {
  self.tick(expr.loc)
  if self.depth >= self.limits.depth {
    raise self.trace_problem(Limit, expr.loc, "evaluation depth limit exceeded")
  }
  self.depth += 1
  defer {
    self.depth -= 1
  }
  self.eval_inner(
    expr,
    if preserve_binding {
      env
    } else {
      env.trace_context(env.diagnostic_context.0)
    },
    tail~,
  )
}

///|
fn Vm::eval_inner(
  self : Vm,
  expr : Expr,
  env : Env,
  tail~ : Bool,
) -> Value raise {
  let previous_trace = self.current_trace
  defer {
    self.current_trace = previous_trace
  }
  let events : Array[EvalHookFrame] = []
  let forwarded : Array[(Int, Location, Bool)] = []
  let result = self.eval_loop(expr, env, tail~, events~, forwarded~) catch {
    Error(d) => {
      for i = forwarded.length() - 1; i >= 0; i = i - 1 {
        d.context.push(forwarded[i].1)
      }
      let d = self.traced(d)
      self.hook_after(events, None, Some(Error(d)))
      for (id, _, _) in forwarded {
        self.thunks[id] = Failed(Error(d))
      }
      raise Error(d)
    }
    error => {
      self.hook_after(events, None, Some(error))
      raise error
    }
  }
  self.hook_after(events, Some(result), None)
  for (id, _, owner) in forwarded {
    self.thunks[id] = Ready(result)
    if owner {
      ignore(self.retries.remove(id))
    }
  }
  result
}

///|
fn Vm::eval_loop(
  self : Vm,
  expr : Expr,
  env : Env,
  tail~ : Bool,
  events~ : Array[EvalHookFrame],
  forwarded~ : Array[(Int, Location, Bool)],
) -> Value raise {
  let mut expr = expr
  let mut env = env
  let mut tail = tail
  let frame_base = self.frames.length()
  // The loop owns any strict function frame added above its entry frame.
  defer (while self.frames.length() > frame_base {
    self.pop_frame()
  })
  while true {
    if !self.hooks_suppressed &&
      self.eval_hook is Some(_) &&
      (expr.kind is ArrayComp(_, _) || expr.kind is ObjectComp(_, _, _, _)) {
      expr = debugger_lower_comprehension(expr)
    }
    self.trace_expression(expr, env)
    self.tick(expr.loc)
    self.hook_before(expr, env, events) catch {
      Error(d) => raise Error(self.traced(d))
      e => raise self.trace_problem(Runtime, expr.loc, e.to_string())
    }
    let loc = expr.loc
    return try {
      match expr.kind {
        NumberLiteral(raw) => {
          let n = @string.parse_double(raw) catch {
            _ => raise problem(Runtime, loc, "overflow")
          }
          Num(n)
        }
        Literal(j) => self.from_json(j, loc)
        Var(n) =>
          match env.lookup(n) {
            Some(t) => self.force(t, loc)
            None => raise problem(Static, loc, "unknown variable '\{n}'")
          }
        Local(bs, body) => {
          env = self.bind(bs, env, debug_expression=expr)
          expr = body
          continue
        }
        If(c, yes, no) => {
          expr = if boolean(self.eval(c, env), c.loc) { yes } else { no }
          env = env.trace_context(env.diagnostic_context.0)
          continue
        }
        Func(ps, body) => Closure(ps, body, env)
        Call(f, args, strict) => {
          let function = self.eval(f, env)
          let lowered_call = f.end is None &&
            f.kind
            is Index(
              { kind: Var("$std"), .. },
              { kind: Literal(String(_)), .. }
            )
          let thunks = args.map(pair => {
            (
              pair.0,
              self.store(
                Pending(
                  pair.1,
                  env
                  .debug_capture(if lowered_call { [expr] } else { [pair.1] })
                  .trace_thunk(),
                ),
              ),
            )
          })
          if tail &&
            self.frames.last().map(frame => frame.trimmable) == Some(true) {
            ignore(self.frames.pop())
          }
          if tail && function is Builtin("extVar") {
            self.tick(loc)
            let id = try {
              let bound = bind_arguments([("x", true)], thunks, loc)
              self.external_parameter(self.force(bound["x"], loc), loc)
            } catch {
              Error(d) => {
                d.context.push(loc)
                raise Error(d)
              }
              error => raise error
            }
            let owner = self.thunks[id] is Code(_, _) ||
              self.thunks[id] is ParsedParameter(_, _)
            if self.forward_parameter(id) is Some((next, scope)) {
              forwarded.push((id, loc, owner))
              self.push_frame(next.loc, false)
              if self.depth >= self.limits.depth {
                raise self.trace_problem(
                  Limit,
                  next.loc,
                  "evaluation depth limit exceeded",
                )
              }
              self.tick(next.loc)
              expr = next
              env = scope
              continue
            }
            return self.force(id, loc)
          }
          if strict && function is Closure(params, body, outer) {
            let scope = try {
              let scope = self.call_env(params, thunks, outer, loc, body~)
              for { name: n, .. } in params {
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
        Arr(items) =>
          ArrayValue(
            items.map(e => {
              self.store(Pending(e, env.debug_capture([e]).trace_thunk()))
            }),
          )
        Obj(fields, locals, assertions, assertion_sites) => {
          let captured = env.debug_capture([expr])
          let fs : Map[String, LayerField] = Map([])
          for f in fields {
            match self.eval(f.key, env) {
              Nil => ()
              Str(k) => {
                if fs.contains(k) {
                  raise problem(Runtime, f.key.loc, "duplicate field '\{k}'")
                }
                fs[k] = { field: f, env: captured, }
              }
              _ =>
                raise problem(
                  Type,
                  f.key.loc,
                  "field name must be string or null",
                )
            }
          }
          self.object_value([
            { fields: fs, locals, assertions, assertion_sites, env: captured, },
          ])
        }
        ArrayComp(body, clauses) => {
          let out = []
          self.comprehend_expression(expr, clauses, env, scope => {
            out.push(
              self.store(
                Pending(body, scope.debug_capture([body]).trace_thunk()),
              ),
            )
          })
          ArrayValue(out)
        }
        ObjectComp(key, body, clauses, locals) => {
          let fs : Map[String, LayerField] = Map([])
          self.comprehend_expression(expr, clauses, env, scope => {
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
                raise problem(
                  Type,
                  key.loc,
                  "field name must be string or null",
                )
            }
          })
          self.object_value([
            {
              fields: fs,
              locals: [],
              assertions: [],
              assertion_sites: [],
              env,
            },
          ])
        }
        Index(a, b) => self.index(self.eval(a, env), self.eval(b, env), loc)
        Slice(a, start, end, step) => {
          self.current_trace = Some({
            location: Source({
              begin: expr.loc,
              end: diagnostic_expr_end(expr),
            }),
            name: "",
          })
          let library = self.force(env.lookup("$std").unwrap(), loc)
          let function = self.index(library, Str("slice"), loc)
          let argument_env = env.trace_context("")
          let arguments = [Some(a), start, end, step].map(expression => {
            let thunk = match expression {
              Some(expression) =>
                self.store(
                  Pending(expression, argument_env.debug_capture([expression])),
                )
              None => self.store(Ready(Nil))
            }
            (None, thunk)
          })
          self.call(function, arguments, loc)
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
          self.assertion(
            c,
            m,
            env,
            condition_frame={ location: Synthetic(""), name: "", },
            failure_frame={
              location: Source({
                begin: expr.loc,
                end: diagnostic_expr_end(expr),
              }),
              name: "",
            },
          )
          expr = body
          env = env.trace_context(env.diagnostic_context.0)
          continue
        }
        Fail(e) =>
          raise problem(
            Runtime,
            loc,
            self.coerce_string(self.eval(e, env), loc),
          )
        ImportFile(path, raw) =>
          self.import_file(path, raw, env.import_from, loc)
        ImportBinary(path) => self.import_binary(path, env.import_from, loc)
        StandardFunction(name) => Builtin(name)
        StandardValue(json) => self.from_json(json, loc)
      }
    } catch {
      Error(d) => raise Error(self.traced(d))
      e => raise self.trace_problem(Runtime, loc, e.to_string())
    }
  } nobreak {
    abort("unreachable evaluator loop")
  }
}

///|
fn Vm::comprehend_expression(
  self : Vm,
  expression : Expr,
  clauses : Array[Clause],
  environment : Env,
  emit : (Env) -> Unit raise,
) -> Unit raise {
  // Go lowers a comprehension to a call at the whole expression's range.
  // Its input/condition/key evaluation has a clean frame under that call.
  self.with_trace(
    Source({ begin: expression.loc, end: diagnostic_expr_end(expression), }),
    () => {
      self.push_frame(expression.loc, false)
      defer self.pop_frame()
      self.comprehend(clauses, 0, environment, expression.loc, emit) catch {
        Error(d) => raise Error(self.traced(d))
        e => raise e
      }
    },
  )
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
      let env = self.call_env(params, args, outer, loc, body~)
      if strict {
        for { name: n, .. } in params {
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
  params : Array[ExprParameter],
  args : Array[(String?, Int)],
  outer : Env,
  loc : Location,
  body? : Expr,
) -> Env raise {
  let roots = params.filter_map(p => p.default_value)
  if body is Some(body) {
    roots.push(body)
  }
  let env = outer
    .debug_capture(roots, bound=params.map(p => p.name))
    .child()
    .trace_context("function <" + outer.diagnostic_context.1 + ">")
  let assigned = bind_arguments(
    params.map(p => (p.name, p.default_value is None)),
    args,
    loc,
  )
  for name, thunk in assigned {
    env.names[name] = thunk
  }
  for { name: n, default_value: d, .. } in params {
    if !env.names.contains(n) && d is Some(e) {
      env.names[n] = self.store(Pending(e, env))
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
  let n = reference_int64(number)
  if n < 0L || n >= length.to_int64() {
    raise problem(
      Runtime,
      loc,
      "Index \{n} out of bounds, not within [0, \{length})",
    )
  }
  n.to_int()
}
