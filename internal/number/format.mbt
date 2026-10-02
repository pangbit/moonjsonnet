///|
extern "c" fn format_ffi(value : Double) -> Bytes = "mj_number"

///|
pub fn format(value : Double) -> String {
  @utf8.decode_lossy(format_ffi(value))
}
