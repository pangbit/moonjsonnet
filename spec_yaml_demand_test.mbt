// Independent error/demand criteria: SPEC-YAML-DEMAND-2026-10-25.md.
// Stream end flags are explicit; defaults and assertion profiles are not adjudicated.

///|
fn yaml_demand_doc(
  value : OrderingExpr,
  indent : OrderingExpr,
  quote : OrderingExpr,
) -> OrderingExpr {
  rounding_apply("manifestYamlDoc", [
    (Some("quote_keys"), quote),
    (Some("value"), value),
    (Some("indent_array_in_object"), indent),
  ])
}

///|
fn yaml_demand_stream(
  value : OrderingExpr,
  indent : OrderingExpr,
  quote : OrderingExpr,
  ending : OrderingExpr,
) -> OrderingExpr {
  rounding_apply("manifestYamlStream", [
    (Some("quote_keys"), quote),
    (Some("value"), value),
    (Some("c_document_end"), ending),
    (Some("indent_array_in_object"), indent),
  ])
}

///|
test "YAML scalar empty and hidden only values never demand unused formatting options" {
  for
    (value, expected) in [
      (ordering_leaf("null", Literal(Json::null())), "null"),
      (reflect_bool(true), "true"),
      (sequence_num(1), "1"),
      (reflect_string("x"), "\"x\""),
      (ordering_array([]), "[]"),
      (reflect_object([]), "{}"),
      (
        reflect_object([
          (reflect_string("h"), 2, ordering_error("hidden-unused")),
        ]),
        "{}",
      ),
    ] {
    for
      (indent, quote) in [
        (ordering_error("unused-indent"), ordering_error("unused-quote")),
        (sequence_num(0), ordering_leaf("null", Literal(Json::null()))),
        (
          ordering_array([ordering_error("option-item-unused")]),
          make_function([], ordering_error("option-body-uncalled")),
        ),
      ] {
      sequence_value(
        yaml_demand_doc(value, indent, quote),
        Json::string(expected),
      )
    }
  }
}

///|
test "YAML visible keys demand quote options while scalar Object fields skip array indentation" {
  for
    (child, expected) in [
      (sequence_num(1), "\"key\": 1"),
      (ordering_array([]), "\"key\": []"),
      (
        reflect_object([
          (reflect_string("hidden"), 2, ordering_error("unread-field")),
        ]),
        "\"key\": {}",
      ),
      (
        reflect_object([(reflect_string("inner"), 1, sequence_num(1))]),
        "\"key\":\n  \"inner\": 1",
      ),
    ] {
    sequence_value(
      yaml_demand_doc(
        reflect_object([(reflect_string("key"), 1, child)]),
        ordering_error("indent-unused"),
        reflect_bool(true),
      ),
      Json::string(expected),
    )
  }
  let value = reflect_object([(reflect_string("key"), 1, sequence_num(1))])
  sequence_value(
    yaml_demand_doc(value, ordering_error("indent-unused"), reflect_bool(false)),
    "key: 1",
  )
  sequence_failure(
    sequence_call("type", [
      yaml_demand_doc(
        value,
        reflect_bool(false),
        ordering_error("quote-required"),
      ),
    ]),
    @moonjsonnet.Runtime,
    Some("quote-required"),
  )
  sequence_failure(
    yaml_demand_doc(value, ordering_error("indent-unused"), sequence_num(0)),
    @moonjsonnet.Type,
    None,
  )
}

///|
test "YAML array indentation is required only for nonempty Array fields at the actual depth" {
  let value = reflect_object([
    (
      reflect_string("key"),
      1,
      ordering_array([sequence_num(1), sequence_num(2)]),
    ),
  ])
  sequence_value(
    yaml_demand_doc(value, reflect_bool(false), reflect_bool(true)),
    "\"key\":\n- 1\n- 2",
  )
  sequence_value(
    yaml_demand_doc(value, reflect_bool(true), reflect_bool(true)),
    "\"key\":\n  - 1\n  - 2",
  )
  sequence_failure(
    yaml_demand_doc(
      value,
      ordering_error("indent-required"),
      reflect_bool(true),
    ),
    @moonjsonnet.Runtime,
    Some("indent-required"),
  )
  sequence_failure(
    yaml_demand_doc(value, sequence_num(0), reflect_bool(true)),
    @moonjsonnet.Type,
    None,
  )
  sequence_value(
    yaml_demand_doc(
      ordering_array([ordering_array([sequence_num(1)])]),
      ordering_error("unused-array-indent"),
      ordering_error("unused-array-quote"),
    ),
    "-\n  - 1",
  )
  sequence_failure(
    sequence_call("type", [
      yaml_demand_doc(
        ordering_array([value]),
        ordering_error("indent-required"),
        reflect_bool(true),
      ),
    ]),
    @moonjsonnet.Runtime,
    Some("indent-required"),
  )
}

