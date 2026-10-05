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
// Parser checks which must also hold for manually constructed syntax trees.
fn check_ast_shape(e : Ast) -> Unit raise JsonnetError {
  if e.end is Some(end) &&
    (
      end.file != e.loc.file ||
      e.loc.line < 1 ||
      e.loc.column < 1 ||
      end.line < e.loc.line ||
      end.column < 1 ||
      (end.line == e.loc.line && end.column < e.loc.column)
    ) {
    raise problem(Static, e.loc, "invalid AST source range")
  }
  let name = fn(n) raise JsonnetError { ast_name(n, e.loc) }
  let bindings = fn(bs : Array[(String, Ast)]) raise JsonnetError {
    for (n, _) in bs {
      name(n)
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
    Literal(Array(_) | Object(_)) =>
      raise problem(Static, e.loc, "AST literal must be scalar")
    Var(n) => if n != "self" && n != "super" && n != "$" { name(n) }
    Local(bs, _) => bindings(bs)
    Func(ps, _) => {
      let seen : Map[String, Bool] = Map([])
      for (n, _) in ps {
        name(n)
        if seen.contains(n) {
          raise problem(Static, e.loc, "duplicate parameter '\{n}'")
        }
        seen[n] = true
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
