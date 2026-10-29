// Fixed Jsonnet v0.21.0 std.jsonnet 37-38, 842-849 and 1661-1689.
// Literal source/handmade-AST criteria for all, any, assertEqual and toString.
// Reuse only neutral constructors and the existing collecting value helper.
// Object witnesses have no assertions/inheritance; no array concatenation is used.

///|
test "CC1 Boolean reducers preserve empty identities and literal truth tables" {
  let cases : Array[(OrderingExpr, Json)] = []
  for (name, empty, mixed) in [("all", true, false), ("any", false, true)] {
    for
      (values, expected) in [
        ([], empty),
        ([true], true),
        ([false], false),
        ([true, true], true),
        ([false, false], false),
        ([true, false], mixed),
        ([false, true], mixed),
        ([true, false, true], mixed),
      ] {
      cases.push(
        (
          sequence_call(name, [ordering_array(values.map(reflect_bool))]),
          Json::boolean(expected),
        ),
      )
    }
  }
  string_utilities_values(cases)
}

///|
test "CC2 reducer decisive prefixes leave later invalid heads and errors unused" {
  let unread = ordering_error("config-unread-tail")
  let tails = [
    unread,
    ordering_leaf("null", Literal(Json::null())),
    sequence_num(1),
    reflect_string("not a Boolean"),
    ordering_array([unread]),
    reflect_object([(reflect_string("x"), 1, unread)]),
    value_head_function(unread, unread),
  ]
  let cases : Array[(OrderingExpr, Json)] = []
  for
    (name, decisive, continuing) in [("all", false, true), ("any", true, false)] {
    for tail in tails {
      cases.push(
        (
          sequence_call(name, [ordering_array([reflect_bool(decisive), tail])]),
          Json::boolean(decisive),
        ),
      )
      cases.push(
        (
          sequence_call(name, [
            ordering_array([
              reflect_bool(continuing),
              reflect_bool(decisive),
              tail,
            ]),
          ]),
          Json::boolean(decisive),
        ),
      )
    }
  }
  string_utilities_values(cases)
}

///|
test "CC3 reducers reject nonarray inputs and every visited nonboolean head" {
  let unread = ordering_error("config-invalid-payload")
  let nonbooleans = [
    ordering_leaf("null", Literal(Json::null())),
    sequence_num(0),
    reflect_string(""),
    ordering_array([unread]),
    reflect_object([(reflect_string("x"), 1, unread)]),
    value_head_function(unread, unread),
  ]
  for (name, continuing) in [("all", true), ("any", false)] {
    for input in nonbooleans {
      transfer_reject(sequence_call(name, [ordering_array([input])]))
      transfer_reject(
        sequence_call(name, [ordering_array([reflect_bool(continuing), input])]),
      )
    }
    for
      input in [
        ordering_leaf("null", Literal(Json::null())),
        reflect_bool(false),
        reflect_bool(true),
        sequence_num(0),
        reflect_string(""),
        reflect_object([(reflect_string("x"), 1, unread)]),
        value_head_function(unread, unread),
      ] {
      // Rejection alone makes no claim about payload evaluation or diagnostics.
      transfer_reject(sequence_call(name, [input]))
    }
    let needed = sequence_call(name, [
      ordering_array([reflect_bool(continuing), unread]),
    ])
    transfer_reject(needed)
    transfer_reject(sequence_call("type", [needed]))
  }
}

///|
test "CC4 assertEqual returns true for equal ordinary values without printing them" {
  let unread = ordering_error("config-hidden-equal")
  let cases : Array[(OrderingExpr, OrderingExpr)] = [
    (
      ordering_leaf("null", Literal(Json::null())),
      ordering_leaf("null", Literal(Json::null())),
    ),
    (reflect_bool(false), reflect_bool(false)),
    (reflect_bool(true), reflect_bool(true)),
    (sequence_num(0), sequence_num(0)),
    (sequence_num(-2), sequence_num(-2)),
    (reflect_string(""), reflect_string("")),
    (
      reflect_string("é中😀\n\u{0000}"),
      reflect_string("é中😀\n\u{0000}"),
    ),
    (ordering_array([]), ordering_array([])),
    (
      ordering_array([sequence_num(1), reflect_string("é"), reflect_bool(true)]),
      ordering_array([sequence_num(1), reflect_string("é"), reflect_bool(true)]),
    ),
    (reflect_object([]), reflect_object([])),
    (
      reflect_object([
        (reflect_string("a"), 1, sequence_num(7)),
        (reflect_string("h"), 2, unread),
      ]),
      reflect_object([(reflect_string("a"), 1, sequence_num(7))]),
    ),
    (
      reflect_object([
        (reflect_string("z"), 1, ordering_array([reflect_bool(false)])),
        (reflect_string("a"), 1, reflect_string("中")),
      ]),
      reflect_object([
        (reflect_string("a"), 1, reflect_string("中")),
        (reflect_string("z"), 1, ordering_array([reflect_bool(false)])),
      ]),
    ),
  ]
  string_utilities_values(
    cases.map(c => {
      (sequence_call("assertEqual", [c.0, c.1]), Json::boolean(true))
    }),
  )
}

