///|
// Traverse values directly: native Go manifests read visible fields, so an
// object with no visible fields does not force assertions or hidden values.
fn Vm::manifest_json_ex(
  self : Vm,
  value : Value,
  style : (String, String, String),
  current_indent : String,
  depth : Int,
  limit : Int,
  loc : Location,
) -> String raise {
  self.tick(loc)
  if depth >= self.limits.depth {
    raise problem(Limit, loc, "manifest depth limit exceeded")
  }
  let (indent, newline, key_separator) = style
  let output = StringBuilder()
  let mut size = 0
  let write = fn(s : String) raise {
    let bytes = @utf8.encode(s).length()
    if bytes > limit - size {
      raise problem(Limit, loc, "rendered JSON string exceeds output limit")
    }
    size += bytes
    output.write_string(s)
  }
  match value {
    Nil => write("null")
    Bool(b) => write(if b { "true" } else { "false" })
    Num(n) => write(manifest_number(n))
    Str(s) => write(manifest_json_quote(s))
    Closure(_, _, _) | Builtin(_) =>
      raise problem(Runtime, loc, "cannot manifest a function")
    ArrayValue(items) => {
      write("[")
      write(newline)
      let next_indent = current_indent + indent
      for i, item in items {
        if i > 0 {
          write(",")
          write(newline)
        }
        write(next_indent)
        write(
          self.manifest_json_ex(
            self.force(item, loc),
            style,
            next_indent,
            depth + 1,
            limit - size,
            loc,
          ),
        )
      }
      write(newline)
      write(current_indent)
      write("]")
    }
    ObjectValue(id, top) => {
      write("{")
      write(newline)
      let next_indent = current_indent + indent
      for i, key in self.keys(id, top, false) {
        if i > 0 {
          write(",")
          write(newline)
        }
        write(next_indent)
        write(manifest_json_quote(key))
        write(key_separator)
        write(
          self.manifest_json_ex(
            self.field(id, top, key, loc),
            style,
            next_indent,
            depth + 1,
            limit - size,
            loc,
          ),
        )
      }
      write(newline)
      write(current_indent)
      write("}")
    }
  }
  output.to_string()
}

///|
// encoding/json with EscapeHTML(false) still escapes JavaScript line separators.
fn manifest_json_quote(s : String) -> String {
  Json::string(s)
  .stringify()
  .replace(old="\u2028", new="\\u2028")
  .replace(old="\u2029", new="\\u2029")
}
