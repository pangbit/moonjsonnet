///|
// Child traversal for lint analysis. Direct children follow the fixed reference's
// desugared eager edges; thunks, functions, locals and lowered std calls stop it.
fn lint_children(e : Expr, direct? : Bool = false) -> Array[Expr] {
  let out = []
  let optional = fn(x : Expr?) { if x is Some(x) { out.push(x) } }
  match e.kind {
    Local(bs, body) =>
      if !direct {
        for { value: x, .. } in bs {
          out.push(x)
        }
        out.push(body)
      }
    Func(ps, body) =>
      if !direct {
        for (_, x) in ps {
          optional(x)
        }
        out.push(body)
      }
    Call(f, args, _) => {
      out.push(f)
      if !direct {
        for (_, x) in args {
          out.push(x)
        }
      }
    }
    If(a, b, c) => {
      out.push(a)
      out.push(b)
      out.push(c)
    }
    Binary("%" | "in", a, b) =>
      if !direct {
        out.push(a)
        out.push(b)
      }
    Binary(_, a, b) | Index(a, b) => {
      out.push(a)
      out.push(b)
    }
    Unary(_, a) | Fail(a) => out.push(a)
    Arr(xs) => if !direct { out.append(xs) }
    Obj(fs, bs, _) => {
      for f in fs {
        out.push(f.key)
      }
      if !direct {
        for { value: x, .. } in bs {
          out.push(x)
        }
        for f in fs {
          out.push(f.value)
        }
      }
    }
    Assert(a, b, c) => {
      out.push(a)
      optional(b)
      out.push(c)
    }
    Slice(a, b, c, d) =>
      if !direct {
        out.push(a)
        optional(b)
        optional(c)
        optional(d)
      }
    ArrayComp(body, cs) =>
      if !direct {
        out.push(body)
        for c in cs {
          match c {
            For(_, x) | When(x) => out.push(x)
          }
        }
      }
    ObjectComp(key, body, cs, bs) =>
      if !direct {
        out.push(key)
        out.push(body)
        for { value: x, .. } in bs {
          out.push(x)
        }
        for c in cs {
          match c {
            For(_, x) | When(x) => out.push(x)
          }
        }
      }
    _ => ()
  }
  out
}
