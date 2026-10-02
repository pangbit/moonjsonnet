///|
test "sha256 known answers and multi block padding" {
  let cases = [
    ("", "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"),
    ("abc", "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"),
    ("x", "2d711642b726b04401627ca9fbac32f5c8530fb1903cc4db02258717921a4881"),
    (
      "你😀", "cec26da7276b013db43249baa588b9099de46f9ccd8547d4216133d535e96ae2",
    ),
    (
      "a\u0000b", "59b271ae1bbcb1d31d41929817f4b16fb439eb4f31520b5ad1d5ce98920a7138",
    ),
    (
      "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1",
    ),
    (
      "a".repeat(1000000),
      "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0",
    ),
  ]
  let limits = @moonjsonnet.Limits::default()
  for (input, expected) in cases {
    assert_eq(
      @moonjsonnet.evaluate(
        "std.sha256(s=std.extVar('input'))",
        ext_vars=Map([("input", Json::string(input))]),
        limits={ ..limits, steps: 2000000, },
      ),
      Json::string(expected),
    )
  }
}

///|
test "sha256 enforces string input and work budget" {
  try @moonjsonnet.evaluate("std.sha256([97,98,99])") catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Type)
  } noraise {
    _ => fail("expected string type error")
  }
  let limits = @moonjsonnet.Limits::default()
  try
    @moonjsonnet.evaluate("std.sha256('abc')", limits={ ..limits, steps: 20, })
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected hash work limit")
  }
}
