// Independent criteria: SPEC-ASSERTION-CONJUNCTION-REVIEW.md. ASTs are handmade
// with existing neutral helpers. Observer maps compare membership, never order.

///|
fn conjunction_limits() -> @moonjsonnet.Limits {
  { ..@moonjsonnet.Limits::default(), steps: 5000, depth: 48, stack: 64, }
}

///|
fn conjunction_check(
  id : String,
  predicate : @moonjsonnet.Ast,
  context : @moonjsonnet.Ast,
  error_message? : Bool = false,
) -> (@moonjsonnet.Ast, @moonjsonnet.Ast?) {
  (
    assertion_self_ast(
      If(
        assertion_self_native("seen", [
          assertion_self_ast(Literal(Json::string(id))),
          context,
        ]),
        predicate,
        assertion_self_ast(Literal(false)),
      ),
    ),
    Some(
      if error_message {
        assertion_self_ast(
          Fail(assertion_self_ast(Literal("unused-conjunction-message"))),
        )
      } else {
        assertion_self_native("message", [
          assertion_self_ast(Literal(Json::string(id))),
        ])
      },
    ),
  )
}

///|
fn conjunction_source_check(
  id : String,
  predicate : String,
  context : String,
  error_message? : Bool = false,
) -> String {
  "assert (if std.native('seen')('" +
  id +
  "'," +
  context +
  ") then (" +
  predicate +
  ") else false):" +
  (if error_message {
    "error 'unused-conjunction-message'"
  } else {
    "std.native('message')('" + id + "')"
  })
}

///|
fn conjunction_tree(
  bad : Array[String],
  body : @moonjsonnet.Ast,
) -> @moonjsonnet.Ast {
  let left = assertion_self_object(
    [
      (
        "value",
        assertion_self_ast(
          Fail(assertion_self_ast(Literal("overridden-left-value"))),
        ),
      ),
    ],
    checks=["L0", "L1"].map(id => {
      conjunction_check(
        id,
        assertion_self_ast(Literal(Json::boolean(!bad.contains(id)))),
        assertion_self_ast(Literal(0)),
      )
    }),
  )
  let right = assertion_self_object(
    [
      (
        "value",
        assertion_self_native("payload", [assertion_self_ast(Literal(42))]),
      ),
    ],
    checks=["R0", "R1"].map(id => {
      conjunction_check(
        id,
        assertion_self_ast(Literal(Json::boolean(!bad.contains(id)))),
        assertion_self_ast(Literal(0)),
      )
    }),
  )
  assertion_self_local(
    [
      ("left", left),
      ("right", right),
      (
        "merged",
        assertion_self_ast(
          Binary("+", assertion_self_var("left"), assertion_self_var("right")),
        ),
      ),
    ],
    body,
  )
}

///|
fn conjunction_source(bad : Array[String]) -> String {
  let predicate = (id : String) => {
    if bad.contains(id) {
      "false"
    } else {
      "true"
    }
  }
  "local left={" +
  ["L0", "L1"]
  .map(id => conjunction_source_check(id, predicate(id), "0"))
  .join(",") +
  ",value:error 'overridden-left-value'},right={" +
  ["R0", "R1"]
  .map(id => conjunction_source_check(id, predicate(id), "0"))
  .join(",") +
  ",value:std.native('payload')(42)},merged=left+right;"
}

///|
fn conjunction_natives(
  seen : Map[String, Bool],
  messages : Map[String, Bool],
  payloads : Ref[Int],
) -> Map[String, @moonjsonnet.NativeFunction] {
  Map([
    (
      "seen",
      {
        params: ["id", "context"],
        callback: args => {
          guard args[0] is String(id) else {
            abort("observer ID must be a string")
          }
          seen[id + "@" + args[1].stringify()] = true
          true
        },
      },
    ),
    (
      "message",
      {
        params: ["id"],
        callback: args => {
          guard args[0] is String(id) else {
            abort("message ID must be a string")
          }
          messages[id] = true
          args[0]
        },
      },
    ),
    (
      "payload",
      {
        params: ["value"],
        callback: args => {
          payloads.val += 1
          args[0]
        },
      },
    ),
  ])
}

