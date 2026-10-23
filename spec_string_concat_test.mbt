// Frozen oracle: SPEC-STRING-CONCAT-2026-10-22.md.
// Source strings and public ASTs share neutral builders, never parsed trees.

///|
fn concat_json(
  value : OrderingExpr,
  expected : Json,
  single_line? : Bool = true,
) -> Unit raise {
  for handmade in [false, true] {
    guard ordering_program(value, handmade).evaluate(limits=sequence_limits())
      is String(text) else {
      fail("conversion did not yield a String")
    }
    if single_line {
      assert_true(!text.contains("\n") && !text.contains("\r"))
    }
    // Host JSON parsing admits legal spelling/spacing; no formatter output
    // or product std.parseJson result supplies the expected JSON value.
    assert_eq(@json.parse(text), expected)
  }
}

///|
fn concat_json_sides(value : OrderingExpr, expected : Json) -> Unit raise {
  let empty = reflect_string("")
  concat_json(ordering_binary(empty, "+", value), expected)
  concat_json(ordering_binary(value, "+", empty), expected)
  concat_json(sequence_call("toString", [value]), expected)
}

///|
fn concat_assert_object(
  fields : Array[(OrderingExpr, Int, OrderingExpr)],
  condition : OrderingExpr,
  message : OrderingExpr?,
) -> OrderingExpr {
  let plain = reflect_object(fields)
  let (fs, locals) = match plain.tree.kind {
    Obj(fs, locals, _) => (fs, locals)
    _ => abort("neutral object builder did not build Obj")
  }
  {
    source: "{assert (" +
    condition.source +
    ")" +
    (match message {
      Some(m) => ":(" + m.source + ")"
      None => ""
    }) +
    "," +
    plain.source[1:].to_owned(),
    tree: ordering_ast(
      Obj(fs, locals, [(condition.tree, message.map(m => m.tree))]),
    ),
  }
}

///|
test "string concatenation preserves String contents rather than JSON quoting" {
  let raw = "😀e\u0301\u0000\n\"\\"
  for
    (left, right, expected) in [
      ("", "", ""),
      ("", raw, raw),
      (raw, "", raw),
      ("left:", raw, "left:" + raw),
      (raw, ":right", raw + ":right"),
    ] {
    sequence_value(
      ordering_binary(reflect_string(left), "+", reflect_string(right)),
      Json::string(expected),
    )
  }
  sequence_value(
    sequence_call("toString", [reflect_string(raw)]),
    Json::string(raw),
  )
  // Public manifestJson quotes a String; implicit tostring leaves it intact.
  sequence_value(sequence_call("manifestJson", [reflect_string("A")]), "\"A\"")
}

///|
test "non String concatenation manifests JSON and omits hidden inherited payloads" {
  for
    (value, expected) in [
      (ordering_leaf("null", Literal(Json::null())), Json::null()),
      (reflect_bool(false), Json::boolean(false)),
      (reflect_bool(true), Json::boolean(true)),
      (sequence_num(7), Json::number(7)),
      (ordering_array([]), Json::array([])),
      (reflect_object([]), Json::object(Map([]))),
      (
        ordering_array([sequence_num(7), reflect_string("line\n\"\\😀")]),
        Json::array([7, "line\n\"\\😀"]),
      ),
    ] {
    concat_json_sides(value, expected)
  }
  let hidden_function = ordering_leaf(
    "function() error 'hidden-function-body'",
    Func([], ordering_error("hidden-function-body").tree),
  )
  let nested = reflect_object([
    (reflect_string("keep"), 1, sequence_num(1)),
    (reflect_string("h"), 2, hidden_function),
  ])
  concat_json_sides(
    reflect_object([
      (reflect_string("h"), 2, ordering_error("hidden-value")),
      (reflect_string("visible"), 1, nested),
    ]),
    { "visible": { "keep": 1 } },
  )
  concat_json_sides(
    ordering_binary(
      reflect_object([
        (reflect_string("x"), 1, ordering_error("overridden-value")),
        (reflect_string("h"), 2, ordering_error("overridden-hidden")),
      ]),
      "+",
      reflect_object([
        (reflect_string("x"), 1, sequence_num(7)),
        (reflect_string("h"), 3, sequence_num(9)),
      ]),
    ),
    { "x": 7, "h": 9 },
  )
}

///|
test "string conversion is strict at its demanded boundary and rejects functions or overflow" {
  let nested_error = reflect_object([
    (
      reflect_string("x"),
      1,
      ordering_array([ordering_error("visible-payload")]),
    ),
  ])
  let function = ordering_leaf(
    "function() error 'function-body-unread'",
    Func([], ordering_error("function-body-unread").tree),
  )
  let large = ordering_leaf("1e308", Literal(Json::number(1.0e308)))
  for
    (value, kind, marker) in [
      (
        ordering_error("required-head"),
        @moonjsonnet.Runtime,
        Some("required-head"),
      ),
      (nested_error, @moonjsonnet.Runtime, Some("visible-payload")),
      (function, @moonjsonnet.Type, None),
      (ordering_array([function]), @moonjsonnet.Type, None),
      (ordering_binary(large, "*", large), @moonjsonnet.Runtime, None),
    ] {
    for
      conversion in [
        ordering_binary(reflect_string(""), "+", value),
        ordering_binary(value, "+", reflect_string("")),
        sequence_call("toString", [value]),
      ] {
      // Observing only the tag still needs the entire strict String value.
      // sequence_failure also proves that ignoring the whole call stays lazy.
      sequence_failure(sequence_call("type", [conversion]), kind, marker)
    }
  }
}

///|
test "implicit manifestation checks assertions while library JSON and statics keep separate boundaries" {
  let empty_bad = concat_assert_object([], reflect_bool(false), None)
  let hidden_bad = concat_assert_object(
    [(reflect_string("h"), 2, ordering_error("hidden-value"))],
    reflect_bool(false),
    None,
  )
  for value in [empty_bad, hidden_bad, ordering_array([empty_bad])] {
    for
      conversion in [
        ordering_binary(reflect_string(""), "+", value),
        ordering_binary(value, "+", reflect_string("")),
        sequence_call("toString", [value]),
      ] {
      sequence_failure(
        sequence_call("type", [conversion]),
        @moonjsonnet.Assertion,
        None,
      )
    }
  }
  concat_json(
    sequence_call("manifestJson", [empty_bad]),
    Json::object(Map([])),
    single_line=false,
  )
  concat_json_sides(
    concat_assert_object(
      [(reflect_string("x"), 1, sequence_num(7))],
      reflect_bool(true),
      Some(ordering_error("unused-assert-message")),
    ),
    { "x": 7 },
  )
  let invalid = reflect_object([
    (reflect_string("h"), 2, sequence_var("concat_missing")),
  ])
  for handmade in [false, true] {
    try
      ordering_program(
        ordering_unused(ordering_binary(reflect_string(""), "+", invalid)),
        handmade,
      )
    catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
    } noraise {
      _ => fail("unused hidden concat payload escaped static checking")
    }
  }
}
