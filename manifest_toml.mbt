// Portions adapted from google/go-jsonnet v0.21.0 (Apache-2.0).
// https://github.com/google/go-jsonnet/tree/67968688d9952f50662e979fab1bef889d0d3e57
// Source: builtins.go
// Source: interpreter.go
// Copyright 2017 Google Inc. All rights reserved.
// Copyright 2016 Google Inc. All rights reserved.
// Modifications: Ported native text-rendering and quoting paths to MoonBit values with output budgets.
// License and retained attribution: LICENSE and NOTICE at the module root.

///|
// Adapted from go-jsonnet v0.21.0 native TOML rendering. See NOTICE and LICENSE.
fn toml_key(key : String) -> String {
  if key.is_empty() {
    return "''"
  }
  if key
    .iter()
    .all(c => {
      (c >= 'a' && c <= 'z') ||
      (c >= 'A' && c <= 'Z') ||
      (c >= '0' && c <= '9') ||
      c == '_' ||
      c == '-'
    }) {
    key
  } else {
    manifest_text_quote(key)
  }
}

///|
// A level-zero prefix never uses indent. In particular, passing through an
// empty nested table must not demand the next level's formatting argument.
fn Vm::toml_indent(
  self : Vm,
  indent : Int32,
  level : Int32,
  loc : Location,
) -> String raise {
  if level == 0 {
    return ""
  }
  let unit = text_value(self.force(indent, loc), loc)
  let out = ManifestText::new(self.limits.output_bytes, loc)
  for _ in 0..<level {
    out.write(unit)
  }
  out.text()
}

///|
fn Vm::toml_section(self : Vm, value : Value, loc : Location) -> Bool raise {
  match value {
    ObjectValue(_, _) => true
    ArrayValue(items) => {
      if items.is_empty() {
        return false
      }
      for t in items {
        if !(self.force(t, loc) is ObjectValue(_, _)) {
          return false
        }
      }
      true
    }
    _ => false
  }
}

///|
fn Vm::toml_value(
  self : Vm,
  value : Value,
  indent : Int32,
  inline : Bool,
  depth : Int32,
  loc : Location,
  indexed_path~ : Array[String] = [],
) -> String raise {
  self.tick(loc)
  if depth >= self.limits.depth {
    raise problem(Limit, loc, "TOML depth limit exceeded")
  }
  let out = ManifestText::new(self.limits.output_bytes, loc)
  match value {
    Nil =>
      raise problem(
        Runtime,
        loc,
        "Tried to manifest \"null\" at [" + indexed_path.join(" ") + "]",
      )
    Closure(_, _, _) | Builtin(_) | Native(_) =>
      raise problem(
        Runtime,
        loc,
        "Tried to manifest function at [" + indexed_path.join(" ") + "]",
      )
    Bool(v) => out.write(if v { "true" } else { "false" })
    Num(v) =>
      out.write(
        if v.is_inf() || v.is_nan() {
          manifest_number(v)
        } else {
          @number.format(v)
        },
      )
    Str(v) => out.write(manifest_text_quote(v))
    ArrayValue(items) => {
      if items.is_empty() {
        return "[]"
      }
      let separator = if inline { " " } else { "\n" }
      out.write("[")
      out.write(separator)
      for i, t in items {
        if i > 0 {
          out.write(",")
          out.write(separator)
        }
        if !inline {
          out.write(self.toml_indent(indent, 1, loc))
        }
        out.write(
          self.toml_value(
            self.force(t, loc),
            indent,
            true,
            depth + 1,
            loc,
            indexed_path=indexed_path + [i.to_string()],
          ),
        )
      }
      out.write(separator)
      out.write("]")
    }
    ObjectValue(id, top) => {
      out.write("{ ")
      for i, key in self.keys(id, top, false) {
        if i > 0 {
          out.write(", ")
        }
        let value = self.field(id, top, key, loc)
        out.write(toml_key(key))
        out.write(" = ")
        out.write(
          self.toml_value(
            value,
            indent,
            true,
            depth + 1,
            loc,
            indexed_path=indexed_path + [key],
          ),
        )
      }
      out.write(" }")
    }
  }
  out.text()
}

///|
fn Vm::toml_table(
  self : Vm,
  value : Value,
  indent : Int32,
  path : Array[String],
  indent_level : Int32,
  depth : Int32,
  loc : Location,
  indexed_path~ : Array[String] = [],
) -> String raise {
  self.tick(loc)
  if depth >= self.limits.depth {
    raise problem(Limit, loc, "TOML depth limit exceeded")
  }
  guard value is ObjectValue(id, top) else {
    raise problem(
      Type,
      loc,
      "TOML body must be an object. Got " + value_type(value),
    )
  }
  let fields = ManifestText::new(self.limits.output_bytes, loc)
  let sections = ManifestText::new(self.limits.output_bytes, loc)
  let mut first = true
  // Render each key in order, even though scalar fields are ultimately emitted
  // before sections. Classification and rendering may evaluate lazy values.
  for key in self.keys(id, top, false) {
    let child = self.field(id, top, key, loc)
    if self.toml_section(child, loc) {
      let child_path = path + [key]
      let header = child_path.map(toml_key).join(".")
      let tables = match child {
        ArrayValue(items) => items
        _ => [self.store(Ready(child))]
      }
      let array_table = child is ArrayValue(_)
      for index, t in tables {
        let obj = self.force(t, loc)
        guard obj is ObjectValue(oid, otop) else {
          raise problem(Type, loc, "expected TOML table")
        }
        sections.write("\n\n")
        sections.write(self.toml_indent(indent, indent_level, loc))
        sections.write(if array_table { "[[" } else { "[" })
        sections.write(header)
        sections.write(if array_table { "]]" } else { "]" })
        if !self.keys(oid, otop, false).is_empty() {
          sections.write("\n")
        }
        sections.write(
          self.toml_table(
            obj,
            indent,
            child_path,
            indent_level + 1,
            depth + 1,
            loc,
            indexed_path=indexed_path +
              [key] +
              (if array_table { [index.to_string()] } else { [] }),
          ),
        )
      }
    } else {
      let rendered = self.toml_value(
        child,
        indent,
        false,
        depth + 1,
        loc,
        indexed_path=indexed_path + [key],
      )
      let line = toml_key(key) + " = " + rendered
      for part in line.split("\n") {
        if !first {
          fields.write("\n")
        }
        first = false
        fields.write(self.toml_indent(indent, indent_level, loc))
        fields.write(part.to_owned())
      }
    }
  }
  fields.write(sections.text())
  fields.text()
}
