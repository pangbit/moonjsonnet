// Fixed independent integer domain/oracle: SPEC-BOUNDED-SHIFTS-2026-10-23.md.

///|
fn shift_number(source : String, value : Double) -> OrderingExpr {
  ordering_leaf(source, Literal(Json::number(value)))
}

///|
test "bounded shifts use exact integer counts modulo 64 without host narrowing" {
  // count spelling/value, small left input, expected left/right results.
  // Right input is exactly 2^62; every expected result is literal.
  let cases : Array[(String, Double, Double, Double, Double)] = [
    ("0", 0.0, 3.0, 3.0, 4611686018427387904.0),
    ("-0", -0.0, 3.0, 3.0, 4611686018427387904.0),
    ("1", 1.0, 3.0, 6.0, 2305843009213693952.0),
    ("31", 31.0, 3.0, 6442450944.0, 2147483648.0),
    ("32", 32.0, 3.0, 12884901888.0, 1073741824.0),
    ("61", 61.0, 3.0, 6917529027641081856.0, 2.0),
    ("62", 62.0, 1.0, 4611686018427387904.0, 1.0),
    ("63", 63.0, 0.0, 0.0, 0.0),
    ("64", 64.0, 3.0, 3.0, 4611686018427387904.0),
    ("65", 65.0, 3.0, 6.0, 2305843009213693952.0),
    ("126", 126.0, 1.0, 4611686018427387904.0, 1.0),
    ("127", 127.0, 0.0, 0.0, 0.0),
    ("128", 128.0, 3.0, 3.0, 4611686018427387904.0),
    ("129", 129.0, 3.0, 6.0, 2305843009213693952.0),
    ("4294967297", 4294967297.0, 3.0, 6.0, 2305843009213693952.0),
    ("9007199254740991", 9007199254740991.0, 0.0, 0.0, 0.0),
    ("9007199254740994", 9007199254740994.0, 3.0, 12.0, 1152921504606846976.0),
    (
      "9223372036854774784", 9223372036854774784.0, 3.0, 3.0, 4611686018427387904.0,
    ),
  ]
  let right_input = shift_number("4611686018427387904", 4611686018427387904.0)
  for (source, count_value, left_value, expected_left, expected_right) in cases {
    let count = shift_number(source, count_value)
    let left_source = if left_value == 0.0 {
      "0"
    } else if left_value == 1.0 {
      "1"
    } else {
      "3"
    }
    let left_input = shift_number(left_source, left_value)
    sequence_value(
      ordering_binary(left_input, "<<", count),
      Json::number(expected_left),
    )
    sequence_value(
      ordering_binary(right_input, ">>", count),
      Json::number(expected_right),
    )
  }
}

///|
test "negative integral shift counts reject before modulo can hide their sign" {
  let counts : Array[(String, Double)] = [
    ("-1", -1.0),
    ("-63", -63.0),
    ("-64", -64.0),
    ("-65", -65.0),
    ("-128", -128.0),
    ("-4294967297", -4294967297.0),
    ("-9007199254740994", -9007199254740994.0),
    ("-9223372036854775808", -9223372036854775808.0),
  ]
  for op in ["<<", ">>"] {
    for (source, number) in counts {
      for left in [sequence_num(0), sequence_num(3)] {
        sequence_failure(
          ordering_binary(left, op, shift_number(source, number)),
          @moonjsonnet.Runtime,
          None,
        )
      }
    }
  }
}

///|
test "shift type and required operand errors remain separate from skipped execution and source syntax" {
  let unread = ordering_error("shift-unread-payload")
  let wrong_types = [
    ordering_leaf("null", Literal(Json::null())),
    reflect_bool(true),
    reflect_string("1"),
    ordering_array([unread]),
    reflect_object([(reflect_string("payload"), 1, unread)]),
    value_head_function(ordering_error("shift-unread-default"), unread),
  ]
  for op in ["<<", ">>"] {
    for wrong in wrong_types {
      sequence_failure(
        ordering_binary(wrong, op, sequence_num(1)),
        @moonjsonnet.Type,
        None,
      )
      sequence_failure(
        ordering_binary(sequence_num(0), op, wrong),
        @moonjsonnet.Type,
        None,
      )
    }
    sequence_failure(
      ordering_binary(
        ordering_error("shift-left-required"),
        op,
        sequence_num(1),
      ),
      @moonjsonnet.Runtime,
      Some("shift-left-required"),
    )
    let needed_count = ordering_binary(
      sequence_num(0),
      op,
      ordering_error("shift-count-required"),
    )
    sequence_failure(
      needed_count,
      @moonjsonnet.Runtime,
      Some("shift-count-required"),
    )
    let negative = ordering_binary(sequence_num(0), op, sequence_num(-64))
    for deferred in [needed_count, negative] {
      let skipped : OrderingExpr = {
        source: "if false then (" + deferred.source + ") else 42",
        tree: ordering_ast(
          If(reflect_bool(false).tree, deferred.tree, sequence_num(42).tree),
        ),
      }
      let hidden = reflect_object([
        (reflect_string("hidden"), 2, deferred),
        (reflect_string("ok"), 1, sequence_num(42)),
      ])
      sequence_value(skipped, 42)
      sequence_value(
        ordering_binary(reflect_bool(false), "&&", deferred),
        false,
      )
      sequence_value(ordering_binary(reflect_bool(true), "||", deferred), true)
      sequence_value(additive_select(hidden, "ok"), 42)
    }
    for malformed in [op + "1", "1" + op] {
      names_syntax(malformed)
    }
  }
}
