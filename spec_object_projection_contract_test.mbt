// Fixed std.jsonnet 289-295 and 1573-1580; independent source/handmade trees.
// Pair normal-value oracles stay in the Object-valued public/source common domain.
// The public value(object) annotation versus unrestricted o[k] is not adjudicated.
// Visibility/index/application children are premises; no inherited assertion oracle.

///|
fn projection_box(n : Int32) -> OrderingExpr {
  reflect_object([(reflect_string("n"), 1, sequence_num(n))])
}

///|
fn projection_value_at(
  name : String,
  result : OrderingExpr,
  index : Int32,
) -> OrderingExpr {
  let item = make_index(result, index)
  if name == "objectValuesAll" {
    item
  } else {
    additive_select(item, "value")
  }
}

///|
fn projection_map(func : OrderingExpr, obj : OrderingExpr) -> OrderingExpr {
  sequence_call("mapWithKey", [func, obj])
}

///|
test "OP1 object projections retain literal key order visibility and pair shape" {
  let original = reflect_object([
    (reflect_string("😀"), 1, projection_box(15)),
    (reflect_string("a"), 2, projection_box(13)),
    (reflect_string("é"), 3, projection_box(14)),
    (reflect_string("A"), 1, projection_box(12)),
    (reflect_string("\u0000"), 1, projection_box(11)),
    (reflect_string(""), 1, projection_box(10)),
  ])
  transfer_value(sequence_call("objectValuesAll", [original]), [
    { "n": 10 },
    { "n": 11 },
    { "n": 12 },
    { "n": 13 },
    { "n": 14 },
    { "n": 15 },
  ])
  transfer_value(sequence_call("objectKeysValues", [original]), [
    { "key": "", "value": { "n": 10 } },
    { "key": "\u0000", "value": { "n": 11 } },
    { "key": "A", "value": { "n": 12 } },
    { "key": "é", "value": { "n": 14 } },
    { "key": "😀", "value": { "n": 15 } },
  ])
  transfer_value(sequence_call("objectKeysValuesAll", [original]), [
    { "key": "", "value": { "n": 10 } },
    { "key": "\u0000", "value": { "n": 11 } },
    { "key": "A", "value": { "n": 12 } },
    { "key": "a", "value": { "n": 13 } },
    { "key": "é", "value": { "n": 14 } },
    { "key": "😀", "value": { "n": 15 } },
  ])
  let mapped = projection_map(
    make_function(
      ["k", "v"],
      ordering_array([
        sequence_var("k"),
        additive_select(sequence_var("v"), "n"),
      ]),
    ),
    original,
  )
  transfer_value(mapped, {
    "": ["", 10],
    "\u0000": ["\u0000", 11],
    "A": ["A", 12],
    "é": ["é", 14],
    "😀": ["😀", 15],
  })
  transfer_value(sequence_call("objectFieldsAll", [mapped]), [
    "", "\u0000", "A", "é", "😀",
  ])
}

///|
test "OP2 projection visibility follows input inheritance while mapped fields are regular" {
  let original = ordering_binary(
    reflect_object([
      (reflect_string("a"), 2, projection_box(1)),
      (reflect_string("b"), 2, projection_box(2)),
      (reflect_string("c"), 1, projection_box(3)),
    ]),
    "+",
    reflect_object([
      (reflect_string("a"), 1, projection_box(10)),
      (reflect_string("b"), 3, projection_box(20)),
      (reflect_string("c"), 2, projection_box(30)),
      (reflect_string("d"), 1, projection_box(40)),
    ]),
  )
  transfer_value(sequence_call("objectValuesAll", [original]), [
    { "n": 10 },
    { "n": 20 },
    { "n": 30 },
    { "n": 40 },
  ])
  transfer_value(sequence_call("objectKeysValues", [original]), [
    { "key": "b", "value": { "n": 20 } },
    { "key": "d", "value": { "n": 40 } },
  ])
  transfer_value(sequence_call("objectKeysValuesAll", [original]), [
    { "key": "a", "value": { "n": 10 } },
    { "key": "b", "value": { "n": 20 } },
    { "key": "c", "value": { "n": 30 } },
    { "key": "d", "value": { "n": 40 } },
  ])
  let mapped = projection_map(
    make_function(["k", "v"], sequence_var("v")),
    original,
  )
  transfer_value(sequence_call("objectFieldsAll", [mapped]), ["b", "d"])
  let hidden_base = reflect_object([
    (reflect_string("b"), 2, projection_box(99)),
  ])
  let overlay = ordering_binary(hidden_base, "+", mapped)
  transfer_value(sequence_call("objectFields", [overlay]), ["d"])
  transfer_value(additive_select(additive_select(overlay, "b"), "n"), 20)
  for name in ["objectValuesAll", "objectKeysValues", "objectKeysValuesAll"] {
    transfer_value(sequence_call(name, [reflect_object([])]), [])
  }
  let hidden = reflect_object([(reflect_string("h"), 2, projection_box(7))])
  transfer_value(sequence_call("objectValuesAll", [hidden]), [{ "n": 7 }])
  transfer_value(sequence_call("objectKeysValues", [hidden]), [])
  transfer_value(sequence_call("objectKeysValuesAll", [hidden]), [
    { "key": "h", "value": { "n": 7 } },
  ])
}

