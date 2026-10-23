// Fixed independent criteria: SPEC-ENCODING-ENTRIES-2026-10-23.md.
// The String oracle is not decoded from the independently declared byte fixture.

///|
fn encoding_entry_text() -> String {
  "\u00a0\u07ff\u0800\ud7ff\ue000\uffff\u{10000}\u{10ffff}|é|e\u0301|A\ufeffZ|�"
}

///|
fn encoding_entry_bytes() -> Bytes {
  b"/* \xc3\xa9 */\r\n'\xc2\xa0\xdf\xbf\xe0\xa0\x80\xed\x9f\xbf\xee\x80\x80\xef\xbf\xbf\xf0\x90\x80\x80\xf4\x8f\xbf\xbf|\xc3\xa9|e\xcc\x81|A\xef\xbb\xbfZ|\xef\xbf\xbd'"
}

///|
fn encoding_entry_program(
  handmade : Bool,
  unused : Bool,
) -> @moonjsonnet.Program raise @moonjsonnet.JsonnetError {
  let leaf = ordering_leaf("import 'code'", ImportFile("code", false))
  ordering_program(if unused { ordering_unused(leaf) } else { leaf }, handmade)
}

///|
test "direct String source preserves canonical Unicode without claiming byte validation" {
  let source = "/* é */\r\n'\u00a0\u07ff\u0800\ud7ff\ue000\uffff\u{10000}\u{10ffff}|é|e\u0301|A\ufeffZ|�'"
  sequence_value(
    ordering_leaf(source, Literal(Json::string(encoding_entry_text()))),
    Json::string(encoding_entry_text()),
  )
}

///|
test "binary code imports decode valid UTF8 independently of their source or AST headers" {
  for handmade in [false, true] {
    let requests : Array[(String, String)] = []
    let evaluator = @moonjsonnet.Evaluator::new()
    evaluator.set_importer(binary_resolver=(from, path) => {
      requests.push((from, path))
      { id: "encoding-code", bytes: encoding_entry_bytes(), }
    })
    let program = encoding_entry_program(handmade, false)
    assert_eq(requests.length(), 0)
    assert_eq(evaluator.evaluate(program), Json::string(encoding_entry_text()))
    assert_eq(requests, [("ordering-entry", "code")])
  }
}

///|
test "code import host decoding errors remain distinct from source phases and stay lazy" {
  let cases : Array[(Bytes, @moonjsonnet.ErrorKind, String?)] = [
    // This first row is the documented strict host policy, not a language
    // diagnostic/recovery rule for text outside the valid UTF8 domain.
    (b"'\xff'", @moonjsonnet.Import, None),
    (b"local", @moonjsonnet.Syntax, None),
    (b"encoding_missing", @moonjsonnet.Static, None),
    (
      b"error '\xe5\x85\xa5\xe5\x8f\xa3\xe9\x94\x99\xe8\xaf\xaf'",
      @moonjsonnet.Runtime,
      Some("入口错误"),
    ),
  ]
  for (bytes, kind, marker) in cases {
    for handmade in [false, true] {
      let mut reads = 0
      let evaluator = @moonjsonnet.Evaluator::new()
      evaluator.set_importer(binary_resolver=(_, _) => {
        reads += 1
        { id: "encoding-code", bytes, }
      })
      assert_eq(evaluator.evaluate(encoding_entry_program(handmade, true)), 42)
      assert_eq(reads, 0)
      let program = encoding_entry_program(handmade, false)
      try evaluator.evaluate(program) catch {
        @moonjsonnet.Error(d) => {
          assert_eq(d.kind, kind)
          assert_eq(d.location.file, "encoding-code")
          if marker is Some(text) {
            assert_eq(d.message, text)
          }
        }
      } noraise {
        _ => fail("demanded code import failure was hidden")
      }
      assert_eq(reads, 1)
    }
  }
}
