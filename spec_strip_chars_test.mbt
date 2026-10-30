// Pending execution: SPEC-STRIP-CHARS-2026-10-23.md.
// Independent expectations frozen before product execution or correction.

///|
test "strip functions remove directional character sets without altering interior Unicode data" {
  for
    (input, chars, left, right, both) in [
      ("", "", "", "", ""),
      ("", "a", "", "", ""),
      ("a", "", "a", "a", "a"),
      ("a", "a", "", "", ""),
      ("aaaa", "a", "", "", ""),
      ("cacabbbbaacc", "ac", "bbbbaacc", "cacabbbb", "bbbb"),
      ("abZba", "ab", "Zba", "abZ", "Z"),
      ("abZba", "bbaa", "Zba", "abZ", "Z"),
      ("x.y.x", "xy", ".y.x", "x.y.", ".y."),
      ("x😀x", "😀", "x😀x", "x😀x", "x😀x"),
      ("😀中😀", "😀", "中😀", "😀中", "中"),
      ("\u0000x\u0000", "\u0000", "x\u0000", "\u0000x", "x"),
      ("\u0301e\u0301", "\u0301", "e\u0301", "\u0301e", "e"),
      (
        "e\u0301xe\u0301", "é", "e\u0301xe\u0301", "e\u0301xe\u0301", "e\u0301xe\u0301",
      ),
      (" \tx\n ", " \t\n", "x\n ", " \tx", "x"),
      (" A a ", "a", " A a ", " A a ", " A a "),
    ] {
    for
      (name, expected) in [
        ("lstripChars", left),
        ("rstripChars", right),
        ("stripChars", both),
      ] {
      sequence_value(
        sequence_call(name, [reflect_string(input), reflect_string(chars)]),
        Json::string(expected),
      )
      sequence_value(
        rounding_apply(name, [
          (Some("chars"), reflect_string(chars)),
          (Some("str"), reflect_string(input)),
        ]),
        Json::string(expected),
      )
    }
  }
}

///|
fn strip_empty(name : String) -> Unit raise {
  let unread = ordering_error("strip-empty-characters-unread")
  for
    chars in [
      unread,
      ordering_leaf("null", Literal(Json::null())),
      reflect_bool(false),
      sequence_num(1),
      ordering_array([unread]),
      merge_patch_object([("x", unread)]),
      value_head_function(unread, unread),
    ] {
    let value = sequence_call(name, [reflect_string(""), chars])
    sequence_value(value, "")
    sequence_value(sequence_call("type", [value]), "string")
    sequence_value(sequence_call("length", [value]), 0)
  }
}

///|
test "lstripChars returns an empty string without demanding characters" {
  strip_empty("lstripChars")
}

///|
test "rstripChars returns an empty string without demanding characters" {
  strip_empty("rstripChars")
}

///|
test "stripChars returns an empty string without demanding characters" {
  strip_empty("stripChars")
}

///|
test "strip empty results share the input head and never run a successful character gate" {
  for name in ["lstripChars", "rstripChars", "stripChars"] {
    let result = sequence_var("result")
    let value = additive_probe_scope(
      sequence_local(
        [
          ("input", rewrite_gate(reflect_string("input"), reflect_string(""))),
          ("chars", rewrite_gate(reflect_string("chars"), reflect_string("a"))),
          (
            "result",
            sequence_call(name, [sequence_var("input"), sequence_var("chars")]),
          ),
        ],
        sequence_gate(
          [(sequence_call("length", [result]), 0)],
          ordering_array([result, result, sequence_call("type", [result])]),
        ),
      ),
    )
    for handmade in [false, true] {
      let counts : Map[String, Int32] = Map([])
      assert_eq(
        ordering_program(ordering_unused(value), handmade).evaluate(
          native_functions=rewrite_natives(counts),
          limits=sequence_limits(),
        ),
        42,
      )
      assert_eq(counts.length(), 0)
      assert_eq(
        ordering_program(value, handmade).evaluate(
          native_functions=rewrite_natives(counts),
          limits=sequence_limits(),
        ),
        ["", "", "string"],
      )
      assert_eq(counts, Map([("input", 1)]))
    }
  }
}

