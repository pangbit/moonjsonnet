///|
test "character conversion retains truncation and replaces surrogates" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.char(65.5),std.char(55296),std.char(57343),std.codepoint(std.char(55296)),std.codepoint('😀')]",
    ).stringify(),
    "[\"A\",\"�\",\"�\",65533,128512]",
  )
  assert_eq(
    @moonjsonnet.evaluate(
      "local inf=std.sum([1e308,1e308]); local nan=std.sum([inf,-inf]); std.codepoint(std.char(nan))",
    ).stringify(),
    if @number.reference_amd64() {
      "65533"
    } else {
      "0"
    },
  )
}

///|
test "character errors use numeric bounds before truncation and Go messages" {
  for
    (source, expected) in [
      ("std.char(-1)", "Codepoints must be >= 0, got -1"),
      ("std.char(-0.5)", "Codepoints must be >= 0, got -0.5"),
      ("std.char(1114112)", "Invalid unicode codepoint, got 1.114112e+06"),
      ("std.char(1114111.5)", "Invalid unicode codepoint, got 1.1141115e+06"),
      (
        "std.codepoint('')", "codepoint takes a string of length 1, got length 0",
      ),
      (
        "std.codepoint('é😀')", "codepoint takes a string of length 1, got length 2",
      ),
    ] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Runtime)
        assert_eq(d.message, expected)
      }
    } noraise {
      _ => fail("expected character error")
    }
  }
}
