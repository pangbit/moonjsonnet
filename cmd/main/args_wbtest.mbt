///|
test "trace limits use nonnegative decimal integers without narrowing overflow" {
  for
    (text, value) in [
      ("0", 0),
      ("-0", 0),
      ("+1", 1),
      ("01", 1),
      ("20", 20),
      ("2147483647", 2147483647),
      ("2147483648", 2147483647),
      ("9223372036854775807", 2147483647),
    ] {
    assert_eq(trace_limit(text), value)
  }
  for
    text in [
      "", "+", "-", "-1", "1_0", "0x10", " 1", "1 ", "1.5", "1e2", "１２", "9223372036854775808",
    ] {
    try trace_limit(text) catch {
      _ => ()
    } noraise {
      _ => fail("expected invalid trace limit: " + text)
    }
  }
}

///|
test "stack limits require positive decimal integers" {
  for
    (text, value) in [
      ("1", 1),
      ("+1", 1),
      ("001", 1),
      ("2147483648", 2147483647),
      ("9223372036854775807", 2147483647),
    ] {
    assert_eq(decimal_limit(text, "--max-stack", 1), value)
  }
  for
    text in [
      "0", "-0", "-1", "", "+", "1_0", "0x10", " 1", "1 ", "1.5", "1e2", "１２",
      "9223372036854775808",
    ] {
    try decimal_limit(text, "--max-stack", 1) catch {
      _ => ()
    } noraise {
      _ => fail("expected invalid stack limit")
    }
  }
}

///|
test "short option expansion preserves order and stops at delimiter" {
  assert_eq(simplify_args(["cli", "-eV", "x=42", "--", "-42", "-hello"]), [
    "cli", "-e", "-V", "x=42", "--", "-42", "-hello",
  ])
  assert_eq(
    simplify_args(["cli", "--exec", "-", "-42", "--ext-code", "x=-42"]),
    ["cli", "--exec", "-", "-4", "-2", "--ext-code", "x=-42"],
  )
  assert_eq(simplify_args(["cli", "-é"]), ["cli", "-Ã", "-©"])
}