///|
test "strip functions propagate required string and character errors before result inspection" {
  for name in ["lstripChars", "rstripChars", "stripChars"] {
    for
      (input, chars, marker) in [
        (
          ordering_error("strip-needed-input"),
          reflect_string(""),
          "strip-needed-input",
        ),
        (
          reflect_string("x"),
          ordering_error("strip-needed-chars"),
          "strip-needed-chars",
        ),
        (
          ordering_binary(
            reflect_string("x"),
            "+",
            ordering_error("strip-strict-input"),
          ),
          reflect_string(""),
          "strip-strict-input",
        ),
      ] {
      let value = sequence_call(name, [input, chars])
      for
        observation in [
          value,
          sequence_call("type", [value]),
          sequence_call("length", [value]),
          make_index(value, 0),
        ] {
        sequence_failure(observation, @moonjsonnet.Runtime, Some(marker))
      }
    }
  }
}

///|
test "strip functions reject invalid needed character heads without reading their payloads" {
  let unread = rewrite_gate(
    reflect_string("payload"),
    ordering_error("strip-rejected-payload"),
  )
  for name in ["lstripChars", "rstripChars", "stripChars"] {
    for
      chars in [
        ordering_leaf("null", Literal(Json::null())),
        reflect_bool(false),
        sequence_num(1),
        merge_patch_object([("x", unread)]),
        value_head_function(unread, unread),
      ] {
      let value = additive_probe_scope(
        sequence_call(name, [reflect_string("a"), chars]),
      )
      for handmade in [false, true] {
        let counts : Map[String, Int32] = Map([])
        assert_eq(
          ordering_program(ordering_unused(value), handmade).evaluate(
            native_functions=rewrite_natives(counts),
            limits=sequence_limits(),
          ),
          42,
        )
        try
          ordering_program(value, handmade).evaluate(
            native_functions=rewrite_natives(counts),
            limits=sequence_limits(),
          )
        catch {
          @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
        } noraise {
          _ => fail("invalid strip character head succeeded")
        }
        assert_eq(counts.length(), 0)
      }
    }
  }
}

///|
test "strip functions reject length-invalid input heads before the character gate" {
  for name in ["lstripChars", "rstripChars", "stripChars"] {
    for
      input in [
        ordering_leaf("null", Literal(Json::null())),
        reflect_bool(false),
        sequence_num(1),
      ] {
      let value = additive_probe_scope(
        sequence_call(name, [
          rewrite_gate(reflect_string("input"), input),
          rewrite_gate(reflect_string("chars"), reflect_string("a")),
        ]),
      )
      for handmade in [false, true] {
        let counts : Map[String, Int32] = Map([])
        try
          ordering_program(value, handmade).evaluate(
            native_functions=rewrite_natives(counts),
            limits=sequence_limits(),
          )
        catch {
          @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
        } noraise {
          _ => fail("length-invalid strip input succeeded")
        }
        assert_eq(counts, Map([("input", 1)]))
      }
    }
  }
}

///|
test "strip functions preserve original strings and share required inputs across repeated reads" {
  for
    (name, expected, size) in [
      ("lstripChars", "x😀aa", 4),
      ("rstripChars", "aa😀x", 4),
      ("stripChars", "x", 1),
    ] {
    for inputs_first in [false, true] {
      let input = sequence_var("input")
      let chars = sequence_var("chars")
      let result = sequence_var("result")
      let before = [
        (sequence_call("length", [input]), 7),
        (sequence_call("length", [chars]), 2),
      ]
      let after = [(sequence_call("length", [result]), size)]
      let value = additive_probe_scope(
        sequence_local(
          [
            (
              "input",
              rewrite_gate(
                reflect_string("input"),
                reflect_string("aa😀x😀aa"),
              ),
            ),
            ("alias", input),
            (
              "chars",
              rewrite_gate(reflect_string("chars"), reflect_string("a😀")),
            ),
            ("result", sequence_call(name, [input, chars])),
          ],
          sequence_gate(
            if inputs_first {
              before + after
            } else {
              after + before
            },
            ordering_array([
              input,
              sequence_var("alias"),
              chars,
              result,
              result,
              sequence_call(name, [input, chars]),
            ]),
          ),
        ),
      )
      for handmade in [false, true] {
        let counts : Map[String, Int32] = Map([])
        assert_eq(
          ordering_program(ordering_unused(value), handmade).evaluate(
            native_functions=rewrite_natives(counts),
            limits=sequence_limits(),
          ),
          42,
        )
        assert_eq(counts.length(), 0)
        assert_eq(
          ordering_program(value, handmade).evaluate(
            native_functions=rewrite_natives(counts),
            limits=sequence_limits(),
          ),
          [
            "aa😀x😀aa",
            "aa😀x😀aa",
            "a😀",
            Json::string(expected),
            Json::string(expected),
            Json::string(expected),
          ],
        )
        assert_eq(counts, Map([("input", 1), ("chars", 1)]))
      }
    }
  }
}

