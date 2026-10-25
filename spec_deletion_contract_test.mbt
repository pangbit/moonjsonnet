// Frozen deletion-domain criteria: SPEC-DELETION-CONTRACT-2026-10-25.md.
// Both entry paths use literal expectations and independently handmade trees.

///|
fn deletion_number(source : String, value : Double) -> OrderingExpr {
  ordering_leaf(source, Literal(Json::number(value)))
}

///|
fn deletion_at(arr : OrderingExpr, index : OrderingExpr) -> OrderingExpr {
  sequence_call("removeAt", [arr, index])
}

///|
fn deletion_binding_reject(value : OrderingExpr) -> Unit raise {
  for handmade in [false, true] {
    assert_eq(
      ordering_program(ordering_unused(value), handmade).evaluate(
        limits=sequence_limits(),
      ),
      42,
    )
    try
      ordering_program(value, handmade).evaluate(limits=sequence_limits())
    catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Runtime)
        assert_true(d.message != "binding-must-skip")
      }
    } noraise {
      _ => fail("invalid deletion call was admitted")
    }
  }
}

///|
test "deletion signatures require two arguments and bind before argument demand" {
  let bad = ordering_error("binding-must-skip")
  for name in ["remove", "removeAt"] {
    let function = additive_select(sequence_var("std"), name)
    sequence_value(
      ordering_array([
        sequence_call("type", [function]),
        sequence_call("length", [function]),
      ]),
      ["function", 2],
    )
    for
      args in [
        [],
        [(None, bad)],
        [(Some("arr"), bad)],
        [(None, bad), (None, bad), (None, bad)],
        [(None, bad), (None, bad), (Some("unknown"), bad)],
        [(None, bad), (Some("arr"), bad)],
      ] {
      deletion_binding_reject(rounding_apply(name, args))
    }
  }
  sequence_value(
    rounding_apply("remove", [
      (None, ordering_array([sequence_num(1), sequence_num(2)])),
      (Some("elem"), sequence_num(1)),
    ]),
    [2],
  )
}

///|
test "remove handles singleton targets and literal primitive container equality domains" {
  let nil = ordering_leaf("null", Literal(Json::null()))
  let text = reflect_string("😀e\u0301")
  let nested = ordering_array([sequence_num(1), sequence_num(2)])
  let object = reflect_object([
    (reflect_string("é"), 1, sequence_num(3)),
    (reflect_string("hidden"), 2, ordering_error("unread-hidden")),
  ])
  for target in [nil, reflect_bool(true), sequence_num(7), text, nested, object] {
    sequence_value(remove_search_call(ordering_array([target]), target), [])
  }
  sequence_value(
    remove_search_call(
      ordering_array([reflect_bool(true), nil, sequence_num(1)]),
      nil,
    ),
    [true, 1],
  )
  sequence_value(
    remove_search_call(
      ordering_array([reflect_string("é"), reflect_string("e\u0301")]),
      reflect_string("é"),
    ),
    ["é"],
  )
}

///|
test "remove rejects every nonarray input in find before demanding its target" {
  for
    input in [
      ordering_leaf("null", Literal(Json::null())),
      reflect_bool(false),
      sequence_num(1),
      reflect_string("abc"),
      reflect_object([]),
      make_function([], ordering_error("uncalled-input-body")),
    ] {
    for handmade in [false, true] {
      let call = remove_search_call(input, ordering_error("target-must-skip"))
      try
        ordering_program(call, handmade).evaluate(limits=sequence_limits())
      catch {
        @moonjsonnet.Error(d) => {
          assert_eq(d.kind, @moonjsonnet.Runtime)
          assert_true(
            d.message.has_prefix(
              "find second parameter should be an array, got ",
            ),
          )
        }
      } noraise {
        _ => fail("remove admitted a nonarray instead of the fixed find guard")
      }
    }
  }
}

///|
test "removeAt deletes exactly each matching numeric position including negative zero" {
  let values = ordering_array([
    sequence_num(4),
    sequence_num(4),
    sequence_num(9),
  ])
  for
    (index, expected) in [
      (sequence_num(0), Json::array([4, 9])),
      (deletion_number("-0", -0.0), Json::array([4, 9])),
      (deletion_number("1.0", 1.0), Json::array([4, 9])),
      (sequence_num(2), Json::array([4, 4])),
    ] {
    sequence_value(deletion_at(values, index), expected)
  }
  sequence_value(
    deletion_at(ordering_array([sequence_num(7)]), sequence_num(0)),
    [],
  )
}

///|
test "removeAt empty ranges skip all index heads including errors" {
  for
    index in [
      ordering_error("empty-index-must-skip"),
      sequence_num(0),
      sequence_num(-1),
      deletion_number("0.5", 0.5),
      ordering_leaf("null", Literal(Json::null())),
      reflect_bool(true),
      reflect_string("0"),
      ordering_array([ordering_error("unread-index-item")]),
      reflect_object([
        (reflect_string("x"), 1, ordering_error("unread-index-field")),
      ]),
      make_function([], ordering_error("uncalled-index-body")),
    ] {
    let result = deletion_at(ordering_array([]), index)
    sequence_value(result, [])
    sequence_value(sequence_call("length", [result]), 0)
    sequence_value(sequence_call("type", [result]), "array")
  }
}

