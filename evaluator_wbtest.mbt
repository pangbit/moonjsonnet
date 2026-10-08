///|
test "retained heap reaches steady size across repeated entries" {
  let evaluator = Evaluator::new()
  evaluator.set_importer(resolver=fn(_, path) {
    {
      id: path,
      text: "local x=21; {f(n):x*n, nested:{a:42}, hidden::[1,2,3]}",
    }
  })
  let entry = Program::parse(
    "local o=import 'dep'; [o.f(2),o.nested.a,std.length(o.hidden)]",
  )
  for _ in 0..<3 {
    assert_eq(evaluator.evaluate(entry), [42, 42, 3])
  }
  let before = evaluator.state.unwrap()
  let size = (before.thunks.length(), before.objects.length())
  for _ in 0..<200 {
    assert_eq(evaluator.evaluate(entry), [42, 42, 3])
  }
  let after = evaluator.state.unwrap()
  assert_eq((after.thunks.length(), after.objects.length()), size)
  assert_true(after.free_thunks.length() > 0)
  assert_true(after.free_objects.length() > 0)
  assert_eq(after.retries.length(), 0)
  assert_eq(after.ext.length(), 0)
  assert_eq(after.frames.length(), 0)
  assert_true(after.current_trace is None)
  assert_eq(after.depth, 0)
  evaluator.ext_var("invalidate", 1)
  let cleared = evaluator.state.unwrap()
  assert_eq(cleared.thunks.length(), 0)
  assert_eq(cleared.objects.length(), 0)
  assert_eq(cleared.parsed_imports.length(), 1)
  assert_eq(cleared.sources.length(), 1)
  assert_eq(evaluator.evaluate(entry), [42, 42, 3])
}

///|
test "heap collection releases uncached entries and preserves recursive closures" {
  let evaluator = Evaluator::new()
  let entry = Program::parse(
    "local f(n)=if n==0 then 42 else f(n-1) tailstrict; f(100) tailstrict",
  )
  for _ in 0..<5 {
    assert_eq(evaluator.evaluate(entry), 42)
    let vm = evaluator.state.unwrap()
    assert_eq(vm.free_thunks.length(), vm.thunks.length())
    assert_eq(vm.free_objects.length(), vm.objects.length())
  }
  evaluator.set_importer(resolver=fn(_, path) {
    { id: path, text: "local f(n)=if n==0 then 42 else f(n-1) tailstrict; f", }
  })
  let imported = Program::parse("(import 'f')(100) tailstrict")
  for _ in 0..<10 {
    assert_eq(evaluator.evaluate(imported), 42)
  }
}
