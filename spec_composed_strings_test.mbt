// Pending execution: SPEC-COMPOSED-STRINGS-2026-10-23.md.
// Expected values were derived before any product execution.

///|
test "deepJoin and lines preserve ordered strings and their distinct null contracts" {
  let nil = ordering_leaf("null", Literal(Json::null()))
  let empty = ordering_array([])
  for
    (name, input, expected) in [
      ("deepJoin", reflect_string(""), ""),
      ("deepJoin", reflect_string("中😀\u0000"), "中😀\u0000"),
      ("deepJoin", empty, ""),
      ("deepJoin", ordering_array([empty, ordering_array([empty])]), ""),
      (
        "deepJoin",
        ordering_array([
          reflect_string("a"),
          ordering_array([reflect_string(""), empty, reflect_string("中")]),
          reflect_string("😀\n"),
        ]),
        "a中😀\n",
      ),
      ("lines", empty, ""),
      ("lines", ordering_array([nil, nil]), ""),
      ("lines", ordering_array([reflect_string("")]), "\n"),
      ("lines", ordering_array([nil, reflect_string(""), nil]), "\n"),
      (
        "lines",
        ordering_array([
          reflect_string("a"),
          nil,
          reflect_string(""),
          reflect_string("b"),
        ]),
        "a\n\nb\n",
      ),
      (
        "lines",
        ordering_array([reflect_string("中\n"), reflect_string("😀\u0000")]),
        "中\n\n😀\u0000\n",
      ),
    ] {
    sequence_value(sequence_call(name, [input]), Json::string(expected))
    sequence_value(
      rounding_apply(name, [(Some("arr"), input)]),
      Json::string(expected),
    )
  }
}

///|
fn composed_domain_failure(
  name : String,
  input : OrderingExpr,
  kind : @moonjsonnet.ErrorKind,
) -> Unit raise {
  let value = additive_probe_scope(sequence_call(name, [input]))
  for handmade in [false, true] {
    let counts : Map[String, Int32] = Map([])
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
      @moonjsonnet.Error(d) => assert_eq(d.kind, kind)
    } noraise {
      _ => fail("composed-string domain rejection was suppressed")
    }
    assert_eq(
      counts.length(),
      0,
      msg="domain rejection must not demand payload gates",
    )
  }
}

///|
test "deepJoin and lines reject wrong domains without demanding rejected payloads" {
  let nil = ordering_leaf("null", Literal(Json::null()))
  let unread = rewrite_gate(
    reflect_string("rejected-payload"),
    ordering_error("composed-rejected-payload"),
  )
  let object = merge_patch_object([("x", unread)])
  let function = value_head_function(unread, unread)
  let common = [reflect_bool(false), sequence_num(1), object, function]
  for bad in common + [nil] {
    for
      input in [
        bad,
        ordering_array([reflect_string("ok"), ordering_array([bad])]),
      ] {
      composed_domain_failure("deepJoin", input, @moonjsonnet.Runtime)
    }
  }
  for bad in common + [nil, reflect_string("")] {
    composed_domain_failure("lines", bad, @moonjsonnet.Type)
  }
  for bad in common + [ordering_array([unread])] {
    composed_domain_failure(
      "lines",
      ordering_array([reflect_string("ok"), bad]),
      @moonjsonnet.Type,
    )
  }
}

///|
test "deepJoin and lines demand complete string results even for length and early selection" {
  for
    (name, nested) in [
      (
        "deepJoin",
        ordering_array([
          reflect_string("a"),
          ordering_array([ordering_error("composed-required")]),
        ]),
      ),
      (
        "lines",
        ordering_array([
          reflect_string("a"),
          ordering_error("composed-required"),
        ]),
      ),
    ] {
    for input in [ordering_error("composed-required"), nested] {
      let value = sequence_call(name, [input])
      for
        observation in [
          value,
          sequence_call("length", [value]),
          make_index(value, 0),
        ] {
        sequence_failure(
          observation,
          @moonjsonnet.Runtime,
          Some("composed-required"),
        )
      }
    }
  }
}

