// Fixed std.jsonnet receiver binding, with the explicit project input profiles.
// Every changed method has std / std + {} / dependency-override controls.
// Expected results are literals; all ASTs are handmade using neutral builders.

///|
fn inherited_profile_controls() -> Array[OrderingExpr] {
  [
    sequence_var("std"),
    ordering_binary(sequence_var("std"), "+", reflect_object([])),
  ]
}

///|
test "inherited profile String methods observe dependencies and retain head admission" {
  let substring = inherited_standard_override(
    "substr",
    ["str", "from", "len"],
    reflect_string("x"),
  )
  for name in ["startsWith", "endsWith"] {
    inherited_standard_check(
      substring,
      name,
      [("a", reflect_string("abcd")), ("b", reflect_string("x"))],
      true,
      false,
    )
  }
  let membership = inherited_standard_override(
    "member",
    ["arr", "x"],
    reflect_bool(false),
  )
  let cases : Array[(String, Json)] = [
    ("lstripChars", "ax"),
    ("rstripChars", "xa"),
  ]
  for (name, ordinary) in cases {
    inherited_standard_check(
      membership,
      name,
      [("str", reflect_string("xax")), ("chars", reflect_string("x"))],
      "xax",
      ordinary,
    )
  }
  // stripChars must propagate this receiver through both adapted callees.
  sequence_value(
    inherited_standard_call(membership, "stripChars", [
      ("str", reflect_string("xax")),
      ("chars", reflect_string("x")),
    ]),
    "xax",
  )
  for library in inherited_profile_controls() {
    for name in ["startsWith", "endsWith"] {
      sequence_failure(
        inherited_standard_call(library, name, [
          ("a", ordering_array([])),
          ("b", reflect_string("")),
        ]),
        @moonjsonnet.Type,
        None,
      )
    }
    for name in ["lstripChars", "rstripChars"] {
      sequence_failure(
        inherited_standard_call(library, name, [
          ("str", ordering_array([])),
          ("chars", reflect_string("")),
        ]),
        @moonjsonnet.Runtime,
        None,
      )
      sequence_value(
        inherited_standard_call(library, name, [
          ("str", reflect_string("")),
          ("chars", ordering_error("unused empty characters")),
        ]),
        "",
      )
    }
  }
}

///|
test "inherited profile extrema observe folds while Array checks remain demand driven" {
  let library = inherited_standard_override(
    "foldl",
    ["func", "arr", "init"],
    sequence_num(42),
  )
  let cases : Array[(String, Json)] = [("minArray", 1), ("maxArray", 3)]
  for (name, ordinary) in cases {
    inherited_standard_check(
      library,
      name,
      [("arr", ordering_array([sequence_num(3), sequence_num(1)]))],
      42,
      ordinary,
    )
    for control in inherited_profile_controls() {
      sequence_failure(
        inherited_standard_call(control, name, [("arr", reflect_string("ab"))]),
        @moonjsonnet.Type,
        None,
      )
    }
    // Overridden length can select onEmpty without consuming either head.
    sequence_value(
      inherited_standard_call(inherited_sequence_library(0), name, [
        ("arr", ordering_error("unused extrema input")),
        ("keyF", ordering_error("unused extrema key")),
        ("onEmpty", sequence_num(42)),
      ]),
      42,
    )
  }
}

///|
test "inherited profile splitting observes dependencies with directional and integer count policies" {
  // Fixed C++ replaces this source definition with a native operation. The
  // inherited project contract follows its source-level receiver dependencies.
  inherited_standard_check(
    inherited_sequence_library(1),
    "splitLimit",
    [
      ("str", reflect_string("a,b")),
      ("c", reflect_string(",")),
      ("maxsplits", sequence_num(-1)),
    ],
    ["a"],
    ["a", "b"],
  )
  sequence_value(
    inherited_standard_call(inherited_sequence_library(1), "split", [
      ("str", reflect_string("a,b")),
      ("c", reflect_string(",")),
    ]),
    ["a"],
  )
  inherited_standard_check(
    inherited_standard_override("reverse", ["arr"], sequence_var("arr")),
    "splitLimitR",
    [
      ("str", reflect_string("aaa")),
      ("c", reflect_string("aa")),
      ("maxsplits", sequence_num(-1)),
    ],
    ["", "a"],
    ["a", ""],
  )
  for library in inherited_profile_controls() {
    for name in ["splitLimit", "splitLimitR"] {
      for maximum in [ordering_leaf("0.5", Literal(0.5)), sequence_num(-2)] {
        sequence_failure(
          inherited_standard_call(library, name, [
            ("str", reflect_string("a,b")),
            ("c", reflect_string(",")),
            ("maxsplits", maximum),
          ]),
          @moonjsonnet.Runtime,
          None,
        )
      }
      sequence_failure(
        inherited_standard_call(library, name, [
          ("str", reflect_string("a")),
          ("c", reflect_string("")),
          ("maxsplits", sequence_num(-1)),
        ]),
        @moonjsonnet.Runtime,
        None,
      )
    }
  }
}

