// Frozen independent criteria: SPEC-EXTREMA-DEMAND-2026-10-23.md.
// Pending execution. Array-only demand scope; comparator invocation counts,
// singleton noncomparable values and non-Array extensions remain unadjudicated.

///|
fn extrema_demand_call(
  name : String,
  input : OrderingExpr,
  key : OrderingExpr?,
  fallback : OrderingExpr?,
) -> OrderingExpr {
  let args : Array[(String?, OrderingExpr)] = [(Some("arr"), input)]
  if key is Some(value) {
    args.push((Some("keyF"), value))
  }
  if fallback is Some(value) {
    args.push((Some("onEmpty"), value))
  }
  rounding_apply(name, args)
}

///|
test "Array extrema retain literal numeric Unicode and stable-key selections" {
  let cases : Array[(OrderingExpr, Json, Json)] = [
    (ordering_array([sequence_num(3), sequence_num(1), sequence_num(2)]), 1, 3),
    (
      ordering_array([sequence_num(-2), sequence_num(0), sequence_num(1)]),
      -2,
      1,
    ),
    (ordering_array([sequence_num(7)]), 7, 7),
    (ordering_array([sequence_num(1), sequence_num(1)]), 1, 1),
    (
      ordering_array([
        reflect_string("😀"),
        reflect_string("é"),
        reflect_string("Z"),
        reflect_string("中"),
      ]),
      "Z",
      "😀",
    ),
    (
      ordering_array([reflect_string("e\u0301"), reflect_string("é")]),
      "e\u0301",
      "é",
    ),
    (
      ordering_array([reflect_string("a"), reflect_string("\u0000")]),
      "\u0000",
      "a",
    ),
    (
      ordering_array([
        ordering_array([sequence_num(2)]),
        ordering_array([sequence_num(1), sequence_num(4)]),
        ordering_array([sequence_num(1), sequence_num(3)]),
      ]),
      [1, 3],
      [2],
    ),
  ]
  for (input, minimum, maximum) in cases {
    for (name, expected) in [("minArray", minimum), ("maxArray", maximum)] {
      sequence_value(sequence_call(name, [input]), expected)
      sequence_value(extrema_demand_call(name, input, None, None), expected)
    }
  }
  let keyed = ordering_array([
    merge_patch_object([("k", sequence_num(2)), ("id", reflect_string("a"))]),
    merge_patch_object([("k", sequence_num(1)), ("id", reflect_string("b"))]),
    merge_patch_object([("k", sequence_num(2)), ("id", reflect_string("c"))]),
  ])
  let key = make_function(
    ["item"],
    pair_expr("[]", sequence_var("item"), reflect_string("k")),
  )
  for (name, expected) in [("minArray", "b"), ("maxArray", "a")] {
    sequence_value(
      pair_expr(
        "[]",
        rounding_apply(name, [(Some("keyF"), key), (Some("arr"), keyed)]),
        reflect_string("id"),
      ),
      Json::string(expected),
    )
  }
}

///|
fn extrema_unused_fallback(name : String, handmade : Bool) -> Unit raise {
  let unread = ordering_error("extrema-nonempty-fallback-unread")
  for
    fallback in [
      unread,
      ordering_leaf("null", Literal(Json::null())),
      reflect_bool(false),
      sequence_num(0),
      reflect_string("unused"),
      ordering_array([unread]),
      merge_patch_object([("x", unread)]),
      value_head_function(unread, unread),
    ] {
    let value = extrema_demand_call(
      name,
      ordering_array([sequence_num(7)]),
      None,
      Some(fallback),
    )
    for
      (observation, expected) in [
        (value, Json::number(7)),
        (sequence_call("type", [value]), Json::string("number")),
      ] {
      assert_eq(
        ordering_program(ordering_unused(observation), handmade).evaluate(
          limits=sequence_limits(),
        ),
        42,
      )
      assert_eq(
        ordering_program(observation, handmade).evaluate(
          limits=sequence_limits(),
        ),
        expected,
      )
    }
  }
}

