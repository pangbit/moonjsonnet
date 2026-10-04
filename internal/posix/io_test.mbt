///|
test "stdin rejects invalid limits without consuming input" {
  for limit in [0, -1, 2147483647] {
    let (status, bytes) = @posix.read_stdin(limit)
    assert_eq(status, 2)
    assert_eq(bytes, b"")
  }
}

///|
test "output helpers reject invalid paths and descriptors" {
  assert_true(!@posix.mkdir_all(""))
  assert_true(!@posix.mkdir_all("x\u0000y"))
  assert_eq(@posix.open_output("x\u0000y"), -1)
  assert_eq(@posix.output_same("x\u0000y", "data"), 2)
  assert_true(!@posix.write_output(-1, "data"))
  assert_true(!@posix.close_output(-1))
}
