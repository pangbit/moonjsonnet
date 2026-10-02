///|
fn Vm::binary(
  self : Vm,
  op : String,
  a : Value,
  b : Value,
  loc : Location,
) -> Value raise {
  match op {
    "+" =>
      match (a, b) {
        (Num(x), Num(y)) => finite(x + y, loc)
        (ArrayValue(x), ArrayValue(y)) => {
          self.tick(loc)
          if x.length() > self.limits.steps - y.length() ||
            x.length() > self.limits.output_bytes - y.length() {
            raise problem(Limit, loc, "array size limit exceeded")
          }
          ArrayValue(x + y)
        }
        (ObjectValue(x, xt), ObjectValue(y, yt)) => {
          if xt > self.limits.steps - yt {
            raise problem(Limit, loc, "object layer limit exceeded")
          }
          let layers = self.objects[x].layers[:xt].to_owned() +
            self.objects[y].layers[:yt].to_owned()
          self.object_value(layers)
        }
        (Str(x), _) => self.join_string(x, self.coerce_string(b, loc), loc)
        (_, Str(y)) => self.join_string(self.coerce_string(a, loc), y, loc)
        _ => raise problem(Type, loc, "incompatible operands for +")
      }
    "-" => finite(number_value(a, loc) - number_value(b, loc), loc)
    "*" => finite(number_value(a, loc) * number_value(b, loc), loc)
    "/" | "%" => {
      if op == "%" && a is Str(_) {
        raise problem(Unsupported, loc, "string formatting is unsupported")
      }
      let x = number_value(a, loc)
      let y = number_value(b, loc)
      if y == 0 {
        raise problem(Runtime, loc, "division by zero")
      }
      finite(if op == "/" { x / y } else { x % y }, loc)
    }
    "==" => Bool(self.equal(a, b, loc))
    "!=" => Bool(!self.equal(a, b, loc))
    "<" | "<=" | ">" | ">=" => {
      let c = match (a, b) {
        (Num(x), Num(y)) => x.compare(y)
        (Str(x), Str(y)) => compare_unicode(x, y)
        (ArrayValue(_), ArrayValue(_)) =>
          raise problem(
            Unsupported,
            loc,
            "ordering supports only numbers and strings",
          )
        _ =>
          raise problem(
            Type,
            loc,
            "ordering operands must have compatible types",
          )
      }
      Bool(
        match op {
          "<" => c < 0
          "<=" => c <= 0
          ">" => c > 0
          _ => c >= 0
        },
      )
    }
    "in" => {
      let k = text_value(a, loc)
      guard b is ObjectValue(id, top) else {
        raise problem(Type, loc, "right operand of in must be object")
      }
      Bool(self.has_field(id, top, k))
    }
    _ => raise problem(Unsupported, loc, "operator '\{op}' is unsupported")
  }
}

///|
fn compare_unicode(a : String, b : String) -> Int {
  let x = a.to_array()
  let y = b.to_array()
  for i in 0..<Int::min(x.length(), y.length()) {
    let c = x[i].to_int().compare(y[i].to_int())
    if c != 0 {
      return c
    }
  }
  x.length().compare(y.length())
}

///|
fn Vm::join_string(
  self : Vm,
  a : String,
  b : String,
  loc : Location,
) -> Value raise {
  if a.length() > self.limits.output_bytes - b.length() {
    raise problem(Limit, loc, "string size limit exceeded")
  }
  Str(a + b)
}

///|
fn Vm::coerce_string(self : Vm, v : Value, loc : Location) -> String raise {
  match v {
    Str(s) => s
    _ => render_json(self.manifest(v, loc, 0), false, 0)
  }
}

///|
fn Vm::equal(self : Vm, a : Value, b : Value, loc : Location) -> Bool raise {
  if self.depth >= self.limits.depth {
    raise problem(Limit, loc, "comparison depth limit exceeded")
  }
  self.depth += 1
  defer {
    self.depth -= 1
  }
  self.equal_inner(a, b, loc)
}

///|
fn Vm::equal_inner(
  self : Vm,
  a : Value,
  b : Value,
  loc : Location,
) -> Bool raise {
  self.tick(loc)
  match (a, b) {
    (Closure(_, _, _), _)
    | (_, Closure(_, _, _))
    | (Builtin(_), _)
    | (_, Builtin(_)) =>
      raise problem(Type, loc, "functions cannot be compared")
    (Nil, Nil) => true
    (Bool(x), Bool(y)) => x == y
    (Num(x), Num(y)) => x == y
    (Str(x), Str(y)) => x == y
    (ArrayValue(x), ArrayValue(y)) => {
      if x.length() != y.length() {
        return false
      }
      for i in 0..<x.length() {
        if !self.equal(self.force(x[i], loc), self.force(y[i], loc), loc) {
          return false
        }
      }
      true
    }
    (ObjectValue(x, xt), ObjectValue(y, yt)) => {
      self.check_assertions(x, loc)
      self.check_assertions(y, loc)
      let keys = self.keys(x, xt, false)
      if keys != self.keys(y, yt, false) {
        return false
      }
      for k in keys {
        if !self.equal(
            self.field(x, xt, k, loc),
            self.field(y, yt, k, loc),
            loc,
          ) {
          return false
        }
      }
      true
    }
    _ => false
  }
}
