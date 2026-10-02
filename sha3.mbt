///|
// FIPS 202 SHA3-512: Keccak-f[1600], rate 576 bits, domain suffix 0x06.
// The Jsonnet name sha3 denotes SHA3-512, not legacy Keccak or SHA3-256.
fn Vm::sha3(self : Vm, s : String, loc : Location) -> String raise {
  let input = @utf8.encode(s)
  let state = Array::make(25, 0UL)
  let scratch = Array::make(25, 0UL)
  let columns = Array::make(5, 0UL)
  let rotations = [
    0, 1, 62, 28, 27, 36, 44, 6, 55, 20, 3, 10, 43, 25, 39, 41, 45, 15, 21, 8, 18,
    2, 61, 56, 14,
  ]
  let constants : Array[UInt64] = [
    0x0000000000000001, 0x0000000000008082, 0x800000000000808a, 0x8000000080008000,
    0x000000000000808b, 0x0000000080000001, 0x8000000080008081, 0x8000000000008009,
    0x000000000000008a, 0x0000000000000088, 0x0000000080008009, 0x000000008000000a,
    0x000000008000808b, 0x800000000000008b, 0x8000000000008089, 0x8000000000008003,
    0x8000000000008002, 0x8000000000000080, 0x000000000000800a, 0x800000008000000a,
    0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008,
  ]
  let blocks = input.length() / 72 + 1
  for block in 0..<blocks {
    for byte in 0..<72 {
      let position = block.to_int64() * 72L + byte.to_int64()
      let mut value = if position < input.length().to_int64() {
        input[position.to_int()].to_uint64()
      } else if position == input.length().to_int64() {
        6UL
      } else {
        0UL
      }
      if block == blocks - 1 && byte == 71 {
        value = value | 128UL
      }
      state[byte / 8] = state[byte / 8] ^ (value << (byte % 8 * 8))
    }
    for rc in constants {
      self.tick(loc)
      for x in 0..<5 {
        columns[x] = state[x] ^
          state[x + 5] ^
          state[x + 10] ^
          state[x + 15] ^
          state[x + 20]
      }
      for x in 0..<5 {
        let delta = columns[(x + 4) % 5] ^
          digest_rotl64(columns[(x + 1) % 5], 1)
        for y in 0..<5 {
          state[x + 5 * y] = state[x + 5 * y] ^ delta
        }
      }
      for x in 0..<5 {
        for y in 0..<5 {
          scratch[y + 5 * ((2 * x + 3 * y) % 5)] = digest_rotl64(
            state[x + 5 * y],
            rotations[x + 5 * y],
          )
        }
      }
      for x in 0..<5 {
        for y in 0..<5 {
          state[x + 5 * y] = scratch[x + 5 * y] ^
            (scratch[(x + 1) % 5 + 5 * y].lnot() & scratch[(x + 2) % 5 + 5 * y])
        }
      }
      state[0] = state[0] ^ rc
    }
  }
  digest_hex(state[:8].to_owned(), 8, true)
}