///|
test "inherited profile Base64 encoding retains byte bounds and fractional conversion" {
  inherited_standard_check(
    inherited_standard_override("codepoint", ["str"], sequence_num(0)),
    "base64",
    [("input", reflect_string("f"))],
    "AA==",
    "Zg==",
  )
  for library in inherited_profile_controls() {
    // 1.5 truncates to byte 1; the literal sextets are A, Q, padding, padding.
    sequence_value(
      inherited_standard_call(library, "base64", [
        ("input", ordering_array([ordering_leaf("1.5", Literal(1.5))])),
      ]),
      "AQ==",
    )
    for
      input in [
        reflect_string("中"),
        ordering_array([ordering_leaf("255.5", Literal(255.5))]),
      ] {
      sequence_failure(
        inherited_standard_call(library, "base64", [("input", input)]),
        @moonjsonnet.Runtime,
        None,
      )
    }
  }
  // The private validation map must keep Array elements deferred. Both all's
  // check count and the encoder's input count are zero on this receiver.
  sequence_value(
    inherited_standard_call(inherited_sequence_library(0), "base64", [
      ("input", ordering_array([ordering_error("unused encoded byte")])),
    ]),
    "",
  )
}

///|
test "inherited profile byte decoding normalizes extensions only when str is consumed" {
  inherited_standard_check(
    inherited_sequence_library(0),
    "base64DecodeBytes",
    [("str", reflect_string("Zg=="))],
    [],
    [102],
  )
  for library in inherited_profile_controls() {
    for input in ["Zg==\r\n\r\n", "Zh=="] {
      sequence_value(
        inherited_standard_call(library, "base64DecodeBytes", [
          ("str", reflect_string(input)),
        ]),
        [102],
      )
    }
    sequence_failure(
      inherited_standard_call(library, "base64DecodeBytes", [
        ("str", ordering_array([])),
      ]),
      @moonjsonnet.Runtime,
      None,
    )
  }
  sequence_value(
    inherited_standard_call(
      inherited_sequence_library(0),
      "base64DecodeBytes",
      [("str", ordering_error("unused decoded input"))],
    ),
    [],
  )
}

