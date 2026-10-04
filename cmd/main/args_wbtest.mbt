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
