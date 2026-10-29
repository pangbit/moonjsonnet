// Explicit compatibility choice: retain i and accept documented idx / source at
// as the same slot. This is not a claim that fixed sources require all aliases.

///|
test "deletion binding profile retains i and accepts documented and source index names" {
  let values = ordering_array([sequence_num(1), sequence_num(2)])
  sequence_value(
    rounding_apply("removeAt", [
      (Some("i"), sequence_num(0)),
      (Some("arr"), values),
    ]),
    [2],
  )
  for spelling in ["idx", "at"] {
    sequence_value(
      rounding_apply("removeAt", [
        (Some("arr"), values),
        (Some(spelling), sequence_num(0)),
      ]),
      [2],
    )
    // Preserve the historical inputs. Previously the names were rejected before
    // their value; accepted binding now reaches that same required error thunk.
    sequence_failure(
      rounding_apply("removeAt", [
        (Some("arr"), values),
        (Some(spelling), ordering_error("binding-must-skip")),
      ]),
      @moonjsonnet.Runtime,
      Some("binding-must-skip"),
    )
  }
  deletion_binding_reject(
    rounding_apply("removeAt", [
      (Some("arr"), values),
      (Some("unknown"), ordering_error("binding-must-skip")),
    ]),
  )
}
