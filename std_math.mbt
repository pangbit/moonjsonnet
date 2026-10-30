///|
fn math_builtin(
  name : String,
  values : Array[Value],
  loc : Location,
) -> Value raise {
  if name == "xor" || name == "xnor" {
    let x = boolean(values[0], loc)
    let y = boolean(values[1], loc)
    return Bool(if name == "xor" { x != y } else { x == y })
  }
  let x = number_value(values[0], loc)
  match name {
    "isEven" => Bool(x.trunc() % 2 == 0)
    "isOdd" => Bool(x.trunc() % 2 != 0)
    "isInteger" => Bool(x - x.trunc() == 0)
    "isDecimal" => Bool(x - x.trunc() != 0)
    "round" => {
      let whole = x.trunc()
      let rounded = if (x - whole).abs() >= 0.5 {
        if x < 0 {
          whole - 1
        } else {
          whole + 1
        }
      } else {
        whole
      }
      finite(rounded, loc)
    }
    "mantissa" => finite(binary_fraction(x).0, loc)
    "exponent" => Num(binary_fraction(x).1.to_double())
    "modulo" => {
      let y = number_value(values[1], loc)
      if y == 0 {
        raise problem(Runtime, loc, "Division by zero.")
      }
      finite(x % y, loc)
    }
    _ => {
      let result = match name {
        "sqrt" => x.sqrt()
        "sin" | "cos" | "tan" => reference_trig(name, x)
        "asin" => reference_asin(x)
        "acos" => 1.5707963267948966 - reference_asin(x)
        "atan" => reference_atan(x)
        "log" => reference_log(x)
        "exp" => reference_exp(x)
        "hypot" => @math.hypot(x, number_value(values[1], loc))
        "atan2" => reference_atan2(x, number_value(values[1], loc))
        "pow" => reference_pow(x, number_value(values[1], loc))
        _ => raise problem(Unsupported, loc, "unsupported math function")
      }
      finite(result, loc)
    }
  }
}

///|
// IEEE binary64 decomposition, including normalization of subnormal values.
fn binary_fraction(x : Double) -> (Double, Int32) {
  if x == 0 || x.is_inf() || x.is_nan() {
    return (x, 0)
  }
  let small = x.abs() < 2.2250738585072014e-308
  let normalized = if small { x * 18014398509481984.0 } else { x }
  let bits = normalized.reinterpret_as_int64()
  let exponent = (bits >> 52).land(2047L).to_int() -
    1022 -
    (if small { 54 } else { 0 })
  let fraction = bits
    .land(0x7ff0000000000000L.lnot())
    .lor(0x3fe0000000000000L)
    .reinterpret_as_double()
  (fraction, exponent)
}
