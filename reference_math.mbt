// Copyright 2009, 2017 The Go Authors. All rights reserved.
// Adapted from Go 1.24.0 src/math/{atan,atan2,asin,exp,pow}.go and exp_arm64.s.
// Redistribution terms and inherited notices: licenses/GO-BSD-3-Clause.txt,
// licenses/GO-MATH-NOTICES.txt.

///|
fn reference_atan_series(x : Double) -> Double {
  let z = x * x
  let p = reference_polynomial(z, [
    -8.750608600031904122785e-01, -1.615753718733365076637e+01, -7.500855792314704667340e+01,
    -1.228866684490136173410e+02, -6.485021904942025371773e+01,
  ])
  let first = @number.fused_multiply_add(x, x, 2.485846490142306297962e+01)
  let q = reference_polynomial(z, [
    first, 1.650270098316988542046e+02, 4.328810604912902668951e+02, 4.853903996359136964868e+02,
    1.945506571482613964425e+02,
  ])
  @number.fused_multiply_add(x, z * p / q, x)
}

///|
// Horner evaluation with the explicit FMA sites used by the pinned ARM64 Go
// binary. Do not replace this with multiply/add or change its evaluation order.
fn reference_polynomial(
  x : Double,
  coefficients : FixedArray[Double],
) -> Double {
  let mut result = coefficients[0]
  for i in 1..<coefficients.length() {
    result = @number.fused_multiply_add(result, x, coefficients[i])
  }
  result
}

///|
fn reference_atan_positive(x : Double) -> Double {
  if x <= 0.66 {
    reference_atan_series(x)
  } else if x > 2.41421356237309504880 {
    1.5707963267948966 -
    reference_atan_series(1 / x) +
    6.123233995736765886130e-17
  } else {
    0.7853981633974483 +
    reference_atan_series((x - 1) / (x + 1)) +
    3.061616997868382943065e-17
  }
}

///|
fn reference_atan(x : Double) -> Double {
  if x == 0 {
    x
  } else if x > 0 {
    reference_atan_positive(x)
  } else {
    -reference_atan_positive(-x)
  }
}

///|
fn reference_copy_sign(x : Double, sign : Double) -> Double {
  x
  .reinterpret_as_int64()
  .land(0x7fffffffffffffffL)
  .lor(sign.reinterpret_as_int64().land(0x8000000000000000L))
  .reinterpret_as_double()
}

///|
fn reference_atan2(y : Double, x : Double) -> Double {
  if y.is_nan() || x.is_nan() {
    return 0.0 / 0.0
  }
  if y == 0 {
    return reference_copy_sign(
      if x >= 0 && x.reinterpret_as_int64() >= 0L {
        0
      } else {
        3.141592653589793
      },
      y,
    )
  }
  if x == 0 {
    return reference_copy_sign(1.5707963267948966, y)
  }
  if x.is_inf() {
    let angle = if x > 0 {
      if y.is_inf() {
        0.7853981633974483
      } else {
        0
      }
    } else if y.is_inf() {
      2.356194490192345
    } else {
      3.141592653589793
    }
    return reference_copy_sign(angle, y)
  }
  if y.is_inf() {
    return reference_copy_sign(1.5707963267948966, y)
  }
  let q = reference_atan(y / x)
  if x < 0 {
    if q <= 0 {
      q + 3.141592653589793
    } else {
      q - 3.141592653589793
    }
  } else {
    q
  }
}

///|
fn reference_asin(x : Double) -> Double {
  if x == 0 {
    return x
  }
  let magnitude = x.abs()
  if magnitude > 1 {
    return 0.0 / 0.0
  }
  let root = @number.fused_multiply_add(-magnitude, magnitude, 1).sqrt()
  let angle = if magnitude > 0.7 {
    1.5707963267948966 - reference_atan_positive(root / magnitude)
  } else {
    reference_atan_positive(magnitude / root)
  }
  if x < 0 {
    -angle
  } else {
    angle
  }
}

