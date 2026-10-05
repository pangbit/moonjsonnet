///|
test "queries allocate no runtime state and retain parsed cache across ext reset" {
  let evaluator = Evaluator::new()
  evaluator.set_importer(resolver=fn(_, path) {
    { id: path, text: if path == "main" { "import 'dep'" } else { "42" }, }
  })
  assert_eq(evaluator.find_dependencies("", ["main"]), ["dep"])
  assert_true(evaluator.state is None)
  assert_eq(evaluator.parsed_imports.length(), 2)
  evaluator.ext_reset()
  assert_eq(evaluator.parsed_imports.length(), 2)
  let (program, _) = evaluator.import_program("", "main")
  assert_eq(evaluator.evaluate(program), 42)
  assert_eq(evaluator.state.unwrap().parsed_imports.length(), 2)
  evaluator.set_importer()
  assert_eq(evaluator.parsed_imports.length(), 0)
  assert_eq(evaluator.binary_sources.length(), 0)
  assert_eq(evaluator.sources.length(), 0)
  assert_true(evaluator.state is None)
}
