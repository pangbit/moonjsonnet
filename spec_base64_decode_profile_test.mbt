// Ungraded observations outside the documented canonical String input domain.
// A successful collector is not normative acceptance of malformed encodings,
// linebreak/padding policies or source-defined non-String admission.

///|
test "Base64 decoder out of domain inputs emit ungraded paired entry observations" {
  let cases : Array[(String, OrderingExpr)] = [
    ("missing-padding", reflect_string("Zg")),
    ("nonzero-pad-bits-one", reflect_string("Zh==")),
    ("nonzero-pad-bits-two", reflect_string("Zm9=")),
    ("padding-only", reflect_string("====")),
    ("interior-padding", reflect_string("Zg=A")),
    ("group-after-padding", reflect_string("Zg==AAAA")),
    ("CRLF-after-padding", reflect_string("Zg==\r\n\r\n")),
    ("only-CRLF", reflect_string("\r\n\r\n")),
    ("nonstandard-alphabet", reflect_string("____")),
    ("empty-Array", ordering_array([])),
    ("empty-Object", reflect_object([])),
    ("zero-arity-Function", make_function([], sequence_num(0))),
  ]
  for (id, input) in cases {
    for name in ["base64DecodeBytes", "base64Decode"] {
      for handmade in [false, true] {
        let call = base64_decode_call(name, input)
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
              "function": name,
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
}