///|
test "source minArray leaves onEmpty unforced for a nonempty Array" {
  extrema_unused_fallback("minArray", false)
}

///|
test "handmade minArray leaves onEmpty unforced for a nonempty Array" {
  extrema_unused_fallback("minArray", true)
}

///|
test "source maxArray leaves onEmpty unforced for a nonempty Array" {
  extrema_unused_fallback("maxArray", false)
}

///|
test "handmade maxArray leaves onEmpty unforced for a nonempty Array" {
  extrema_unused_fallback("maxArray", true)
}

///|
fn extrema_unused_key(name : String, handmade : Bool) -> Unit raise {
  let unread = ordering_error("extrema-empty-key-unread")
  for
    key in [
      unread,
      ordering_leaf("null", Literal(Json::null())),
      reflect_bool(false),
      sequence_num(1),
      reflect_string("unused"),
      ordering_array([unread]),
      merge_patch_object([("x", unread)]),
      make_function(["a", "b"], unread),
    ] {
    let value = extrema_demand_call(
      name,
      ordering_array([]),
      Some(key),
      Some(sequence_num(9)),
    )
    for
      (observation, expected) in [
        (value, Json::number(9)),
        (sequence_call("type", [value]), Json::string("number")),
      ] {
      assert_eq(
        ordering_program(observation, handmade).evaluate(
          limits=sequence_limits(),
        ),
        expected,
      )
    }
  }
  for
    (fallback, observer, expected) in [
      (ordering_array([unread]), "length", Json::number(1)),
      (merge_patch_object([("x", unread)]), "type", Json::string("object")),
      (value_head_function(unread, unread), "type", Json::string("function")),
    ] {
    assert_eq(
      ordering_program(
        sequence_call(observer, [
          extrema_demand_call(
            name,
            ordering_array([]),
            Some(unread),
            Some(fallback),
          ),
        ]),
        handmade,
      ).evaluate(limits=sequence_limits()),
      expected,
    )
  }
}

///|
test "source minArray empty Array selects onEmpty without demanding keyF" {
  extrema_unused_key("minArray", false)
}

///|
test "handmade minArray empty Array selects onEmpty without demanding keyF" {
  extrema_unused_key("minArray", true)
}

///|
test "source maxArray empty Array selects onEmpty without demanding keyF" {
  extrema_unused_key("maxArray", false)
}

///|
test "handmade maxArray empty Array selects onEmpty without demanding keyF" {
  extrema_unused_key("maxArray", true)
}

///|
fn extrema_discarded_payload(name : String) -> Unit raise {
  let value = extrema_demand_call(
    name,
    ordering_array([
      sequence_num(7),
      ordering_error("extrema-discarded-payload"),
    ]),
    Some(make_function(["item"], sequence_num(0))),
    None,
  )
  sequence_value(value, 7)
  sequence_value(sequence_call("type", [value]), "number")
}

///|
test "minArray constant keys do not demand an unselected tail element" {
  extrema_discarded_payload("minArray")
}

///|
test "maxArray constant keys do not demand an unselected tail element" {
  extrema_discarded_payload("maxArray")
}

///|
test "extrema branch gates preserve selected demand and shared argument values" {
  for name in ["minArray", "maxArray"] {
    for empty in [false, true] {
      let input = if empty {
        ordering_array([])
      } else {
        ordering_array([
          rewrite_gate(reflect_string("selected"), sequence_num(7)),
          rewrite_gate(reflect_string("discarded"), sequence_num(8)),
        ])
      }
      let result = sequence_var("result")
      let value = additive_probe_scope(
        sequence_local(
          [
            ("input", rewrite_gate(reflect_string("input"), input)),
            (
              "key",
              rewrite_gate(
                reflect_string("key"),
                make_function(["item"], sequence_num(0)),
              ),
            ),
            (
              "fallback",
              rewrite_gate(reflect_string("fallback"), sequence_num(9)),
            ),
            (
              "result",
              extrema_demand_call(
                name,
                sequence_var("input"),
                Some(sequence_var("key")),
                Some(sequence_var("fallback")),
              ),
            ),
          ],
          ordering_array([result, result, sequence_call("type", [result])]),
        ),
      )
      for handmade in [false, true] {
        let counts : Map[String, Int32] = Map([])
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
          if empty {
            [9, 9, "number"]
          } else {
            [7, 7, "number"]
          },
        )
        assert_eq(
          counts,
          if empty {
            Map([("input", 1), ("fallback", 1)])
          } else {
            Map([("input", 1), ("key", 1), ("selected", 1)])
          },
        )
      }
    }
  }
}

