///|
priv struct FormatCode {
  key : String?
  alt : Bool
  zero : Bool
  left : Bool
  blank : Bool
  plus : Bool
  width : Int
  precision : Int?
  width_arg : Bool
  precision_arg : Bool
  kind : Char
}

///|
fn parse_format(
  chars : Array[Char],
  offset : Int,
  limit : Int,
  loc : Location,
) -> (FormatCode, Int) raise {
  let mut i = offset
  let mut key = None
  if chars.get(i) == Some('(') {
    i += 1
    let b = StringBuilder()
    while chars.get(i) != Some(')') {
      guard i < chars.length() else {
        raise problem(Runtime, loc, "unterminated format mapping key")
      }
      b.write_char(chars[i])
      i += 1
    }
    key = Some(b.to_string())
    i += 1
  }
  let mut alt = false
  let mut zero = false
  let mut left = false
  let mut blank = false
  let mut plus = false
  while i < chars.length() {
    match chars[i] {
      '#' => alt = true
      '0' => zero = true
      '-' => left = true
      ' ' => blank = true
      '+' => plus = true
      _ => break
    }
    i += 1
  }
  let width_arg = chars.get(i) == Some('*')
  let mut width = 0
  if width_arg {
    i += 1
  } else {
    while i < chars.length() && digit(chars[i]) {
      let d = chars[i].to_int() - 48
      if width > (limit - d) / 10 {
        raise problem(Limit, loc, "format width exceeds output limit")
      }
      width = width * 10 + d
      i += 1
    }
  }
  let mut precision = None
  let mut precision_arg = false
  if chars.get(i) == Some('.') {
    i += 1
    precision_arg = chars.get(i) == Some('*')
    if precision_arg {
      i += 1
    } else {
      let mut p = 0
      while i < chars.length() && digit(chars[i]) {
        let d = chars[i].to_int() - 48
        if p > (limit - d) / 10 {
          raise problem(Limit, loc, "format precision exceeds output limit")
        }
        p = p * 10 + d
        i += 1
      }
      precision = Some(p)
    }
  }
  if chars.get(i) == Some('h') ||
    chars.get(i) == Some('l') ||
    chars.get(i) == Some('L') {
    i += 1
  }
  guard i < chars.length() else {
    raise problem(Runtime, loc, "truncated format code")
  }
  let kind = chars[i]
  if !"diuoxXeEfFgGcs%".to_array().contains(kind) {
    raise problem(Runtime, loc, "unrecognized format conversion")
  }
  (
    {
      key,
      alt,
      zero,
      left,
      blank,
      plus,
      width,
      precision,
      width_arg,
      precision_arg,
      kind,
    },
    i + 1,
  )
}

///|
fn Vm::format_size(self : Vm, v : Value, loc : Location) -> Double raise {
  let n = number_value(v, loc)
  if n.abs() > self.limits.output_bytes.to_double() {
    raise problem(Limit, loc, "format size exceeds output limit")
  }
  n
}

