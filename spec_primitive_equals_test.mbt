// Frozen criteria/PE0: SPEC-PRIMITIVE-EQUALS-2026-10-22.md.
// Nonscalar same-type rejection is not a normative oracle in these tests.

///|
fn primitive_call(left : OrderingExpr, right : OrderingExpr) -> OrderingExpr {
  sequence_call("primitiveEquals", [left, right])
}

///|
fn primitive_interfaces(
  left : OrderingExpr,
  right : OrderingExpr,
) -> Array[OrderingExpr] {
  [
    primitive_call(left, right),
    sequence_call("equals", [left, right]),
    ordering_binary(left, "==", right),
  ]
}

///|
test "primitive equality scalar truth table does not coerce distinct types" {
  let values = [
    ordering_leaf("null", Literal(Json::null())),
    reflect_bool(false),
    reflect_bool(true),
    sequence_num(0),
    sequence_num(1),
    reflect_string(""),
    reflect_string("0"),
    reflect_string("true"),
  ]
  let expected = [
    [true, false, false, false, false, false, false, false],
    [false, true, false, false, false, false, false, false],
    [false, false, true, false, false, false, false, false],
    [false, false, false, true, false, false, false, false],
    [false, false, false, false, true, false, false, false],
    [false, false, false, false, false, true, false, false],
    [false, false, false, false, false, false, true, false],
    [false, false, false, false, false, false, false, true],
  ]
  for i = 0; i < values.length(); i = i + 1 {
    for j = 0; j < values.length(); j = j + 1 {
      for value in primitive_interfaces(values[i], values[j]) {
        sequence_value(value, Json::boolean(expected[i][j]))
      }
    }
  }
}

///|
test "primitive equality preserves finite signed zero and exact string values" {
  let zero = sequence_num(0)
  let negative_zero = ordering_leaf("-0", Unary("-", zero.tree))
  let cases = [
    (zero, negative_zero, true),
    (negative_zero, zero, true),
    (sequence_num(1), token_number("1.0e0"), true),
    (token_number("9007199254740992"), token_number("9007199254740991"), false),
    (
      ordering_leaf(
        "1.7976931348623157e308",
        Literal(Json::number(1.7976931348623157e308)),
      ),
      token_number("1.7976931348623157e308"),
      true,
    ),
    (ordering_leaf("5e-324", Literal(Json::number(5.0e-324))), zero, false),
    (reflect_string("é"), reflect_string("e\u0301"), false),
    (
      reflect_string("😀"),
      ordering_leaf("'\\ud83d\\ude00'", Literal("😀")),
      true,
    ),
    (reflect_string("\u0000"), reflect_string(""), false),
    (reflect_string("\u0000"), reflect_string("\u0000"), true),
    (reflect_string("A"), reflect_string("a"), false),
  ]
  for (left, right, expected) in cases {
    for value in primitive_interfaces(left, right) {
      sequence_value(value, Json::boolean(expected))
    }
  }
}

///|
test "primitive equality disjoint value classes require no recursive payloads" {
  let payload = ordering_error("undemanded-payload")
  let values = [
    ordering_leaf("null", Literal(Json::null())),
    reflect_bool(false),
    sequence_num(0),
    reflect_string(""),
    ordering_array([payload]),
    reflect_object([(reflect_string("a"), 1, payload)]),
    ordering_leaf(
      "function()error 'undemanded-payload'",
      Func([], payload.tree),
    ),
  ]
  for i = 0; i < values.length(); i = i + 1 {
    for j = 0; j < values.length(); j = j + 1 {
      if i != j {
        for value in primitive_interfaces(values[i], values[j]) {
          sequence_value(value, false)
        }
      }
    }
  }
  let builtin = ordering_leaf(
    "std.length",
    Index(ordering_ast(Var("std")), ordering_ast(Literal("length"))),
  )
  for value in primitive_interfaces(builtin, sequence_num(1)) {
    sequence_value(value, false)
  }
  for value in primitive_interfaces(sequence_num(1), builtin) {
    sequence_value(value, false)
  }
  // These two interfaces use recursive shape gates in the official library.
  // No expected answer is asserted for primitiveEquals on this same-type pair.
  for
    value in [
      sequence_call("equals", [ordering_array([payload]), ordering_array([])]),
      ordering_binary(ordering_array([payload]), "==", ordering_array([])),
    ] {
    sequence_value(value, false)
  }
}

///|
test "primitive equality requires both operand heads and rejects nonfinite producers" {
  for
    (left, right, marker) in [
      (ordering_error("left-required"), sequence_num(1), "left-required"),
      (sequence_num(1), ordering_error("right-required"), "right-required"),
    ] {
    sequence_failure(
      primitive_call(left, right),
      @moonjsonnet.Runtime,
      Some(marker),
    )
  }
  for
    value in [
      primitive_call(token_number("1e309"), sequence_num(0)),
      primitive_call(sequence_num(0), token_number("1e309")),
    ] {
    sequence_failure(value, @moonjsonnet.Runtime, Some("overflow"))
  }
  let unknown : OrderingExpr = {
    source: "if false then primitive_missing else 2",
    tree: ordering_ast(
      If(
        ordering_ast(Literal(false)),
        ordering_ast(Var("primitive_missing")),
        sequence_num(2).tree,
      ),
    ),
  }
  let failed = primitive_call(sequence_num(1), unknown)
  for handmade in [false, true] {
    try ordering_program(ordering_unused(failed), handmade) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
    } noraise {
      _ => fail("unused equality operand escaped static checking")
    }
  }
  try @moonjsonnet.Program::parse("std.primitiveEquals(1,") catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Syntax)
  } noraise {
    _ => fail("unfinished call was admitted")
  }
}
