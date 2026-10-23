// Independent fixed criteria: SPEC-FLATTEN-2026-10-23.md.

///|
test "flattenArrays concatenates exactly one level and retains all payload kinds" {
  let nil = ordering_leaf("null", Literal(Json::null()))
  let empty = ordering_array([])
  for
    (input, expected) in [
      (empty, Json::array([])),
      (ordering_array([empty, empty]), []),
      (ordering_array([ordering_array([sequence_num(1)])]), [1]),
      (
        ordering_array([
          empty,
          ordering_array([sequence_num(1), nil, reflect_bool(false)]),
          empty,
          ordering_array([
            reflect_string("中😀\u0000"),
            ordering_array([sequence_num(2), sequence_num(3)]),
            merge_patch_object([("x", sequence_num(4))]),
          ]),
        ]),
        [1, Json::null(), false, "中😀\u0000", [2, 3], { "x": 4 }],
      ),
    ] {
    sequence_value(sequence_call("flattenArrays", [input]), expected)
  }
}

///|
test "flattenDeepArray recursively preserves leaves including null and source defined scalar roots" {
  let nil = ordering_leaf("null", Literal(Json::null()))
  let empty = ordering_array([])
  let object = merge_patch_object([("x", ordering_array([sequence_num(4)]))])
  for
    (input, expected) in [
      (empty, Json::array([])),
      (ordering_array([empty, ordering_array([empty])]), []),
      (nil, [Json::null()]),
      (reflect_bool(false), [false]),
      (sequence_num(7), [7]),
      (reflect_string("中😀\u0000"), ["中😀\u0000"]),
      (object, [{ "x": [4] }]),
      (
        ordering_array([
          ordering_array([sequence_num(1), empty]),
          ordering_array([
            ordering_array([nil, sequence_num(2)]),
            object,
            reflect_string(""),
          ]),
          reflect_bool(true),
        ]),
        [1, Json::null(), 2, { "x": [4] }, "", true],
      ),
    ] {
    sequence_value(sequence_call("flattenDeepArray", [input]), expected)
    sequence_value(
      rounding_apply("flattenDeepArray", [(Some("value"), input)]),
      expected,
    )
  }
}

///|
test "flattenArrays rejects clear unsupported additions and demands every outer array head" {
  let unread = ordering_error("flatten-rejected-payload")
  let nil = ordering_leaf("null", Literal(Json::null()))
  for input in [nil, reflect_bool(false), sequence_num(1)] {
    sequence_failure(
      sequence_call("flattenArrays", [input]),
      @moonjsonnet.Type,
      None,
    )
  }
  for
    item in [
      nil,
      reflect_bool(false),
      sequence_num(1),
      merge_patch_object([("x", unread)]),
      value_head_function(unread, unread),
    ] {
    sequence_failure(
      sequence_call("flattenArrays", [
        ordering_array([ordering_array([]), item]),
      ]),
      @moonjsonnet.Type,
      None,
    )
  }
  for
    input in [
      ordering_error("flatten-required-outer"),
      ordering_array([
        ordering_array([sequence_num(1)]),
        ordering_error("flatten-required-outer"),
      ]),
    ] {
    let value = sequence_call("flattenArrays", [input])
    sequence_failure(
      sequence_call("length", [value]),
      @moonjsonnet.Runtime,
      Some("flatten-required-outer"),
    )
    sequence_failure(
      make_index(value, 0),
      @moonjsonnet.Runtime,
      Some("flatten-required-outer"),
    )
  }
}

///|
test "flattenArrays defers retained payloads until selection or manifestation" {
  let unread = ordering_error("flatten-shallow-payload")
  let flat = sequence_call("flattenArrays", [
    ordering_array([ordering_array([sequence_num(1)]), ordering_array([unread])]),
  ])
  sequence_value(sequence_call("length", [flat]), 2)
  sequence_value(make_index(flat, 0), 1)
  sequence_failure(
    make_index(flat, 1),
    @moonjsonnet.Runtime,
    Some("flatten-shallow-payload"),
  )
  sequence_failure(flat, @moonjsonnet.Runtime, Some("flatten-shallow-payload"))
  for
    (payload, kind) in [
      (ordering_array([unread]), "array"),
      (merge_patch_object([("x", unread)]), "object"),
      (value_head_function(unread, unread), "function"),
    ] {
    sequence_value(
      sequence_call("type", [
        make_index(
          sequence_call("flattenArrays", [
            ordering_array([ordering_array([payload])]),
          ]),
          0,
        ),
      ]),
      Json::string(kind),
    )
  }
}