///|
test "both operand assertion lists survive overrides without imposing check order" {
  let cases : Array[Array[String]] = [
    [],
    ["L0"],
    ["L1"],
    ["R0"],
    ["R1"],
    ["L0", "R1"],
  ]
  for bad in cases {
    let modes = if bad.length() == 2 {
      ["metadata", "unused", "forced"]
    } else {
      ["forced"]
    }
    for mode in modes {
      let type_of_merged = assertion_self_ast(
        Call(
          assertion_self_index("std", "type"),
          [(None, assertion_self_var("merged"))],
          false,
        ),
      )
      let suffix = match mode {
        "metadata" => "std.type(merged)"
        "unused" => "(local unused=merged.value;42)"
        _ => "merged.value"
      }
      let body = match mode {
        "metadata" => type_of_merged
        "unused" =>
          assertion_self_local(
            [("unused", assertion_self_index("merged", "value"))],
            assertion_self_ast(Literal(42)),
          )
        _ => assertion_self_index("merged", "value")
      }
      let source = conjunction_source(bad) +
        "if std.type(merged)=='object' then " +
        suffix +
        " else null"
      let tree = conjunction_tree(
        bad,
        assertion_self_ast(
          If(
            assertion_self_ast(
              Binary(
                "==",
                type_of_merged,
                assertion_self_ast(Literal("object")),
              ),
            ),
            body,
            assertion_self_ast(Literal(null)),
          ),
        ),
      )
      for handmade in [false, true] {
        let seen : Map[String, Bool] = Map([])
        let messages : Map[String, Bool] = Map([])
        let payloads = Ref(0)
        let program = assertion_self_program(source, tree, handmade)
        let natives = conjunction_natives(seen, messages, payloads)
        assert_eq(seen.length(), 0)
        if mode != "forced" {
          let expected : Json = if mode == "metadata" { "object" } else { 42 }
          assert_eq(
            program.evaluate(
              native_functions=natives,
              limits=conjunction_limits(),
            ),
            expected,
          )
          assert_eq(seen.length(), 0)
          assert_eq(messages.length(), 0)
          assert_eq(payloads.val, 0)
        } else if bad.is_empty() {
          assert_eq(
            program.evaluate(
              native_functions=natives,
              limits=conjunction_limits(),
            ),
            42,
          )
          for id in ["L0@0", "L1@0", "R0@0", "R1@0"] {
            assert_true(seen.contains(id))
          }
          assert_eq(seen.length(), 4)
          assert_eq(messages.length(), 0)
          assert_true(payloads.val > 0)
        } else {
          try
            program.evaluate(
              native_functions=natives,
              limits=conjunction_limits(),
            )
          catch {
            @moonjsonnet.Error(d) => {
              assert_eq(d.kind, @moonjsonnet.Assertion)
              assert_eq(d.location.file, "assertion-self-entry")
              assert_true(bad.contains(d.message))
              assert_true(messages.contains(d.message))
            }
          } noraise {
            _ => fail("a retained operand assertion was lost")
          }
          assert_eq(payloads.val, 0)
        }
      }
    }
  }
}

///|
test "finite assertion reentry retains all checks and rebinds a checked original" {
  let source = "local left={seed:1,goal:3,next:self.seed+1,done:self.next+1," +
    conjunction_source_check(
      "L0",
      "self.done==self.goal",
      "self.goal",
      error_message=true,
    ) +
    "," +
    conjunction_source_check(
      "L1",
      "self.next+1==self.goal",
      "self.goal",
      error_message=true,
    ) +
    ",value:std.native('payload')(self.done)},right={seed:10,goal:12," +
    conjunction_source_check(
      "R0",
      "self.seed+2==self.goal",
      "self.goal",
      error_message=true,
    ) +
    "," +
    conjunction_source_check(
      "R1",
      "self.done-self.seed==2",
      "self.goal",
      error_message=true,
    ) +
    ",value:std.native('payload')(self.done)},merged=left+right;" +
    "if left.value==3 then merged.value else null"
  let goal = assertion_self_index("self", "goal")
  let done = assertion_self_index("self", "done")
  let seed = assertion_self_index("self", "seed")
  let next = assertion_self_index("self", "next")
  let value = assertion_self_native("payload", [done])
  let left = assertion_self_object(
    [
      ("seed", assertion_self_ast(Literal(1))),
      ("goal", assertion_self_ast(Literal(3))),
      (
        "next",
        assertion_self_ast(Binary("+", seed, assertion_self_ast(Literal(1)))),
      ),
      (
        "done",
        assertion_self_ast(Binary("+", next, assertion_self_ast(Literal(1)))),
      ),
      ("value", value),
    ],
    checks=[
      conjunction_check(
        "L0",
        assertion_self_ast(Binary("==", done, goal)),
        goal,
        error_message=true,
      ),
      conjunction_check(
        "L1",
        assertion_self_ast(
          Binary(
            "==",
            assertion_self_ast(
              Binary("+", next, assertion_self_ast(Literal(1))),
            ),
            goal,
          ),
        ),
        goal,
        error_message=true,
      ),
    ],
  )
  let right = assertion_self_object(
    [
      ("seed", assertion_self_ast(Literal(10))),
      ("goal", assertion_self_ast(Literal(12))),
      ("value", value),
    ],
    checks=[
      conjunction_check(
        "R0",
        assertion_self_ast(
          Binary(
            "==",
            assertion_self_ast(
              Binary("+", seed, assertion_self_ast(Literal(2))),
            ),
            goal,
          ),
        ),
        goal,
        error_message=true,
      ),
      conjunction_check(
        "R1",
        assertion_self_ast(
          Binary(
            "==",
            assertion_self_ast(Binary("-", done, seed)),
            assertion_self_ast(Literal(2)),
          ),
        ),
        goal,
        error_message=true,
      ),
    ],
  )
  let tree = assertion_self_local(
    [
      ("left", left),
      ("right", right),
      (
        "merged",
        assertion_self_ast(
          Binary("+", assertion_self_var("left"), assertion_self_var("right")),
        ),
      ),
    ],
    assertion_self_ast(
      If(
        assertion_self_ast(
          Binary(
            "==",
            assertion_self_index("left", "value"),
            assertion_self_ast(Literal(3)),
          ),
        ),
        assertion_self_index("merged", "value"),
        assertion_self_ast(Literal(null)),
      ),
    ),
  )
  for handmade in [false, true] {
    let seen : Map[String, Bool] = Map([])
    let messages : Map[String, Bool] = Map([])
    let payloads = Ref(0)
    let program = assertion_self_program(source, tree, handmade)
    assert_eq(
      program.evaluate(
        native_functions=conjunction_natives(seen, messages, payloads),
        limits=conjunction_limits(),
      ),
      12,
    )
    for key in ["L0@3", "L1@3", "L0@12", "L1@12", "R0@12", "R1@12"] {
      assert_true(seen.contains(key))
    }
    assert_eq(seen.length(), 6)
    assert_eq(messages.length(), 0)
    assert_true(payloads.val > 0)
  }
}
