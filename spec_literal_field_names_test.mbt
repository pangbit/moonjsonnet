// Fixed Jsonnet spec.html (bbb38f1020be1f5aed560928fb839b2c448cefb4),
// Lexing canonicalizes strings before chk-object compares literal field names.
// Expected keys are explicit codepoint strings; trees never come from parsing.

///|
fn literal_field_pair(
  first : String,
  second : String,
  first_key : String,
  second_key : String,
) -> OrderingExpr {
  {
    source: "{" + first + ":1," + second + ":2}",
    tree: reflect_object([
      (reflect_string(first_key), 1, sequence_num(1)),
      (reflect_string(second_key), 1, sequence_num(2)),
    ]).tree,
  }
}

///|
test "literal field names admit distinct canonical keys with identical raw payloads" {
  for
    (ordinary, verbatim, decoded, literal) in [
      ("\"\\u0061\"", "@\"\\u0061\"", "a", "\\u0061"),
      ("'\\u0061'", "@'\\u0061'", "a", "\\u0061"),
      ("\"\\n\"", "@\"\\n\"", "\n", "\\n"),
      ("'\\n'", "@'\\n'", "\n", "\\n"),
      ("\"\\\\\"", "@\"\\\\\"", "\\", "\\\\"),
      ("'\\\\'", "@'\\\\'", "\\", "\\\\"),
    ] {
    // Admission is required even when the object and its values stay unused.
    sequence_value(
      ordering_unused(literal_field_pair(ordinary, verbatim, decoded, literal)),
      42,
    )
    sequence_value(
      ordering_unused(literal_field_pair(verbatim, ordinary, literal, decoded)),
      42,
    )
  }
}

///|
test "literal field names still reject canonical duplicates in unused contexts" {
  for
    (first, second, key) in [
      ("\"\\u0061\"", "a", "a"),
      ("a", "\"\\u0061\"", "a"),
      ("\"a\"", "@\"a\"", "a"),
      ("'\\u0061'", "'\\u0061'", "a"),
      ("\"\\n\"", "\"\n\"", "\n"),
      ("\"\\\\\"", "@\"\\\"", "\\"),
      ("[\"\\u0061\"]", "a", "a"),
      ("@'\\u0061'", "['\\\\u0061']", "\\u0061"),
    ] {
    // This helper checks direct, unused local and unselected branch admission
    // through both source and independently built canonical ASTs.
    pair_reject(literal_field_pair(first, second, key, key))
  }
  // Both canonical names sharing one raw payload must remain tracked.
  for
    source in [
      "{'\\u0061':1,@'\\u0061':2,'\\u0061':3}", "{@'\\u0061':1,'\\u0061':2,@'\\u0061':3}",
    ] {
    try @moonjsonnet.Program::parse(source) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
    } noraise {
      _ => fail("repeated canonical key was admitted")
    }
  }
}

///|
test "literal field names retain exact keys values and method receivers" {
  let cases : Array[(String, String, String, String, Json)] = [
    ("'\\u0061'", "@'\\u0061'", "a", "\\u0061", { "a": 1, "\\u0061": 2 }),
    ("@'\\n'", "'\\n'", "\\n", "\n", { "\\n": 1, "\n": 2 }),
    ("'\\\\'", "@'\\\\'", "\\", "\\\\", { "\\": 1, "\\\\": 2 }),
  ]
  for (first, second, first_key, second_key, expected) in cases {
    sequence_value(
      literal_field_pair(first, second, first_key, second_key),
      expected,
    )
  }
  let method_tree = ordering_ast(
    Func(
      [{ name: "x", default_value: Some(sequence_num(2).tree), range: None, }],
      ordering_ast(
        Binary(
          "+",
          ordering_ast(
            Index(sequence_var("self").tree, reflect_string("a").tree),
          ),
          sequence_var("x").tree,
        ),
      ),
    ),
  )
  let object : OrderingExpr = {
    source: "{'\\u0061':1,@'\\u0061'(x=2):self.a+x}",
    tree: reflect_object([
      (reflect_string("a"), 1, sequence_num(1)),
      (reflect_string("\\u0061"), 1, { source: "", tree: method_tree, }),
    ]).tree,
  }
  let receiver = sequence_var("o")
  let callee = additive_select(receiver, "\\u0061")
  sequence_value(
    sequence_local(
      [("o", object)],
      ordering_array([
        additive_select(receiver, "a"),
        value_head_call(callee, []),
        value_head_call(callee, [sequence_num(4)]),
      ]),
    ),
    [1, 3, 5],
  )
}

///|
test "literal field name correction preserves raw document spelling and diagnostics" {
  for
    source in [
      "{ /* names */ '\\u0061': 1, @'\\u0061': 2 }", "{'a':1,'\\u0061':2}",
    ] {
    let document = @moonjsonnet.SyntaxDocument::parse(source)
    assert_eq(document.text(), source)
  }
  // Existing early repeated-spelling diagnostics retain their raw name.
  try @moonjsonnet.Program::parse("{'\\u0061':1,'\\u0061':2}") catch {
    @moonjsonnet.Error(d) => {
      assert_eq(d.kind, @moonjsonnet.Static)
      assert_eq(d.message, "Duplicate field: \\u0061")
    }
  } noraise {
    _ => fail("identical literal field names were admitted")
  }
}
