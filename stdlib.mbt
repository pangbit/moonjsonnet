///|
fn builtin_names() -> Array[String] {
  [
    "extVar", "type", "isArray", "isBoolean", "isFunction", "isNumber", "isObject",
    "isString", "length", "objectFields", "objectFieldsAll", "objectHas", "objectHasAll",
    "map", "mapWithIndex", "makeArray", "reverse", "filter", "flatMap", "foldl",
    "foldr", "range", "join", "split", "substr", "strReplace", "startsWith", "endsWith",
    "parseJson", "manifestJson", "toString", "floor", "ceil", "abs", "format", "slice",
    "char", "codepoint", "assertEqual", "lines", "sort", "sha256", "objectFieldsEx",
    "objectHasEx", "primitiveEquals", "objectRemoveKey", "equals", "member", "contains",
    "minArray", "maxArray", "$flatMapArray", "sum", "avg", "sqrt", "hypot", "sin",
    "cos", "tan", "asin", "acos", "atan", "atan2", "log", "exp", "mantissa", "exponent",
    "round", "isEven", "isOdd", "isInteger", "isDecimal", "pow", "modulo", "xor",
    "xnor", "id", "parseInt", "isEmpty", "trim", "splitLimit", "splitLimitR", "equalsIgnoreCase",
    "lstripChars", "rstripChars", "stripChars", "base64", "base64Decode", "base64DecodeBytes",
    "encodeUTF8", "decodeUTF8", "manifestJsonEx", "remove", "removeAt", "$objectFlatMerge",
    "manifestTomlEx", "manifestYamlDoc", "md5", "sha1", "sha512", "sha3", "native",
    "trace", "parseYaml",
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
    ObjectValue(_, _) => "object"
    Closure(_, _, _) | Builtin(_) | Native(_) => "function"
  }
}

///|
fn builtin_params(name : String) -> Array[String] {
  match name {
    "native" => ["x"]
    "trace" => ["str", "rest"]
    "manifestYamlDoc" => ["value", "indent_array_in_object", "quote_keys"]
    "manifestTomlEx" => ["value", "indent"]
    "remove" => ["arr", "elem"]
    "removeAt" => ["arr", "i"]
    "$objectFlatMerge" => ["x"]
    "extVar" => ["x"]
    "isArray"
    | "isBoolean"
    | "isFunction"
    | "isNumber"
    | "isObject"
    | "isString" => ["v"]
    "toString" => ["a"]
    "type" | "length" | "floor" | "ceil" => ["x"]
    "sqrt"
    | "sin"
    | "cos"
    | "tan"
    | "asin"
    | "acos"
    | "atan"
    | "log"
    | "exp"
    | "mantissa"
    | "exponent"
    | "round"
    | "isEven"
    | "isOdd"
    | "isInteger"
    | "isDecimal" => ["x"]
    "hypot" => ["a", "b"]
    "modulo" | "xor" | "xnor" => ["x", "y"]
    "atan2" => ["y", "x"]
    "pow" => ["x", "n"]
    "id" => ["x"]
    "base64" => ["input"]
    "base64Decode" | "base64DecodeBytes" | "encodeUTF8" => ["str"]
    "decodeUTF8" => ["arr"]
    "parseInt" | "isEmpty" | "trim" => ["str"]
    "equalsIgnoreCase" => ["str1", "str2"]
    "lstripChars" | "rstripChars" | "stripChars" => ["str", "chars"]
    "splitLimit" | "splitLimitR" => ["str", "c", "maxsplits"]
    "abs" => ["n"]
    "objectFields" | "objectFieldsAll" => ["o"]
    "objectHas" | "objectHasAll" => ["o", "f"]
    "objectFieldsEx" => ["obj", "hidden"]
    "objectHasEx" => ["obj", "fname", "hidden"]
    "primitiveEquals" => ["x", "y"]
    "equals" => ["a", "b"]
    "objectRemoveKey" => ["obj", "key"]
    "member" => ["arr", "x"]
    "contains" => ["arr", "elem"]
    "map" | "mapWithIndex" | "filter" | "flatMap" | "$flatMapArray" =>
      ["func", "arr"]
    "makeArray" => ["sz", "func"]
    "reverse" | "sum" | "avg" => ["arr"]
    "sort" => ["arr", "keyF"]
    "minArray" | "maxArray" => ["arr", "keyF", "onEmpty"]
    "md5" | "sha1" | "sha256" | "sha512" | "sha3" => ["s"]
    "foldl" | "foldr" => ["func", "arr", "init"]
    "range" => ["from", "to"]
    "join" => ["sep", "arr"]
    "split" => ["str", "c"]
    "substr" => ["str", "from", "len"]
    "strReplace" => ["str", "from", "to"]
    "startsWith" => ["a", "b"]
    "endsWith" => ["a", "b"]
    "parseJson" | "parseYaml" => ["str"]
    "manifestJson" => ["value"]
    "manifestJsonEx" => ["value", "indent", "newline", "key_val_sep"]
    "format" => ["str", "vals"]
    "slice" => ["indexable", "index", "end", "step"]
    "char" => ["n"]
    "codepoint" => ["str"]
    "assertEqual" => ["a", "b"]
    "lines" => ["arr"]
    _ => []
  }
}

