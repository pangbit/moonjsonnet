// Frozen independent criteria: SPEC-MEMBERSHIP-2026-10-23.md.
// Pending execution. Source and handmade AST paths use literal outcomes;
// neither Go/C++ behavior nor the maintained implementation is an oracle.

///|
fn membership_call(
  name : String,
  array : OrderingExpr,
  needle : OrderingExpr,
) -> OrderingExpr {
  sequence_call(name, [array, needle])
}

///|
test "membership preserves literal Array equality and required named arguments" {
  let hidden = reflect_object([
    (reflect_string("a"), 1, sequence_num(1)),
    (reflect_string("hidden"), 2, ordering_error("membership-hidden")),
  ])
  let plain = merge_patch_object([("a", sequence_num(1))])
  let function = value_head_function(
    ordering_error("membership-default"),
    ordering_error("membership-body"),
  )
  let cases : Array[(OrderingExpr, OrderingExpr, Json)] = [
    (ordering_array([]), sequence_num(1), false),
    (ordering_array([sequence_num(1), sequence_num(2)]), sequence_num(2), true),
    (ordering_array([sequence_num(1), sequence_num(2)]), sequence_num(3), false),
    (ordering_array([sequence_num(1), sequence_num(1)]), sequence_num(1), true),
    (ordering_array([hidden]), plain, true),
    (
      ordering_array([ordering_array([sequence_num(1)])]),
      ordering_array([sequence_num(1)]),
      true,
    ),
    (ordering_array([function, sequence_num(2)]), sequence_num(2), true),
    (ordering_array([reflect_string("1")]), sequence_num(1), false),
  ]
  for name in ["member", "contains"] {
    let parameter = if name == "member" { "x" } else { "elem" }
    for (array, needle, expected) in cases {
      sequence_value(membership_call(name, array, needle), expected)
      sequence_value(
        rounding_apply(name, [(Some(parameter), needle), (Some("arr"), array)]),
        expected,
      )
    }
  }
}

///|
test "member String search preserves nonempty Unicode patterns and literal boundaries" {
  for
    (input, pattern, expected) in [
      ("", "a", false),
      ("abc", "a", true),
      ("abc", "bc", true),
      ("abc", "abcd", false),
      ("aaaa", "aa", true),
      ("😀a😀", "😀", true),
      ("😀a😀", "a😀", true),
      ("😀a😀", "😀😀", false),
      ("x\u0000y", "\u0000", true),
      ("e\u0301", "é", false),
      ("e\u0301", "\u0301", true),
      ("中😀", "😀中", false),
    ] {
    sequence_value(
      membership_call("member", reflect_string(input), reflect_string(pattern)),
      Json::boolean(expected),
    )
    sequence_value(
      rounding_apply("member", [
        (Some("x"), reflect_string(pattern)),
        (Some("arr"), reflect_string(input)),
      ]),
      Json::boolean(expected),
    )
  }
}

///|
test "member String empty patterns follow the fixed findSubstr empty result" {
  for input in ["", "a", "😀", "\u0000", "e\u0301"] {
    sequence_value(
      membership_call("member", reflect_string(input), reflect_string("")),
      false,
    )
  }
}

///|
fn membership_empty(name : String, handmade : Bool) -> Unit raise {
  let unread = ordering_error("membership-empty-needle-unread")
  for
    needle in [
      unread,
      ordering_leaf("null", Literal(Json::null())),
      reflect_bool(false),
      sequence_num(1),
      reflect_string("x"),
      ordering_array([unread]),
      merge_patch_object([("x", unread)]),
      value_head_function(unread, unread),
    ] {
    let value = membership_call(name, ordering_array([]), needle)
    for
      (observation, expected) in [
        (value, Json::boolean(false)),
        (sequence_call("type", [value]), Json::string("boolean")),
      ] {
      assert_eq(
        ordering_program(observation, handmade).evaluate(
          limits=sequence_limits(),
        ),
        expected,
      )
    }
  }
  let value = additive_probe_scope(
    membership_call(
      name,
      rewrite_gate(reflect_string("array"), ordering_array([])),
      rewrite_gate(reflect_string("needle"), sequence_num(1)),
    ),
  )
  let counts : Map[String, Int] = Map([])
  assert_eq(
    ordering_program(ordering_unused(value), handmade).evaluate(
      native_functions=rewrite_natives(counts),
      limits=sequence_limits(),
    ),
    42,
  )
  assert_eq(counts.length(), 0)
  assert_eq(
    ordering_program(value, handmade).evaluate(
      native_functions=rewrite_natives(counts),
      limits=sequence_limits(),
    ),
    false,
  )
  assert_eq(counts, Map([("array", 1)]))
}

