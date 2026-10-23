// Pending execution: SPEC-SPLIT-LIMITS-2026-10-23.md.
// Literal expectations precede execution. Fractional/other-negative limits and
// unlimited right splits with overlapping separators remain unadjudicated.

///|
fn split_contract_call(
  name : String,
  input : OrderingExpr,
  separator : OrderingExpr,
  maximum : OrderingExpr,
) -> OrderingExpr {
  sequence_call(
    name,
    if name == "split" {
      [input, separator]
    } else {
      [input, separator, maximum]
    },
  )
}

///|
test "split contracts preserve directional nonoverlapping data and named parameters" {
  let unlimited : Array[(String, String, Json)] = [
    ("", "::", [""]),
    ("abc", "::", ["abc"]),
    ("::a::b::", "::", ["", "a", "b", ""]),
    ("::::", "::", ["", "", ""]),
    ("aaa", "aa", ["", "a"]),
    ("😀a😀b😀", "😀", ["", "a", "b", ""]),
    ("a\u0000b\u0000", "\u0000", ["a", "b", ""]),
    ("e\u0301/xé", "é", ["e\u0301/x", ""]),
  ]
  for (input, separator, expected) in unlimited {
    sequence_value(
      sequence_call("split", [reflect_string(input), reflect_string(separator)]),
      expected,
    )
    sequence_value(
      rounding_apply("split", [
        (Some("c"), reflect_string(separator)),
        (Some("str"), reflect_string(input)),
      ]),
      expected,
    )
  }
  let limited : Array[(String, String, Int, Json, Json)] = [
    ("", "::", 0, [""], [""]),
    ("abc", "::", 1, ["abc"], ["abc"]),
    ("a::b::c", "::", 0, ["a::b::c"], ["a::b::c"]),
    ("a::b::c", "::", 1, ["a", "b::c"], ["a::b", "c"]),
    ("a::b::c", "::", 2, ["a", "b", "c"], ["a", "b", "c"]),
    ("a::b::c", "::", -1, ["a", "b", "c"], ["a", "b", "c"]),
    ("a::b::c", "::", 2147483647, ["a", "b", "c"], ["a", "b", "c"]),
    ("::a::", "::", 1, ["", "a::"], ["::a", ""]),
    ("::::", "::", 1, ["", "::"], ["::", ""]),
    ("::::", "::", 2, ["", "", ""], ["", "", ""]),
    ("aaa", "aa", 1, ["", "a"], ["a", ""]),
    ("ababa", "aba", 1, ["", "ba"], ["ab", ""]),
    ("😀a😀b😀", "😀", 1, ["", "a😀b😀"], ["😀a😀b", ""]),
    ("😀a😀b😀", "😀", 2, ["", "a", "b😀"], ["😀a", "b", ""]),
    ("a\u0000b\u0000", "\u0000", 1, ["a", "b\u0000"], ["a\u0000b", ""]),
    ("e\u0301/xé", "é", 1, ["e\u0301/x", ""], ["e\u0301/x", ""]),
  ]
  for (input, separator, maximum, left, right) in limited {
    for (name, expected) in [("splitLimit", left), ("splitLimitR", right)] {
      sequence_value(
        split_contract_call(
          name,
          reflect_string(input),
          reflect_string(separator),
          sequence_num(maximum),
        ),
        expected,
      )
      sequence_value(
        rounding_apply(name, [
          (Some("maxsplits"), sequence_num(maximum)),
          (Some("c"), reflect_string(separator)),
          (Some("str"), reflect_string(input)),
        ]),
        expected,
      )
    }
  }
}

