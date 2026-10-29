// Fixed std.jsonnet 1582: equals(a, b), two required parameters, no defaults.
// Only public call binding is adjudicated; equality and its demand are controls.
// Neutral builders/evaluation helpers use independent source and handmade AST.

///|
test "EN1 equals accepts every public positional named mixed and alias call form" {
  let cases : Array[(Array[(String?, OrderingExpr)], Json)] = [
    ([(None, sequence_num(7)), (None, sequence_num(7))], true),
    ([(Some("a"), sequence_num(7)), (Some("b"), sequence_num(7))], true),
    ([(Some("b"), sequence_num(8)), (Some("a"), sequence_num(7))], false),
    ([(None, sequence_num(7)), (Some("b"), sequence_num(8))], false),
  ]
  let function = additive_select(sequence_var("std"), "equals")
  for (args, expected) in cases {
    transfer_value(rounding_apply("equals", args), expected)
    transfer_value(
      sequence_local(
        [("f", function)],
        shared_mode_call(sequence_var("f"), args),
      ),
      expected,
    )
  }
}

///|
test "EN2 equals retains arity no defaults and ordinary invalid binding rules" {
  transfer_value(
    sequence_call("length", [additive_select(sequence_var("std"), "equals")]),
    2,
  )
  let safe = sequence_num(1)
  let invalid : Array[Array[(String?, OrderingExpr)]] = [
    [],
    [(None, safe)],
    [(Some("a"), safe)],
    [(Some("b"), safe)],
    [(None, safe), (None, safe), (None, safe)],
    [(None, safe), (None, safe), (Some("unknown"), safe)],
    [(None, safe), (Some("a"), safe), (Some("b"), safe)],
  ]
  for args in invalid {
    // Runtime is an existing embedding phase check; operands cannot fail equality.
    for handmade in [false, true] {
      try
        ordering_program(rounding_apply("equals", args), handmade).evaluate(
          limits=transfer_limits(),
        )
      catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
      } noraise {
        _ => fail("equals accepted an invalid ordinary binding")
      }
    }
  }
  // Reuse the established named-uniqueness static rule, including unused calls.
  let duplicate = rounding_apply("equals", [
    (Some("a"), safe),
    (Some("b"), safe),
    (Some("a"), safe),
  ])
  for handmade in [false, true] {
    try ordering_program(ordering_unused(duplicate), handmade) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
    } noraise {
      _ => fail("duplicate equals named arguments escaped static admission")
    }
  }
}

///|
test "EN3 equals rejects legacy x y names as unknown public parameters" {
  let safe = sequence_num(1)
  let legacy : Array[Array[(String?, OrderingExpr)]] = [
    [(Some("x"), safe), (Some("y"), safe)],
    [(Some("x"), safe), (Some("b"), safe)],
    [(Some("a"), safe), (Some("y"), safe)],
    [(None, safe), (Some("y"), safe)],
  ]
  let function = additive_select(sequence_var("std"), "equals")
  for args in legacy {
    transfer_reject(rounding_apply("equals", args))
    transfer_reject(
      sequence_local(
        [("f", function)],
        shared_mode_call(sequence_var("f"), args),
      ),
    )
  }
}

///|
test "EN4 equals preserves isolated required head failures through ordinary aliases" {
  let function = additive_select(sequence_var("std"), "equals")
  for
    (left, right, marker) in [
      (ordering_error("equals-left"), sequence_num(1), "equals-left"),
      (sequence_num(1), ordering_error("equals-right"), "equals-right"),
    ] {
    transfer_error(sequence_call("equals", [left, right]), marker)
    transfer_error(
      sequence_local(
        [("f", function)],
        shared_mode_call(sequence_var("f"), [(None, left), (None, right)]),
      ),
      marker,
    )
  }
}

///|
test "EN5 unused equals calls defer runtime binding and argument errors" {
  let calls = [
    rounding_apply("equals", [
      (Some("a"), ordering_error("unused-left")),
      (Some("b"), sequence_num(1)),
    ]),
    rounding_apply("equals", [
      (Some("b"), ordering_error("unused-right")),
      (Some("a"), sequence_num(1)),
    ]),
    rounding_apply("equals", [
      (Some("x"), sequence_num(1)),
      (Some("y"), sequence_num(1)),
    ]),
    sequence_call("equals", [sequence_num(1)]),
  ]
  for call in calls {
    transfer_value(ordering_unused(call), 42)
    transfer_value(transfer_if(reflect_bool(false), call, sequence_num(42)), 42)
  }
}

///|
test "EN6 equals binding work preserves existing nested comparison laziness" {
  let bad = ordering_error("unused-equality-tail")
  transfer_value(
    sequence_call("equals", [
      ordering_array([sequence_num(1), bad]),
      ordering_array([sequence_num(2), bad]),
    ]),
    false,
  )
  transfer_value(
    sequence_call("equals", [ordering_array([bad]), ordering_array([])]),
    false,
  )
  transfer_value(
    sequence_call("equals", [
      reflect_object([(reflect_string("a"), 1, bad)]),
      reflect_object([(reflect_string("b"), 1, bad)]),
    ]),
    false,
  )
  transfer_value(
    sequence_call("equals", [
      ordering_array([
        reflect_object([
          (reflect_string("a"), 1, sequence_num(2)),
          (reflect_string("hidden"), 2, bad),
        ]),
      ]),
      ordering_array([
        reflect_object([(reflect_string("a"), 1, sequence_num(2))]),
      ]),
    ]),
    true,
  )
}
