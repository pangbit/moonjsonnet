// Fixed strReplace criteria: SPEC-STRING-CONTRACTS-EVIDENCE-2026-10-22.md.
// Literal outputs are independent of the implementation; every call also has
// a handmade AST. Rejection checks do not mandate an error tag or winner.

///|
fn replace_contract_call(
  str : OrderingExpr,
  from : OrderingExpr,
  to : OrderingExpr,
) -> OrderingExpr {
  sequence_call("strReplace", [str, from, to])
}

///|
fn replace_contract_text(
  str : String,
  from : String,
  to : String,
) -> OrderingExpr {
  replace_contract_call(
    reflect_string(str),
    reflect_string(from),
    reflect_string(to),
  )
}

///|
fn replace_contract_reject(call : OrderingExpr) -> Unit raise {
  for handmade in [false, true] {
    try
      ordering_program(call, handmade).evaluate(limits=sequence_limits())
    catch {
      @moonjsonnet.Error(_) => ()
    } noraise {
      _ => fail("strReplace accepted an invalid call")
    }
  }
}

///|
test "SR1 strReplace retains literal ASCII replacement and nonoverlapping results" {
  for
    (str, from, to, expected) in [
      (
        "I like to skate with my skateboard", "skate", "surf", "I like to surf with my surfboard",
      ),
      ("", "a", "x", ""),
      ("abc", "z", "X", "abc"),
      ("ab", "abc", "X", "ab"),
      ("abba", "b", "b", "abba"),
      ("banana", "a", "", "bnn"),
      ("aaa", "a", "X", "XXX"),
      ("aaaaa", "aa", "X", "XXa"),
      ("ababa", "aba", "X", "Xba"),
      ("abcabc", "abc", "_", "__"),
      ("aaa", "a", "aa", "aaaaaa"),
      ("abab", "ab", "abab", "abababab"),
      ("a.b.a", ".", "$", "a$b$a"),
    ] {
    sequence_value(replace_contract_text(str, from, to), Json::string(expected))
  }
}

///|
test "SR2 strReplace uses exact Unicode codepoint patterns including NUL" {
  for
    (str, from, to, expected) in [
      ("😀a😀", "😀", "中", "中a中"),
      ("A\u0000B\u0000", "\u0000", "é", "AéBé"),
      ("e\u0301é e\u0301", "e\u0301", "X", "Xé X"),
      ("e\u0301é", "\u0301", "", "eé"),
      ("é", "e\u0301", "X", "é"),
      ("😀😀😀", "😀😀", "x", "x😀"),
      ("中😀中😀", "中😀", "é", "éé"),
      ("\u0000x\u0000", "\u0000x", "😀", "😀\u0000"),
    ] {
    sequence_value(replace_contract_text(str, from, to), Json::string(expected))
  }
}

///|
test "SR3 strReplace binds required names and aliases without defaults" {
  let str = reflect_string("ababa")
  let from = reflect_string("ab")
  let to = reflect_string("X")
  let arguments = [(Some("to"), to), (Some("str"), str), (Some("from"), from)]
  sequence_value(replace_contract_call(str, from, to), "XXa")
  sequence_value(rounding_apply("strReplace", arguments), "XXa")
  sequence_value(
    sequence_local(
      [("replace", additive_select(sequence_var("std"), "strReplace"))],
      shared_mode_call(sequence_var("replace"), arguments),
    ),
    "XXa",
  )
  sequence_value(
    sequence_call("length", [additive_select(sequence_var("std"), "strReplace")]),
    3,
  )
  for
    call in [
      sequence_call("strReplace", []),
      sequence_call("strReplace", [str, from]),
      rounding_apply("strReplace", [(Some("from"), from), (Some("to"), to)]),
      rounding_apply("strReplace", [(Some("str"), str), (Some("to"), to)]),
      sequence_call("strReplace", [str, from, to, reflect_string("extra")]),
      rounding_apply("strReplace", [
        (Some("str"), str),
        (Some("from"), from),
        (Some("to"), to),
        (Some("unknown"), reflect_string("extra")),
      ]),
    ] {
    replace_contract_reject(call)
  }
}