///|
test "strip functions reject invalid bindings before argument gates and retain static checks" {
  let input = rewrite_gate(reflect_string("input"), reflect_string("a"))
  let chars = rewrite_gate(reflect_string("chars"), reflect_string("a"))
  for name in ["lstripChars", "rstripChars", "stripChars"] {
    for
      args in [
        [sequence_var("strip_missing"), reflect_string("")],
        [reflect_string(""), sequence_var("strip_missing")],
      ] {
      pair_reject(ordering_unused(sequence_call(name, args)))
    }
    for
      args in [
        [],
        [(Some("str"), input)],
        [(Some("chars"), chars)],
        [(None, input), (None, chars), (None, input)],
        [(Some("str"), input), (Some("unexpected"), chars)],
        [(None, input), (Some("str"), input), (Some("chars"), chars)],
      ] {
      let value = additive_probe_scope(rounding_apply(name, args))
      for handmade in [false, true] {
        let counts : Map[String, Int32] = Map([])
        assert_eq(
          ordering_program(ordering_unused(value), handmade).evaluate(
            native_functions=rewrite_natives(counts),
            limits=sequence_limits(),
          ),
          42,
        )
        try
          ordering_program(value, handmade).evaluate(
            native_functions=rewrite_natives(counts),
            limits=sequence_limits(),
          )
        catch {
          @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
        } noraise {
          _ => fail("invalid strip binding succeeded")
        }
        assert_eq(counts.length(), 0)
      }
    }
  }
}

///|
test "strip functions inspect all array character members and share their required values" {
  for name in ["lstripChars", "rstripChars", "stripChars"] {
    sequence_value(
      sequence_call(name, [
        reflect_string("aba"),
        ordering_array([reflect_string("a"), reflect_string("b")]),
      ]),
      "",
    )
    sequence_value(
      sequence_call(name, [reflect_string("aba"), ordering_array([])]),
      "aba",
    )
    let result = sequence_var("result")
    let value = additive_probe_scope(
      sequence_local(
        [
          (
            "chars",
            rewrite_gate(
              reflect_string("chars"),
              ordering_array([
                rewrite_gate(reflect_string("first"), reflect_string("a")),
                rewrite_gate(reflect_string("later"), reflect_string("b")),
              ]),
            ),
          ),
          (
            "result",
            sequence_call(name, [reflect_string("aaa"), sequence_var("chars")]),
          ),
        ],
        sequence_gate(
          [(sequence_call("length", [result]), 0)],
          ordering_array([result, result]),
        ),
      ),
    )
    for handmade in [false, true] {
      let counts : Map[String, Int32] = Map([])
      assert_eq(
        ordering_program(ordering_unused(value), handmade).evaluate(
          native_functions=rewrite_natives(counts),
          limits=sequence_limits(),
        ),
        42,
      )
      assert_eq(counts.length(), 0)
      assert_eq(
        ordering_program(value, handmade).evaluate(
          native_functions=rewrite_natives(counts),
          limits=sequence_limits(),
        ),
        ["", ""],
      )
      assert_eq(counts, Map([("chars", 1), ("first", 1), ("later", 1)]))
    }
  }
}

///|
test "strip functions propagate later array character errors despite an earlier match" {
  for name in ["lstripChars", "rstripChars", "stripChars"] {
    let value = sequence_call(name, [
      reflect_string("a"),
      ordering_array([
        reflect_string("a"),
        ordering_error("strip-required-later-member"),
      ]),
    ])
    for
      observation in [
        value,
        sequence_call("type", [value]),
        sequence_call("length", [value]),
      ] {
      sequence_failure(
        observation,
        @moonjsonnet.Runtime,
        Some("strip-required-later-member"),
      )
    }
  }
}
