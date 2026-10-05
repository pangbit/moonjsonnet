///|
test "editable AST remains isolated from imported source and value caches" {
  let evaluator = @moonjsonnet.Evaluator::new()
  evaluator.set_importer(resolver=fn(_, path) { { id: path, text: "[21]", } })
  let (imported, _) = evaluator.import_program("entry", "lib")
  let tree = imported.ast()
  guard tree.kind is Arr(items) else { fail("array AST") }
  items[0] = { ..items[0], kind: Literal(42), }
  let edited = @moonjsonnet.Program::from_ast(tree)
  let entry = @moonjsonnet.Program::parse("import 'lib'", filename="entry")
  assert_eq(evaluator.evaluate(entry), [21])
  assert_eq(evaluator.evaluate(edited), [42])
  items.clear()
  assert_eq(evaluator.evaluate(entry), [21])
  assert_eq(evaluator.evaluate(imported), [21])
  assert_eq(evaluator.evaluate(edited), [42])
}
