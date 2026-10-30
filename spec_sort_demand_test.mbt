// Frozen independent criteria: SPEC-SORT-DEMAND-2026-10-25.md.
// Fixed source-defined Array branches; no interpreter/reference output oracle.

///|
fn sort_demand_call(
  input : OrderingExpr,
  key : OrderingExpr?,
  named : Bool,
) -> OrderingExpr {
  let args : Array[(String?, OrderingExpr)] = []
  if named {
    if key is Some(value) {
      args.push((Some("keyF"), value))
    }
    args.push((Some("arr"), input))
  } else {
    args.push((None, input))
    if key is Some(value) {
      args.push((None, value))
    }
  }
  rounding_apply("sort", args)
}

///|
fn sort_degenerate_key(handmade : Bool) -> Unit raise {
  for
    (items, expected) in [
      (ordering_array([]), Json::array([])),
      (ordering_array([sequence_num(7)]), Json::array([7])),
    ] {
    for named in [false, true] {
      let value = sort_demand_call(
        items,
        Some(ordering_error("sort-unused-key-head")),
        named,
      )
      assert_eq(
        ordering_program(value, handmade).evaluate(limits=sequence_limits()),
        expected,
      )
      assert_eq(
        ordering_program(sequence_call("length", [value]), handmade).evaluate(
          limits=sequence_limits(),
        ),
        Json::number(
          if expected is Array(a) {
            a.length().to_double()
          } else {
            abort("array fixture")
          },
        ),
      )
      assert_eq(
        ordering_program(sequence_call("type", [value]), handmade).evaluate(
          limits=sequence_limits(),
        ),
        "array",
      )
      assert_eq(
        ordering_program(ordering_unused(value), handmade).evaluate(
          limits=sequence_limits(),
        ),
        42,
      )
    }
  }
}

///|
test "source sort empty and singleton Arrays never demand an unused key expression" {
  sort_degenerate_key(false)
}

///|
test "handmade sort empty and singleton Arrays never demand an unused key expression" {
  sort_degenerate_key(true)
}

///|
fn sort_singleton_payload(handmade : Bool) -> Unit raise {
  let unread = ordering_error("sort-singleton-element-unread")
  let values = [
    unread,
    ordering_array([unread]),
    merge_patch_object([("v", unread)]),
    make_function(["p"], unread),
  ]
  for payload in values {
    for
      key in [
        None,
        Some(
          make_function(["p"], ordering_error("sort-singleton-key-body-unread")),
        ),
      ] {
      let value = sort_demand_call(ordering_array([payload]), key, false)
      assert_eq(
        ordering_program(sequence_call("length", [value]), handmade).evaluate(
          limits=sequence_limits(),
        ),
        1,
      )
      assert_eq(
        ordering_program(sequence_call("type", [value]), handmade).evaluate(
          limits=sequence_limits(),
        ),
        "array",
      )
      assert_eq(
        ordering_program(ordering_unused(value), handmade).evaluate(
          limits=sequence_limits(),
        ),
        42,
      )
    }
  }
}

///|
test "source sort singleton shape preserves every deferred element head" {
  sort_singleton_payload(false)
}

///|
test "handmade sort singleton shape preserves every deferred element head" {
  sort_singleton_payload(true)
}

///|
test "sort retains literal ordering stable keys and the fixed thirty element branch seam" {
  sequence_value(
    sort_demand_call(
      ordering_array([
        sequence_num(3),
        sequence_num(-1),
        sequence_num(2),
        sequence_num(2),
      ]),
      None,
      false,
    ),
    [-1, 2, 2, 3],
  )
  sequence_value(
    sort_demand_call(
      ordering_array([
        reflect_string("😀"),
        reflect_string("é"),
        reflect_string("e\u0301"),
        reflect_string(""),
        reflect_string("\u0000"),
        reflect_string("a"),
      ]),
      None,
      true,
    ),
    ["", "\u0000", "a", "e\u0301", "é", "😀"],
  )
  for n in [2, 30, 31] {
    let input : Array[OrderingExpr] = []
    let expected : Array[Json] = []
    for i in 0..<n {
      input.push(sequence_num(n - i - 1))
      expected.push(Json::number(i.to_double()))
    }
    sequence_value(
      sort_demand_call(ordering_array(input), None, false),
      Json::array(expected),
    )
  }
  let rows = ordering_array([
    merge_patch_object([
      ("key", sequence_num(1)),
      ("id", reflect_string("a")),
      ("unread", ordering_error("sort-object-payload")),
    ]),
    merge_patch_object([
      ("key", sequence_num(0)),
      ("id", reflect_string("b")),
      ("unread", ordering_error("sort-object-payload")),
    ]),
    merge_patch_object([
      ("key", sequence_num(1)),
      ("id", reflect_string("c")),
      ("unread", ordering_error("sort-object-payload")),
    ]),
  ])
  let sorted = sort_demand_call(
    rows,
    Some(make_function(["p"], additive_select(sequence_var("p"), "key"))),
    true,
  )
  sequence_value(
    sequence_local(
      [("sorted", sorted)],
      ordering_array([
        additive_select(make_index(sequence_var("sorted"), 0), "id"),
        additive_select(make_index(sequence_var("sorted"), 1), "id"),
        additive_select(make_index(sequence_var("sorted"), 2), "id"),
      ]),
    ),
    ["b", "a", "c"],
  )
  let original = ordering_array([
    sequence_num(3),
    sequence_num(1),
    sequence_num(2),
  ])
  sequence_value(
    sequence_local(
      [("a", original)],
      ordering_array([
        sort_demand_call(sequence_var("a"), None, false),
        sequence_var("a"),
      ]),
    ),
    [[1, 2, 3], [3, 1, 2]],
  )
}

