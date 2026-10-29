// Frozen String/key criteria: SPEC-JSON-CONTRACTS-2026-10-23.md.
// Every quoted-text expectation is literal, not another quoting algorithm.

///|
fn json_string_text(value : String, expected : String) -> Unit raise {
  for name in ["manifestJsonEx", "manifestJson", "manifestJsonMinified"] {
    sequence_value(
      json_render(name, reflect_string(value)),
      Json::string(expected),
    )
  }
}

///|
test "JS1 JSON Strings preserve ordinary text and the complete C0 escape table" {
  for
    (value, expected) in [
      ("", "\"\""),
      (" ~/<>&'", "\" ~/<>&'\""),
      ("\"\\", "\"\\\"\\\\\""),
      ("é中😀e\u0301", "\"é中😀e\u0301\""),
      ("\u00a0", "\"\u00a0\""),
      (
        "\u0000\u0001\u0002\u0003\u0004\u0005\u0006\u0007\b\t\n\u000b\u000c\r\u000e\u000f",
        "\"\\u0000\\u0001\\u0002\\u0003\\u0004\\u0005\\u0006\\u0007\\b\\t\\n\\u000b\\f\\r\\u000e\\u000f\"",
      ),
      (
        "\u0010\u0011\u0012\u0013\u0014\u0015\u0016\u0017\u0018\u0019\u001a\u001b\u001c\u001d\u001e\u001f",
        "\"\\u0010\\u0011\\u0012\\u0013\\u0014\\u0015\\u0016\\u0017\\u0018\\u0019\\u001a\\u001b\\u001c\\u001d\\u001e\\u001f\"",
      ),
    ] {
    json_string_text(value, expected)
  }
}

///|
test "JS2 JSON Strings escape the complete C1 table with lowercase hex" {
  for
    (value, expected) in [
      ("\u007f", "\"\\u007f\""),
      (
        "\u0080\u0081\u0082\u0083\u0084\u0085\u0086\u0087\u0088\u0089\u008a\u008b\u008c\u008d\u008e\u008f",
        "\"\\u0080\\u0081\\u0082\\u0083\\u0084\\u0085\\u0086\\u0087\\u0088\\u0089\\u008a\\u008b\\u008c\\u008d\\u008e\\u008f\"",
      ),
      (
        "\u0090\u0091\u0092\u0093\u0094\u0095\u0096\u0097\u0098\u0099\u009a\u009b\u009c\u009d\u009e\u009f",
        "\"\\u0090\\u0091\\u0092\\u0093\\u0094\\u0095\\u0096\\u0097\\u0098\\u0099\\u009a\\u009b\\u009c\\u009d\\u009e\\u009f\"",
      ),
      ("~\u007f\u0080\u009f\u00a0", "\"~\\u007f\\u0080\\u009f\u00a0\""),
    ] {
    json_string_text(value, expected)
  }
}

///|
test "JS3 JSON Strings retain raw Unicode line and paragraph separators" {
  for
    (value, expected) in [
      ("\u2028", "\"\u2028\""),
      ("\u2029", "\"\u2029\""),
      ("\u2028\u2029", "\"\u2028\u2029\""),
      ("<>&\u2028é😀\u2029", "\"<>&\u2028é😀\u2029\""),
    ] {
    json_string_text(value, expected)
  }
}

///|
test "JS4 JSON visible keys share String escaping and preserve sorted layouts" {
  let object = reflect_object([
    (reflect_string("\u007f\u2028"), 1, reflect_string("x")),
    (reflect_string("a"), 1, reflect_string("\u0085")),
    (reflect_string("\n\"\\"), 1, reflect_string("\u2029")),
    (reflect_string("hidden"), 2, ordering_error("json-string-hidden")),
  ])
  for
    (name, expected) in [
      (
        "manifestJsonEx", "{\n  \"\\n\\\"\\\\\": \"\u2029\",\n  \"a\": \"\\u0085\",\n  \"\\u007f\u2028\": \"x\"\n}",
      ),
      (
        "manifestJson", "{\n    \"\\n\\\"\\\\\": \"\u2029\",\n    \"a\": \"\\u0085\",\n    \"\\u007f\u2028\": \"x\"\n}",
      ),
      (
        "manifestJsonMinified", "{\"\\n\\\"\\\\\":\"\u2029\",\"a\":\"\\u0085\",\"\\u007f\u2028\":\"x\"}",
      ),
    ] {
    sequence_value(json_render(name, object), Json::string(expected))
  }
  sequence_value(
    rounding_apply("manifestJsonEx", [
      (Some("value"), object),
      (Some("indent"), reflect_string("")),
      (Some("newline"), reflect_string(" ")),
      (Some("key_val_sep"), reflect_string(" : ")),
    ]),
    "{ \"\\n\\\"\\\\\" : \"\u2029\", \"a\" : \"\\u0085\", \"\\u007f\u2028\" : \"x\" }",
  )
  sequence_value(
    json_render(
      "manifestJsonMinified",
      reflect_object([
        (
          reflect_string("a"),
          1,
          ordering_array([
            reflect_string("\u0085"),
            reflect_object([
              (reflect_string("\u2028"), 1, reflect_string("\u007f")),
            ]),
          ]),
        ),
      ]),
    ),
    "{\"a\":[\"\\u0085\",{\"\u2028\":\"\\u007f\"}]}",
  )
}

