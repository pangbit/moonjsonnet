// Static candidate only: not compiled or executed.
// Fixed public std.extVar(x); host maps supply values for lookup witnesses.
// Source and handmade AST cover the caller; ext_code remains host-provided text.
// No callback counts, diagnostics order, import policy or resource thresholds.

///|
fn external_contract_value(
  call : OrderingExpr,
  expected : Json,
  ext_vars~ : Map[String, Json] = Map([]),
  ext_code~ : Map[String, String] = Map([]),
) -> Unit raise {
  for handmade in [false, true] {
    assert_eq(
      ordering_program(call, handmade).evaluate(
        ext_vars~,
        ext_code~,
        limits=transfer_limits(),
      ),
      expected,
    )
  }
}

///|
fn external_contract_reject(
  call : OrderingExpr,
  ext_vars~ : Map[String, Json] = Map([]),
  ext_code~ : Map[String, String] = Map([]),
) -> Unit raise {
  for handmade in [false, true] {
    try
      ordering_program(call, handmade).evaluate(
        ext_vars~,
        ext_code~,
        limits=transfer_limits(),
      )
    catch {
      @moonjsonnet.Error(_) => ()
    } noraise {
      _ => fail("external lookup accepted an invalid or demanded failing input")
    }
  }
}

///|
test "EV1 extVar transfers configured literal data with exact names" {
  let cases : Array[(String, Json)] = [
    ("", Json::null()),
    ("boolean", true),
    ("number", 42),
    ("text", Json::string("é中😀\u{0000}")),
    ("array", [1, false, null]),
    ("object", { "answer": 42 }),
    ("é中😀", Json::string("Unicode key")),
    ("A", 1),
    ("a", 2),
  ]
  for (key, expected) in cases {
    external_contract_value(
      sequence_call("extVar", [reflect_string(key)]),
      expected,
      ext_vars=Map(cases),
    )
  }
}

///|
test "EV2 extVar uses required x through direct aliased and nested calls" {
  let ext_vars : Map[String, Json] = Map([("answer", 42)])
  let key = reflect_string("answer")
  let function = additive_select(sequence_var("std"), "extVar")
  transfer_value(sequence_call("length", [function]), 1)
  for label in [None, Some("x")] {
    let direct = rounding_apply("extVar", [(label, key)])
    let aliased = sequence_local(
      [("f", function)],
      shared_mode_call(sequence_var("f"), [(label, key)]),
    )
    for call in [direct, aliased] {
      external_contract_value(call, 42, ext_vars~)
      external_contract_value(
        sequence_call("type", [call]),
        "number",
        ext_vars~,
      )
    }
  }
  let invalid : Array[Array[(String?, OrderingExpr)]] = [
    [],
    [(None, key), (None, key)],
    [(Some("unknown"), key)],
    [(None, key), (Some("x"), key)],
    [(Some("x"), key), (Some("x"), key)],
  ]
  for args in invalid {
    external_contract_reject(rounding_apply("extVar", args), ext_vars~)
  }
}

///|
test "EV3 extVar rejects invalid names and demands only selected value heads" {
  let unread = ordering_error("external-unread")
  let wrong = [
    ordering_leaf("null", Literal(Json::null())),
    reflect_bool(true),
    reflect_bool(false),
    sequence_num(1),
    ordering_array([unread]),
    reflect_object([(reflect_string("field"), 1, unread)]),
    value_head_function(unread, unread),
    unread,
  ]
  for input in wrong {
    let call = sequence_call("extVar", [input])
    external_contract_reject(call)
    external_contract_reject(sequence_call("type", [call]))
  }
  for name in ["missing", ""] {
    external_contract_reject(sequence_call("extVar", [reflect_string(name)]))
  }
  let ext_code = Map([
    ("answer", "42"),
    ("forward", "std.extVar('answer')"),
    ("broken", "error 'external-required'"),
    ("array", "[error 'external-element']"),
    ("object", "{field:error 'external-field'}"),
    ("function", "function(x=error 'external-default') error 'external-body'"),
  ])
  external_contract_value(
    sequence_call("extVar", [reflect_string("forward")]),
    42,
    ext_code~,
  )
  let heads : Array[(String, String, Json)] = [
    ("array", "type", "array"),
    ("array", "length", 1),
    ("object", "type", "object"),
    ("object", "length", 1),
    ("function", "type", "function"),
    ("function", "length", 1),
  ]
  for (name, consumer, expected) in heads {
    external_contract_value(
      sequence_call(consumer, [sequence_call("extVar", [reflect_string(name)])]),
      expected,
      ext_code~,
    )
  }
  for name in ["broken", "array", "object"] {
    external_contract_reject(
      sequence_call("extVar", [reflect_string(name)]),
      ext_code~,
    )
  }
  external_contract_reject(
    value_head_call(sequence_call("extVar", [reflect_string("function")]), [
      sequence_num(1),
    ]),
    ext_code~,
  )
  external_contract_reject(
    sequence_call("type", [sequence_call("extVar", [reflect_string("broken")])]),
    ext_code~,
  )
  // Rejection alone does not establish skipped payloads or a winning error.
}

///|
test "EV4 extVar keeps unused calls lazy and configurations execution local" {
  let ext_code = Map([("broken", "error 'external-unused'")])
  for
    call in [
      sequence_call("extVar", [reflect_string("broken")]),
      sequence_call("extVar", [reflect_string("missing")]),
      sequence_call("extVar", [ordering_error("unused-name")]),
      rounding_apply("extVar", []),
    ] {
    external_contract_value(ordering_unused(call), 42, ext_code~)
    external_contract_value(
      transfer_if(reflect_bool(false), call, sequence_num(42)),
      42,
      ext_code~,
    )
    external_contract_value(
      ordering_binary(reflect_bool(false), "&&", call),
      false,
      ext_code~,
    )
    external_contract_value(
      value_head_call(make_function(["unused"], sequence_num(42)), [call]),
      42,
      ext_code~,
    )
  }
  let call = sequence_call("extVar", [reflect_string("answer")])
  for handmade in [false, true] {
    let program = ordering_program(call, handmade)
    for expected in [1, 42] {
      assert_eq(
        program.evaluate(
          ext_vars=Map([("answer", Json::number(expected.to_double()))]),
          limits=transfer_limits(),
        ),
        Json::number(expected.to_double()),
      )
    }
  }
  external_contract_value(
    sequence_local(
      [("original", sequence_call("extVar", [reflect_string("data")]))],
      ordering_array([sequence_var("original"), sequence_var("original")]),
    ),
    [[1, 2], [1, 2]],
    ext_vars=Map([("data", Json::array([1, 2]))]),
  )
}
