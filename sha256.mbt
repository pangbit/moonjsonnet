///|
fn sha256_rotr(x : UInt, bits : Int) -> UInt {
  (x >> bits) | (x << (32 - bits))
}

///|
// FIPS 180-4 sections 4.2.2, 5.1.1, 5.3.3 and 6.2.2.
// Process padding virtually; only the UTF-8 input and one schedule are stored.
fn Vm::sha256(self : Vm, s : String, loc : Location) -> String raise {
  let input = @utf8.encode(s)
  let size = input.length()
  let blocks = size / 64 + (if size % 64 < 56 { 1 } else { 2 })
  let bit_length = size.to_uint64() * 8UL
  let state : Array[UInt] = [
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab,
    0x5be0cd19,
  ]
  let constants : Array[UInt] = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4,
    0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe,
    0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f,
    0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc,
    0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
    0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116,
    0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7,
    0xc67178f2,
  ]
  let words = Array::make(64, 0U)
  for block in 0..<blocks {
    for word in 0..<16 {
      let mut value = 0U
      for byte in 0..<4 {
        let offset = word * 4 + byte
        let position = block.to_int64() * 64L + offset.to_int64()
        let part = if position < size.to_int64() {
          input[position.to_int()].to_uint()
        } else if position == size.to_int64() {
          128U
        } else if block == blocks - 1 && offset >= 56 {
          ((bit_length >> ((63 - offset) * 8)) & 255UL).to_uint()
        } else {
          0U
        }
        value = (value << 8) | part
      }
      words[word] = value
    }
    for i in 16..<64 {
      let x = words[i - 15]
      let y = words[i - 2]
      let a = sha256_rotr(x, 7) ^ sha256_rotr(x, 18) ^ (x >> 3)
      let b = sha256_rotr(y, 17) ^ sha256_rotr(y, 19) ^ (y >> 10)
      words[i] = words[i - 16] + a + words[i - 7] + b
    }
    let mut a = state[0]
    let mut b = state[1]
    let mut c = state[2]
    let mut d = state[3]
    let mut e = state[4]
    let mut f = state[5]
    let mut g = state[6]
    let mut h = state[7]
    for i in 0..<64 {
      self.tick(loc)
      let upper = sha256_rotr(e, 6) ^ sha256_rotr(e, 11) ^ sha256_rotr(e, 25)
      let choose = (e & f) ^ (e.lnot() & g)
      let t1 = h + upper + choose + constants[i] + words[i]
      let lower = sha256_rotr(a, 2) ^ sha256_rotr(a, 13) ^ sha256_rotr(a, 22)
      let majority = (a & b) ^ (a & c) ^ (b & c)
      h = g
      g = f
      f = e
      e = d + t1
      d = c
      c = b
      b = a
      a = t1 + lower + majority
    }
    for i, value in [a, b, c, d, e, f, g, h] {
      state[i] += value
    }
  }
  let result = StringBuilder()
  for word in state {
    let hex = word.to_string(radix=16)
    result.write_string("0".repeat(8 - hex.length()))
    result.write_string(hex)
  }
  result.to_string()
}