///|
test "inherited profile TOML observes fields with valid keys lazy indent and resource bounds" {
  try {
    // The first run hit the source sort's evaluation-depth limit at 64.
    // Ordinary correctness uses the published default budget; the dedicated
    // output=32 and depth=24 rejection checks below keep their target limits.
    let check = fn(value : OrderingExpr, expected : Json) raise {
      for handmade in [false, true] {
        assert_eq(
          ordering_program(value, handmade).evaluate(
            limits=@moonjsonnet.Limits::default(),
          ),
          expected,
        )
      }
    }
    let reject_type = fn(value : OrderingExpr) raise {
      for handmade in [false, true] {
        assert_eq(
          ordering_program(ordering_unused(value), handmade).evaluate(
            limits=sequence_limits(),
          ),
          42,
        )
        let program = ordering_program(value, handmade)
        try program.evaluate(limits=@moonjsonnet.Limits::default()) catch {
          @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Type)
        } noraise {
          _ => fail("required TOML type failure was suppressed")
        }
      }
    }
    let value = reflect_object([(reflect_string("a"), 1, sequence_num(1))])
    check(
      inherited_standard_call(
        inherited_standard_override("objectFields", ["o"], ordering_array([])),
        "manifestTomlEx",
        [("value", value), ("indent", reflect_string(""))],
      ),
      "",
    )
    for library in inherited_profile_controls() {
      check(
        inherited_standard_call(library, "manifestTomlEx", [
          ("value", value),
          ("indent", reflect_string("")),
        ]),
        "a = 1",
      )
      check(
        inherited_standard_call(library, "manifestTomlEx", [
          ("value", reflect_object([(reflect_string(""), 1, sequence_num(1))])),
          ("indent", reflect_string("")),
        ]),
        "'' = 1",
      )
      check(
        inherited_standard_call(library, "manifestTomlEx", [
          ("value", value),
          ("indent", ordering_error("unused flat TOML indent")),
        ]),
        "a = 1",
      )
      reject_type(
        inherited_standard_call(library, "manifestTomlEx", [
          ("value", ordering_array([])),
          ("indent", reflect_string("")),
        ]),
      )
      reject_type(
        inherited_standard_call(library, "manifestTomlEx", [
          ("value", reflect_object([(reflect_string("section"), 1, value)])),
          ("indent", sequence_num(0)),
        ]),
      )
      let oversized = inherited_standard_call(library, "manifestTomlEx", [
        (
          "value",
          reflect_object([
            (
              reflect_string("a"),
              1,
              reflect_string(
                "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcd",
              ),
            ),
          ]),
        ),
        ("indent", reflect_string("")),
      ])
      // The adapter returns the empty key's quote directly, bypassing the
      // bare_allowed character set. This control must reach a text limit.
      let oversized_text = inherited_standard_call(library, "manifestTomlEx", [
        (
          "value",
          reflect_object([
            (
              reflect_string(""),
              1,
              reflect_string(
                "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcd",
              ),
            ),
          ]),
        ),
        ("indent", reflect_string("")),
      ])
      let recursive = sequence_local(
        [
          (
            "cycle",
            reflect_object([(reflect_string("child"), 1, sequence_var("cycle"))]),
          ),
        ],
        inherited_standard_call(library, "manifestTomlEx", [
          ("value", sequence_var("cycle")),
          ("indent", reflect_string("")),
        ]),
      )
      for
        (rendered, limits, output_limit, allow_array_limit) in [
          (
            oversized,
            { ..@moonjsonnet.Limits::default(), output_bytes: 32, },
            true,
            true,
          ),
          (
            oversized_text,
            { ..@moonjsonnet.Limits::default(), output_bytes: 32, },
            true,
            false,
          ),
          (
            recursive,
            { ..@moonjsonnet.Limits::default(), depth: 24, },
            false,
            false,
          ),
        ] {
        for handmade in [false, true] {
          // Observe length so the bound belongs to rendering, not outer JSON quoting.
          let program = ordering_program(
            sequence_call("length", [rendered]),
            handmade,
          )
          try program.evaluate(limits~) catch {
            @moonjsonnet.Error(d) => {
              assert_eq(d.kind, @moonjsonnet.Limit)
              if output_limit {
                // Native text writes and source String/Array concatenation
                // share output_bytes. With default steps, the small source
                // key-character set can hit only the Array output bound.
                assert_true(
                  d.message == "manifest output limit exceeded" ||
                  d.message == "string size limit exceeded" ||
                  (
                    allow_array_limit &&
                    d.message == "array size limit exceeded"
                  ),
                )
              } else {
                assert_true(d.message.contains("depth limit exceeded"))
              }
            }
          } noraise {
            _ => fail("TOML rendering exceeded its resource limit")
          }
        }
      }
    }
  } catch {
    @moonjsonnet.Error(d) => fail("TOML adapter diagnostic: " + d.format())
    error => raise error
  }
}