///|
test "JS5 JSON String values and keys obey the fixed escapeStringJson identity" {
  let defaults = @moonjsonnet.Limits::default()
  let limits = {
    ..sequence_limits(),
    depth: defaults.depth,
    stack: defaults.stack,
  }
  let check = fn(value : OrderingExpr, expected : Json) raise {
    for handmade in [false, true] {
      assert_eq(ordering_program(value, handmade).evaluate(limits~), expected)
    }
  }
  for
    (value, expected) in [
      ("\u007f\u0085\u009f", "\"\\u007f\\u0085\\u009f\""),
      ("\u2028\u2029", "\"\u2028\u2029\""),
      ("\n\"\\/é😀", "\"\\n\\\"\\\\/é😀\""),
    ] {
    let string = reflect_string(value)
    let escaped = sequence_call("escapeStringJson", [string])
    // Literal text is primary; this relation independently checks delegation.
    check(escaped, Json::string(expected))
    for name in ["manifestJsonEx", "manifestJson", "manifestJsonMinified"] {
      check(json_render(name, string), Json::string(expected))
      check(ordering_binary(json_render(name, string), "==", escaped), true)
    }
    let object = reflect_object([(string, 1, sequence_num(0))])
    let compact = json_render("manifestJsonMinified", object)
    check(compact, Json::string("{" + expected + ":0}"))
    let escaped_key = ordering_binary(
      ordering_binary(reflect_string("{"), "+", escaped),
      "+",
      reflect_string(":0}"),
    )
    check(ordering_binary(compact, "==", escaped_key), true)
  }
}

///|
test "JS6 JSON String demand skips unused styles and preserves required errors" {
  sequence_value(
    rounding_apply("manifestJsonEx", [
      (Some("value"), reflect_string("safe")),
      (Some("indent"), ordering_error("json-string-unused-indent")),
      (Some("newline"), ordering_error("json-string-unused-newline")),
      (Some("key_val_sep"), ordering_error("json-string-unused-separator")),
    ]),
    "\"safe\"",
  )
  let bad = ordering_error("json-string-required")
  for name in ["manifestJsonEx", "manifestJson", "manifestJsonMinified"] {
    for
      value in [
        bad,
        ordering_array([reflect_string("safe"), bad]),
        reflect_object([(reflect_string("field"), 1, bad)]),
        reflect_object([(bad, 1, reflect_string("safe"))]),
      ] {
      // sequence_failure also checks that an unused whole call returns 42.
      sequence_failure(
        json_render(name, value),
        @moonjsonnet.Runtime,
        Some("json-string-required"),
      )
    }
  }
}

///|
test "JS7 JSON String byte limits count escaped expansion and raw Unicode" {
  for
    (value, expected, characters, expected_bytes) in [
      (reflect_string("\u007f"), "\"\\u007f\"", 8, 8),
      (reflect_string("\u0000\n"), "\"\\u0000\\n\"", 10, 10),
      (reflect_string("\u2028\u2029"), "\"\u2028\u2029\"", 4, 8),
      (reflect_string("é😀"), "\"é😀\"", 4, 8),
      (reflect_string("\u007f\u2028"), "\"\\u007f\u2028\"", 9, 11),
      (
        ordering_array([reflect_string("\u0085"), reflect_string("\u2028")]),
        "[\"\\u0085\",\"\u2028\"]",
        14,
        16,
      ),
      (
        reflect_object([(reflect_string("\u007f\u2028"), 1, sequence_num(0))]),
        "{\"\\u007f\u2028\":0}",
        13,
        15,
      ),
    ] {
    // The expected text is literal. UTF-8 bytes and String codepoint length
    // are distinct; std.length avoids charging outer JSON String escaping.
    let bytes = @utf8.encode(expected).length()
    assert_eq(bytes, expected_bytes)
    assert_eq(expected.iter().count(), characters)
    let call = sequence_call("length", [
      json_render("manifestJsonMinified", value),
    ])
    for handmade in [false, true] {
      let program = ordering_program(call, handmade)
      assert_eq(
        program.evaluate(limits={ ..sequence_limits(), output_bytes: bytes, }),
        Json::number(characters.to_double()),
      )
      try
        program.evaluate(limits={
          ..sequence_limits(),
          output_bytes: bytes - 1,
        })
      catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
      } noraise {
        _ => fail("JSON String output accepted a one-byte-short budget")
      }
    }
  }
}
