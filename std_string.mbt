///|
// Go strconv.ParseInt with explicit base 10: optional sign, ASCII digits only,
// signed 64-bit range. Accumulate negatively so MinInt64 stays representable.
fn parse_decimal(s : String, loc : Location) -> Value raise {
  let chars = s.to_array()
  let signed = !chars.is_empty() && (chars[0] == '-' || chars[0] == '+')
  let start = if signed { 1 } else { 0 }
  if chars.length() == start {
    raise problem(Runtime, loc, s + " is not a base 10 integer")
  }
  let negative = signed && chars[0] == '-'
  let bound = if negative {
    -9223372036854775807L - 1L
  } else {
    -9223372036854775807L
  }
  let mut value = 0L
  for i in start..<chars.length() {
    let digit = chars[i].to_int() - 48
    if digit < 0 || digit > 9 || value < bound / 10L {
      raise problem(Runtime, loc, s + " is not a base 10 integer")
    }
    value *= 10L
    if value < bound + digit.to_int64() {
      raise problem(Runtime, loc, s + " is not a base 10 integer")
    }
    value -= digit.to_int64()
  }
  Num((if negative { value } else { -value }).to_double())
}

///|
// Unicode 15 White_Space, used by the pinned Go strings.TrimSpace.
fn trim_space(s : String) -> String {
  s
  .trim(
    chars="\u0009\u000a\u000b\u000c\u000d\u0020\u0085\u00a0\u1680\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u2028\u2029\u202f\u205f\u3000",
  )
  .to_owned()
}

///|
fn equal_fold(a : String, b : String) -> Bool {
  let x = a.iter()
  let y = b.iter()
  while x.next() is Some(c) {
    guard y.next() is Some(d) else { return false }
    let c = c.to_int()
    let d = d.to_int()
    if unicode_fold.get(c).unwrap_or(c) != unicode_fold.get(d).unwrap_or(d) {
      return false
    }
  }
  y.next() is None
}

///|
fn Vm::strip_characters(
  self : Vm,
  value : Value,
  chars : Value,
  name : String,
  loc : Location,
) -> Value raise {
  guard value is Str(s) else {
    raise problem(
      Runtime,
      loc,
      "Unexpected type " + value_type(value) + ", expected string",
    )
  }
  let points = s.to_array()
  let includes = fn(c : Char) raise {
    self.tick(loc)
    match chars {
      Str(chars) => chars.contains_char(c)
      ArrayValue(items) => {
        for item in items {
          if self.equal(self.force(item, loc), Str(c.to_string()), loc) {
            return true
          }
        }
        false
      }
      _ =>
        raise problem(
          Runtime,
          loc,
          "std.member first argument must be an array or a string",
        )
    }
  }
  let mut start = 0
  let mut end = points.length()
  if name != "rstripChars" {
    while start < end && includes(points[start]) {
      start += 1
    }
  }
  if name != "lstripChars" {
    while start < end && includes(points[end - 1]) {
      end -= 1
    }
  }
  Str(String::from_array(points[start:end]))
}

///|
fn Vm::split_limit(
  self : Vm,
  s : String,
  separator : String,
  maximum : Int,
  reverse : Bool,
  loc : Location,
) -> Value raise {
  if maximum < -1 {
    raise problem(
      Runtime,
      loc,
      "std." +
      (if reverse { "splitLimitR" } else { "splitLimit" }) +
      " third parameter should be -1 or non-negative, got " +
      maximum.to_string(),
    )
  }
  if separator.is_empty() {
    raise problem(
      Runtime,
      loc,
      "std." +
      (if reverse { "splitLimitR" } else { "splitLimit" }) +
      " second parameter should have length 1 or greater, got 0",
    )
  }
  let parts : Array[Int] = []
  let mut rest = s[:]
  while maximum == -1 || parts.length() < maximum {
    self.tick(loc)
    let found = if reverse {
      rest.rev_find(separator)
    } else {
      rest.find(separator)
    }
    guard found is Some(index) else { break }
    if reverse {
      parts.push(
        self.store(Ready(Str(rest[index + separator.length():].to_owned()))),
      )
      rest = rest[:index]
    } else {
      parts.push(self.store(Ready(Str(rest[:index].to_owned()))))
      rest = rest[index + separator.length():]
    }
  }
  parts.push(self.store(Ready(Str(rest.to_owned()))))
  ArrayValue(if reverse { parts.rev() } else { parts })
}
