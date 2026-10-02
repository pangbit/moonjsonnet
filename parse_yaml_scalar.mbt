///|
fn yaml_tag(tag : @yaml.Tag?) -> String {
  match tag {
    None => ""
    Some(t) =>
      if t.handle == "tag:yaml.org,2002:" || t.handle == "!!" {
        t.suffix
      } else {
        let full = t.handle + t.suffix
        full.strip_prefix("tag:yaml.org,2002:").unwrap_or(full[:]).to_owned()
      }
  }
}

///|
fn Vm::yaml_scalar(
  self : Vm,
  s : String,
  style : @yaml.TScalarStyle,
  tag : @yaml.Tag?,
  loc : Location,
) -> (Json, String, String) raise {
  self.tick(loc)
  let tag = yaml_tag(tag)
  if tag == "binary" {
    let cleaned = s.replace_all(old="\n", new="").replace_all(old="\r", new="")
    let value = decode_go_utf8(self.decode_base64(cleaned, loc))
    return (Json::string(value), "str", value)
  }
  if tag == "str" ||
    (tag == "" && !(style is @yaml.Plain)) ||
    (tag != "" && !["int", "float", "bool", "null", "timestamp"].contains(tag)) {
    return (Json::string(s), "str", s)
  }
  let (value, kind, key) = yaml_resolve(s)
  if tag == "timestamp" {
    if !yaml_timestamp(s) {
      raise problem(Runtime, loc, "invalid YAML timestamp")
    }
    return (Json::string(s), "str", s)
  }
  if tag != "" &&
    tag != kind &&
    !(tag == "int" && kind == "uint") &&
    !(tag == "float" && kind == "int") {
    raise problem(Runtime, loc, "YAML scalar cannot be decoded as " + tag)
  }
  if tag == "float" && kind == "int" && value is Number(n, ..) {
    return (value, "float", yaml_float_key(n))
  }
  (value, kind, key)
}

///|
fn yaml_resolve(s : String) -> (Json, String, String) {
  if ["y", "Y", "yes", "Yes", "YES", "true", "True", "TRUE", "on", "On", "ON"].contains(
      s,
    ) {
    return (Json::boolean(true), "bool", "true")
  }
  if [
      "n", "N", "no", "No", "NO", "false", "False", "FALSE", "off", "Off", "OFF",
    ].contains(s) {
    return (Json::boolean(false), "bool", "false")
  }
  if ["", "~", "null", "Null", "NULL"].contains(s) {
    return (Json::null(), "null", "")
  }
  if [".nan", ".NaN", ".NAN"].contains(s) {
    return (Json::number(0.0 / 0.0), "float", ".nan")
  }
  if [".inf", ".Inf", ".INF", "+.inf", "+.Inf", "+.INF"].contains(s) {
    return (Json::number(1.0 / 0.0), "float", ".inf")
  }
  if ["-.inf", "-.Inf", "-.INF"].contains(s) {
    return (Json::number(-1.0 / 0.0), "float", "-.inf")
  }
  if s.is_empty() || !"+-0123456789.".contains_char(s.to_array()[0]) {
    return (Json::string(s), "str", s)
  }
  let plain = s.replace_all(old="_", new="")
  if s.has_prefix(".") {
    let chars = s.to_array()
    for i, c in chars {
      if c == '_' &&
        (
          i == 0 ||
          i + 1 == chars.length() ||
          chars[i - 1] < '0' ||
          chars[i - 1] > '9' ||
          chars[i + 1] < '0' ||
          chars[i + 1] > '9'
        ) {
        return (Json::string(s), "str", s)
      }
    }
  }
  if !s.has_prefix(".") {
    let negative = plain.has_prefix("-")
    let unsigned = if negative || plain.has_prefix("+") {
      plain[1:].to_owned()
    } else {
      plain
    }
    let (base, digits) = if unsigned.has_prefix("0x") ||
      unsigned.has_prefix("0X") {
      (16, unsigned[2:].to_owned())
    } else if unsigned.has_prefix("0o") || unsigned.has_prefix("0O") {
      (8, unsigned[2:].to_owned())
    } else if unsigned.has_prefix("0b") || unsigned.has_prefix("0B") {
      (2, unsigned[2:].to_owned())
    } else if unsigned.has_prefix("0") && unsigned.length() > 1 {
      (8, unsigned[1:].to_owned())
    } else {
      (10, unsigned)
    }
    let integer = try @string.parse_uint64(digits[:], base~) catch {
      _ => None
    } noraise {
      n => Some(n)
    }
    if integer is Some(n) &&
      !digits.is_empty() &&
      !digits.has_prefix("+") &&
      !digits.has_prefix("-") {
      if negative && n <= 9223372036854775808UL {
        return (
          Json::number(-n.to_double()),
          "int",
          if n == 0UL {
            "0"
          } else {
            "-" + n.to_string()
          },
        )
      } else if !negative {
        return (
          Json::number(n.to_double()),
          if n > 9223372036854775807UL {
            "uint"
          } else {
            "int"
          },
          n.to_string(),
        )
      }
    }
  }
  let number = if yaml_float_syntax(plain) {
    try @string.parse_double(plain[:]) catch {
      _ => None
    } noraise {
      n => if n.is_inf() { None } else { Some(n) }
    }
  } else {
    None
  }
  if number is Some(n) {
    return (Json::number(n), "float", yaml_float_key(n))
  }
  (Json::string(s), "str", s)
}

