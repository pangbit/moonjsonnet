///|
// Traverse visible fields. This is the stdlib String-rendering path; an object
// with no visible fields does not index assertions or hidden values.
fn Vm::manifest_json_ex(
  self : Vm,
  value : Value,
  style : (String, String, String),
  current_indent : String,
  depth : Int32,
  limit : Int32,
  loc : Location,
  path~ : Array[String] = [],
  style_thunks~ : (Int32, Int32, Int32)? = None,
) -> String raise {
  self.tick(loc)
  if depth >= self.limits.depth {
    raise problem(Limit, loc, "manifest depth limit exceeded")
  }
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
    Num(n) => {
      ignore(finite(n, loc))
      write(render_json(Json::number(n), false, 0, limit - size, loc))
    }
    Str(s) => write(manifest_json_quote(s))
    Closure(_, _, _) | Builtin(_) | Native(_) =>
      raise problem(
        Runtime,
        loc,
        "tried to manifest function at [" + path.join(" ") + "]",
      )
    ArrayValue(items) => {
      write("[")
      let newline = self.manifest_json_style(style, style_thunks, 1, loc)
      write(newline)
      let next_indent = if items.is_empty() {
        current_indent
      } else {
        current_indent + self.manifest_json_style(style, style_thunks, 0, loc)
      }
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
            path=path + [i.to_string()],
            style_thunks~,
          ),
        )
      }
      write(newline)
      write(current_indent)
      write("]")
    }
    ObjectValue(id, top) => {
      write("{")
      let newline = self.manifest_json_style(style, style_thunks, 1, loc)
      write(newline)
      let keys = self.keys(id, top, false)
      let next_indent = if keys.is_empty() {
        current_indent
      } else {
        current_indent + self.manifest_json_style(style, style_thunks, 0, loc)
      }
      for i, key in keys {
        if i > 0 {
          write(",")
          write(newline)
        }
        write(next_indent)
        write(manifest_json_quote(key))
        write(self.manifest_json_style(style, style_thunks, 2, loc))
        write(
          self.manifest_json_ex(
            self.field(id, top, key, loc),
            style,
            next_indent,
            depth + 1,
            limit - size,
            loc,
            path=path + [key],
            style_thunks~,
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
fn Vm::manifest_json_style(
  self : Vm,
  style : (String, String, String),
  pending : (Int32, Int32, Int32)?,
  slot : Int32,
  loc : Location,
) -> String raise {
  match pending {
    Some(ids) => {
      let id = match slot {
        0 => ids.0
        1 => ids.1
        _ => ids.2
      }
      text_value(self.force(id, loc), loc)
    }
    None =>
      match slot {
        0 => style.0
        1 => style.1
        _ => style.2
      }
  }
}

///|
// The fixed escapeStringJson definition quotes both String values and keys.
fn manifest_json_quote(s : String) -> String {
  manifest_text_quote(s)
}
