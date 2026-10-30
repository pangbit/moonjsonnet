// Independent fixed contract: SPEC-JOIN-2026-10-23.md.

///|
fn join_call(sep : OrderingExpr, arr : OrderingExpr) -> OrderingExpr {
  rounding_apply("join", [(None, sep), (None, arr)])
}

///|
test "join preserves ordered string and array data while skipping only null items" {
  let nil = ordering_leaf("null", Literal(Json::null()))
  let empty = ordering_array([])
  let cases : Array[(OrderingExpr, OrderingExpr, Json)] = [
    (reflect_string("-"), empty, ""),
    (reflect_string("-"), ordering_array([nil, nil]), ""),
    (reflect_string("-"), ordering_array([nil, reflect_string("x"), nil]), "x"),
    (
      reflect_string("-"),
      ordering_array([reflect_string(""), nil, reflect_string("")]),
      "-",
    ),
    (
      reflect_string(""),
      ordering_array([reflect_string("a"), nil, reflect_string("b")]),
      "ab",
    ),
    (
      reflect_string("中\u0000"),
      ordering_array([
        reflect_string("😀"),
        nil,
        reflect_string("e\u0301"),
        reflect_string(""),
      ]),
      "😀中\u0000e\u0301中\u0000",
    ),
    (ordering_array([sequence_num(9)]), empty, []),
    (ordering_array([sequence_num(9)]), ordering_array([nil, nil]), []),
    (ordering_array([sequence_num(9)]), ordering_array([nil, empty, nil]), []),
    (
      ordering_array([sequence_num(9)]),
      ordering_array([empty, nil, empty]),
      [9],
    ),
    (
      empty,
      ordering_array([
        ordering_array([sequence_num(1)]),
        nil,
        ordering_array([sequence_num(2), sequence_num(3)]),
      ]),
      [1, 2, 3],
    ),
    (
      ordering_array([sequence_num(9), sequence_num(8)]),
      ordering_array([
        nil,
        ordering_array([sequence_num(1)]),
        nil,
        empty,
        ordering_array([sequence_num(2), sequence_num(3)]),
        nil,
      ]),
      [1, 9, 8, 9, 8, 2, 3],
    ),
    (
      ordering_array([reflect_bool(false)]),
      ordering_array([
        ordering_array([ordering_array([sequence_num(1), sequence_num(2)])]),
        ordering_array([ordering_array([sequence_num(3)])]),
      ]),
      [[1, 2], false, [3]],
    ),
  ]
  for (sep, arr, expected) in cases {
    sequence_value(join_call(sep, arr), expected)
    sequence_value(
      rounding_apply("join", [(Some("arr"), arr), (Some("sep"), sep)]),
      expected,
    )
  }
}

///|
test "join array heads defer separator and member payloads until selected or manifested" {
  let nil = ordering_leaf("null", Literal(Json::null()))
  let empty = ordering_array([])
  let sep_error = ordering_error("join-separator-payload")
  let sep = ordering_array([sep_error])
  for
    arr in [
      empty,
      ordering_array([nil, nil]),
      ordering_array([nil, empty, nil]),
    ] {
    sequence_value(join_call(sep, arr), [])
  }
  let inserted = join_call(sep, ordering_array([empty, nil, empty]))
  sequence_value(sequence_call("length", [inserted]), 1)
  sequence_failure(
    make_index(inserted, 0),
    @moonjsonnet.Runtime,
    Some("join-separator-payload"),
  )
  let middle = join_call(
    sep,
    ordering_array([
      ordering_array([sequence_num(1)]),
      ordering_array([sequence_num(2)]),
    ]),
  )
  sequence_value(make_index(middle, 0), 1)
  sequence_value(make_index(middle, 2), 2)
  sequence_failure(middle, @moonjsonnet.Runtime, Some("join-separator-payload"))
  let member_error = ordering_error("join-member-payload")
  let joined = join_call(
    empty,
    ordering_array([ordering_array([sequence_num(1), member_error])]),
  )
  sequence_value(sequence_call("length", [joined]), 2)
  sequence_value(make_index(joined, 0), 1)
  sequence_failure(joined, @moonjsonnet.Runtime, Some("join-member-payload"))
  let unread = ordering_error("join-function-body-or-default")
  sequence_value(
    sequence_call("type", [
      make_index(
        join_call(
          empty,
          ordering_array([ordering_array([value_head_function(unread, unread)])]),
        ),
        0,
      ),
    ]),
    "function",
  )
}

///|
test "join rejects wrong outer and element kinds without traversing their payloads" {
  let nil = ordering_leaf("null", Literal(Json::null()))
  let unread = ordering_error("join-invalid-payload-unread")
  let object = merge_patch_object([("x", unread)])
  let function = value_head_function(unread, unread)
  let common = [nil, reflect_bool(false), sequence_num(1), object, function]
  for sep in common {
    sequence_failure(
      join_call(sep, ordering_array([])),
      @moonjsonnet.Type,
      None,
    )
  }
  for arr in common + [reflect_string("")] {
    sequence_failure(
      join_call(reflect_string("-"), arr),
      @moonjsonnet.Type,
      None,
    )
  }
  for
    (sep, opposite) in [
      (reflect_string("-"), ordering_array([unread])),
      (ordering_array([]), reflect_string("x")),
    ] {
    for
      item in [reflect_bool(false), sequence_num(1), object, function, opposite] {
      sequence_failure(
        join_call(sep, ordering_array([nil, item])),
        @moonjsonnet.Type,
        None,
      )
    }
  }
}

