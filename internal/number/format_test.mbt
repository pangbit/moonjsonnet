///|
test "fixed diagnostic decimals preserve signs rounding and special values" {
  assert_eq(@number.diagnostic_fixed(-0.0), "-0.000000")
  assert_eq(@number.diagnostic_fixed(-1.0000005), "-1.000001")
  assert_eq(@number.diagnostic_fixed(1.0 / 0.0), "+Inf")
  assert_eq(@number.diagnostic_fixed(-1.0 / 0.0), "-Inf")
  assert_eq(@number.diagnostic_fixed(0.0 / 0.0), "NaN")
}

///|
test "fixed diagnostic decimals fit both finite binary64 extremes" {
  let maximum = 1.7976931348623157e308
  let positive = @number.diagnostic_fixed(maximum)
  let negative = @number.diagnostic_fixed(-maximum)
  assert_eq(positive.length(), 316)
  assert_eq(negative.length(), 317)
  assert_true(positive.has_prefix("17976931348623157"))
  assert_true(positive.has_suffix(".000000"))
  assert_eq(negative, "-" + positive)
}
