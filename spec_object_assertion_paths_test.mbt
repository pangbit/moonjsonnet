// Shared assertion-domain criteria and profile qualifications:
// SPEC-OBJECT-ASSERTION-ADJUDICATION-2026-10-22.md.
// Cases0-4 have independent agreed expectations. Cases5-6 are explicitly
// conditional operational profiles; they are not N0/R0 normative evidence.

///|
fn assertion_paths_object(
  fields : Array[(String, Int, OrderingExpr)],
  condition : OrderingExpr,
  message : OrderingExpr?,
) -> OrderingExpr {
  let parts = fields.map(f => {
    let separator = match f.1 {
      2 => "::"
      3 => ":::"
      _ => ":"
    }
    Json::string(f.0).stringify() + separator + "(" + f.2.source + ")"
  })
  {
    source: "{assert (" +
    condition.source +
    ")" +
    (match message {
      Some(m) => ":(" + m.source + ")"
      None => ""
    }) +
    (if parts.is_empty() { "" } else { "," + parts.join(",") }) +
    "}",
    tree: ordering_ast(
      Obj(
        fields.map(f => {
          key: reflect_string(f.0).tree,
          value: f.2.tree,
          visibility: f.1,
          additive: false,
        }),
        [],
        [(condition.tree, message.map(m => m.tree))],
      ),
    ),
  }
}

///|
fn assertion_paths_compact(value : OrderingExpr) -> OrderingExpr {
  sequence_call("manifestJsonEx", [
    value,
    reflect_string(""),
    reflect_string(""),
    reflect_string(":"),
  ])
}

///|
fn assertion_paths_loop() -> OrderingExpr {
  sequence_local([("loop", sequence_var("loop"))], sequence_var("loop"))
}

///|
fn assertion_paths_no_value(value : OrderingExpr) -> Unit raise {
  for handmade in [false, true] {
    assert_eq(
      ordering_program(ordering_unused(value), handmade).evaluate(
        limits=conjunction_limits(),
      ),
      42,
    )
    let program = ordering_program(value, handmade)
    try program.evaluate(limits=conjunction_limits()) catch {
      @moonjsonnet.Error(d) =>
        // Bounded rejection, not a standardized error label or loop detector.
        assert_true(
          d.kind == @moonjsonnet.Runtime || d.kind == @moonjsonnet.Limit,
        )
    } noraise {
      _ => fail("a genuinely demanded cycle cannot yield a finite JSON value")
    }
  }
}

///|
test "agreed assertion paths leave conditions dormant under reflection and unused values" {
  for
    condition in [
      reflect_bool(false),
      ordering_error("unused-condition"),
      sequence_num(1),
    ] {
    let input = assertion_paths_object(
      [
        ("h", 2, ordering_error("hidden-value")),
        ("v", 1, ordering_error("visible-value")),
      ],
      condition,
      Some(ordering_error("unused-message")),
    )
    sequence_value(
      ordering_array([
        sequence_call("type", [input]),
        sequence_call("length", [input]),
        sequence_call("objectFields", [input]),
        sequence_call("objectFieldsAll", [input]),
        sequence_call("length", [ordering_array([input])]),
        ordering_unused(additive_select(input, "v")),
        reflect_object([(reflect_string("nested"), 2, input)]),
      ]),
      ["object", 1, ["v"], ["h", "v"], 1, 42, Json::object(Map([]))],
    )
  }
}

