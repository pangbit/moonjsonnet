///|
test "cyclic returned external parameters exhaust real clean frames" {
  for stack in [1, 2, 3, 8, 500] {
    for
      codes in [
        Map([("a", "std.extVar('a')")]),
        Map([("a", "std.extVar('b')"), ("b", "std.extVar('a')")]),
      ] {
      try
        @moonjsonnet.evaluate("std.extVar('a')", ext_code=codes, limits={
          ..@moonjsonnet.Limits::default(),
          stack,
        })
      catch {
        @moonjsonnet.Error(diagnostic) => {
          assert_eq(diagnostic.kind, @moonjsonnet.Limit)
          assert_eq(diagnostic.message, "max stack frames exceeded.")
          assert_eq(diagnostic.trace.length(), stack + 1)
        }
      } noraise {
        _ => fail("expected external parameter stack exhaustion")
      }
    }
  }
  try
    @moonjsonnet.evaluate(
      "std.extVar('a')",
      ext_code=Map([("a", "std.extVar('a')")]),
      limits={ ..@moonjsonnet.Limits::default(), steps: 3000, },
    )
  catch {
    @moonjsonnet.Error(diagnostic) => {
      assert_eq(diagnostic.kind, @moonjsonnet.Limit)
      assert_eq(diagnostic.message, "evaluation step limit exceeded")
      assert_true(diagnostic.trace.length() > 3)
    }
  } noraise {
    _ => fail("expected independent step budget")
  }
  try
    @moonjsonnet.evaluate(
      "std.extVar('a')",
      ext_code=Map([("a", "local f(n)=f(n+1);f(0)")]),
      limits={ ..@moonjsonnet.Limits::default(), depth: 20, stack: 2147483647, },
    )
  catch {
    @moonjsonnet.Error(diagnostic) =>
      assert_eq(diagnostic.message, "evaluation depth limit exceeded")
  } noraise {
    _ => fail("expected independent expression depth budget")
  }
}

///|
test "returned external calls execute each body and cache its result" {
  let calls = Ref(0)
  let native : @moonjsonnet.NativeFunction = {
    params: [],
    callback: fn(_) {
      calls.val += 1
      Json::boolean(calls.val == 12)
    },
  }
  let result = @moonjsonnet.evaluate(
    "local first=std.extVar('a');[first,std.extVar('a')]",
    ext_code=Map([("a", "if std.native('done')() then 42 else std.extVar('a')")]),
    native_functions=Map([("done", native)]),
  )
  assert_eq(result, Json::array([42, 42]))
  assert_eq(calls.val, 12)
}

///|
test "external forwarding unwinds hooks and recovers a reusable evaluator" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let active = Ref(0)
  evaluator.set_eval_hook(hook={
    before: fn(_) { active.val += 1 },
    after: fn(_, _) { active.val -= 1 },
  })
  evaluator.set_limits({ ..@moonjsonnet.Limits::default(), stack: 8, })
  evaluator.ext_code("a", "std.extVar('a')")
  let program = @moonjsonnet.Program::parse("std.extVar('a')")
  for _ in 0..<2 {
    try evaluator.evaluate(program) catch {
      @moonjsonnet.Error(diagnostic) =>
        assert_eq(diagnostic.message, "max stack frames exceeded.")
    } noraise {
      _ => fail("expected forwarding cycle")
    }
    assert_eq(active.val, 0)
  }
  evaluator.ext_code("a", "42")
  assert_eq(evaluator.evaluate(program), 42)
  assert_eq(active.val, 0)
}
