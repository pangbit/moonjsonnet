// Fixed Jsonnet ASCII case family: std.jsonnet 179-194 and 1766.
// Independent literal oracles; no Unicode-fold table or case-conversion oracle.

///|
fn ascii_case_limits() -> @moonjsonnet.Limits {
  { ..@moonjsonnet.Limits::default(), steps: 50000, }
}

///|
fn ascii_case_value(call : OrderingExpr, expected : Json) -> Unit raise {
  for handmade in [false, true] {
    assert_eq(
      ordering_program(call, handmade).evaluate(limits=ascii_case_limits()),
      expected,
    )
  }
}

///|
fn ascii_case_compare(left : String, right : String) -> OrderingExpr {
  sequence_call("equalsIgnoreCase", [
    reflect_string(left),
    reflect_string(right),
  ])
}

///|
fn ascii_case_reject(call : OrderingExpr) -> Unit raise {
  for handmade in [false, true] {
    try
      ordering_program(call, handmade).evaluate(limits=ascii_case_limits())
    catch {
      @moonjsonnet.Error(_) => ()
    } noraise {
      _ => fail("ASCII case call unexpectedly accepted invalid input")
    }
  }
}

///|
fn ascii_case_error(call : OrderingExpr, marker : String) -> Unit raise {
  ascii_case_value(ordering_unused(call), 42)
  for handmade in [false, true] {
    try
      ordering_program(call, handmade).evaluate(limits=ascii_case_limits())
    catch {
      @moonjsonnet.Error(d) => {
        // Embedding checks in addition to the required language failure.
        assert_eq(d.kind, @moonjsonnet.Runtime)
        assert_eq(d.message, marker)
      }
    } noraise {
      _ => fail("ASCII case call suppressed its sole required error")
    }
  }
}

///|
test "AC1 asciiUpper has literal values for all ASCII letters and range boundaries" {
  for
    (input, expected) in [
      ("abcdefghijklmnopqrstuvwxyz", "ABCDEFGHIJKLMNOPQRSTUVWXYZ"),
      ("ABCDEFGHIJKLMNOPQRSTUVWXYZ", "ABCDEFGHIJKLMNOPQRSTUVWXYZ"),
      ("@AZ[\\]^_`az{", "@AZ[\\]^_`AZ{"),
      ("100 Cats!", "100 CATS!"),
      ("", ""),
    ] {
    ascii_case_value(
      sequence_call("asciiUpper", [reflect_string(input)]),
      Json::string(expected),
    )
  }
}

///|
test "AC2 asciiLower has literal values for all ASCII letters and range boundaries" {
  for
    (input, expected) in [
      ("ABCDEFGHIJKLMNOPQRSTUVWXYZ", "abcdefghijklmnopqrstuvwxyz"),
      ("abcdefghijklmnopqrstuvwxyz", "abcdefghijklmnopqrstuvwxyz"),
      ("@AZ[\\]^_`az{", "@az[\\]^_`az{"),
      ("100 Cats!", "100 cats!"),
      ("", ""),
    ] {
    ascii_case_value(
      sequence_call("asciiLower", [reflect_string(input)]),
      Json::string(expected),
    )
  }
}

///|
test "AC3 ASCII conversion preserves nonASCII NUL combining and supplementary codepoints" {
  let input = reflect_string(
    "AzÄäΣσςßẞİıKé中😀𐐀𐐨\u0000e\u0301",
  )
  ascii_case_value(
    sequence_call("asciiUpper", [input]),
    "AZÄäΣσςßẞİıKé中😀𐐀𐐨\u0000E\u0301",
  )
  ascii_case_value(
    sequence_call("asciiLower", [input]),
    "azÄäΣσςßẞİıKé中😀𐐀𐐨\u0000e\u0301",
  )
  ascii_case_value(
    sequence_call("asciiUpper", [reflect_string("A\u007f\u0080\u00ffa")]),
    "A\u007f\u0080\u00ffA",
  )
  ascii_case_value(
    sequence_call("asciiLower", [reflect_string("A\u007f\u0080\u00ffa")]),
    "a\u007f\u0080\u00ffa",
  )
}

///|
test "AC4 equalsIgnoreCase retains ASCII equality empty and literal Unicode controls" {
  for
    (left, right, expected) in [
      ("", "", true),
      ("AbC", "aBc", true),
      ("abc", "abd", false),
      ("a", "aa", false),
      ("A\u0000Z", "a\u0000z", true),
      ("A\u0000", "a", false),
      ("É", "É", true),
      ("😀e\u0301", "😀E\u0301", true),
      ("é", "e\u0301", false),
    ] {
    ascii_case_value(ascii_case_compare(left, right), Json::boolean(expected))
  }
}

///|
test "AC5 equalsIgnoreCase does not fold distinct nonASCII case variants" {
  for
    (left, right) in [
      ("KelvinK", "kELVINk"),
      ("Σσς", "ςΣσ"),
      ("ß", "ẞ"),
      ("Ä", "ä"),
      ("İ", "i"),
      ("ı", "I"),
      ("ß", "ss"),
      ("𐐀", "𐐨"),
    ] {
    ascii_case_value(ascii_case_compare(left, right), false)
    ascii_case_value(ascii_case_compare(right, left), false)
  }
}

///|
test "AC6 consumer Unicode case input obeys the fixed ASCII lowering identity" {
  let left = reflect_string("KΣẞ𐐀")
  let right = reflect_string("kςß𐐨")
  let lower_left = sequence_call("asciiLower", [left])
  let lower_right = sequence_call("asciiLower", [right])
  ascii_case_value(lower_left, "KΣẞ𐐀")
  ascii_case_value(lower_right, "kςß𐐨")
  let lowered_equal = ordering_binary(lower_left, "==", lower_right)
  ascii_case_value(lowered_equal, false)
  let comparison = sequence_call("equalsIgnoreCase", [left, right])
  ascii_case_value(comparison, false)
  ascii_case_value(ordering_binary(comparison, "==", lowered_equal), true)
}

