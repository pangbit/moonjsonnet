///|
extern "c" fn fma_ffi(x : Double, y : Double, z : Double) -> Double = "mj_fma"

///|
pub fn fused_multiply_add(x : Double, y : Double, z : Double) -> Double {
  fma_ffi(x, y, z)
}

///|
pub extern "c" fn reference_multiply_add(
  x : Double,
  y : Double,
  z : Double,
) -> Double = "mj_reference_multiply_add"

///|
pub extern "c" fn reference_int64(value : Double) -> Int64 = "mj_reference_int64"

///|
pub extern "c" fn reference_rune(value : Double) -> Int32 = "mj_reference_rune"

///|
pub extern "c" fn reference_amd64() -> Bool = "mj_reference_amd64"

///|
pub extern "c" fn reference_exp_amd64(value : Double) -> Double = "mj_reference_exp_amd64"