///|
test "inherited profile methods capture receivers while chosen native policies stay independent" {
  let library = inherited_standard_override(
    "foldl",
    ["func", "arr", "init"],
    sequence_num(42),
  )
  let args = [("arr", ordering_array([sequence_num(3), sequence_num(1)]))]
  let cases : Array[(OrderingExpr, Json)] = [
    (library, 42),
    (sequence_var("std"), 1),
  ]
  for (receiver, expected) in cases {
    sequence_value(
      sequence_local(
        [("saved", additive_select(receiver, "minArray"))],
        sequence_local(
          [
            (
              "holder",
              reflect_object([
                (reflect_string("minArray"), 2, sequence_var("saved")),
                (
                  reflect_string("foldl"),
                  2,
                  make_function(["func", "arr", "init"], sequence_num(99)),
                ),
              ]),
            ),
            ("std", ordering_error("unused adapter caller std")),
          ],
          inherited_standard_call(sequence_var("holder"), "minArray", args),
        ),
      ),
      expected,
    )
  }
  let wrapper = reflect_object([
    (
      reflect_string("minArray"),
      2,
      make_function(
        ["arr"],
        inherited_sequence_call(
          ordering_leaf("super", Var("super")),
          "minArray",
          [sequence_var("arr")],
        ),
      ),
    ),
  ])
  sequence_value(
    inherited_standard_call(
      ordering_binary(library, "+", wrapper),
      "minArray",
      args,
    ),
    42,
  )
  // Integral-part parity deliberately does not adopt the rejected round formula.
  let parity = inherited_standard_override("round", ["x"], sequence_num(1))
  inherited_standard_check(
    parity,
    "isEven",
    [("x", ordering_leaf("0.5", Literal(0.5)))],
    true,
    true,
  )
  inherited_standard_check(
    parity,
    "isOdd",
    [("x", ordering_leaf("0.5", Literal(0.5)))],
    false,
    false,
  )
}

///|
test "native and inherited tailstrict calls enforce binding then parameter heads and defaults" {
  // This is the published project tailstrict contract, not an assertion that
  // the fixed specification resolves its TODO about this call mode.
  for library in inherited_profile_controls() {
    for name in ["minArray", "maxArray"] {
      let callee = additive_select(library, name)
      let args = [(Some("arr"), ordering_array([sequence_num(1)]))]
      sequence_value(shared_mode_call(callee, args), 1)
      sequence_failure(
        shared_mode_call(callee, args, strict=true),
        @moonjsonnet.Runtime,
        Some("Expected at least one element in array. Got none"),
      )
      // Supplied heads are forced without inspecting unused nested payloads.
      sequence_value(
        shared_mode_call(
          callee,
          [
            (Some("arr"), ordering_array([sequence_num(1)])),
            (
              Some("onEmpty"),
              ordering_array([ordering_error("unused strict payload")]),
            ),
          ],
          strict=true,
        ),
        1,
      )
    }
    let strips = [
      (Some("str"), reflect_string("")),
      (Some("chars"), ordering_error("strict characters")),
    ]
    let strip = additive_select(library, "lstripChars")
    sequence_value(shared_mode_call(strip, strips), "")
    sequence_failure(
      shared_mode_call(strip, strips, strict=true),
      @moonjsonnet.Runtime,
      Some("strict characters"),
    )
    // Binding must reject an unknown argument before any supplied head runs.
    sequence_failure(
      shared_mode_call(
        strip,
        [
          (Some("str"), ordering_error("unforced invalid binding")),
          (Some("chars"), reflect_string("")),
          (Some("unknown"), sequence_num(0)),
        ],
        strict=true,
      ),
      @moonjsonnet.Runtime,
      Some("function has no parameter unknown"),
    )
    let fold = additive_select(library, "foldr")
    let fold_args = [
      (Some("func"), ordering_error("strict fold function")),
      (Some("arr"), ordering_array([])),
      (Some("init"), sequence_num(42)),
    ]
    sequence_value(shared_mode_call(fold, fold_args), 42)
    sequence_failure(
      shared_mode_call(fold, fold_args, strict=true),
      @moonjsonnet.Runtime,
      Some("strict fold function"),
    )
    let json = additive_select(library, "manifestJsonEx")
    let json_args = [
      (Some("value"), sequence_num(1)),
      (Some("indent"), ordering_error("strict JSON indent")),
    ]
    sequence_value(shared_mode_call(json, json_args), "1")
    sequence_failure(
      shared_mode_call(json, json_args, strict=true),
      @moonjsonnet.Runtime,
      Some("strict JSON indent"),
    )
  }
}
