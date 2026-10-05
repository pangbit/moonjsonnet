///|
test "source ranges retain byte columns exclusive ends and round trips" {
  let tree = @moonjsonnet.Program::parse("['é',\n '😀']", filename="bytes").ast()
  let range = tree.source_range().unwrap()
  assert_eq(range.begin, { file: "bytes", line: 1, column: 1, })
  assert_eq(range.end, { file: "bytes", line: 2, column: 9, })
  assert_eq(range.format(), "bytes:(1:1)-(2:9)")
  guard tree.kind is Arr(items) else { fail("array") }
  assert_eq(items[0].source_range().unwrap().format(), "bytes:1:2-6")
  assert_eq(items[1].source_range().unwrap().format(), "bytes:2:2-8")
  let copy = @moonjsonnet.Program::from_ast(tree.clone(), filename="changed").ast()
  assert_eq(copy.source_range(), Some(range))
  guard copy.kind is Arr(copied) else { fail("array") }
  assert_eq(copied[1].source_range(), items[1].source_range())
  let loc : @moonjsonnet.Location = { file: "", line: 3, column: 4, }
  let point : @moonjsonnet.SourceRange = { begin: loc, end: loc, }
  assert_eq(point.format(), "3:4")
  let synthetic : @moonjsonnet.Ast = { kind: Literal(42), loc, end: None, }
  assert_eq(
    @moonjsonnet.Program::from_ast(synthetic).ast().source_range(),
    None,
  )
}

///|
test "invalid AST ranges are rejected and explicit metadata edits retained" {
  let tree = @moonjsonnet.Program::parse(" 42", filename="original").ast()
  let invalid : Array[@moonjsonnet.Location] = [
    { file: "other", line: 1, column: 4, },
    { file: "original", line: 1, column: 1, },
    { file: "original", line: 0, column: 4, },
    { file: "original", line: 2, column: 0, },
  ]
  for end in invalid {
    try @moonjsonnet.Program::from_ast({ ..tree, end: Some(end), }) catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Static)
        assert_eq(d.message, "invalid AST source range")
      }
    } noraise {
      _ => fail("invalid range accepted")
    }
  }
  let edited = {
    ..tree,
    loc: { file: "edited", line: 2, column: 1, },
    end: Some({ file: "edited", line: 3, column: 2, }),
  }
  let program = @moonjsonnet.Program::from_ast(edited)
  assert_eq(program.evaluate(), 42)
  assert_eq(
    program.ast().source_range().unwrap().format(),
    "edited:(2:1)-(3:2)",
  )
}