///|
test "sort required keys payloads and selected singleton values propagate isolated errors" {
  let two = ordering_array([sequence_num(1), sequence_num(2)])
  sequence_failure(
    sort_demand_call(ordering_error("sort-required-array"), None, false),
    @moonjsonnet.Runtime,
    Some("sort-required-array"),
  )
  sequence_failure(
    sort_demand_call(two, Some(ordering_error("sort-required-key-head")), false),
    @moonjsonnet.Runtime,
    Some("sort-required-key-head"),
  )
  sequence_failure(
    sort_demand_call(
      two,
      Some(make_function(["p"], ordering_error("sort-required-key-body"))),
      true,
    ),
    @moonjsonnet.Runtime,
    Some("sort-required-key-body"),
  )
  sequence_failure(
    sort_demand_call(
      ordering_array([sequence_num(1), ordering_error("sort-required-element")]),
      None,
      false,
    ),
    @moonjsonnet.Runtime,
    Some("sort-required-element"),
  )
  sequence_failure(
    make_index(
      sort_demand_call(
        ordering_array([ordering_error("sort-selected-singleton")]),
        Some(ordering_error("sort-unused-key-head")),
        false,
      ),
      0,
    ),
    @moonjsonnet.Runtime,
    Some("sort-selected-singleton"),
  )
  for
    key in [
      ordering_leaf("null", Literal(Json::null())),
      sequence_num(7),
      make_function(["p"], reflect_bool(false)),
    ] {
    sequence_failure(
      sort_demand_call(two, Some(key), false),
      @moonjsonnet.Type,
      None,
    )
  }
}

///|
test "sort degenerate native gates demand only array shape until a result element is selected" {
  for handmade in [false, true] {
    for n in [0, 1] {
      let payload = rewrite_gate(reflect_string("element"), sequence_num(7))
      let items = ordering_array(if n == 0 { [] } else { [payload] })
      let key = rewrite_gate(
        reflect_string("key"),
        make_function(
          ["p"],
          rewrite_gate(reflect_string("body"), sequence_num(0)),
        ),
      )
      let value = sort_demand_call(
        rewrite_gate(reflect_string("array"), items),
        Some(key),
        true,
      )
      let counts : Map[String, Int32] = Map([])
      assert_eq(
        ordering_program(
          additive_probe_scope(sequence_call("length", [value])),
          handmade,
        ).evaluate(
          native_functions=rewrite_natives(counts),
          limits=sequence_limits(),
        ),
        Json::number(n.to_double()),
      )
      assert_eq(counts, Map([("array", 1)]))
      if n == 1 {
        let selected : Map[String, Int32] = Map([])
        assert_eq(
          ordering_program(additive_probe_scope(make_index(value, 0)), handmade).evaluate(
            native_functions=rewrite_natives(selected),
            limits=sequence_limits(),
          ),
          7,
        )
        assert_eq(selected, Map([("array", 1), ("element", 1)]))
      }
    }
    let key = rewrite_gate(
      reflect_string("key"),
      make_function(
        ["p"],
        rewrite_gate(reflect_string("body"), sequence_num(0)),
      ),
    )
    let two = ordering_array([
      rewrite_gate(reflect_string("element"), sequence_num(2)),
      rewrite_gate(reflect_string("element"), sequence_num(1)),
    ])
    let value = sort_demand_call(two, Some(key), false)
    let counts : Map[String, Int32] = Map([])
    assert_eq(
      ordering_program(
        additive_probe_scope(sequence_call("length", [value])),
        handmade,
      ).evaluate(
        native_functions=rewrite_natives(counts),
        limits=sequence_limits(),
      ),
      2,
    )
    assert_true(counts.get("key").unwrap_or(0) > 0)
    assert_true(counts.get("body").unwrap_or(0) > 0)
    assert_eq(counts.get("element").unwrap_or(0), 0)
  }
}

///|
test "sort call admission binding failures and skipped calls preserve their phases" {
  let gate = rewrite_gate(reflect_string("provided"), ordering_array([]))
  let bad : Array[Array[(String?, OrderingExpr)]] = [
    [],
    [(Some("xs"), gate)],
    [(None, gate), (Some("arr"), gate)],
    [(None, gate), (None, gate), (None, gate)],
    [(Some("keyF"), gate)],
  ]
  for args in bad {
    let value = rounding_apply("sort", args)
    for handmade in [false, true] {
      let counts : Map[String, Int32] = Map([])
      assert_eq(
        ordering_program(additive_probe_scope(ordering_unused(value)), handmade).evaluate(
          native_functions=rewrite_natives(counts),
          limits=sequence_limits(),
        ),
        42,
      )
      try
        ordering_program(additive_probe_scope(value), handmade).evaluate(
          native_functions=rewrite_natives(counts),
          limits=sequence_limits(),
        )
      catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
      } noraise {
        _ => fail("invalid sort binding admitted")
      }
      assert_eq(counts.length(), 0)
    }
  }
  let skipped = sort_demand_call(
    ordering_array([]),
    Some(ordering_error("sort-skipped-key")),
    false,
  )
  sequence_value(ordering_binary(reflect_bool(false), "&&", skipped), false)
  sequence_value(ordering_binary(reflect_bool(true), "||", skipped), true)
  pair_reject(
    sort_demand_call(
      ordering_array([]),
      Some(sequence_var("sort_missing_key")),
      false,
    ),
  )
  pair_reject(
    sort_demand_call(
      ordering_array([]),
      Some(make_function(["p"], sequence_var("sort_missing_body"))),
      false,
    ),
  )
}
