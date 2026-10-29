// Fixed Jsonnet bbb38f std.jsonnet 898-916, enabled without native overrides.
// Literal INI layouts and finite value-demand witnesses through source and
// handmade caller ASTs. General value coercion, numeric spelling, unusual key
// names, assertions/inheritance, cycles and resource thresholds are excluded.

///|
fn ini_contract_field(name : String, value : OrderingExpr) -> OrderingExpr {
  reflect_object([(reflect_string(name), 1, value)])
}

///|
fn ini_contract_call(
  args : Array[(String?, OrderingExpr)],
  through_alias? : Bool = false,
) -> OrderingExpr {
  let function = additive_select(sequence_var("std"), "manifestIni")
  if through_alias {
    sequence_local(
      [("saved_ini", function)],
      shared_mode_call(sequence_var("saved_ini"), args),
    )
  } else {
    shared_mode_call(function, args)
  }
}

///|
test "INI1 INI output sorts fields and sections but preserves repeated value order" {
  let ini = reflect_object([
    (
      reflect_string("sections"),
      1,
      reflect_object([
        (reflect_string("z"), 1, reflect_object([])),
        (
          reflect_string("a"),
          1,
          reflect_object([
            (
              reflect_string("z"),
              1,
              ordering_array([reflect_bool(false), reflect_bool(true)]),
            ),
            (
              reflect_string("a"),
              1,
              ordering_leaf("null", Literal(Json::null())),
            ),
          ]),
        ),
      ]),
    ),
    (
      reflect_string("main"),
      1,
      reflect_object([
        (
          reflect_string("z"),
          1,
          ordering_array([
            reflect_string("third"),
            reflect_string("first"),
            reflect_string("third"),
          ]),
        ),
        (reflect_string("a"), 1, sequence_num(7)),
      ]),
    ),
  ])
  transfer_value(
    sequence_call("manifestIni", [ini]),
    "a = 7\nz = third\nz = first\nz = third\n[a]\na = null\nz = false\nz = true\n[z]\n",
  )
  transfer_value(
    sequence_call("manifestIni", [
      reflect_object([
        (
          reflect_string("main"),
          1,
          ini_contract_field("text", reflect_string("é😀%\"\\\n")),
        ),
        (reflect_string("sections"), 1, reflect_object([])),
      ]),
    ]),
    "text = é😀%\"\\\n\n",
  )
}

///|
test "INI2 empty bodies and empty repeated Arrays emit no lines but sections do" {
  let empty = reflect_object([])
  for main in [empty, ini_contract_field("omitted", ordering_array([]))] {
    transfer_value(
      sequence_call("manifestIni", [
        reflect_object([
          (reflect_string("main"), 1, main),
          (reflect_string("sections"), 1, empty),
        ]),
      ]),
      "",
    )
  }
  transfer_value(
    sequence_call("manifestIni", [ini_contract_field("sections", empty)]),
    "",
  )
  transfer_value(
    sequence_call("manifestIni", [
      ini_contract_field(
        "sections",
        ini_contract_field(
          "empty",
          ini_contract_field("omitted", ordering_array([])),
        ),
      ),
    ]),
    "[empty]\n",
  )
}

///|
test "INI3 INI skips hidden entries while still reading the sections field" {
  let unread = ordering_error("ini-hidden-payload")
  let hidden_only = reflect_object([(reflect_string("hidden"), 2, unread)])
  let cases : Array[(OrderingExpr, String)] = [
    (
      reflect_object([
        (reflect_string("main"), 2, unread),
        (reflect_string("sections"), 1, reflect_object([])),
        (reflect_string("unrelated"), 1, unread),
      ]),
      "",
    ),
    (
      reflect_object([
        (reflect_string("main"), 1, hidden_only),
        (reflect_string("sections"), 1, hidden_only),
      ]),
      "",
    ),
    (
      reflect_object([
        (
          reflect_string("main"),
          1,
          reflect_object([
            (reflect_string("hidden"), 2, unread),
            (reflect_string("main_value"), 3, reflect_string("kept")),
          ]),
        ),
        (
          reflect_string("sections"),
          2,
          reflect_object([
            (reflect_string("hidden"), 2, unread),
            (reflect_string("empty"), 3, hidden_only),
          ]),
        ),
      ]),
      "main_value = kept\n[empty]\n",
    ),
  ]
  // sections is indexed directly even when hidden on ini; main is selected
  // by objectHas, and body/section names are selected by objectFields.
  for (ini, expected) in cases {
    transfer_value(sequence_call("manifestIni", [ini]), Json::string(expected))
  }
}

///|
test "INI4 INI output requires visible payloads while unused calls stay lazy" {
  let required = ordering_error("ini-required-payload")
  let empty = reflect_object([])
  let bodies = [
    required,
    ini_contract_field("value", required),
    ini_contract_field("value", ordering_array([required])),
  ]
  let inputs = [required, ini_contract_field("sections", required)]
  for body in bodies {
    inputs.push(
      reflect_object([
        (reflect_string("main"), 1, body),
        (reflect_string("sections"), 1, empty),
      ]),
    )
    inputs.push(ini_contract_field("sections", ini_contract_field("s", body)))
  }
  for ini in inputs {
    let call = ini_contract_call([(None, ini)])
    // Sole-marker/kind assertions are embedding controls, not specified
    // diagnostic wording or competing-error precedence.
    transfer_error(call, "ini-required-payload")
    transfer_reject(sequence_call("type", [call]))
    transfer_value(
      shared_mode_call(make_function(["unused"], sequence_num(42)), [
        (None, call),
      ]),
      42,
    )
  }
  for
    ini in [
      empty,
      ordering_array([]),
      ini_contract_field("sections", ordering_array([])),
      ini_contract_field(
        "sections",
        ini_contract_field("s", ordering_array([])),
      ),
      reflect_object([
        (reflect_string("main"), 1, ordering_array([])),
        (reflect_string("sections"), 1, empty),
      ]),
    ] {
    transfer_reject(sequence_call("manifestIni", [ini]))
  }
}

///|
test "INI5 INI retains its required ini parameter through direct and saved calls" {
  let safe = ini_contract_field(
    "sections",
    ini_contract_field("s", reflect_object([])),
  )
  let function = additive_select(sequence_var("std"), "manifestIni")
  transfer_value(sequence_call("length", [function]), 1)
  for through_alias in [false, true] {
    for label in [None, Some("ini")] {
      transfer_value(
        ini_contract_call([(label, safe)], through_alias~),
        "[s]\n",
      )
    }
    let invalid : Array[Array[(String?, OrderingExpr)]] = [
      [],
      [(None, safe), (None, safe)],
      [(Some("unknown"), safe)],
      [(None, safe), (Some("ini"), safe)],
    ]
    for args in invalid {
      transfer_reject(ini_contract_call(args, through_alias~))
    }
  }
}