///|
fn yaml_float_syntax(s : String) -> Bool {
  let a = s.to_array()
  let mut i = if !a.is_empty() && (a[0] == '+' || a[0] == '-') { 1 } else { 0 }
  let mut digits = 0
  while i < a.length() && a[i] >= '0' && a[i] <= '9' {
    i += 1
    digits += 1
  }
  if i < a.length() && a[i] == '.' {
    i += 1
    while i < a.length() && a[i] >= '0' && a[i] <= '9' {
      i += 1
      digits += 1
    }
  }
  if digits == 0 {
    return false
  }
  if i < a.length() && (a[i] == 'e' || a[i] == 'E') {
    i += 1
    if i < a.length() && (a[i] == '+' || a[i] == '-') {
      i += 1
    }
    let start = i
    while i < a.length() && a[i] >= '0' && a[i] <= '9' {
      i += 1
    }
    if start == i {
      return false
    }
  }
  i == a.length()
}

///|
fn yaml_float_key(n : Double) -> String {
  if n.is_nan() {
    return ".nan"
  }
  if n.is_inf() {
    return if n < 0 { "-.inf" } else { ".inf" }
  }
  let rounded = Float::from_double(n)
  if rounded.is_inf() {
    return if n < 0 { "-.inf" } else { ".inf" }
  }
  let scientific = @number.float32_shortest(n)
  guard scientific.find("e") is Some(e) else { return scientific }
  let exponent = try! @string.parse_int(scientific[e + 1:])
  let negative = scientific.has_prefix("-")
  let sign = if negative { "-" } else { "" }
  let mantissa = scientific[if negative { 1 } else { 0 }:e].to_owned()
  let digits = mantissa.replace_all(old=".", new="")
  if exponent < -4 || exponent >= 6 {
    return sign +
      mantissa +
      "e" +
      (if exponent < 0 { "-" } else { "+" }) +
      (if exponent.abs() < 10 { "0" } else { "" }) +
      exponent.abs().to_string()
  }
  let point = exponent + 1
  if point <= 0 {
    sign + "0." + "0".repeat(-point) + digits
  } else if point >= digits.length() {
    sign + digits + "0".repeat(point - digits.length())
  } else {
    sign + digits[:point].to_owned() + "." + digits[point:].to_owned()
  }
}

///|
fn yaml_timestamp(s : String) -> Bool {
  let a = s.to_array()
  let mut i = 0
  let number = fn(min : Int, max : Int) {
    let start = i
    let mut n = 0
    while i < a.length() && a[i] >= '0' && a[i] <= '9' && i - start < max {
      n = n * 10 + a[i].to_int() - 48
      i += 1
    }
    if i - start < min {
      -1
    } else {
      n
    }
  }
  let consume = fn(c : Char) {
    if i < a.length() && a[i] == c {
      i += 1
      true
    } else {
      false
    }
  }
  let year = number(4, 4)
  if year < 0 || !consume('-') {
    return false
  }
  let month = number(1, 2)
  if !consume('-') {
    return false
  }
  let day = number(1, 2)
  if month < 1 || month > 12 {
    return false
  }
  let days = [
    31,
    if year % 4 == 0 && (year % 100 != 0 || year % 400 == 0) {
      29
    } else {
      28
    },
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31,
  ]
  if day < 1 || day > days[month - 1] {
    return false
  }
  if i == a.length() {
    return true
  }
  let zoned = consume('T') || consume('t')
  if !zoned && !consume(' ') {
    return false
  }
  let hour = number(1, 2)
  if hour < 0 || hour > 23 || !consume(':') {
    return false
  }
  let minute = number(1, 2)
  if minute < 0 || minute > 59 || !consume(':') {
    return false
  }
  let second = number(1, 2)
  if second < 0 || second > 59 {
    return false
  }
  if consume('.') || consume(',') {
    let start = i
    while i < a.length() && a[i] >= '0' && a[i] <= '9' {
      i += 1
    }
    if i == start {
      return false
    }
  }
  if zoned {
    if !consume('Z') {
      if !(consume('+') || consume('-')) {
        return false
      }
      let hour = number(2, 2)
      if hour < 0 || hour > 24 || !consume(':') {
        return false
      }
      let minute = number(2, 2)
      if minute < 0 || minute > 60 {
        return false
      }
    }
  }
  i == a.length()
}
