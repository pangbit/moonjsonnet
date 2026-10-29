// Portions adapted from google/go-jsonnet v0.21.0 (Apache-2.0).
// https://github.com/google/go-jsonnet/tree/67968688d9952f50662e979fab1bef889d0d3e57
// Source: builtins.go
// Source: interpreter.go
// Copyright 2017 Google Inc. All rights reserved.
// Copyright 2016 Google Inc. All rights reserved.
// Modifications: Ported native text-rendering and quoting paths to MoonBit values with output budgets.
// License and retained attribution: LICENSE and NOTICE at the module root.

///|
priv struct ManifestText {
  buffer : StringBuilder
  mut bytes : Int
  limit : Int
  loc : Location
}

///|
fn ManifestText::new(limit : Int, loc : Location) -> ManifestText {
  { buffer: StringBuilder(), bytes: 0, limit, loc, }
}

///|
fn ManifestText::write(self : ManifestText, s : String) -> Unit raise {
  let size = @utf8.encode(s).length()
  if size > self.limit - self.bytes {
    raise problem(Limit, self.loc, "manifest output limit exceeded")
  }
  self.bytes += size
  self.buffer.write_string(s)
}

///|
fn ManifestText::text(self : ManifestText) -> String {
  self.buffer.to_string()
}

///|
// Shared JSON, TOML and YAML quoting escapes C0/C1 but leaves HTML and
// U+2028/U+2029 raw, matching the fixed escapeStringJson String policy.
fn manifest_text_quote(s : String) -> String {
  let out = StringBuilder()
  out.write_string("\"")
  for c in s.iter() {
    out.write_string(
      match c {
        '"' => "\\\""
        '\\' => "\\\\"
        '\b' => "\\b"
        '\u000c' => "\\f"
        '\n' => "\\n"
        '\r' => "\\r"
        '\t' => "\\t"
        _ => {
          let n = c.to_int()
          if n < 32 || (n >= 127 && n <= 159) {
            let hex = "0123456789abcdef".to_array()
            "\\u00" + hex[n / 16].to_string() + hex[n % 16].to_string()
          } else {
            c.to_string()
          }
        }
      },
    )
  }
  out.write_string("\"")
  out.to_string()
}
