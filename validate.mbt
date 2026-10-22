///|
fn binding_scope(
  bindings : Array[ExprBinding],
  names : Array[String],
  loc : Location,
) -> Array[String] raise Error {
  let result = names.copy()
  let seen : Map[String, Bool] = Map([])
  for { name: n, .. } in bindings {
    if seen.contains(n) {
      raise problem(Static, loc, "duplicate binding '\{n}'")
    }
    seen[n] = true
    result.push(n)
  }
  result
}

///|
fn validate(
  e : Expr,
  names : Array[String],
  in_object : Bool,
) -> Unit raise Error {
  match e.kind {
    Literal(_)
    | NumberLiteral(_)
    | ImportFile(_, _)
    | ImportBinary(_)
    | StandardFunction(_)
    | StandardValue(_) => ()
    Var(n) => {
      if n == "super" {
        raise problem(
          Static,
          e.loc,
          "super requires field access or the in operator",
        )
      }
      if n == "self" && in_object {
        return
      }
      if !names.contains(n) {
        raise problem(Static, e.loc, "Unknown variable: \{n}")
      }
    }
    Local(bs, body) => {
      let scope = binding_scope(bs, names, e.loc)
      for { value: v, .. } in bs {
        validate(v, scope, in_object)
      }
      validate(body, scope, in_object)
    }
    Func(ps, body) => {
      let scope = names.copy()
      let seen : Map[String, Bool] = Map([])
      for p in ps {
        if seen.contains(p.name) {
          raise problem(
            Static,
            p.range.map(r => r.begin).unwrap_or(e.loc),
            "duplicate parameter '\{p.name}'",
          )
        }
        seen[p.name] = true
        scope.push(p.name)
      }
      for { default_value: d, .. } in ps {
        if d is Some(v) {
          validate(v, scope, in_object)
        }
      }
      validate(body, scope, in_object)
    }
    Call(f, args, _) => {
      validate(f, names, in_object)
      let seen : Map[String, Bool] = Map([])
      for (n, a) in args {
        if n is Some(name) {
          if seen.contains(name) {
            raise problem(Static, a.loc, "duplicate argument '\{name}'")
          }
          seen[name] = true
        }
        validate(a, names, in_object)
      }
    }
    If(a, b, c) => {
      validate(a, names, in_object)
      validate(b, names, in_object)
      validate(c, names, in_object)
    }
    Arr(xs) =>
      for x in xs {
        validate(x, names, in_object)
      }
    Obj(fs, bs, assertions, _) => {
      let outer = names.copy()
      outer.push("$")
      let scope = binding_scope(bs, outer, e.loc)
      for { value: v, .. } in bs {
        validate(v, scope, true)
      }
      let keys : Map[String, Bool] = Map([])
      for f in fs {
        validate(f.key, names, in_object)
        if f.key.kind is Literal(String(k)) {
          if keys.contains(k) {
            raise problem(Static, f.key.loc, "duplicate field '\{k}'")
          }
          keys[k] = true
        }
        validate(f.value, scope, true)
      }
      for (a, b) in assertions {
        validate(a, scope, true)
        if b is Some(v) {
          validate(v, scope, true)
        }
      }
    }
    ArrayComp(body, cs) => {
      let scope = validate_clauses(cs, names, in_object)
      validate(body, scope, in_object)
    }
    ObjectComp(key, body, cs, bs) => {
      let scope = validate_clauses(cs, names, in_object)
      validate(key, scope, in_object)
      scope.push("$")
      let inner = binding_scope(bs, scope, e.loc)
      for { value: v, .. } in bs {
        validate(v, inner, true)
      }
      validate(body, inner, true)
    }
    Index({ kind: Var("super"), .. }, b)
    | Binary("in", b, { kind: Var("super"), .. }) => {
      if !in_object {
        raise problem(Static, e.loc, "super outside object")
      }
      validate(b, names, in_object)
    }
    Index(a, b) | Binary(_, a, b) => {
      validate(a, names, in_object)
      validate(b, names, in_object)
    }
    Slice(a, start, end, step) => {
      validate(a, names, in_object)
      for x in [start, end, step] {
        if x is Some(v) {
          validate(v, names, in_object)
        }
      }
    }
    Unary(_, a) | Fail(a) => validate(a, names, in_object)
    Assert(a, b, c) => {
      validate(a, names, in_object)
      if b is Some(v) {
        validate(v, names, in_object)
      }
      validate(c, names, in_object)
    }
  }
}

///|
fn validate_clauses(
  cs : Array[Clause],
  names : Array[String],
  in_object : Bool,
) -> Array[String] raise Error {
  let scope = names.copy()
  for c in cs {
    match c {
      For(n, e) => {
        validate(e, scope, in_object)
        scope.push(n)
      }
      When(e) => validate(e, scope, in_object)
    }
  }
  scope
}
