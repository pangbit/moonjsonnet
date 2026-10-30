// Independent criteria: SPEC-ARRAY-ORDERING-REVIEW.md. Trees are constructed
// separately from source, without a parser export or a computed-order oracle.

///|
struct OrderingExpr {
  source : String
  tree : @moonjsonnet.Ast
}

///|
fn ordering_ast(kind : @moonjsonnet.AstKind) -> @moonjsonnet.Ast {
  { kind, loc: { file: "ordering-entry", line: 1, column: 1, }, end: None, }
}

///|
fn ordering_leaf(source : String, kind : @moonjsonnet.AstKind) -> OrderingExpr {
  { source, tree: ordering_ast(kind), }
}

///|
fn ordering_array(values : Array[OrderingExpr]) -> OrderingExpr {
  {
    source: "[" + values.map(v => v.source).join(",") + "]",
    tree: ordering_ast(Arr(values.map(v => v.tree))),
  }
}

///|
fn ordering_error(marker : String) -> OrderingExpr {
  ordering_leaf(
    "error " + Json::string(marker).stringify(),
    Fail(ordering_ast(Literal(Json::string(marker)))),
  )
}

///|
fn ordering_binary(
  left : OrderingExpr,
  op : String,
  right : OrderingExpr,
) -> OrderingExpr {
  {
    source: "(" + left.source + ")" + op + "(" + right.source + ")",
    tree: ordering_ast(Binary(op, left.tree, right.tree)),
  }
}

///|
fn ordering_unused(value : OrderingExpr) -> OrderingExpr {
  {
    source: "local unused=(" + value.source + ");42",
    tree: ordering_ast(
      Local(
        [{ name: "unused", value: value.tree, range: None, }],
        ordering_ast(Literal(42)),
      ),
    ),
  }
}

///|
fn ordering_program(
  value : OrderingExpr,
  handmade : Bool,
) -> @moonjsonnet.Program raise @moonjsonnet.JsonnetError {
  if handmade {
    @moonjsonnet.Program::from_ast(value.tree)
  } else {
    @moonjsonnet.Program::parse(value.source, filename="ordering-entry")
  }
}

///|
fn ordering_limits() -> @moonjsonnet.Limits {
  { ..@moonjsonnet.Limits::default(), steps: 5000, depth: 48, stack: 64, }
}

///|
fn ordering_visit(id : String, value : Int32) -> OrderingExpr {
  let native = ordering_ast(
    Call(
      ordering_ast(
        Index(ordering_ast(Var("std")), ordering_ast(Literal("native"))),
      ),
      [(None, ordering_ast(Literal("visit")))],
      false,
    ),
  )
  {
    source: "std.native('visit')(" +
    Json::string(id).stringify() +
    "," +
    value.to_string() +
    ")",
    tree: ordering_ast(
      Call(
        native,
        [
          (None, ordering_ast(Literal(Json::string(id)))),
          (None, ordering_ast(Literal(Json::number(value.to_double())))),
        ],
        false,
      ),
    ),
  }
}

///|
test "array ordering covers empty prefix and recursive first difference cases" {
  let one = ordering_leaf("1", Literal(1))
  let two = ordering_leaf("2", Literal(2))
  let three = ordering_leaf("3", Literal(3))
  let left_tail = ordering_error("left-unused")
  let right_tail = ordering_error("right-unused")
  let empty = ordering_array([])
  let cases : Array[(OrderingExpr, OrderingExpr, Bool, Bool)] = [
    (empty, empty, false, true),
    (empty, ordering_array([right_tail]), true, true),
    (ordering_array([left_tail]), empty, false, false),
    (
      ordering_array([one, left_tail]),
      ordering_array([two, right_tail]),
      true,
      true,
    ),
    (
      ordering_array([two, left_tail]),
      ordering_array([one, right_tail]),
      false,
      false,
    ),
    (ordering_array([one]), ordering_array([one, right_tail]), true, true),
    (ordering_array([one, left_tail]), ordering_array([one]), false, false),
    (
      ordering_array([one, ordering_array([two, three]), empty]),
      ordering_array([one, ordering_array([two, three]), empty]),
      false,
      true,
    ),
    (
      ordering_array([ordering_array([one, left_tail]), left_tail]),
      ordering_array([ordering_array([two, right_tail]), right_tail]),
      true,
      true,
    ),
    (
      ordering_array([ordering_array([one]), two, left_tail]),
      ordering_array([ordering_array([one]), three, right_tail]),
      true,
      true,
    ),
    (
      ordering_array([empty, left_tail]),
      ordering_array([ordering_array([right_tail]), right_tail]),
      true,
      true,
    ),
    (
      ordering_array([
        one,
        ordering_leaf("'\\uE000'", Literal("")),
        left_tail,
      ]),
      ordering_array([one, ordering_leaf("'😀'", Literal("😀")), right_tail]),
      true,
      true,
    ),
  ]
  for (left, right, less, less_equal) in cases {
    for (op, expected) in [("<", less), ("<=", less_equal)] {
      let value = ordering_binary(left, op, right)
      for handmade in [false, true] {
        assert_eq(
          ordering_program(value, handmade).evaluate(limits=ordering_limits()),
          Json::boolean(expected),
        )
      }
    }
  }
}

