///|
test "stdin rejects invalid limits without consuming input" {
  for limit in [0, -1, 2147483647] {
    let (status, bytes) = @posix.read_stdin(limit)
    assert_eq(status, 2)
    assert_eq(bytes, b"")
  }
}
