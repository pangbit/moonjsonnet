///|
fn LintGraph::build(
  self : LintGraph,
  e : Expr,
  scope : Map[String, Int],
  from : String,
  id? : Int,
  depth? : Int = 0,
) -> LintTyped raise JsonnetError {
  if depth >= self.scan.limits.depth {
    raise problem(Limit, e.loc, "lint type expression depth exceeded")
  }
  self.scan.tick(e)
  let id = id.unwrap_or_else(() => self.add())
  let children = []
  let visit = fn(e : Expr, scope : Map[String, Int]) raise JsonnetError {
    let node = self.build(e, scope, from, depth=depth + 1)
    children.push(node)
    node.id
  }
  let refs = self.slots[id].refs
  let t = self.slots[id].concrete
  match e.kind {
    NumberLiteral(_) => refs.push(3)
    Literal(v) =>
      refs.push(
        match v {
          True | False => 2
          Number(_) => 3
          String(_) => 4
          Null => 5
          _ => 1
        },
      )
    Var("self" | "super" | "$") => refs.push(9)
    Var("$std") => refs.push(11)
    Var(n) => refs.push(scope.get(n).unwrap_or(1))
    Local(bs, body) => {
      let inner = scope.copy()
      for (n, _) in bs {
        inner[n] = self.add()
      }
      refs.push(visit(body, inner))
      for (n, x) in bs {
        children.push(self.build(x, inner, from, id=inner[n], depth=depth + 1))
      }
    }
    Func(ps, body) => {
      let inner = scope.copy()
      for (n, _) in ps {
        inner[n] = 1
      }
      let result = visit(body, inner)
      for (_, value) in ps {
        if value is Some(x) {
          ignore(visit(x, inner))
        }
      }
      t.func = Some({
        results: [result],
        params: if ps.is_empty() {
          None
        } else {
          Some(ps.map(p => (p.0, p.1 is Some(_))))
        },
        min: ps.filter(p => p.1 is Some(_)).length(),
        max: ps.length(),
      })
    }
    If(a, b, c) => {
      ignore(visit(a, scope))
      refs.push(visit(b, scope))
      refs.push(visit(c, scope))
    }
    Arr(xs) => {
      let elements = []
      let further = []
      for i, x in xs {
        let child = visit(x, scope)
        if i < 5 {
          elements.push([child])
        } else {
          further.push(child)
        }
      }
      t.array = Some({ elements, further, })
    }
    Obj(fs, bs, _) => {
      let inner = scope.copy()
      inner["$"] = 9
      for (n, _) in bs {
        inner[n] = self.add()
      }
      let fields : Map[String, Array[Int]] = Map([])
      let unknown = []
      let mut known = true
      // Reference traversal visits all field names before locals and bodies.
      for f in fs {
        ignore(visit(f.key, scope))
      }
      for (n, x) in bs {
        children.push(self.build(x, inner, from, id=inner[n], depth=depth + 1))
      }
      for f in fs {
        let value = visit(f.value, inner)
        let value = if f.additive { 1 } else { value }
        if f.key.kind is Literal(String(key)) {
          fields.get_or_init(key, () => []).push(value)
        } else {
          known = false
          unknown.push(value)
        }
      }
      t.object = Some({ fields, unknown, known, })
    }
    Binary("in", a, { kind: Var("super"), .. }) => {
      ignore(visit(a, scope))
      refs.push(2)
    }
    Binary("%", a, b) =>
      return self.build(
        lint_std_call("mod", [a, b], e.loc),
        scope,
        from,
        id~,
        depth~,
      )
    Binary("in", a, b) =>
      return self.build(
        lint_std_call("objectHasAll", [b, a], e.loc),
        scope,
        from,
        id~,
        depth~,
      )
    Index({ kind: Var("super"), .. }, key) => {
      ignore(visit(key, scope))
      refs.push(1)
    }
    Index(a, b) => {
      let target = visit(a, scope)
      ignore(visit(b, scope))
      let index = match b.kind {
        Literal(String(s)) => StringIndex(s)
        NumberLiteral(raw) => {
          let parsed = Some(@string.parse_double(raw)) catch { _ => None }
          if parsed is Some(n) && n >= 0 && n < 5 && n == n.to_int().to_double() {
            IntIndex(n.to_int())
          } else {
            AnyIndex
          }
        }
        Literal(Number(n, ..)) if n >= 0 && n < 5 && n == n.to_int().to_double() =>
          IntIndex(n.to_int())
        _ => AnyIndex
      }
      self.slots[id].index = Some((target, index))
    }
    Call(f, args, _) => {
      let target = visit(f, scope)
      for (_, x) in args {
        ignore(visit(x, scope))
      }
      self.slots[id].index = Some((target, ResultIndex))
    }
    Binary(op, a, b) => {
      let a = visit(a, scope)
      let b = visit(b, scope)
      if op == "+" {
        self.slots[id].plus = Some((a, b))
      } else {
        refs.push(1)
      }
    }
    Unary(op, x) => {
      ignore(visit(x, scope))
      refs.push(if op == "!" { 2 } else { 3 })
    }
    Fail(x) => ignore(visit(x, scope))
    Assert(a, b, c) => {
      ignore(visit(a, scope))
      refs.push(visit(c, scope))
      if b is Some(b) {
        ignore(visit(b, scope))
      }
    }
    Slice(a, b, c, d) => {
      let null : Expr = { kind: Literal(Json::null()), loc: e.loc, end: None, }
      return self.build(
        lint_std_call(
          "slice",
          [a, b.unwrap_or(null), c.unwrap_or(null), d.unwrap_or(null)],
          e.loc,
        ),
        scope,
        from,
        id~,
        depth~,
      )
    }
    ArrayComp(body, cs) => {
      self.work(cs.length())
      return self.build(lint_comp(body, cs, e.loc), scope, from, id~, depth~)
    }
    ObjectComp(key, body, cs, bs) => {
      self.work(cs.length())
      let value = if bs.is_empty() {
        body
      } else {
        Expr::{ kind: Local(bs, body), loc: body.loc, end: None, }
      }
      let object : Expr = {
        kind: Obj([{ key, value, visibility: 1, additive: false, }], [], []),
        loc: e.loc,
        end: e.end,
      }
      return self.build(
        lint_std_call("$objectFlatMerge", [lint_comp(object, cs, e.loc)], e.loc),
        scope,
        from,
        id~,
        depth~,
      )
    }
    ImportFile(path, false) =>
      refs.push(
        self.imports
        .get((from, path))
        .map(id => self.roots.get(id).unwrap_or(1))
        .unwrap_or(1),
      )
    ImportFile(_, true) => refs.push(4)
    ImportBinary(_) => refs.push(7)
    StandardFunction(_) | StandardValue(_) => refs.push(1)
  }
  { expression: e, id, children, }
}
