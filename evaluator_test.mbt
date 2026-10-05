///|
test "evaluator separates source cache and value cache invalidation" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let mut reads = 0
  let mut calls = 0
  let mut source = "std.native('tick')() + std.extVar('x')"
  let resolver : (String, String) -> @moonjsonnet.Source raise = (_, path) => {
    reads += 1
    { id: path, text: source, }
  }
  let native : @moonjsonnet.NativeFunction = {
    params: [],
    callback: fn(_) {
      calls += 1
      40
    },
  }
  evaluator.set_importer(resolver~)
  evaluator.native_function("tick", native)
  evaluator.ext_var("x", 2)
  let program = @moonjsonnet.Program::parse("import 'dep'")
  assert_eq(evaluator.evaluate(program), 42)
  assert_eq(evaluator.evaluate(program), 42)
  assert_eq((reads, calls), (1, 1))
  evaluator.tla_var("unused", 1)
  evaluator.tla_reset()
  assert_eq(evaluator.evaluate(program), 42)
  assert_eq((reads, calls), (1, 1))
  source = "99"
  evaluator.ext_code("x", "3")
  assert_eq(evaluator.evaluate(program), 43)
  assert_eq((reads, calls), (1, 2))
  evaluator.ext_program("x", @moonjsonnet.Program::parse("4"))
  assert_eq(evaluator.evaluate(program), 44)
  assert_eq((reads, calls), (1, 3))
  evaluator.native_function("tick", { params: [], callback: fn(_) { 1 }, })
  assert_eq(evaluator.evaluate(program), 5)
  evaluator.set_importer(resolver~)
  assert_eq(evaluator.evaluate(program), 99)
  assert_eq(reads, 2)
  evaluator.ext_reset()
  try evaluator.evaluate(@moonjsonnet.Program::parse("std.extVar('x')")) catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
  } noraise {
    _ => fail("expected reset external")
  }
}

///|
test "evaluator retains closures lazy object fields and trace sink changes" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let first = []
  let second = []
  evaluator.set_importer(resolver=fn(_, path) {
    { id: path, text: "local a=21; {f(n):a*n, later:std.trace('late',42)}", }
  })
  evaluator.set_trace(fn(_, message) { first.push(message) })
  assert_eq(
    evaluator.evaluate(@moonjsonnet.Program::parse("(import 'dep').f(2)")),
    42,
  )
  evaluator.set_trace(fn(_, message) { second.push(message) })
  assert_eq(
    evaluator.evaluate(@moonjsonnet.Program::parse("(import 'dep').later")),
    42,
  )
  assert_eq(
    evaluator.evaluate(@moonjsonnet.Program::parse("(import 'dep').later")),
    42,
  )
  assert_eq(first, [])
  assert_eq(second, ["late"])
  for _ in 0..<20 {
    assert_eq(
      evaluator.evaluate(
        @moonjsonnet.Program::parse(
          "local o=(import 'dep')+{later:1}; [o.f(2),o.later]",
        ),
      ),
      [42, 1],
    )
    assert_eq(
      evaluator.evaluate(@moonjsonnet.Program::parse("(import 'dep').f(2)")),
      42,
    )
  }
}

///|
test "evaluator retries failed imported values and object fields" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let mut attempts = 0
  evaluator.native_function("attempt", {
    params: [],
    callback: fn(_) {
      attempts += 1
      Json::number(attempts.to_double())
    },
  })
  evaluator.set_importer(resolver=fn(_, path) {
    {
      id: path,
      text: if path == "value" {
        "local x=std.native('attempt')(); if x==1 then error 'retry' else x"
      } else {
        "{x:local a=std.native('attempt')(); if a==3 then error 'retry field' else a}"
      },
    }
  })
  let value = @moonjsonnet.Program::parse("import 'value'")
  try evaluator.evaluate(value) catch {
    @moonjsonnet.Error(d) => assert_eq(d.message, "retry")
  } noraise {
    _ => fail("expected first failure")
  }
  assert_eq(evaluator.evaluate(value), 2)
  assert_eq(evaluator.evaluate(value), 2)
  let field = @moonjsonnet.Program::parse("(import 'object').x")
  try evaluator.evaluate(field) catch {
    @moonjsonnet.Error(d) => assert_eq(d.message, "retry field")
  } noraise {
    _ => fail("expected field failure")
  }
  assert_eq(evaluator.evaluate(field), 4)
  assert_eq(evaluator.evaluate(field), 4)
  assert_eq(attempts, 4)
}

