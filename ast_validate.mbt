///|
priv struct AstReader {
  limits : Limits
  mut nodes : Int
}

///|
fn ast_name(name : String, loc : Location) -> Unit raise JsonnetError {
  if !is_name(name) ||
    !name.to_array().all(c => identifier_start(c) || digit(c)) {
    raise problem(Static, loc, "invalid identifier '\{name}'")
  }
}

///|
fn check_ast_range(begin : Location, end : Location) -> Unit raise JsonnetError {
  if end.file != begin.file ||
    begin.line < 1 ||
    begin.column < 1 ||
    end.line < begin.line ||
    end.column < 1 ||
    (end.line == begin.line && end.column < begin.column) {
    raise problem(Static, begin, "invalid AST source range")
  }
}

///|
// Parser checks which must also hold for manually constructed syntax trees.
fn check_ast_shape(e : Ast) -> Unit raise JsonnetError {
  if e.end is Some(end) {
    check_ast_range(e.loc, end)
  }
  let name = fn(n) raise JsonnetError { ast_name(n, e.loc) }
  let bindings = fn(bs : Array[AstBinding]) raise JsonnetError {
    for b in bs {
      name(b.name)
      if b.range is Some(r) {
        check_ast_range(r.begin, r.end)
      }
    }
  }
  let clauses = fn(cs : Array[AstClause]) raise JsonnetError {
    guard cs.get(0) is Some(For(_, _)) else {
      raise problem(Static, e.loc, "comprehension must begin with for")
    }
    for c in cs {
      if c is For(n, _) {
        name(n)
      }
    }
  }
  match e.kind {
    NumberLiteral(raw) => {
      let chars = raw.to_array()
      let valid = chars.get(0) is Some(c) &&
        digit(c) &&
        (try number_end(chars, 0, e.loc) == chars.length() catch {
          _ => false
        })
      if !valid {
        raise problem(Static, e.loc, "invalid AST numeric literal")
      }
    }
    Literal(Array(_) | Object(_)) =>
      raise problem(Static, e.loc, "AST literal must be scalar")
    Var(n) => if n != "self" && n != "super" && n != "$" { name(n) }
    Local(bs, _) => bindings(bs)
    Func(ps, _) =>
      for p in ps {
        name(p.name)
        if p.range is Some(r) {
          check_ast_range(r.begin, r.end)
        }
      }
    Call(_, args, _) => {
      let mut named = false
      for (n, _) in args {
        if n is Some(n) {
          name(n)
          named = true
        } else if named {
          raise problem(
            Static,
            e.loc,
            "positional argument after named argument",
          )
        }
      }
    }
    Obj(fs, bs, _) => {
      bindings(bs)
      for f in fs {
        if f.visibility < 1 || f.visibility > 3 {
          raise problem(Static, f.key.loc, "invalid field visibility")
        }
      }
    }
    ArrayComp(_, cs) => clauses(cs)
    ObjectComp(_, _, cs, bs) => {
      clauses(cs)
      bindings(bs)
    }
    Unary(op, _) =>
      if op != "+" && op != "-" && op != "!" && op != "~" {
        raise problem(Static, e.loc, "invalid unary operator '\{op}'")
      }
    Binary(op, _, _) =>
      if precedence(op) == 0 {
        raise problem(Static, e.loc, "invalid binary operator '\{op}'")
      }
    _ => ()
  }
}
