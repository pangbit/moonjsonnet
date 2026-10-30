// Static candidate only: not formatted, compiled or executed.
// Fixed bbb38f std.jsonnet 1428-1430: length(arr), then lazy makeArray indexing.
// Embedded source minus its extra final LF matches fixed SHA-256
// e76dd6b8e51a2ca041b292dadea9c5521aeea5781b0ffe7c2c683865e7e45351.
// Literal source/handmade-AST expectations. Documentation says "Reverses an
// array" without an explicit other-kind rejection; the fixed body defines behavior.
// Documentation arrs versus source/current arr remains unresolved. Assertions,
// inherited std receivers, cycles and exact resource thresholds are excluded.

///|
fn reverse_contract_call(
  value : OrderingExpr,
  through_alias~ : Bool = false,
  strict~ : Bool = false,
) -> OrderingExpr {
  let function = additive_select(sequence_var("std"), "reverse")
  if through_alias {
    sequence_local(
      [("saved_reverse", function)],
      shared_mode_call(sequence_var("saved_reverse"), [(None, value)], strict~),
    )
  } else {
    shared_mode_call(function, [(None, value)], strict~)
  }
}

///|
test "RV1 reverse returns literal Unicode codepoint Arrays for Strings" {
  let cases : Array[(String, Json)] = [
    ("", []),
    ("a", ["a"]),
    ("ab", ["b", "a"]),
    ("é😀中", ["中", "😀", "é"]),
    ("e\u{0301}\u{0000}", ["\u{0000}", "\u{0301}", "e"]),
  ]
  for (input, expected) in cases {
    for through_alias in [false, true] {
      transfer_value(
        reverse_contract_call(reflect_string(input), through_alias~),
        expected,
      )
    }
  }
  let reversed = reverse_contract_call(reflect_string("你😀"))
  transfer_value(sequence_call("type", [reversed]), "array")
  transfer_value(sequence_call("length", [reversed]), 2)
  transfer_value(make_index(reversed, 0), "😀")
}

///|
test "RV2 reverse preserves Array order aliases and unselected payloads" {
  transfer_value(reverse_contract_call(ordering_array([])), [])
  transfer_value(
    reverse_contract_call(
      ordering_array([
        sequence_num(1),
        sequence_num(2),
        sequence_num(1),
        sequence_num(3),
      ]),
    ),
    [3, 1, 2, 1],
  )
  let original = ordering_array([
    sequence_num(1),
    sequence_num(2),
    sequence_num(3),
  ])
  transfer_value(
    sequence_local(
      [
        ("original", original),
        ("reversed", reverse_contract_call(sequence_var("original"))),
      ],
      ordering_array([
        sequence_var("reversed"),
        sequence_var("original"),
        reverse_contract_call(sequence_var("reversed")),
      ]),
    ),
    [[3, 2, 1], [1, 2, 3], [1, 2, 3]],
  )
  let lazy_result = reverse_contract_call(
    ordering_array([ordering_error("reverse-selected-payload"), sequence_num(7)]),
  )
  transfer_value(sequence_call("length", [lazy_result]), 2)
  transfer_value(make_index(lazy_result, 0), 7)
  // Sole marker verifies the selected payload caused the embedding error;
  // no independent diagnostic priority is specified.
  sequence_failure(
    make_index(lazy_result, 1),
    @moonjsonnet.Runtime,
    Some("reverse-selected-payload"),
  )
}

///|
test "RV3 reverse transfers Object and Function lengths before indexing" {
  let unread = ordering_error("reverse-structural-payload-unused")
  for
    input in [
      reflect_object([]),
      reflect_object([(reflect_string("hidden"), 2, unread)]),
      make_function([], unread),
    ] {
    transfer_value(reverse_contract_call(input), [])
  }
  let cases : Array[(OrderingExpr, Int32)] = [
    (reflect_object([(reflect_string("a"), 1, unread)]), 1),
    (
      reflect_object([
        (reflect_string("a"), 1, unread),
        (reflect_string("b"), 1, unread),
      ]),
      2,
    ),
    (make_function(["x", "y"], unread), 2),
    (fscope_function([("x", Some(unread))], unread), 1),
    (additive_select(sequence_var("std"), "length"), 1),
  ]
  for (input, size) in cases {
    let reversed = reverse_contract_call(input)
    transfer_value(sequence_call("type", [reversed]), "array")
    transfer_value(
      sequence_call("length", [reversed]),
      Json::number(size.to_double()),
    )
    // Numeric indexing of these heads is invalid only when an element is used.
    transfer_reject(make_index(reversed, 0))
  }
}

///|
test "RV4 reverse rejects unsupported length heads and demands its input" {
  for
    input in [
      ordering_leaf("null", Literal(Json::null())),
      reflect_bool(false),
      reflect_bool(true),
      sequence_num(1),
    ] {
    transfer_reject(reverse_contract_call(input))
  }
  for through_alias in [false, true] {
    sequence_failure(
      reverse_contract_call(
        ordering_error("reverse-required-input"),
        through_alias~,
      ),
      @moonjsonnet.Runtime,
      Some("reverse-required-input"),
    )
  }
}

///|
test "RV5 reverse retains binding and strict head behavior" {
  let function = additive_select(sequence_var("std"), "reverse")
  let safe = ordering_array([sequence_num(1), sequence_num(2)])
  transfer_value(sequence_call("length", [function]), 1)
  // Existing source/current arr spelling is a compatibility control only;
  // it does not adjudicate the documentation's arrs spelling.
  transfer_value(shared_mode_call(function, [(Some("arr"), safe)]), [2, 1])
  let invalid : Array[Array[(String?, OrderingExpr)]] = [
    [],
    [(None, safe), (None, safe)],
    [(Some("unknown"), safe)],
  ]
  for args in invalid {
    transfer_reject(shared_mode_call(function, args))
  }
  // Existing tailstrict profile: force the input head, not Array payloads.
  for through_alias in [false, true] {
    let strict_result = reverse_contract_call(
      ordering_array([ordering_error("strict-payload-unused"), sequence_num(7)]),
      through_alias~,
      strict=true,
    )
    transfer_value(sequence_call("length", [strict_result]), 2)
    transfer_value(make_index(strict_result, 0), 7)
    sequence_failure(
      reverse_contract_call(
        ordering_error("reverse-strict-input"),
        through_alias~,
        strict=true,
      ),
      @moonjsonnet.Runtime,
      Some("reverse-strict-input"),
    )
  }
}
