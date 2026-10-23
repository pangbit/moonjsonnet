// Independent contract: SPEC-PRUNE-2026-10-23.md.

///|
fn prune_call(value : OrderingExpr, named? : Bool = false) -> OrderingExpr {
  rounding_apply("prune", [(if named { Some("a") } else { None }, value)])
}

///|
test "prune recursively removes empty members while preserving scalar data and order" {
  let nil = ordering_leaf("null", Literal(Json::null()))
  let empty_array = ordering_array([])
  let empty_object = merge_patch_object([])
  let cascading = merge_patch_object([
    (
      "x",
      ordering_array([nil, empty_array, merge_patch_object([("drop", nil)])]),
    ),
  ])
  let input = merge_patch_object([
    ("chain", ordering_array([merge_patch_object([("a", cascading)])])),
    (
      "data",
      ordering_array([
        sequence_num(42),
        empty_array,
        nil,
        reflect_string(""),
        reflect_bool(false),
        empty_object,
        sequence_num(0),
        ordering_array([reflect_string("ok"), nil]),
      ]),
    ),
    (
      "map",
      merge_patch_object([
        ("drop", nil),
        ("zero", sequence_num(0)),
        ("false", reflect_bool(false)),
        ("empty_text", reflect_string("")),
      ]),
    ),
  ])
  for named in [false, true] {
    sequence_value(prune_call(input, named~), {
      "data": [42, "", false, 0, ["ok"]],
      "map": { "zero": 0, "false": false, "empty_text": "" },
    })
  }
  for
    (value, expected) in [
      (nil, Json::null()),
      (empty_array, Json::array([])),
      (empty_object, {}),
      (reflect_bool(false), Json::boolean(false)),
      (sequence_num(0), Json::number(0)),
      (sequence_num(7), Json::number(7)),
      (reflect_string(""), Json::string("")),
      (reflect_string("text"), Json::string("text")),
    ] {
    sequence_value(prune_call(value), expected)
  }
}

///|
test "prune preserves shared original values across cold and warm result reads" {
  let nil = ordering_leaf("null", Literal(Json::null()))
  let input = merge_patch_object([
    ("gone", nil),
    (
      "arr",
      ordering_array([
        nil,
        sequence_num(0),
        merge_patch_object([]),
        reflect_bool(false),
        reflect_string(""),
        merge_patch_object([("drop", ordering_array([]))]),
      ]),
    ),
    (
      "node",
      merge_patch_object([
        ("empty", merge_patch_object([("x", nil)])),
        ("keep", sequence_num(2)),
      ]),
    ),
  ])
  let original = sequence_var("original")
  let result = sequence_var("result")
  let size = fn(value : OrderingExpr, name : String) {
    sequence_call("length", [additive_select(value, name)])
  }
  for inputs_first in [false, true] {
    let input_checks = [(size(original, "arr"), 6), (size(original, "node"), 2)]
    let result_checks = [(size(result, "arr"), 3), (size(result, "node"), 1)]
    sequence_value(
      sequence_local(
        [
          ("original", input),
          ("alias", original),
          ("result", prune_call(original)),
        ],
        sequence_gate(
          if inputs_first {
            input_checks + result_checks
          } else {
            result_checks + input_checks
          },
          ordering_array([
            original,
            sequence_var("alias"),
            result,
            prune_call(original),
          ]),
        ),
      ),
      [
        {
          "gone": Json::null(),
          "arr": [Json::null(), 0, {}, false, "", { "drop": [] }],
          "node": { "empty": { "x": Json::null() }, "keep": 2 },
        },
        {
          "gone": Json::null(),
          "arr": [Json::null(), 0, {}, false, "", { "drop": [] }],
          "node": { "empty": { "x": Json::null() }, "keep": 2 },
        },
        { "arr": [0, false, ""], "node": { "keep": 2 } },
        { "arr": [0, false, ""], "node": { "keep": 2 } },
      ],
    )
  }
}

///|
test "prune selects final inherited visible fields and skips hidden payloads" {
  let bad = ordering_error("prune-hidden-unread")
  let base = reflect_object([
    (reflect_string("turned_hidden"), 1, sequence_num(9)),
    (reflect_string("turned_visible"), 2, bad),
    (reflect_string("hidden"), 2, bad),
    (reflect_string("zero"), 1, sequence_num(0)),
  ])
  let top = reflect_object([
    (reflect_string("turned_hidden"), 2, bad),
    (reflect_string("turned_visible"), 3, reflect_bool(false)),
  ])
  sequence_value(prune_call(ordering_binary(base, "+", top)), {
    "turned_visible": false,
    "zero": 0,
  })
  let hidden_only = reflect_object([(reflect_string("h"), 2, bad)])
  sequence_value(prune_call(hidden_only), {})
  sequence_value(
    prune_call(
      merge_patch_object([
        ("empty", hidden_only),
        ("array", ordering_array([hidden_only, reflect_string("keep")])),
      ]),
    ),
    { "array": ["keep"] },
  )
}

///|
test "prune demands recursive membership errors while unused bodies and bindings stay lazy" {
  let number = ordering_leaf("1e308", Literal(Json::number(1.0e308)))
  for
    (value, marker) in [
      (
        prune_call(ordering_error("prune-root-required")),
        Some("prune-root-required"),
      ),
      (
        sequence_call("length", [
          prune_call(
            ordering_array([
              sequence_num(1),
              ordering_error("prune-array-member"),
            ]),
          ),
        ]),
        Some("prune-array-member"),
      ),
      (
        sequence_call("objectFields", [
          prune_call(
            merge_patch_object([
              ("ok", sequence_num(1)),
              (
                "bad",
                merge_patch_object([
                  ("deep", ordering_error("prune-nested-member")),
                ]),
              ),
            ]),
          ),
        ]),
        Some("prune-nested-member"),
      ),
      (
        sequence_call("type", [prune_call(ordering_binary(number, "*", number))]),
        None,
      ),
    ] {
    sequence_failure(value, @moonjsonnet.Runtime, marker)
  }
  let unread = ordering_error("prune-function-body-or-default")
  sequence_value(
    sequence_call("type", [prune_call(value_head_function(unread, unread))]),
    "function",
  )
  pair_reject(ordering_unused(prune_call(sequence_var("prune_missing"))))
  for
    args in [
      [],
      [
        (
          Some("not_a"),
          rewrite_gate(reflect_string("binding"), sequence_num(1)),
        ),
      ],
    ] {
    let value = additive_probe_scope(rounding_apply("prune", args))
    for handmade in [false, true] {
      let counts : Map[String, Int] = Map([])
      try
        ordering_program(value, handmade).evaluate(
          native_functions=rewrite_natives(counts),
          limits=sequence_limits(),
        )
      catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
      } noraise {
        _ => fail("invalid prune binding succeeded")
      }
      assert_eq(counts.length(), 0)
    }
  }
}