///|
test "AC7 ASCII case family uses required public names through direct and aliased calls" {
  let value = reflect_string("aBc")
  for (name, expected) in [("asciiUpper", "ABC"), ("asciiLower", "abc")] {
    ascii_case_value(
      rounding_apply(name, [(Some("str"), value)]),
      Json::string(expected),
    )
    let function = additive_select(sequence_var("std"), name)
    ascii_case_value(sequence_call("length", [function]), 1)
    ascii_case_value(
      sequence_local(
        [("f", function)],
        shared_mode_call(sequence_var("f"), [(Some("str"), value)]),
      ),
      Json::string(expected),
    )
    ascii_case_reject(sequence_call(name, []))
    ascii_case_reject(sequence_call(name, [value, value]))
    ascii_case_reject(
      rounding_apply(name, [(Some("str"), value), (Some("unknown"), value)]),
    )
  }
  let arguments = [(Some("str2"), reflect_string("ABC")), (Some("str1"), value)]
  ascii_case_value(rounding_apply("equalsIgnoreCase", arguments), true)
  let function = additive_select(sequence_var("std"), "equalsIgnoreCase")
  ascii_case_value(sequence_call("length", [function]), 2)
  ascii_case_value(
    sequence_local(
      [("f", function)],
      shared_mode_call(sequence_var("f"), arguments),
    ),
    true,
  )
  ascii_case_reject(sequence_call("equalsIgnoreCase", []))
  ascii_case_reject(sequence_call("equalsIgnoreCase", [value]))
  ascii_case_reject(rounding_apply("equalsIgnoreCase", [(Some("str2"), value)]))
  ascii_case_reject(sequence_call("equalsIgnoreCase", [value, value, value]))
  ascii_case_reject(
    rounding_apply("equalsIgnoreCase", [
      (Some("str1"), value),
      (Some("str2"), value),
      (Some("unknown"), value),
    ]),
  )
}

///|
test "AC8 ASCII case family rejects primitive inputs excluded by source length" {
  // Container/function stringChars admission is a separate unresolved child;
  // these primitive kinds are unambiguously rejected by length.
  for
    invalid in [
      ordering_leaf("null", Literal(Json::null())),
      reflect_bool(false),
      sequence_num(1),
    ] {
    for name in ["asciiUpper", "asciiLower"] {
      ascii_case_reject(sequence_call(name, [invalid]))
    }
    ascii_case_reject(
      sequence_call("equalsIgnoreCase", [invalid, reflect_string("")]),
    )
    ascii_case_reject(
      sequence_call("equalsIgnoreCase", [reflect_string(""), invalid]),
    )
  }
}

///|
test "AC9 ASCII case family propagates isolated required argument errors" {
  for name in ["asciiUpper", "asciiLower"] {
    let marker = "ascii-case-" + name
    ascii_case_error(sequence_call(name, [ordering_error(marker)]), marker)
  }
  ascii_case_error(
    sequence_call("equalsIgnoreCase", [
      ordering_error("ascii-case-left"),
      reflect_string(""),
    ]),
    "ascii-case-left",
  )
  ascii_case_error(
    sequence_call("equalsIgnoreCase", [
      reflect_string(""),
      ordering_error("ascii-case-right"),
    ]),
    "ascii-case-right",
  )
  ascii_case_error(
    sequence_call("equalsIgnoreCase", [
      reflect_string("unmatched"),
      ordering_error("ascii-case-required"),
    ]),
    "ascii-case-required",
  )
}

///|
test "AC10 unused ASCII case calls remain lazy in branches and Boolean shortcuts" {
  let bad = ordering_error("ascii-case-unused")
  for
    call in [
      sequence_call("asciiUpper", [bad]),
      sequence_call("asciiLower", [bad]),
      sequence_call("equalsIgnoreCase", [bad, reflect_string("")]),
      sequence_call("equalsIgnoreCase", [reflect_string(""), bad]),
    ] {
    ascii_case_value(ordering_unused(call), 42)
    let branch : OrderingExpr = {
      source: "if false then (" + call.source + ") else 42",
      tree: ordering_ast(
        If(reflect_bool(false).tree, call.tree, sequence_num(42).tree),
      ),
    }
    ascii_case_value(branch, 42)
    ascii_case_value(ordering_binary(reflect_bool(false), "&&", call), false)
    ascii_case_value(ordering_binary(reflect_bool(true), "||", call), true)
  }
}

///|
test "AC11 ASCII case results preserve original String aliases and repeated values" {
  let original = sequence_var("original")
  let lower = sequence_var("lower")
  let upper = sequence_var("upper")
  ascii_case_value(
    sequence_local(
      [
        ("original", reflect_string("AbKΣẞ😀e\u0301")),
        ("lower", sequence_call("asciiLower", [original])),
        ("upper", sequence_call("asciiUpper", [original])),
      ],
      ordering_array([
        original,
        lower,
        upper,
        original,
        sequence_call("equalsIgnoreCase", [original, lower]),
        lower,
        upper,
      ]),
    ),
    [
      "AbKΣẞ😀e\u0301", "abKΣẞ😀e\u0301", "ABKΣẞ😀E\u0301",
      "AbKΣẞ😀e\u0301", true, "abKΣẞ😀e\u0301", "ABKΣẞ😀E\u0301",
    ],
  )
}
