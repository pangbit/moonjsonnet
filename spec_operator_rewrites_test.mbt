// Fixed independent criteria: SPEC-OPERATOR-REWRITES-2026-10-23.md.

///|
fn rewrite_library(name : String, args : Array[OrderingExpr]) -> OrderingExpr {
  value_head_call(
    {
      source: "oracle_std." + name,
      tree: ordering_ast(
        Index(sequence_var("oracle_std").tree, reflect_string(name).tree),
      ),
    },
    args,
  )
}

///|
fn rewrite_reference(
  op : String,
  left : OrderingExpr,
  right : OrderingExpr,
) -> OrderingExpr {
  match op {
    "==" => rewrite_library("equals", [left, right])
    "!=" => negation_expr(rewrite_library("equals", [left, right]))
    "%" => rewrite_library("mod", [left, right])
    "in" => rewrite_library("objectHasEx", [right, left, reflect_bool(true)])
    _ => abort("fixture operator outside the fixed rewrite equations")
  }
}

///|
fn rewrite_scope(value : OrderingExpr) -> OrderingExpr {
  sequence_local(
    [
      ("oracle_std", sequence_var("std")),
      ("probe", sequence_call("native", [reflect_string("rewrite-probe")])),
    ],
    sequence_local([("std", ordering_error("public-std-shadow"))], value),
  )
}

///|
fn rewrite_gate(id : OrderingExpr, value : OrderingExpr) -> OrderingExpr {
  let condition = value_head_call(sequence_var("probe"), [id])
  let wrong = ordering_error("probe returned false")
  {
    source: "if (" +
    condition.source +
    ") then (" +
    value.source +
    ") else (" +
    wrong.source +
    ")",
    tree: ordering_ast(If(condition.tree, value.tree, wrong.tree)),
  }
}

///|
fn rewrite_natives(
  counts : Map[String, Int32],
) -> Map[String, @moonjsonnet.NativeFunction] {
  Map([
    (
      "rewrite-probe",
      {
        params: ["id"],
        callback: args => {
          guard args[0] is String(id) else { abort("probe ID is not String") }
          counts[id] = counts.get(id).unwrap_or(0) + 1
          true
        },
      },
    ),
  ])
}

///|
test "rewritten operators retain private std and one demanded head per operand role" {
  let bad = ordering_error("rewrite-unread-tail")
  let object = reflect_object([(reflect_string("h"), 2, bad)])
  let cases : Array[(String, OrderingExpr, OrderingExpr, Json)] = [
    (
      "==",
      ordering_array([sequence_num(1), bad]),
      ordering_array([sequence_num(2), bad]),
      false,
    ),
    (
      "!=",
      ordering_array([sequence_num(1), bad]),
      ordering_array([sequence_num(2), bad]),
      true,
    ),
    ("%", sequence_num(7), sequence_num(3), 1),
    ("%", reflect_string("[%s]"), reflect_string("ok"), "[ok]"),
    ("in", reflect_string("h"), object, true),
    ("in", reflect_string("missing"), object, false),
  ]
  for (op, a, b, expected) in cases {
    let left = rewrite_gate(reflect_string("L"), a)
    let right = rewrite_gate(reflect_string("R"), b)
    for
      expression in [
        ordering_binary(left, op, right),
        rewrite_reference(op, left, right),
      ] {
      for unused in [false, true] {
        let value = rewrite_scope(
          if unused {
            ordering_unused(expression)
          } else {
            expression
          },
        )
        for handmade in [false, true] {
          let counts : Map[String, Int32] = Map([])
          let program = ordering_program(value, handmade)
          assert_eq(counts.length(), 0)
          assert_eq(
            program.evaluate(
              native_functions=rewrite_natives(counts),
              limits=sequence_limits(),
            ),
            if unused {
              42
            } else {
              expected
            },
          )
          assert_eq(counts.get("L").unwrap_or(0), if unused { 0 } else { 1 })
          assert_eq(counts.get("R").unwrap_or(0), if unused { 0 } else { 1 })
          assert_eq(counts.length(), if unused { 0 } else { 2 })
        }
      }
    }
  }
}

