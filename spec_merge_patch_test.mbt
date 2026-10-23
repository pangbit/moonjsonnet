// Independent criteria: SPEC-MERGE-PATCH-2026-10-23.md.

///|
fn merge_patch_object(fields : Array[(String, OrderingExpr)]) -> OrderingExpr {
  reflect_object(fields.map(f => (reflect_string(f.0), 1, f.1)))
}

///|
fn merge_patch_call(
  target : OrderingExpr,
  patch : OrderingExpr,
  named? : Bool = false,
) -> OrderingExpr {
  rounding_apply("mergePatch", [
    (if named { Some("target") } else { None }, target),
    (if named { Some("patch") } else { None }, patch),
  ])
}

///|
test "mergePatch JSON data deletes recurses and replaces with literal results" {
  let nil = ordering_leaf("null", Literal(Json::null()))
  let target = merge_patch_object([
    ("erase", sequence_num(1)),
    (
      "keep",
      merge_patch_object([
        ("nil", nil),
        ("list", ordering_array([sequence_num(1), sequence_num(2)])),
      ]),
    ),
    (
      "nest",
      merge_patch_object([("drop", sequence_num(3)), ("old", sequence_num(4))]),
    ),
    ("arr", ordering_array([merge_patch_object([("v", sequence_num(1))])])),
  ])
  let patch = merge_patch_object([
    ("erase", nil),
    ("absent", nil),
    ("nest", merge_patch_object([("drop", nil), ("new", sequence_num(5))])),
    ("arr", ordering_array([sequence_num(9)])),
    ("add", merge_patch_object([("gone", nil)])),
  ])
  for named in [false, true] {
    sequence_value(merge_patch_call(target, patch, named~), {
      "keep": { "nil": Json::null(), "list": [1, 2] },
      "nest": { "old": 4, "new": 5 },
      "arr": [9],
      "add": {},
    })
  }
  let normalize = merge_patch_object([
    ("a", merge_patch_object([("gone", nil), ("b", sequence_num(2))])),
    ("absent", nil),
  ])
  for
    base in [
      nil,
      reflect_bool(false),
      sequence_num(3),
      reflect_string("old"),
      ordering_array([sequence_num(1)]),
    ] {
    sequence_value(merge_patch_call(base, normalize), { "a": { "b": 2 } })
  }
  for
    (replacement, expected) in [
      (nil, Json::null()),
      (reflect_bool(false), Json::boolean(false)),
      (sequence_num(8), Json::number(8)),
      (reflect_string("new"), Json::string("new")),
      (ordering_array([sequence_num(7), nil]), Json::array([7, Json::null()])),
    ] {
    sequence_value(merge_patch_call(target, replacement), expected)
  }
  sequence_value(
    merge_patch_call(
      merge_patch_object([
        ("x", sequence_num(1)),
        ("华北😀", sequence_num(2)),
      ]),
      merge_patch_object([("x", nil), ("é", sequence_num(3))]),
    ),
    { "华北😀": 2, "é": 3 },
  )
}

///|
test "mergePatch shared target and patch stay unchanged before and after demand" {
  let nil = ordering_leaf("null", Literal(Json::null()))
  let target = merge_patch_object([
    (
      "node",
      merge_patch_object([("drop", sequence_num(1)), ("keep", sequence_num(2))]),
    ),
    ("arr", ordering_array([sequence_num(1), sequence_num(2)])),
    ("raw", nil),
  ])
  let patch = merge_patch_object([
    ("node", merge_patch_object([("drop", nil), ("new", sequence_num(3))])),
    ("arr", ordering_array([sequence_num(9)])),
  ])
  let original = sequence_var("original")
  let overlay = sequence_var("overlay")
  let result = sequence_var("result")
  let node_field = fn(value : OrderingExpr, key : String) {
    additive_select(additive_select(value, "node"), key)
  }
  for warm_inputs_first in [false, true] {
    let old_checks = [
      (node_field(original, "drop"), 1),
      (node_field(overlay, "new"), 3),
    ]
    let merged_checks = [(node_field(result, "new"), 3)]
    sequence_value(
      sequence_local(
        [
          ("original", target),
          ("overlay", patch),
          ("alias", original),
          ("result", merge_patch_call(original, overlay)),
        ],
        sequence_gate(
          if warm_inputs_first {
            old_checks + merged_checks
          } else {
            merged_checks + old_checks
          },
          ordering_array([
            result,
            original,
            overlay,
            sequence_var("alias"),
            merge_patch_call(original, overlay),
          ]),
        ),
      ),
      [
        { "node": { "keep": 2, "new": 3 }, "arr": [9], "raw": Json::null() },
        { "node": { "drop": 1, "keep": 2 }, "arr": [1, 2], "raw": Json::null() },
        { "node": { "drop": Json::null(), "new": 3 }, "arr": [9] },
        { "node": { "drop": 1, "keep": 2 }, "arr": [1, 2], "raw": Json::null() },
        { "node": { "keep": 2, "new": 3 }, "arr": [9], "raw": Json::null() },
      ],
    )
  }
}

