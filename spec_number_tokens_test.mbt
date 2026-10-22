// Frozen oracle and stage boundaries: SPEC-NUMBER-TOKENS-2026-10-22.md.
// Neutral ordering_*/sequence_* helpers construct source and typed trees
// separately; no parser-exported tree or observed value supplies an oracle.

///|
fn token_number(raw : String) -> OrderingExpr {
  ordering_leaf(raw, NumberLiteral(raw))
}

///|
fn number_token_text(source : String) -> Array[String] raise {
  let parts = @moonjsonnet.SyntaxDocument::parse(source).parts()
  let tokens : Array[String] = []
  for part in parts {
    if part.kind is TokenText && !part.text.is_empty() {
      tokens.push(part.text)
    }
  }
  tokens
}

///|
test "number tokens retain the longest legal prefix before dot and else" {
  for raw in ["0", "1", "12", "0.5", "1e0"] {
    let access : OrderingExpr = {
      source: raw + ".slot",
      tree: ordering_ast(
        Index(token_number(raw).tree, ordering_ast(Literal("slot"))),
      ),
    }
    // Syntax/static admission precedes demand; numeric indexing is Type only
    // when forced. An unused field access cannot become a lexical failure.
    sequence_failure(access, @moonjsonnet.Type, None)
    assert_eq(number_token_text(access.source), [raw, ".", "slot"])
  }
  let cases : Array[(String, Json)] = [
    ("0", 0),
    ("1", 1),
    ("0.5", 0.5),
    ("1e+2", 100),
  ]
  for (raw, expected) in cases {
    for selected in [false, true] {
      let value : OrderingExpr = {
        source: "if " + selected.to_string() + " then " + raw + "else 2",
        tree: ordering_ast(
          If(
            ordering_ast(Literal(Json::boolean(selected))),
            token_number(raw).tree,
            token_number("2").tree,
          ),
        ),
      }
      sequence_value(value, if selected { expected } else { 2 })
    }
  }
  assert_eq(number_token_text("if true then 1else 2"), [
    "if", "true", "then", "1", "else", "2",
  ])
}

///|
test "number spelling signs and comments have independent token boundaries" {
  let source = "[0,12.50E-1,-2,+3,1e+2+3]"
  let value : OrderingExpr = {
    source,
    tree: ordering_ast(
      Arr([
        token_number("0").tree,
        token_number("12.50E-1").tree,
        ordering_ast(Unary("-", token_number("2").tree)),
        ordering_ast(Unary("+", token_number("3").tree)),
        ordering_binary(token_number("1e+2"), "+", token_number("3")).tree,
      ]),
    ),
  }
  assert_eq(number_token_text(source), [
    "[", "0", ",", "12.50E-1", ",", "-", "2", ",", "+", "3", ",", "1e+2", "+", "3",
    "]",
  ])
  sequence_value(value, [0, 1.25, -2, 3, 103])
  let commented : OrderingExpr = {
    source: "[1/*e9*/+2,1e+2//line\n+3]",
    tree: ordering_array([
      ordering_binary(token_number("1"), "+", token_number("2")),
      ordering_binary(token_number("1e+2"), "+", token_number("3")),
    ]).tree,
  }
  assert_eq(number_token_text(commented.source), [
    "[", "1", "+", "2", ",", "1e+2", "+", "3", "]",
  ])
  sequence_value(commented, [3, 103])
}

///|
test "malformed numeric source and handmade raw tokens reject before demand" {
  for raw in ["00", "00.1", "0e", "0e-", "1.0E+", ".5", "2_5", "0x10", "1e2.3"] {
    let value = ordering_unused(token_number(raw))
    for handmade in [false, true] {
      try ordering_program(value, handmade) catch {
        @moonjsonnet.Error(d) =>
          assert_eq(
            d.kind,
            if handmade {
              @moonjsonnet.Static
            } else {
              @moonjsonnet.Syntax
            },
          )
      } noraise {
        _ => fail("an unused malformed number was admitted")
      }
    }
  }
  // These are identifiers, not numeric tokens or reserved number constants.
  let names = sequence_local(
    [("NaN", token_number("41")), ("Infinity", token_number("42"))],
    ordering_array([sequence_var("NaN"), sequence_var("Infinity")]),
  )
  sequence_value(names, [41, 42])
}

///|
test "number token admission stays separate from demanded overflow" {
  let cases : Array[(String, Json?)] = [
    ("1.25e999999999999999999999999999", None),
    ("0.0e999999999999999999999999999", Some(0)),
    ("1e-999999999999999999999999999", Some(0)),
    ("12.5E+000000000000000000000000000000000000000001", Some(125)),
  ]
  for (raw, expected) in cases {
    let number = token_number(raw)
    for handmade in [false, true] {
      // Construction performs lexical/static checks but never conversion.
      ignore(ordering_program(number, handmade))
    }
    sequence_value(ordering_unused(number), 42)
    sequence_value(sequence_call("length", [ordering_array([number])]), 1)
    let skipped : OrderingExpr = {
      source: "if false then " + raw + " else 42",
      tree: ordering_ast(
        If(ordering_ast(Literal(false)), number.tree, token_number("42").tree),
      ),
    }
    sequence_value(skipped, 42)
    match expected {
      Some(value) => sequence_value(number, value)
      None => {
        sequence_failure(number, @moonjsonnet.Runtime, None)
        sequence_failure(
          sequence_call("type", [number]),
          @moonjsonnet.Runtime,
          None,
        )
      }
    }
  }
}