///|
test "source member empty Array leaves the target unforced" {
  membership_empty("member", false)
}

///|
test "handmade member empty Array leaves the target unforced" {
  membership_empty("member", true)
}

///|
test "source contains empty Array leaves the target unforced" {
  membership_empty("contains", false)
}

///|
test "handmade contains empty Array leaves the target unforced" {
  membership_empty("contains", true)
}

///|
fn membership_shared(
  name : String,
  elements : Array[OrderingExpr],
  expected_counts : Map[String, Int],
) -> Unit raise {
  let array = sequence_var("array")
  let needle = sequence_var("needle")
  let result = sequence_var("result")
  let value = additive_probe_scope(
    sequence_local(
      [
        (
          "array",
          rewrite_gate(reflect_string("array"), ordering_array(elements)),
        ),
        ("needle", rewrite_gate(reflect_string("needle"), sequence_num(1))),
        ("result", membership_call(name, array, needle)),
      ],
      ordering_array([
        result,
        result,
        membership_call(name, array, needle),
        sequence_call("type", [result]),
      ]),
    ),
  )
  for handmade in [false, true] {
    let counts : Map[String, Int] = Map([])
    assert_eq(
      ordering_program(ordering_unused(value), handmade).evaluate(
        native_functions=rewrite_natives(counts),
        limits=sequence_limits(),
      ),
      42,
    )
    assert_eq(counts.length(), 0)
    assert_eq(
      ordering_program(value, handmade).evaluate(
        native_functions=rewrite_natives(counts),
        limits=sequence_limits(),
      ),
      [true, true, true, "boolean"],
    )
    assert_eq(counts, expected_counts)
  }
}

///|
test "member compares every Array entry after a match while sharing demanded values" {
  membership_shared(
    "member",
    [
      rewrite_gate(reflect_string("first"), sequence_num(1)),
      rewrite_gate(reflect_string("middle"), sequence_num(2)),
      rewrite_gate(reflect_string("last"), sequence_num(1)),
    ],
    Map([("array", 1), ("needle", 1), ("first", 1), ("middle", 1), ("last", 1)]),
  )
}

///|
fn membership_tail_error(handmade : Bool) -> Unit raise {
  let value = membership_call(
    "member",
    ordering_array([sequence_num(1), ordering_error("membership-required-tail")]),
    sequence_num(1),
  )
  for observation in [value, sequence_call("type", [value])] {
    assert_eq(
      ordering_program(ordering_unused(observation), handmade).evaluate(
        limits=sequence_limits(),
      ),
      42,
    )
    try
      ordering_program(observation, handmade).evaluate(limits=sequence_limits())
    catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Runtime)
        assert_eq(d.message, "membership-required-tail")
      }
    } noraise {
      _ => fail("member suppressed an error after its first matching entry")
    }
  }
}

///|
test "source member propagates required errors after an earlier Array match" {
  membership_tail_error(false)
}

///|
test "handmade member propagates required errors after an earlier Array match" {
  membership_tail_error(true)
}

///|
test "contains stops at its first match and shares required inputs without touching the tail" {
  membership_shared(
    "contains",
    [
      rewrite_gate(reflect_string("first"), sequence_num(1)),
      rewrite_gate(
        reflect_string("tail"),
        ordering_error("contains-unread-tail"),
      ),
    ],
    Map([("array", 1), ("needle", 1), ("first", 1)]),
  )
}

