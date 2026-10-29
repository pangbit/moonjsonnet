// Copyright 2010 The Go Authors. All rights reserved.
// Adapted from Go 1.24.0 src/math/log_amd64.s, including its subnormal path.
// Redistribution terms: licenses/GO-BSD-3-Clause.txt.

///|
fn reference_log(x : Double) -> Double {
  if !@number.reference_amd64() {
    return @math.ln(x)
  }
  reference_log_amd64(x)
}

///|
fn reference_log_amd64(x : Double) -> Double {
  if x == 0 {
    return -1.0 / 0.0
  }
  if x < 0 {
    return 0.0 / 0.0
  }
  if x.is_nan() || x.is_inf() {
    return x
  }
  let small = x < 2.2250738585072014e-308
  let normalized = if small { x * 18014398509481984.0 } else { x }
  let bits = normalized.reinterpret_as_int64()
  let mut fraction = bits
    .land(0x000fffffffffffffL)
    .lor(0x3fe0000000000000L)
    .reinterpret_as_double()
  let mut exponent = (bits >> 52).to_int() - 1022 - (if small { 54 } else { 0 })
  if fraction < 7.07106781186547524401e-01 {
    exponent -= 1
    fraction *= 2
  }
  let f = fraction - 1
  let s = f / (2 + f)
  let s2 = s * s
  let s4 = s2 * s2
  let t1 = s2 *
    reference_polynomial(s4, [
      1.479819860511658591e-01, 1.818357216161805012e-01, 2.857142874366239149e-01,
      6.666666666666735130e-01,
    ])
  let t2 = s4 *
    reference_polynomial(s4, [
      1.531383769920937332e-01, 2.222219843214978396e-01, 3.999999999940941908e-01,
    ])
  let hfsq = 0.5 * f * f
  let k = exponent.to_double()
  k * 6.93147180369123816490e-01 -
  (hfsq - (s * (hfsq + (t1 + t2)) + k * 1.90821492927058770002e-10) - f)
}
