// Fixed independent criteria: SPEC-NEGATION-2026-10-23.md.

///|
fn negation_expr(value : OrderingExpr) -> OrderingExpr {
  {
    source: "!(" + value.source + ")",
    tree: ordering_ast(Unary("!", value.tree)),
  }
}

///|
fn negation_std_field(name : String) -> OrderingExpr {
  {
    source: "std." + name,
    tree: ordering_ast(
      Index(ordering_ast(Var("std")), ordering_ast(Literal(Json::string(name)))),
    ),
  }
}

///|
test "logical negation flips both Booleans and demands only a used operand head" {
  for (operand, expected) in [(true, false), (false, true)] {
    sequence_value(
      negation_expr(reflect_bool(operand)),
      Json::boolean(expected),
    )
    let observed = negation_expr(boolean_observe("B", reflect_bool(operand)))
    for unused in [false, true] {
      let expression = if unused { ordering_unused(observed) } else { observed }
      for handmade in [false, true] {
        let seen : Map[String, Bool] = Map([])
        let program = ordering_program(expression, handmade)
        assert_eq(seen.length(), 0)
        assert_eq(
          program.evaluate(
            native_functions=boolean_natives(seen),
            limits=sequence_limits(),
          ),
          if unused {
            Json::number(42)
          } else {
            Json::boolean(expected)
          },
        )
        if unused {
          assert_eq(seen.length(), 0)
        } else {
          assert_true(seen.contains("B"))
          assert_eq(seen.length(), 1)
        }
      }
    }
  }
}

///|
test "logical negation rejects non Boolean values without manifesting or calling them" {
  let bad = ordering_error("negation-unread")
  let closure = ordering_leaf(
    "function() error 'negation-unread'",
    Func([], bad.tree),
  )
  for
    value in [
      sequence_num(0),
      sequence_num(1),
      reflect_string(""),
      reflect_string("true"),
      ordering_array([]),
      ordering_array([bad]),
      reflect_object([]),
      reflect_object([(reflect_string("x"), 1, bad)]),
      closure,
    ] {
    sequence_failure(negation_expr(value), @moonjsonnet.Type, None)
  }
  sequence_failure(
    negation_expr(ordering_error("negation-required")),
    @moonjsonnet.Runtime,
    Some("negation-required"),
  )
  // Builtin and native function values are rejected without invocation.
  for
    value in [
      negation_std_field("length"),
      sequence_call("native", [reflect_string("observe")]),
    ] {
    let operation = negation_expr(value)
    for handmade in [false, true] {
      let seen : Map[String, Bool] = Map([])
      let natives = boolean_natives(seen)
      assert_eq(
        ordering_program(ordering_unused(operation), handmade).evaluate(
          native_functions=natives,
          limits=sequence_limits(),
        ),
        42,
      )
      let program = ordering_program(operation, handmade)
      try
        program.evaluate(native_functions=natives, limits=sequence_limits())
      catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Type)
      } noraise {
        _ => fail("function value was coerced to Boolean")
      }
      assert_eq(seen.length(), 0)
    }
  }
}