///|
fn split_wide_limit(name : String, handmade : Bool) -> Unit raise {
  let cases : Array[(String, String, Json)] = [
    ("", ",", [""]),
    ("abc", "-", ["abc"]),
    ("a,b,c", ",", ["a", "b", "c"]),
    ("aaa", "aa", if name == "splitLimitR" { ["a", ""] } else { ["", "a"] }),
  ]
  for
    (source, number) in [
      ("2147483648", 2147483648.0),
      ("9007199254740992", 9007199254740992.0),
      ("1e308", 1.0e308),
    ] {
    let maximum = ordering_leaf(source, Literal(Json::number(number)))
    for (input, separator, expected) in cases {
      let positional = split_contract_call(
        name,
        reflect_string(input),
        reflect_string(separator),
        maximum,
      )
      let named = rounding_apply(name, [
        (Some("maxsplits"), maximum),
        (Some("str"), reflect_string(input)),
        (Some("c"), reflect_string(separator)),
      ])
      for value in [positional, named] {
        assert_eq(
          ordering_program(value, handmade).evaluate(limits=sequence_limits()),
          expected,
        )
        assert_eq(
          ordering_program(sequence_call("type", [value]), handmade).evaluate(
            limits=sequence_limits(),
          ),
          "array",
        )
      }
    }
  }
}

///|
test "source splitLimit accepts finite integral limits beyond Int32" {
  split_wide_limit("splitLimit", false)
}

///|
test "handmade splitLimit accepts finite integral limits beyond Int32" {
  split_wide_limit("splitLimit", true)
}

///|
test "source splitLimitR accepts finite integral limits beyond Int32" {
  split_wide_limit("splitLimitR", false)
}

///|
test "handmade splitLimitR accepts finite integral limits beyond Int32" {
  split_wide_limit("splitLimitR", true)
}

///|
fn split_guard_failure(
  value : OrderingExpr,
  kind : @moonjsonnet.ErrorKind,
) -> Unit raise {
  let value = additive_probe_scope(value)
  for handmade in [false, true] {
    let counts : Map[String, Int] = Map([])
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
      @moonjsonnet.Error(d) => assert_eq(d.kind, kind)
    } noraise {
      _ => fail("invalid split argument head succeeded")
    }
    assert_eq(
      counts.length(),
      0,
      msg="split guards must skip later arguments and rejected payloads",
    )
  }
}

///|
test "split input guards reject before separator and limit gates" {
  let unread = rewrite_gate(
    reflect_string("payload"),
    ordering_error("split-rejected-payload"),
  )
  for name in ["split", "splitLimit", "splitLimitR"] {
    for
      input in [
        ordering_leaf("null", Literal(Json::null())),
        reflect_bool(false),
        sequence_num(1),
        ordering_array([unread]),
        merge_patch_object([("x", unread)]),
        value_head_function(unread, unread),
      ] {
      split_guard_failure(
        split_contract_call(
          name,
          input,
          rewrite_gate(reflect_string("separator"), reflect_string(",")),
          rewrite_gate(reflect_string("maximum"), sequence_num(1)),
        ),
        if name == "split" {
          @moonjsonnet.Assertion
        } else {
          @moonjsonnet.Type
        },
      )
    }
  }
}

///|
test "split separator guards reject wrong or empty heads before limit gates" {
  let unread = rewrite_gate(
    reflect_string("payload"),
    ordering_error("split-rejected-payload"),
  )
  for name in ["split", "splitLimit", "splitLimitR"] {
    for
      separator in [
        ordering_leaf("null", Literal(Json::null())),
        reflect_bool(false),
        sequence_num(1),
        ordering_array([unread]),
        merge_patch_object([("x", unread)]),
        value_head_function(unread, unread),
      ] {
      split_guard_failure(
        split_contract_call(
          name,
          reflect_string(""),
          separator,
          rewrite_gate(reflect_string("maximum"), sequence_num(0)),
        ),
        if name == "split" {
          @moonjsonnet.Assertion
        } else {
          @moonjsonnet.Type
        },
      )
    }
    split_guard_failure(
      split_contract_call(
        name,
        reflect_string(""),
        reflect_string(""),
        rewrite_gate(reflect_string("maximum"), sequence_num(0)),
      ),
      if name == "split" {
        @moonjsonnet.Assertion
      } else {
        @moonjsonnet.Runtime
      },
    )
  }
}

///|
test "split limits reject nonnumber heads without forcing their payloads" {
  let unread = rewrite_gate(
    reflect_string("payload"),
    ordering_error("split-rejected-payload"),
  )
  for name in ["splitLimit", "splitLimitR"] {
    for
      maximum in [
        ordering_leaf("null", Literal(Json::null())),
        reflect_bool(false),
        reflect_string("1"),
        ordering_array([unread]),
        merge_patch_object([("x", unread)]),
        value_head_function(unread, unread),
      ] {
      split_guard_failure(
        split_contract_call(
          name,
          reflect_string(""),
          reflect_string(","),
          maximum,
        ),
        @moonjsonnet.Type,
      )
    }
  }
}

