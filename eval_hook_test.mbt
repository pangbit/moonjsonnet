///|
test "evaluation hooks preserve order laziness and independent nodes" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let events : Array[String] = []
  evaluator.set_eval_hook(hook={
    before: ctx => {
      if ctx.location().file == "entry" {
        let node = ctx.node()
        events.push("before " + ctx.source_range().unwrap().format())
        assert_eq(
          ctx.stack().last().unwrap().source_range(),
          node.source_range(),
        )
        if node.kind is Arr(items) {
          items.clear()
        }
      }
    },
    after: (ctx, outcome) => {
      if ctx.location().file == "entry" {
        guard outcome is Success(value) else { fail("unexpected failure") }
        events.push(
          "after " + ctx.source_range().unwrap().format() + " " + value.kind(),
        )
      }
    },
  })
  let program = @moonjsonnet.Program::parse(
    "if true then 1+2 else error 'unused'",
    filename="entry",
  )
  assert_eq(evaluator.evaluate(program), 3)
  assert_eq(events, [
    "before entry:1:1-37", "before entry:1:4-8", "after entry:1:4-8 boolean", "before entry:1:14-17",
    "before entry:1:14-15", "after entry:1:14-15 number", "before entry:1:16-17",
    "after entry:1:16-17 number", "after entry:1:14-17 number", "after entry:1:1-37 number",
  ])
  events.clear()
  assert_eq(
    evaluator.evaluate(@moonjsonnet.Program::parse("[42]", filename="entry")),
    [42],
  )
  assert_true(events.contains("after entry:1:1-5 array"))
  assert_true(events.contains("after entry:1:2-4 number"))
}

///|
test "hook contexts expire and explicit inspection suppresses hooks" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let contexts : Array[@moonjsonnet.EvalContext] = []
  let values : Array[@moonjsonnet.DebugValue] = []
  let mut visited = 0
  evaluator.set_eval_hook(hook={
    before: ctx => {
      if ctx.location().file == "entry" {
        visited += 1
      }
      if ctx.location().file == "entry" && ctx.node().kind is Var("x") {
        assert_eq(ctx.variables(), ["$std", "std", "unused", "x"])
        assert_true(ctx.peek("x") is None)
        assert_true(ctx.peek("unused") is None)
        let value = ctx.lookup("x")
        assert_eq(value.kind(), "array")
        assert_eq(value.display(), "[<unevaluated>]")
        assert_eq(value.json(), [42])
        assert_eq(value.display(), "[42]")
        assert_true(ctx.peek("x") is Some(_))
        values.push(value)
        contexts.push(ctx)
      }
    },
    after: (_, _) => (),
  })
  assert_eq(
    evaluator.evaluate(
      @moonjsonnet.Program::parse(
        "local x=[21*2],unused=error 'unused';x",
        filename="entry",
      ),
    ),
    [42],
  )
  assert_eq(visited, 2)
  try contexts[0].variables() catch {
    @moonjsonnet.Error(d) =>
      assert_eq(d.message, "evaluation context is no longer active")
  } noraise {
    _ => fail("expired context accepted")
  }
  try values[0].json() catch {
    @moonjsonnet.Error(d) =>
      assert_eq(d.message, "debug value is no longer active")
  } noraise {
    _ => fail("expired value accepted")
  }
}

///|
test "hooks retain failures reject reentry and preserve evaluator caches" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let messages : Array[String] = []
  evaluator.set_eval_hook(hook={
    before: ctx => {
      if ctx.location().file == "entry" {
        try evaluator.set_eval_hook() catch {
          @moonjsonnet.Error(d) =>
            assert_eq(d.message, "evaluator is already executing")
        } noraise {
          _ => fail("reentrant hook replacement accepted")
        }
      }
    },
    after: (ctx, outcome) => {
      if ctx.location().file == "entry" && outcome is Failure(d) {
        messages.push(d.message)
        d.context.clear()
      }
    },
  })
  try
    evaluator.evaluate(
      @moonjsonnet.Program::parse(
        "local f()=error 'failed';f()",
        filename="entry",
      ),
    )
  catch {
    @moonjsonnet.Error(d) => {
      assert_eq(d.message, "failed")
      assert_eq(d.context.length(), 1)
    }
  } noraise {
    _ => fail("expected failure")
  }
  assert_true(messages.length() >= 3)
  assert_eq(evaluator.evaluate(@moonjsonnet.Program::parse("42")), 42)
  let mut calls = 0
  evaluator.set_importer(resolver=(_, _) => {
    calls += 1
    { id: "library", text: "42", }
  })
  let imported = @moonjsonnet.Program::parse("import 'library'")
  assert_eq(evaluator.evaluate(imported), 42)
  evaluator.set_eval_hook()
  assert_eq(evaluator.evaluate(imported), 42)
  assert_eq(calls, 1)
}

///|
test "hook callbacks obey execution budgets and failures recover" {
  let evaluator = @moonjsonnet.Evaluator::new()
  evaluator.set_eval_hook(hook={
    before: ctx => {
      if ctx.location().file == "entry" && ctx.node().kind is Var("x") {
        ignore(ctx.lookup("x").json())
      }
    },
    after: (_, _) => (),
  })
  let program = @moonjsonnet.Program::parse(
    "local x=[1,2,3,4,5];x",
    filename="entry",
  )
  evaluator.set_limits({ ..@moonjsonnet.Limits::default(), stack: 2, })
  try evaluator.evaluate(program) catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("debug inspection ignored stack budget")
  }
  evaluator.set_limits(@moonjsonnet.Limits::default())
  assert_eq(evaluator.evaluate(program), [1, 2, 3, 4, 5])
}

///|
test "hook copies and captured comprehension views obey complete budgets" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let names : Array[Array[String]] = []
  evaluator.set_eval_hook(hook={
    before: ctx => {
      if ctx.location().file == "entry" && ctx.node().kind is Binary("*", _, _) {
        names.push(ctx.variables())
      }
    },
    after: (_, _) => (),
  })
  assert_eq(
    evaluator.evaluate(
      @moonjsonnet.Program::parse(
        "local x=21,unused=0;[x*n for n in [2]]",
        filename="entry",
      ),
    ),
    [42],
  )
  assert_eq(names, [["n", "x"]])
  evaluator.set_eval_hook(hook={
    before: ctx => ignore(ctx.node()),
    after: (_, _) => (),
  })
  evaluator.set_limits({ ..@moonjsonnet.Limits::default(), steps: 10, })
  try
    evaluator.evaluate(@moonjsonnet.Program::parse("[1,2,3,4,5,6,7,8,9,10]"))
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("hook AST copy escaped work budget")
  }
  evaluator.set_eval_hook()
  evaluator.set_limits(@moonjsonnet.Limits::default())
  assert_eq(evaluator.evaluate(@moonjsonnet.Program::parse("42")), 42)
}
