///|
fn Vm::encoding_builtin(
  self : Vm,
  name : String,
  value : Value,
  loc : Location,
) -> Value raise {
  match name {
    "base64" => {
      let bytes = match value {
        Str(s) => {
          for c in s.iter() {
            self.tick(loc)
            if c.to_int() > 255 {
              raise problem(
                Runtime,
                loc,
                "base64 string code point exceeds 255",
              )
            }
          }
          // Go validates Latin-1 code points but encodes their UTF-8 bytes.
          @utf8.encode(s)
        }
        ArrayValue(_) => self.byte_array(value, true, loc)
        _ =>
          raise problem(Runtime, loc, "base64 expects a string or byte array")
      }
      Str(@base64.encode(bytes))
    }
    "encodeUTF8" => self.bytes_value(@utf8.encode(text_value(value, loc)), loc)
    "decodeUTF8" => Str(decode_go_utf8(self.byte_array(value, false, loc)))
    _ => {
      guard value is Str(s) else {
        raise problem(Runtime, loc, "base64 decoder expects a string")
      }
      let bytes = self.decode_base64(s, loc)
      if name == "base64DecodeBytes" {
        self.bytes_value(bytes, loc)
      } else {
        Str(decode_go_utf8(bytes))
      }
    }
  }
}

///|
fn Vm::byte_array(
  self : Vm,
  value : Value,
  base64 : Bool,
  loc : Location,
) -> Bytes raise {
  let items = array_value(value, loc)
  Bytes::makei(items.length(), fn(i) raise {
    let value = self.force(items[i], loc)
    if base64 && !(value is Num(_)) {
      raise problem(Runtime, loc, "base64 expects numeric bytes")
    }
    let n = integer(value, loc)
    if n < 0 || n > 255 {
      raise problem(Runtime, loc, "byte must be in range 0..255")
    }
    n.to_byte()
  })
}

///|
fn Vm::bytes_value(self : Vm, bytes : Bytes, loc : Location) -> Value raise {
  let items = []
  for b in bytes.iter() {
    self.tick(loc)
    items.push(self.store(Ready(Num(b.to_int().to_double()))))
  }
  ArrayValue(items)
}

///|
fn base64_digit(c : Byte) -> Int {
  let n = c.to_int()
  if n >= 65 && n <= 90 {
    n - 65
  } else if n >= 97 && n <= 122 {
    n - 97 + 26
  } else if n >= 48 && n <= 57 {
    n - 48 + 52
  } else if n == 43 {
    62
  } else if n == 47 {
    63
  } else {
    -1
  }
}

///|
fn Vm::decode_base64(self : Vm, s : String, loc : Location) -> Bytes raise {
  let raw = @utf8.encode(s)
  if raw.length() % 4 != 0 {
    raise problem(Runtime, loc, "base64 input length must be divisible by four")
  }
  // Go ignores only CR and LF, after checking the original UTF-8 byte length.
  let clean = raw.iter().filter(b => b != 13 && b != 10).collect()
  if clean.length() % 4 != 0 {
    raise problem(Runtime, loc, "incomplete base64 quartet")
  }
  let bytes : Array[Byte] = []
  for i = 0; i < clean.length(); i = i + 4 {
    self.tick(loc)
    let a = base64_digit(clean[i])
    let b = base64_digit(clean[i + 1])
    let c = base64_digit(clean[i + 2])
    let d = base64_digit(clean[i + 3])
    if a < 0 || b < 0 {
      raise problem(Runtime, loc, "invalid base64 character")
    }
    bytes.push(((a << 2) | (b >> 4)).to_byte())
    if clean[i + 2] == 61 {
      if clean[i + 3] != 61 || i + 4 != clean.length() {
        raise problem(Runtime, loc, "invalid base64 padding")
      }
    } else {
      if c < 0 {
        raise problem(Runtime, loc, "invalid base64 character")
      }
      bytes.push((((b & 15) << 4) | (c >> 2)).to_byte())
      if clean[i + 3] == 61 {
        if i + 4 != clean.length() {
          raise problem(Runtime, loc, "base64 data follows padding")
        }
      } else {
        if d < 0 {
          raise problem(Runtime, loc, "invalid base64 character")
        }
        bytes.push((((c & 3) << 6) | d).to_byte())
      }
    }
  }
  Bytes::from_array(bytes)
}

///|
// Go's []rune(string(bytes)) consumes one byte for each malformed sequence,
// unlike decoders that replace an entire maximal invalid subpart at once.
fn decode_go_utf8(bytes : Bytes) -> String {
  let output = StringBuilder()
  let mut i = 0
  while i < bytes.length() {
    let first = bytes[i].to_int()
    if first < 128 {
      output.write_char(first.to_char().unwrap())
      i += 1
      continue
    }
    let (width, minimum, mask) = if first >= 194 && first <= 223 {
      (2, 128, 31)
    } else if first >= 224 && first <= 239 {
      (3, 2048, 15)
    } else if first >= 240 && first <= 244 {
      (4, 65536, 7)
    } else {
      (0, 0, 0)
    }
    let mut valid = width > 0 && width <= bytes.length() - i
    let mut point = first & mask
    if valid {
      for j in 1..<width {
        let next = bytes[i + j].to_int()
        if next < 128 || next > 191 {
          valid = false
          break
        }
        point = (point << 6) | (next & 63)
      }
      valid = valid &&
        point >= minimum &&
        point <= 0x10ffff &&
        !(point >= 0xd800 && point <= 0xdfff)
    }
    if valid {
      output.write_char(point.to_char().unwrap())
      i += width
    } else {
      output.write_char('\uFFFD')
      i += 1
    }
  }
  output.to_string()
}
