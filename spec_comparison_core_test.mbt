// Fixed spec.html cmp-number/cmp-string and numeric semantics, 2448-2538/2796-2804.
// Literal signs are observed through the three unambiguous <, <=, >= consumers.
// Number source text and canonical Literal AST values are supplied separately.
// Array rule witnesses remain AO1-3/RS1-3; no std.cmp public API is assumed.

///|
fn comparison_number(source : String, value : Double) -> OrderingExpr {
  ordering_leaf(source, Literal(Json::number(value)))
}

///|
test "CC1 finite numeric comparison preserves IEEE order at representable boundaries" {
  for
    (left, right, expected) in [
      (
        comparison_number("-0", -0.0),
        comparison_number("0", 0.0),
        Json::array([false, true, true]),
      ),
      (
        comparison_number("-0.5", -0.5),
        comparison_number("-0.25", -0.25),
        Json::array([true, true, false]),
      ),
      (
        comparison_number("0.125", 0.125),
        comparison_number("0.25", 0.25),
        Json::array([true, true, false]),
      ),
      (
        comparison_number("0.1", 0.1),
        comparison_number("0.1", 0.1),
        Json::array([false, true, true]),
      ),
      (
        comparison_number("0.5", 0.5),
        comparison_number("0.25", 0.25),
        Json::array([false, false, true]),
      ),
      (
        comparison_number("-5e-324", -5.0e-324),
        comparison_number("0", 0.0),
        Json::array([true, true, false]),
      ),
      (
        comparison_number("0", 0.0),
        comparison_number("5e-324", 5.0e-324),
        Json::array([true, true, false]),
      ),
      (
        comparison_number("5e-324", 5.0e-324),
        comparison_number("1e-323", 1.0e-323),
        Json::array([true, true, false]),
      ),
      (
        comparison_number("5e-324", 5.0e-324),
        comparison_number("5e-324", 5.0e-324),
        Json::array([false, true, true]),
      ),
      (
        comparison_number("2.225073858507201e-308", 2.225073858507201e-308),
        comparison_number("2.2250738585072014e-308", 2.2250738585072014e-308),
        Json::array([true, true, false]),
      ),
      (
        comparison_number("2.2250738585072014e-308", 2.2250738585072014e-308),
        comparison_number("2.225073858507201e-308", 2.225073858507201e-308),
        Json::array([false, false, true]),
      ),
      (
        comparison_number("9007199254740991", 9007199254740991.0),
        comparison_number("9007199254740992", 9007199254740992.0),
        Json::array([true, true, false]),
      ),
      (
        comparison_number("9007199254740992", 9007199254740992.0),
        comparison_number("9007199254740994", 9007199254740994.0),
        Json::array([true, true, false]),
      ),
      (
        comparison_number("1.7976931348623155e308", 1.7976931348623155e308),
        comparison_number("1.7976931348623157e308", 1.7976931348623157e308),
        Json::array([true, true, false]),
      ),
      (
        comparison_number("1.7976931348623157e308", 1.7976931348623157e308),
        comparison_number("1.7976931348623157e308", 1.7976931348623157e308),
        Json::array([false, true, true]),
      ),
      (
        comparison_number("-1.7976931348623157e308", -1.7976931348623157e308),
        comparison_number("-2.2250738585072014e-308", -2.2250738585072014e-308),
        Json::array([true, true, false]),
      ),
    ] {
    relational_values(left, right, expected)
  }
}

///|
test "CC2 string comparison uses codepoint order across widths and equal prefixes" {
  for
    (left, right, expected) in [
      ("\u007f", "\u0080", Json::array([true, true, false])),
      ("\u07ff", "\u0800", Json::array([true, true, false])),
      ("\ud7ff", "\ue000", Json::array([true, true, false])),
      ("\uffff", "\u{10000}", Json::array([true, true, false])),
      ("\u{10000}", "\uffff", Json::array([false, false, true])),
      ("\u{10fffe}", "\u{10ffff}", Json::array([true, true, false])),
      ("\u0000\u{10ffff}", "\u0000\u{10ffff}", Json::array([false, true, true])),
      ("\u{10ffff}", "\u{10ffff}\u0000", Json::array([true, true, false])),
      ("\u{10ffff}\u0000", "\u{10ffff}", Json::array([false, false, true])),
      ("a\u0000b", "a\u0000c", Json::array([true, true, false])),
      ("a\u{10000}z", "a\u{10ffff}a", Json::array([true, true, false])),
      ("A\u030a", "Å", Json::array([true, true, false])),
    ] {
    relational_values(reflect_string(left), reflect_string(right), expected)
  }
}

///|
test "CC3 scalar comparisons demand each required head and leave unused expressions lazy" {
  for op in ["<", "<=", ">="] {
    for
      value in [
        comparison_number("0.125", 0.125),
        reflect_string("a\u0000😀"),
      ] {
      for
        (left, right, marker) in [
          (
            ordering_error("comparison-left-head"),
            value,
            "comparison-left-head",
          ),
          (
            value,
            ordering_error("comparison-right-head"),
            "comparison-right-head",
          ),
        ] {
        let expression = ordering_binary(left, op, right)
        // Runtime kind/marker are extra embedding checks on the sole error.
        transfer_error(expression, marker)
        transfer_value(
          transfer_if(reflect_bool(false), expression, sequence_num(42)),
          42,
        )
        transfer_value(
          transfer_if(reflect_bool(true), sequence_num(42), expression),
          42,
        )
      }
    }
  }
}

///|
test "CC4 scalar comparison gates incompatible heads before nested payload demand" {
  let bad = ordering_error("comparison-unread-payload")
  let object = reflect_object([(reflect_string("x"), 1, bad)])
  let closure = make_function([], bad)
  let array = ordering_array([bad])
  for op in ["<", "<=", ">="] {
    for scalar in [comparison_number("0.5", 0.5), reflect_string("a")] {
      for other in [object, closure, array] {
        for (left, right) in [(scalar, other), (other, scalar)] {
          // Type distinguishes head rejection from the poisoned Runtime child;
          // neither this host tag nor a competing-error winner is a language rule.
          sequence_failure(
            ordering_binary(left, op, right),
            @moonjsonnet.Type,
            None,
          )
        }
      }
    }
  }
}
