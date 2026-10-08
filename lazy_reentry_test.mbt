///|
test "recursive lazy demands retain real frame and expression limits" {
  let sources = [
    "local x=x;x", "local x=1+x;x", "local x={a:self.a};x.a", "local x=[x[0]];x[0]",
    "local f(x)=x;local x=f(x);x", "local x=std.makeArray(1,function(i) x[0]);x[0]",
    "local x={a:1}+{a+:self.a};x.a",
  ]
  for source in sources {
    for stack in [1, 2, 3, 8] {
      try
        @moonjsonnet.evaluate(source, limits={
          ..@moonjsonnet.Limits::default(),
          stack,
        })
      catch {
        @moonjsonnet.Error(diagnostic) => {
          assert_eq(diagnostic.kind, @moonjsonnet.Limit)
          assert_eq(diagnostic.message, "max stack frames exceeded.")
          assert_true(!diagnostic.trace.is_empty())
        }
      } noraise {
        _ => fail("expected recursive lazy frame exhaustion")
      }
    }
    try
      @moonjsonnet.evaluate(source, limits={
        ..@moonjsonnet.Limits::default(),
        depth: 20,
        stack: 2147483647,
      })
    catch {
      @moonjsonnet.Error(diagnostic) => {
        assert_eq(diagnostic.kind, @moonjsonnet.Limit)
        assert_true(diagnostic.message.contains("depth limit exceeded"))
      }
    } noraise {
      _ => fail("expected independent expression depth limit")
    }
  }
  try
    @moonjsonnet.evaluate("local x=1+x;x", limits={
      ..@moonjsonnet.Limits::default(),
      depth: 100,
      stack: 2147483647,
      steps: 100,
    })
  catch {
    @moonjsonnet.Error(diagnostic) =>
      assert_eq(diagnostic.message, "evaluation step limit exceeded")
  } noraise {
    _ => fail("expected independent step limit")
  }
}

///|
test "finite lazy reentry executes callbacks and caches final results" {
  let sources : Array[(String, Int)] = [
    ("local x=if std.native('done')() then 42 else x+1;[x,x]", 44),
    ("local x={a:if std.native('done')() then 42 else self.a+1};[x.a,x.a]", 44),
    ("local x=[if std.native('done')() then 42 else x[0]+1];[x[0],x[0]]", 44),
    (
      "local x=std.makeArray(1,function(i) if std.native('done')() then 42 else x[0]+1);[x[0],x[0]]",
      44,
    ),
    (
      "local x={a:1}+{a+:if std.native('done')() then 42 else self.a+1};[x.a,x.a]",
      47,
    ),
  ]
  for (source, expected) in sources {
    let calls = Ref(0)
    let native : @moonjsonnet.NativeFunction = {
      params: [],
      callback: fn(_) {
        calls.val += 1
        Json::boolean(calls.val == 3)
      },
    }
    assert_eq(
      @moonjsonnet.evaluate(source, native_functions=Map([("done", native)])),
      Json::array([
        Json::number(expected.to_double()),
        Json::number(expected.to_double()),
      ]),
    )
    assert_eq(calls.val, 3)
  }
}

///|
test "reentrant cached imports restore the outermost failed computation" {
  for
    (source, demand) in [
      (
        "local x=if std.native('done')() then 42 else x+error 'outer';{a:x}", "(import 'library').a",
      ),
      (
        "local x=std.makeArray(1,function(i) if std.native('done')() then 42 else x[0]+error 'outer');x",
        "(import 'library')[0]",
      ),
      (
        "{a:if std.native('done')() then 42 else self.a+error 'outer'}", "(import 'library').a",
      ),
    ] {
    let calls = Ref(0)
    let active = Ref(0)
    let evaluator = @moonjsonnet.Evaluator::new()
    evaluator.native_function("done", {
      params: [],
      callback: fn(_) {
        calls.val += 1
        Json::boolean(calls.val >= 3)
      },
    })
    evaluator.set_eval_hook(hook={
      before: fn(_) { active.val += 1 },
      after: fn(_, _) { active.val -= 1 },
    })
    evaluator.set_importer(resolver=(_, _) => { id: "library", text: source, })
    let program = @moonjsonnet.Program::parse(demand)
    try evaluator.evaluate(program) catch {
      @moonjsonnet.Error(diagnostic) => assert_eq(diagnostic.message, "outer")
    } noraise {
      _ => fail("expected the outer computation to fail after an inner result")
    }
    assert_eq(calls.val, 3)
    assert_eq(active.val, 0)
    assert_eq(evaluator.evaluate(program), 42)
    assert_eq(calls.val, 4)
    assert_eq(active.val, 0)
    assert_eq(evaluator.evaluate(program), 42)
    assert_eq(calls.val, 4)
  }
}

///|
test "non-tail external Code and Program reuse their actual independent scopes" {
  for parsed in [false, true] {
    let evaluator = @moonjsonnet.Evaluator::new()
    let calls = Ref(0)
    evaluator.native_function("done", {
      params: [],
      callback: fn(_) {
        calls.val += 1
        Json::boolean(calls.val == 3)
      },
    })
    let source = "if std.native('done')() then 42 else std.extVar('x')+1"
    if parsed {
      evaluator.ext_program("x", @moonjsonnet.Program::parse(source))
    } else {
      evaluator.ext_code("x", source)
    }
    assert_eq(
      evaluator.evaluate(
        @moonjsonnet.Program::parse("[std.extVar('x'),std.extVar('x')]"),
      ),
      Json::array([44, 44]),
    )
    assert_eq(calls.val, 3)
  }
}
