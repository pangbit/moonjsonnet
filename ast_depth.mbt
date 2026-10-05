///|
// Pratt parsing can create arbitrarily deep left-associated trees without
// increasing parser recursion. Walk iteratively before recursive validation.
fn check_ast_depth(root : Expr, limit : Int) -> Unit raise {
  let stack = [(root, 0)]
  while stack.pop() is Some((e, depth)) {
    if depth >= limit {
      raise problem(Limit, e.loc, "syntax tree depth limit exceeded")
    }
    let push = fn(child) { stack.push((child, depth + 1)) }
    let clauses = fn(cs : Array[Clause]) {
      for c in cs {
        match c {
          For(_, x) | When(x) => push(x)
        }
      }
    }
    match e.kind {
      Literal(_)
      | NumberLiteral(_)
      | Var(_)
      | ImportFile(_, _)
      | ImportBinary(_)
      | StandardFunction(_)
      | StandardValue(_) => ()
      Local(bs, body) => {
        for (_, v) in bs {
          push(v)
        }
        push(body)
      }
      Func(ps, body) => {
        for (_, v) in ps {
          if v is Some(x) {
            push(x)
          }
        }
        push(body)
      }
      If(a, b, c) => {
        push(a)
        push(b)
        push(c)
      }
      Call(f, args, _) => {
        push(f)
        for (_, v) in args {
          push(v)
        }
      }
      Arr(a) =>
        for x in a {
          push(x)
        }
      Obj(fs, bs, assertions) => {
        for f in fs {
          push(f.key)
          push(f.value)
        }
        for (_, v) in bs {
          push(v)
        }
        for (c, m) in assertions {
          push(c)
          if m is Some(v) {
            push(v)
          }
        }
      }
      ArrayComp(body, cs) => {
        push(body)
        clauses(cs)
      }
      ObjectComp(key, body, cs, bs) => {
        for (_, v) in bs {
          push(v)
        }
        push(key)
        push(body)
        clauses(cs)
      }
      Index(a, b) | Binary(_, a, b) => {
        push(a)
        push(b)
      }
      Slice(a, start, end, step) => {
        push(a)
        for x in [start, end, step] {
          if x is Some(v) {
            push(v)
          }
        }
      }
      Unary(_, a) | Fail(a) => push(a)
      Assert(a, m, b) => {
        push(a)
        push(b)
        if m is Some(v) {
          push(v)
        }
      }
    }
  }
}