///|
test "agreed core manifestation checks empty hidden nested and inherited assertions" {
  let empty_false = assertion_paths_object([], reflect_bool(false), None)
  let hidden_false = assertion_paths_object(
    [("h", 2, ordering_error("hidden-payload"))],
    reflect_bool(false),
    None,
  )
  let visible_false = assertion_paths_object(
    [("v", 1, sequence_num(7))],
    reflect_bool(false),
    None,
  )
  for
    input in [
      empty_false,
      hidden_false,
      visible_false,
      reflect_object([(reflect_string("outer"), 1, empty_false)]),
      ordering_array([empty_false]),
    ] {
    sequence_failure(input, @moonjsonnet.Assertion, None)
  }
  sequence_value(
    assertion_paths_object([], reflect_bool(true), None),
    Json::object(Map([])),
  )
  sequence_value(
    assertion_paths_object(
      [("h", 2, ordering_error("hidden-payload"))],
      reflect_bool(true),
      None,
    ),
    Json::object(Map([])),
  )
  for (left, right) in [(false, true), (true, false), (false, false)] {
    let merged = ordering_binary(
      assertion_paths_object([], reflect_bool(left), None),
      "+",
      assertion_paths_object([], reflect_bool(right), None),
    )
    sequence_failure(merged, @moonjsonnet.Assertion, None)
    sequence_failure(
      additive_select(
        ordering_binary(
          merged,
          "+",
          reflect_object([(reflect_string("v"), 1, sequence_num(7))]),
        ),
        "v",
      ),
      @moonjsonnet.Assertion,
      None,
    )
  }
  sequence_value(
    ordering_binary(
      assertion_paths_object(
        [("h", 2, ordering_error("unread-inherited-hidden"))],
        reflect_bool(true),
        None,
      ),
      "+",
      assertion_paths_object([], reflect_bool(true), None),
    ),
    Json::object(Map([])),
  )
}

///|
test "agreed field assertion gates preserve messages and constant condition inheritance" {
  for visibility in [1, 2] {
    let valid = assertion_paths_object(
      [("v", visibility, sequence_num(7))],
      reflect_bool(true),
      Some(assertion_paths_loop()),
    )
    sequence_value(additive_select(valid, "v"), 7)
    let invalid = assertion_paths_object(
      [("v", visibility, sequence_num(7))],
      reflect_bool(false),
      None,
    )
    sequence_failure(
      additive_select(invalid, "v"),
      @moonjsonnet.Assertion,
      None,
    )
  }
  for
    (condition, message, kind, marker) in [
      (sequence_num(1), None, @moonjsonnet.Type, None),
      (
        ordering_error("condition-required"),
        None,
        @moonjsonnet.Runtime,
        Some("condition-required"),
      ),
      (
        reflect_bool(false),
        Some(ordering_error("message-required")),
        @moonjsonnet.Runtime,
        Some("message-required"),
      ),
    ] {
    let input = assertion_paths_object(
      [("v", 1, sequence_num(7))],
      condition,
      message,
    )
    sequence_failure(additive_select(input, "v"), kind, marker)
  }
  // One overlapping field avoids the printed right-only prefix omission.
  sequence_value(
    additive_select(
      ordering_binary(
        assertion_paths_object(
          [("x", 1, reflect_bool(true))],
          reflect_bool(true),
          None,
        ),
        "+",
        assertion_paths_object(
          [("x", 1, additive_select(sequence_var("super"), "x"))],
          reflect_bool(true),
          None,
        ),
      ),
      "x",
    ),
    true,
  )
  sequence_value(
    additive_select(
      ordering_binary(
        assertion_paths_object(
          [
            ("x", 1, sequence_num(1)),
            ("y", 1, additive_select(sequence_var("self"), "x")),
          ],
          reflect_bool(true),
          None,
        ),
        "+",
        assertion_paths_object(
          [("x", 1, sequence_num(2))],
          reflect_bool(true),
          None,
        ),
      ),
      "y",
    ),
    2,
  )
}

///|
test "agreed JSON library traversal differs from recursive core manifestation" {
  let empty = assertion_paths_object([], reflect_bool(false), None)
  let hidden = assertion_paths_object(
    [("h", 2, ordering_error("unread-hidden"))],
    reflect_bool(false),
    None,
  )
  for input in [empty, hidden] {
    sequence_value(assertion_paths_compact(input), "{}")
    sequence_value(sequence_call("manifestJson", [input]), "{\n\n}")
  }
  sequence_value(
    assertion_paths_compact(
      reflect_object([(reflect_string("outer"), 1, empty)]),
    ),
    "{\"outer\":{}}",
  )
  sequence_value(assertion_paths_compact(ordering_array([empty])), "[{}]")
  let visible = assertion_paths_object(
    [("v", 1, sequence_num(7))],
    reflect_bool(false),
    None,
  )
  sequence_failure(
    assertion_paths_compact(visible),
    @moonjsonnet.Assertion,
    None,
  )
  sequence_failure(
    sequence_call("manifestJson", [visible]),
    @moonjsonnet.Assertion,
    None,
  )
}

