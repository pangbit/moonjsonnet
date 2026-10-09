/* Copyright 2010, 2017 The Go Authors. All rights reserved.
 * The amd64 exponential below adapts Go 1.24.0 src/math/exp_amd64.s.
 * Redistribution terms and inherited notices: licenses/GO-BSD-3-Clause.txt
 * and licenses/GO-MATH-NOTICES.txt. */
#include <moonbit.h>
#include <math.h>
#include <stdint.h>
#include <string.h>

MOONBIT_FFI_EXPORT double mj_fma(double x, double y, double z) {
  return fma(x, y, z);
}

/* Go 1.24 contracts these generic math sites on arm64, but not amd64. */
MOONBIT_FFI_EXPORT double mj_reference_multiply_add(double x, double y, double z) {
#if defined(__aarch64__)
  return fma(x, y, z);
#else
  volatile double product = x * y;
  return product + z;
#endif
}

MOONBIT_FFI_EXPORT int32_t mj_reference_amd64(void) {
#if defined(__x86_64__)
  return 1;
#else
  return 0;
#endif
}

/* Define Go's conversions without C casts of NaN or out-of-range values. */
MOONBIT_FFI_EXPORT int64_t mj_reference_int64(double value) {
#if defined(__x86_64__)
  if (isnan(value) || value >= 0x1p63 || value < -0x1p63) return INT64_MIN;
#else
  if (isnan(value)) return 0;
  if (value >= 0x1p63) return INT64_MAX;
  if (value <= -0x1p63) return INT64_MIN;
#endif
  return (int64_t)value;
}

/* Root callers check Unicode bounds first; keep the FFI defined for all values. */
MOONBIT_FFI_EXPORT int32_t mj_reference_rune(double value) {
#if defined(__x86_64__)
  if (isnan(value) || value >= 0x1p31 || value < -0x1p31) return INT32_MIN;
#else
  if (isnan(value)) return 0;
  if (value >= 0x1p31) return INT32_MAX;
  if (value <= -0x1p31) return INT32_MIN;
#endif
  return (int32_t)value;
}

static double mj_rounded_multiply_add(double x, double y, double z, int fused) {
  if (fused) return fma(x, y, z);
  volatile double product = x * y;
  return product + z;
}

static double mj_power_of_two(int exponent) {
  uint64_t bits = (uint64_t)exponent << 52;
  double result;
  memcpy(&result, &bits, sizeof(result));
  return result;
}

MOONBIT_FFI_EXPORT double mj_reference_exp_amd64(double x) {
  if (isnan(x) || x == INFINITY) return x;
  if (x > 7.09782712893384e+02) return INFINITY;
  if (x < -746.0) return 0.0;
  int fused = 0;
#if defined(__x86_64__)
  /* Go's useFMA requires both AVX (including OS support) and FMA. */
  __builtin_cpu_init();
  fused = __builtin_cpu_supports("avx") && __builtin_cpu_supports("fma");
#endif
  int exponent = (int)nearbyint(x * 1.4426950408889634073599246810018920);
  double r = mj_rounded_multiply_add(-exponent, 0.69314718055966295651160180568695068359375, x, fused);
  r = mj_rounded_multiply_add(-exponent, 0.28235290563031577122588448175013436025525412068e-12, r, fused);
  r *= 0.0625;
  const double coefficients[] = {
    2.4801587301587301587e-5, 1.9841269841269841270e-4,
    1.3888888888888888889e-3, 8.3333333333333333333e-3,
    4.1666666666666666667e-2, 1.6666666666666666667e-1, 0.5, 1.0
  };
  double polynomial = coefficients[0];
  for (int i = 1; i < 8; i++) {
    polynomial = mj_rounded_multiply_add(polynomial, r, coefficients[i], fused);
  }
  r *= polynomial;
  for (int i = 0; i < 3; i++) r *= 2.0 + r;
  double fraction = mj_rounded_multiply_add(r, 2.0 + r, 1.0, fused);
  int biased = exponent + 1023;
  if (biased <= 0) {
    if (biased < -52) return 0.0;
    fraction *= mj_power_of_two(biased + 1022);
    biased = 1;
  } else if (biased >= 2047) {
    return INFINITY;
  }
  return fraction * mj_power_of_two(biased);
}
