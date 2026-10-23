// Frozen oracle: SPEC-OPERATOR-TOKENS-2026-10-23.md.
// Only admitted spellings are compared to independently constructed ASTs.

///|
fn op_plus_operand(value : OrderingExpr) -> OrderingExpr {
  {
    source: "1++(" + value.source + ")",
    tree: ordering_ast(
      Binary("+", sequence_num(1).tree, ordering_ast(Unary("+", value.tree))),
    ),
  }
}

///|
test "operator token splits feed source AST and admission boundaries independently" {
  let one = sequence_num(1).tree
  let two = sequence_num(2).tree
  let plus_two = ordering_ast(Unary("+", two))
  let minus_two = ordering_ast(Unary("-", two))
  let cases : Array[(String, @moonjsonnet.Ast, Json)] = [
    ("1++2", ordering_ast(Binary("+", one, plus_two)), 3),
    ("1--2", ordering_ast(Binary("-", one, minus_two)), 3),
    ("1<+2", ordering_ast(Binary("<", one, plus_two)), true),
    ("1+/*c*/+2", ordering_ast(Binary("+", one, plus_two)), 3),
  ]
  for (source, tree, expected) in cases {
    sequence_value({ source, tree, }, expected)
  }
  let block = "|||\n  x\n|||"
  let source = "'a'+" + block
  sequence_value(
    {
      source,
      tree: ordering_ast(
        Binary(
          "+",
          ordering_ast(Literal(Json::string("a"))),
          ordering_ast(Literal(Json::string("x\n"))),
        ),
      ),
    },
    "ax\n",
  )
  assert_eq(number_token_text("1++2"), ["1", "+", "+", "2"])
  assert_eq(number_token_text(source), ["'a'", "+", block])
  for invalid in ["1===2", "1**2", "1<<=2", "1+/*", "1+||| x"] {
    names_syntax(invalid)
  }
  sequence_failure(
    op_plus_operand(ordering_leaf("null", Literal(Json::null()))),
    @moonjsonnet.Type,
    None,
  )
  sequence_failure(
    op_plus_operand(ordering_error("operator-demand")),
    @moonjsonnet.Runtime,
    Some("operator-demand"),
  )
  for handmade in [false, true] {
    try
      ordering_program(
        ordering_unused(op_plus_operand(sequence_var("operator_missing"))),
        handmade,
      )
    catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
    } noraise {
      _ => fail("valid operator tokens bypassed static operand checking")
    }
  }
}