///|
test "extrema retain required branch errors and demand the selected result" {
  let identity = make_function(["item"], sequence_var("item"))
  for name in ["minArray", "maxArray"] {
    let required = [
      (
        extrema_demand_call(
          name,
          ordering_error("extrema-input"),
          Some(identity),
          None,
        ),
        "extrema-input",
      ),
      (
        extrema_demand_call(
          name,
          ordering_array([]),
          Some(identity),
          Some(ordering_error("extrema-fallback")),
        ),
        "extrema-fallback",
      ),
      (
        extrema_demand_call(
          name,
          ordering_array([sequence_num(1)]),
          Some(ordering_error("extrema-key")),
          None,
        ),
        "extrema-key",
      ),
      (
        extrema_demand_call(
          name,
          ordering_array([sequence_num(1)]),
          Some(make_function(["item"], ordering_error("extrema-key-body"))),
          None,
        ),
        "extrema-key-body",
      ),
      (
        extrema_demand_call(
          name,
          ordering_array([ordering_error("extrema-selected")]),
          Some(make_function(["item"], sequence_num(0))),
          None,
        ),
        "extrema-selected",
      ),
    ]
    for (value, marker) in required {
      for observation in [value, sequence_call("type", [value])] {
        sequence_failure(observation, @moonjsonnet.Runtime, Some(marker))
      }
    }
    sequence_failure(
      extrema_demand_call(name, ordering_array([]), None, None),
      @moonjsonnet.Runtime,
      None,
    )
    sequence_failure(
      extrema_demand_call(
        name,
        ordering_array([sequence_num(1)]),
        Some(make_function(["a", "b"], sequence_var("a"))),
        None,
      ),
      @moonjsonnet.Runtime,
      None,
    )
  }
}

///|
test "extrema bindings reject before gates and unused optional free names remain Static" {
  let input = rewrite_gate(reflect_string("input"), ordering_array([]))
  let key = rewrite_gate(
    reflect_string("key"),
    make_function(["item"], sequence_num(0)),
  )
  let fallback = rewrite_gate(reflect_string("fallback"), sequence_num(9))
  for name in ["minArray", "maxArray"] {
    for
      args in [
        [],
        [(Some("keyF"), key), (Some("onEmpty"), fallback)],
        [(None, input), (None, key), (None, fallback), (None, fallback)],
        [(Some("arr"), input), (Some("unexpected"), fallback)],
        [(None, input), (Some("arr"), input)],
      ] {
      // Reuse only the runtime-domain/zero-gate assertion helper, not an oracle.
      membership_reject_without_gates(rounding_apply(name, args))
    }
    for
      (array, mapper, empty_result) in [
        (
          sequence_var("extrema_missing"),
          make_function(["item"], sequence_num(0)),
          sequence_num(9),
        ),
        (ordering_array([]), sequence_var("extrema_missing"), sequence_num(9)),
        (
          ordering_array([sequence_num(1)]),
          make_function(["item"], sequence_num(0)),
          sequence_var("extrema_missing"),
        ),
      ] {
      pair_reject(
        ordering_unused(
          extrema_demand_call(name, array, Some(mapper), Some(empty_result)),
        ),
      )
    }
  }
}