///|
test "SR4 strReplace rejects nonstring heads and empty patterns without tag promises" {
  let valid = reflect_string("x")
  for
    invalid in [
      ordering_leaf("null", Literal(Json::null())),
      reflect_bool(false),
      sequence_num(0),
      ordering_array([]),
      reflect_object([]),
      make_function([], sequence_num(0)),
    ] {
    replace_contract_reject(replace_contract_call(invalid, valid, valid))
    replace_contract_reject(replace_contract_call(valid, invalid, valid))
    replace_contract_reject(replace_contract_call(valid, valid, invalid))
  }
  for str in ["", "abc"] {
    for to in ["", "x"] {
      replace_contract_reject(replace_contract_text(str, "", to))
    }
  }
}

///|
test "SR5 strReplace propagates each isolated required argument error" {
  for
    (call, marker) in [
      (
        replace_contract_call(
          ordering_error("replace-str"),
          reflect_string("a"),
          reflect_string("b"),
        ),
        "replace-str",
      ),
      (
        replace_contract_call(
          reflect_string("abc"),
          ordering_error("replace-from"),
          reflect_string("b"),
        ),
        "replace-from",
      ),
      (
        replace_contract_call(
          reflect_string("a"),
          reflect_string("a"),
          ordering_error("replace-to"),
        ),
        "replace-to",
      ),
      (
        replace_contract_call(
          reflect_string(""),
          reflect_string("a"),
          ordering_error("replace-to-empty"),
        ),
        "replace-to-empty",
      ),
      (
        replace_contract_call(
          reflect_string("abc"),
          reflect_string("z"),
          ordering_error("replace-to-unmatched"),
        ),
        "replace-to-unmatched",
      ),
    ] {
    sequence_failure(call, @moonjsonnet.Runtime, Some(marker))
  }
}

///|
test "SR6 strReplace calls stay lazy in unused bindings branches and shortcuts" {
  let valid = reflect_string("x")
  let bad = ordering_error("replace-unused")
  for
    call in [
      replace_contract_call(bad, valid, valid),
      replace_contract_call(valid, bad, valid),
      replace_contract_call(reflect_string(""), valid, bad),
      replace_contract_text("abc", "", "x"),
    ] {
    sequence_value(ordering_unused(call), 42)
    let branch : OrderingExpr = {
      source: "if false then (" + call.source + ") else 42",
      tree: ordering_ast(
        If(reflect_bool(false).tree, call.tree, sequence_num(42).tree),
      ),
    }
    sequence_value(branch, 42)
    sequence_value(ordering_binary(reflect_bool(false), "&&", call), false)
    sequence_value(ordering_binary(reflect_bool(true), "||", call), true)
  }
}

///|
test "SR7 strReplace preserves String aliases and repeated literal results" {
  let str = sequence_var("text")
  let from = sequence_var("pattern")
  let to = sequence_var("replacement")
  let result = sequence_var("result")
  sequence_value(
    sequence_local(
      [
        ("text", reflect_string("ab😀ab")),
        ("pattern", reflect_string("ab")),
        ("replacement", reflect_string("é")),
        ("result", replace_contract_call(str, from, to)),
      ],
      ordering_array([
        str,
        result,
        str,
        from,
        to,
        result,
        replace_contract_call(str, from, reflect_string("Z")),
        str,
      ]),
    ),
    [
      "ab😀ab", "é😀é", "ab😀ab", "ab", "é", "é😀é", "Z😀Z", "ab😀ab",
    ],
  )
}

///|
test "SR8 strReplace final compact JSON byte budgets are separate from codepoint length" {
  for
    (str, from, to, expected, bytes, codepoints) in [
      ("a", "a", "é", "é", 4, 1),
      ("ab", "a", "ZZ", "ZZb", 5, 3),
      ("xx", "x", "😀", "😀😀", 10, 2),
      ("abab", "ab", "é", "éé", 6, 2),
    ] {
    let call = replace_contract_text(str, from, to)
    sequence_value(call, Json::string(expected))
    sequence_value(
      sequence_call("length", [call]),
      Json::number(codepoints.to_double()),
    )
    for handmade in [false, true] {
      let program = ordering_program(call, handmade)
      // The public evaluate budget counts final compact JSON, including both
      // quotes. Codepoint length is a separate value check above.
      assert_eq(
        program.evaluate(limits={ ..sequence_limits(), output_bytes: bytes, }),
        Json::string(expected),
      )
      try
        program.evaluate(limits={
          ..sequence_limits(),
          output_bytes: bytes - 1,
        })
      catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
      } noraise {
        _ => fail("strReplace accepted a one-byte-short output budget")
      }
    }
  }
}
