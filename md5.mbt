///|
// RFC 1321 section 3. Virtual padding keeps memory proportional to the input.
fn Vm::md5(self : Vm, s : String, loc : Location) -> String raise {
  let input = @utf8.encode(s)
  let blocks = input.length() / 64 +
    (if input.length() % 64 < 56 { 1 } else { 2 })
  let total = blocks.to_int64() * 64L
  let state : Array[UInt32] = [0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476]
  let constants : Array[UInt32] = [
    0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee, 0xf57c0faf, 0x4787c62a, 0xa8304613,
    0xfd469501, 0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be, 0x6b901122, 0xfd987193,
    0xa679438e, 0x49b40821, 0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa, 0xd62f105d,
    0x02441453, 0xd8a1e681, 0xe7d3fbc8, 0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
    0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a, 0xfffa3942, 0x8771f681, 0x6d9d6122,
    0xfde5380c, 0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70, 0x289b7ec6, 0xeaa127fa,
    0xd4ef3085, 0x04881d05, 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665, 0xf4292244,
    0x432aff97, 0xab9423a7, 0xfc93a039, 0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
    0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1, 0xf7537e82, 0xbd3af235, 0x2ad7d2bb,
    0xeb86d391,
  ]
  let shifts = [7, 12, 17, 22, 5, 9, 14, 20, 4, 11, 16, 23, 6, 10, 15, 21]
  let words = Array::make(16, 0U)
  for block in 0..<blocks {
    for word in 0..<16 {
      let mut value = 0U
      for byte in 0..<4 {
        let position = block.to_int64() * 64L + (word * 4 + byte).to_int64()
        value = value |
          (digest_byte(input, position, total, true) << (byte * 8))
      }
      words[word] = value
    }
    let mut a = state[0]
    let mut b = state[1]
    let mut c = state[2]
    let mut d = state[3]
    for i in 0..<64 {
      self.tick(loc)
      let (f, index) = if i < 16 {
        ((b & c) | (b.lnot() & d), i)
      } else if i < 32 {
        ((b & d) | (c & d.lnot()), (5 * i + 1) % 16)
      } else if i < 48 {
        (b ^ c ^ d, (3 * i + 5) % 16)
      } else {
        (c ^ (b | d.lnot()), 7 * i % 16)
      }
      let next = b +
        digest_rotl32(
          a + f + constants[i] + words[index],
          shifts[i / 16 * 4 + i % 4],
        )
      a = d
      d = c
      c = b
      b = next
    }
    state[0] += a
    state[1] += b
    state[2] += c
    state[3] += d
  }
  digest_hex(state.map(x => x.to_uint64()), 4, true)
}
