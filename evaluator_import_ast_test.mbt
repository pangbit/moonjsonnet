///|
test "nullable import AST caches static failure without weakening strict queries" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let mut reads = 0
  evaluator.set_importer(resolver=fn(_, _) {
    reads += 1
    { id: "lib/main", text: "missing", }
  })
  for _ in 0..<2 {
    try evaluator.import_program("entry", "main") catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
    } noraise {
      _ => fail("strict query must fail")
    }
  }
  try evaluator.import_ast("entry", "main") catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
  } noraise {
    _ => fail("first nullable query must fail")
  }
  for _ in 0..<2 {
    let (program, id) = evaluator.import_ast("entry", "main")
    assert_true(program is None)
    assert_eq(id, "lib/main")
    try evaluator.import_program("entry", "main") catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
    } noraise {
      _ => fail("nullable cache must not weaken strict queries")
    }
  }
  assert_eq(reads, 1)
}

///|
test "nullable import AST syntax history survives setters and resets with importer" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let mut reads = 0
  let mut source = "["
  let resolver : (String, String) -> @moonjsonnet.Source raise = (_, path) => {
    reads += 1
    { id: path, text: source, }
  }
  evaluator.set_importer(resolver~)
  try evaluator.import_ast("", "main") catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Syntax)
  } noraise {
    _ => fail("syntax error expected")
  }
  source = "42"
  evaluator.ext_var("x", 1)
  evaluator.ext_reset()
  evaluator.tla_reset()
  evaluator.native_function("tick", { params: [], callback: _ => 7, })
  evaluator.set_trace((_, _) => ())
  assert_true(evaluator.import_ast("", "main").0 is None)
  assert_eq(reads, 1)
  evaluator.set_importer(resolver~)
  let (program, id) = evaluator.import_ast("", "main")
  guard program is Some(program) else {
    fail("importer reset must clear nil history")
  }
  assert_eq(id, "main")
  assert_eq(program.evaluate(), 42)
  assert_eq(reads, 2)
}

///|
test "nullable import AST returns valid programs without executing callbacks" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let mut reads = 0
  let mut calls = 0
  let messages = []
  evaluator.native_function("tick", {
    params: [],
    callback: _ => {
      calls += 1
      42
    },
  })
  evaluator.set_trace((_, message) => messages.push(message))
  evaluator.set_importer(binary_resolver=fn(_, _) {
    reads += 1
    { id: "lib/main", bytes: b"std.trace('run',std.native('tick')())", }
  })
  let (program, id) = evaluator.import_ast("entry", "main")
  guard program is Some(program) else { fail("valid AST expected") }
  assert_eq(id, "lib/main")
  assert_true(evaluator.import_ast("entry", "main").0 is Some(_))
  let (strict, _) = evaluator.import_program("entry", "main")
  assert_eq((reads, calls), (1, 0))
  assert_eq(messages, [])
  assert_eq(evaluator.evaluate(program), 42)
  assert_eq(evaluator.evaluate(strict), 42)
  assert_eq((reads, calls), (1, 2))
  assert_eq(messages, ["run", "run"])
}

///|
test "nullable import AST does not cache host errors as nil" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let mut reads = 0
  evaluator.set_importer(resolver=fn(_, path) raise {
    reads += 1
    if reads <= 2 {
      fail("host unavailable")
    }
    { id: path, text: "42", }
  })
  for _ in 0..<2 {
    try evaluator.import_ast("", "main") catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Import)
    } noraise {
      _ => fail("host error expected on each retry")
    }
  }
  assert_true(evaluator.import_ast("", "main").0 is Some(_))
  assert_eq(reads, 3)
}

///|
test "nullable import AST does not cache invalid UTF8 as nil" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let mut reads = 0
  evaluator.set_importer(binary_resolver=fn(_, path) {
    reads += 1
    { id: path, bytes: b"\xff", }
  })
  for _ in 0..<2 {
    try evaluator.import_ast("", "main") catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Import)
    } noraise {
      _ => fail("UTF8 policy must fail on each retry")
    }
  }
  assert_eq(reads, 1)
}

///|
test "nullable import AST checks cached nil bytes and retries depth limits" {
  let evaluator = @moonjsonnet.Evaluator::new()
  evaluator.set_importer(resolver=fn(_, path) {
    { id: path, text: if path == "bad" { "missing" } else { "[[[[[42]]]]]" }, }
  })
  try evaluator.import_ast("", "bad") catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
  } noraise {
    _ => fail("static failure expected")
  }
  evaluator.set_limits({ ..@moonjsonnet.Limits::default(), import_bytes: 1, })
  try evaluator.import_ast("", "bad") catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("cached nil must obey byte limit")
  }
  evaluator.set_limits({ ..@moonjsonnet.Limits::default(), depth: 4, })
  for _ in 0..<2 {
    try evaluator.import_ast("", "deep") catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
    } noraise {
      _ => fail("depth failure must not become nil")
    }
  }
  evaluator.set_limits(@moonjsonnet.Limits::default())
  assert_true(evaluator.import_ast("", "bad").0 is None)
  assert_true(evaluator.import_ast("", "deep").0 is Some(_))
  evaluator.set_limits({ ..@moonjsonnet.Limits::default(), depth: 4, })
  for _ in 0..<2 {
    try evaluator.import_ast("", "deep") catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
    } noraise {
      _ => fail("cached successful AST must obey depth limit")
    }
  }
}

///|
test "nullable import AST uses resolved identity and rejects reentry" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let mut reentries = 0
  let mut reads = 0
  evaluator.set_importer(resolver=fn(_, _) raise {
    reads += 1
    try evaluator.import_ast("", "again") catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Runtime)
        reentries += 1
      }
    } noraise {
      _ => fail("reentry must be rejected")
    }
    { id: "shared", text: "missing", }
  })
  try evaluator.import_ast("", "first") catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
  } noraise {
    _ => fail("first parse must fail")
  }
  let (program, id) = evaluator.import_ast("", "alias")
  assert_true(program is None)
  assert_eq(id, "shared")
  assert_eq((reads, reentries), (2, 2))
}
