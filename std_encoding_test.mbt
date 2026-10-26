///|
test "encoding byte contracts retain separate decoder compatibility profiles" {
  for
    (source, expected) in [
      (
        "std.encodeUTF8(str='Aé中😀')", "[65,195,169,228,184,173,240,159,152,128]",
      ),
      (
        "std.decodeUTF8(arr=[65,195,169,228,184,173,240,159,152,128])", "\"Aé中😀\"",
      ),
      (
        "[std.decodeUTF8([226,130]),std.decodeUTF8([240,159,152]),std.decodeUTF8([237,160,128]),std.decodeUTF8([239,187,191])]",
        "[\"��\",\"���\",\"���\",\"\\ufeff\"]",
      ),
      // Fixed std.jsonnet codepoint conversion; see
      // docs/development/SPEC-BASE64-CONTRACT-2026-10-26.md.
      (
        "[std.base64('é'),std.base64([233]),std.base64(input=[0,1,255]),std.base64(''),std.base64([])]",
        "[\"6Q==\",\"6Q==\",\"AAH/\",\"\",\"\"]",
      ),
      // Fixed std.jsonnet maps decoded bytes through std.char; see
      // docs/development/SPEC-BASE64-DECODE-CONTRACT-2026-10-26.md.
      (
        "[std.base64Decode('w6k='),std.base64Decode('6Q=='),std.base64DecodeBytes(str='AAH/')]",
        "[\"Ã©\",\"é\",[0,1,255]]",
      ),
      (
        "[std.base64DecodeBytes('Zh=='),std.base64DecodeBytes('Zm9='),std.base64DecodeBytes('Zg==\\r\\n\\r\\n'),std.base64DecodeBytes('\\r\\n\\r\\n')]",
        "[[102],[102,111],[102],[]]",
      ),
    ] {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
}

///|
test "encoding rejects invalid bytes and padding" {
  // Negative/fractional base64 Array checks retain the existing project
  // profile; B64-R0/F0 in the contract record remain unresolved.
  for
    source in [
      "std.base64('中')", "std.base64([256])", "std.base64([-1])", "std.base64([1.5])",
      "std.base64([true])", "std.base64({})", "std.base64([error 'forced'])", "std.encodeUTF8([])",
      "std.decodeUTF8('a')", "std.decodeUTF8([256])", "std.decodeUTF8([-1])", "std.decodeUTF8([1.5])",
      "std.decodeUTF8([null])", "std.base64Decode('Zg')", "std.base64Decode('====')",
      "std.base64Decode('Zg=A')", "std.base64Decode('Zg==AAAA')", "std.base64Decode('Zg==\\n')",
      "std.base64Decode('Zg==    ')", "std.base64Decode('Zg==\\t\\t\\t\\t')", "std.base64Decode('____')",
      "std.base64DecodeBytes([])",
    ] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_true(d.kind != @moonjsonnet.Unsupported)
    } noraise {
      _ => fail("expected encoding error: " + source)
    }
  }
}
