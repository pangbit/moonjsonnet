///|
// Go uses decimal Atoi, without underscores, spaces or radix prefixes.
fn trace_limit(value : String) -> Int raise {
  let digits = if value.has_prefix("+") || value.has_prefix("-") {
    value[1:]
  } else {
    value[:]
  }
  if digits.is_empty() || !digits.iter().all(c => c >= '0' && c <= '9') {
    fail("invalid --max-trace integer")
  }
  let n = @string.parse_int64(value, base=10)
  if n < 0L {
    fail("--max-trace must be nonnegative")
  }
  // Context arrays cannot have more than INT_MAX elements; preserve the
  // effect of Go's wider int range without narrowing an out-of-range value.
  if n > 2147483647L {
    2147483647
  } else {
    n.to_int()
  }
}

///|
// Match Go's preprocessing even for option values: bytes after a single '-'
// become separate short options. The first '--' preserves all later arguments.
fn simplify_args(args : Array[String]) -> Array[String] {
  let result = []
  let mut options = true
  for i, arg in args {
    if arg == "--" {
      options = false
    }
    let bytes = @utf8.encode(arg)
    if i > 0 &&
      options &&
      bytes.length() > 2 &&
      bytes[0] == 45 &&
      bytes[1] != 45 {
      for b in bytes[1:] {
        result.push("-" + b.to_int().to_char().unwrap().to_string())
      }
    } else {
      result.push(arg)
    }
  }
  result
}
