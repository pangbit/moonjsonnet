///|
// Jsonnet standard-library string manifests have sorted keys and spaces even
// in compact form. Ordinary CLI JSON has no whitespace contract.
fn render_json(j : Json, pretty : Bool, depth : Int) -> String raise {
  let b = StringBuilder()
  let indent = fn(n) {
    for _ in 0..<n {
      b.write_char(' ')
    }
  }
  let separator = fn(first) {
    if !first {
      b.write_char(',')
    }
    if pretty {
      b.write_char('\n')
      indent((depth + 1) * 4)
    } else if !first {
      b.write_char(' ')
    }
  }
  match j {
    Array(items) => {
      b.write_char('[')
      for i, item in items {
        separator(i == 0)
        b.write_string(render_json(item, pretty, depth + 1))
      }
      if pretty && !items.is_empty() {
        b.write_char('\n')
        indent(depth * 4)
      }
      b.write_char(']')
    }
    Object(fields) => {
      let keys = fields.keys().collect()
      keys.sort_by(compare_unicode)
      b.write_char('{')
      for i, key in keys {
        separator(i == 0)
        b.write_string(Json::string(key).stringify())
        b.write_string(": ")
        b.write_string(render_json(fields[key], pretty, depth + 1))
      }
      if pretty && !keys.is_empty() {
        b.write_char('\n')
        indent(depth * 4)
      }
      b.write_char('}')
    }
    Number(n, ..) => {
      let text = @number.format(n)
      if text.is_empty() {
        fail("cannot format number in C numeric locale")
      }
      b.write_string(text)
    }
    _ => b.write_string(j.stringify())
  }
  b.to_string()
}