///|
test "CC5 assertEqual rejects unequal values noncomparable functions and needed errors" {
  let unread = ordering_error("config-required-equal")
  let cases : Array[(OrderingExpr, OrderingExpr)] = [
    (reflect_bool(true), reflect_bool(false)),
    (sequence_num(1), sequence_num(2)),
    (sequence_num(1), reflect_string("1")),
    (reflect_string("é"), reflect_string("e")),
    (ordering_array([]), ordering_array([sequence_num(0)])),
    (ordering_array([sequence_num(1)]), ordering_array([sequence_num(2)])),
    (
      reflect_object([]),
      reflect_object([(reflect_string("a"), 1, sequence_num(0))]),
    ),
    (make_function([], sequence_num(0)), make_function([], sequence_num(0))),
    (
      additive_select(sequence_var("std"), "length"),
      additive_select(sequence_var("std"), "length"),
    ),
    (ordering_array([unread]), ordering_array([sequence_num(0)])),
    (ordering_array([sequence_num(0)]), ordering_array([unread])),
  ]
  for (left, right) in cases {
    let call = sequence_call("assertEqual", [left, right])
    transfer_reject(call)
    transfer_reject(sequence_call("type", [call]))
  }
}

///|
test "CC6 toString preserves raw Strings and fixed ordinary scalar representations" {
  let cases : Array[(OrderingExpr, String)] = [
    (reflect_string(""), ""),
    (
      reflect_string(" \té中😀\n\u{0000}\u{0085} "),
      " \té中😀\n\u{0000}\u{0085} ",
    ),
    (reflect_string("\"\\$"), "\"\\$"),
    (ordering_leaf("null", Literal(Json::null())), "null"),
    (reflect_bool(false), "false"),
    (reflect_bool(true), "true"),
    (sequence_num(0), "0"),
    (sequence_num(-2), "-2"),
    (ordering_leaf("0.5", Literal(Json::number(0.5))), "0.5"),
    (ordering_leaf("0.1", Literal(Json::number(0.1))), "0.10000000000000001"),
    (ordering_leaf("1e-8", Literal(Json::number(1.0e-8))), "1e-08"),
  ]
  string_utilities_values(
    cases.map(c => (sequence_call("toString", [c.0]), Json::string(c.1))),
  )
}

///|
test "CC7 toString manifests visible data and propagates nested failures" {
  let unread = ordering_error("config-required-string")
  // Fixed spec tostring requires single-line JSON, not one empty-container spacing.
  let empty_cases = [
    (ordering_array([]), Json::array([])),
    (reflect_object([]), Json::object(Map([]))),
    (
      reflect_object([(reflect_string("hidden"), 2, unread)]),
      Json::object(Map([])),
    ),
  ]
  for (input, expected) in empty_cases {
    for handmade in [false, true] {
      let actual = ordering_program(
        sequence_call("toString", [input]),
        handmade,
      ).evaluate(limits=transfer_limits())
      guard actual is String(text) else { fail("toString must return String") }
      assert_true(!text.contains_char('\n') && !text.contains_char('\r'))
      assert_eq(@json.parse(text), expected)
    }
  }
  // Existing nonempty spacing literals are retained as a compatibility profile.
  let cases : Array[(OrderingExpr, String)] = [
    (ordering_array([sequence_num(1), reflect_string("é")]), "[1, \"é\"]"),
    (
      reflect_object([
        (reflect_string("b"), 1, sequence_num(2)),
        (
          reflect_string("a"),
          1,
          ordering_array([sequence_num(1), sequence_num(2)]),
        ),
        (reflect_string("hidden"), 2, unread),
      ]),
      "{\"a\": [1, 2], \"b\": 2}",
    ),
  ]
  string_utilities_values(
    cases.map(c => (sequence_call("toString", [c.0]), Json::string(c.1))),
  )
  for
    input in [
      make_function([], unread),
      additive_select(sequence_var("std"), "length"),
      ordering_array([unread]),
      reflect_object([(reflect_string("visible"), 1, unread)]),
      ordering_array([make_function([], sequence_num(1))]),
      reflect_object([
        (reflect_string("visible"), 1, make_function([], sequence_num(1))),
      ]),
    ] {
    let call = sequence_call("toString", [input])
    transfer_reject(call)
    transfer_reject(sequence_call("type", [call]))
  }
}

