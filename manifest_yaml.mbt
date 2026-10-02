///|
// Adapted from go-jsonnet v0.21.0 native YAML rendering. See NOTICE and LICENSE.
fn yaml_bare_safe(s : String) -> Bool {
  let chars = s.to_array()
  if chars.is_empty() {
    return false
  }
  for c in chars {
    if !((c >= 'a' && c <= 'z') ||
      (c >= 'A' && c <= 'Z') ||
      (c >= '0' && c <= '9') ||
      c == '_' ||
      c == '-' ||
      c == '/' ||
      c == '.') {
      return false
    }
  }
  let lower = s.to_lower()
  if [
      "true", "false", "yes", "no", "on", "off", "y", "n", ".nan", "-.inf", ".inf",
      "null", "-", "---", "nan", "inf", "infinity", "-inf", "-infinity",
    ].contains(lower) {
    return false
  }
  // The reference timestamp regexp allows even empty digit groups.
  if chars.iter().all(c => (c >= '0' && c <= '9') || c == '-') &&
    chars.iter().filter(c => c == '-').count() == 2 {
    return false
  }
  let positive = if s.has_prefix("-") { s[1:].to_owned() } else { s }
  if positive.has_prefix("0b") &&
    positive.length() > 2 &&
    positive[2:].iter().all(c => c == '0' || c == '1' || c == '_') {
    return false
  }
  // Intentionally unanchored and case sensitive, like yamlHexPattern in Go.
  for i in 0..<(chars.length() - 2) {
    if chars[i] == '0' && chars[i + 1] == 'x' {
      let c = chars[i + 2]
      if (c >= '0' && c <= '9') ||
        (c >= 'a' && c <= 'f') ||
        (c >= 'A' && c <= 'F') ||
        c == '_' {
        return false
      }
    }
  }
  !yaml_decimal(s)
}

///|
// ParseFloat accepts decimal underscores only between digits. Overflow returns
// ErrRange and therefore does not disqualify a bare key; underflow is accepted.
fn yaml_decimal(s : String) -> Bool {
  let chars = s.to_array()
  let n = chars.length()
  let mut i = if chars[0] == '-' { 1 } else { 0 }
  let digits = fn() {
    let mut count = 0
    while i < n && ((chars[i] >= '0' && chars[i] <= '9') || chars[i] == '_') {
      if chars[i] == '_' {
        if count == 0 ||
          i + 1 == n ||
          chars[i - 1] == '_' ||
          chars[i + 1] < '0' ||
          chars[i + 1] > '9' {
          return -1
        }
      } else {
        count += 1
      }
      i += 1
    }
    count
  }
  let before = digits()
  if before < 0 {
    return false
  }
  let after = if i < n && chars[i] == '.' {
    i += 1
    digits()
  } else {
    0
  }
  if after < 0 || before + after == 0 {
    return false
  }
  if i < n && (chars[i] == 'e' || chars[i] == 'E') {
    i += 1
    if i < n && chars[i] == '-' {
      i += 1
    }
    if digits() <= 0 {
      return false
    }
  }
  if i != n {
    return false
  }
  let cleaned = s.replace(old="_", new="")
  try @string.parse_double(cleaned[:]) catch {
    _ => false
  } noraise {
    value => !value.is_inf()
  }
}

///|
fn Vm::yaml_value(
  self : Vm,
  value : Value,
  indent_arrays : Bool,
  quote_keys : Bool,
  current_indent : String,
  depth : Int,
  out : ManifestText,
  loc : Location,
) -> Unit raise {
  self.tick(loc)
  if depth >= self.limits.depth {
    raise problem(Limit, loc, "YAML depth limit exceeded")
  }
  match value {
    Nil => out.write("null")
    Bool(v) => out.write(if v { "true" } else { "false" })
    Num(v) => out.write(manifest_number(v))
    Str(s) =>
      if s.has_suffix("\n") {
        out.write("|")
        for line in s[:s.length() - 1].split("\n") {
          out.write("\n")
          out.write(current_indent)
          out.write("  ")
          out.write(line.to_owned())
        }
      } else {
        out.write(manifest_text_quote(s))
      }
    // Native Go omits a function case and returns an empty string.
    Closure(_, _, _) | Builtin(_) | Native(_) => ()
    ArrayValue(items) => {
      if items.is_empty() {
        out.write("[]")
        return
      }
      for i, t in items {
        if i > 0 {
          out.write("\n")
          out.write(current_indent)
        }
        let child = self.force(t, loc)
        out.write("-")
        if child is ArrayValue(a) && !a.is_empty() {
          out.write("\n")
          out.write(current_indent)
          out.write("  ")
        } else {
          out.write(" ")
        }
        let child_indent = match child {
          ArrayValue(_) | ObjectValue(_, _) => current_indent + "  "
          _ => current_indent
        }
        self.yaml_value(
          child,
          indent_arrays,
          quote_keys,
          child_indent,
          depth + 1,
          out,
          loc,
        )
      }
    }
    ObjectValue(id, top) => {
      let keys = self.keys(id, top, false)
      if keys.is_empty() {
        out.write("{}")
        return
      }
      for i, key in keys {
        let child = self.field(id, top, key, loc)
        if i > 0 {
          out.write("\n")
          out.write(current_indent)
        }
        out.write(
          if quote_keys || !yaml_bare_safe(key) {
            manifest_text_quote(key)
          } else {
            key
          },
        )
        out.write(":")
        let nested = match child {
          ArrayValue(a) => !a.is_empty()
          ObjectValue(oid, otop) => !self.keys(oid, otop, false).is_empty()
          _ => false
        }
        let child_indent = if nested {
          if child is ArrayValue(_) && !indent_arrays {
            current_indent
          } else {
            current_indent + "  "
          }
        } else {
          current_indent
        }
        if nested {
          out.write("\n")
          out.write(child_indent)
        } else {
          out.write(" ")
        }
        // Go discards this recursive call's error, keeping its partial output.
        // Resource limits remain mandatory and cannot be swallowed.
        self.yaml_value(
          child,
          indent_arrays,
          quote_keys,
          child_indent,
          depth + 1,
          out,
          loc,
        ) catch {
          Error(d) => if d.kind == Limit { raise Error(d) }
          e => raise e
        }
      }
    }
  }
}
