///|
test "fmt CLI expands short options before the delimiter" {
  assert_eq(simplify_args(["-ein", "2", "--", "-abc"]), [
    "-e", "-i", "-n", "2", "--", "-abc",
  ])
  assert_eq(simplify_args(["-n", "-12", "42"]), ["-n", "-1", "-2", "42"])
}

///|
test "fmt CLI preserves last options and multi input rules" {
  guard parse_args([
      "--pad-arrays", "--no-pad-arrays", "-n", "0", "--test", "a", "b",
    ])
    is Run(config) else {
    fail("run config")
  }
  assert_eq(config.paths, ["a", "b"])
  assert_true(config.test_only)
  assert_false(config.options.pad_arrays)
  assert_eq(config.options.indent, 0)
  assert_true(parse_args(["-e"]) is UsageFailure("must give code"))
  assert_true(parse_args(["-h", "--unknown"]) is Help)
  try parse_args(["a", "b"]) catch {
    Message(message) =>
      assert_eq(message, "ERROR: only one filename is allowed\n")
    SyntaxMessage(_) => fail("unexpected syntax message")
  } noraise {
    _ => fail("multiple files accepted without test/in-place")
  }
}

///|
test "fmt CLI integer options follow decimal int64 parsing" {
  assert_eq(integer("+2", "--indent"), 2)
  assert_eq(integer("-0", "--indent"), 0)
  assert_eq(integer("9223372036854775807", "--indent"), 2147483647)
  for value in ["", "0x10", "1_0", " 2", "9223372036854775808"] {
    try integer(value, "--indent") catch {
      Message(message) =>
        assert_eq(message, "Invalid integer \"" + value + "\"\n")
      SyntaxMessage(_) => fail("unexpected syntax message")
    } noraise {
      _ => fail("invalid decimal accepted")
    }
  }
  try integer("-2", "--indent") catch {
    Message(message) =>
      assert_eq(message, "ERROR: invalid --indent value: -2\n")
    SyntaxMessage(_) => fail("unexpected syntax message")
  } noraise {
    _ => fail("negative indentation accepted")
  }
}

///|
test "fmt CLI output parents use lexical cleaning" {
  for
    (path, expected) in [
      ("a", "."),
      ("/a", "/"),
      ("a//b/../c/out", "a/c"),
      ("../out", ".."),
      ("a/../../out", ".."),
    ] {
    assert_eq(output_parent(path), expected)
  }
}
