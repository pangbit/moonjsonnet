// Independent fixed mathematical oracle: SPEC-MATH-ROUNDING-2026-10-23.md.

///|
fn rounding_apply(
  name : String,
  args : Array[(String?, OrderingExpr)],
) -> OrderingExpr {
  {
    source: "std." +
    name +
    "(" +
    args
    .map(arg => {
      (match arg.0 {
        Some(label) => label + "="
        None => ""
      }) +
      "(" +
      arg.1.source +
      ")"
    })
    .join(",") +
    ")",
    tree: ordering_ast(
      Call(
        ordering_ast(Index(sequence_var("std").tree, reflect_string(name).tree)),
        args.map(arg => (arg.0, arg.1.tree)),
        false,
      ),
    ),
  }
}

///|
test "floor and ceil use exact finite mathematical bounds without integer narrowing" {
  let cases : Array[(String, Double, Double, Double)] = [
    ("0", 0.0, 0.0, 0.0),
    ("-0", -0.0, 0.0, 0.0),
    ("1", 1.0, 1.0, 1.0),
    ("-1", -1.0, -1.0, -1.0),
    ("0.5", 0.5, 0.0, 1.0),
    ("-0.5", -0.5, -1.0, 0.0),
    ("2.5", 2.5, 2.0, 3.0),
    ("-2.5", -2.5, -3.0, -2.0),
    ("5e-324", 5.0e-324, 0.0, 1.0),
    ("-5e-324", -5.0e-324, -1.0, 0.0),
    ("0.9999999999999999", 0.9999999999999999, 0.0, 1.0),
    ("1.0000000000000002", 1.0000000000000002, 1.0, 2.0),
    ("-0.9999999999999999", -0.9999999999999999, -1.0, 0.0),
    ("-1.0000000000000002", -1.0000000000000002, -2.0, -1.0),
    (
      "4503599627370495.5", 4503599627370495.5, 4503599627370495.0, 4503599627370496.0,
    ),
    (
      "-4503599627370495.5", -4503599627370495.5, -4503599627370496.0, -4503599627370495.0,
    ),
    (
      "9007199254740991", 9007199254740991.0, 9007199254740991.0, 9007199254740991.0,
    ),
    (
      "9007199254740992", 9007199254740992.0, 9007199254740992.0, 9007199254740992.0,
    ),
    (
      "9007199254740994", 9007199254740994.0, 9007199254740994.0, 9007199254740994.0,
    ),
    (
      "-9007199254740994", -9007199254740994.0, -9007199254740994.0, -9007199254740994.0,
    ),
    (
      "1.7976931348623157e308", 1.7976931348623157e308, 1.7976931348623157e308, 1.7976931348623157e308,
    ),
    (
      "-1.7976931348623157e308", -1.7976931348623157e308, -1.7976931348623157e308,
      -1.7976931348623157e308,
    ),
  ]
  for (source, number, floor_result, ceil_result) in cases {
    let operand = ordering_leaf(source, Literal(Json::number(number)))
    for (name, expected) in [("floor", floor_result), ("ceil", ceil_result)] {
      for named in [false, true] {
        let label = if named { Some("x") } else { None }
        sequence_value(
          rounding_apply(name, [(label, operand)]),
          Json::number(expected),
        )
      }
    }
  }
}

///|
test "floor and ceil reject nonnumber heads and preserve required child errors" {
  let unread = ordering_error("rounding-unread-payload")
  let values = [
    ordering_leaf("null", Literal(Json::null())),
    reflect_bool(true),
    reflect_string("1.25"),
    ordering_array([unread]),
    reflect_object([(reflect_string("payload"), 1, unread)]),
    value_head_function(ordering_error("rounding-unread-default"), unread),
  ]
  for name in ["floor", "ceil"] {
    for value in values {
      for named in [false, true] {
        sequence_failure(
          rounding_apply(name, [(if named { Some("x") } else { None }, value)]),
          @moonjsonnet.Type,
          None,
        )
      }
    }
    sequence_failure(
      rounding_apply(name, [(None, ordering_error("rounding-required"))]),
      @moonjsonnet.Runtime,
      Some("rounding-required"),
    )
    let overflow = sequence_call("pow", [
      ordering_leaf("1e308", Literal(Json::number(1.0e308))),
      sequence_num(2),
    ])
    sequence_failure(
      rounding_apply(name, [(None, overflow)]),
      @moonjsonnet.Runtime,
      None,
    )
  }
}

///|
test "rounding call bindings and unselected operands retain admission and lazy boundaries" {
  for name in ["floor", "ceil"] {
    let left = rewrite_gate(reflect_string("L"), sequence_num(7))
    let right = rewrite_gate(reflect_string("R"), sequence_num(8))
    let invalid : Array[Array[(String?, OrderingExpr)]] = [
      [],
      [(None, left), (None, right)],
      [(Some("unknown"), left)],
      [(None, left), (Some("x"), right)],
    ]
    for args in invalid {
      let expression = rounding_apply(name, args)
      for unused in [false, true] {
        let value = additive_probe_scope(
          if unused {
            ordering_unused(expression)
          } else {
            expression
          },
        )
        for handmade in [false, true] {
          let counts : Map[String, Int32] = Map([])
          let program = ordering_program(value, handmade)
          assert_eq(counts.length(), 0)
          if unused {
            assert_eq(
              program.evaluate(
                native_functions=rewrite_natives(counts),
                limits=sequence_limits(),
              ),
              42,
            )
          } else {
            try
              program.evaluate(
                native_functions=rewrite_natives(counts),
                limits=sequence_limits(),
              )
            catch {
              @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
            } noraise {
              _ => fail("invalid rounding signature binding succeeded")
            }
          }
          assert_eq(counts.length(), 0)
        }
      }
    }
    let required = rounding_apply(name, [
      (None, ordering_error("rounding-skipped")),
    ])
    let skipped : OrderingExpr = {
      source: "if false then (" + required.source + ") else 42",
      tree: ordering_ast(
        If(reflect_bool(false).tree, required.tree, sequence_num(42).tree),
      ),
    }
    let hidden = reflect_object([
      (reflect_string("hidden"), 2, required),
      (reflect_string("ok"), 1, sequence_num(42)),
    ])
    sequence_value(skipped, 42)
    sequence_value(ordering_binary(reflect_bool(false), "&&", required), false)
    sequence_value(ordering_binary(reflect_bool(true), "||", required), true)
    sequence_value(additive_select(hidden, "ok"), 42)
    pair_reject(
      rounding_apply(name, [(None, sequence_var("rounding_missing"))]),
    )
  }
}