///|
test "YAML streams pass lazy options to each document and require later Object options" {
  let empty = ordering_array([])
  let scalars = ordering_array([
    sequence_num(1),
    reflect_bool(true),
    ordering_array([]),
  ])
  let hidden = reflect_object([
    (reflect_string("h"), 2, ordering_error("hidden-document")),
  ])
  for ending in [false, true] {
    let suffix = if ending { "...\n" } else { "" }
    sequence_value(
      yaml_demand_stream(
        empty,
        ordering_error("unused-indent"),
        ordering_error("unused-quote"),
        reflect_bool(ending),
      ),
      Json::string("---\n\n" + suffix),
    )
    sequence_value(
      yaml_demand_stream(
        scalars,
        ordering_error("unused-indent"),
        ordering_error("unused-quote"),
        reflect_bool(ending),
      ),
      Json::string("---\n1\n---\ntrue\n---\n[]\n" + suffix),
    )
    sequence_value(
      yaml_demand_stream(
        ordering_array([reflect_object([]), hidden]),
        ordering_error("unused-indent"),
        ordering_error("unused-quote"),
        reflect_bool(ending),
      ),
      Json::string("---\n{}\n---\n{}\n" + suffix),
    )
    let object = reflect_object([(reflect_string("key"), 1, sequence_num(1))])
    sequence_failure(
      sequence_call("type", [
        yaml_demand_stream(
          ordering_array([sequence_num(1), object]),
          reflect_bool(false),
          ordering_error("later-quote-required"),
          reflect_bool(ending),
        ),
      ]),
      @moonjsonnet.Runtime,
      Some("later-quote-required"),
    )
    let nested = reflect_object([
      (reflect_string("key"), 1, ordering_array([sequence_num(1)])),
    ])
    sequence_failure(
      yaml_demand_stream(
        ordering_array([sequence_num(1), nested]),
        ordering_error("later-indent-required"),
        reflect_bool(true),
        reflect_bool(ending),
      ),
      @moonjsonnet.Runtime,
      Some("later-indent-required"),
    )
  }
}

///|
test "YAML rejects late visible failures and later documents without returning prefix text" {
  let good = reflect_object([(reflect_string("good"), 1, sequence_num(1))])
  let later = reflect_object([
    (
      reflect_string("later"),
      1,
      ordering_array([
        sequence_num(2),
        reflect_object([
          (reflect_string("bad"), 1, ordering_error("late-visible")),
        ]),
      ]),
    ),
  ])
  for ending in [false, true] {
    sequence_failure(
      sequence_call("type", [
        yaml_demand_stream(
          ordering_array([sequence_num(1), good, later]),
          reflect_bool(false),
          reflect_bool(true),
          reflect_bool(ending),
        ),
      ]),
      @moonjsonnet.Runtime,
      Some("late-visible"),
    )
    let wrong = sequence_call("length", [
      ordering_leaf("null", Literal(Json::null())),
    ])
    sequence_failure(
      yaml_demand_stream(
        ordering_array([good, ordering_array([wrong])]),
        reflect_bool(true),
        reflect_bool(false),
        reflect_bool(ending),
      ),
      @moonjsonnet.Type,
      None,
    )
    sequence_failure(
      yaml_demand_stream(
        ordering_array([
          good,
          ordering_array([
            make_function([], ordering_error("uncalled-function-body")),
          ]),
        ]),
        reflect_bool(false),
        reflect_bool(true),
        reflect_bool(ending),
      ),
      @moonjsonnet.Runtime,
      None,
    )
  }
}

