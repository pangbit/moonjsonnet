///|
priv struct Parser {
  tokens : Array[Token]
  mut pos : Int
  mut depth : Int
  max_depth : Int
}

///|
fn Parser::peek(self : Parser) -> Token {
  self.tokens[self.pos]
}

///|
fn Parser::take(self : Parser) -> Token {
  let t = self.peek()
  if self.pos < self.tokens.length() - 1 {
    self.pos += 1
  }
  t
}

///|
fn Parser::eat(self : Parser, text : String) -> Bool {
  if self.peek().text == text {
    ignore(self.take())
    true
  } else {
    false
  }
}

///|
fn Parser::expect(self : Parser, text : String) -> Unit raise Error {
  if !self.eat(text) {
    raise problem(
      Syntax,
      self.peek().loc,
      "expected '\{text}', got '\{self.peek().text}'",
    )
  }
}

///|
fn is_name(s : String) -> Bool {
  if s == "<eof>" || s == "<string>" || s == "<number>" {
    return false
  }
  match s {
    "local"
    | "if"
    | "then"
    | "else"
    | "function"
    | "for"
    | "in"
    | "assert"
    | "error"
    | "true"
    | "false"
    | "null"
    | "self"
    | "super"
    | "import"
    | "importstr"
    | "importbin"
    | "tailstrict" => false
    _ => s.to_array().get(0) is Some(c) && identifier_start(c)
  }
}

///|
fn Parser::name(self : Parser) -> String raise Error {
  let t = self.take()
  if !is_name(t.text) {
    raise problem(Syntax, t.loc, "expected identifier")
  }
  t.text
}

///|
fn precedence(op : String) -> Int {
  match op {
    "||" => 1
    "&&" => 2
    "|" => 3
    "^" => 4
    "&" => 5
    "==" | "!=" => 6
    "<" | ">" | "<=" | ">=" | "in" => 7
    "<<" | ">>" => 8
    "+" | "-" => 9
    "*" | "/" | "%" => 10
    _ => 0
  }
}

///|
fn Parser::params(self : Parser) -> Array[(String, Expr?)] raise Error {
  self.expect("(")
  let params = []
  let names : Map[String, Bool] = Map([])
  while !self.eat(")") {
    let n = self.name()
    if names.contains(n) {
      raise problem(Static, self.peek().loc, "duplicate parameter '\{n}'")
    }
    names[n] = true
    let default = if self.eat("=") { Some(self.expr(0)) } else { None }
    params.push((n, default))
    if !self.eat(",") {
      self.expect(")")
      break
    }
  }
  params
}

///|
fn Parser::binding(self : Parser) -> (String, Expr) raise Error {
  let name = self.name()
  let loc = self.peek().loc
  let params = if self.peek().text == "(" { Some(self.params()) } else { None }
  self.expect("=")
  let value = self.expr(0)
  (
    name,
    match params {
      Some(p) => { kind: Func(p, value), loc, }
      None => value
    },
  )
}

///|
fn Parser::clauses(self : Parser) -> Array[Clause] raise Error {
  let out = []
  while self.peek().text == "for" || self.peek().text == "if" {
    if self.eat("for") {
      let n = self.name()
      self.expect("in")
      out.push(For(n, self.expr(0)))
    } else {
      self.expect("if")
      out.push(When(self.expr(0)))
    }
  }
  out
}

///|
fn Parser::object(self : Parser, loc : Location) -> Expr raise Error {
  let fields : Array[Field] = []
  let locals = []
  let assertions = []
  let mut computed_field = false
  while !self.eat("}") {
    if self.eat("local") {
      locals.push(self.binding())
    } else if self.eat("assert") {
      let cond = self.expr(0)
      let message = if self.eat(":") { Some(self.expr(0)) } else { None }
      assertions.push((cond, message))
    } else {
      let computed = self.eat("[")
      computed_field = computed
      let key = if computed {
        let e = self.expr(0)
        self.expect("]")
        e
      } else {
        let t = self.take()
        if t.value is Some(String(_)) {
          { kind: Literal(t.value.unwrap()), loc: t.loc, }
        } else if is_name(t.text) {
          { kind: Literal(Json::string(t.text)), loc: t.loc, }
        } else {
          raise problem(Syntax, t.loc, "expected field name")
        }
      }
      let params = if self.peek().text == "(" {
        Some(self.params())
      } else {
        None
      }
      let additive = self.eat("+")
      if additive && params is Some(_) {
        raise problem(
          Syntax,
          key.loc,
          "method cannot use additive field syntax",
        )
      }
      let visibility = if self.eat(":::") {
        3
      } else if self.eat("::") {
        2
      } else {
        self.expect(":")
        1
      }
      let body = self.expr(0)
      let value = match params {
        Some(p) => { kind: Func(p, body), loc: key.loc, }
        None => body
      }
      fields.push({ key, value, visibility, additive, })
    }
    let comma = self.eat(",")
    if self.peek().text == "for" {
      if !computed_field ||
        fields.length() != 1 ||
        !assertions.is_empty() ||
        fields[0].visibility != 1 ||
        fields[0].additive {
        raise problem(
          Syntax,
          loc,
          "object comprehension requires one computed visible field",
        )
      }
      let clauses = self.clauses()
      self.expect("}")
      return {
        kind: ObjectComp(fields[0].key, fields[0].value, clauses, locals),
        loc,
      }
    }
    if !comma {
      self.expect("}")
      break
    }
  }
  { kind: Obj(fields, locals, assertions), loc, }
}

