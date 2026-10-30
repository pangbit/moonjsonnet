// Fixed independent criteria: SPEC-ASSERTION-LOCAL-REVIEW.md. Existing neutral
// AST helpers are reused; new trees are handmade, without parser export.

///|
fn assertion_local_call(target : @moonjsonnet.Ast) -> @moonjsonnet.Ast {
  assertion_self_ast(Call(target, [], false))
}

///|
fn assertion_local_sample() -> @moonjsonnet.Ast {
  assertion_local_call(
    assertion_self_ast(
      Index(
        assertion_local_call(assertion_self_var("helper")),
        assertion_self_ast(Literal("read")),
      ),
    ),
  )
}

///|
fn assertion_local_tree(
  body : @moonjsonnet.Ast,
  bad_expected~ : Bool = false,
  local_error~ : Bool = false,
) -> @moonjsonnet.Ast {
  let helper = if local_error {
    assertion_self_ast(
      If(
        assertion_self_native("localInit", []),
        assertion_self_ast(
          Fail(assertion_self_ast(Literal("object-local-init-marker"))),
        ),
        assertion_self_ast(Literal(null)),
      ),
    )
  } else {
    assertion_self_ast(
      Func(
        [],
        assertion_self_object([
          ("tag", assertion_self_ast(Literal(30))),
          (
            "read",
            assertion_self_ast(
              Func(
                [],
                assertion_self_ast(
                  Arr([
                    assertion_self_index("receiver", "tag"),
                    assertion_self_index("self", "tag"),
                    assertion_self_index("$", "tag"),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    )
  }
  let condition = assertion_self_local(
    [("sample", assertion_local_sample())],
    assertion_self_ast(
      If(
        assertion_self_native("note", [
          assertion_self_ast(Literal("condition")),
          assertion_self_var("sample"),
        ]),
        assertion_self_ast(
          Binary(
            "==",
            assertion_self_var("sample"),
            assertion_self_index("self", "expected"),
          ),
        ),
        assertion_self_ast(Literal(false)),
      ),
    ),
  )
  let child = assertion_self_object([
    ("tag", assertion_self_ast(Literal(2))),
    (
      "expected",
      assertion_self_ast(
        Arr([
          assertion_self_ast(Literal(2)),
          assertion_self_ast(Literal(30)),
          assertion_self_ast(Literal(10)),
        ]),
      ),
    ),
    ("value", assertion_self_native("payload", [assertion_local_sample()])),
  ])
  guard child.kind is Obj(fields, _, _) else { abort("neutral object builder") }
  let child = assertion_self_ast(
    Obj(
      fields,
      [
        { name: "receiver", value: assertion_self_var("self"), range: None, },
        { name: "helper", value: helper, range: None, },
        {
          name: "unused",
          value: assertion_self_ast(
            Fail(assertion_self_ast(Literal("unused-local-marker"))),
          ),
          range: None,
        },
      ],
      [
        (
          condition,
          Some(assertion_self_native("message", [assertion_local_sample()])),
        ),
      ],
    ),
  )
  assertion_self_local(
    [
      (
        "helper",
        assertion_self_ast(
          Fail(assertion_self_ast(Literal("outer-helper-marker"))),
        ),
      ),
      (
        "receiver",
        assertion_self_object([("tag", assertion_self_ast(Literal(99)))]),
      ),
      (
        "root",
        assertion_self_object([
          ("tag", assertion_self_ast(Literal(10))),
          ("child", child),
        ]),
      ),
      (
        "derived",
        assertion_self_ast(
          Binary(
            "+",
            assertion_self_var("root"),
            assertion_self_object([("tag", assertion_self_ast(Literal(20)))]),
          ),
        ),
      ),
      (
        "picked",
        assertion_self_ast(
          Binary(
            "+",
            assertion_self_index("derived", "child"),
            assertion_self_object([
              ("tag", assertion_self_ast(Literal(3))),
              (
                "expected",
                assertion_self_ast(
                  Arr([
                    assertion_self_ast(
                      Literal(if bad_expected { 99 } else { 3 }),
                    ),
                    assertion_self_ast(Literal(30)),
                    assertion_self_ast(Literal(20)),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    ],
    body,
  )
}

///|
fn assertion_local_source(
  bad_expected~ : Bool = false,
  local_error~ : Bool = false,
) -> String {
  "local helper=error 'outer-helper-marker',receiver={tag:99}," +
  "root={tag:10,child:{tag:2,expected:[2,30,10],local receiver=self,local helper=" +
  (if local_error {
    "if std.native('localInit')() then error 'object-local-init-marker' else null"
  } else {
    "function(){tag:30,read:function()[receiver.tag,self.tag,$.tag]}"
  }) +
  ",local unused=error 'unused-local-marker'," +
  "assert (local sample=helper().read();if std.native('note')('condition',sample) then sample==self.expected else false):" +
  "std.native('message')(helper().read()),value:std.native('payload')(helper().read())}}," +
  "derived=root+{tag:20},picked=derived.child+{tag:3,expected:[" +
  (if bad_expected { "99" } else { "3" }) +
  ",30,20]};"
}

///|
fn assertion_local_natives(
  events : Array[Json],
) -> Map[String, @moonjsonnet.NativeFunction] {
  Map([
    (
      "note",
      {
        params: ["phase", "value"],
        callback: args => {
          events.push(Json::array(args.copy()))
          true
        },
      },
    ),
    (
      "message",
      {
        params: ["value"],
        callback: args => {
          events.push(Json::array([Json::string("message"), args[0]]))
          "object-local-message-marker"
        },
      },
    ),
    (
      "payload",
      {
        params: ["value"],
        callback: args => {
          events.push(Json::array([Json::string("payload"), args[0]]))
          args[0]
        },
      },
    ),
    (
      "localInit",
      {
        params: [],
        callback: _ => {
          events.push(Json::array([Json::string("local-init")]))
          true
        },
      },
    ),
  ])
}

///|
test "assertion object locals retain receiver and nested capture after inheritance" {
  let source = assertion_local_source() + "[root.child.value,picked.value]"
  let root_child = assertion_self_ast(
    Index(
      assertion_self_index("root", "child"),
      assertion_self_ast(Literal("value")),
    ),
  )
  let tree = assertion_local_tree(
    assertion_self_ast(
      Arr([root_child, assertion_self_index("picked", "value")]),
    ),
  )
  for handmade in [false, true] {
    let events : Array[Json] = []
    let program = assertion_self_program(source, tree, handmade)
    assert_eq(events, [])
    assert_eq(
      program.evaluate(native_functions=assertion_local_natives(events)),
      [[2, 30, 10], [3, 30, 20]],
    )
    assert_eq(events, [
      ["condition", [2, 30, 10]],
      ["payload", [2, 30, 10]],
      ["condition", [3, 30, 20]],
      ["payload", [3, 30, 20]],
    ])
  }
}

///|
test "assertion local messages and initializer errors wait for actual field demand" {
  for local_error in [false, true] {
    for mode in ["metadata", "unused", "forced"] {
      let type_of_picked = assertion_self_ast(
        Call(
          assertion_self_index("std", "type"),
          [(None, assertion_self_var("picked"))],
          false,
        ),
      )
      let suffix = match mode {
        "metadata" => "std.type(picked)"
        "unused" => "(local unused=picked.value;42)"
        _ => "picked.value"
      }
      let body = match mode {
        "metadata" => type_of_picked
        "unused" =>
          assertion_self_local(
            [("unused", assertion_self_index("picked", "value"))],
            assertion_self_ast(Literal(42)),
          )
        _ => assertion_self_index("picked", "value")
      }
      let source = assertion_local_source(bad_expected=true, local_error~) +
        "if std.type(picked)=='object' then " +
        suffix +
        " else null"
      let tree = assertion_local_tree(
        assertion_self_ast(
          If(
            assertion_self_ast(
              Binary(
                "==",
                type_of_picked,
                assertion_self_ast(Literal("object")),
              ),
            ),
            body,
            assertion_self_ast(Literal(null)),
          ),
        ),
        bad_expected=true,
        local_error~,
      )
      for handmade in [false, true] {
        let events : Array[Json] = []
        let program = assertion_self_program(source, tree, handmade)
        assert_eq(events, [])
        if mode == "forced" {
          try
            program.evaluate(native_functions=assertion_local_natives(events))
          catch {
            @moonjsonnet.Error(d) => {
              assert_eq(
                d.kind,
                if local_error {
                  @moonjsonnet.Runtime
                } else {
                  @moonjsonnet.Assertion
                },
              )
              assert_eq(d.location.file, "assertion-self-entry")
              assert_eq(
                d.message,
                if local_error {
                  "object-local-init-marker"
                } else {
                  "object-local-message-marker"
                },
              )
            }
          } noraise {
            _ => fail("demanded assertion local failure was suppressed")
          }
          let expected_events : Array[Json] = if local_error {
            [["local-init"]]
          } else {
            [["condition", [3, 30, 20]], ["message", [3, 30, 20]]]
          }
          assert_eq(events, expected_events)
        } else {
          let expected : Json = if mode == "metadata" { "object" } else { 42 }
          assert_eq(
            program.evaluate(native_functions=assertion_local_natives(events)),
            expected,
          )
          assert_eq(events, [])
        }
      }
    }
  }
}
