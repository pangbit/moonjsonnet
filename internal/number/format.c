#define _XOPEN_SOURCE 700
#define _DARWIN_C_SOURCE
#include <moonbit.h>
#include <locale.h>
#include <math.h>
#include <stdio.h>
#include <string.h>

/* Preserve one rounding step at the FMA sites in the pinned Go arm64 math. */
MOONBIT_FFI_EXPORT double mj_fma(double x, double y, double z) {
  return fma(x, y, z);
}

/* Match the pinned reference's numeric text contract without changing the
 * process locale: fixed integers, otherwise 17 significant decimal digits. */
MOONBIT_FFI_EXPORT moonbit_bytes_t mj_number(double value) {
  locale_t locale = newlocale(LC_NUMERIC_MASK, "C", (locale_t)0);
  if (!locale) return moonbit_make_bytes(0, 0);
  locale_t previous = uselocale(locale);
  if (!previous) { freelocale(locale); return moonbit_make_bytes(0, 0); }
  char buffer[400];
  int n = snprintf(buffer, sizeof(buffer), value == floor(value) ? "%.0f" : "%.17g", value);
  uselocale(previous);
  freelocale(locale);
  if (n <= 0 || n >= (int)sizeof(buffer)) return moonbit_make_bytes(0, 0);
  moonbit_bytes_t result = moonbit_make_bytes(n, 0);
  memcpy(result, buffer, (size_t)n);
  return result;
}