///|
test "YAML assertion checks follow actual flat visible reads rather than blanket manifestation" {
  for
    condition in [
      reflect_bool(false),
      ordering_error("unused-condition"),
      sequence_num(1),
    ] {
    let empty = assertion_paths_object(
      [("h", 2, ordering_error("hidden-unused"))],
      condition,
      Some(ordering_error("unused-message")),
    )
    sequence_value(
      yaml_demand_doc(empty, reflect_bool(false), reflect_bool(true)),
      "{}",
    )
    sequence_value(
      yaml_demand_doc(
        reflect_object([(reflect_string("outer"), 1, empty)]),
        reflect_bool(false),
        reflect_bool(true),
      ),
      "\"outer\": {}",
    )
    sequence_value(
      yaml_demand_stream(
        ordering_array([empty]),
        reflect_bool(false),
        reflect_bool(true),
        reflect_bool(false),
      ),
      "---\n{}\n",
    )
  }
  let visible = [("v", 1, sequence_num(1))]
  for
    (condition, kind, marker) in [
      (reflect_bool(false), @moonjsonnet.Assertion, None),
      (sequence_num(1), @moonjsonnet.Type, None),
      (
        ordering_error("condition-required"),
        @moonjsonnet.Runtime,
        Some("condition-required"),
      ),
    ] {
    sequence_failure(
      yaml_demand_doc(
        assertion_paths_object(visible, condition, None),
        reflect_bool(false),
        reflect_bool(true),
      ),
      kind,
      marker,
    )
  }
  sequence_failure(
    yaml_demand_doc(
      assertion_paths_object(
        visible,
        reflect_bool(false),
        Some(ordering_error("message-required")),
      ),
      reflect_bool(false),
      reflect_bool(true),
    ),
    @moonjsonnet.Runtime,
    Some("message-required"),
  )
  sequence_value(
    yaml_demand_doc(
      assertion_paths_object(
        visible,
        reflect_bool(true),
        Some(ordering_error("message-unused")),
      ),
      reflect_bool(false),
      reflect_bool(true),
    ),
    "\"v\": 1",
  )
  let hidden = reflect_object([
    (reflect_string("a"), 1, sequence_num(1)),
    (reflect_string("cycle"), 2, assertion_paths_loop()),
    (reflect_string("fn"), 2, make_function([], ordering_error("body-unused"))),
  ])
  sequence_value(
    yaml_demand_doc(hidden, reflect_bool(false), reflect_bool(true)),
    "\"a\": 1",
  )
}

///|
test "YAML binding stream input and explicit end marker errors do not force unrelated options" {
  for (name, size) in [("manifestYamlDoc", 3), ("manifestYamlStream", 4)] {
    sequence_value(
      sequence_call("length", [additive_select(sequence_var("std"), name)]),
      Json::number(size.to_double()),
    )
    let bad = ordering_error("binding-must-skip")
    deletion_binding_reject(rounding_apply(name, []))
    deletion_binding_reject(rounding_apply(name, [(Some("unknown"), bad)]))
    deletion_binding_reject(
      rounding_apply(name, [(None, bad), (Some("value"), bad)]),
    )
  }
  for
    input in [
      ordering_leaf("null", Literal(Json::null())),
      reflect_bool(true),
      sequence_num(1),
      reflect_string("x"),
      reflect_object([]),
      make_function([], ordering_error("body-unused")),
    ] {
    for handmade in [false, true] {
      let call = yaml_demand_stream(
        input,
        ordering_error("unused-indent"),
        ordering_error("unused-quote"),
        ordering_error("unused-end"),
      )
      try
        ordering_program(call, handmade).evaluate(limits=sequence_limits())
      catch {
        @moonjsonnet.Error(d) => {
          assert_eq(d.kind, @moonjsonnet.Runtime)
          assert_true(
            d.message.has_prefix("manifestYamlStream only takes arrays, got "),
          )
        }
      } noraise {
        _ => fail("stream accepted a nonarray")
      }
    }
  }
  sequence_failure(
    yaml_demand_stream(
      ordering_array([]),
      ordering_error("unused-indent"),
      ordering_error("unused-quote"),
      ordering_error("end-required"),
    ),
    @moonjsonnet.Runtime,
    Some("end-required"),
  )
  sequence_failure(
    yaml_demand_stream(
      ordering_array([]),
      ordering_error("unused-indent"),
      ordering_error("unused-quote"),
      sequence_num(0),
    ),
    @moonjsonnet.Type,
    None,
  )
}
