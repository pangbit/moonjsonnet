///|
fn LintGraph::check_args(
  self : LintGraph,
  params : Array[(String, Bool)],
  args : Array[(String?, Expr)],
  loc : Location,
) -> Unit {
  let received : Map[String, Bool] = Map([])
  let positional = args.filter(a => a.0 is None)
  for i, (_, value) in positional {
    if i < params.length() {
      received[params[i].0] = true
    } else {
      self.scan.report(
        value.loc,
        "Too many arguments, there can be at most \{params.length()}, but \{positional.length()} provided",
      )
    }
  }
  for (name, value) in args {
    if name is Some(name) {
      if received.contains(name) {
        self.scan.report(value.loc, "Argument \{name} already provided")
        return
      }
      if !params.any(p => p.0 == name) {
        self.scan.report(value.loc, "function has no parameter \{name}")
        return
      }
      received[name] = true
    }
  }
  for (name, optional) in params {
    if !optional && !received.contains(name) {
      self.scan.report(loc, "Missing argument: \{name}")
      return
    }
  }
}

///|
fn LintGraph::check(
  self : LintGraph,
  node : LintTyped,
  untyped? : Bool = false,
) -> Unit raise JsonnetError {
  self.scan.tick(node.expression)
  for child in node.children {
    self.check(child, untyped~)
  }
  let e = node.expression
  let report = fn(message) { self.scan.report(e.loc, message) }
  let child = fn(index) {
    self.bounds[if untyped { 0 } else { node.children[index].id }]
  }
  match e.kind {
    Call(_, args, _) => {
      let t = child(0)
      match t.func {
        None =>
          report(
            "Called value must be a function, but it is assumed to be " +
            t.describe(),
          )
        Some(f) =>
          match f.params {
            Some(params) => self.check_args(params, args, e.loc)
            None => {
              if f.min > args.length() {
                report(
                  "Too few arguments: got \{args.length()}, but expected at least \{f.min}",
                )
              }
              if f.max < args.length() {
                report(
                  "Too many arguments: got \{args.length()}, but expected at most \{f.max}",
                )
              }
            }
          }
      }
    }
    Index({ kind: Var("super"), .. }, _) => ()
    Index(_, key) => {
      let target = child(0)
      let index = child(1)
      let array = target.array is Some(_)
      let object = target.object is Some(_)
      let string = (target.mask & 4) != 0
      if !array && !object && !string {
        report("Indexed value is neither an array nor an object nor a string")
      } else if !object {
        let assumed = if array && string {
          "an array or a string"
        } else if array {
          "an array"
        } else {
          "a string"
        }
        if (index.mask & 2) == 0 {
          report(
            "Indexed value is assumed to be " +
            assumed +
            ", but index is not a number",
          )
        }
      } else if !array && !string {
        if (index.mask & 4) == 0 {
          report(
            "Indexed value is assumed to be an object, but index is not a string",
          )
        }
        if target.object is Some(o) &&
          o.known &&
          key.kind is Literal(String(name)) &&
          !o.fields.contains(name) {
          report("Indexed object has no field " + lint_quote(name))
        }
      } else if (index.mask & 6) == 0 {
        report(
          "Index is neither a number (for indexing arrays and string) nor a string (for indexing objects)",
        )
      }
    }
    Unary(op, _) => {
      let t = child(0)
      if op == "!" {
        if (t.mask & 1) == 0 {
          report(
            "Operand is not a boolean, it is assumed to be " + t.describe(),
          )
        }
      } else if (t.mask & 2) == 0 {
        report("Operand is not a number, it is assumed to be " + t.describe())
      }
    }
    _ => ()
  }
}