///|
test "array ordering observes only the necessary nested common prefix" {
  let left = ordering_array([
    ordering_visit("L0", 1),
    ordering_array([ordering_visit("LN0", 2), ordering_visit("LN1", 4)]),
    ordering_visit("LT", 100),
  ])
  let right = ordering_array([
    ordering_visit("R0", 1),
    ordering_array([ordering_visit("RN0", 2), ordering_visit("RN1", 5)]),
    ordering_visit("RT", 100),
  ])
  for op in ["<", "<="] {
    for unused in [false, true] {
      let comparison = ordering_binary(left, op, right)
      let value = if unused { ordering_unused(comparison) } else { comparison }
      for handmade in [false, true] {
        let seen : Map[String, Bool] = Map([])
        let visit : @moonjsonnet.NativeFunction = {
          params: ["id", "value"],
          callback: args => {
            guard args[0] is String(id) else {
              abort("observer ID must be a string")
            }
            seen[id] = true
            args[1]
          },
        }
        assert_eq(
          ordering_program(value, handmade).evaluate(
            native_functions=Map([("visit", visit)]),
            limits=ordering_limits(),
          ),
          if unused {
            Json::number(42)
          } else {
            Json::boolean(true)
          },
        )
        if unused {
          assert_eq(seen.length(), 0)
        } else {
          for id in ["L0", "R0", "LN0", "RN0", "LN1", "RN1"] {
            assert_true(seen.contains(id))
          }
          assert_eq(seen.length(), 6)
          assert_true(!seen.contains("LT") && !seen.contains("RT"))
        }
      }
    }
  }
}

///|
test "array ordering separates demanded runtime failures from unused static errors" {
  let one = ordering_leaf("1", Literal(1))
  let two = ordering_leaf("2", Literal(2))
  let empty = ordering_array([])
  let text = ordering_leaf("'1'", Literal("1"))
  let cases : Array[
    (OrderingExpr, OrderingExpr, @moonjsonnet.ErrorKind, String?),
  ] = [
    (
      ordering_array([one, ordering_error("required-left")]),
      ordering_array([one, two]),
      @moonjsonnet.Runtime,
      Some("required-left"),
    ),
    (
      ordering_array([one, two]),
      ordering_array([one, ordering_error("required-right")]),
      @moonjsonnet.Runtime,
      Some("required-right"),
    ),
    (
      ordering_array([ordering_array([one, ordering_error("nested-required")])]),
      ordering_array([ordering_array([one, two])]),
      @moonjsonnet.Runtime,
      Some("nested-required"),
    ),
    (
      ordering_error("outer-left"),
      empty,
      @moonjsonnet.Runtime,
      Some("outer-left"),
    ),
    (
      empty,
      ordering_error("outer-right"),
      @moonjsonnet.Runtime,
      Some("outer-right"),
    ),
    (
      ordering_array([one, ordering_leaf("true", Literal(true))]),
      ordering_array([one, ordering_leaf("false", Literal(false))]),
      @moonjsonnet.Type,
      None,
    ),
    (
      ordering_array([ordering_leaf("null", Literal(null))]),
      ordering_array([ordering_leaf("null", Literal(null))]),
      @moonjsonnet.Type,
      None,
    ),
    (ordering_array([one]), ordering_array([text]), @moonjsonnet.Type, None),
    (ordering_array([text]), ordering_array([one]), @moonjsonnet.Type, None),
    (
      ordering_array([one]),
      ordering_array([ordering_array([one])]),
      @moonjsonnet.Type,
      None,
    ),
    (empty, one, @moonjsonnet.Type, None),
    (one, empty, @moonjsonnet.Type, None),
  ]
  for (left, right, kind, marker) in cases {
    for op in ["<", "<="] {
      let value = ordering_binary(left, op, right)
      for handmade in [false, true] {
        assert_eq(
          ordering_program(ordering_unused(value), handmade).evaluate(
            limits=ordering_limits(),
          ),
          42,
        )
        let program = ordering_program(value, handmade)
        try program.evaluate(limits=ordering_limits()) catch {
          @moonjsonnet.Error(d) => {
            assert_eq(d.kind, kind)
            assert_eq(d.location.file, "ordering-entry")
            if marker is Some(text) {
              assert_eq(d.message, text)
            }
          }
        } noraise {
          _ => fail("a demanded comparison failure was suppressed")
        }
      }
    }
  }
  let missing = ordering_leaf("ordering_missing", Var("ordering_missing"))
  for
    (left, right) in [
      (ordering_array([one, missing]), ordering_array([two])),
      (empty, ordering_array([missing])),
      (missing, empty),
      (empty, missing),
    ] {
    for op in ["<", "<="] {
      let value = ordering_binary(left, op, right)
      for subject in [value, ordering_unused(value)] {
        for handmade in [false, true] {
          try ordering_program(subject, handmade) catch {
            @moonjsonnet.Error(d) => {
              assert_eq(d.kind, @moonjsonnet.Static)
              assert_eq(d.location.file, "ordering-entry")
            }
          } noraise {
            _ => fail("an unused comparison captured an unknown name")
          }
        }
      }
    }
  }
}
