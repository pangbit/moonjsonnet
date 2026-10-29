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
          let bytes : Array[Byte] = []
          for c in s.iter() {
            self.tick(loc)
            if c.to_int() > 255 {
              raise problem(
                Runtime,
                loc,
                "base64 encountered invalid codepoint value in the array (must be 0 <= X <= 255), got " +
                c.to_int().to_string(),
              )
            }
            bytes.push(c.to_int().to_byte())
          }
          // The fixed stdlib maps each character to one codepoint byte.
          Bytes::from_array(bytes)
        }
        ArrayValue(_) => self.byte_array(value, true, loc)
        _ =>
          raise problem(
            Runtime,
            loc,
            "base64 can only base64 encode strings / arrays of single bytes, got " +
            value_type(value),
          )
      }
      Str(@base64.encode(bytes))
    }
    "encodeUTF8" => self.bytes_value(@utf8.encode(text_value(value, loc)), loc)
    "decodeUTF8" => Str(decode_go_utf8(self.byte_array(value, false, loc)))
    _ => {
      guard value is Str(s) else {
        raise problem(
          Runtime,
          loc,
          "base64DecodeBytes requires a string, got " + value_type(value),
        )
      }
      let bytes = self.decode_base64(s, loc)
      if name == "base64DecodeBytes" {
        self.bytes_value(bytes, loc)
      } else {
        // The fixed stdlib maps each decoded byte through std.char.
        let output = StringBuilder()
        for b in bytes.iter() {
          output.write_char(b.to_int().to_char().unwrap())
        }
        Str(output.to_string())
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
    // Base64's documented Number range includes fractions. The fixed source
    // encodes them through truncating bitwise conversion. Check the original
    // bounds first; decodeUTF8 and rejected inputs keep their integer path.
    let converted = match value {
      Num(n) =>
        if base64 && n >= 0 && n <= 255 {
          Num(n.trunc())
        } else {
          value
        }
      _ => value
    }
    let n = integer(converted, loc) catch {
      e =>
        if base64 {
          raise problem(
            Runtime,
            loc,
            "base64 encountered a non-integer value in the array, got " +
            value_type(value),
          )
        } else {
          raise e
        }
    }
    if n < 0 || n > 255 {
      raise problem(
        Runtime,
        loc,
        (if base64 {
          "base64 encountered invalid codepoint value in the array (must be 0 <= X <= 255), got "
        } else {
          "Bytes must be integers in range [0, 255], got "
        }) +
        n.to_string(),
      )
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
    raise problem(
      Runtime,
      loc,
      "input string appears not to be a base64 encoded string. Wrong length found (" +
      raw.length().to_string() +
      ")",
    )
  }
  // Keep the original UTF-8 offsets while skipping CR/LF. Go's decoder reports
  // consumed byte positions, including skipped newlines and incomplete padding.
  let bytes : Array[Byte] = []
  let mut position = 0
  while position < raw.length() {
    self.tick(loc)
    let digits = FixedArray::make(4, 0)
    let mut count = 0
    while count < 4 {
      if position == raw.length() {
        if count != 0 {
          raise base64_corrupt(loc, position - count)
        }
        break
      }
      let byte = raw[position]
      position += 1
      let digit = base64_digit(byte)
      if digit >= 0 {
        digits[count] = digit
        count += 1
        continue
      }
      if byte == 13 || byte == 10 {
        continue
      }
      if byte != 61 || count < 2 {
        raise base64_corrupt(loc, position - 1)
      }
      if count == 2 {
        while position < raw.length() &&
              (raw[position] == 13 || raw[position] == 10) {
          position += 1
        }
        if position == raw.length() {
          raise base64_corrupt(loc, position)
        }
        if raw[position] != 61 {
          raise base64_corrupt(loc, position - 1)
        }
        position += 1
      }
      while position < raw.length() &&
            (raw[position] == 13 || raw[position] == 10) {
        position += 1
      }
      if position < raw.length() {
        raise base64_corrupt(loc, position)
      }
      break
    }
    if count >= 2 {
      bytes.push(((digits[0] << 2) | (digits[1] >> 4)).to_byte())
    }
    if count >= 3 {
      bytes.push((((digits[1] & 15) << 4) | (digits[2] >> 2)).to_byte())
    }
    if count == 4 {
      bytes.push((((digits[2] & 3) << 6) | digits[3]).to_byte())
    }
  }
  Bytes::from_array(bytes)
}

///|
fn base64_corrupt(loc : Location, offset : Int) -> JsonnetError {
  problem(
    Runtime,
    loc,
    "failed to decode: illegal base64 data at input byte " + offset.to_string(),
  )
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
