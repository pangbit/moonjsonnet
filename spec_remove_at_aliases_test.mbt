// Compatibility aliases of one existing parameter, not additional parameters.
// Source and handmade ASTs independently exercise the same literal outcomes.

///|
test "removeAt aliases share one slot with ordinary lazy and strict binding" {
  let values = ordering_array([sequence_num(1), sequence_num(2)])
  for library in inherited_profile_controls() {
    let callee = additive_select(library, "removeAt")
    sequence_value(sequence_call("length", [callee]), 2)
    sequence_value(
      shared_mode_call(callee, [(None, values), (None, sequence_num(0))]),
      [2],
    )
    for spelling in ["i", "idx", "at"] {
      let args = [
        (Some("arr"), ordering_array([])),
        (Some(spelling), ordering_error("unused named index")),
      ]
      sequence_value(shared_mode_call(callee, args), [])
      sequence_failure(
        shared_mode_call(callee, args, strict=true),
        @moonjsonnet.Runtime,
        Some("unused named index"),
      )
      sequence_value(
        shared_mode_call(
          callee,
          [(Some("arr"), values), (Some(spelling), sequence_num(0))],
          strict=true,
        ),
        [2],
      )
      sequence_failure(
        shared_mode_call(callee, [
          (None, ordering_error("unforced duplicate array")),
          (None, ordering_error("unforced positional index")),
          (Some(spelling), ordering_error("unforced named index")),
        ]),
        @moonjsonnet.Runtime,
        Some("Argument i already provided"),
      )
    }
    for (first, second) in [("i", "idx"), ("i", "at"), ("idx", "at")] {
      for strict in [false, true] {
        sequence_failure(
          shared_mode_call(
            callee,
            [
              (Some("arr"), ordering_error("unforced alias array")),
              (Some(first), ordering_error("unforced first alias")),
              (Some(second), ordering_error("unforced second alias")),
            ],
            strict~,
          ),
          @moonjsonnet.Runtime,
          Some("Argument i already provided"),
        )
      }
    }
  }
  let ordinary = make_function(["arr", "i"], sequence_var("i"))
  for
    callee in [
      ordinary,
      sequence_local([("removeAt", ordinary)], sequence_var("removeAt")),
      additive_select(
        inherited_standard_override("removeAt", ["arr", "i"], sequence_var("i")),
        "removeAt",
      ),
    ] {
    sequence_value(
      shared_mode_call(callee, [
        (Some("arr"), ordering_array([])),
        (Some("i"), sequence_num(7)),
      ]),
      7,
    )
    for spelling in ["idx", "at"] {
      sequence_failure(
        shared_mode_call(callee, [
          (Some("arr"), ordering_array([])),
          (Some(spelling), ordering_error("unforced ordinary alias")),
        ]),
        @moonjsonnet.Runtime,
        Some("function has no parameter " + spelling),
      )
    }
  }
}

///|
test "removeAt alias closures retain captured and inherited receivers through forwarding and super" {
  let library = inherited_sequence_library(0)
  let cases : Array[(OrderingExpr, Json)] = [
    (sequence_var("std"), [2]),
    (library, []),
  ]
  for (receiver, expected) in cases {
    for spelling in ["idx", "at"] {
      sequence_value(
        sequence_local(
          [("saved", additive_select(receiver, "removeAt"))],
          sequence_local(
            [
              (
                "holder",
                reflect_object([
                  (reflect_string("removeAt"), 2, sequence_var("saved")),
                  (
                    reflect_string("length"),
                    2,
                    make_function(["x"], sequence_num(99)),
                  ),
                ]),
              ),
              ("std", ordering_error("unused alias caller std")),
            ],
            inherited_standard_call(sequence_var("holder"), "removeAt", [
              ("arr", ordering_array([sequence_num(1), sequence_num(2)])),
              (spelling, sequence_num(0)),
            ]),
          ),
        ),
        expected,
      )
    }
  }
  sequence_value(
    inherited_standard_call(library, "removeAt", [
      ("arr", ordering_error("unused inherited array")),
      ("idx", ordering_error("unused inherited index")),
    ]),
    [],
  )
  let wrapper = reflect_object([
    (
      reflect_string("removeAt"),
      2,
      make_function(
        ["arr", "idx"],
        inherited_standard_call(
          ordering_leaf("super", Var("super")),
          "removeAt",
          [("arr", sequence_var("arr")), ("at", sequence_var("idx"))],
        ),
      ),
    ),
  ])
  sequence_value(
    inherited_standard_call(
      ordering_binary(library, "+", wrapper),
      "removeAt",
      [
        ("arr", ordering_array([sequence_num(1), sequence_num(2)])),
        ("idx", sequence_num(0)),
      ],
    ),
    [],
  )
}
