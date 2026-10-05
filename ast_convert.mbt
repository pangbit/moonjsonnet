///|
fn AstReader::read(
  self : AstReader,
  e : Ast,
  depth : Int,
) -> Expr raise JsonnetError {
  if depth >= self.limits.depth || self.nodes >= self.limits.steps {
    raise problem(Limit, e.loc, "AST conversion limit exceeded")
  }
  self.nodes += 1
  check_ast_shape(e)
  let visit = fn(child : Ast) raise JsonnetError { self.read(child, depth + 1) }
  let optional = fn(child : Ast?) raise JsonnetError { child.map(visit) }
  let bindings = fn(bs : Array[(String, Ast)]) raise JsonnetError {
    bs.map(b => (b.0, visit(b.1)))
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
    Func(ps, b) => Func(ps.map(p => (p.0, optional(p.1))), visit(b))
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
fn export_ast(e : Expr) -> Ast {
  let visit = fn(child : Expr) { export_ast(child) }
  let optional = fn(child : Expr?) { child.map(visit) }
  let bindings = fn(bs : Array[(String, Expr)]) {
    bs.map(b => (b.0, visit(b.1)))
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
    Func(ps, b) => Func(ps.map(p => (p.0, optional(p.1))), visit(b))
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