///|
test "CC8 configuration utilities keep required public names arities and aliases" {
  for
    (name, parameter, input, expected) in [
      ("all", "arr", ordering_array([]), Json::boolean(true)),
      ("any", "arr", ordering_array([]), Json::boolean(false)),
      ("toString", "a", reflect_string("é"), Json::string("é")),
    ] {
    let function = additive_select(sequence_var("std"), name)
    transfer_value(sequence_call("length", [function]), 1)
    for label in [None, Some(parameter)] {
      let args = [(label, input)]
      transfer_value(rounding_apply(name, args), expected)
      transfer_value(
        sequence_local(
          [("f", function)],
          shared_mode_call(sequence_var("f"), args),
        ),
        expected,
      )
    }
    for
      args in [
        [],
        [(None, input), (None, input)],
        [(Some("unknown"), input)],
        [(None, input), (Some(parameter), input)],
      ] {
      transfer_reject(rounding_apply(name, args))
      transfer_reject(
        sequence_local(
          [("f", function)],
          shared_mode_call(sequence_var("f"), args),
        ),
      )
    }
  }
  let function = additive_select(sequence_var("std"), "assertEqual")
  let safe = sequence_num(7)
  transfer_value(sequence_call("length", [function]), 2)
  for
    args in [
      [(None, safe), (None, safe)],
      [(Some("a"), safe), (Some("b"), safe)],
      [(Some("b"), safe), (Some("a"), safe)],
      [(None, safe), (Some("b"), safe)],
    ] {
    transfer_value(rounding_apply("assertEqual", args), true)
    transfer_value(
      sequence_local(
        [("f", function)],
        shared_mode_call(sequence_var("f"), args),
      ),
      true,
    )
  }
  for
    args in [
      [],
      [(None, safe)],
      [(Some("b"), safe)],
      [(None, safe), (None, safe), (None, safe)],
      [(Some("x"), safe), (Some("y"), safe)],
      [(None, safe), (Some("a"), safe), (Some("b"), safe)],
    ] {
    transfer_reject(rounding_apply("assertEqual", args))
    transfer_reject(
      sequence_local(
        [("f", function)],
        shared_mode_call(sequence_var("f"), args),
      ),
    )
  }
}

///|
test "CC9 sole demanded errors propagate while unused utility calls stay lazy" {
  let unread = ordering_error("config-required-outer")
  let required = [
    sequence_call("all", [unread]),
    sequence_call("any", [unread]),
    sequence_call("assertEqual", [unread, sequence_num(0)]),
    sequence_call("assertEqual", [sequence_num(0), unread]),
    sequence_call("toString", [unread]),
  ]
  for call in required {
    transfer_reject(call)
    transfer_reject(sequence_call("type", [call]))
    transfer_value(ordering_unused(call), 42)
    transfer_value(transfer_if(reflect_bool(false), call, sequence_num(42)), 42)
    transfer_value(transfer_if(reflect_bool(true), sequence_num(42), call), 42)
    transfer_value(ordering_binary(reflect_bool(false), "&&", call), false)
    transfer_value(ordering_binary(reflect_bool(true), "||", call), true)
    transfer_value(
      value_head_call(make_function(["unused"], sequence_num(42)), [call]),
      42,
    )
    transfer_value(
      reflect_object([(reflect_string("hidden"), 2, call)]),
      Json::object(Map([])),
    )
  }
  for name in ["all", "any", "assertEqual", "toString"] {
    transfer_value(ordering_unused(rounding_apply(name, [])), 42)
  }
}

///|
test "CC10 repeated utility results preserve original container and String aliases" {
  let original = sequence_var("original")
  let copied = sequence_var("copied")
  for (name, decisive) in [("all", false), ("any", true)] {
    transfer_value(
      sequence_local(
        [
          (
            "original",
            ordering_array([
              reflect_bool(decisive),
              ordering_error("config-alias-tail"),
            ]),
          ),
          ("copied", original),
        ],
        ordering_array([
          sequence_call(name, [original]),
          sequence_call(name, [copied]),
          sequence_call("length", [original]),
          make_index(original, 0),
          make_index(copied, 0),
        ]),
      ),
      Json::array([
        Json::boolean(decisive),
        Json::boolean(decisive),
        Json::number(2),
        Json::boolean(decisive),
        Json::boolean(decisive),
      ]),
    )
  }
  transfer_value(
    sequence_local(
      [
        (
          "original",
          reflect_object([
            (reflect_string("a"), 1, sequence_num(7)),
            (reflect_string("h"), 2, ordering_error("config-alias-hidden")),
          ]),
        ),
        ("copied", original),
      ],
      ordering_array([
        sequence_call("assertEqual", [original, copied]),
        sequence_call("toString", [original]),
        sequence_call("toString", [copied]),
        additive_select(original, "a"),
        additive_select(copied, "a"),
      ]),
    ),
    [true, "{\"a\": 7}", "{\"a\": 7}", 7, 7],
  )
  transfer_value(
    sequence_local(
      [("original", reflect_string(" \té中😀\n")), ("copied", original)],
      ordering_array([
        sequence_call("toString", [original]),
        sequence_call("toString", [copied]),
        original,
        copied,
      ]),
    ),
    [" \té中😀\n", " \té中😀\n", " \té中😀\n", " \té中😀\n"],
  )
}
