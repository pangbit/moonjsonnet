///|
fn AstReader::read(
  self : AstReader,
  e : Ast,
  depth : Int32,
) -> Expr raise JsonnetError {
  if depth >= self.limits.depth || self.nodes >= self.limits.steps {
    raise problem(Limit, e.loc, "AST conversion limit exceeded")
  }
  self.nodes += 1
  check_ast_shape(e)
  let visit = fn(child : Ast) raise JsonnetError { self.read(child, depth + 1) }
  let optional = fn(child : Ast?) raise JsonnetError { child.map(visit) }
  let bindings = fn(
    bs : Array[AstBinding],
  ) -> Array[ExprBinding] raise JsonnetError {
    bs.map(b => { name: b.name, value: visit(b.value), range: b.range, })
  }
  let clauses = fn(cs : Array[AstClause]) -> Array[Clause] raise JsonnetError {
    cs.map(c => {
      match c {
        For(n, x) => For(n, visit(x))
        When(x) => When(visit(x))
      }
    })
  }
  let kind : ExprKind = match e.kind {
    NumberLiteral(raw) => NumberLiteral(raw)
    Literal(v) => Literal(v)
    Var(n) => Var(n)
    Local(bs, b) => Local(bindings(bs), visit(b))
    If(a, b, c) => If(visit(a), visit(b), visit(c))
    Func(ps, b) =>
      Func(
        ps.map(p => {
          name: p.name,
          default_value: optional(p.default_value),
          range: p.range,
        }),
        visit(b),
      )
    Call(f, args, strict) =>
      Call(visit(f), args.map(a => (a.0, visit(a.1))), strict)
    Arr(xs) => Arr(xs.map(visit))
    Obj(fs, bs, checks) =>
      Obj(
        fs.map(f => {
          key: visit(f.key),
          value: visit(f.value),
          visibility: f.visibility,
          additive: f.additive,
        }),
        bindings(bs),
        checks.map(c => (visit(c.0), optional(c.1))),
        checks.map(check => {
          let condition = check.0
          let key = (
            {
              begin: condition.loc,
              end: condition.end.unwrap_or(condition.loc),
            } : SourceRange).format()
          let range = self.assertion_ranges.get(key)
          if range is Some(range) {
            check_ast_range(range.begin, range.end)
          }
          range
        }),
      )
    ArrayComp(b, cs) => ArrayComp(visit(b), clauses(cs))
    ObjectComp(k, b, cs, bs) =>
      ObjectComp(visit(k), visit(b), clauses(cs), bindings(bs))
    Index(a, b) => Index(visit(a), visit(b))
    Slice(a, b, c, d) => Slice(visit(a), optional(b), optional(c), optional(d))
    Unary(op, a) => Unary(op, visit(a))
    Binary(op, a, b) => Binary(op, visit(a), visit(b))
    Assert(a, b, c) => Assert(visit(a), optional(b), visit(c))
    Fail(a) => Fail(visit(a))
    ImportFile(p, s) => ImportFile(p, s)
    ImportBinary(p) => ImportBinary(p)
  }
  { kind, loc: e.loc, end: e.end, }
}