///|
test "agreed genuine cycles reject only when their field or condition is required" {
  let cyclic_field = assertion_paths_object(
    [("loop", 2, additive_select(sequence_var("self"), "loop"))],
    reflect_bool(true),
    None,
  )
  sequence_value(cyclic_field, Json::object(Map([])))
  sequence_value(assertion_paths_compact(cyclic_field), "{}")
  assertion_paths_no_value(additive_select(cyclic_field, "loop"))
  let cyclic_condition = assertion_paths_object(
    [("v", 1, sequence_num(7))],
    assertion_paths_loop(),
    None,
  )
  sequence_value(sequence_call("type", [cyclic_condition]), "object")
  assertion_paths_no_value(additive_select(cyclic_condition, "v"))
  assertion_paths_no_value(cyclic_condition)
  let hidden_condition = assertion_paths_object(
    [("h", 2, sequence_num(7))],
    assertion_paths_loop(),
    None,
  )
  sequence_value(assertion_paths_compact(hidden_condition), "{}")
  assertion_paths_no_value(hidden_condition)
  let acyclic = additive_select(
    reflect_object([
      (reflect_string("x"), 1, sequence_num(1)),
      (reflect_string("y"), 1, additive_select(sequence_var("self"), "x")),
    ]),
    "y",
  )
  for handmade in [false, true] {
    assert_eq(
      ordering_program(acyclic, handmade).evaluate(limits=conjunction_limits()),
      1,
    )
  }
}

///|
test "N0 conditional layer prefix profile is not a literal formal rule verdict" {
  // The guide promises this new field's lower prefix. The printed formula
  // leaves it unchanged and later replaces super by {}, so both cannot hold.
  let field_control = additive_select(
    ordering_binary(
      reflect_object([(reflect_string("x"), 1, reflect_bool(true))]),
      "+",
      reflect_object([
        (reflect_string("v"), 1, additive_select(sequence_var("super"), "x")),
      ]),
    ),
    "v",
  )
  sequence_value(field_control, true)
  // For assertions the guide itself leaves exact prefix scope unfinished.
  let assertion = additive_select(
    ordering_binary(
      reflect_object([(reflect_string("ok"), 1, reflect_bool(true))]),
      "+",
      assertion_paths_object(
        [("v", 1, sequence_num(1))],
        additive_select(sequence_var("super"), "ok"),
        None,
      ),
    ),
    "v",
  )
  sequence_value(assertion, 1)
}

///|
test "R0 conditional active check profile is not a finite state free derivation" {
  let input = assertion_paths_object(
    [("ok", 1, reflect_bool(true)), ("v", 1, sequence_num(1))],
    additive_select(sequence_var("self"), "ok"),
    None,
  )
  sequence_value(
    sequence_local([("o", input)], additive_select(sequence_var("o"), "v")),
    1,
  )
  let base = assertion_paths_object(
    [("ok", 1, reflect_bool(false)), ("v", 1, sequence_num(1))],
    additive_select(sequence_var("self"), "ok"),
    None,
  )
  for valid in [false, true] {
    let derived = ordering_binary(
      base,
      "+",
      reflect_object([(reflect_string("ok"), 1, reflect_bool(valid))]),
    )
    let selected = additive_select(derived, "v")
    sequence_value(sequence_call("type", [derived]), "object")
    if valid {
      sequence_value(selected, 1)
    } else {
      sequence_failure(selected, @moonjsonnet.Assertion, None)
    }
  }
  let real_cycle = assertion_paths_object(
    [
      ("ok", 1, additive_select(sequence_var("self"), "ok")),
      ("v", 1, sequence_num(1)),
    ],
    additive_select(sequence_var("self"), "ok"),
    None,
  )
  assertion_paths_no_value(additive_select(real_cycle, "v"))
}
