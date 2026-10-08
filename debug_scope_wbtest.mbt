///|
test "debug capture traverses all scopes and complete declaration budgets" {
  let roots = [
    parse_tokens(
      lex(
        "function(x=outer) local y=x;{local z=y,a:z,b:$.a,c:[y for y in inputs if guard_value],d:[x][::step]}",
        "entry",
      ),
      200,
    ),
  ]
  let visible = debug_visibility(roots, [], [], false)
  let mut steps = 0
  try
    visible(fn() raise {
      steps += 1
      if steps > 5 {
        raise problem(Limit, roots[0].loc, "test work budget")
      }
    })
  catch {
    Error(d) => assert_eq(d.kind, Limit)
    _ => fail("unexpected scope error")
  } noraise {
    _ => fail("declaration work was not bounded")
  }
  let names = visible(() => ())
  assert_eq(names, ["$std", "guard_value", "inputs", "outer", "step"])
  // Successful cached analysis does not rerun traversal, but the public context
  // still accounts every returned name against the execution budget.
  assert_eq(visible(() => fail("analysis unexpectedly repeated")), names)
  let nested = debug_visibility(
    [parse_tokens(lex("function() {value:$.outer}", "entry"), 200)],
    [],
    [],
    true,
  )
  assert_eq(nested(() => ()), ["$"])
}
