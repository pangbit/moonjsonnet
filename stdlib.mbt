///|
fn builtin_names() -> Array[String] {
  [
    "extVar", "type", "isArray", "isBoolean", "isFunction", "isNumber", "isObject",
    "isString", "length", "objectFields", "objectFieldsAll", "objectHas", "objectHasAll",
    "map", "filter", "foldl", "range", "join", "split", "substr", "strReplace", "startsWith",
    "endsWith", "parseJson", "manifestJson", "toString", "floor", "ceil", "abs",
  ]
}

///|
fn value_type(v : Value) -> String {
  match v {
    Nil => "null"
    Bool(_) => "boolean"
    Num(_) => "number"
    Str(_) => "string"
    ArrayValue(_) => "array"
    ObjectValue(_, _) | Std => "object"
    Closure(_, _, _) | Builtin(_) => "function"
  }
}

///|
fn builtin_params(name : String) -> Array[String] {
  match name {
    "extVar" => ["x"]
    "type"
    | "isArray"
    | "isBoolean"
    | "isFunction"
    | "isNumber"
    | "isObject"
    | "isString"
    | "length"
    | "toString"
    | "floor"
    | "ceil"
    | "abs" => ["x"]
    "objectFields" | "objectFieldsAll" => ["o"]
    "objectHas" | "objectHasAll" => ["o", "f"]
    "map" | "filter" => ["func", "arr"]
    "foldl" => ["func", "arr", "init"]
    "range" => ["from", "to"]
    "join" => ["sep", "arr"]
    "split" => ["str", "c"]
    "substr" => ["str", "from", "len"]
    "strReplace" => ["str", "from", "to"]
    "startsWith" => ["a", "b"]
    "endsWith" => ["a", "b"]
    "parseJson" => ["str"]
    "manifestJson" => ["value"]
    _ => []
  }
}

