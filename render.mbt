///|
// Jsonnet standard-library string manifests have sorted keys and spaces even
// in compact form. Ordinary CLI JSON has no whitespace contract.
fn render_json(
  j : Json,
  pretty : Bool,
  depth : Int,
  limit : Int,
  loc : Location,
) -> String raise {
  let b = StringBuilder()
  let mut bytes = 0
  let write = fn(s : String) raise {
    let size = @utf8.encode(s).length()
    if size > limit - bytes {
      raise problem(Limit, loc, "rendered JSON string exceeds output limit")
    }
    bytes += size
    b.write_string(s)
  }
  let indent = fn(n) raise {
    for _ in 0..<n {
      write(" ")
    }
  }
  let separator = fn(first) raise {
    if !first {
      write(",")
    }
    if pretty {
      write("\n")
      indent((depth + 1) * 4)
    } else if !first {
      write(" ")
    }
  }
  match j {
    Array(items) => {
      write("[")
      for i, item in items {
        separator(i == 0)
        write(render_json(item, pretty, depth + 1, limit - bytes, loc))
      }
      if pretty && !items.is_empty() {
        write("\n")
        indent(depth * 4)
      }
      write("]")
    }
    Object(fields) => {
      let keys = fields.keys().collect()
      keys.sort_by(compare_unicode)
      write("{")
      for i, key in keys {
        separator(i == 0)
        write(Json::string(key).stringify())
        write(": ")
        write(render_json(fields[key], pretty, depth + 1, limit - bytes, loc))
      }
      if pretty && !keys.is_empty() {
        write("\n")
        indent(depth * 4)
      }
      write("}")
    }
    Number(n, ..) => {
      let text = @number.format(n)
      if text.is_empty() {
        fail("cannot format number in C numeric locale")
      }
      write(text)
    }
    _ => write(j.stringify())
  }
  b.to_string()
}
