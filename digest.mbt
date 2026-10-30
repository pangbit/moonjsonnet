///|
// Virtual Merkle-Damgard padding. SHA-512's high length word is zero because
// the input length is bounded by MoonBit's Int-sized byte buffer.
fn digest_byte(
  input : Bytes,
  position : Int64,
  total : Int64,
  little : Bool,
) -> UInt32 {
  if position < input.length().to_int64() {
    input[position.to_int()].to_uint()
  } else if position == input.length().to_int64() {
    128U
  } else if position >= total - 8L {
    let index = (position - (total - 8L)).to_int()
    let shift = (if little { index } else { 7 - index }) * 8
    (((input.length().to_uint64() * 8UL) >> shift) & 255UL).to_uint()
  } else {
    0U
  }
}

///|
fn digest_rotl32(x : UInt32, n : Int32) -> UInt32 {
  (x << n) | (x >> (32 - n))
}

///|
fn digest_rotl64(x : UInt64, n : Int32) -> UInt64 {
  if n == 0 {
    x
  } else {
    (x << n) | (x >> (64 - n))
  }
}

///|
fn digest_hex(words : Array[UInt64], width : Int32, little : Bool) -> String {
  let alphabet = "0123456789abcdef".to_array()
  let out = StringBuilder()
  for word in words {
    for i in 0..<width {
      let shift = (if little { i } else { width - 1 - i }) * 8
      let byte = ((word >> shift) & 255UL).to_int()
      out.write_char(alphabet[byte / 16])
      out.write_char(alphabet[byte % 16])
    }
  }
  out.to_string()
}
