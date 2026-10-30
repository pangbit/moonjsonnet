///|
// FIPS 180-4 sections 5.1.1, 5.3.1 and 6.1.2.
fn Vm::sha1(self : Vm, s : String, loc : Location) -> String raise {
  let input = @utf8.encode(s)
  let blocks = input.length() / 64 +
    (if input.length() % 64 < 56 { 1 } else { 2 })
  let total = blocks.to_int64() * 64L
  let state : Array[UInt32] = [
    0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476, 0xc3d2e1f0,
  ]
  let words = Array::make(80, 0U)
  for block in 0..<blocks {
    for word in 0..<16 {
      let mut value = 0U
      for byte in 0..<4 {
        let position = block.to_int64() * 64L + (word * 4 + byte).to_int64()
        value = (value << 8) | digest_byte(input, position, total, false)
      }
      words[word] = value
    }
    for i in 16..<80 {
      words[i] = digest_rotl32(
        words[i - 3] ^ words[i - 8] ^ words[i - 14] ^ words[i - 16],
        1,
      )
    }
    let mut a = state[0]
    let mut b = state[1]
    let mut c = state[2]
    let mut d = state[3]
    let mut e = state[4]
    for i in 0..<80 {
      self.tick(loc)
      let (f, k) = if i < 20 {
        ((b & c) | (b.lnot() & d), 0x5a827999U)
      } else if i < 40 {
        (b ^ c ^ d, 0x6ed9eba1U)
      } else if i < 60 {
        ((b & c) | (b & d) | (c & d), 0x8f1bbcdcU)
      } else {
        (b ^ c ^ d, 0xca62c1d6U)
      }
      let next = digest_rotl32(a, 5) + f + e + k + words[i]
      e = d
      d = c
      c = digest_rotl32(b, 30)
      b = a
      a = next
    }
    for i, word in [a, b, c, d, e] {
      state[i] += word
    }
  }
  digest_hex(state.map(x => x.to_uint64()), 4, false)
}
