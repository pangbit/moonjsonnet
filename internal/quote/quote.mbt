// Go 1.24.0 strconv quoting rules. Copyright The Go Authors.
// BSD terms: licenses/GO-BSD-3-Clause.txt.

///|
fn lint_lower_bound(xs : Array[Int], n : Int) -> Int {
  let mut low = 0
  let mut high = xs.length()
  while low < high {
    let mid = low + (high - low) / 2
    if xs[mid] < n {
      low = mid + 1
    } else {
      high = mid
    }
  }
  low
}

///|
fn lint_printable(n : Int) -> Bool {
  if n <= 255 {
    return (n >= 32 && n <= 126) || (n >= 161 && n <= 255 && n != 173)
  }
  let ranges = if n < 65536 { lint_print16 } else { lint_print32 }
  let i = lint_lower_bound(ranges, n)
  if i >= ranges.length() || n < ranges[i & -2] || n > ranges[i | 1] {
    return false
  }
  if n >= 131072 {
    return true
  }
  let excluded = if n < 65536 { lint_not_print16 } else { lint_not_print32 }
  let key = if n < 65536 { n } else { n - 65536 }
  let j = lint_lower_bound(excluded, key)
  j >= excluded.length() || excluded[j] != key
}

///|
pub fn quote(s : String) -> String {
  let out = StringBuilder()
  out.write_char('"')
  for c in s {
    let n = c.to_int()
    match n {
      34 => out.write_string("\\\"")
      92 => out.write_string("\\\\")
      7 => out.write_string("\\a")
      8 => out.write_string("\\b")
      9 => out.write_string("\\t")
      10 => out.write_string("\\n")
      11 => out.write_string("\\v")
      12 => out.write_string("\\f")
      13 => out.write_string("\\r")
      _ =>
        if lint_printable(n) {
          out.write_char(c)
        } else {
          let digits = if n < 32 || n == 127 {
            out.write_string("\\x")
            2
          } else if n < 65536 {
            out.write_string("\\u")
            4
          } else {
            out.write_string("\\U")
            8
          }
          for i = digits - 1; i >= 0; i = i - 1 {
            out.write_char(
              "0123456789abcdef"[(n >> (i * 4)) & 15].to_char().unwrap(),
            )
          }
        }
    }
  }
  out.write_char('"')
  out.to_string()
}
