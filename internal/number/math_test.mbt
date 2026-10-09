///|
test "fused multiply add rounds once" {
  assert_eq(
    @number.fused_multiply_add(1.0000000074505806, 0.9999999925494194, -1),
    -5.551115123125783e-17,
  )
}

///|
test "native conversions define NaN infinities and the rounded signed bound" {
  let nan = 0.0 / 0.0
  let inf = 1.0 / 0.0
  assert_eq(@number.reference_int64(3.9), 3L)
  assert_eq(@number.reference_int64(-3.9), -3L)
  assert_eq(
    @number.reference_int64(-9223372036854775808.0),
    -9223372036854775808L,
  )
  assert_eq(@number.reference_int64(-inf), -9223372036854775808L)
  if @number.reference_amd64() {
    assert_eq(@number.reference_int64(nan), -9223372036854775808L)
    assert_eq(@number.reference_int64(inf), -9223372036854775808L)
    assert_eq(
      @number.reference_int64(9223372036854775808.0),
      -9223372036854775808L,
    )
    assert_eq(@number.reference_rune(nan), -2147483648)
    assert_eq(
      @number.reference_multiply_add(1.0000000074505806, 0.9999999925494194, -1),
      0.0,
    )
  } else {
    assert_eq(@number.reference_int64(nan), 0L)
    assert_eq(@number.reference_int64(inf), 9223372036854775807L)
    assert_eq(
      @number.reference_int64(9223372036854775808.0),
      9223372036854775807L,
    )
    assert_eq(@number.reference_rune(nan), 0)
    assert_eq(
      @number.reference_multiply_add(1.0000000074505806, 0.9999999925494194, -1),
      -5.551115123125783e-17,
    )
  }
}
