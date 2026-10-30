///|
// Jsonnet standard-library string manifests have sorted keys and spaces even
// in compact form. Ordinary CLI JSON has no whitespace contract.
fn render_json(
  j : Json,
  pretty : Bool,
  depth : Int32,
  limit : Int32,
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
      if items.is_empty() {
        write(if pretty { "\n\n" } else { " " })
      }
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
      if keys.is_empty() {
        write(if pretty { "\n\n" } else { " " })
      }
      for i, key in keys {
        separator(i == 0)
        write(manifest_text_quote(key))
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
      let text = if pretty || n.is_inf() || n.is_nan() {
        manifest_number(n)
      } else {
        @number.format(n)
      }
      if text.is_empty() {
        fail("cannot format number in C numeric locale")
      }
      write(text)
    }
    String(text) => write(manifest_text_quote(text))
    _ => write(j.stringify())
  }
  b.to_string()
}

///|
// Go's manifestJson uses shortest round-trip digits in fixed decimal notation.
// Go's sum/avg may also produce non-finite values. Core supplies finite digits;
// expand its exponent and restore negative zero, which core prints as "0".
fn manifest_number(n : Double) -> String {
  if n.is_nan() {
    return "NaN"
  }
  if n.is_inf() {
    return if n < 0 { "-Inf" } else { "+Inf" }
  }
  let sign = if n.reinterpret_as_int64() < 0 { "-" } else { "" }
  let text = n.abs().to_string()
  guard text.find("e") is Some(e) else { return sign + text }
  let digits = text[:e].to_owned().replace(old=".", new="")
  let mut exponent = 0
  for c in text[e + 2:].iter() {
    exponent = exponent * 10 + c.to_int() - 48
  }
  if text.code_unit_at(e + 1) == 45 {
    sign + "0." + "0".repeat(exponent - 1) + digits
  } else {
    sign + digits + "0".repeat(exponent + 1 - digits.length())
  }
}
