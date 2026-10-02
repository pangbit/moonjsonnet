///|
extern "c" fn fma_ffi(x : Double, y : Double, z : Double) -> Double = "mj_fma"

///|
pub fn fused_multiply_add(x : Double, y : Double, z : Double) -> Double {
  fma_ffi(x, y, z)
}
