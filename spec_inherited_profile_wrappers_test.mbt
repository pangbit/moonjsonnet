// The fixed std.jsonnet base64Decode and stripChars definitions compose
// receiver methods. Their native callees retain existing admission profiles.
// Source and handmade trees use independent literal results in these groups.

///|
test "inherited byte decoder wrapper observes methods and preserves native CRLF extension" {
  inherited_standard_check(
    inherited_standard_override("char", ["n"], reflect_string("X")),
    "base64Decode",
    [("str", reflect_string("Zg=="))],
    "X",
    "f",
  )
  inherited_standard_check(
    inherited_standard_override(
      "base64DecodeBytes",
      ["str"],
      ordering_array([sequence_num(233)]),
    ),
    "base64Decode",
    [("str", reflect_string("AA=="))],
    "é",
    "\u0000",
  )
  // CRLF acceptance is a retained project extension, not the documented
  // canonical input contract. An empty extension must not change that policy.
  for
    library in [
      sequence_var("std"),
      ordering_binary(sequence_var("std"), "+", reflect_object([])),
    ] {
    sequence_value(
      inherited_standard_call(library, "base64Decode", [
        ("str", reflect_string("Zg==\r\n\r\n")),
      ]),
      "f",
    )
  }
}

///|
test "inherited strip wrapper observes both methods and preserves String admission" {
  let args = [("str", reflect_string(" left ")), ("chars", reflect_string(" "))]
  for name in ["lstripChars", "rstripChars"] {
    inherited_standard_check(
      inherited_standard_override(
        name,
        ["str", "chars"],
        reflect_string("changed"),
      ),
      "stripChars",
      args,
      "changed",
      "left",
    )
  }
  for
    library in [
      sequence_var("std"),
      ordering_binary(sequence_var("std"), "+", reflect_object([])),
    ] {
    sequence_failure(
      inherited_standard_call(library, "stripChars", [
        ("str", ordering_array([])),
        ("chars", reflect_string("a")),
      ]),
      @moonjsonnet.Runtime,
      None,
    )
    sequence_value(
      inherited_standard_call(library, "stripChars", [
        ("str", reflect_string("")),
        ("chars", ordering_error("unused empty strip characters")),
      ]),
      "",
    )
  }
}

///|
test "inherited profile wrappers retain extracted and super receivers" {
  let cases : Array[
    (
      String,
      Array[String],
      OrderingExpr,
      Array[(String, OrderingExpr)],
      Json,
      Json,
    ),
  ] = [
    (
      "base64Decode",
      ["str"],
      inherited_standard_override("char", ["n"], reflect_string("X")),
      [("str", reflect_string("Zg=="))],
      "X",
      "f",
    ),
    (
      "stripChars",
      ["str", "chars"],
      inherited_standard_override(
        "rstripChars",
        ["str", "chars"],
        reflect_string("right"),
      ),
      [("str", reflect_string(" left ")), ("chars", reflect_string(" "))],
      "right",
      "left",
    ),
  ]
  for (name, params, library, args, changed, ordinary) in cases {
    for
      (receiver, expected) in [
        (library, changed),
        (sequence_var("std"), ordinary),
      ] {
      sequence_value(
        sequence_local(
          [("saved", additive_select(receiver, name))],
          sequence_local(
            [
              (
                "holder",
                reflect_object([
                  (reflect_string(name), 2, sequence_var("saved")),
                  (
                    reflect_string("char"),
                    2,
                    make_function(["n"], ordering_error("unused holder char")),
                  ),
                  (
                    reflect_string("rstripChars"),
                    2,
                    make_function(
                      ["str", "chars"],
                      ordering_error("unused holder strip"),
                    ),
                  ),
                ]),
              ),
              ("std", ordering_error("unused wrapper caller std")),
            ],
            inherited_standard_call(sequence_var("holder"), name, args),
          ),
        ),
        expected,
      )
    }
    let wrapper = reflect_object([
      (
        reflect_string(name),
        2,
        make_function(
          params,
          inherited_sequence_call(
            ordering_leaf("super", Var("super")),
            name,
            params.map(sequence_var),
          ),
        ),
      ),
    ])
    sequence_value(
      inherited_standard_call(
        ordering_binary(library, "+", wrapper),
        name,
        args,
      ),
      changed,
    )
  }
}

///|
test "inherited profile wrappers defer operands when their overridden callee ignores them" {
  sequence_value(
    inherited_standard_call(
      inherited_standard_override(
        "base64DecodeBytes",
        ["str"],
        ordering_array([]),
      ),
      "base64Decode",
      [("str", ordering_error("unused decoder input"))],
    ),
    "",
  )
  for name in ["lstripChars", "rstripChars"] {
    sequence_value(
      inherited_standard_call(
        inherited_standard_override(name, ["str", "chars"], reflect_string("")),
        "stripChars",
        [
          ("str", ordering_error("unused strip input")),
          ("chars", ordering_error("unused strip characters")),
        ],
      ),
      "",
    )
  }
  let required : Array[(OrderingExpr, String, Array[(String, OrderingExpr)])] = [
    (
      inherited_standard_override(
        "char",
        ["n"],
        ordering_error("required wrapper dependency"),
      ),
      "base64Decode",
      [("str", reflect_string("Zg=="))],
    ),
    (
      inherited_standard_override(
        "rstripChars",
        ["str", "chars"],
        ordering_error("required wrapper dependency"),
      ),
      "stripChars",
      [("str", reflect_string(" left ")), ("chars", reflect_string(" "))],
    ),
  ]
  for (library, name, args) in required {
    sequence_failure(
      inherited_standard_call(library, name, args),
      @moonjsonnet.Runtime,
      Some("required wrapper dependency"),
    )
  }
}
