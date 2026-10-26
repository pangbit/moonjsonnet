// Observation only: B64-R0 negative range and B64-F0 fractional conversion.
// This group's framework success is NOT normative contract acceptance.
// Every probe reports both source and handmade-AST outcomes without pinning
// the implementation's current rejection or one possible source interpretation.

///|
test "base64 unresolved numeric inputs emit ungraded source and AST observations" {
  let cases : Array[(String, OrderingExpr)] = [
    ("negative-one", ordering_array([deletion_number("-1", -1.0)])),
    ("negative-255", ordering_array([deletion_number("-255", -255.0)])),
    ("negative-256", ordering_array([deletion_number("-256", -256.0)])),
    ("fraction-half", ordering_array([deletion_number("0.5", 0.5)])),
    ("fraction-one-half", ordering_array([deletion_number("1.5", 1.5)])),
    ("fraction-254-half", ordering_array([deletion_number("254.5", 254.5)])),
    ("fraction-255-half", ordering_array([deletion_number("255.5", 255.5)])),
    (
      "negative-before-error",
      ordering_array([
        deletion_number("-1", -1.0),
        ordering_error("profile-tail"),
      ]),
    ),
    (
      "fraction-before-error",
      ordering_array([
        deletion_number("1.5", 1.5),
        ordering_error("profile-tail"),
      ]),
    ),
  ]
  for (id, input) in cases {
    for handmade in [false, true] {
      let call = base64_contract_call(input)
      let outcome : Json = try
        ordering_program(call, handmade).evaluate(limits=sequence_limits())
      catch {
        @moonjsonnet.Error(d) => { "outcome": "error", "message": d.message }
      } noraise {
        value => { "outcome": "value", "value": value }
      }
      println(
        (
          {
            "id": id,
            "entry": if handmade {
              "ast"
            } else {
              "source"
            },
            "normative": false,
            "observation": outcome,
          } : Json).stringify(),
      )
    }
  }
}
