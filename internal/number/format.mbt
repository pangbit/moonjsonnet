///|
extern "c" fn format_ffi(value : Double) -> Bytes = "mj_number"

///|
pub fn format(value : Double) -> String {
  @utf8.decode_lossy(format_ffi(value))
}

///|
extern "c" fn diagnostic_fixed_ffi(value : Double) -> Bytes = "mj_diagnostic_fixed"

///|
pub fn diagnostic_fixed(value : Double) -> String {
  if value.is_nan() {
    return "NaN"
  }
  if value.is_inf() {
    return if value < 0 { "-Inf" } else { "+Inf" }
  }
  @utf8.decode_lossy(diagnostic_fixed_ffi(value))
}

///|
extern "c" fn float32_shortest_ffi(value : Double) -> Bytes = "mj_float32_shortest"

///|
pub fn float32_shortest(value : Double) -> String {
  @utf8.decode_lossy(float32_shortest_ffi(value))
}