///|
test "mergePatch leaves unused target and unselected container payloads lazy" {
  let nil = ordering_leaf("null", Literal(Json::null()))
  let bad = ordering_error("merge-unread")
  sequence_value(merge_patch_call(bad, nil), Json::null())
  let array_replacement = merge_patch_call(bad, ordering_array([bad]))
  sequence_value(sequence_call("type", [array_replacement]), "array")
  sequence_value(sequence_call("length", [array_replacement]), 1)
  sequence_value(
    merge_patch_call(
      ordering_array([bad]),
      merge_patch_object([("ok", sequence_num(1))]),
    ),
    { "ok": 1 },
  )
  let retained = merge_patch_call(
    merge_patch_object([("unread", bad)]),
    merge_patch_object([]),
  )
  sequence_value(sequence_call("objectFields", [retained]), ["unread"])
  let nested = merge_patch_call(
    merge_patch_object([
      (
        "node",
        merge_patch_object([
          ("drop", bad),
          ("unread", bad),
          ("ok", sequence_num(1)),
        ]),
      ),
    ]),
    merge_patch_object([("node", merge_patch_object([("drop", nil)]))]),
  )
  sequence_value(additive_select(additive_select(nested, "node"), "ok"), 1)
  let patch_payload = merge_patch_call(
    merge_patch_object([]),
    merge_patch_object([
      ("selected", sequence_num(2)),
      ("spare", ordering_array([bad])),
    ]),
  )
  sequence_value(additive_select(patch_payload, "selected"), 2)
  sequence_value(
    sequence_call("length", [additive_select(patch_payload, "spare")]),
    1,
  )
  sequence_value(
    sequence_call("objectFields", [
      merge_patch_call(
        merge_patch_object([("x", bad)]),
        merge_patch_object([("x", sequence_num(2))]),
      ),
    ]),
    ["x"],
  )
  sequence_value(
    merge_patch_call(
      reflect_object([
        (reflect_string("ok"), 1, sequence_num(1)),
        (reflect_string("hidden"), 2, bad),
      ]),
      reflect_object([(reflect_string("hidden_patch"), 2, bad)]),
    ),
    { "ok": 1 },
  )
}

///|
test "mergePatch propagates isolated required errors and preserves static binding boundaries" {
  let empty = merge_patch_object([])
  let selected_array = merge_patch_call(
    ordering_error("merge-unused-old"),
    ordering_array([ordering_error("merge-array-selected")]),
  )
  for
    (value, marker) in [
      (
        merge_patch_call(ordering_error("merge-target-head"), empty),
        "merge-target-head",
      ),
      (
        merge_patch_call(empty, ordering_error("merge-patch-head")),
        "merge-patch-head",
      ),
      (
        additive_select(
          merge_patch_call(
            empty,
            merge_patch_object([
              ("selected", sequence_num(1)),
              ("other", ordering_error("merge-patch-member-head")),
            ]),
          ),
          "selected",
        ),
        "merge-patch-member-head",
      ),
      (
        additive_select(
          merge_patch_call(
            merge_patch_object([("x", ordering_error("merge-retained-value"))]),
            empty,
          ),
          "x",
        ),
        "merge-retained-value",
      ),
      (
        {
          source: "(" + selected_array.source + ")[0]",
          tree: ordering_ast(Index(selected_array.tree, sequence_num(0).tree)),
        },
        "merge-array-selected",
      ),
      (
        additive_select(
          merge_patch_call(
            merge_patch_object([("x", ordering_error("merge-strict-old-head"))]),
            merge_patch_object([("x", sequence_num(2))]),
          ),
          "x",
        ),
        "merge-strict-old-head",
      ),
    ] {
    sequence_failure(value, @moonjsonnet.Runtime, Some(marker))
  }
  pair_reject(
    merge_patch_call(sequence_var("merge_missing_target"), sequence_num(1)),
  )
  pair_reject(
    ordering_unused(
      merge_patch_call(empty, sequence_var("merge_missing_patch")),
    ),
  )
  let unused_gate = rewrite_gate(reflect_string("binding"), sequence_num(1))
  for
    args in [
      [],
      [(Some("not_a_parameter"), unused_gate), (Some("patch"), empty)],
    ] {
    let value = additive_probe_scope(rounding_apply("mergePatch", args))
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
        _ => fail("invalid mergePatch binding succeeded")
      }
      assert_eq(counts.length(), 0)
    }
  }
}
