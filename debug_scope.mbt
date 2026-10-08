///|
priv struct DebugBoundScope {
  names : Map[String, Unit]
  parent : DebugBoundScope?
}

///|
fn DebugBoundScope::child(
  self : DebugBoundScope,
  names : Array[String],
  tick : () -> Unit raise,
) -> DebugBoundScope raise {
  {
    names: Map(
      names.map(name => {
        tick()
        (name, ())
      }),
    ),
    parent: Some(self),
  }
}

///|
fn DebugBoundScope::contains(
  self : DebugBoundScope,
  name : String,
  tick : () -> Unit raise,
) -> Bool raise {
  let mut next = Some(self)
  while next is Some(scope) {
    tick()
    if scope.names.contains(name) {
      return true
    }
    next = scope.parent
  }
  false
}

///|
// The debugger projects captured scopes without changing interpreter lookup or
// thunk lifetime. Compute lazily only when a host actually requests variables.
fn debug_visibility(
  roots : Array[Expr],
  bound : Array[String],
  extra : Array[String],
  in_object : Bool,
) -> (() -> Unit raise) -> Array[String] raise {
  let saved : Ref[Array[String]?] = Ref(None)
  fn(tick) raise {
    if saved.val is Some(names) {
      return names
    }
    let initial : DebugBoundScope = {
      names: Map(
        bound.map(name => {
          tick()
          (name, ())
        }),
      ),
      parent: None,
    }
    let work = roots.map(root => (root, initial, in_object))
    let free : Map[String, Unit] = Map(
      extra.map(name => {
        tick()
        (name, ())
      }),
    )
    let push_clauses = fn(
      clauses : Array[Clause],
      outer : DebugBoundScope,
      in_object : Bool,
    ) raise {
      let mut scope = outer
      for clause in clauses {
        match clause {
          For(name, expr) => {
            work.push((expr, scope, in_object))
            scope = scope.child([name], tick)
          }
          When(expr) => work.push((expr, scope, in_object))
        }
      }
      scope
    }
    while work.pop() is Some((node, scope, in_object)) {
      tick()
      match node.kind {
        Var(name) =>
          if name != "self" && name != "super" && !scope.contains(name, tick) {
            free[name] = ()
          }
        Local(bindings, body) => {
          let inner = scope.child(bindings.map(b => b.name), tick)
          work.push((body, inner, in_object))
          for binding in bindings {
            work.push((binding.value, inner, in_object))
          }
        }
        Func(params, body) => {
          let inner = scope.child(params.map(p => p.name), tick)
          work.push((body, inner, in_object))
          for parameter in params {
            if parameter.default_value is Some(value) {
              work.push((value, inner, in_object))
            }
          }
        }
        Obj(fields, locals, assertions) => {
          let bound = locals.map(b => b.name)
          if !in_object {
            bound.push("$")
          }
          let inner = scope.child(bound, tick)
          for field in fields {
            work.push((field.key, scope, in_object))
            work.push((field.value, inner, true))
          }
          for binding in locals {
            work.push((binding.value, inner, true))
          }
          for (condition, message) in assertions {
            work.push((condition, inner, true))
            if message is Some(value) {
              work.push((value, inner, true))
            }
          }
        }
        ArrayComp(body, clauses) => {
          free["$std"] = ()
          work.push((body, push_clauses(clauses, scope, in_object), in_object))
        }
        ObjectComp(key, body, clauses, locals) => {
          free["$std"] = ()
          let outer = push_clauses(clauses, scope, in_object)
          work.push((key, outer, in_object))
          let bound = locals.map(b => b.name)
          if !in_object {
            bound.push("$")
          }
          let inner = outer.child(bound, tick)
          work.push((body, inner, true))
          for binding in locals {
            work.push((binding.value, inner, true))
          }
        }
        Slice(_, _, _, _) | Binary("%", _, _) => {
          free["$std"] = ()
          for child in ast_export_children(node) {
            work.push((child, scope, in_object))
          }
        }
        _ =>
          for child in ast_export_children(node) {
            work.push((child, scope, in_object))
          }
      }
    }
    let names = free.keys().collect()
    names.sort_by(compare_unicode)
    saved.val = Some(names)
    names
  }
}

///|
fn Env::debug_capture(
  self : Env,
  roots : Array[Expr],
  bound? : Array[String] = [],
  extra? : Array[String] = [],
) -> Env {
  {
    ..self,
    debug_visible: Some(
      debug_visibility(roots, bound, extra, self.lookup("self") is Some(_)),
    ),
  }
}
