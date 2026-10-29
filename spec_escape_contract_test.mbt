// Unexecuted candidate: fixed bbb38f std.jsonnet 1000-1034, already source-routed.
// Literal String results for Json/Python/Bash/Dollars; source and handmade callers.
// General nonstring coercion, str/str_ naming, XML spelling and resource limits
// are excluded; no product change or new verified coverage is claimed.

///|
fn escape_contract_call(
  name : String,
  input : OrderingExpr,
  through_alias? : Bool = false,
) -> OrderingExpr {
  let function = additive_select(sequence_var("std"), name)
  if through_alias {
    sequence_local(
      [("saved_escape", function)],
      shared_mode_call(sequence_var("saved_escape"), [(None, input)]),
    )
  } else {
    shared_mode_call(function, [(None, input)])
  }
}

///|
test "ESC1 JSON and Python escaping have independent literal String results" {
  // Fixed 1000-1026: named escapes, lowercase C0/C1 hex, other codepoints raw;
  // Python delegates to JSON quoting. The expected Strings below are literals.
  let cases : Array[(String, String)] = [
    ("", "\"\""),
    ("\"\\\b\u{000c}\n\r\t", "\"\\\"\\\\\\b\\f\\n\\r\\t\""),
    (
      "\u{0000}\u{001f}\u{007f}\u{0085}\u{009f}", "\"\\u0000\\u001f\\u007f\\u0085\\u009f\"",
    ),
    ("~\u{00a0}", "\"~\u{00a0}\""),
    (
      "é中😀e\u{0301}\u{2028}\u{2029}<>&/", "\"é中😀e\u{0301}\u{2028}\u{2029}<>&/\"",
    ),
  ]
  for name in ["escapeStringJson", "escapeStringPython"] {
    for (input, expected) in cases {
      transfer_value(
        escape_contract_call(name, reflect_string(input)),
        Json::string(expected),
      )
    }
  }
}

///|
test "ESC2 Bash escaping preserves text and replaces every single quote" {
  // Fixed 1028-1030: replace each apostrophe with '"'"', then wrap in apostrophes.
  for
    (input, expected) in [
      ("", "''"),
      ("'", "''\"'\"''"),
      ("a'b'c", "'a'\"'\"'b'\"'\"'c'"),
      ("x$y\\z\n\t", "'x$y\\z\n\t'"),
      ("é中😀", "'é中😀'"),
    ] {
    transfer_value(
      escape_contract_call("escapeStringBash", reflect_string(input)),
      Json::string(expected),
    )
  }
}

///|
test "ESC3 dollar escaping doubles every dollar and preserves other text" {
  // Fixed 1032-1034: the replacement is literal and does not wrap the result.
  for
    (input, expected) in [
      ("", ""),
      ("$", "$$"),
      ("$$HOME ${name}", "$$$$HOME $${name}"),
      ("a$b$c", "a$$b$$c"),
      ("'\"\\é😀\n", "'\"\\é😀\n"),
    ] {
    transfer_value(
      escape_contract_call("escapeStringDollars", reflect_string(input)),
      Json::string(expected),
    )
  }
}

///|
test "ESC4 escaping demands its input through direct and saved calls" {
  // Fixed 1001/1026/1029/1033 demand the input through toString or delegation;
  // ordinary lazy calls keep the entire operation dormant when unused.
  for
    (name, expected) in [
      ("escapeStringJson", "\"x\""),
      ("escapeStringPython", "\"x\""),
      ("escapeStringBash", "'x'"),
      ("escapeStringDollars", "x"),
    ] {
    for through_alias in [false, true] {
      transfer_value(
        escape_contract_call(name, reflect_string("x"), through_alias~),
        Json::string(expected),
      )
      let required = escape_contract_call(
        name,
        ordering_error("escape-required-input"),
        through_alias~,
      )
      // Sole-marker/error-kind checks are additional embedding controls.
      sequence_failure(
        required,
        @moonjsonnet.Runtime,
        Some("escape-required-input"),
      )
      transfer_value(
        shared_mode_call(make_function(["unused"], sequence_num(42)), [
          (None, required),
        ]),
        42,
      )
    }
  }
}

///|
test "ESC5 escaping retains required arity and unambiguous binding errors" {
  // Fixed 1000/1025/1028/1032 declare one required parameter; Python alone
  // has the same str spelling in the documentation and the fixed source.
  let safe = reflect_string("x")
  for
    name in [
      "escapeStringJson", "escapeStringPython", "escapeStringBash", "escapeStringDollars",
    ] {
    let function = additive_select(sequence_var("std"), name)
    transfer_value(sequence_call("length", [function]), 1)
    let invalid : Array[Array[(String?, OrderingExpr)]] = [
      [],
      [(None, safe), (None, safe)],
      [(Some("unknown"), safe)],
    ]
    for args in invalid {
      transfer_reject(shared_mode_call(function, args))
    }
  }
  transfer_value(
    shared_mode_call(
      additive_select(sequence_var("std"), "escapeStringPython"),
      [(Some("str"), safe)],
    ),
    "\"x\"",
  )
}
