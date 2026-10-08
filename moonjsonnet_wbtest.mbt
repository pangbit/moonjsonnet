///|
test "thunk cache computes once and remembers failure" {
  let vm : Vm = {
    free_thunks: [],
    free_objects: [],
    persistent: false,
    retries: Map([]),
    accessed_sources: Map([]),
    parsed_imports: Map([]),
    library: standard_library_expression(),
    thunks: [],
    objects: [],
    limits: Limits::default(),
    ext: Map([]),
    native_functions: Map([]),
    trace: default_trace,
    eval_hook: None,
    hooks_suppressed: false,
    hook_stack: [],
    hook_serial: 0,
    hook_failure_environment: None,
    resolver: None,
    binary_resolver: None,
    binary_sources: Map([]),
    binary_imports: Map([]),
    sources: Map([]),
    imports: Map([]),
    steps: 0,
    depth: 0,
    frames: [],
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
  assert_eq(vm.frames.length(), 0)
  for
    source in [
      "(function() error 'strict')() tailstrict", "(function() (function() error 'inner')())() tailstrict",
      "local f(n)=f(n+1); f(0)",
    ] {
    let expr = parse(source, "unwind", 100)
    try vm.eval_frame(expr, vm.base_env()) catch {
      _ => ()
    } noraise {
      _ => fail("expected failure")
    }
    assert_eq(vm.frames.length(), 0)
    assert_eq(vm.depth, 0)
  }
}
