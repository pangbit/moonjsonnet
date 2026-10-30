// Fixed Jsonnet bbb38f std.jsonnet 1309-1333, enabled without native overrides.
// Literal Python/PythonVars results through source and handmade caller ASTs.
// Vars keys are valid ASCII identifiers. General number spelling, invalid Vars
// names, assertions/inheritance, cycles and resource thresholds are excluded.

///|
fn python_manifest_call(
  name : String,
  args : Array[(String?, OrderingExpr)],
  through_alias~ : Bool = false,
) -> OrderingExpr {
  let function = additive_select(sequence_var("std"), name)
  if through_alias {
    sequence_local(
      [("saved_manifest", function)],
      shared_mode_call(sequence_var("saved_manifest"), args),
    )
  } else {
    shared_mode_call(function, args)
  }
}

///|
test "PY1 Python manifestation has literal primitive and recursive layouts" {
  let nil = ordering_leaf("null", Literal(Json::null()))
  let cases : Array[(OrderingExpr, String)] = [
    (reflect_string(""), "\"\""),
    (ordering_array([]), "[]"),
    (reflect_object([]), "{}"),
    (
      ordering_array([
        nil,
        reflect_bool(true),
        reflect_bool(false),
        sequence_num(0),
        sequence_num(-17),
      ]),
      "[None, True, False, 0, -17]",
    ),
    (
      reflect_object([
        (reflect_string("z"), 1, ordering_array([])),
        (
          reflect_string("a\"\n"),
          1,
          ordering_array([
            reflect_string("é😀\n\\\""),
            reflect_object([
              (reflect_string("z"), 1, nil),
              (reflect_string("a"), 1, reflect_bool(false)),
            ]),
          ]),
        ),
      ]),
      "{\"a\\\"\\n\": [\"é😀\\n\\\\\\\"\", {\"a\": False, \"z\": None}], \"z\": []}",
    ),
  ]
  for (value, expected) in cases {
    transfer_value(
      sequence_call("manifestPython", [value]),
      Json::string(expected),
    )
  }
}

///|
test "PY2 PythonVars preserves valid names sorted lines and one final newline" {
  let conf = reflect_object([
    (reflect_string("z"), 1, ordering_array([])),
    (
      reflect_string("alpha"),
      1,
      reflect_object([
        (reflect_string("b"), 1, reflect_bool(true)),
        (reflect_string("a"), 1, reflect_string("x\ny")),
      ]),
    ),
    (reflect_string("_config"), 1, reflect_object([])),
    (reflect_string("A1"), 1, sequence_num(7)),
  ])
  transfer_value(
    sequence_call("manifestPythonVars", [conf]),
    "A1 = 7\n_config = {}\nalpha = {\"a\": \"x\\ny\", \"b\": True}\nz = []\n",
  )
  transfer_value(
    sequence_call("manifestPythonVars", [
      reflect_object([
        (reflect_string("one"), 1, ordering_leaf("null", Literal(Json::null()))),
      ]),
    ]),
    "one = None\n",
  )
}

///|
test "PY3 Python manifestations skip hidden payloads at nested object levels" {
  let unread = ordering_error("python-hidden-payload")
  let hidden_only = reflect_object([
    (reflect_string("hidden"), 2, unread),
    (reflect_string("method"), 2, make_function([], unread)),
  ])
  transfer_value(sequence_call("manifestPython", [hidden_only]), "{}")
  transfer_value(sequence_call("manifestPythonVars", [hidden_only]), "")
  let nested = reflect_object([
    (reflect_string("hidden"), 2, unread),
    (reflect_string("visible"), 3, sequence_num(9)),
  ])
  let conf = reflect_object([
    (reflect_string("hidden"), 2, unread),
    (reflect_string("item"), 1, nested),
    (reflect_string("empty"), 3, hidden_only),
  ])
  transfer_value(
    sequence_call("manifestPython", [conf]),
    "{\"empty\": {}, \"item\": {\"visible\": 9}}",
  )
  transfer_value(
    sequence_call("manifestPythonVars", [conf]),
    "empty = {}\nitem = {\"visible\": 9}\n",
  )
}

///|
test "PY4 Python manifestations demand visible values and keep unused calls lazy" {
  let required = ordering_error("python-required-payload")
  let bad_function = make_function([], required)
  for name in ["manifestPython", "manifestPythonVars"] {
    for through_alias in [false, true] {
      for
        input in [
          required,
          reflect_object([(reflect_string("visible"), 3, required)]),
          reflect_object([
            (reflect_string("visible"), 1, ordering_array([required])),
          ]),
        ] {
        let call = python_manifest_call(name, [(None, input)], through_alias~)
        // Exact sole-marker/kind checks are extra embedding controls, not
        // specified diagnostic wording or competing-error precedence.
        transfer_error(call, "python-required-payload")
        transfer_reject(sequence_call("type", [call]))
      }
    }
    let function_value = sequence_call(name, [
      reflect_object([(reflect_string("visible"), 1, bad_function)]),
    ])
    transfer_reject(function_value)
    transfer_value(ordering_unused(function_value), 42)
    transfer_value(
      shared_mode_call(make_function(["unused"], sequence_num(42)), [
        (None, function_value),
      ]),
      42,
    )
  }
  for
    input in [
      bad_function,
      ordering_array([bad_function]),
      additive_select(sequence_var("std"), "length"),
    ] {
    transfer_reject(sequence_call("manifestPython", [input]))
  }
  for
    input in [
      ordering_leaf("null", Literal(Json::null())),
      reflect_bool(false),
      sequence_num(1),
      reflect_string(""),
      ordering_array([]),
      bad_function,
    ] {
    // PythonVars requires an Object; no diagnostic tag or payload ordering
    // is inferred from these ordinary admission rejections.
    transfer_reject(sequence_call("manifestPythonVars", [input]))
  }
}

///|
test "PY5 Python manifestations retain required names aliases and binding errors" {
  let safe = reflect_object([(reflect_string("x"), 1, sequence_num(1))])
  for
    (name, parameter, expected) in [
      ("manifestPython", "v", "{\"x\": 1}"),
      ("manifestPythonVars", "conf", "x = 1\n"),
    ] {
    transfer_value(
      sequence_call("length", [additive_select(sequence_var("std"), name)]),
      1,
    )
    for through_alias in [false, true] {
      for label in [None, Some(parameter)] {
        transfer_value(
          python_manifest_call(name, [(label, safe)], through_alias~),
          Json::string(expected),
        )
      }
      let invalid : Array[Array[(String?, OrderingExpr)]] = [
        [],
        [(None, safe), (None, safe)],
        [(Some("unknown"), safe)],
        [(None, safe), (Some(parameter), safe)],
      ]
      for args in invalid {
        transfer_reject(python_manifest_call(name, args, through_alias~))
      }
    }
  }
}
