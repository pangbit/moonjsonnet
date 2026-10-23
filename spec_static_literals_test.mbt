// Fixed independent criteria: SPEC-STATIC-LITERALS-2026-10-23.md.

///|
fn literal_contexts(value : OrderingExpr) -> Array[OrderingExpr] {
  [
    value,
    sequence_local([("x", sequence_num(1))], value),
    {
      source: "function(p=(" + value.source + ")) (" + value.source + ")",
      tree: ordering_ast(
        Func(
          [{ name: "p", default_value: Some(value.tree), range: None, }],
          value.tree,
        ),
      ),
    },
    reflect_object([(reflect_string("v"), 1, value)]),
  ]
}

///|
test "static scalar leaves ignore enclosing environments and literal name-like text" {
  let values = [
    ordering_leaf("null", Literal(Json::null())),
    reflect_bool(false),
    reflect_bool(true),
    sequence_num(0),
    ordering_leaf("1.5", Literal(Json::number(1.5))),
    token_number("1.5"),
    reflect_string(""),
    reflect_string("unbound self super $ \\q"),
  ]
  for value in values {
    for expression in literal_contexts(value) {
      for handmade in [false, true] {
        ignore(ordering_program(expression, handmade))
      }
      sequence_value(ordering_unused(expression), 42)
    }
  }
}

///|
test "literal host shape distinguishes scalar values from numeric spellings and containers" {
  // Source signs are Unary syntax; the handmade leaves here are canonical values.
  for
    (source, expected) in [
      ("-1", Json::number(-1)),
      ("-0", Json::number(-0.0)),
      ("+1", Json::number(1)),
    ] {
    let value = ordering_leaf(source, Literal(expected))
    for handmade in [false, true] {
      ignore(ordering_program(value, handmade))
    }
    sequence_value(ordering_unused(value), 42)
  }
  let malformed = [
    ordering_ast(NumberLiteral("-1")),
    ordering_ast(NumberLiteral("-0")),
    ordering_ast(NumberLiteral("+1")),
    ordering_ast(Literal(Json::array([Json::number(1)]))),
    ordering_ast(Literal(Json::object(Map([])))),
  ]
  for tree in malformed {
    for
      wrapped in [
        tree,
        ordering_unused({ source: "unused-host-shape", tree, }).tree,
      ] {
      try @moonjsonnet.Program::from_ast(wrapped) catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
      } noraise {
        _ => fail("non scalar or malformed numeric host literal was admitted")
      }
    }
  }
  for container in [ordering_array([sequence_num(1)]), reflect_object([])] {
    sequence_value(ordering_unused(container), 42)
  }
}
