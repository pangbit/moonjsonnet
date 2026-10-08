///|
// fmt's default float64 presentation uses shortest round-trip digits and
// scientific notation below exponent -4 or from exponent 6 onward.
fn diagnostic_number(n : Double) -> String {
  let text = manifest_number(n)
  if n.is_nan() || n.is_inf() || n == 0 {
    return text
  }
  let negative = text.has_prefix("-")
  let unsigned = if negative { text[1:].to_owned() } else { text }
  let point = unsigned.find(".").unwrap_or(unsigned.length())
  let digits = unsigned.replace_all(old=".", new="")
  let mut first = 0
  while digits.code_unit_at(first) == 48 {
    first += 1
  }
  let exponent = point - first - 1
  if exponent >= -4 && exponent < 6 {
    return text
  }
  let mut end = digits.length()
  while end > first + 1 && digits.code_unit_at(end - 1) == 48 {
    end -= 1
  }
  let significand = digits[first:first + 1].to_owned() +
    (if end > first + 1 { "." + digits[first + 1:end].to_owned() } else { "" })
  let magnitude = exponent.abs().to_string()
  (if negative { "-" } else { "" }) +
  significand +
  "e" +
  (if exponent < 0 { "-" } else { "+" }) +
  (if magnitude.length() < 2 { "0" } else { "" }) +
  magnitude
}
