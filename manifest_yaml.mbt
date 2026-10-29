// Portions adapted from google/go-jsonnet v0.21.0 (Apache-2.0).
// https://github.com/google/go-jsonnet/tree/67968688d9952f50662e979fab1bef889d0d3e57
// Source: builtins.go
// Source: interpreter.go
// Copyright 2017 Google Inc. All rights reserved.
// Copyright 2016 Google Inc. All rights reserved.
// Modifications: Ported native text-rendering and quoting paths to MoonBit values with output budgets.
// License and retained attribution: LICENSE and NOTICE at the module root.

///|
// Adapted from Jsonnet v0.21.0 std.manifestYamlDoc bareSafe (Apache-2.0).
// https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1089-L1220
// Copyright 2015 Google Inc. All rights reserved. See NOTICE and LICENSE.
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
      "true", "false", "yes", "no", "on", "off", "y", "n", ".nan", "-.inf", "+.inf",
      ".inf", "null", "-", "---", "",
    ].contains(lower) {
    return false
  }
  let lower_chars = lower.to_array()
  let dashes = chars.iter().filter(c => c == '-').count()
  // These are the fixed source's conservative character/count predicates,
  // including malformed-looking numeric shapes; they do not parse numbers.
  if chars.iter().all(c => (c >= '0' && c <= '9') || c == '-') && dashes == 2 {
    return false
  }
  if lower_chars.iter().all(c => (c >= '0' && c <= '9') || c == '_' || c == '-') &&
    dashes < 2 {
    return false
  }
  if lower_chars
    .iter()
    .all(c => (c >= '0' && c <= '9') || c == '_' || c == '-' || c == 'b') &&
    chars.length() > 2 &&
    (s.has_prefix("0b") || s.has_prefix("-0b")) {
    return false
  }
  if lower_chars
    .iter()
    .all(c => {
      (c >= '0' && c <= '9') || c == 'e' || c == '.' || c == '_' || c == '-'
    }) &&
    chars.iter().filter(c => c == '.').count() == 1 &&
    dashes < 3 &&
    lower_chars.iter().filter(c => c == 'e').count() < 2 {
    return false
  }
  if lower_chars
    .iter()
    .all(c => {
      (c >= '0' && c <= '9') ||
      (c >= 'a' && c <= 'f') ||
      c == 'x' ||
      c == '_' ||
      c == '-'
    }) &&
    dashes < 2 &&
    chars.length() > 2 &&
    (s.has_prefix("0x") || s.has_prefix("-0x")) {
    return false
  }
  true
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
  option_thunks? : (Int, Int)? = None,
) -> Unit raise {
  self.tick(loc)
  if depth >= self.limits.depth {
    raise problem(Limit, loc, "YAML depth limit exceeded")
  }
  match value {
    Nil => out.write("null")
    Bool(v) => out.write(if v { "true" } else { "false" })
    Num(v) => {
      ignore(finite(v, loc))
      out.write(
        render_json(Json::number(v), false, 0, out.limit - out.bytes, loc),
      )
    }
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
    Closure(_, _, _) | Builtin(_) | Native(_) =>
      raise problem(Runtime, loc, "couldn't manifest function as YAML")
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
          option_thunks~,
        )
      }
    }
    ObjectValue(id, top) => {
      let keys = self.keys(id, top, false)
      if keys.is_empty() {
        out.write("{}")
        return
      }
      let quote_keys = match option_thunks {
        Some((_, key_option)) => boolean(self.force(key_option, loc), loc)
        None => quote_keys
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
          let add_indent = if child is ArrayValue(_) {
            match option_thunks {
              Some((array_option, _)) =>
                boolean(self.force(array_option, loc), loc)
              None => indent_arrays
            }
          } else {
            true
          }
          if add_indent {
            current_indent + "  "
          } else {
            current_indent
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
        self.yaml_value(
          child,
          indent_arrays,
          quote_keys,
          child_indent,
          depth + 1,
          out,
          loc,
          option_thunks~,
        )
      }
    }
  }
}