///|
test "deepJoin and lines preserve originals and aliases across cold and warm result reads" {
  let nil = ordering_leaf("null", Literal(Json::null()))
  let input = sequence_var("input")
  let result = sequence_var("result")
  for
    (name, original, original_json, expected, result_length, first_length) in [
      (
        "deepJoin",
        ordering_array([
          ordering_array([
            reflect_string("a"),
            ordering_array([reflect_string("b")]),
          ]),
          ordering_array([]),
          reflect_string("c"),
        ]),
        Json::array([["a", ["b"]], [], "c"]),
        "abc",
        3,
        2,
      ),
      (
        "lines",
        ordering_array([reflect_string("a"), nil, reflect_string("b")]),
        ["a", Json::null(), "b"],
        "a\nb\n",
        4,
        1,
      ),
    ] {
    for inputs_first in [false, true] {
      let before = [
        (sequence_call("length", [input]), 3),
        (sequence_call("length", [make_index(input, 0)]), first_length),
      ]
      let after = [(sequence_call("length", [result]), result_length)]
      sequence_value(
        sequence_local(
          [
            ("input", original),
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
              input,
              sequence_var("alias"),
              result,
              sequence_call(name, [input]),
            ]),
          ),
        ),
        [
          original_json,
          original_json,
          Json::string(expected),
          Json::string(expected),
        ],
      )
    }
  }
}

///|
test "deepJoin and lines share required input and string leaves while unused calls stay lazy" {
  let leaf = rewrite_gate(reflect_string("leaf"), reflect_string("a"))
  for
    (name, original, expected, original_json, size) in [
      (
        "deepJoin",
        ordering_array([leaf, ordering_array([reflect_string("b")])]),
        "ab",
        Json::array(["a", ["b"]]),
        2,
      ),
      (
        "lines",
        ordering_array([leaf, reflect_string("b")]),
        "a\nb\n",
        ["a", "b"],
        4,
      ),
    ] {
    let input = sequence_var("input")
    let result = sequence_var("result")
    let expression = additive_probe_scope(
      sequence_local(
        [
          ("input", rewrite_gate(reflect_string("input"), original)),
          ("result", sequence_call(name, [input])),
        ],
        sequence_gate(
          [(sequence_call("length", [result]), size)],
          ordering_array([result, result, sequence_call(name, [input]), input]),
        ),
      ),
    )
    for handmade in [false, true] {
      let counts : Map[String, Int32] = Map([])
      assert_eq(
        ordering_program(ordering_unused(expression), handmade).evaluate(
          native_functions=rewrite_natives(counts),
          limits=sequence_limits(),
        ),
        42,
      )
      assert_eq(counts.length(), 0)
      assert_eq(
        ordering_program(expression, handmade).evaluate(
          native_functions=rewrite_natives(counts),
          limits=sequence_limits(),
        ),
        [
          Json::string(expected),
          Json::string(expected),
          Json::string(expected),
          original_json,
        ],
      )
      assert_eq(counts, Map([("input", 1), ("leaf", 1)]))
    }
  }
}

///|
test "deepJoin and lines reject bad bindings before gates without skipping static free names" {
  let input = rewrite_gate(reflect_string("binding"), ordering_array([]))
  for name in ["deepJoin", "lines"] {
    pair_reject(
      ordering_unused(sequence_call(name, [sequence_var("composed_missing")])),
    )
    for
      args in [
        [],
        [(None, input), (None, input)],
        [(Some("unexpected"), input)],
        [(None, input), (Some("arr"), input)],
      ] {
      let call = additive_probe_scope(rounding_apply(name, args))
      for handmade in [false, true] {
        let counts : Map[String, Int32] = Map([])
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
          _ => fail("invalid composed-string binding succeeded")
        }
        assert_eq(counts.length(), 0)
      }
    }
  }
}
