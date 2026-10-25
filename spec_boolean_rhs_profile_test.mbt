// B0 strict-extension compatibility only. The fixed longcut RHS metavariable
// domain is not adjudicated by this test or a reference interpreter result.

///|
test "B0 strict RHS profile remains conditional rather than normative acceptance" {
  let bad = ordering_error("B0-unread-nested-payload")
  let values = [
    ordering_leaf("null", Literal(null)),
    sequence_num(7),
    reflect_string("value"),
    ordering_array([bad]),
    reflect_object([(reflect_string("field"), 1, bad)]),
    make_function([], bad),
  ]
  for op in ["&&", "||"] {
    for rhs in values {
      let expression = ordering_binary(reflect_bool(op == "&&"), op, rhs)
      // The type wrapper distinguishes a rejected head from later JSON
      // manifestation of a successfully transferred Array/Object/Function.
      sequence_failure(
        sequence_call("type", [expression]),
        @moonjsonnet.Type,
        None,
      )
    }
  }
}
