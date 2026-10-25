// Compatibility preservation only: idx/at/i has no unique normative spelling.
// This profile must not be counted as specification acceptance.

///|
test "deletion binding profile preserves current i without adding disputed aliases" {
  let values = ordering_array([sequence_num(1), sequence_num(2)])
  sequence_value(
    rounding_apply("removeAt", [
      (Some("i"), sequence_num(0)),
      (Some("arr"), values),
    ]),
    [2],
  )
  for disputed in ["idx", "at"] {
    deletion_binding_reject(
      rounding_apply("removeAt", [
        (Some("arr"), values),
        (Some(disputed), ordering_error("binding-must-skip")),
      ]),
    )
  }
}