///|
fn export_ast_node(e : Expr, children : Array[Ast]) -> Ast {
  let mut position = 0
  let visit = fn(_ : Expr) {
    let child = children[position]
    position += 1
    child
  }
  let optional = fn(child : Expr?) { child.map(visit) }
  let bindings = fn(bs : Array[ExprBinding]) -> Array[AstBinding] {
    bs.map(b => { name: b.name, value: visit(b.value), range: b.range, })
  }
  let clauses = fn(cs : Array[Clause]) -> Array[AstClause] {
    cs.map(c => {
      match c {
        For(n, x) => For(n, visit(x))
        When(x) => When(visit(x))
      }
    })
  }
  let kind : AstKind = match e.kind {
    NumberLiteral(raw) => NumberLiteral(raw)
    Literal(v) => Literal(v)
    Var(n) => Var(n)
    Local(bs, b) => Local(bindings(bs), visit(b))
    If(a, b, c) => If(visit(a), visit(b), visit(c))
    Func(ps, b) =>
      Func(
        ps.map(p => {
          name: p.name,
          default_value: optional(p.default_value),
          range: p.range,
        }),
        visit(b),
      )
    Call(f, args, strict) =>
      Call(visit(f), args.map(a => (a.0, visit(a.1))), strict)
    Arr(xs) => Arr(xs.map(visit))
    Obj(fs, bs, checks, _) =>
      Obj(
        fs.map(f => {
          key: visit(f.key),
          value: visit(f.value),
          visibility: f.visibility,
          additive: f.additive,
        }),
        bindings(bs),
        checks.map(c => (visit(c.0), optional(c.1))),
      )
    ArrayComp(b, cs) => ArrayComp(visit(b), clauses(cs))
    ObjectComp(k, b, cs, bs) =>
      ObjectComp(visit(k), visit(b), clauses(cs), bindings(bs))
    Index(a, b) => Index(visit(a), visit(b))
    Slice(a, b, c, d) => Slice(visit(a), optional(b), optional(c), optional(d))
    Unary(op, a) => Unary(op, visit(a))
    Binary(op, a, b) => Binary(op, visit(a), visit(b))
    Assert(a, b, c) => Assert(visit(a), optional(b), visit(c))
    Fail(a) => Fail(visit(a))
    ImportFile(p, s) => ImportFile(p, s)
    ImportBinary(p) => ImportBinary(p)
    StandardFunction(_) | StandardValue(_) =>
      abort("runtime-only node in program AST")
  }
  { kind, loc: e.loc, end: e.end, }
}

///|
// Keep the order identical to export_ast_node's constructor arguments. Lint
// traversal uses different eager edges and omits object assertions.
fn ast_export_children(e : Expr) -> Array[Expr] {
  let children = []
  let optional = fn(value : Expr?) {
    if value is Some(value) {
      children.push(value)
    }
  }
  let bindings = fn(values : Array[ExprBinding]) {
    for binding in values {
      children.push(binding.value)
    }
  }
  let clauses = fn(values : Array[Clause]) {
    for clause in values {
      match clause {
        For(_, value) | When(value) => children.push(value)
      }
    }
  }
  match e.kind {
    Local(values, body) => {
      bindings(values)
      children.push(body)
    }
    Func(parameters, body) => {
      for parameter in parameters {
        optional(parameter.default_value)
      }
      children.push(body)
    }
    If(condition, yes, no) => children.append([condition, yes, no])
    Call(target, arguments, _) => {
      children.push(target)
      for (_, value) in arguments {
        children.push(value)
      }
    }
    Arr(values) => children.append(values)
    Obj(fields, values, assertions, _) => {
      for field in fields {
        children.append([field.key, field.value])
      }
      bindings(values)
      for (condition, message) in assertions {
        children.push(condition)
        optional(message)
      }
    }
    ArrayComp(body, specs) => {
      children.push(body)
      clauses(specs)
    }
    ObjectComp(key, body, specs, values) => {
      children.append([key, body])
      clauses(specs)
      bindings(values)
    }
    Index(left, right) | Binary(_, left, right) =>
      children.append([left, right])
    Slice(target, begin, end, step) => {
      children.push(target)
      optional(begin)
      optional(end)
      optional(step)
    }
    Unary(_, value) | Fail(value) => children.push(value)
    Assert(condition, message, body) => {
      children.push(condition)
      optional(message)
      children.push(body)
    }
    Literal(_)
    | NumberLiteral(_)
    | Var(_)
    | ImportFile(_, _)
    | ImportBinary(_)
    | StandardFunction(_)
    | StandardValue(_) => ()
  }
  children
}

///|
priv enum AstExportFrame {
  Enter(Expr)
  Leave(Expr, Int32)
}

///|
// Programs and parsed documents have already checked their admission budgets.
// Export every occurrence independently, without a native-stack recursion or
// memoization that could make mutable AST containers alias one another.
fn export_ast(root : Expr) -> Ast {
  let stack : Array[AstExportFrame] = [Enter(root)]
  let completed : Array[Ast] = []
  while stack.pop() is Some(frame) {
    match frame {
      Enter(e) => {
        let children = ast_export_children(e)
        stack.push(Leave(e, children.length()))
        for i = children.length() - 1; i >= 0; i = i - 1 {
          stack.push(Enter(children[i]))
        }
      }
      Leave(e, count) => {
        let children = completed[completed.length() - count:].to_owned()
        let node = export_ast_node(e, children)
        for _ in 0..<count {
          ignore(completed.pop())
        }
        completed.push(node)
      }
    }
  }
  completed[0]
}
