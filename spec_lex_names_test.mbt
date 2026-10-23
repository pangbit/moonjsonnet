// Independent frozen oracle: SPEC-LEX-NAMES-2026-10-23.md.
// Lexical rejection is source-only; handmade ASTs compare admitted names.

///|
fn names_character(value : Char) -> String {
  let out = StringBuilder()
  out.write_char(value)
  out.to_string()
}

///|
fn names_binding(name : String) -> OrderingExpr {
  {
    source: "local " + name + "=42;" + name,
    tree: sequence_local([(name, sequence_num(42))], sequence_var(name)).tree,
  }
}

///|
fn names_binding_value(name : String) -> Unit raise {
  let expression = names_binding(name)
  assert_eq(number_token_text(expression.source), [
    "local", name, "=", "42", ";", name,
  ])
  sequence_value(expression, 42)
}

///|
fn names_syntax(source : String) -> Unit raise {
  try
    @moonjsonnet.Program::parse(
      "if true then 42 else (" + source + ")",
      filename="names",
    )
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Syntax)
  } noraise {
    _ => fail("unused source escaped required Syntax rejection")
  }
}

///|
fn names_quoted_field(name : String) -> OrderingExpr {
  let quoted = Json::string(name).stringify()
  let key = ordering_ast(Literal(Json::string(name)))
  {
    source: "{" + quoted + ":42}[" + quoted + "]",
    tree: ordering_ast(
      Index(
        ordering_ast(
          Obj(
            [
              {
                key,
                value: sequence_num(42).tree,
                visibility: 1,
                additive: false,
              },
            ],
            [],
            [],
          ),
        ),
        key,
      ),
    ),
  }
}

///|
test "ASCII identifier starts and continuations retain complete tokens and bindings" {
  let starts = "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
  let continuations = "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  for character in starts {
    names_binding_value(names_character(character))
  }
  for character in continuations {
    names_binding_value("a" + names_character(character) + "9")
  }
  for name in ["Local", "LOCAL", "True", "TRUE", "_name09".repeat(64)] {
    names_binding_value(name)
  }
}

///|
test "all fixed keywords are excluded from identifier slots but longer names remain identifiers" {
  let words = [
    "assert", "else", "error", "false", "for", "function", "if", "import", "importstr",
    "importbin", "in", "local", "null", "tailstrict", "then", "self", "super", "true",
  ]
  assert_eq(words.length(), 18)
  for word in words {
    for
      source in [
        "local " + word + "=42;42",
        "function(" + word + ")42",
        "{" + word + ":42}",
        "{x:42}." + word,
      ] {
      names_syntax(source)
    }
    for
      name in [word + "0", word + "A", word + "_suffix", "_" + word, "X" + word] {
      names_binding_value(name)
    }
    sequence_value(names_quoted_field(word), 42)
  }
}

///|
test "identifier separators and invalid spellings preserve Syntax Static and Runtime boundaries" {
  for
    name in [
      "0a", "9x", "a-b", "a b", "$", "a$", "é", "中", "😀", "\u0301", "aé",
      "a\u0301", "a\u0000",
    ] {
    names_syntax("local " + name + "=42;42")
  }
  for source in ["local a/**/b=42;42", "local lo/**/cal=42;42"] {
    names_syntax(source)
  }
  for
    source in [
      "local/*split*/x=42;x", "local//split\nx=42;x", "local#split\nx=42;x",
    ] {
    assert_eq(number_token_text(source), ["local", "x", "=", "42", ";", "x"])
    sequence_value({ source, tree: names_binding("x").tree, }, 42)
  }
  let missing = ordering_leaf("lexical_missing", Var("lexical_missing"))
  for handmade in [false, true] {
    try ordering_program(ordering_unused(missing), handmade) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
    } noraise {
      _ => fail("unbound admitted identifier escaped static checking")
    }
  }
  sequence_failure(
    sequence_local([("if0", ordering_error("name-value"))], sequence_var("if0")),
    @moonjsonnet.Runtime,
    Some("name-value"),
  )
}
