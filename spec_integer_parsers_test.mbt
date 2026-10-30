// Independent criteria: SPEC-INTEGER-PARSERS-2026-10-23.md.

///|
fn integer_parser_call(name : String, value : OrderingExpr) -> OrderingExpr {
  rounding_apply(name, [(None, value)])
}

///|
fn integer_parser_wide(handmade : Bool) -> Unit raise {
  for
    (text, expected) in [
      ("100000000000000000000", 100000000000000000000.0),
      ("-100000000000000000000", -100000000000000000000.0),
    ] {
    assert_eq(
      ordering_program(
        integer_parser_call("parseInt", reflect_string(text)),
        handmade,
      ).evaluate(limits=sequence_limits()),
      Json::number(expected),
    )
  }
}

///|
fn integer_parser_plus(handmade : Bool) -> Unit raise {
  let call = integer_parser_call("parseInt", reflect_string("+12"))
  try
    ordering_program(call, handmade).evaluate(limits=sequence_limits())
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
  } noraise {
    _ => fail("fixed parseInt helper does not admit a leading plus")
  }
}

///|
test "integer parsers preserve exact digits case named inputs and radix powers" {
  for
    (name, data, expected) in [
      ("parseInt", "000123", 123.0),
      ("parseInt", "-000123", -123.0),
      ("parseInt", "-0", 0.0),
      ("parseInt", "9007199254740991", 9007199254740991.0),
      ("parseInt", "9007199254740992", 9007199254740992.0),
      ("parseOctal", "000755", 493.0),
      ("parseOctal", "01234567", 342391.0),
      ("parseOctal", "0", 0.0),
      ("parseOctal", "1" + "0".repeat(24), 4722366482869645213696.0),
      ("parseHex", "ABCDEF", 11259375.0),
      ("parseHex", "abcdef", 11259375.0),
      ("parseHex", "aBcDeF", 11259375.0),
      ("parseHex", "DeAdBeEf", 3735928559.0),
      ("parseHex", "00", 0.0),
      ("parseHex", "1" + "0".repeat(20), 1208925819614629174706176.0),
    ] {
    for named in [false, true] {
      sequence_value(
        rounding_apply(name, [
          (if named { Some("str") } else { None }, reflect_string(data)),
        ]),
        Json::number(expected),
      )
    }
  }
}

///|
test "source parseInt rejects a plus according to the fixed definition" {
  integer_parser_plus(false)
}

///|
test "handmade parseInt rejects a plus according to the fixed definition" {
  integer_parser_plus(true)
}

///|
test "source parseInt accepts exact finite decimal values beyond Int64" {
  integer_parser_wide(false)
}

///|
test "handmade parseInt accepts exact finite decimal values beyond Int64" {
  integer_parser_wide(true)
}

///|
test "integer parsers reject clear malformed data and wrong heads without payload demand" {
  for name in ["parseInt", "parseOctal", "parseHex"] {
    let malformed = [
      "", "+", "-", " ", "\n1", "1 ", "1_0", "0x10", "0X10", "0o10", "１２", "1\u0000",
      "😀",
    ]
    let extra = match name {
      "parseInt" => ["1.0", "1e2", "a"]
      "parseOctal" => ["8", "9", "a", "-1", "+1"]
      _ => ["g", "G", "-F", "+F", "/", "@"]
    }
    for text in malformed + extra {
      sequence_failure(
        integer_parser_call(name, reflect_string(text)),
        if name == "parseInt" {
          @moonjsonnet.Runtime
        } else {
          @moonjsonnet.Assertion
        },
        None,
      )
    }
    let unread = ordering_error("integer-parser-unread")
    for
      value in [
        ordering_leaf("null", Literal(Json::null())),
        reflect_bool(false),
        sequence_num(1),
        ordering_array([unread]),
        merge_patch_object([("x", unread)]),
        value_head_function(unread, unread),
      ] {
      sequence_failure(
        integer_parser_call(name, value),
        if name == "parseInt" {
          @moonjsonnet.Type
        } else {
          @moonjsonnet.Assertion
        },
        None,
      )
    }
    sequence_failure(
      integer_parser_call(name, ordering_error("integer-parser-needed-input")),
      @moonjsonnet.Runtime,
      Some("integer-parser-needed-input"),
    )
  }
}

///|
test "integer parsers reject actual overflow before inspection and retain lazy static binding boundaries" {
  let limits = { ..sequence_limits(), steps: 100000, }
  for
    (name, digits) in [
      ("parseInt", 310),
      ("parseOctal", 342),
      ("parseHex", 256),
    ] {
    let parsed = integer_parser_call(
      name,
      reflect_string("1" + "0".repeat(digits)),
    )
    let observed = sequence_call("type", [parsed])
    for handmade in [false, true] {
      assert_eq(
        ordering_program(ordering_unused(observed), handmade).evaluate(limits~),
        42,
      )
      try ordering_program(observed, handmade).evaluate(limits~) catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
      } noraise {
        _ => fail("an overflowing parser returned a Number head")
      }
    }
    pair_reject(
      ordering_unused(
        integer_parser_call(name, sequence_var("integer_parser_missing")),
      ),
    )
    for
      args in [
        [],
        [
          (
            Some("not_str"),
            rewrite_gate(reflect_string("binding"), reflect_string("12")),
          ),
        ],
      ] {
      let value = additive_probe_scope(rounding_apply(name, args))
      for handmade in [false, true] {
        let counts : Map[String, Int32] = Map([])
        try
          ordering_program(value, handmade).evaluate(
            native_functions=rewrite_natives(counts),
            limits~,
          )
        catch {
          @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
        } noraise {
          _ => fail("invalid numeric parser binding succeeded")
        }
        assert_eq(counts.length(), 0)
      }
    }
  }
}