///|
test "flattenDeepArray demands recursive leaf heads but leaves object fields and function bodies lazy" {
  let bad = ordering_error("flatten-deep-required-leaf")
  for input in [bad, ordering_array([sequence_num(1), ordering_array([bad])])] {
    let flat = sequence_call("flattenDeepArray", [input])
    sequence_failure(
      sequence_call("length", [flat]),
      @moonjsonnet.Runtime,
      Some("flatten-deep-required-leaf"),
    )
    sequence_failure(
      make_index(flat, 0),
      @moonjsonnet.Runtime,
      Some("flatten-deep-required-leaf"),
    )
  }
  let payload = ordering_error("flatten-object-field")
  let object = merge_patch_object([("x", payload)])
  for input in [object, ordering_array([ordering_array([object])])] {
    let flat = sequence_call("flattenDeepArray", [input])
    sequence_value(sequence_call("length", [flat]), 1)
    sequence_value(sequence_call("type", [make_index(flat, 0)]), "object")
    sequence_failure(flat, @moonjsonnet.Runtime, Some("flatten-object-field"))
  }
  let function = value_head_function(payload, payload)
  sequence_value(
    sequence_call("type", [
      make_index(
        sequence_call("flattenDeepArray", [
          ordering_array([ordering_array([function])]),
        ]),
        0,
      ),
    ]),
    "function",
  )
}

///|
test "flatten operations preserve original arrays and aliases under cold and warm reads" {
  let nested = sequence_var("nested")
  let left = sequence_var("left")
  let input = sequence_var("input")
  let result = sequence_var("result")
  for
    (name, flattened) in [
      ("flattenArrays", Json::array([1, [2], 3, Json::null()])),
      ("flattenDeepArray", [1, 2, 3, Json::null()]),
    ] {
    for inputs_first in [false, true] {
      let before = [
        (sequence_call("length", [input]), 3),
        (sequence_call("length", [left]), 2),
        (sequence_call("length", [nested]), 1),
      ]
      let after = [
        (sequence_call("length", [result]), 4),
        (make_index(result, 0), 1),
      ]
      sequence_value(
        sequence_local(
          [
            ("nested", ordering_array([sequence_num(2)])),
            ("left", ordering_array([sequence_num(1), nested])),
            (
              "input",
              ordering_array([
                left,
                ordering_array([]),
                ordering_array([
                  sequence_num(3),
                  ordering_leaf("null", Literal(Json::null())),
                ]),
              ]),
            ),
            ("alias", input),
            ("result", sequence_call(name, [input])),
          ],
          sequence_gate(
            if inputs_first {
              before + after
            } else {
              after + before
            },
            ordering_array([
              nested,
              left,
              input,
              sequence_var("alias"),
              result,
              sequence_call(name, [input]),
            ]),
          ),
        ),
        [
          [2],
          [1, [2]],
          [[1, [2]], [], [3, Json::null()]],
          [[1, [2]], [], [3, Json::null()]],
          flattened,
          flattened,
        ],
      )
    }
  }
}

///|
test "flatten operations share demanded source heads and retained leaves across repeated reads" {
  let payload = rewrite_gate(reflect_string("leaf"), sequence_num(2))
  let left = rewrite_gate(
    reflect_string("left"),
    ordering_array([sequence_num(1), payload]),
  )
  let input = rewrite_gate(
    reflect_string("input"),
    ordering_array([left, ordering_array([sequence_num(3)])]),
  )
  for name in ["flattenArrays", "flattenDeepArray"] {
    let original = sequence_var("original")
    let result = sequence_var("result")
    let value = additive_probe_scope(
      sequence_local(
        [("original", input), ("result", sequence_call(name, [original]))],
        sequence_gate(
          [(sequence_call("length", [result]), 3)],
          ordering_array([
            make_index(result, 1),
            make_index(result, 1),
            make_index(make_index(original, 0), 1),
            result,
            sequence_call(name, [original]),
          ]),
        ),
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
        [2, 2, 2, [1, 2, 3], [1, 2, 3]],
      )
      assert_eq(counts, Map([("input", 1), ("left", 1), ("leaf", 1)]))
    }
  }
}

///|
test "flatten operations reject unambiguous bad bindings before gates and preserve unused calls" {
  let input = rewrite_gate(reflect_string("binding"), ordering_array([]))
  for name in ["flattenArrays", "flattenDeepArray"] {
    pair_reject(
      ordering_unused(sequence_call(name, [sequence_var("flatten_missing")])),
    )
    for
      args in [
        [],
        [(None, input), (None, input)],
        [(Some("unexpected"), input)],
      ] {
      let call = additive_probe_scope(rounding_apply(name, args))
      for handmade in [false, true] {
        let counts : Map[String, Int] = Map([])
        assert_eq(
          ordering_program(ordering_unused(call), handmade).evaluate(
            native_functions=rewrite_natives(counts),
            limits=sequence_limits(),
          ),
          42,
        )
        try
          ordering_program(call, handmade).evaluate(
            native_functions=rewrite_natives(counts),
            limits=sequence_limits(),
          )
        catch {
          @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
        } noraise {
          _ => fail("invalid flatten binding succeeded")
        }
        assert_eq(counts.length(), 0)
      }
    }
  }
}
