// Fixed std.jsonnet 1799/1762, preserved in stdlib_source.mbt.
// Literal ordinary-source and handmade-AST expectations for trim and isEmpty.
// Child judgments: stripChars, length and ordinary calls; resolvePath is deferred.

///|
fn string_utilities_values(cases : Array[(OrderingExpr, Json)]) -> Unit raise {
  let failures : Array[String] = []
  for (call, expected) in cases {
    for handmade in [false, true] {
      let label = call.source + " handmade=" + handmade.to_string()
      try {
        let actual = ordering_program(call, handmade).evaluate(
          limits=transfer_limits(),
        )
        if actual != expected {
          failures.push(
            label +
            " actual=" +
            actual.stringify() +
            " expected=" +
            expected.stringify(),
          )
        }
      } catch {
        @moonjsonnet.Error(d) =>
          failures.push(
            label + " error=" + d.message + " expected=" + expected.stringify(),
          )
      }
    }
  }
  if !failures.is_empty() {
    fail(failures.join("; "))
  }
}

///|
test "SU1 trim removes exactly the seven fixed endpoint characters" {
  let cases : Array[(String, String)] = [
    (" x ", "x"),
    ("\tx\t", "x"),
    ("\nx\n", "x"),
    ("\u{000c}x\u{000c}", "x"),
    ("\rx\r", "x"),
    ("\u{0085}x\u{0085}", "x"),
    ("\u{00a0}x\u{00a0}", "x"),
    (
      " \t\n\u{000c}\r\u{0085}\u{00a0}é中😀\u{00a0}\u{0085}\r\u{000c}\n\t ",
      "é中😀",
    ),
    (" \t\n\u{000c}\r\u{0085}\u{00a0}", ""),
    ("", ""),
    ("x y\tz\nq", "x y\tz\nq"),
    (
      "é\u{000c}中\r😀\u{0085}x\u{00a0}y", "é\u{000c}中\r😀\u{0085}x\u{00a0}y",
    ),
    (" \u{0000}x\u{0000} ", "\u{0000}x\u{0000}"),
    ("\u{000b}x\u{000b}", "\u{000b}x\u{000b}"),
    ("\u{1680}x\u{1680}", "\u{1680}x\u{1680}"),
    ("\u{2000}x\u{2000}", "\u{2000}x\u{2000}"),
    ("\u{2001}x\u{2001}", "\u{2001}x\u{2001}"),
    ("\u{2002}x\u{2002}", "\u{2002}x\u{2002}"),
    ("\u{2003}x\u{2003}", "\u{2003}x\u{2003}"),
    ("\u{2004}x\u{2004}", "\u{2004}x\u{2004}"),
    ("\u{2005}x\u{2005}", "\u{2005}x\u{2005}"),
    ("\u{2006}x\u{2006}", "\u{2006}x\u{2006}"),
    ("\u{2007}x\u{2007}", "\u{2007}x\u{2007}"),
    ("\u{2008}x\u{2008}", "\u{2008}x\u{2008}"),
    ("\u{2009}x\u{2009}", "\u{2009}x\u{2009}"),
    ("\u{200a}x\u{200a}", "\u{200a}x\u{200a}"),
    ("\u{2028}x\u{2028}", "\u{2028}x\u{2028}"),
    ("\u{2029}x\u{2029}", "\u{2029}x\u{2029}"),
    ("\u{3000}x\u{3000}", "\u{3000}x\u{3000}"),
    ("\u{202f}x\u{202f}", "\u{202f}x\u{202f}"),
    ("\u{205f}x\u{205f}", "\u{205f}x\u{205f}"),
    ("\u{200b}x\u{200b}", "\u{200b}x\u{200b}"),
    (" \u{2003}x\u{2003} ", "\u{2003}x\u{2003}"),
    (" \u{2003} x \t", "\u{2003} x"),
  ]
  string_utilities_values(
    cases.map(c => {
      (sequence_call("trim", [reflect_string(c.0)]), Json::string(c.1))
    }),
  )
}

///|
test "SU2 isEmpty follows supported length heads without demanding payloads" {
  let unread = ordering_error("utilities-unread-payload")
  let cases : Array[(OrderingExpr, Bool)] = [
    (reflect_string(""), true),
    (reflect_string(" "), false),
    (reflect_string("\u{0000}"), false),
    (reflect_string("é中😀"), false),
    (ordering_array([]), true),
    (ordering_array([sequence_num(0)]), false),
    (ordering_array([unread]), false),
    (reflect_object([]), true),
    (reflect_object([(reflect_string("中😀"), 1, unread)]), false),
    (reflect_object([(reflect_string("hidden"), 2, unread)]), true),
    (make_function([], unread), true),
    (make_function(["x"], unread), false),
    (value_head_function(unread, unread), false),
    (additive_select(sequence_var("std"), "length"), false),
  ]
  string_utilities_values(
    cases.map(c => (sequence_call("isEmpty", [c.0]), Json::boolean(c.1))),
  )
}