///|
fn Vm::format_string(
  self : Vm,
  format : String,
  values : Value,
  loc : Location,
) -> String raise {
  let chars = format.to_array()
  let args = match values {
    ArrayValue(a) => a
    ObjectValue(_, _) => []
    _ => [self.store(Ready(values))]
  }
  let mut position = 0
  let mut i = 0
  let b = StringBuilder()
  let mut bytes = 0
  let append = fn(s : String) raise {
    let size = @utf8.encode(s).length()
    if size > self.limits.output_bytes - bytes {
      raise problem(Limit, loc, "format output limit exceeded")
    }
    bytes += size
    b.write_string(s)
  }
  let next = fn() raise {
    guard position < args.length() else {
      raise problem(Runtime, loc, "not enough format arguments")
    }
    let v = self.force(args[position], loc)
    position += 1
    v
  }
  while i < chars.length() {
    self.tick(loc)
    if chars[i] != '%' {
      append(chars[i].to_string())
      i += 1
      continue
    }
    let (code, after) = parse_format(
      chars,
      i + 1,
      self.limits.output_bytes,
      loc,
    )
    i = after
    let object = values is ObjectValue(_, _)
    let uses_precision = code.kind != 's' &&
      code.kind != 'c' &&
      code.kind != '%'
    if object && (code.width_arg || (code.precision_arg && uses_precision)) {
      raise problem(
        Runtime,
        loc,
        "mapping format cannot use dynamic width or precision",
      )
    }
    let width = if code.width_arg {
      self.format_size(next(), loc)
    } else {
      code.width.to_double()
    }
    let precision = if code.precision_arg {
      if object {
        None
      } else {
        guard position < args.length() else {
          raise problem(Runtime, loc, "not enough format arguments")
        }
        let id = args[position]
        position += 1
        if uses_precision {
          match self.force(id, loc) {
            Nil => None
            v => Some(self.format_size(v, loc))
          }
        } else {
          None
        }
      }
    } else {
      code.precision.map(p => p.to_double())
    }
    let rendered = if code.kind == '%' {
      "%"
    } else {
      let v = match values {
        ObjectValue(id, top) => {
          guard code.key is Some(key) else {
            raise problem(Runtime, loc, "mapping format requires a key")
          }
          self.field(id, top, key, loc)
        }
        _ => next()
      }
      self.format_value(v, code, width, precision, loc)
    }
    append(format_pad(rendered, width, ' ', code.left))
  }
  if !(values is ObjectValue(_, _)) && position < args.length() {
    raise problem(Runtime, loc, "too many format arguments")
  }
  b.to_string()
}

///|
fn format_pad(s : String, width : Double, char : Char, right : Bool) -> String {
  let n = (width - s.iter().count().to_double()).ceil().to_int()
  if n <= 0 {
    return s
  }
  let b = StringBuilder()
  if right {
    b.write_string(s)
  }
  for _ in 0..<n {
    b.write_char(char)
  }
  if !right {
    b.write_string(s)
  }
  b.to_string()
}

///|
fn format_digits(n : Double, base : Int, caps : Bool) -> String {
  let digits = (if caps { "0123456789ABCDEF" } else { "0123456789abcdef" }).to_array()
  let out = []
  let mut n = n
  if n == 0 {
    return "0"
  }
  while n > 0 {
    let remainder = n % base.to_double()
    out.push(
      if remainder == remainder.floor() {
        digits[remainder.to_int()].to_string()
      } else {
        @number.format(remainder)
      },
    )
    n = (n / base.to_double()).floor()
  }
  let b = StringBuilder()
  for i = out.length() - 1; i >= 0; i = i - 1 {
    b.write_string(out[i])
  }
  b.to_string()
}

///|
fn format_sign(negative : Bool, code : FormatCode) -> String {
  if negative {
    "-"
  } else if code.plus {
    "+"
  } else if code.blank {
    " "
  } else {
    ""
  }
}

///|
fn format_decimal(
  n : Double,
  code : FormatCode,
  width : Double,
  precision : Double,
  trailing : Bool,
  loc : Location,
) -> String raise {
  let denominator = @math.pow(10, precision)
  let rounded = n.abs() * denominator + 0.5
  if denominator == 0 || denominator.is_inf() || rounded.is_inf() {
    raise problem(Runtime, loc, "non-finite formatting arithmetic")
  }
  let whole = (rounded / denominator).floor()
  let fraction = rounded.floor() % denominator
  let sign = format_sign(n < 0, code)
  let dot = if precision == 0 && !code.alt { 0 } else { 1 }
  let integral = format_pad(
    format_digits(whole, 10, false),
    width - precision - dot.to_double() - sign.length().to_double(),
    '0',
    false,
  )
  if precision == 0 {
    return sign + integral + (if code.alt { "." } else { "" })
  }
  if !trailing && fraction <= 0 {
    return sign + integral
  }
  let mut fractional = format_pad(
    format_digits(fraction, 10, false),
    precision,
    '0',
    false,
  )
  if !trailing {
    let mut end = fractional.length()
    while end > 0 && fractional.code_unit_at(end - 1) == 48 {
      end -= 1
    }
    fractional = fractional[:end].to_owned()
  }
  sign + integral + "." + fractional
}