///|
test "core logic keeps shortcuts while rewritten errors remain isolated under std shadowing" {
  let cases : Array[(String, Bool, OrderingExpr, Bool, Bool)] = [
    ("&&", false, ordering_error("unused-right"), false, false),
    ("||", true, ordering_error("unused-right"), true, false),
    ("&&", true, reflect_bool(false), false, true),
    ("||", false, reflect_bool(true), true, true),
  ]
  for (op, flag, rhs, expected, needed) in cases {
    let left = rewrite_gate(reflect_string("L"), reflect_bool(flag))
    let right = rewrite_gate(reflect_string("R"), rhs)
    for unused in [false, true] {
      let expression = ordering_binary(left, op, right)
      let value = rewrite_scope(
        if unused {
          ordering_unused(expression)
        } else {
          expression
        },
      )
      for handmade in [false, true] {
        let counts : Map[String, Int32] = Map([])
        assert_eq(
          ordering_program(value, handmade).evaluate(
            native_functions=rewrite_natives(counts),
            limits=sequence_limits(),
          ),
          if unused {
            Json::number(42)
          } else {
            Json::boolean(expected)
          },
        )
        assert_eq(counts.get("L").unwrap_or(0), if unused { 0 } else { 1 })
        assert_eq(
          counts.get("R").unwrap_or(0),
          if !unused && needed {
            1
          } else {
            0
          },
        )
      }
    }
  }
  for op in ["==", "!=", "%", "in"] {
    let good_left = if op == "in" {
      reflect_string("h")
    } else {
      sequence_num(7)
    }
    let good_right = if op == "in" {
      reflect_object([(reflect_string("h"), 2, ordering_error("unread-field"))])
    } else {
      sequence_num(3)
    }
    for left_bad in [false, true] {
      let marker = if left_bad {
        "rewrite-left-required"
      } else {
        "rewrite-right-required"
      }
      let left = if left_bad { ordering_error(marker) } else { good_left }
      let right = if left_bad { good_right } else { ordering_error(marker) }
      for
        value in [
          ordering_binary(left, op, right),
          rewrite_reference(op, left, right),
        ] {
        sequence_failure(
          rewrite_scope(value),
          @moonjsonnet.Runtime,
          Some(marker),
        )
      }
    }
  }
}

///|
test "in super preserves hidden lexical prefix after extracting a function from a derived object" {
  let key = sequence_var("k")
  let membership = ordering_binary(
    rewrite_gate(key, key),
    "in",
    ordering_leaf("super", Var("super")),
  )
  let first = reflect_object([
    (reflect_string("a"), 1, sequence_num(1)),
    (reflect_string("h"), 2, ordering_error("unread-hidden")),
  ])
  let middle = reflect_object([
    (reflect_string("query"), 1, make_function(["k"], membership)),
    (reflect_string("b"), 1, sequence_num(2)),
  ])
  let last = reflect_object([
    (reflect_string("a"), 1, sequence_num(99)),
    (reflect_string("b"), 1, sequence_num(99)),
    (reflect_string("c"), 1, sequence_num(3)),
    (reflect_string("h"), 3, ordering_error("unread-derived")),
  ])
  let object = ordering_binary(ordering_binary(first, "+", middle), "+", last)
  let query : OrderingExpr = {
    source: "(" + object.source + ").query",
    tree: ordering_ast(Index(object.tree, reflect_string("query").tree)),
  }
  let body = sequence_local(
    [("q", query)],
    ordering_array(
      ["h", "a", "b", "c"].map(name => {
        value_head_call(sequence_var("q"), [reflect_string(name)])
      }),
    ),
  )
  for unused in [false, true] {
    let value = rewrite_scope(if unused { ordering_unused(body) } else { body })
    for handmade in [false, true] {
      let counts : Map[String, Int32] = Map([])
      assert_eq(
        ordering_program(value, handmade).evaluate(
          native_functions=rewrite_natives(counts),
          limits=sequence_limits(),
        ),
        if unused {
          Json::number(42)
        } else {
          Json::array([true, true, false, false])
        },
      )
      for name in ["h", "a", "b", "c"] {
        assert_eq(counts.get(name).unwrap_or(0), if unused { 0 } else { 1 })
      }
      assert_eq(counts.length(), if unused { 0 } else { 4 })
    }
  }
}
