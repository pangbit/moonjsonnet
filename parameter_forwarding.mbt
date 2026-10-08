///|
// A returned extVar call can enter its code in the evaluator's existing loop.
// Keep each real clean frame, while avoiding physical recursion for forwarding
// chains. Non-tail calls retain their expression-depth and busy-thunk checks.
fn Vm::forward_parameter(self : Vm, id : Int) -> (Expr, Env)? raise {
  let original = self.thunks[id]
  if original is RunningParameter(expression, environment) {
    return Some((expression, environment))
  }
  if !(original is Code(_, _) || original is ParsedParameter(_, _)) {
    return None
  }
  if self.persistent {
    self.retries[id] = original
  }
  let (expression, environment) = try {
    match original {
      Code(source, origin) => {
        if @utf8.encode(source).length() > self.limits.source_bytes {
          raise problem(Limit, origin, "parameter source byte limit exceeded")
        }
        let expression = parse(source, origin.file, self.limits.depth)
        (expression, self.base_env(file=origin.file, import_from=""))
      }
      ParsedParameter(program, origin) => {
        if program.source_bytes > self.limits.source_bytes {
          raise problem(Limit, origin, "parameter source byte limit exceeded")
        }
        check_ast_depth(program.expression, self.limits.depth)
        (
          program.expression,
          self.base_env(
            file=origin.file,
            import_from=if program.anonymous { "" } else { program.filename },
          ),
        )
      }
      _ => abort("parameter forwarding requires code")
    }
  } catch {
    error => self.failure(id, error)
  }
  self.thunks[id] = RunningParameter(expression, environment)
  Some((expression, environment))
}

///|
fn Vm::external_parameter(self : Vm, name : Value, loc : Location) -> Int raise {
  let name = text_value(name, loc)
  match self.ext.get(name) {
    Some(id) => id
    None => raise problem(Runtime, loc, "Undefined external variable: " + name)
  }
}