///|
test "OP3 projection shapes and pair keys defer original values and nested payloads" {
  let original = reflect_object([
    (reflect_string("a"), 1, ordering_error("projection-value")),
    (reflect_string("b"), 1, projection_box(8)),
    (reflect_string("h"), 2, ordering_error("projection-hidden")),
  ])
  for name in ["objectValuesAll", "objectKeysValues", "objectKeysValuesAll"] {
    let result = sequence_call(name, [original])
    transfer_value(
      sequence_call("length", [result]),
      if name == "objectKeysValues" {
        2
      } else {
        3
      },
    )
    transfer_value(projection_value_at(name, result, 1), { "n": 8 })
    transfer_error(projection_value_at(name, result, 0), "projection-value")
    if name != "objectValuesAll" {
      transfer_value(additive_select(make_index(result, 0), "key"), "a")
      transfer_value(
        sequence_call("objectFieldsAll", [make_index(result, 0)]),
        ["key", "value"],
      )
    }
    if name != "objectKeysValues" {
      transfer_error(projection_value_at(name, result, 2), "projection-hidden")
    }
  }
  let nested = reflect_object([
    (
      reflect_string("a"),
      1,
      reflect_object([
        (reflect_string("safe"), 1, sequence_num(9)),
        (reflect_string("bad"), 1, ordering_error("nested-payload")),
      ]),
    ),
  ])
  for name in ["objectValuesAll", "objectKeysValues", "objectKeysValuesAll"] {
    let value = projection_value_at(name, sequence_call(name, [nested]), 0)
    transfer_value(additive_select(value, "safe"), 9)
    transfer_error(additive_select(value, "bad"), "nested-payload")
  }
  let varied = reflect_object([
    (reflect_string("a"), 1, ordering_leaf("null", Literal(Json::null()))),
    (reflect_string("b"), 1, reflect_bool(false)),
    (reflect_string("c"), 1, reflect_string("x")),
    (reflect_string("d"), 1, ordering_array([sequence_num(1)])),
  ])
  transfer_value(sequence_call("objectValuesAll", [varied]), [
    null,
    false,
    "x",
    [1],
  ])
  let function = make_function([], sequence_num(7))
  transfer_value(
    value_head_call(
      make_index(
        sequence_call("objectValuesAll", [
          reflect_object([(reflect_string("a"), 1, function)]),
        ]),
        0,
      ),
      [],
    ),
    7,
  )
}

///|
test "OP4 mapWithKey defers callback arity bodies and ignored original values" {
  let hidden = reflect_object([
    (reflect_string("h"), 2, ordering_error("unused-hidden")),
  ])
  let nonempty = reflect_object([(reflect_string("a"), 1, sequence_num(7))])
  for params in [[], ["k"], ["k", "v", "extra"]] {
    let wrong_arity = make_function(params, sequence_num(8))
    for empty in [reflect_object([]), hidden] {
      transfer_value(projection_map(wrong_arity, empty), Json::object(Map([])))
    }
    let result = projection_map(wrong_arity, nonempty)
    transfer_value(sequence_call("objectFieldsAll", [result]), ["a"])
    transfer_value(sequence_call("length", [result]), 1)
    transfer_reject(additive_select(result, "a"))
  }
  let bad_body = make_function(["k", "v"], ordering_error("map-key-body"))
  transfer_value(projection_map(bad_body, hidden), Json::object(Map([])))
  transfer_value(
    sequence_call("length", [projection_map(bad_body, nonempty)]),
    1,
  )
  transfer_error(
    additive_select(projection_map(bad_body, nonempty), "a"),
    "map-key-body",
  )
  let payload = reflect_object([
    (reflect_string("a"), 1, ordering_error("map-key-value")),
  ])
  transfer_value(
    projection_map(make_function(["k", "v"], sequence_var("k")), payload),
    { "a": "a" },
  )
  transfer_error(
    additive_select(
      projection_map(make_function(["k", "v"], sequence_var("v")), payload),
      "a",
    ),
    "map-key-value",
  )
  let returns_function = make_function(
    ["k", "v"],
    make_function([], sequence_var("v")),
  )
  transfer_value(
    value_head_call(
      additive_select(projection_map(returns_function, nonempty), "a"),
      [],
    ),
    7,
  )
}