///|
test "evaluator output modes configuration and TLA replacement" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let program = @moonjsonnet.Program::parse("function(x=1) x")
  assert_eq(evaluator.evaluate(program), 1)
  evaluator.tla_var("x", 2)
  assert_eq(evaluator.evaluate_text(program), "2\n")
  evaluator.tla_code("x", "[3]")
  assert_eq(evaluator.evaluate_stream(program), ["3\n"])
  evaluator.tla_program("x", @moonjsonnet.Program::parse("{a:'raw'}"))
  assert_eq(evaluator.evaluate_multi(program)["a"], "\"raw\"\n")
  evaluator.set_string_output(true)
  assert_eq(evaluator.evaluate_multi(program)["a"], "raw")
  evaluator.tla_var("x", Json::string("raw"))
  assert_eq(evaluator.evaluate_text(program), "raw\n")
  assert_eq(evaluator.evaluate(program), Json::string("raw"))
  evaluator.tla_reset()
  assert_eq(evaluator.evaluate(program), 1)
}

///|
test "evaluator enforces per execution budgets including cached imports" {
  let evaluator = @moonjsonnet.Evaluator::new()
  evaluator.set_importer(resolver=fn(_, path) {
    { id: path, text: "[1,2,3,4,5,6,7,8,9,10]", }
  })
  let program = @moonjsonnet.Program::parse("import 'dep'")
  assert_eq(evaluator.evaluate(program), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  evaluator.set_limits({ ..@moonjsonnet.Limits::default(), source_bytes: 16, })
  try evaluator.evaluate(program) catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected cached source limit")
  }
  evaluator.set_limits(@moonjsonnet.Limits::default())
  assert_eq(evaluator.evaluate(program), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  for _ in 0..<3 {
    assert_eq(evaluator.evaluate(@moonjsonnet.Program::parse("42")), 42)
  }
}

///|
test "evaluator rejects reentrant execution and mutation without corrupting state" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let inner = @moonjsonnet.Program::parse("1")
  let mut rejected = 0
  evaluator.native_function("reenter", {
    params: [],
    callback: fn(_) raise {
      try evaluator.evaluate(inner) catch {
        @moonjsonnet.Error(d) => {
          assert_eq(d.message, "evaluator is already executing")
          rejected += 1
        }
      } noraise {
        _ => fail("expected reentrancy guard")
      }
      try evaluator.ext_var("x", 1) catch {
        @moonjsonnet.Error(d) => {
          assert_eq(d.message, "evaluator is already executing")
          rejected += 1
        }
      } noraise {
        _ => fail("expected mutation guard")
      }
      42
    },
  })
  assert_eq(
    evaluator.evaluate(@moonjsonnet.Program::parse("std.native('reenter')()")),
    42,
  )
  assert_eq(rejected, 2)
  assert_eq(evaluator.evaluate(inner), 1)
}

///|
test "evaluator caches assertion failures until value invalidation" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let mut calls = 0
  evaluator.native_function("tick", {
    params: [],
    callback: fn(_) {
      calls += 1
      Json::number(calls.to_double())
    },
  })
  evaluator.set_importer(resolver=fn(_, path) {
    { id: path, text: "{assert std.native('tick')()>1:'assert retry',a:42}", }
  })
  let entry = @moonjsonnet.Program::parse("import 'dep'")
  let errors = []
  for _ in 0..<3 {
    try evaluator.evaluate(entry) catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Assertion)
        assert_eq(d.message, "assert retry")
        errors.push(d)
      }
    } noraise {
      _ => fail("expected retained assertion failure")
    }
  }
  assert_eq(calls, 1)
  assert_eq(errors[0].format(), errors[2].format())
  let original = errors[2].context.length()
  errors[0].context.push({ file: "caller mutation", line: 1, column: 1, })
  assert_eq(errors[2].context.length(), original)
  evaluator.ext_var("invalidate", 1)
  assert_eq(evaluator.evaluate(entry), { "a": 42 })
  assert_eq(calls, 2)
}

///|
test "evaluator raw imports and per execution import budgets" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let mut reads = 0
  evaluator.set_importer(binary_resolver=fn(_, path) {
    reads += 1
    { id: path, bytes: b"\xff\x00", }
  })
  let entry = @moonjsonnet.Program::parse("importbin 'data'")
  for _ in 0..<3 {
    assert_eq(evaluator.evaluate(entry), [255, 0])
  }
  assert_eq(reads, 1)
  evaluator.set_limits({ ..@moonjsonnet.Limits::default(), import_bytes: 1, })
  try evaluator.evaluate(entry) catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected byte budget")
  }
  evaluator.set_limits(@moonjsonnet.Limits::default())
  assert_eq(evaluator.evaluate(entry), [255, 0])
  evaluator.set_importer()
  try evaluator.evaluate(entry) catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Import)
  } noraise {
    _ => fail("expected disabled imports")
  }
}