///|
fn reference_exp(x : Double) -> Double {
  if x.is_nan() {
    return x
  }
  if x > 7.09782712893383973096e+02 {
    return 1.0 / 0.0
  }
  if x < -7.45133219101941108420e+02 {
    return 0
  }
  if x.abs() < 3.725290298461914e-9 {
    return 1 + x
  }
  let k = @number.fused_multiply_add(
    1.44269504088896338700e+00,
    x,
    if x < 0 {
      -0.5
    } else {
      0.5
    },
  ).to_int()
  let hi = @number.fused_multiply_add(
    -k.to_double(),
    6.93147180369123816490e-01,
    x,
  )
  let lo = k.to_double() * 1.90821492927058770002e-10
  let r = hi - lo
  let t = r * r
  let p = reference_polynomial(t, [
    4.13813679705723846039e-08, -1.65339022054652515390e-06, 6.61375632143793436117e-05,
    -2.77777777770155933842e-03, 1.66666666666666657415e-01,
  ])
  let c = @number.fused_multiply_add(-t, p, r)
  let y = 1.0 - (lo - r * c / (2 - c) - hi)
  // Match exp_arm64.s's inline exponent adjustment, including its lowest
  // subnormal boundary; the generic Go Ldexp path rounds differently there.
  let bits = y.reinterpret_as_int64()
  let mut exponent = (bits >> 52).to_int() + k
  let mut multiplier = 1.0
  if exponent < 1 {
    exponent += 52
    multiplier = 2.220446049250313e-16
  }
  bits
  .land(0x000fffffffffffffL)
  .lor(exponent.to_int64() << 52)
  .reinterpret_as_double() *
  multiplier
}

///|
fn reference_pow(x : Double, y : Double) -> Double {
  if y == 0 || x == 1 {
    return 1
  }
  if y == 1 {
    return x
  }
  if x.is_nan() || y.is_nan() {
    return 0.0 / 0.0
  }
  if x == 0 {
    let odd = y.abs() < 9007199254740992.0 && y == y.trunc() && y % 2 != 0
    let result = if y < 0 { 1.0 / 0.0 } else { 0.0 }
    return if odd { reference_copy_sign(result, x) } else { result }
  }
  if y.is_inf() {
    return if x == -1 {
      1
    } else if (x.abs() < 1) == (y > 0) {
      0
    } else {
      1.0 / 0.0
    }
  }
  if x.is_inf() {
    return if x < 0 { reference_pow(1 / x, -y) } else if y < 0 { 0 } else { x }
  }
  if y == 0.5 {
    return x.sqrt()
  }
  if y == -0.5 {
    return 1 / x.sqrt()
  }
  let mut yi = y.abs().trunc()
  let mut yf = y.abs() - yi
  if yf != 0 && x < 0 {
    return 0.0 / 0.0
  }
  if yi >= 9223372036854775808.0 {
    return if x == -1 {
      1
    } else if (x.abs() < 1) == (y > 0) {
      0
    } else {
      1.0 / 0.0
    }
  }
  let mut a = 1.0
  let mut exponent = 0
  if yf != 0 {
    if yf > 0.5 {
      yf -= 1
      yi += 1
    }
    a = reference_exp(yf * @math.ln(x))
  }
  let (fraction, e) = binary_fraction(x)
  let mut factor = fraction
  let mut factor_exponent = e
  for i = yi.to_int64(); i != 0L; i = i >> 1 {
    if factor_exponent < -4096 || factor_exponent > 4096 {
      exponent += factor_exponent
      break
    }
    if i.land(1L) != 0L {
      a *= factor
      exponent += factor_exponent
    }
    factor *= factor
    factor_exponent *= 2
    if factor < 0.5 {
      factor += factor
      factor_exponent -= 1
    }
  }
  if y < 0 {
    a = 1 / a
    exponent = -exponent
  }
  @math.scalbn(a, exponent)
}
