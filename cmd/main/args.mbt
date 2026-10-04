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
