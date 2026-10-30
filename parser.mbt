// Portions adapted from google/go-jsonnet v0.21.0 (Apache-2.0).
// https://github.com/google/go-jsonnet/tree/67968688d9952f50662e979fab1bef889d0d3e57
// Source: internal/parser/parser.go
// Source: ast/ast.go
// Source: internal/program/desugarer.go
// Copyright 2016 Google Inc. All rights reserved.
// Modifications: Adapted parsing, binding ranges and diagnostics to the local AST and bounded parser; raw-tree instrumentation is local.
// License and retained attribution: LICENSE and NOTICE at the module root.

///|
priv struct Parser {
  tokens : Array[Token]
  mut pos : Int32
  mut depth : Int32
  max_depth : Int32
  // End of the last parsed expression before semantic sugar is removed.
  mut expression_end : Location
  raw_spans : Array[RawSpan]?
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
      (if text == "<eof>" {
        "Did not expect: "
      } else if text == "=" || text == ":" {
        "Expected operator " + text + " but got "
      } else {
        "Expected token " + token_kind_name(text) + " but got "
      }) +
      self.peek().describe(),
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
fn Parser::name(self : Parser, parameter~ : Bool = false) -> String raise Error {
  let t = self.take()
  if !is_name(t.text) {
    raise problem(
      Syntax,
      t.loc,
      "Expected token IDENTIFIER but got " +
      t.describe() +
      (if parameter { " while parsing parameter" } else { "" }),
    )
  }
  t.text
}

///|
fn precedence(op : String) -> Int32 {
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
fn Parser::params(
  self : Parser,
  is_method~ : Bool = false,
) -> Array[ExprParameter] raise Error {
  self.expect("(")
  let params : Array[ExprParameter] = []
  while !self.eat(")") {
    let raw_begin = self.pos
    let token = self.peek()
    let n = self.name(parameter=true)
    let default = if self.eat("=") { Some(self.expr(0)) } else { None }
    params.push({
      name: n,
      default_value: default,
      range: Some({
        begin: token.loc,
        end: if default is Some(_) {
          self.expression_end
        } else {
          token.end
        },
      }),
    })
    self.record_raw(Parameter, raw_begin)
    if !self.eat(",") {
      self.end_list(
        ")",
        if is_method {
          "method parameter"
        } else {
          "function parameter"
        },
      )
      break
    }
  }
  params
}

///|
fn Parser::last_end(self : Parser) -> Location {
  self.tokens[self.pos - 1].end
}

///|
fn Parser::binding(
  self : Parser,
  names : Map[String, Bool],
  in_object~ : Bool = false,
) -> ExprBinding raise Error {
  let raw_begin = self.pos
  let loc = self.peek().loc
  let name = self.name()
  if names.contains(name) {
    raise problem(Static, loc, "Duplicate local var: \{name}")
  }
  names[name] = true
  let params = if self.peek().text == "(" { Some(self.params()) } else { None }
  self.expect("=")
  let value = self.expr(0)
  self.record_raw(Binding, raw_begin)
  {
    name,
    value: match params {
      Some(p) => { kind: Func(p, value), loc, end: Some(self.expression_end), }
      None => value
    },
    // Go's local-function lowering drops the binding range, while object
    // methods retain the object-local declaration range.
    range: if params is Some(_) && !in_object {
      None
    } else {
      Some({ begin: loc, end: self.expression_end, })
    },
  }
}

///|
fn Parser::clauses(self : Parser) -> Array[Clause] raise Error {
  let out : Array[Clause] = []
  while self.peek().text == "for" || self.peek().text == "if" {
    let raw_begin = self.pos
    if self.eat("for") {
      let n = self.name()
      self.expect("in")
      out.push(For(n, self.expr(0)))
      self.record_raw(ForClause, raw_begin)
    } else {
      self.expect("if")
      out.push(When(self.expr(0)))
      self.record_raw(IfClause, raw_begin)
    }
  }
  out
}

///|
fn Parser::object(self : Parser, loc : Location) -> Expr raise Error {
  let raw_begin = self.pos - 1
  let fields : Array[Field] = []
  let locals = []
  let local_names : Map[String, Bool] = Map([])
  let field_names : Map[(String, String), Bool] = Map([])
  let assertions = []
  let assertion_sites = []
  let mut computed_field = false
  while !self.eat("}") {
    let member_begin = self.pos
    if self.eat("local") {
      locals.push(self.binding(local_names, in_object=true))
      self.record_raw(ObjectLocal, member_begin)
    } else if self.eat("assert") {
      let cond = self.expr(0)
      let message = if self.eat(":") { Some(self.expr(0)) } else { None }
      assertions.push((cond, message))
      assertion_sites.push(
        Some({ begin: self.tokens[member_begin].loc, end: self.last_end(), }),
      )
      self.record_raw(ObjectAssert, member_begin)
    } else {
      let computed = self.eat("[")
      computed_field = computed
      let (key, literal_name) = if computed {
        let e = self.expr(0)
        self.expect("]")
        (e, None)
      } else {
        let t = self.take()
        if t.value is Some(String(raw)) {
          ({ kind: t.literal_kind(), loc: t.loc, end: Some(t.end), }, Some(raw))
        } else if is_name(t.text) {
          (
            { kind: Literal(Json::string(t.text)), loc: t.loc, end: None, },
            Some(t.text),
          )
        } else {
          raise problem(
            Syntax,
            t.loc,
            "Unexpected: " + t.describe() + " while parsing field definition",
          )
        }
      }
      let params = if self.peek().text == "(" {
        Some(self.params(is_method=true))
      } else {
        None
      }
      let op = self.take()
      if !op.is_operator() {
        raise problem(
          Syntax,
          op.loc,
          "Expected token OPERATOR but got " + op.describe(),
        )
      }
      let (additive, visibility) = match op.text {
        ":" => (false, 1)
        "::" => (false, 2)
        ":::" => (false, 3)
        "+:" => (true, 1)
        "+::" => (true, 2)
        "+:::" => (true, 3)
        _ =>
          raise problem(
            Syntax,
            op.loc,
            "Expected one of :, ::, :::, +:, +::, +:::, got: " + op.text,
          )
      }
      if additive && params is Some(_) {
        raise problem(
          Syntax,
          key.loc,
          "method cannot use additive field syntax",
        )
      }
      if literal_name is Some(name) {
        guard key.kind is Literal(String(canonical)) else {
          abort("literal field name must be a string")
        }
        // Reject equal raw payloads only when their decoded names also match.
        // SyntaxDocument retains differently spelled aliases; semantic validate
        // checks complete canonical uniqueness before evaluator admission.
        let identity = (name, canonical)
        if field_names.contains(identity) {
          raise problem(Static, key.loc, "Duplicate field: \{name}")
        }
        field_names[identity] = true
      }
      let body = self.expr(0)
      let value : Expr = match params {
        Some(p) => { kind: Func(p, body), loc: key.loc, end: None, }
        None => body
      }
      fields.push({ key, value, visibility, additive, })
      self.record_raw(Field, member_begin)
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
      self.record_raw(ObjectComp, raw_begin)
      return {
        kind: ObjectComp(fields[0].key, fields[0].value, clauses, locals),
        loc,
        end: Some(self.last_end()),
      }
    }
    if !comma {
      self.end_list("}", "field", describe=false)
      break
    }
  }
  self.record_raw(Object, raw_begin)
  {
    kind: Obj(fields, locals, assertions, assertion_sites),
    loc,
    end: Some(self.last_end()),
  }
}

///|
fn Parser::expr(self : Parser, min_prec : Int32) -> Expr raise Error {
  let raw_begin = self.pos
  self.depth += 1
  if self.depth > self.max_depth {
    raise problem(Limit, self.peek().loc, "parse depth limit exceeded")
  }
  let token = self.take()
  let loc = token.loc
  let mut left : Expr = match token.value {
    Some(_) => { kind: token.literal_kind(), loc, end: None, }
    None =>
      match token.text {
        "<number>" => { kind: NumberLiteral(token.raw), loc, end: None, }
        "true" => { kind: Literal(Json::boolean(true)), loc, end: None, }
        "false" => { kind: Literal(Json::boolean(false)), loc, end: None, }
        "null" => { kind: Literal(Json::null()), loc, end: None, }
        "(" => {
          let e = self.expr(0)
          self.expect(")")
          e
        }
        "local" => {
          let names : Map[String, Bool] = Map([])
          let bindings = [self.binding(names)]
          while self.eat(",") {
            bindings.push(self.binding(names))
          }
          if !self.eat(";") {
            raise problem(
              Syntax,
              self.peek().loc,
              "Expected , or ; but got " + self.peek().describe(),
            )
          }
          { kind: Local(bindings, self.expr(0)), loc, end: None, }
        }
        "if" => {
          let c = self.expr(0)
          self.expect("then")
          let yes = self.expr(0)
          let no = if self.eat("else") {
            self.expr(0)
          } else {
            { kind: Literal(Json::null()), loc, end: None, }
          }
          { kind: If(c, yes, no), loc, end: None, }
        }
        "function" => {
          if self.peek().text != "(" {
            raise problem(
              Syntax,
              self.peek().loc,
              "Expected ( but got " + self.peek().describe(),
            )
          }
          let p = self.params()
          { kind: Func(p, self.expr(0)), loc, end: None, }
        }
        "assert" => {
          let c = self.expr(0)
          let m = if self.eat(":") { Some(self.expr(0)) } else { None }
          self.expect(";")
          { kind: Assert(c, m, self.expr(0)), loc, end: None, }
        }
        "error" => { kind: Fail(self.expr(0)), loc, end: None, }
        "import" | "importstr" | "importbin" => {
          let t = self.peek()
          let body = self.expr(0)
          guard t.value is Some(String(_)) && body.kind is Literal(String(path)) else {
            raise problem(Syntax, t.loc, "Computed imports are not allowed")
          }
          if t.text == "<block>" {
            raise problem(
              Syntax,
              t.loc,
              "Block string literals not allowed in imports",
            )
          }
          {
            kind: if token.text == "importbin" {
              ImportBinary(path)
            } else {
              ImportFile(path, token.text == "importstr")
            },
            loc,
            end: None,
          }
        }
        "!" | "-" | "+" | "~" =>
          { kind: Unary(token.text, self.expr(11)), loc, end: None, }
        "[" =>
          if self.eat("]") {
            { kind: Arr([]), loc, end: None, }
          } else {
            let first = self.expr(0)
            let comma = self.eat(",")
            if self.peek().text == "for" {
              let clauses = self.clauses()
              self.expect("]")
              { kind: ArrayComp(first, clauses), loc, end: None, }
            } else {
              let items = [first]
              if comma {
                while !self.eat("]") {
                  items.push(self.expr(0))
                  if !self.eat(",") {
                    self.end_list("]", "array element", describe=false)
                    break
                  }
                }
              } else {
                self.end_list("]", "array element", describe=false)
              }
              { kind: Arr(items), loc, end: None, }
            }
          }
        "{" => self.object(loc)
        "self" | "super" | "$" => { kind: Var(token.text), loc, end: None, }
        n =>
          if is_name(n) {
            { kind: Var(n), loc, end: None, }
          } else {
            raise problem(
              Syntax,
              loc,
              if n == "<eof>" {
                "Unexpected end of file"
              } else if token.is_operator() {
                "Not a unary operator: " + n
              } else {
                "Unexpected: " + token.describe() + " while parsing terminal"
              },
            )
          }
      }
  }
  let mut span_end = match token.text {
    "local"
    | "if"
    | "function"
    | "assert"
    | "error"
    | "import"
    | "importstr"
    | "importbin"
    | "!"
    | "-"
    | "+"
    | "~" => self.expression_end
    _ => self.last_end()
  }
  if token.text != "(" && token.text != "assert" {
    left = { ..left, end: Some(span_end), }
  }
  self.record_raw(raw_primary_kind(left, token), raw_begin)
  while true {
    let t = self.peek()
    let mut end = None
    if t.text == "." {
      ignore(self.take())
      let n = self.name()
      left = {
        kind: Index(left, {
          kind: Literal(Json::string(n)),
          loc: t.loc,
          end: None,
        }),
        loc,
        end: None,
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
        left = { kind: Slice(left, index, end, step), loc, end: None, }
      } else {
        self.expect("]")
        left = { kind: Index(left, index.unwrap()), loc, end: None, }
      }
    } else if t.text == "(" {
      ignore(self.take())
      let args = []
      let mut named = false
      while !self.eat(")") {
        let argument_begin = self.pos
        let arg_loc = self.peek().loc
        let name = if is_name(self.peek().text) &&
          self.tokens[self.pos + 1].text == "=" {
          let n = self.name()
          self.expect("=")
          named = true
          Some(n)
        } else {
          None
        }
        let value = self.expr(0)
        if name is None && named {
          raise problem(
            Static,
            arg_loc,
            "Positional argument after a named argument is not allowed",
          )
        }
        args.push((name, value))
        self.record_raw(Argument, argument_begin)
        if !self.eat(",") {
          self.end_list(")", "function argument")
          break
        }
      }
      end = Some(self.last_end())
      left = { kind: Call(left, args, self.eat("tailstrict")), loc, end: None, }
    } else if t.text == "{" {
      ignore(self.take())
      left = { kind: Binary("+", left, self.object(t.loc)), loc, end: None, }
    } else {
      let prec = precedence(t.text)
      if prec == 0 && t.is_operator() && t.text != ":" && t.text != "::" {
        raise problem(Syntax, t.loc, "Not a binary operator: " + t.text)
      }
      if prec == 0 || prec < min_prec {
        break
      }
      ignore(self.take())
      let right = self.expr(prec + 1)
      end = Some(self.expression_end)
      left = { kind: Binary(t.text, left, right), loc, end: None, }
    }
    span_end = end.unwrap_or(self.last_end())
    left = { ..left, end: Some(span_end), }
    self.record_raw(
      match t.text {
        "." => DotIndex
        "(" => Call
        "{" => ApplyBrace
        "[" => if left.kind is Slice(_, _, _, _) { Slice } else { Index }
        _ => Binary(t.text)
      },
      raw_begin,
    )
  }
  self.expression_end = span_end
  self.depth -= 1
  left
}

///|
fn parse(source : String, file : String, max_depth : Int32) -> Expr raise Error {
  try {
    let e = parse_tokens(lex(source, file), max_depth)
    validate(e, ["std"], false)
    e
  } catch {
    Error(d) => raise Error(d.with_syntax_trace(source))
    e => raise e
  }
}

///|
fn parse_tokens(
  tokens : Array[Token],
  max_depth : Int32,
  tree_depth? : Int32,
  node_limit? : Int32,
  raw_spans? : Array[RawSpan],
) -> Expr raise Error {
  let p : Parser = {
    tokens,
    pos: 0,
    depth: 0,
    max_depth,
    expression_end: tokens[0].loc,
    raw_spans,
  }
  let e = p.expr(0)
  p.expect("<eof>")
  check_ast_depth(e, tree_depth.unwrap_or(max_depth))
  if node_limit is Some(limit) {
    check_ast_nodes(e, limit)
  }
  e
}