///|
fn Parser::expr(self : Parser, min_prec : Int) -> Expr raise Error {
  self.depth += 1
  if self.depth > self.max_depth {
    raise problem(Limit, self.peek().loc, "parse depth limit exceeded")
  }
  let token = self.take()
  let loc = token.loc
  let mut left : Expr = match token.value {
    Some(value) => { kind: Literal(value), loc, }
    None =>
      match token.text {
        "true" => { kind: Literal(Json::boolean(true)), loc, }
        "false" => { kind: Literal(Json::boolean(false)), loc, }
        "null" => { kind: Literal(Json::null()), loc, }
        "(" => {
          let e = self.expr(0)
          self.expect(")")
          e
        }
        "local" => {
          let bindings = [self.binding()]
          while self.eat(",") {
            bindings.push(self.binding())
          }
          self.expect(";")
          { kind: Local(bindings, self.expr(0)), loc, }
        }
        "if" => {
          let c = self.expr(0)
          self.expect("then")
          let yes = self.expr(0)
          let no = if self.eat("else") {
            self.expr(0)
          } else {
            { kind: Literal(Json::null()), loc, }
          }
          { kind: If(c, yes, no), loc, }
        }
        "function" => {
          let p = self.params()
          { kind: Func(p, self.expr(0)), loc, }
        }
        "assert" => {
          let c = self.expr(0)
          let m = if self.eat(":") { Some(self.expr(0)) } else { None }
          self.expect(";")
          { kind: Assert(c, m, self.expr(0)), loc, }
        }
        "error" => { kind: Fail(self.expr(0)), loc, }
        "import" | "importstr" | "importbin" => {
          let t = self.take()
          guard t.value is Some(String(path)) else {
            raise problem(Syntax, t.loc, "import requires a string literal")
          }
          if t.text == "<block>" {
            raise problem(Syntax, t.loc, "imports cannot use text blocks")
          }
          {
            kind: if token.text == "importbin" {
              ImportBinary(path)
            } else {
              ImportFile(path, token.text == "importstr")
            },
            loc,
          }
        }
        "!" | "-" | "+" | "~" =>
          { kind: Unary(token.text, self.expr(11)), loc, }
        "[" =>
          if self.eat("]") {
            { kind: Arr([]), loc, }
          } else {
            let first = self.expr(0)
            let comma = self.eat(",")
            if self.peek().text == "for" {
              let clauses = self.clauses()
              self.expect("]")
              { kind: ArrayComp(first, clauses), loc, }
            } else {
              let items = [first]
              if comma {
                while !self.eat("]") {
                  items.push(self.expr(0))
                  if !self.eat(",") {
                    self.expect("]")
                    break
                  }
                }
              } else {
                self.expect("]")
              }
              { kind: Arr(items), loc, }
            }
          }
        "{" => self.object(loc)
        "self" | "super" | "$" => { kind: Var(token.text), loc, }
        n =>
          if is_name(n) {
            { kind: Var(n), loc, }
          } else {
            raise problem(Syntax, loc, "unexpected token '\{n}'")
          }
      }
  }
  while true {
    let t = self.peek()
    if t.text == "." {
      ignore(self.take())
      let n = self.name()
      left = {
        kind: Index(left, { kind: Literal(Json::string(n)), loc: t.loc, }),
        loc,
      }
    } else if t.text == "[" {
      ignore(self.take())
      let index = if self.peek().text == ":" || self.peek().text == "::" {
        None
      } else {
        Some(self.expr(0))
      }
      if self.peek().text == ":" || self.peek().text == "::" {
        let double = self.eat("::")
        if !double {
          self.expect(":")
        }
        let end = if double ||
          self.peek().text == ":" ||
          self.peek().text == "]" {
          None
        } else {
          Some(self.expr(0))
        }
        let step = if double || self.eat(":") {
          if self.peek().text == "]" {
            None
          } else {
            Some(self.expr(0))
          }
        } else {
          None
        }
        self.expect("]")
        left = { kind: Slice(left, index, end, step), loc, }
      } else {
        self.expect("]")
        left = { kind: Index(left, index.unwrap()), loc, }
      }
    } else if t.text == "(" {
      ignore(self.take())
      let args = []
      let mut named = false
      while !self.eat(")") {
        let name = if is_name(self.peek().text) &&
          self.tokens[self.pos + 1].text == "=" {
          let n = self.name()
          self.expect("=")
          named = true
          Some(n)
        } else {
          if named {
            raise problem(
              Static,
              self.peek().loc,
              "positional argument after named argument",
            )
          }
          None
        }
        args.push((name, self.expr(0)))
        if !self.eat(",") {
          self.expect(")")
          break
        }
      }
      left = { kind: Call(left, args, self.eat("tailstrict")), loc, }
    } else if t.text == "{" {
      ignore(self.take())
      left = { kind: Binary("+", left, self.object(t.loc)), loc, }
    } else {
      let prec = precedence(t.text)
      if prec == 0 || prec < min_prec {
        break
      }
      ignore(self.take())
      let right = self.expr(prec + 1)
      left = { kind: Binary(t.text, left, right), loc, }
    }
  }
  self.depth -= 1
  left
}

///|
fn parse(source : String, file : String, max_depth : Int) -> Expr raise Error {
  let p : Parser = { tokens: lex(source, file), pos: 0, depth: 0, max_depth, }
  let e = p.expr(0)
  p.expect("<eof>")
  check_ast_depth(e, max_depth)
  validate(e, ["std"], false)
  e
}
