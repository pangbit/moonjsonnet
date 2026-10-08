///|
test "OS failures are consumed and successful operations clear stale errors" {
  let missing = "__moonjsonnet_missing_io_error_regression__"
  assert_eq(canonical_result(missing).0, 6)
  assert_eq(
    io_error(missing),
    Some("open " + missing + ": no such file or directory"),
  )
  assert_eq(io_error(missing), None)
  assert_eq(canonical_result(missing).0, 6)
  assert_eq(canonical_result("moon.mod").0, 0)
  assert_eq(io_error("moon.mod"), None)
  assert_eq(canonical_result(missing).0, 6)
  clear_io_error()
  assert_eq(io_error(missing), None)
}

///|
test "invalid output paths clear pending OS state" {
  let missing = "__moonjsonnet_missing_io_error_regression__"
  assert_eq(canonical_result(missing).0, 6)
  assert_eq(io_error("x\u0000y"), Some("open x\u0000y: invalid argument"))
  assert_eq(io_error(missing), None)
}
