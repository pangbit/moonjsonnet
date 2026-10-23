// Fixed independent criteria: SPEC-VALUE-HEADS-2026-10-23.md.

///|
fn value_head_call(
  function : OrderingExpr,
  args : Array[OrderingExpr],
) -> OrderingExpr {
  {
    source: "(" +
    function.source +
    ")(" +
    args.map(a => "(" + a.source + ")").join(",") +
    ")",
    tree: ordering_ast(
      Call(function.tree, args.map(a => (None, a.tree)), false),
    ),
  }
}

///|
fn value_head_function(
  default : OrderingExpr,
  body : OrderingExpr,
) -> OrderingExpr {
  {
    source: "function(p=(" + default.source + ")) (" + body.source + ")",
    tree: ordering_ast(
      Func(
        [{ name: "p", default_value: Some(default.tree), range: None, }],
        body.tree,
      ),
    ),
  }
}

///|
fn value_head_scope(
  name : String,
  value : OrderingExpr,
  body : OrderingExpr,
) -> OrderingExpr {
  sequence_local(
    [("x", sequence_num(7)), (name, value)],
    sequence_local([("x", sequence_num(99))], body),
  )
}

///|
test "Array value heads retain ordered deferred children and their defining scope" {
  let a = sequence_var("a")
  let array = ordering_array([
    boolean_observe("element", sequence_var("x")),
    ordering_error("value-array-tail"),
    make_function([], ordering_error("value-nested-body")),
  ])
  let heads = ordering_array([
    sequence_call("type", [a]),
    sequence_call("length", [a]),
    sequence_call("type", [make_index(a, 2)]),
  ])
  for
    (body, expected, selected) in [
      (heads, Json::array(["array", 3, "function"]), false),
      (make_index(a, 0), Json::number(7), true),
    ] {
    let value = value_head_scope("a", array, body)
    for handmade in [false, true] {
      let seen : Map[String, Bool] = Map([])
      let program = ordering_program(value, handmade)
      assert_eq(seen.length(), 0)
      assert_eq(
        program.evaluate(
          native_functions=boolean_natives(seen),
          limits=sequence_limits(),
        ),
        expected,
      )
      assert_eq(seen.contains("element"), selected)
      assert_eq(seen.length(), if selected { 1 } else { 0 })
    }
  }
  sequence_failure(
    value_head_scope("a", array, make_index(a, 1)),
    @moonjsonnet.Runtime,
    Some("value-array-tail"),
  )
  sequence_failure(
    ordering_array([ordering_error("value-array-manifest")]),
    @moonjsonnet.Runtime,
    Some("value-array-manifest"),
  )
}

///|
test "Function value heads defer defaults bodies and preserve defining scope until application" {
  let f = sequence_var("f")
  let function = value_head_function(
    boolean_observe("default", sequence_var("x")),
    boolean_observe(
      "body",
      ordering_binary(sequence_var("p"), "+", sequence_var("x")),
    ),
  )
  for
    (body, expected, applied, defaulted) in [
      (sequence_call("type", [f]), Json::string("function"), false, false),
      (value_head_call(f, [sequence_num(3)]), Json::number(10), true, false),
      (value_head_call(f, []), Json::number(14), true, true),
    ] {
    let value = value_head_scope("f", function, body)
    for handmade in [false, true] {
      let seen : Map[String, Bool] = Map([])
      let program = ordering_program(value, handmade)
      assert_eq(seen.length(), 0)
      assert_eq(
        program.evaluate(
          native_functions=boolean_natives(seen),
          limits=sequence_limits(),
        ),
        expected,
      )
      assert_eq(seen.contains("body"), applied)
      assert_eq(seen.contains("default"), defaulted)
      assert_eq(
        seen.length(),
        if defaulted {
          2
        } else if applied {
          1
        } else {
          0
        },
      )
    }
  }
  let error_default = value_head_function(
    ordering_error("value-function-default"),
    sequence_var("p"),
  )
  let error_body = make_function([], ordering_error("value-function-body"))
  for value in [error_default, error_body] {
    sequence_value(sequence_call("type", [value]), "function")
  }
  sequence_value(value_head_call(error_default, [sequence_num(5)]), 5)
  sequence_failure(
    value_head_call(error_default, []),
    @moonjsonnet.Runtime,
    Some("value-function-default"),
  )
  sequence_failure(
    value_head_call(error_body, []),
    @moonjsonnet.Runtime,
    Some("value-function-body"),
  )
  // A container bypasses the API's one top-level Function application.
  for handmade in [false, true] {
    let program = ordering_program(ordering_array([error_body]), handmade)
    try program.evaluate(limits=sequence_limits()) catch {
      @moonjsonnet.Error(d) => assert_true(d.message != "value-function-body")
    } noraise {
      _ => fail("Function unexpectedly had a JSON representation")
    }
  }
}