///|
test "SU3 utilities retain required names arities aliases and safe binding rejection" {
  for
    (name, input, expected) in [
      ("trim", " x ", Json::string("x")),
      ("isEmpty", "", Json::boolean(true)),
    ] {
    let function = additive_select(sequence_var("std"), name)
    transfer_value(sequence_call("length", [function]), 1)
    for label in [None, Some("str")] {
      let args = [(label, reflect_string(input))]
      transfer_value(rounding_apply(name, args), expected)
      transfer_value(
        sequence_local(
          [("f", function)],
          shared_mode_call(sequence_var("f"), args),
        ),
        expected,
      )
    }
    let safe = reflect_string("x")
    let invalid : Array[Array[(String?, OrderingExpr)]] = [
      [],
      [(None, safe), (None, safe)],
      [(Some("x"), safe)],
      [(Some("str"), safe), (Some("unknown"), safe)],
      [(None, safe), (Some("str"), safe)],
    ]
    for args in invalid {
      transfer_reject(rounding_apply(name, args))
      transfer_reject(
        sequence_local(
          [("f", function)],
          shared_mode_call(sequence_var("f"), args),
        ),
      )
    }
  }
}

///|
test "SU4 utilities reject only the required incompatible argument heads" {
  let unread = ordering_error("utilities-rejected-payload")
  let nonstrings = [
    ordering_leaf("null", Literal(Json::null())),
    reflect_bool(false),
    sequence_num(0),
    ordering_array([]),
    ordering_array([unread]),
    reflect_object([]),
    reflect_object([(reflect_string("x"), 1, unread)]),
    value_head_function(unread, unread),
  ]
  for input in nonstrings {
    transfer_reject(sequence_call("trim", [input]))
  }
  // Rejection alone does not prove a rejected payload was skipped or set its diagnostic kind.
  for
    input in [
      ordering_leaf("null", Literal(Json::null())),
      reflect_bool(false),
      reflect_bool(true),
      sequence_num(0),
    ] {
    transfer_reject(sequence_call("isEmpty", [input]))
  }
}

///|
test "SU5 isolated required errors propagate while unused utility calls remain lazy" {
  let required = [
    sequence_call("trim", [ordering_error("utilities-trim-outer")]),
    sequence_call("isEmpty", [ordering_error("utilities-empty-outer")]),
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
  for name in ["trim", "isEmpty"] {
    transfer_value(ordering_unused(rounding_apply(name, [])), 42)
  }
}

///|
test "SU6 utility results preserve original String Array Object and Function aliases" {
  let original = sequence_var("original")
  let aliased_expr = sequence_var("copied")
  transfer_value(
    sequence_local(
      [
        ("original", reflect_string(" \té中😀\u{00a0}")),
        ("copied", original),
      ],
      ordering_array([
        sequence_call("trim", [original]),
        sequence_call("trim", [aliased_expr]),
        original,
        aliased_expr,
      ]),
    ),
    ["é中😀", "é中😀", " \té中😀\u{00a0}", " \té中😀\u{00a0}"],
  )
  transfer_value(
    sequence_local(
      [
        (
          "original",
          ordering_array([
            reflect_string("é"),
            ordering_error("utilities-alias-tail"),
          ]),
        ),
        ("copied", original),
      ],
      ordering_array([
        sequence_call("isEmpty", [original]),
        sequence_call("isEmpty", [aliased_expr]),
        sequence_call("length", [original]),
        make_index(original, 0),
        make_index(aliased_expr, 0),
      ]),
    ),
    [false, false, 2, "é", "é"],
  )
  transfer_value(
    sequence_local(
      [
        (
          "original",
          reflect_object([
            (reflect_string("x"), 1, sequence_num(7)),
            (
              reflect_string("hidden"),
              2,
              ordering_error("utilities-alias-hidden"),
            ),
          ]),
        ),
        ("copied", original),
      ],
      ordering_array([
        sequence_call("isEmpty", [original]),
        sequence_call("isEmpty", [aliased_expr]),
        additive_select(original, "x"),
        additive_select(aliased_expr, "x"),
      ]),
    ),
    [false, false, 7, 7],
  )
  transfer_value(
    sequence_local(
      [("original", make_function([], sequence_num(7))), ("copied", original)],
      ordering_array([
        sequence_call("isEmpty", [original]),
        sequence_call("isEmpty", [aliased_expr]),
        value_head_call(original, []),
        value_head_call(aliased_expr, []),
      ]),
    ),
    [true, true, 7, 7],
  )
}
