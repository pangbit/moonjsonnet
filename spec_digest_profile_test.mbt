// Fixed Jsonnet bbb38f1020be1f5aed560928fb839b2c448cefb4: stdlib.html
// #std-sha256/#std-sha512 and std.jsonnet 1795-1796. The docs say Go-only;
// the source has go_only_function stubs. This file exercises MoonJsonnet's
// existing native digest host profile, not a successful C++ source contract.
// UTF-8 bytes and lowercase hex are explicit profile choices. Public s versus
// source str, platform availability, invalid host Strings and resource limits
// remain outside these finite checks. Existing known-answer/type/budget tests
// in sha256_test.mbt and digest_test.mbt retain their separate scope.
// Padding constants were prepared independently with Python hashlib and
// checked with /usr/bin/shasum -a 256/512, over UTF-8 bytes of
// "a" repeated (byte_length - 7), followed by U+00E9, U+1F600 and U+0000.
// No MoonJsonnet, Go or C++ evaluator output supplies the expected digests.

///|
fn digest_profile_vectors(name : String) -> Array[(Int32, String)] {
  match name {
    "sha256" =>
      [
        (55, "35aedec77eb30390b26f3db755aaefa71c4211ca5f935d70c252730c62d5b239"),
        (56, "591850417e1db69b0c4be5c9696475bf7e9c37f16b132469877dd83488bf5fb2"),
        (63, "706639aea88920cafe28ece83e460e444024c8792829a8e5a045842a773dd442"),
        (64, "8e805285be750a7b7ab7311bc0edbbe09ad1caa1f5c014f095ed7633c3a595d7"),
        (65, "74d91a867e635cfeb17f2c0bf1b6348c5942150b0548548302da1d1f5e145dc2"),
      ]
    "sha512" =>
      [
        (
          111, "6c0e13a0ffa5ad750a159fb586e05c2702f5d9c8ed98cb6d222b37995e120667ddcea1b81a4b3f231139bacb66f9019211ecb38a6689afa14f200e5a2479a55b",
        ),
        (
          112, "f6c8bf64386ffc4476f82e489193ca3fc79d25521247df19c1281fdf439bab2f518e91f3ac0b954a0f499bf3dffdac361c60eb4a7581b210c01d5f155a0db6cc",
        ),
        (
          127, "d709c34804737009e65d284c78db7ccdebd104da2fa9329e8a1f318ddaff2fedd23ad1601dc1d3380bbe859d3cc2034817b1b3ec908b91538221d50d7c4b104f",
        ),
        (
          128, "ad3f20d93cd1765a9e643edbfc4afd91cab3274ce65b81c00ae680ef8d8b8df2dea0b34d68c21efd6032a49a4ac980da78dabcff9bff6c3950a466cabf1cbda8",
        ),
        (
          129, "20c8e1638fac2ded3939e665a1715fcd27992082a478d8b997e5912f68f969aa57d451e34b143eac0ea95a8ce355ccf98f5f0c4efa28f673cb9ebfae4433bba9",
        ),
      ]
    _ => abort("unlisted digest profile")
  }
}

///|
fn digest_profile_input(byte_length : Int32) -> String {
  "a".repeat(byte_length - 7) + "é😀\u{0000}"
}

///|
fn digest_profile_call(
  name : String,
  args : Array[(String?, OrderingExpr)],
  through_alias~ : Bool = false,
) -> OrderingExpr {
  let function = additive_select(sequence_var("std"), name)
  if through_alias {
    sequence_local(
      [("saved_digest", function)],
      shared_mode_call(sequence_var("saved_digest"), args),
    )
  } else {
    shared_mode_call(function, args)
  }
}

///|
test "DIG1 native SHA256 pads by UTF8 bytes around 56 and 64 bytes" {
  for (size, expected) in digest_profile_vectors("sha256") {
    transfer_value(
      sequence_call("sha256", [reflect_string(digest_profile_input(size))]),
      Json::string(expected),
    )
  }
}

///|
test "DIG2 native SHA512 pads by UTF8 bytes around 112 and 128 bytes" {
  for (size, expected) in digest_profile_vectors("sha512") {
    transfer_value(
      sequence_call("sha512", [reflect_string(digest_profile_input(size))]),
      Json::string(expected),
    )
  }
}

///|
test "DIG3 native digests retain arity aliases and independent repeated calls" {
  for name in ["sha256", "sha512"] {
    let vectors = digest_profile_vectors(name)
    let first = digest_profile_input(vectors[0].0)
    let last = digest_profile_input(vectors[4].0)
    let function = additive_select(sequence_var("std"), name)
    transfer_value(sequence_call("length", [function]), 1)
    for through_alias in [false, true] {
      let first_call = digest_profile_call(
        name,
        [(None, sequence_var("input"))],
        through_alias~,
      )
      let last_call = digest_profile_call(
        name,
        [(None, reflect_string(last))],
        through_alias~,
      )
      transfer_value(
        sequence_local(
          [("input", reflect_string(first))],
          ordering_array([
            first_call,
            last_call,
            first_call,
            sequence_var("input"),
          ]),
        ),
        Json::array([
          Json::string(vectors[0].1),
          Json::string(vectors[4].1),
          Json::string(vectors[0].1),
          Json::string(first),
        ]),
      )
      // These bindings do not choose either disputed s/str spelling.
      let safe = reflect_string(first)
      let invalid : Array[Array[(String?, OrderingExpr)]] = [
        [],
        [(None, safe), (None, safe)],
        [(Some("unknown"), safe)],
      ]
      for args in invalid {
        transfer_reject(digest_profile_call(name, args, through_alias~))
      }
    }
  }
}

///|
test "DIG4 native digest input errors are required only when the call is used" {
  for name in ["sha256", "sha512"] {
    for through_alias in [false, true] {
      let call = digest_profile_call(
        name,
        [(None, ordering_error("digest-required-input"))],
        through_alias~,
      )
      // transfer_error also checks an unused local call. Exact marker/kind
      // checks are embedding controls, not a diagnostic-priority promise.
      transfer_error(call, "digest-required-input")
      transfer_reject(sequence_call("type", [call]))
      transfer_value(
        shared_mode_call(make_function(["unused"], sequence_num(42)), [
          (None, call),
        ]),
        42,
      )
      transfer_value(transfer_if(reflect_bool(false), call, sequence_num(9)), 9)
    }
  }
}
