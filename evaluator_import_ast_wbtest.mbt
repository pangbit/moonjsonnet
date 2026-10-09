///|
test "nullable import AST keeps nil history separate from valid AST and VM caches" {
  let evaluator = Evaluator::new()
  evaluator.set_importer(resolver=fn(_, path) { { id: path, text: "missing", } })
  try evaluator.import_ast("", "main") catch {
    Error(d) => assert_eq(d.kind, Static)
  } noraise {
    _ => fail("static error expected")
  }
  assert_eq(evaluator.failed_import_asts.length(), 1)
  assert_eq(evaluator.parsed_imports.length(), 0)
  assert_true(evaluator.state is None)
  evaluator.ext_reset()
  assert_eq(evaluator.failed_import_asts.length(), 1)
  try evaluator.find_dependencies("", ["main"]) catch {
    Error(d) => assert_eq(d.kind, Static)
  } noraise {
    _ => fail("scan remains strict")
  }
  try evaluator.evaluate(Program::parse("import 'main'")) catch {
    Error(d) => assert_eq(d.kind, Static)
  } noraise {
    _ => fail("ordinary evaluation remains strict")
  }
  assert_eq(evaluator.parsed_imports.length(), 0)
  evaluator.set_importer()
  assert_eq(evaluator.failed_import_asts.length(), 0)
  assert_eq(evaluator.binary_sources.length(), 0)
  assert_eq(evaluator.parsed_imports.length(), 0)
  assert_true(evaluator.state is None)
}