///|
fn Vm::builtin(
  self : Vm,
  name : String,
  args : Array[(String?, Int)],
  loc : Location,
) -> Value raise {
  let params = builtin_params(name)
  if args.length() != params.length() {
    raise problem(Runtime, loc, "std.\{name}: wrong argument count")
  }
  let ids : Map[String, Int] = Map([])
  for i, (n, t) in args {
    let key = n.unwrap_or(params[i])
    if !params.contains(key) || ids.contains(key) {
      raise problem(Runtime, loc, "invalid or duplicate argument '\{key}'")
    }
    ids[key] = t
  }
  let values = params.map(n => self.force(ids[n], loc))
  let x = values[0]
  match name {
    "extVar" => {
      let key = text_value(x, loc)
      match self.ext.get(key) {
        Some(j) => self.from_json(j, loc)
        None =>
          raise problem(Runtime, loc, "undefined external variable '\{key}'")
      }
    }
    "type" => Str(value_type(x))
    "isArray" => Bool(value_type(x) == "array")
    "isBoolean" => Bool(value_type(x) == "boolean")
    "isFunction" => Bool(value_type(x) == "function")
    "isNumber" => Bool(value_type(x) == "number")
    "isObject" => Bool(value_type(x) == "object")
    "isString" => Bool(value_type(x) == "string")
    "length" =>
      Num(
        match x {
          Str(s) => s.iter().count().to_double()
          ArrayValue(a) => a.length().to_double()
          ObjectValue(id, top) => self.keys(id, top, false).length().to_double()
          Closure(ps, _, _) => ps.length().to_double()
          Builtin(n) => builtin_params(n).length().to_double()
          _ =>
            raise problem(
              Type,
              loc,
              "std.length: expected string, array, object or function",
            )
        },
      )
    "objectFields" | "objectFieldsAll" | "objectHas" | "objectHasAll" => {
      guard x is ObjectValue(id, top) else {
        raise problem(Type, loc, "expected object")
      }
      let hidden = name == "objectFieldsAll" || name == "objectHasAll"
      if name == "objectHas" || name == "objectHasAll" {
        let k = text_value(values[1], loc)
        Bool(self.has_field(id, top, k) && (hidden || self.visible(id, top, k)))
      } else {
        ArrayValue(
          self.keys(id, top, hidden).map(k => self.store(Ready(Str(k)))),
        )
      }
    }
    "map" | "filter" => {
      let a = array_value(values[1], loc)
      let out = []
      if value_type(x) != "function" {
        raise problem(Type, loc, "expected function")
      }
      for t in a {
        self.tick(loc)
        if name == "filter" {
          if boolean(self.call(x, [(None, t)], loc), loc) {
            out.push(t)
          }
        } else {
          // Keep mapped results lazy by constructing a call in a tiny environment.
          let scope : Env = {
            parent: None,
            names: Map([("f", self.store(Ready(x))), ("x", t)]),
          }
          out.push(
            self.store(
              Pending(
                {
                  kind: Call({ kind: Var("f"), loc, }, [
                    (None, { kind: Var("x"), loc, }),
                  ]),
                  loc,
                },
                scope,
              ),
            ),
          )
        }
      }
      ArrayValue(out)
    }
    "foldl" => {
      let a = array_value(values[1], loc)
      let mut acc = values[2]
      for t in a {
        acc = self.call(x, [(None, self.store(Ready(acc))), (None, t)], loc)
      }
      acc
    }
    "range" => {
      let start = integer(x, loc)
      let end = integer(values[1], loc)
      let out = []
      let mut i = start
      while i <= end {
        self.tick(loc)
        out.push(self.store(Ready(Num(i.to_double()))))
        if i == end {
          break
        }
        i += 1
      }
      ArrayValue(out)
    }
    "join" => {
      let a = array_value(values[1], loc)
      let mut result = match x {
        Str(_) => Str("")
        ArrayValue(_) => ArrayValue([])
        _ => raise problem(Type, loc, "join separator must be string or array")
      }
      let mut first = true
      for t in a {
        let v = self.force(t, loc)
        if v is Nil {
          continue
        }
        if value_type(v) != value_type(x) {
          raise problem(Type, loc, "join element and separator types differ")
        }
        if !first {
          result = self.binary("+", result, x, loc)
        }
        result = self.binary("+", result, v, loc)
        first = false
      }
      result
    }
    "split" => {
      let s = text_value(x, loc)
      let sep = text_value(values[1], loc)
      if sep.iter().count() != 1 {
        raise problem(Runtime, loc, "split separator must be one character")
      }
      ArrayValue(
        s.split(sep).map(s => self.store(Ready(Str(s.to_owned())))).collect(),
      )
    }
    "substr" => {
      let s = text_value(x, loc).to_array()
      let start = integer(values[1], loc)
      let len = integer(values[2], loc)
      if start < 0 || len < 0 {
        raise problem(Runtime, loc, "substr indices must be nonnegative")
      }
      let b = StringBuilder()
      let stop = Int::min(
        s.length(),
        if len > s.length() {
          s.length()
        } else {
          Int::min(start, s.length()) + len
        },
      )
      for i in Int::min(start, s.length())..<stop {
        b.write_char(s[i])
      }
      Str(b.to_string())
    }
    "strReplace" => {
      let s = text_value(x, loc)
      let from = text_value(values[1], loc)
      let to = text_value(values[2], loc)
      if from.is_empty() {
        raise problem(
          Unsupported,
          loc,
          "empty strReplace pattern is unsupported",
        )
      }
      let mut out = ""
      let mut first = true
      for part in s.split(from) {
        self.tick(loc)
        if !first {
          out = text_value(self.join_string(out, to, loc), loc)
        }
        out = text_value(self.join_string(out, part.to_owned(), loc), loc)
        first = false
      }
      Str(out)
    }
    "startsWith" =>
      Bool(text_value(x, loc).has_prefix(text_value(values[1], loc)))
    "endsWith" =>
      Bool(text_value(x, loc).has_suffix(text_value(values[1], loc)))
    "parseJson" => {
      let s = text_value(x, loc)
      check_json_depth(s, self.limits.depth, loc)
      let j = @json.parse(s) catch {
        _ => raise problem(Runtime, loc, "invalid JSON")
      }
      self.from_json(j, loc)
    }
    "manifestJson" => Str(self.manifest(x, loc, 0).stringify(indent=4))
    "toString" => Str(self.coerce_string(x, loc))
    "floor" => finite(number_value(x, loc).floor(), loc)
    "ceil" => finite(number_value(x, loc).ceil(), loc)
    "abs" => finite(number_value(x, loc).abs(), loc)
    _ => raise problem(Unsupported, loc, "unsupported std.\{name}")
  }
}

///|
// Core's optional parse-depth argument is deprecated. Bound nesting before
// calling its parser, respecting escapes inside JSON strings.
fn check_json_depth(s : String, limit : Int, loc : Location) -> Unit raise {
  let mut quoted = false
  let mut escaped = false
  let mut depth = 0
  for c in s.iter() {
    if quoted {
      if escaped {
        escaped = false
      } else if c == '\\' {
        escaped = true
      } else if c == '"' {
        quoted = false
      }
    } else if c == '"' {
      quoted = true
    } else if c == '[' || c == '{' {
      depth += 1
      if depth > limit {
        raise problem(Limit, loc, "JSON depth limit exceeded")
      }
    } else if c == ']' || c == '}' {
      depth -= 1
    }
  }
}

///|
fn integer(v : Value, loc : Location) -> Int raise {
  let n = number_value(v, loc)
  if n != n.floor() || n < -2147483648.0 || n > 2147483647.0 {
    raise problem(Runtime, loc, "expected 32-bit integer")
  }
  n.to_int()
}