///|
test "OP5 projection and mapping functions retain public names no defaults and aliases" {
  let original = reflect_object([(reflect_string("a"), 1, projection_box(7))])
  let pair : Json = [{ "key": "a", "value": { "n": 7 } }]
  let cases : Array[(String, Array[(String?, OrderingExpr)], Json, Int32)] = [
    ("objectValuesAll", [(Some("o"), original)], [{ "n": 7 }], 1),
    ("objectKeysValues", [(Some("o"), original)], pair, 1),
    ("objectKeysValuesAll", [(Some("o"), original)], pair, 1),
    (
      "mapWithKey",
      [
        (Some("obj"), original),
        (Some("func"), make_function(["k", "v"], sequence_var("v"))),
      ],
      { "a": { "n": 7 } },
      2,
    ),
  ]
  for (name, args, expected, arity) in cases {
    let function = additive_select(sequence_var("std"), name)
    transfer_value(rounding_apply(name, args), expected)
    transfer_value(
      sequence_local(
        [("f", function)],
        shared_mode_call(sequence_var("f"), args),
      ),
      expected,
    )
    transfer_value(
      sequence_call("length", [function]),
      Json::number(arity.to_double()),
    )
    transfer_reject(sequence_call(name, []))
    if args.length() == 2 {
      transfer_reject(rounding_apply(name, [args[0]]))
      transfer_reject(rounding_apply(name, [args[1]]))
    }
    let wrong_name = args.copy()
    wrong_name.push((Some("unknown"), sequence_num(0)))
    transfer_reject(rounding_apply(name, wrong_name))
    let positional = if name == "mapWithKey" {
      [args[1].1, args[0].1]
    } else {
      [args[0].1]
    }
    positional.push(sequence_num(0))
    transfer_reject(sequence_call(name, positional))
  }
}

///|
test "OP6 projection guards reject wrong heads and mapWithKey guards func before obj" {
  let null = ordering_leaf("null", Literal(Json::null()))
  let function = make_function([], sequence_num(7))
  let mapper = make_function(["k", "v"], sequence_var("v"))
  for
    invalid in [
      null,
      reflect_bool(false),
      sequence_num(1),
      reflect_string(""),
      ordering_array([]),
      function,
    ] {
    for name in ["objectValuesAll", "objectKeysValues", "objectKeysValuesAll"] {
      transfer_reject(sequence_call(name, [invalid]))
    }
    transfer_reject(projection_map(mapper, invalid))
  }
  for
    invalid in [
      null,
      reflect_bool(false),
      sequence_num(1),
      reflect_string(""),
      ordering_array([]),
      reflect_object([]),
    ] {
    transfer_reject(projection_map(invalid, reflect_object([])))
  }
  // A successful host gate distinguishes non-demand; no competing error or callback count rule.
  let gate = value_head_call(
    sequence_call("native", [reflect_string("projection-object")]),
    [],
  )
  for handmade in [false, true] {
    let seen : Array[Json] = []
    let native : @moonjsonnet.NativeFunction = {
      params: [],
      callback: _ => {
        seen.push(true)
        Json::object(Map([]))
      },
    }
    try
      ordering_program(projection_map(sequence_num(1), gate), handmade).evaluate(
        limits=transfer_limits(),
        native_functions=Map([("projection-object", native)]),
      )
    catch {
      @moonjsonnet.Error(_) => ()
    } noraise {
      _ => fail("mapWithKey accepted a nonfunction")
    }
    assert_eq(seen.length(), 0)
  }
}

