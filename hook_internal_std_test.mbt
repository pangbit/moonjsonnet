///|
test "hooks export clean nodes and paired stacks across private standard adapters" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let active : Array[Int] = []
  let seen : Map[Int, Bool] = Map([])
  let contexts : Array[@moonjsonnet.EvalContext] = []
  let values : Array[@moonjsonnet.DebugValue] = []
  let mut saw_root = false
  let mut saw_source_child = false
  let mut saw_source_stack = false
  let mut completed = 0
  evaluator.set_eval_hook(hook={
    before: ctx => {
      // Every admitted expression must have a real exportable node, including
      // library initialization and actual inherited adapter execution.
      let node = ctx.node()
      let id = ctx.evaluation_id()
      assert_true(!seen.contains(id))
      seen[id] = true
      let source_stack = !saw_source_stack &&
        ctx.location().file == "<std>" &&
        !active.is_empty()
      if ctx.location().file == "hook-entry" || source_stack {
        let stack = ctx.stack()
        assert_eq(stack.length(), active.length() + 1)
        assert_eq(stack.last().unwrap().loc, node.loc)
        if source_stack {
          saw_source_stack = true
        }
      }
      active.push(id)
      if ctx.location().file == "hook-entry" &&
        node.kind is Local(bindings, body) &&
        bindings[0].name == "s" {
        guard body.kind is Arr(items) else { fail("user root was replaced") }
        assert_eq(items.length(), 5)
        saw_root = true
        contexts.push(ctx)
      }
      if ctx.location().file == "<std>" &&
        node.kind is Literal(String("startsWith")) {
        saw_source_child = true
      }
    },
    after: (ctx, outcome) => {
      let node = ctx.node()
      if ctx.location().file == "hook-entry" {
        let stack = ctx.stack()
        assert_eq(stack.length(), active.length())
        assert_eq(stack.last().unwrap().loc, node.loc)
      }
      assert_eq(active.pop(), Some(ctx.evaluation_id()))
      completed += 1
      match outcome {
        Success(value) =>
          if ctx.location().file == "hook-entry" && values.is_empty() {
            values.push(value)
          }
        Failure(d) => fail(d.format())
      }
    },
  })
  // Default public limits; empty-key TOML reaches its adapter without the
  // unrelated key-alphabet sorting work. Observing/copying nodes is budgeted.
  let program = @moonjsonnet.Program::parse(
    "local s=std+{}; [s.startsWith('ab','a'), s.base64([1.5]), s.base64DecodeBytes('Zg==\\r\\n\\r\\n'), s.manifestTomlEx({'':1},''), s.removeAt([1,2],idx=0)]",
    filename="hook-entry",
  )
  assert_eq(evaluator.evaluate(program), [true, "AQ==", [102], "'' = 1", [2]])
  assert_true(saw_root && saw_source_child && saw_source_stack)
  assert_true(active.is_empty())
  assert_eq(completed, seen.length())
  try contexts[0].node() catch {
    @moonjsonnet.Error(d) =>
      assert_eq(d.message, "evaluation context is no longer active")
  } noraise {
    _ => fail("private-wrapper evaluation retained an active context")
  }
  try values[0].kind() catch {
    @moonjsonnet.Error(d) =>
      assert_eq(d.message, "debug value is no longer active")
  } noraise {
    _ => fail("private-wrapper evaluation retained an active value handle")
  }
}

///|
test "a user filename matching the standard library still exposes its real nodes" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let active : Array[Int] = []
  let mut root_seen = false
  let mut call_seen = false
  let mut before_count = 0
  let mut after_count = 0
  evaluator.set_eval_hook(hook={
    before: ctx => {
      let node = ctx.node()
      active.push(ctx.evaluation_id())
      before_count += 1
      if node.kind is Local(bindings, body) && bindings[0].name == "f" {
        guard body.kind is Call(target, _, _) else {
          fail("same-filename user root was replaced")
        }
        assert_true(target.kind is Var("f"))
        assert_eq(ctx.stack().last().unwrap().loc, node.loc)
        root_seen = true
      }
      if node.kind is Call({ kind: Var("f"), .. }, _, _) {
        assert_eq(ctx.stack().length(), active.length())
        call_seen = true
      }
    },
    after: (ctx, _) => {
      ignore(ctx.node())
      assert_eq(active.pop(), Some(ctx.evaluation_id()))
      after_count += 1
    },
  })
  assert_eq(
    evaluator.evaluate(
      @moonjsonnet.Program::parse("local f(x)=x+1;f(41)", filename="<std>"),
    ),
    42,
  )
  assert_true(root_seen && call_seen)
  assert_true(active.is_empty())
  assert_eq(before_count, after_count)
}