///|
fn format_exponent(n : Double) -> Int {
  if n == 0 {
    0
  } else {
    (@math.ln(n.abs()) / @math.ln(10)).floor().to_int()
  }
}

///|
fn format_scientific(
  n : Double,
  code : FormatCode,
  width : Double,
  precision : Double,
  trailing : Bool,
  loc : Location,
) -> String raise {
  let exponent = format_exponent(n)
  let sign = if exponent < 0 { "-" } else { "+" }
  let suffix = (if code.kind == 'E' || code.kind == 'G' { "E" } else { "e" }) +
    sign +
    format_pad(exponent.abs().to_string(), 2, '0', false)
  let mantissa = if exponent == -324 {
    n * 10 / @math.pow(10, -323)
  } else {
    n / @math.pow(10, exponent.to_double())
  }
  format_decimal(
    mantissa,
    code,
    width - suffix.length().to_double(),
    precision,
    trailing,
    loc,
  ) +
  suffix
}

///|
fn Vm::format_value(
  self : Vm,
  value : Value,
  code : FormatCode,
  width : Double,
  precision : Double?,
  loc : Location,
) -> String raise {
  if code.kind == 's' {
    return self.coerce_string(value, loc)
  }
  if code.kind == 'c' {
    return match value {
      Str(s) => {
        if s.iter().count() != 1 {
          raise problem(Runtime, loc, "%c requires one code point")
        }
        s
      }
      Num(n) => {
        if n <= -1 || n >= 1114112 {
          raise problem(Runtime, loc, "invalid character code")
        }
        guard n.to_int().to_char() is Some(c) else {
          raise problem(Runtime, loc, "invalid Unicode scalar")
        }
        c.to_string()
      }
      _ => raise problem(Type, loc, "%c requires a number or string")
    }
  }
  let n = number_value(value, loc)
  let padding = if code.zero && !code.left { width } else { 0 }
  match code.kind {
    'd' | 'i' | 'u' | 'o' | 'x' | 'X' => {
      let hex = code.kind == 'x' || code.kind == 'X'
      let octal = code.kind == 'o'
      let magnitude = if hex { n.floor().abs() } else { n.abs().floor() }
      let sign = format_sign(if hex { n.floor() < 0 } else { n <= -1 }, code)
      let prefix = if code.alt && hex {
        if code.kind == 'X' {
          "0X"
        } else {
          "0x"
        }
      } else {
        ""
      }
      let digits = (if octal && code.alt && magnitude != 0 { "0" } else { "" }) +
        format_digits(
          magnitude,
          if hex {
            16
          } else if octal {
            8
          } else {
            10
          },
          code.kind == 'X',
        )
      sign +
      prefix +
      format_pad(
        digits,
        Double::max(
          precision.unwrap_or(0),
          padding - sign.length().to_double() - prefix.length().to_double(),
        ),
        '0',
        false,
      )
    }
    'f' | 'F' =>
      format_decimal(n, code, padding, precision.unwrap_or(6), true, loc)
    'e' | 'E' =>
      format_scientific(n, code, padding, precision.unwrap_or(6), true, loc)
    _ => {
      let p = precision.unwrap_or(6)
      let exponent = format_exponent(n)
      if exponent < -4 || exponent.to_double() >= p {
        format_scientific(n, code, padding, p - 1, code.alt, loc)
      } else {
        format_decimal(
          n,
          code,
          padding,
          p - Int::max(1, exponent + 1).to_double(),
          code.alt,
          loc,
        )
      }
    }
  }
}
