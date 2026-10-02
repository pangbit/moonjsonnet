///|
test "fused multiply add rounds once" {
  assert_eq(
    @number.fused_multiply_add(1.0000000074505806, 0.9999999925494194, -1),
    -5.551115123125783e-17,
  )
}
