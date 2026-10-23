// Fixed independent sign table: SPEC-RELATIONAL-SIGN-2026-10-23.md.
// All expected booleans are literals, not results from another comparator.

///|
fn relational_values(
  left : OrderingExpr,
  right : OrderingExpr,
  expected : Json,
) -> Unit raise {
  sequence_value(
    ordering_array([
      ordering_binary(left, "<", right),
      ordering_binary(left, "<=", right),
      ordering_binary(left, ">=", right),
    ]),
    expected,
  )
}

///|
test "relational sign table covers direct finite numbers and codepoint strings" {
  let negative_zero = ordering_leaf("-0", Unary("-", sequence_num(0).tree))
  for
    (left, right, expected) in [
      (sequence_num(-2), sequence_num(-1), Json::array([true, true, false])),
      (sequence_num(-1), sequence_num(-1), Json::array([false, true, true])),
      (sequence_num(1), sequence_num(0), Json::array([false, false, true])),
      (negative_zero, sequence_num(0), Json::array([false, true, true])),
    ] {
    relational_values(left, right, expected)
  }
  for
    (left, right, expected) in [
      ("", "", Json::array([false, true, true])),
      ("", "a", Json::array([true, true, false])),
      ("a", "", Json::array([false, false, true])),
      ("a", "aa", Json::array([true, true, false])),
      ("aa", "a", Json::array([false, false, true])),
      ("\uE000", "😀", Json::array([true, true, false])),
      ("😀", "\uE000", Json::array([false, false, true])),
      ("é", "e\u0301", Json::array([false, false, true])),
      ("e\u0301", "é", Json::array([true, true, false])),
      ("\u0000", "\u0000a", Json::array([true, true, false])),
    ] {
    relational_values(reflect_string(left), reflect_string(right), expected)
  }
}

///|
test "greater equal consumes array comparison signs with precise required demand" {
  let empty = ordering_array([])
  let one = sequence_num(1)
  let two = sequence_num(2)
  let bad = ordering_error("relation-unread-tail")
  let equal = ordering_array([ordering_array([one]), two])
  for
    (left, right, expected) in [
      (empty, ordering_array([bad]), false),
      (ordering_array([bad]), empty, true),
      (
        ordering_array([ordering_array([two, bad]), bad]),
        ordering_array([ordering_array([one, bad]), bad]),
        true,
      ),
      (equal, equal, true),
    ] {
    sequence_value(ordering_binary(left, ">=", right), Json::boolean(expected))
  }
  for
    (left, right, marker) in [
      (ordering_error("relation-left-head"), empty, "relation-left-head"),
      (empty, ordering_error("relation-right-head"), "relation-right-head"),
      (
        ordering_array([one, ordering_error("relation-required-element")]),
        ordering_array([one, two]),
        "relation-required-element",
      ),
    ] {
    sequence_failure(
      ordering_binary(left, ">=", right),
      @moonjsonnet.Runtime,
      Some(marker),
    )
  }
}

///|
test "relational domains reject unsupported heads without reading nested payloads" {
  let bad = ordering_error("relation-unread-value")
  let obj = reflect_object([(reflect_string("x"), 1, bad)])
  let closure = ordering_leaf(
    "function() error 'relation-unread-value'",
    Func([], bad.tree),
  )
  for op in ["<", "<=", ">="] {
    for
      value in [
        ordering_leaf("null", Literal(Json::null())),
        ordering_leaf("true", Literal(true)),
        obj,
        closure,
      ] {
      sequence_failure(
        ordering_binary(value, op, value),
        @moonjsonnet.Type,
        None,
      )
    }
    for
      (left, right) in [
        (sequence_num(1), reflect_string("1")),
        (reflect_string("1"), sequence_num(1)),
      ] {
      sequence_failure(
        ordering_binary(left, op, right),
        @moonjsonnet.Type,
        None,
      )
    }
  }
  let poisoned = ordering_array([bad])
  for
    (left, right) in [
      (poisoned, sequence_num(1)),
      (sequence_num(1), poisoned),
      (
        ordering_array([ordering_leaf("true", Literal(true))]),
        ordering_array([ordering_leaf("false", Literal(false))]),
      ),
    ] {
    sequence_failure(
      ordering_binary(left, ">=", right),
      @moonjsonnet.Type,
      None,
    )
  }
}