///|
test "OP7 projections preserve original self super closures and aliases after overlays" {
  let original = ordering_binary(
    reflect_object([(reflect_string("a"), 1, projection_box(1))]),
    "+",
    reflect_object([
      (reflect_string("a"), 1, projection_box(2)),
      (reflect_string("b"), 1, additive_select(sequence_var("self"), "a")),
      (reflect_string("c"), 1, additive_select(sequence_var("super"), "a")),
      (
        reflect_string("f"),
        1,
        sequence_local(
          [("captured", additive_select(sequence_var("self"), "a"))],
          reflect_object([
            (
              reflect_string("get"),
              1,
              make_function([], additive_select(sequence_var("captured"), "n")),
            ),
          ]),
        ),
      ),
    ]),
  )
  for name in ["objectValuesAll", "objectKeysValues", "objectKeysValuesAll"] {
    let result = sequence_var("r")
    let b = projection_value_at(name, result, 1)
    let observations = [
      additive_select(projection_value_at(name, result, 0), "n"),
      additive_select(b, "n"),
      additive_select(projection_value_at(name, result, 2), "n"),
      value_head_call(
        additive_select(projection_value_at(name, result, 3), "get"),
        [],
      ),
      additive_select(additive_select(sequence_var("o"), "b"), "n"),
      additive_select(b, "n"),
    ]
    if name != "objectValuesAll" {
      let extended_pair = ordering_binary(
        make_index(result, 1),
        "+",
        reflect_object([(reflect_string("a"), 1, projection_box(99))]),
      )
      observations.push(
        additive_select(additive_select(extended_pair, "value"), "n"),
      )
    }
    transfer_value(
      sequence_local(
        [("o", original), ("r", sequence_call(name, [sequence_var("o")]))],
        ordering_array(observations),
      ),
      if name == "objectValuesAll" {
        [2, 2, 1, 2, 2, 2]
      } else {
        [2, 2, 1, 2, 2, 2, 2]
      },
    )
  }
  let mapped = sequence_var("mapped")
  let overlay = sequence_var("overlay")
  transfer_value(
    sequence_local(
      [
        ("o", original),
        (
          "mapped",
          projection_map(
            make_function(["k", "v"], sequence_var("v")),
            sequence_var("o"),
          ),
        ),
        (
          "overlay",
          ordering_binary(
            mapped,
            "+",
            reflect_object([(reflect_string("a"), 1, projection_box(99))]),
          ),
        ),
      ],
      ordering_array([
        additive_select(additive_select(mapped, "b"), "n"),
        additive_select(additive_select(overlay, "b"), "n"),
        additive_select(additive_select(overlay, "c"), "n"),
        value_head_call(additive_select(additive_select(overlay, "f"), "get"), []),
        additive_select(additive_select(sequence_var("o"), "a"), "n"),
        additive_select(additive_select(mapped, "a"), "n"),
      ]),
    ),
    [2, 2, 1, 2, 2, 2],
  )
}

///|
test "OP8 flat assertions are demanded only by original field indexing" {
  let original = assertion_paths_object(
    [("a", 1, projection_box(7))],
    reflect_bool(false),
    None,
  )
  for name in ["objectValuesAll", "objectKeysValues", "objectKeysValuesAll"] {
    let result = sequence_call(name, [original])
    transfer_value(sequence_call("length", [result]), 1)
    if name != "objectValuesAll" {
      transfer_value(additive_select(make_index(result, 0), "key"), "a")
    }
    transfer_reject(projection_value_at(name, result, 0))
    transfer_value(
      sequence_call(name, [
        assertion_paths_object([], reflect_bool(false), None),
      ]),
      [],
    )
    let good = assertion_paths_object(
      [("a", 1, projection_box(7))],
      reflect_bool(true),
      Some(ordering_error("unused-assertion-message")),
    )
    transfer_value(projection_value_at(name, sequence_call(name, [good]), 0), {
      "n": 7,
    })
  }
  let hidden = assertion_paths_object(
    [("h", 2, projection_box(8))],
    reflect_bool(false),
    None,
  )
  transfer_value(sequence_call("objectKeysValues", [hidden]), [])
  for name in ["objectValuesAll", "objectKeysValuesAll"] {
    let result = sequence_call(name, [hidden])
    transfer_value(sequence_call("length", [result]), 1)
    transfer_reject(projection_value_at(name, result, 0))
  }
  let identity = make_function(["k", "v"], sequence_var("v"))
  let mapped = projection_map(identity, original)
  transfer_value(sequence_call("objectFieldsAll", [mapped]), ["a"])
  transfer_reject(additive_select(mapped, "a"))
  transfer_value(
    projection_map(make_function(["k", "v"], sequence_var("k")), original),
    { "a": "a" },
  )
  transfer_value(
    projection_map(
      make_function(["k", "v"], ordering_error("unused-hidden-map")),
      hidden,
    ),
    Json::object(Map([])),
  )
}

///|
test "OP9 required projection heads propagate errors and unused whole calls stay lazy" {
  let calls : Array[OrderingExpr] = []
  for name in ["objectValuesAll", "objectKeysValues", "objectKeysValuesAll"] {
    let call = sequence_call(name, [ordering_error("projection-head")])
    transfer_error(call, "projection-head")
    calls.push(call)
  }
  let bad_func = projection_map(
    ordering_error("map-key-func"),
    reflect_object([]),
  )
  transfer_error(bad_func, "map-key-func")
  calls.push(bad_func)
  let bad_obj = projection_map(
    make_function(["k", "v"], sequence_var("v")),
    ordering_error("map-key-object"),
  )
  transfer_error(bad_obj, "map-key-object")
  calls.push(bad_obj)
  for call in calls {
    transfer_value(ordering_unused(call), 42)
    transfer_value(transfer_if(reflect_bool(false), call, sequence_num(42)), 42)
    transfer_value(ordering_binary(reflect_bool(false), "&&", call), false)
  }
}
