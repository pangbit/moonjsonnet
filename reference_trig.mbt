// Copyright 2011, 2018 The Go Authors. All rights reserved.
// Adapted from Go 1.24.0 src/math/{sin,tan,trig_reduce}.go.
// Redistribution terms and inherited notices: licenses/GO-BSD-3-Clause.txt,
// licenses/GO-MATH-NOTICES.txt.

///|
let reference_four_over_pi : FixedArray[UInt64] = [
  0x0000000000000001UL, 0x45f306dc9c882a53UL, 0xf84eafa3ea69bb81UL, 0xb6c52b3278872083UL,
  0xfca2c757bd778ac3UL, 0x6e48dc74849ba5c0UL, 0x0c925dd413a32439UL, 0xfc3bd63962534e7dUL,
  0xd1046bea5d768909UL, 0xd338e04d68befc82UL, 0x7323ac7306a673e9UL, 0x3908bf177bf25076UL,
  0x3ff12fffbc0b301fUL, 0xde5e2316b414da3eUL, 0xda6cfd9e4f96136eUL, 0x9e8c7ecd3cbfd45aUL,
  0xea4f758fd7cbe2f6UL, 0x7a0e73ef14a525d4UL, 0xd7f6bf623f1aba10UL, 0xac06608df8f6d757UL,
]

///|
// Upper word of an unsigned 64 x 64 bit product, using 32 bit limbs.
fn reference_mul_high(a : UInt64, b : UInt64) -> UInt64 {
  let a0 = a.land(0xffffffffUL)
  let a1 = a >> 32
  let b0 = b.land(0xffffffffUL)
  let b1 = b >> 32
  let cross = a1 * b0 + ((a0 * b0) >> 32)
  let middle = cross.land(0xffffffffUL) + a0 * b1
  a1 * b1 + (cross >> 32) + (middle >> 32)
}

///|
fn reference_trig_reduce(x : Double) -> (Int32, Double) {
  if x < 536870912.0 {
    let mut j = (x * 1.2732395447351628).to_int()
    if (j & 1) == 1 {
      j += 1
    }
    let y = j.to_double()
    let z = @number.reference_multiply_add(-y, 7.85398125648498535156e-1, x)
    let z = @number.reference_multiply_add(-y, 3.77489470793079817668e-8, z)
    let z = @number.reference_multiply_add(-y, 2.69515142907905952645e-15, z)
    return (j & 7, z)
  }
  let bits = x.reinterpret_as_uint64()
  let exp = (bits >> 52).land(2047UL).to_int() - 1023 - 52
  let ix = bits.land(0x000fffffffffffffUL).lor(0x0010000000000000UL)
  let digit = (exp + 61) / 64
  let shift = (exp + 61) % 64
  let words : Array[UInt64] = []
  for i in 0..<3 {
    let low = if shift == 0 {
      0UL
    } else {
      reference_four_over_pi[digit + i + 1] >> (64 - shift)
    }
    words.push((reference_four_over_pi[digit + i] << shift).lor(low))
  }
  let z2hi = reference_mul_high(words[2], ix)
  let z1hi = reference_mul_high(words[1], ix)
  let z1lo = words[1] * ix
  let lo = z1lo + z2hi
  let carry = if lo < z1lo { 1UL } else { 0UL }
  let mut hi = words[0] * ix + z1hi + carry
  let mut j = (hi >> 61).to_int()
  hi = (hi << 3).lor(lo >> 61)
  let shift = hi.clz() + 1
  let exponent = (1023 - shift).to_uint64()
  // Go's shifts of a 64-bit word by >=64 produce zero; MoonBit masks shifts.
  let high = if shift >= 64 { 0UL } else { hi << shift }
  let low = if shift > 64 { 0UL } else { lo >> (64 - shift) }
  hi = (high.lor(low) >> 12).lor(exponent << 52)
  let mut z = hi.reinterpret_as_double()
  if (j & 1) == 1 {
    j = (j + 1) & 7
    z -= 1
  }
  (j, z * 0.7853981633974483)
}

///|
fn reference_sin_polynomial(z : Double) -> Double {
  let zz = z * z
  let p = reference_polynomial(zz, [
    1.58962301576546568060e-10, -2.50507477628578072866e-8, 2.75573136213857245213e-6,
    -1.98412698295895385996e-4, 8.33333333332211858878e-3, -1.66666666666666307295e-1,
  ])
  @number.reference_multiply_add(z * zz, p, z)
}

///|
fn reference_cos_polynomial(z : Double) -> Double {
  let zz = z * z
  let p = reference_polynomial(zz, [
    -1.13585365213876817300e-11, 2.08757008419747316778e-9, -2.75573141792967388112e-7,
    2.48015872888517045348e-5, -1.38888888888730564116e-3, 4.16666666666665929218e-2,
  ])
  @number.reference_multiply_add(
    zz * zz,
    p,
    @number.reference_multiply_add(-0.5, zz, 1),
  )
}

///|
fn reference_trig(name : String, x : Double) -> Double {
  if x.is_nan() || x.is_inf() {
    return 0.0 / 0.0
  }
  if x == 0 {
    return if name == "cos" { 1 } else { x }
  }
  let (octant, z) = reference_trig_reduce(x.abs())
  if name == "tan" {
    let zz = z * z
    let mut y = if zz > 1.0e-14 {
      let p = reference_polynomial(zz, [
        -1.30936939181383777646e4, 1.15351664838587416140e6, -1.79565251976484877988e7,
      ])
      let first = @number.reference_multiply_add(z, z, 1.36812963470692954678e4)
      let q = reference_polynomial(zz, [
        first, -1.32089234440210967447e6, 2.50083801823357915839e7, -5.38695755929454629881e7,
      ])
      @number.reference_multiply_add(z, zz * p / q, z)
    } else {
      z
    }
    if (octant & 2) == 2 {
      y = -1 / y
    }
    return if x < 0 { -y } else { y }
  }
  let mut negative = name == "sin" && x < 0
  let mut j = octant
  if j > 3 {
    j -= 4
    negative = !negative
  }
  let y = if name == "cos" {
    if j > 1 {
      negative = !negative
    }
    if j == 1 || j == 2 {
      reference_sin_polynomial(z)
    } else {
      reference_cos_polynomial(z)
    }
  } else if j == 1 || j == 2 {
    reference_cos_polynomial(z)
  } else {
    reference_sin_polynomial(z)
  }
  if negative {
    -y
  } else {
    y
  }
}
