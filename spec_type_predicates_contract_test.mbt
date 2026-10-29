// Fixed std.jsonnet 30,32-35 and stdlib.html 143-145: required v, no defaults.
// Literal classification-transfer oracles; ordinary source and handmade AST calls.
// Predicate order below is Array, Boolean, Function, Object, String.

///|
fn type_predicate_results(value : OrderingExpr) -> OrderingExpr {
  ordering_array(
    ["isArray", "isBoolean", "isFunction", "isObject", "isString"].map(name => {
      sequence_call(name, [value])
    }),
  )
}

///|
test "TP1 five predicates classify all seven Value heads by literal truth vectors" {
  let cases : Array[(OrderingExpr, Json)] = [
    (
      ordering_leaf("null", Literal(Json::null())),
      [false, false, false, false, false],
    ),
    (reflect_bool(false), [false, true, false, false, false]),
    (reflect_bool(true), [false, true, false, false, false]),
    (sequence_num(0), [false, false, false, false, false]),
    (
      ordering_leaf("-0.5", Literal(Json::number(-0.5))),
      [false, false, false, false, false],
    ),
    (reflect_string(""), [false, false, false, false, true]),
    (reflect_string("é中😀"), [false, false, false, false, true]),
    (ordering_array([]), [true, false, false, false, false]),
    (ordering_array([sequence_num(7)]), [true, false, false, false, false]),
    (reflect_object([]), [false, false, false, true, false]),
    (
      reflect_object([(reflect_string("中😀"), 1, sequence_num(7))]),
      [false, false, false, true, false],
    ),
    (make_function([], sequence_num(7)), [false, false, true, false, false]),
  ]
  for (value, expected) in cases {
    transfer_value(type_predicate_results(value), expected)
  }
}

///|
test "TP2 classification leaves Array Object and Function payloads unread" {
  let unread = ordering_error("predicate-unread-payload")
  let cases : Array[(OrderingExpr, Json)] = [
    (ordering_array([unread]), [true, false, false, false, false]),
    (
      reflect_object([(reflect_string("\u{0000}😀"), 1, unread)]),
      [false, false, false, true, false],
    ),
    (
      reflect_object([(reflect_string("hidden"), 2, unread)]),
      [false, false, false, true, false],
    ),
    (make_function(["x"], unread), [false, false, true, false, false]),
    (
      value_head_function(ordering_error("predicate-unread-default"), unread),
      [false, false, true, false, false],
    ),
    (
      additive_select(sequence_var("std"), "length"),
      [false, false, true, false, false],
    ),
    (
      additive_select(sequence_var("std"), "isArray"),
      [false, false, true, false, false],
    ),
  ]
  for (value, expected) in cases {
    transfer_value(type_predicate_results(value), expected)
  }
}

///|
test "TP3 each required v accepts positional named and first class alias calls" {
  let cases = [
    ("isArray", ordering_array([])),
    ("isBoolean", reflect_bool(false)),
    ("isFunction", make_function([], sequence_num(7))),
    ("isObject", reflect_object([])),
    ("isString", reflect_string("")),
  ]
  for (name, positive) in cases {
    let function = additive_select(sequence_var("std"), name)
    transfer_value(sequence_call("length", [function]), 1)
    for
      (value, expected) in [
        (positive, Json::boolean(true)),
        (ordering_leaf("null", Literal(Json::null())), Json::boolean(false)),
      ] {
      for label in [None, Some("v")] {
        let args = [(label, value)]
        transfer_value(rounding_apply(name, args), expected)
        transfer_value(
          sequence_local(
            [("predicate", function)],
            shared_mode_call(sequence_var("predicate"), args),
          ),
          expected,
        )
      }
    }
  }
}

///|
test "TP4 required arity names and ordinary duplicate binding reject safe operands" {
  let safe = sequence_num(7)
  let invalid : Array[Array[(String?, OrderingExpr)]] = [
    [],
    [(None, safe), (None, safe)],
    [(Some("x"), safe)],
    [(Some("v"), safe), (Some("unknown"), safe)],
    [(None, safe), (Some("v"), safe)],
  ]
  for name in ["isArray", "isBoolean", "isFunction", "isObject", "isString"] {
    let function = additive_select(sequence_var("std"), name)
    for args in invalid {
      for
        call in [
          rounding_apply(name, args),
          sequence_local(
            [("predicate", function)],
            shared_mode_call(sequence_var("predicate"), args),
          ),
        ] {
        // Runtime is an embedding phase check; every operand itself is valid.
        for handmade in [false, true] {
          try
            ordering_program(call, handmade).evaluate(limits=transfer_limits())
          catch {
            @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
          } noraise {
            _ => fail("type predicate accepted invalid ordinary binding")
          }
        }
      }
    }
    // Reuse ordinary static named uniqueness, independent of call demand.
    let duplicate = rounding_apply(name, [(Some("v"), safe), (Some("v"), safe)])
    for handmade in [false, true] {
      try ordering_program(ordering_unused(duplicate), handmade) catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
      } noraise {
        _ =>
          fail("duplicate predicate named arguments escaped static admission")
      }
    }
  }
}

