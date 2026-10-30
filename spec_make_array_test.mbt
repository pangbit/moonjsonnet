// Frozen cardinality/domain/laziness oracle: SPEC-MAKEARRAY-2026-10-22.md.
// All trees are handmade; old negative-size [] behavior is not the oracle.

///|
fn make_function(params : Array[String], body : OrderingExpr) -> OrderingExpr {
  {
    source: "function(" + params.join(",") + ")(" + body.source + ")",
    tree: ordering_ast(
      Func(
        params.map(name => { name, default_value: None, range: None, }),
        body.tree,
      ),
    ),
  }
}

///|
fn make_array(size : OrderingExpr, func : OrderingExpr) -> OrderingExpr {
  sequence_call("makeArray", [size, func])
}

///|
fn make_index(array : OrderingExpr, index : Int32) -> OrderingExpr {
  {
    source: "(" + array.source + ")[" + index.to_string() + "]",
    tree: ordering_ast(Index(array.tree, sequence_num(index).tree)),
  }
}

///|
test "makeArray produces exact nonnegative cardinalities and positional indices" {
  let i = sequence_var("i")
  let func = make_function(
    ["i"],
    ordering_binary(
      ordering_binary(i, "*", sequence_num(10)),
      "+",
      sequence_num(5),
    ),
  )
  sequence_value(make_array(sequence_num(0), func), [])
  sequence_value(make_array(sequence_num(1), func), [5])
  sequence_value(make_array(sequence_num(3), func), [5, 15, 25])
  let negative_zero = ordering_leaf("-0", Unary("-", sequence_num(0).tree))
  sequence_value(make_array(negative_zero, func), [])
}

///|
test "makeArray rejects invalid cardinalities instead of clamping negative sizes" {
  let func = make_function(["i"], ordering_error("uncalled-body"))
  for size in [sequence_num(-1), sequence_num(-2), token_number("1.5")] {
    sequence_failure(make_array(size, func), @moonjsonnet.Runtime, None)
  }
  for
    size in [
      ordering_leaf("null", Literal(Json::null())),
      reflect_bool(true),
      reflect_string("2"),
      ordering_array([]),
      reflect_object([]),
      make_function([], sequence_num(0)),
    ] {
    sequence_failure(make_array(size, func), @moonjsonnet.Type, None)
  }
}

///|
test "makeArray demands both argument heads even at zero but never unused bodies" {
  let func = make_function(["i"], ordering_error("uncalled-body"))
  sequence_value(make_array(sequence_num(0), func), [])
  sequence_value(
    sequence_call("length", [make_array(sequence_num(3), func)]),
    3,
  )
  for
    invalid in [
      ordering_leaf("null", Literal(Json::null())),
      reflect_bool(false),
      sequence_num(1),
      reflect_string("function"),
      ordering_array([]),
      reflect_object([]),
    ] {
    sequence_failure(
      make_array(sequence_num(0), invalid),
      @moonjsonnet.Type,
      None,
    )
  }
  sequence_failure(
    make_array(sequence_num(0), ordering_error("function-head")),
    @moonjsonnet.Runtime,
    Some("function-head"),
  )
  sequence_failure(
    make_array(ordering_error("size-head"), func),
    @moonjsonnet.Runtime,
    Some("size-head"),
  )
  let unknown = make_function(
    ["i"],
    ordering_leaf("make_missing", Var("make_missing")),
  )
  for handmade in [false, true] {
    try
      ordering_program(
        ordering_unused(make_array(sequence_num(0), unknown)),
        handmade,
      )
    catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
    } noraise {
      _ => fail("unused zero-size initializer escaped static checking")
    }
  }
}

///|
test "makeArray delays selected callback applications and arity errors" {
  let body : OrderingExpr = {
    source: "if i==1 then 21 else error 'other-element'",
    tree: ordering_ast(
      If(
        ordering_binary(sequence_var("i"), "==", sequence_num(1)).tree,
        sequence_num(21).tree,
        ordering_error("other-element").tree,
      ),
    ),
  }
  let array = make_array(sequence_num(3), make_function(["i"], body))
  sequence_value(
    sequence_local(
      [("a", array)],
      ordering_array([
        sequence_call("length", [sequence_var("a")]),
        make_index(sequence_var("a"), 1),
        make_index(sequence_var("a"), 1),
      ]),
    ),
    [3, 21, 21],
  )
  sequence_failure(
    make_index(array, 0),
    @moonjsonnet.Runtime,
    Some("other-element"),
  )
  let two = make_function(["i", "required"], sequence_var("i"))
  sequence_value(make_array(sequence_num(0), two), [])
  let one = make_array(sequence_num(1), two)
  sequence_value(sequence_call("length", [one]), 1)
  sequence_failure(make_index(one, 0), @moonjsonnet.Runtime, None)
}
