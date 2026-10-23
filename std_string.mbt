///|
// Fixed parseInt/parse_nat: optional minus and ASCII digits, accumulated using
// separate finite Number multiplication and addition without Int64 narrowing.
fn parse_decimal(s : String, loc : Location) -> Value raise {
  let chars = s.to_array()
  let negative = !chars.is_empty() && chars[0] == '-'
  let start = if negative { 1 } else { 0 }
  if chars.length() == start {
    raise problem(Runtime, loc, s + " is not a base 10 integer")
  }
  let mut value = 0.0
  for i in start..<chars.length() {
    let digit = chars[i].to_int() - 48
    if digit < 0 || digit > 9 {
      raise problem(Runtime, loc, s + " is not a base 10 integer")
    }
    let product = number_value(finite(10.0 * value, loc), loc)
    value = number_value(finite(product + digit.to_double(), loc), loc)
  }
  finite(if negative { -value } else { value }, loc)
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
  chars_thunk : Int,
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
  if s.is_empty() {
    return Str(s)
  }
  let chars = self.force(chars_thunk, loc)
  let points = s.to_array()
  let includes = fn(c : Char) raise {
    self.tick(loc)
    match chars {
      Str(chars) => chars.contains_char(c)
      ArrayValue(items) => {
        // Fixed member counts all matches; an early match cannot skip errors.
        let mut found = false
        for item in items {
          if self.equal(self.force(item, loc), Str(c.to_string()), loc) {
            found = true
          }
        }
        found
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
  maximum_thunk : Int,
  reverse : Bool,
  loc : Location,
) -> Value raise {
  if separator.is_empty() {
    raise problem(
      Runtime,
      loc,
      "std." +
      (if reverse { "splitLimitR" } else { "splitLimit" }) +
      " second parameter should have length 1 or greater, got 0",
    )
  }
  let maximum = number_value(self.force(maximum_thunk, loc), loc)
  // Retain the existing rejection policy for unadjudicated fractional and
  // negative limits, without narrowing valid nonnegative Number bounds.
  if maximum != maximum.floor() || maximum < -2147483648.0 {
    raise problem(
      Runtime,
      loc,
      "Expected an integer, but got " + diagnostic_number(maximum),
    )
  }
  if maximum < -1.0 {
    raise problem(
      Runtime,
      loc,
      "std." +
      (if reverse { "splitLimitR" } else { "splitLimit" }) +
      " third parameter should be -1 or non-negative, got " +
      diagnostic_number(maximum),
    )
  }
  let parts : Array[Int] = []
  let mut rest = s[:]
  while maximum == -1.0 || parts.length().to_double() < maximum {
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
