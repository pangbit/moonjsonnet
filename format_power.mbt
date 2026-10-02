// Copyright 2009 The Go Authors. All rights reserved.
// Adapted from Go 1.24.0 src/math/pow.go for finite base-10 fractional powers.
// Redistribution terms are in licenses/GO-BSD-3-Clause.txt.

///|
fn format_power(precision : Double) -> Double {
  // Preserve the existing integral-precision path. Larger magnitudes already
  // underflow/overflow and are rejected by the formatting arithmetic checks.
  if precision == precision.floor() || precision.abs() > 324 {
    return @math.pow(10, precision)
  }
  if precision == 0.5 {
    return 10.0.sqrt()
  }
  if precision == -0.5 {
    return 1 / 10.0.sqrt()
  }
  let mut integral = precision.abs().floor().to_int()
  let mut fraction = precision.abs() - integral.to_double()
  if fraction > 0.5 {
    fraction -= 1
    integral += 1
  }
  let mut result = @math.exp(fraction * @math.ln(10))
  let mut exponent = 0
  let mut factor = 0.625
  let mut factor_exponent = 4
  while integral != 0 {
    if (integral & 1) != 0 {
      result *= factor
      exponent += factor_exponent
    }
    factor *= factor
    factor_exponent *= 2
    if factor < 0.5 {
      factor *= 2
      factor_exponent -= 1
    }
    integral = integral >> 1
  }
  if precision < 0 {
    result = 1 / result
    exponent = -exponent
  }
  @math.scalbn(result, exponent)
}
