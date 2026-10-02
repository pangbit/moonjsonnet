///|
test "thunk cache computes once and remembers failure" {
  let vm : Vm = {
    library: standard_library_expression(),
    thunks: [],
    objects: [],
    limits: Limits::default(),
    ext: Map([]),
    native_functions: Map([]),
    trace: default_trace,
    resolver: None,
    binary_resolver: None,
    binary_sources: Map([]),
    binary_imports: Map([]),
    sources: Map([]),
    imports: Map([]),
    steps: 0,
    depth: 0,
    imported_bytes: 0,
    output_bytes: 0,
  }
  let e = parse("21 * 2", "cache", 100)
  let t = vm.store(Pending(e, vm.base_env()))
  assert_true(vm.force(t, e.loc) is Num(42))
  let steps = vm.steps
  assert_true(vm.force(t, e.loc) is Num(42))
  assert_eq(vm.steps, steps + 1)
  let bad = parse("error 'once'", "cache", 100)
  let t = vm.store(Pending(bad, vm.base_env()))
  try vm.force(t, bad.loc) catch {
    _ => ()
  } noraise {
    _ => fail("expected failure")
  }
  let steps = vm.steps
  try vm.force(t, bad.loc) catch {
    _ => ()
  } noraise {
    _ => fail("expected failure")
  }
  assert_eq(vm.steps, steps + 1)
}