///|
test "split contracts require valid argument heads before observing the result array" {
  for name in ["split", "splitLimit", "splitLimitR"] {
    let cases = [
      (
        ordering_error("split-needed-input"),
        reflect_string(","),
        sequence_num(0),
        "split-needed-input",
      ),
      (
        reflect_string(""),
        ordering_error("split-needed-separator"),
        sequence_num(0),
        "split-needed-separator",
      ),
      (
        ordering_binary(
          reflect_string("x"),
          "+",
          ordering_error("split-strict-input"),
        ),
        reflect_string(","),
        sequence_num(0),
        "split-strict-input",
      ),
    ]
    let cases = if name == "split" {
      cases
    } else {
      cases +
      [
        (
          reflect_string(""),
          reflect_string(","),
          ordering_error("split-needed-limit"),
          "split-needed-limit",
        ),
      ]
    }
    for (input, separator, maximum, marker) in cases {
      let value = split_contract_call(name, input, separator, maximum)
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
test "split contracts share required inputs and preserve originals across result reads" {
  let cases : Array[(String, Json, Int)] = [
    ("split", ["a", "b", "c"], 3),
    ("splitLimit", ["a", "b::c"], 2),
    ("splitLimitR", ["a::b", "c"], 2),
  ]
  for (name, expected, size) in cases {
    let input = sequence_var("input")
    let separator = sequence_var("separator")
    let maximum = sequence_var("maximum")
    let result = sequence_var("result")
    let value = additive_probe_scope(
      sequence_local(
        [
          (
            "input",
            rewrite_gate(reflect_string("input"), reflect_string("a::b::c")),
          ),
          (
            "separator",
            rewrite_gate(reflect_string("separator"), reflect_string("::")),
          ),
          ("maximum", rewrite_gate(reflect_string("maximum"), sequence_num(1))),
          ("result", split_contract_call(name, input, separator, maximum)),
        ],
        sequence_gate(
          [(sequence_call("length", [result]), size)],
          ordering_array([
            result,
            result,
            split_contract_call(name, input, separator, maximum),
            input,
            separator,
          ]),
        ),
      ),
    )
    for handmade in [false, true] {
      let counts : Map[String, Int] = Map([])
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
        [expected, expected, expected, "a::b::c", "::"],
      )
      let expected_counts = Map([("input", 1), ("separator", 1)])
      if name != "split" {
        expected_counts["maximum"] = 1
      }
      assert_eq(counts, expected_counts)
    }
  }
}

///|
test "split contracts reject invalid bindings before gates and retain static free-name errors" {
  let input = rewrite_gate(reflect_string("input"), reflect_string("a,b"))
  let separator = rewrite_gate(reflect_string("separator"), reflect_string(","))
  let maximum = rewrite_gate(reflect_string("maximum"), sequence_num(1))
  for name in ["split", "splitLimit", "splitLimitR"] {
    for
      (str, c, n) in [
        (sequence_var("split_missing"), reflect_string(","), sequence_num(0)),
        (reflect_string(""), sequence_var("split_missing"), sequence_num(0)),
      ] {
      pair_reject(ordering_unused(split_contract_call(name, str, c, n)))
    }
    if name != "split" {
      pair_reject(
        ordering_unused(
          split_contract_call(
            name,
            reflect_string(""),
            reflect_string(","),
            sequence_var("split_missing"),
          ),
        ),
      )
    }
    let common = [
      [],
      [(Some("str"), input)],
      [(Some("str"), input), (Some("unexpected"), separator)],
      [(None, input), (Some("str"), input), (Some("c"), separator)],
    ]
    let args_list = common +
      (if name == "split" {
        [[(None, input), (None, separator), (None, maximum)]]
      } else {
        [
          [(None, input), (None, separator)],
          [(None, input), (None, separator), (None, maximum), (None, maximum)],
        ]
      })
    for args in args_list {
      split_guard_failure(rounding_apply(name, args), @moonjsonnet.Runtime)
    }
  }
}