///|
fn membership_reject_without_gates(value : OrderingExpr) -> Unit raise {
  let value = additive_probe_scope(value)
  for handmade in [false, true] {
    let counts : Map[String, Int] = Map([])
    assert_eq(
      ordering_program(ordering_unused(value), handmade).evaluate(
        native_functions=rewrite_natives(counts),
        limits=sequence_limits(),
      ),
      42,
    )
    try
      ordering_program(value, handmade).evaluate(
        native_functions=rewrite_natives(counts),
        limits=sequence_limits(),
      )
    catch {
      @moonjsonnet.Error(d) =>
        assert_true(
          d.kind == @moonjsonnet.Runtime ||
          d.kind == @moonjsonnet.Type ||
          d.kind == @moonjsonnet.Assertion,
          msg="membership rejection must be a runtime-domain failure",
        )
    } noraise {
      _ => fail("invalid membership call succeeded")
    }
    assert_eq(
      counts.length(),
      0,
      msg="rejection must skip target and payload gates",
    )
  }
}

///|
test "membership rejects invalid collection heads before target and nested payload gates" {
  let unread = rewrite_gate(
    reflect_string("payload"),
    ordering_error("membership-rejected-payload"),
  )
  for name in ["member", "contains"] {
    for
      input in [
        ordering_leaf("null", Literal(Json::null())),
        reflect_bool(false),
        sequence_num(1),
        merge_patch_object([("x", unread)]),
        value_head_function(unread, unread),
      ] {
      membership_reject_without_gates(
        membership_call(
          name,
          input,
          rewrite_gate(reflect_string("needle"), sequence_num(1)),
        ),
      )
    }
  }
  membership_reject_without_gates(
    membership_call(
      "contains",
      reflect_string("abc"),
      rewrite_gate(reflect_string("needle"), reflect_string("a")),
    ),
  )
}

///|
test "membership propagates isolated required input target and pre-match element errors" {
  for name in ["member", "contains"] {
    for
      (array, needle, marker) in [
        (
          ordering_error("membership-input"),
          sequence_num(1),
          "membership-input",
        ),
        (
          ordering_array([sequence_num(1)]),
          ordering_error("membership-target"),
          "membership-target",
        ),
        (
          ordering_array([ordering_error("membership-first"), sequence_num(1)]),
          sequence_num(1),
          "membership-first",
        ),
      ] {
      let value = membership_call(name, array, needle)
      for observation in [value, sequence_call("type", [value])] {
        sequence_failure(observation, @moonjsonnet.Runtime, Some(marker))
      }
    }
  }
  sequence_failure(
    membership_call(
      "member",
      reflect_string(""),
      ordering_error("member-string-target"),
    ),
    @moonjsonnet.Runtime,
    Some("member-string-target"),
  )
  for needle in [sequence_num(1), ordering_array([])] {
    membership_reject_without_gates(
      membership_call("member", reflect_string(""), needle),
    )
  }
}

///|
test "membership rejects invalid bindings before gates and retains unused free-name errors" {
  let array = rewrite_gate(reflect_string("array"), ordering_array([]))
  let needle = rewrite_gate(reflect_string("needle"), sequence_num(1))
  for name in ["member", "contains"] {
    let parameter = if name == "member" { "x" } else { "elem" }
    for
      args in [
        [],
        [(None, array)],
        [(Some(parameter), needle)],
        [(None, array), (None, needle), (None, needle)],
        [(Some("arr"), array), (Some("unexpected"), needle)],
        [(None, array), (Some("arr"), array), (Some(parameter), needle)],
      ] {
      membership_reject_without_gates(rounding_apply(name, args))
    }
    for
      (input, target) in [
        (sequence_var("membership_missing"), sequence_num(1)),
        (ordering_array([]), sequence_var("membership_missing")),
      ] {
      pair_reject(ordering_unused(membership_call(name, input, target)))
    }
  }
}
