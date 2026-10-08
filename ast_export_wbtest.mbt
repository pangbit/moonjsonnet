///|
test "AST export traverses a ten-thousand-level tree iteratively" {
  let loc : Location = { file: "deep-export", line: 1, column: 1, }
  let end : Location = { ..loc, column: 3, }
  let leaf : Expr = {
    kind: Arr([{ kind: NumberLiteral("42"), loc, end: Some(end), }]),
    loc,
    end: Some(end),
  }
  let mut expression = leaf
  for _ in 0..<10000 {
    expression = {
      kind: Binary("+", expression, {
        kind: NumberLiteral("1"),
        loc,
        end: Some(end),
      }),
      loc,
      end: Some(end),
    }
  }
  // Private construction is a lifecycle stress test, not a public admission
  // bypass. The public parser and evaluator still reject their own limits.
  let tree = export_ast(expression)
  let mut current = tree
  let mut depth = 0
  while current.kind is Binary("+", left, right) {
    assert_true(right.kind is NumberLiteral("1"))
    assert_eq(current.loc, loc)
    assert_eq(current.end, Some(end))
    current = left
    depth += 1
  }
  assert_eq(depth, 10000)
  guard current.kind is Arr(values) else { fail("leaf array") }
  assert_true(values[0].kind is NumberLiteral("42"))
  values[0] = { ..values[0], kind: Literal(0), }
  guard export_ast(leaf).kind is Arr(original) else { fail("original leaf") }
  assert_true(original[0].kind is NumberLiteral("42"))
}

///|
test "AST export copies every occurrence of a shared expression independently" {
  let loc : Location = { file: "shared-export", line: 1, column: 1, }
  let value : Expr = {
    kind: Arr([{ kind: NumberLiteral("42"), loc, end: None, }]),
    loc,
    end: None,
  }
  let root : Expr = { kind: Binary("+", value, value), loc, end: None, }
  guard export_ast(root).kind is Binary(_, left, right) &&
    left.kind is Arr(xs) &&
    right.kind is Arr(ys) else {
    fail("exported shared arrays")
  }
  xs[0] = { ..xs[0], kind: Literal(0), }
  assert_true(ys[0].kind is NumberLiteral("42"))
  guard export_ast(value).kind is Arr(original) else { fail("input array") }
  assert_true(original[0].kind is NumberLiteral("42"))
}