///|
test "removeAt unmatched finite numeric positions preserve all values without bounds conversion" {
  let values = ordering_array([sequence_num(3), sequence_num(5)])
  for
    index in [
      sequence_num(-1),
      sequence_num(2),
      sequence_num(3),
      deletion_number("0.5", 0.5),
      deletion_number("-0.5", -0.5),
      deletion_number("2147483648", 2147483648.0),
      deletion_number("1e308", 1.0e308),
      deletion_number("-1e308", -1.0e308),
    ] {
    sequence_value(deletion_at(values, index), [3, 5])
    sequence_value(
      sequence_call("length", [
        deletion_at(
          ordering_array([ordering_error("retained-head-unread")]),
          index,
        ),
      ]),
      1,
    )
  }
}

///|
test "removeAt compares index kinds without nested demand and requires only nonempty index heads" {
  for
    index in [
      ordering_leaf("null", Literal(Json::null())),
      reflect_bool(true),
      reflect_string("0"),
      ordering_array([ordering_error("index-payload-unread")]),
      reflect_object([
        (reflect_string("x"), 1, ordering_error("index-field-unread")),
      ]),
      make_function([], ordering_error("index-body-uncalled")),
    ] {
    sequence_value(
      deletion_at(ordering_array([sequence_num(3), sequence_num(5)]), index),
      [3, 5],
    )
  }
  sequence_failure(
    deletion_at(
      ordering_array([ordering_error("array-payload-unread")]),
      ordering_error("index-required"),
    ),
    @moonjsonnet.Runtime,
    Some("index-required"),
  )
  sequence_failure(
    deletion_at(
      ordering_array([sequence_num(1)]),
      ordering_binary(
        deletion_number("1e308", 1.0e308),
        "+",
        deletion_number("1e308", 1.0e308),
      ),
    ),
    @moonjsonnet.Runtime,
    None,
  )
}

///|
test "removeAt follows source length admission and defers retained indexing for nonarray values" {
  sequence_value(deletion_at(reflect_string("😀e\u0301"), sequence_num(1)), [
    "😀", "́",
  ])
  for
    input in [
      reflect_string(""),
      reflect_object([]),
      make_function([], ordering_error("uncalled-zero-parameter-body")),
    ] {
    sequence_value(deletion_at(input, ordering_error("empty-index-unread")), [])
  }
  for
    input in [
      reflect_object([
        (reflect_string("x"), 1, ordering_error("unread-object-value")),
      ]),
      make_function(["x"], ordering_error("uncalled-one-parameter-body")),
    ] {
    sequence_value(deletion_at(input, sequence_num(0)), [])
    let retained = deletion_at(input, sequence_num(1))
    sequence_value(sequence_call("type", [retained]), "array")
    sequence_value(sequence_call("length", [retained]), 1)
    sequence_failure(make_index(retained, 0), @moonjsonnet.Type, None)
  }
  for
    input in [
      ordering_leaf("null", Literal(Json::null())),
      reflect_bool(true),
      sequence_num(1),
    ] {
    sequence_failure(
      deletion_at(input, sequence_num(0)),
      @moonjsonnet.Type,
      None,
    )
  }
}

///|
test "deletion retains lazy values original aliases maps and returned closures" {
  let original = ordering_array([
    sequence_num(1),
    sequence_num(2),
    sequence_num(3),
  ])
  sequence_value(
    sequence_local(
      [
        ("a", original),
        (
          "mapped",
          sequence_call("map", [
            make_function(["x"], sequence_var("x")),
            sequence_var("a"),
          ]),
        ),
        ("removed", remove_search_call(sequence_var("a"), sequence_num(2))),
        ("again", deletion_at(sequence_var("removed"), sequence_num(0))),
      ],
      ordering_array([
        sequence_var("again"),
        sequence_var("removed"),
        sequence_var("mapped"),
        sequence_var("a"),
      ]),
    ),
    [[3], [1, 3], [1, 2, 3], [1, 2, 3]],
  )
  let kept = ordering_array([
    ordering_error("removed-unread"),
    make_function([], sequence_num(42)),
    reflect_object([
      (reflect_string("x"), 1, sequence_num(7)),
      (reflect_string("hidden"), 2, ordering_error("hidden-unread")),
    ]),
  ])
  let result = deletion_at(kept, sequence_num(0))
  sequence_value(sequence_call("length", [result]), 2)
  let closure = make_index(result, 0)
  let invoked : OrderingExpr = {
    source: "(" + closure.source + ")()",
    tree: ordering_ast(Call(closure.tree, [], false)),
  }
  sequence_value(invoked, 42)
  sequence_value(make_index(result, 1), { "x": 7 })
  sequence_failure(
    make_index(
      deletion_at(
        ordering_array([sequence_num(1), ordering_error("retained-required")]),
        sequence_num(0),
      ),
      0,
    ),
    @moonjsonnet.Runtime,
    Some("retained-required"),
  )
}
