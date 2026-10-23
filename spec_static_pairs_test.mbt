// Independent fixed criteria: SPEC-STATIC-PAIRS-2026-10-23.md.

///|
fn pair_symbols() -> Array[String] {
  [
    "[]", "*", "/", "%", "+", "-", "<<", ">>", "<", "<=", ">", ">=", "==", "!=",
    "in", "&", "^", "|", "&&", "||",
  ]
}

///|
fn pair_expr(
  op : String,
  left : OrderingExpr,
  right : OrderingExpr,
) -> OrderingExpr {
  if op == "[]" {
    {
      source: "(" + left.source + ")[" + right.source + "]",
      tree: ordering_ast(Index(left.tree, right.tree)),
    }
  } else {
    ordering_binary(left, op, right)
  }
}

///|
fn pair_reject(value : OrderingExpr) -> Unit raise {
  let skipped : OrderingExpr = {
    source: "if false then (" + value.source + ") else 42",
    tree: ordering_ast(
      If(ordering_ast(Literal(false)), value.tree, sequence_num(42).tree),
    ),
  }
  for expression in [value, ordering_unused(value), skipped] {
    for handmade in [false, true] {
      try ordering_program(expression, handmade) catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
      } noraise {
        _ => fail("paired static child was skipped or given a different scope")
      }
    }
  }
}

///|
fn pair_access(name : String) -> OrderingExpr {
  pair_expr("[]", ordering_leaf(name, Var(name)), reflect_string("n"))
}

///|
fn pair_field(value : OrderingExpr) -> OrderingExpr {
  reflect_object([(reflect_string("u"), 1, value)])
}

///|
fn pair_inherited(value : OrderingExpr) -> OrderingExpr {
  ordering_binary(
    reflect_object([(reflect_string("n"), 1, sequence_num(0))]),
    "+",
    pair_field(value),
  )
}

///|
test "paired static children preserve enclosing names without sibling binding leaks" {
  let missing = sequence_var("pair_missing")
  let zero = sequence_num(0)
  let private_child = sequence_local(
    [("pair_private", zero)],
    sequence_var("pair_private"),
  )
  for op in pair_symbols() {
    for
      value in [
        pair_expr(op, missing, zero),
        pair_expr(op, zero, missing),
        pair_expr(op, private_child, sequence_var("pair_private")),
        pair_expr(op, sequence_var("pair_private"), private_child),
      ] {
      pair_reject(value)
    }
    let scoped = sequence_local(
      [("a", ordering_error("unread-a")), ("b", ordering_error("unread-b"))],
      ordering_unused(pair_expr(op, sequence_var("a"), sequence_var("b"))),
    )
    sequence_value(scoped, 42)
  }
}

///|
test "paired static children retain object permissions without granting them to field keys" {
  for op in pair_symbols() {
    for name in ["self", "super", "$"] {
      let access = pair_access(name)
      for
        value in [
          pair_expr(op, access, sequence_num(0)),
          pair_expr(op, sequence_num(0), access),
        ] {
        pair_reject(value)
        pair_reject(reflect_object([(value, 1, sequence_num(42))]))
        let object = if name == "super" {
          pair_inherited(value)
        } else {
          pair_field(value)
        }
        sequence_value(ordering_unused(object), 42)
      }
    }
  }
}

///|
test "super pair special cases require permission and still check the key scope" {
  let parent = ordering_leaf("super", Var("super"))
  for op in ["[]", "in"] {
    let operation = fn(key : OrderingExpr) {
      if op == "[]" {
        pair_expr(op, parent, key)
      } else {
        pair_expr(op, key, parent)
      }
    }
    pair_reject(operation(reflect_string("n")))
    pair_reject(pair_inherited(operation(sequence_var("missing_super_key"))))
    let bound = sequence_local(
      [("k", reflect_string("n"))],
      operation(sequence_var("k")),
    )
    sequence_value(ordering_unused(pair_inherited(bound)), 42)
  }
}

///|
test "static pair admission imposes no runtime index or binary type requirement" {
  let poisoned = ordering_array([ordering_error("pair-element-demand")])
  for key in [ordering_leaf("0.5", NumberLiteral("0.5")), sequence_num(2)] {
    let value = pair_expr("[]", poisoned, key)
    for handmade in [false, true] {
      let program = ordering_program(value, handmade)
      assert_eq(
        ordering_program(ordering_unused(value), handmade).evaluate(
          limits=sequence_limits(),
        ),
        42,
      )
      try program.evaluate(limits=sequence_limits()) catch {
        @moonjsonnet.Error(d) => {
          assert_eq(d.kind, @moonjsonnet.Runtime)
          assert_true(d.message != "pair-element-demand")
        }
      } noraise {
        _ => fail("required index constraint was ignored")
      }
    }
  }
  sequence_failure(
    pair_expr("[]", poisoned, sequence_num(0)),
    @moonjsonnet.Runtime,
    Some("pair-element-demand"),
  )
  for op in pair_symbols() {
    let mixed = pair_expr(
      op,
      reflect_string("not-a-type-premise"),
      ordering_leaf("null", Literal(Json::null())),
    )
    sequence_value(ordering_unused(mixed), 42)
  }
}
