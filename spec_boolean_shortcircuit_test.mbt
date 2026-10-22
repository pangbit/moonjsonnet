// Criteria: SPEC-BOOLEAN-SHORTCIRCUIT-REVIEW.md. Reuse only the neutral
// ordering_* builders; all Boolean trees and literal oracles below are new.

///|
fn boolean_observe(id : String, value : OrderingExpr) -> OrderingExpr {
  let native = ordering_ast(
    Call(
      ordering_ast(
        Index(ordering_ast(Var("std")), ordering_ast(Literal("native"))),
      ),
      [(None, ordering_ast(Literal("observe")))],
      false,
    ),
  )
  {
    source: "std.native('observe')(" +
    Json::string(id).stringify() +
    ",(" +
    value.source +
    "))",
    tree: ordering_ast(
      Call(
        native,
        [(None, ordering_ast(Literal(Json::string(id)))), (None, value.tree)],
        false,
      ),
    ),
  }
}

///|
fn boolean_natives(
  seen : Map[String, Bool],
) -> Map[String, @moonjsonnet.NativeFunction] {
  Map([
    (
      "observe",
      {
        params: ["id", "value"],
        callback: args => {
          guard args[0] is String(id) else {
            abort("observer ID must be a string")
          }
          seen[id] = true
          args[1]
        },
      },
    ),
  ])
}

///|
fn boolean_pair(left : Bool, op : String, right : Bool) -> OrderingExpr {
  let value = ordering_binary(
    boolean_observe("L", ordering_leaf("x", Var("x"))),
    op,
    boolean_observe("R", ordering_leaf("y", Var("y"))),
  )
  {
    source: "local x=" +
    left.to_string() +
    ",y=" +
    right.to_string() +
    ";" +
    value.source,
    tree: ordering_ast(
      Local(
        [
          {
            name: "x",
            value: ordering_ast(Literal(Json::boolean(left))),
            range: None,
          },
          {
            name: "y",
            value: ordering_ast(Literal(Json::boolean(right))),
            range: None,
          },
        ],
        value.tree,
      ),
    ),
  }
}

///|
fn boolean_failure(
  value : OrderingExpr,
  kind : @moonjsonnet.ErrorKind,
  marker : String?,
) -> Unit raise {
  for handmade in [false, true] {
    let seen : Map[String, Bool] = Map([])
    let natives = boolean_natives(seen)
    assert_eq(
      ordering_program(ordering_unused(value), handmade).evaluate(
        native_functions=natives,
        limits=ordering_limits(),
      ),
      42,
    )
    assert_eq(seen.length(), 0)
    let program = ordering_program(value, handmade)
    try
      program.evaluate(native_functions=natives, limits=ordering_limits())
    catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, kind)
        assert_eq(d.location.file, "ordering-entry")
        if marker is Some(text) {
          assert_eq(d.message, text)
        }
      }
    } noraise {
      _ => fail("required Boolean operand failure was suppressed")
    }
    assert_eq(seen.length(), 0)
  }
}

///|
test "Boolean operators transfer the full truth table and required lexical operands" {
  for
    (left, right, and_value, or_value) in [
      (false, false, false, false),
      (false, true, false, true),
      (true, false, false, true),
      (true, true, true, true),
    ] {
    for
      (op, expected, need_right) in [
        ("&&", and_value, left),
        ("||", or_value, !left),
      ] {
      let comparison = boolean_pair(left, op, right)
      for unused in [false, true] {
        let value = if unused {
          ordering_unused(comparison)
        } else {
          comparison
        }
        for handmade in [false, true] {
          let seen : Map[String, Bool] = Map([])
          assert_eq(
            ordering_program(value, handmade).evaluate(
              native_functions=boolean_natives(seen),
              limits=ordering_limits(),
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
            assert_true(seen.contains("L"))
            assert_eq(seen.contains("R"), need_right)
            assert_eq(seen.length(), if need_right { 2 } else { 1 })
          }
        }
      }
    }
  }
}

///|
test "Boolean left type gates and shortcuts preserve dormant right shapes and errors" {
  let yes = ordering_leaf("true", Literal(true))
  let payload = boolean_observe("payload", yes)
  let nonbooleans = [
    ordering_leaf("null", Literal(null)),
    ordering_leaf("0", Literal(0)),
    ordering_leaf("''", Literal("")),
    ordering_array([payload]),
    ordering_leaf(
      "{payload:" + payload.source + "}",
      Obj(
        [
          {
            key: ordering_ast(Literal("payload")),
            value: payload.tree,
            visibility: 1,
            additive: false,
          },
        ],
        [],
        [],
      ),
    ),
    ordering_leaf("function()" + payload.source, Func([], payload.tree)),
  ]
  for (op, shortcut, enable) in [("&&", false, true), ("||", true, false)] {
    let rhs = boolean_observe("R", yes)
    for nonboolean in nonbooleans {
      boolean_failure(
        ordering_binary(nonboolean, op, rhs),
        @moonjsonnet.Type,
        None,
      )
      let value = ordering_binary(
        ordering_leaf(shortcut.to_string(), Literal(Json::boolean(shortcut))),
        op,
        nonboolean,
      )
      for handmade in [false, true] {
        let seen : Map[String, Bool] = Map([])
        assert_eq(
          ordering_program(value, handmade).evaluate(
            native_functions=boolean_natives(seen),
            limits=ordering_limits(),
          ),
          Json::boolean(shortcut),
        )
        assert_eq(seen.length(), 0)
      }
    }
    boolean_failure(
      ordering_binary(ordering_error("left-required"), op, rhs),
      @moonjsonnet.Runtime,
      Some("left-required"),
    )
    boolean_failure(
      ordering_binary(
        ordering_leaf(enable.to_string(), Literal(Json::boolean(enable))),
        op,
        ordering_error("right-required"),
      ),
      @moonjsonnet.Runtime,
      Some("right-required"),
    )
  }
  // Forced non-Boolean RHS is deliberately absent: the fixed longcut
  // metavariable domain remains B0, not a passing Type assertion.
}

///|
test "Boolean statics visit both operands even under shortcuts and unused bindings" {
  let missing = ordering_leaf("boolean_missing", Var("boolean_missing"))
  for op in ["&&", "||"] {
    for choice in [false, true] {
      let flag = ordering_leaf(
        choice.to_string(),
        Literal(Json::boolean(choice)),
      )
      for
        value in [
          ordering_binary(missing, op, flag),
          ordering_binary(flag, op, missing),
        ] {
        for subject in [value, ordering_unused(value)] {
          for handmade in [false, true] {
            try ordering_program(subject, handmade) catch {
              @moonjsonnet.Error(d) => {
                assert_eq(d.kind, @moonjsonnet.Static)
                assert_eq(d.location.file, "ordering-entry")
              }
            } noraise {
              _ => fail("a skipped Boolean operand escaped static checking")
            }
          }
        }
      }
    }
    for source in ["true " + op, op + " true"] {
      try @moonjsonnet.Program::parse(source, filename="ordering-entry") catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Syntax)
      } noraise {
        _ => fail("a missing Boolean operand escaped source parsing")
      }
    }
  }
}