///|
test "TP5 required outer errors propagate while unused calls and branches stay lazy" {
  for name in ["isArray", "isBoolean", "isFunction", "isObject", "isString"] {
    let marker = "predicate-outer-" + name
    let required = rounding_apply(name, [(Some("v"), ordering_error(marker))])
    // transfer_error checks required failure plus extra Runtime/message diagnostics.
    transfer_error(required, marker)
    transfer_error(
      sequence_local(
        [("predicate", additive_select(sequence_var("std"), name))],
        shared_mode_call(sequence_var("predicate"), [
          (None, ordering_error(marker)),
        ]),
      ),
      marker,
    )
    for
      call in [
        required,
        rounding_apply(name, []),
        rounding_apply(name, [(Some("unknown"), sequence_num(7))]),
      ] {
      transfer_value(ordering_unused(call), 42)
      transfer_value(
        transfer_if(reflect_bool(false), call, sequence_num(42)),
        42,
      )
      transfer_value(
        transfer_if(reflect_bool(true), sequence_num(42), call),
        42,
      )
      transfer_value(ordering_binary(reflect_bool(false), "&&", call), false)
      transfer_value(ordering_binary(reflect_bool(true), "||", call), true)
    }
  }
}

///|
test "TP6 classification preserves original Array String Function and inherited Object aliases" {
  let cases : Array[(OrderingExpr, Json)] = [
    (
      ordering_array([reflect_string("é"), sequence_num(7)]),
      [
        [true, false, false, false, false],
        [true, false, false, false, false],
        ["é", 7],
        ["é", 7],
      ],
    ),
    (
      reflect_string("A\u{0000}e\u{0301}😀"),
      [
        [false, false, false, false, true],
        [false, false, false, false, true],
        "A\u{0000}e\u{0301}😀",
        "A\u{0000}e\u{0301}😀",
      ],
    ),
  ]
  for (value, expected) in cases {
    transfer_value(
      sequence_local(
        [("original", value), ("alias", sequence_var("original"))],
        ordering_array([
          type_predicate_results(sequence_var("original")),
          type_predicate_results(sequence_var("alias")),
          sequence_var("original"),
          sequence_var("alias"),
        ]),
      ),
      expected,
    )
  }
  let original = sequence_var("original")
  let aliased_expr = sequence_var("alias")
  transfer_value(
    sequence_local(
      [
        (
          "original",
          make_function(
            ["x"],
            ordering_binary(sequence_var("x"), "+", sequence_num(1)),
          ),
        ),
        ("alias", original),
      ],
      ordering_array([
        type_predicate_results(original),
        type_predicate_results(aliased_expr),
        value_head_call(original, [sequence_num(7)]),
        value_head_call(aliased_expr, [sequence_num(7)]),
      ]),
    ),
    [
      [false, false, true, false, false],
      [false, false, true, false, false],
      8,
      8,
    ],
  )
  let base = reflect_object([
    (reflect_string("中"), 1, sequence_num(1)),
    (reflect_string("hidden"), 2, ordering_error("predicate-inherited-hidden")),
  ])
  transfer_value(
    sequence_local(
      [
        ("base", base),
        (
          "original",
          ordering_binary(
            sequence_var("base"),
            "+",
            reflect_object([(reflect_string("中"), 1, sequence_num(2))]),
          ),
        ),
        ("alias", original),
      ],
      ordering_array([
        type_predicate_results(original),
        type_predicate_results(aliased_expr),
        additive_select(sequence_var("base"), "中"),
        additive_select(original, "中"),
        additive_select(aliased_expr, "中"),
      ]),
    ),
    [
      [false, false, false, true, false],
      [false, false, false, true, false],
      1,
      2,
      2,
    ],
  )
}
