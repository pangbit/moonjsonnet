///|
test "digests of one million a bytes" {
  let input = Json::string("a".repeat(1000000))
  let limits = { ..@moonjsonnet.Limits::default(), steps: 2000000, }
  for
    (name, expected) in [
      ("md5", "7707d6ae4e027c70eea2a935c2296f21"),
      ("sha1", "34aa973cd4c4daa4f61eeb2bdbad27316534016f"),
      (
        "sha512", "e718483d0ce769644e2e42c7bc15b4638e1f98b13b2044285632a803afa973ebde0ff244877ea60a4cb0432ce577c31beb009c5c2c49aa2e4eadb217ad8cc09b",
      ),
      (
        "sha3", "3c3a876da14034ab60627c077bb98f7e120a2a5370212dffb3385a18d4f38859ed311d0a9d5141ce9cc5c66ee689b266a8aa18ace8282a0e0db596c90b0a7b87",
      ),
    ] {
    assert_eq(
      @moonjsonnet.evaluate(
        "std." + name + "(std.extVar('input'))",
        ext_vars=Map([("input", input)]),
        limits~,
      ),
      Json::string(expected),
    )
  }
}

///|
test "MD5 SHA-1 SHA-512 SHA3-512 known answers" {
  // Previously an Unsupported diagnostic fixture; retain the input as success.
  assert_eq(
    @moonjsonnet.evaluate("std.sha512('x')"),
    Json::string(
      "a4abd4448c49562d828115d13a1fccea927f52b4d5459297f8b43e42da89238bc13626e43dcb38ddb082488927ec904fb42057443983e88585179d50551afe62",
    ),
  )
  for
    (name, input, expected) in [
      ("md5", "", "d41d8cd98f00b204e9800998ecf8427e"),
      ("md5", "abc", "900150983cd24fb0d6963f7d28e17f72"),
      ("sha1", "", "da39a3ee5e6b4b0d3255bfef95601890afd80709"),
      ("sha1", "abc", "a9993e364706816aba3e25717850c26c9cd0d89d"),
      (
        "sha512", "", "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e",
      ),
      (
        "sha512", "abc", "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f",
      ),
      (
        "sha3", "", "a69f73cca23a9ac5c8b567dc185a756e97c982164fe25859e0d1dcc1475c80a615b2123af1f5f94c11e3e9402c3ac558f500199d95b6d3e301758586281dcd26",
      ),
      (
        "sha3", "abc", "b751850b1a57168a5693cd924b6b096e08f621827444f70d884f5d0240d2712e10e116e9192af3c91a7ec57647e3934057340b4cf408d5a56592f8274eec53f0",
      ),
    ] {
    assert_eq(
      @moonjsonnet.evaluate(
        "std." + name + "(s=std.extVar('input'))",
        ext_vars=Map([("input", Json::string(input))]),
      ),
      Json::string(expected),
    )
  }
}

///|
test "digest string inputs and work limits" {
  for name in ["md5", "sha1", "sha512", "sha3"] {
    for input in ["null", "true", "123", "[97,98,99]", "{}", "function()0"] {
      try @moonjsonnet.evaluate("std." + name + "(" + input + ")") catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Type)
      } noraise {
        _ => fail("expected string type error")
      }
    }
    let limits = { ..@moonjsonnet.Limits::default(), steps: 100, }
    try
      @moonjsonnet.evaluate(
        "std." + name + "(std.extVar('input'))",
        ext_vars=Map([("input", Json::string("a".repeat(1024)))]),
        limits~,
      )
    catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
    } noraise {
      _ => fail("expected hash work limit")
    }
  }
}
