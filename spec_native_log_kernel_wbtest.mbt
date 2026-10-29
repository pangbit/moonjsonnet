// 0.6931 < ln(2) < 0.6932 and ln(2^-n) = -n ln(2) give these integer bounds.
// Exercise the real amd64 kernel even on a host whose public log dispatch uses ln.
// This is an implementation-path check, not Linux end-to-end execution.

///|
test "NL1 amd64 log kernel respects independent subnormal and normal intervals" {
  let observations : Array[String] = []
  let mut all_pass = true
  for
    (label, input, lower, upper) in [
      ("2^-1074", 5.0e-324, -745.0, -744.0),
      ("2^-1023", 1.1125369292536007e-308, -710.0, -709.0),
      ("2^-1022", 2.2250738585072014e-308, -709.0, -708.0),
    ] {
    let actual = reference_log_amd64(input)
    let passed = lower < actual && actual < upper
    observations.push(
      label +
      " actual=" +
      actual.to_string() +
      " expected=(" +
      lower.to_string() +
      "," +
      upper.to_string() +
      ") " +
      (if passed { "PASS" } else { "FAIL" }),
    )
    all_pass = all_pass && passed
  }
  if !all_pass {
    fail(observations.join("; "))
  }
}