///|
test "join propagates required outer heads even when only an early result is selected" {
  let empty = ordering_array([])
  let huge = ordering_leaf("1e308", Literal(Json::number(1.0e308)))
  for
    (value, marker) in [
      (
        join_call(ordering_error("join-separator-head"), empty),
        Some("join-separator-head"),
      ),
      (
        join_call(empty, ordering_error("join-array-head")),
        Some("join-array-head"),
      ),
      (
        make_index(
          join_call(
            empty,
            ordering_array([
              ordering_array([sequence_num(1)]),
              ordering_error("join-later-outer"),
            ]),
          ),
          0,
        ),
        Some("join-later-outer"),
      ),
      (
        sequence_call("type", [
          join_call(
            reflect_string("-"),
            ordering_array([
              reflect_string("ok"),
              ordering_error("join-string-item"),
            ]),
          ),
        ]),
        Some("join-string-item"),
      ),
      (join_call(ordering_binary(huge, "*", huge), empty), None),
    ] {
    sequence_failure(value, @moonjsonnet.Runtime, marker)
  }
  pair_reject(ordering_unused(join_call(sequence_var("join_missing"), empty)))
}

///|
fn join_arr_guard(handmade : Bool) -> Unit raise {
  let sep = rewrite_gate(reflect_string("separator"), reflect_string("-"))
  for
    (arr, expected_kind, marker) in [
      (sequence_num(1), @moonjsonnet.Type, None),
      (
        ordering_error("join-required-array"),
        @moonjsonnet.Runtime,
        Some("join-required-array"),
      ),
    ] {
    let value = additive_probe_scope(join_call(sep, arr))
    let counts : Map[String, Int32] = Map([])
    try
      ordering_program(value, handmade).evaluate(
        native_functions=rewrite_natives(counts),
        limits=sequence_limits(),
      )
    catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, expected_kind)
        if marker is Some(text) {
          assert_eq(d.message, text)
        }
      }
    } noraise {
      _ => fail("join accepted an invalid required array")
    }
    assert_eq(
      counts.length(),
      0,
      msg="arr rejection must not demand the successful separator gate",
    )
  }
}

///|
test "source join validates the outer array before demanding the separator" {
  join_arr_guard(false)
}

///|
test "handmade join validates the outer array before demanding the separator" {
  join_arr_guard(true)
}

///|
test "join preserves separator input members and aliases across cold and warm reads" {
  let sep = sequence_var("sep")
  let left = sequence_var("left")
  let right = sequence_var("right")
  let arr = sequence_var("arr")
  let result = sequence_var("result")
  for inputs_first in [false, true] {
    let input_checks = [
      (sequence_call("length", [sep]), 2),
      (sequence_call("length", [left]), 1),
      (sequence_call("length", [right]), 1),
      (sequence_call("length", [arr]), 4),
    ]
    let result_checks = [
      (sequence_call("length", [result]), 6),
      (make_index(result, 0), 1),
      (make_index(result, 2), 8),
    ]
    sequence_value(
      sequence_local(
        [
          ("sep", ordering_array([sequence_num(9), sequence_num(8)])),
          ("sep_alias", sep),
          ("left", ordering_array([sequence_num(1)])),
          ("right", ordering_array([sequence_num(2)])),
          (
            "arr",
            ordering_array([
              left,
              ordering_leaf("null", Literal(Json::null())),
              ordering_array([]),
              right,
            ]),
          ),
          ("arr_alias", arr),
          ("result", join_call(sep, arr)),
        ],
        sequence_gate(
          if inputs_first {
            input_checks + result_checks
          } else {
            result_checks + input_checks
          },
          ordering_array([
            sep,
            sequence_var("sep_alias"),
            left,
            right,
            arr,
            sequence_var("arr_alias"),
            result,
            join_call(sep, arr),
          ]),
        ),
      ),
      [
        [9, 8],
        [9, 8],
        [1],
        [2],
        [[1], Json::null(), [], [2]],
        [[1], Json::null(), [], [2]],
        [1, 9, 8, 9, 8, 2],
        [1, 9, 8, 9, 8, 2],
      ],
    )
  }
}

///|
test "join refuses invalid bindings before argument gates and retains unused calls" {
  let sep = rewrite_gate(reflect_string("sep-binding"), reflect_string("-"))
  let arr = rewrite_gate(reflect_string("arr-binding"), ordering_array([]))
  for
    args in [
      [],
      [(None, sep)],
      [(Some("arr"), arr)],
      [(Some("separator"), sep), (Some("arr"), arr)],
      [(None, sep), (None, arr), (None, arr)],
      [(None, sep), (Some("sep"), sep), (Some("arr"), arr)],
    ] {
    let call = rounding_apply("join", args)
    for handmade in [false, true] {
      let counts : Map[String, Int32] = Map([])
      assert_eq(
        ordering_program(additive_probe_scope(ordering_unused(call)), handmade).evaluate(
          native_functions=rewrite_natives(counts),
          limits=sequence_limits(),
        ),
        42,
      )
      try
        ordering_program(additive_probe_scope(call), handmade).evaluate(
          native_functions=rewrite_natives(counts),
          limits=sequence_limits(),
        )
      catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
      } noraise {
        _ => fail("invalid join binding succeeded")
      }
      assert_eq(counts.length(), 0)
    }
  }
}