///|
fn Vm::builtin(
  self : Vm,
  name : String,
  args : Array[(String?, Int)],
  loc : Location,
  strict? : Bool = false,
) -> Value raise {
  let params = builtin_params(name)
  let required = if name == "sort" ||
    name == "minArray" ||
    name == "maxArray" ||
    name == "manifestYamlDoc" {
    1
  } else if name == "manifestJsonEx" {
    2
  } else {
    params.length()
  }
  let ids = bind_arguments(
    params.mapi((index, name) => (name, index < required)),
    args,
    loc,
  )
  if name == "manifestJsonEx" {
    for key in ["value", "indent"] {
      if !ids.contains(key) {
        raise problem(Runtime, loc, "std.manifestJsonEx: missing " + key)
      }
    }
    for (key, default_value) in [("newline", "\n"), ("key_val_sep", ": ")] {
      if !ids.contains(key) {
        ids[key] = self.store(Ready(Str(default_value)))
      }
    }
  }
  if name == "manifestYamlDoc" {
    if !ids.contains("value") {
      raise problem(Runtime, loc, "std.manifestYamlDoc: missing value")
    }
    for
      (key, default_value) in [
        ("indent_array_in_object", false),
        ("quote_keys", true),
      ] {
      if !ids.contains(key) {
        ids[key] = self.store(Ready(Bool(default_value)))
      }
    }
  }
  if strict {
    // Match Closure calls: validate binding first, then force parameter heads
    // in declaration order, including defaults, before any builtin shortcut.
    for key in params {
      match ids.get(key) {
        Some(id) => ignore(self.force(id, loc))
        None =>
          if key == "onEmpty" && (name == "minArray" || name == "maxArray") {
            raise problem(
              Runtime,
              loc,
              "Expected at least one element in array. Got none",
            )
          }
        // The only other omitted default is sort/extrema's identity function;
        // its function head is already a value and has no deferred work.
      }
    }
  }
  if name == "sort" || name == "minArray" || name == "maxArray" {
    guard ids.get("arr") is Some(arr) else {
      raise problem(Runtime, loc, "std.\{name}: missing arr argument")
    }
    let input = self.force(arr, loc)
    if name == "sort" {
      return self.sort_values(input, ids.get("keyF"), loc)
    }
    return self.extreme_value(
      input,
      ids.get("keyF"),
      ids.get("onEmpty"),
      name == "maxArray",
      loc,
    )
  }
  if name == "foldl" || name == "foldr" {
    return self.fold_sequence(
      name,
      self.force(ids["arr"], loc),
      ids["func"],
      ids["init"],
      loc,
    )
  }
  if name == "flatMap" {
    let func = self.force(ids["func"], loc)
    if value_type(func) != "function" {
      raise problem(
        Type,
        loc,
        "Unexpected type " + value_type(func) + ", expected function",
      )
    }
    return self.flat_map(func, self.force(ids["arr"], loc), loc)
  }
  if name == "manifestJsonEx" {
    return Str(
      self.manifest_json_ex(
        self.force(ids["value"], loc),
        ("", "", ""),
        "",
        0,
        self.limits.output_bytes,
        loc,
        style_thunks=Some((ids["indent"], ids["newline"], ids["key_val_sep"])),
      ),
    )
  }
  if name == "manifestTomlEx" {
    // Flat fields and empty tables need no indentation. Keep the style thunk
    // until the renderer actually emits an indented prefix.
    return Str(
      self.toml_table(
        self.force(ids["value"], loc),
        ids["indent"],
        [],
        0,
        0,
        loc,
      ),
    )
  }
  if name == "lstripChars" || name == "rstripChars" || name == "stripChars" {
    // The fixed source checks str length before demanding the character set.
    return self.strip_characters(
      self.force(ids["str"], loc),
      ids["chars"],
      name,
      loc,
    )
  }
  if name == "splitLimit" || name == "splitLimitR" {
    let input = text_value(self.force(ids["str"], loc), loc)
    let separator = text_value(self.force(ids["c"], loc), loc)
    return self.split_limit(
      input,
      separator,
      ids["maxsplits"],
      name == "splitLimitR",
      loc,
    )
  }
  if name == "member" || name == "contains" {
    let target = if name == "member" { ids["x"] } else { ids["elem"] }
    return self.membership(
      self.force(ids["arr"], loc),
      target,
      name == "contains",
      loc,
    )
  }
  if name == "manifestYamlDoc" {
    let out = ManifestText::new(self.limits.output_bytes, loc)
    self.yaml_value(
      self.force(ids["value"], loc),
      false,
      true,
      "",
      0,
      out,
      loc,
      option_thunks=Some((ids["indent_array_in_object"], ids["quote_keys"])),
    )
    return Str(out.text())
  }
  let values = if name == "join" {
    // The fixed source rejects arr before inspecting the separator.
    let arr = self.force(ids["arr"], loc)
    ignore(array_value(arr, loc))
    [self.force(ids["sep"], loc), arr]
  } else {
    params.map(n => self.force(ids[n], loc))
  }
  let x = values[0]
  match name {
    "native" =>
      match self.native_functions.get(text_value(x, loc)) {
        Some(f) => Native(f)
        None => Nil
      }
    "trace" => {
      (self.trace)(loc, text_value(x, loc))
      values[1]
    }
    "parseYaml" => self.parse_yaml(text_value(x, loc), loc)
    "manifestYamlDoc" => {
      let out = ManifestText::new(self.limits.output_bytes, loc)
      self.yaml_value(
        x,
        boolean(values[1], loc),
        boolean(values[2], loc),
        "",
        0,
        out,
        loc,
      )
      Str(out.text())
    }
    "$objectFlatMerge" => self.object_flat_merge(array_value(x, loc), loc)
    "removeAt" =>
      self.remove_at(array_value(x, loc), integer(values[1], loc), loc)
    "remove" => {
      let items = array_value(x, loc)
      let mut found = -1
      for i, t in items {
        self.tick(loc)
        if self.equal(self.force(t, loc), values[1], loc) {
          found = i
          break
        }
      }
      if found < 0 {
        x
      } else {
        self.remove_at(items, found, loc)
      }
    }
    "base64"
    | "base64Decode"
    | "base64DecodeBytes"
    | "encodeUTF8"
    | "decodeUTF8" => self.encoding_builtin(name, x, loc)
    "id" => x
    "parseInt" => parse_decimal(text_value(x, loc), loc)
    "isEmpty" => Bool(text_value(x, loc).is_empty())
    "trim" => Str(trim_space(text_value(x, loc)))
    "equalsIgnoreCase" =>
      Bool(equal_fold(text_value(x, loc), text_value(values[1], loc)))
    "sqrt"
    | "hypot"
    | "sin"
    | "cos"
    | "tan"
    | "asin"
    | "acos"
    | "atan"
    | "atan2"
    | "log"
    | "exp"
    | "mantissa"
    | "exponent"
    | "round"
    | "isEven"
    | "isOdd"
    | "isInteger"
    | "isDecimal"
    | "pow"
    | "modulo"
    | "xor"
    | "xnor" => math_builtin(name, values, loc)
    "sum" | "avg" => {
      let items = array_value(x, loc)
      if name == "avg" && items.is_empty() {
        raise problem(
          Runtime,
          loc,
          "Cannot calculate average of an empty array.",
        )
      }
      // The fixed sum fold uses ordinary +, including String coercion. Keep
      // each new accumulator strict, with numeric finite checks in binary().
      let mut sum : Value = Num(0.0)
      for t in items {
        self.tick(loc)
        sum = self.binary("+", sum, self.force(t, loc), loc)
      }
      if name == "avg" {
        self.binary("/", sum, Num(items.length().to_double()), loc)
      } else {
        sum
      }
    }
    "equals" => Bool(self.equal(x, values[1], loc))
    "objectRemoveKey" => {
      guard x is ObjectValue(id, top) else {
        raise problem(Type, loc, "expected object")
      }
      let key = text_value(values[1], loc)
      let layers = []
      for i in 0..<top {
        self.tick(loc)
        let layer = self.objects[id].layers[i]
        let fields : Map[String, LayerField] = Map([])
        for name, field in layer.fields {
          self.tick(loc)
          if name != key {
            fields[name] = field
          }
        }
        layers.push({ ..layer, fields, assertions: [], assertion_sites: [], })
      }
      self.object_value(layers)
    }
    "primitiveEquals" => {
      let y = values[1]
      if value_type(x) != value_type(y) {
        Bool(false)
      } else {
        match x {
          ArrayValue(_)
          | ObjectValue(_, _)
          | Closure(_, _, _)
          | Builtin(_)
          | Native(_) =>
            raise problem(
              Type,
              loc,
              "primitiveEquals operates on primitive types, got " +
              value_type(x),
            )
          _ => Bool(self.equal(x, y, loc))
        }
      }
    }
    "sha256" => Str(self.sha256(text_value(x, loc), loc))
    "md5" => Str(self.md5(text_value(x, loc), loc))
    "sha1" => Str(self.sha1(text_value(x, loc), loc))
    "sha512" => Str(self.sha512(text_value(x, loc), loc))
    "sha3" => Str(self.sha3(text_value(x, loc), loc))
    "$flatMapArray" => {
      ignore(array_value(values[1], loc))
      self.flat_map(x, values[1], loc)
    }
    "lines" => {
      let mut result = Str("")
      for t in array_value(x, loc) {
        let v = self.force(t, loc)
        if v is Nil {
          continue
        }
        result = self.join_string(
          text_value(result, loc),
          text_value(v, loc),
          loc,
        )
        result = self.join_string(text_value(result, loc), "\n", loc)
      }
      result
    }
    "format" => Str(self.format_string(text_value(x, loc), values[1], loc))
    "slice" => self.slice(x, values[1], values[2], values[3], loc)
    "char" => {
      let n = number_value(x, loc)
      if n > 1114111 {
        raise problem(
          Runtime,
          loc,
          "Invalid unicode codepoint, got " + diagnostic_number(n),
        )
      }
      if n < 0 {
        raise problem(
          Runtime,
          loc,
          "Codepoints must be >= 0, got " + diagnostic_number(n),
        )
      }
      if n != n.trunc() {
        raise problem(
          Runtime,
          loc,
          "Codepoints must be integers, got " + diagnostic_number(n),
        )
      }
      // Go's rune-to-string conversion replaces surrogate code points.
      let c = @number.reference_rune(n).to_char().unwrap_or('�')
      Str(c.to_string())
    }
    "codepoint" => {
      let chars = text_value(x, loc).to_array()
      if chars.length() != 1 {
        raise problem(
          Runtime,
          loc,
          "codepoint takes a string of length 1, got length " +
          chars.length().to_string(),
        )
      }
      Num(chars[0].to_int().to_double())
    }
    "assertEqual" => {
      if !self.equal(x, values[1], loc) {
        raise problem(Assertion, loc, "values are not equal")
      }
      Bool(true)
    }
    "extVar" => self.force(self.external_parameter(x, loc), loc)
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
          Native(f) => f.params.length().to_double()
          Builtin(n) => builtin_params(n).length().to_double()
          _ => raise problem(Type, loc, "Unexpected type " + value_type(x))
        },
      )
    "objectFields"
    | "objectFieldsAll"
    | "objectHas"
    | "objectHasAll"
    | "objectFieldsEx"
    | "objectHasEx" => {
      guard x is ObjectValue(id, top) else {
        raise problem(
          Type,
          loc,
          "Unexpected type " + value_type(x) + ", expected object",
        )
      }
      let hidden = match name {
        "objectFieldsEx" => boolean(values[1], loc)
        "objectHasEx" => boolean(values[2], loc)
        _ => name == "objectFieldsAll" || name == "objectHasAll"
      }
      if name == "objectHas" || name == "objectHasAll" || name == "objectHasEx" {
        let k = text_value(values[1], loc)
        Bool(self.has_field(id, top, k) && (hidden || self.visible(id, top, k)))
      } else {
        ArrayValue(
          self.keys(id, top, hidden).map(k => self.store(Ready(Str(k)))),
        )
      }
    }
    "makeArray" => {
      let size = integer(x, loc)
      if size < 0 {
        raise problem(Runtime, loc, "makeArray size must be non-negative")
      }
      let func = values[1]
      if value_type(func) != "function" {
        raise problem(
          Type,
          loc,
          "Unexpected type " + value_type(values[1]) + ", expected function",
        )
      }
      let out = []
      for i in 0..<size {
        self.tick(loc)
        let index = self.store(Ready(Num(i.to_double())))
        out.push(self.defer_call(func, [index], loc))
      }
      ArrayValue(out)
    }
    "reverse" => {
      let a = array_value(x, loc)
      let out = []
      for i in 0..<a.length() {
        self.tick(loc)
        out.push(a[a.length() - i - 1])
      }
      ArrayValue(out)
    }
    "map" | "mapWithIndex" | "filter" => {
      let a = if name != "filter" {
        self.sequence(values[1], loc)
      } else {
        array_value(values[1], loc)
      }
      let out = []
      if value_type(x) != "function" {
        raise problem(
          Type,
          loc,
          "Unexpected type " + value_type(values[0]) + ", expected function",
        )
      }
      for i, t in a {
        self.tick(loc)
        if name == "filter" {
          if boolean(self.call(x, [(None, t)], loc), loc) {
            out.push(a[i])
          }
        } else {
          let element = if values[1] is ArrayValue(_) {
            self.defer_index(values[1], i.to_double(), loc)
          } else {
            t
          }
          let call_args = if name == "mapWithIndex" {
            [self.store(Ready(Num(i.to_double()))), element]
          } else {
            [element]
          }
          out.push(self.defer_call(x, call_args, loc))
        }
      }
      ArrayValue(out)
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
        _ =>
          raise problem(
            Type,
            loc,
            "join first parameter should be string or array, got " +
            value_type(x),
          )
      }
      let mut first = true
      for t in a {
        let v = self.force(t, loc)
        if v is Nil {
          continue
        }
        if value_type(v) != value_type(x) {
          raise problem(
            Type,
            loc,
            "Unexpected type " + value_type(v) + ", expected " + value_type(x),
          )
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
      if sep.is_empty() {
        raise problem(Runtime, loc, "split separator must be nonempty")
      }
      ArrayValue(
        s.split(sep).map(s => self.store(Ready(Str(s.to_owned())))).collect(),
      )
    }
    "substr" => {
      guard x is Str(s) else {
        raise problem(
          Runtime,
          loc,
          "substr first parameter should be a string, got " + value_type(x),
        )
      }
      guard values[1] is Num(from) else {
        raise problem(
          Runtime,
          loc,
          "substr second parameter should be a number, got " +
          value_type(values[1]),
        )
      }
      if from != from.trunc() {
        raise problem(
          Runtime,
          loc,
          "substr second parameter should be an integer, got " +
          @number.diagnostic_fixed(from),
        )
      }
      if from < 0 {
        raise problem(
          Runtime,
          loc,
          "substr second parameter should be greater than zero, got " +
          @number.diagnostic_fixed(from),
        )
      }
      guard values[2] is Num(length) else {
        raise problem(
          Runtime,
          loc,
          "substr third parameter should be a number, got " +
          value_type(values[2]),
        )
      }
      if length != length.trunc() ||
        length < -2147483648.0 ||
        length > 2147483647.0 {
        raise problem(
          Runtime,
          loc,
          "substr third parameter should be an integer, got " +
          @number.diagnostic_fixed(length),
        )
      }
      let len = length.to_int()
      if len < 0 {
        raise problem(
          Runtime,
          loc,
          "substr third parameter should be greater than zero, got " +
          len.to_string(),
        )
      }
      let s = s.to_array()
      let start = if from > s.length().to_double() {
        s.length()
      } else {
        from.to_int()
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
        raise problem(Assertion, loc, "'from' string must not be zero length.")
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
        _ =>
          raise problem(
            Runtime,
            loc,
            "failed to parse JSON: " + self.json_syntax_error(s, loc),
          )
      }
      // Parsed data must be finite before any caller observes its shape.
      self.check_json_finite(j, self.depth, loc)
      self.from_json(j, loc)
    }
    "manifestJson" =>
      Str(
        self.manifest_json_ex(
          x,
          ("    ", "\n", ": "),
          "",
          0,
          self.limits.output_bytes,
          loc,
        ),
      )
    "toString" => Str(self.coerce_string(x, loc))
    "floor" => finite(number_value(x, loc).floor(), loc)
    "ceil" => finite(number_value(x, loc).ceil(), loc)
    "abs" => {
      let n = number_value(x, loc)
      Num(if n > 0 { n } else { -n })
    }
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
fn Vm::check_json_finite(
  self : Vm,
  value : Json,
  depth : Int,
  loc : Location,
) -> Unit raise {
  if depth >= self.limits.depth {
    raise problem(Limit, loc, "JSON value depth limit exceeded")
  }
  self.tick(loc)
  match value {
    Number(n, ..) => ignore(finite(n, loc))
    Array(items) =>
      for item in items {
        self.check_json_finite(item, depth + 1, loc)
      }
    Object(fields) =>
      for _, item in fields {
        self.check_json_finite(item, depth + 1, loc)
      }
    _ => ()
  }
}

///|
fn integer(v : Value, loc : Location) -> Int raise {
  let n = number_value(v, loc)
  if n != n.floor() || n < -2147483648.0 || n > 2147483647.0 {
    raise problem(
      Runtime,
      loc,
      "Expected an integer, but got " + diagnostic_number(n),
    )
  }
  n.to_int()
}
