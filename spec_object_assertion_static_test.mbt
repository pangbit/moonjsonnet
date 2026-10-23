// Independent pre-execution criteria: SPEC-OBJECT-ASSERTION-STATIC-2026-10-23.md.
// Handmade ASTs are constructed directly, without parsing/exporting source.

///|
fn ostatic_object(
  locals : Array[(String, OrderingExpr)],
  checks : Array[(OrderingExpr, OrderingExpr?)],
  fields? : Array[(OrderingExpr, OrderingExpr)] = [],
) -> OrderingExpr {
  let members : Array[String] = []
  // Put assertions before locals to check whole-object scope in source too.
  for (condition, message) in checks {
    let suffix = match message {
      None => ""
      Some(value) => ":(" + value.source + ")"
    }
    members.push("assert (" + condition.source + ")" + suffix)
  }
  for (name, value) in locals {
    members.push("local " + name + "=(" + value.source + ")")
  }
  for (key, value) in fields {
    members.push("[(" + key.source + ")]:(" + value.source + ")")
  }
  {
    source: "{" + members.join(",") + "}",
    tree: ordering_ast(
      Obj(
        fields.map(pair => {
          key: pair.0.tree,
          value: pair.1.tree,
          visibility: 1,
          additive: false,
        }),
        locals.map(pair => { name: pair.0, value: pair.1.tree, range: None, }),
        checks.map(pair => (pair.0.tree, pair.1.map(value => value.tree))),
      ),
    ),
  }
}

///|
fn ostatic_assert(
  condition : OrderingExpr,
  message : OrderingExpr?,
  body : OrderingExpr,
) -> OrderingExpr {
  let suffix = match message {
    None => ""
    Some(value) => ":(" + value.source + ")"
  }
  {
    source: "assert (" +
    condition.source +
    ")" +
    suffix +
    ";(" +
    body.source +
    ")",
    tree: ordering_ast(
      Assert(condition.tree, message.map(value => value.tree), body.tree),
    ),
  }
}

///|
fn ostatic_reject(value : OrderingExpr) -> Unit raise {
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
        _ =>
          fail(
            "object assertion scope accepted an invalid child " +
            "(handmade=\{handmade}): " +
            expression.source,
          )
      }
    }
  }
}

///|
fn ostatic_admit(value : OrderingExpr) -> Unit raise {
  for handmade in [false, true] {
    ignore(ordering_program(value, handmade))
    assert_eq(
      ordering_program(ordering_unused(value), handmade).evaluate(
        limits=sequence_limits(),
      ),
      42,
    )
  }
}

///|
test "object statics check every assertion condition before demand" {
  let truth = ordering_leaf("true", Literal(true))
  for bad_position in 0..<3 {
    let checks : Array[(OrderingExpr, OrderingExpr?)] = [
      (truth, None),
      (truth, None),
      (truth, None),
    ]
    checks[bad_position] = (sequence_var("ostatic_missing"), None)
    ostatic_reject(ostatic_object([], checks))
  }
}

///|
test "object statics check every message even when all conditions are true" {
  let truth = ordering_leaf("true", Literal(true))
  let message = Some(reflect_string("not-demanded"))
  for bad_position in 0..<3 {
    let checks : Array[(OrderingExpr, OrderingExpr?)] = [
      (truth, message),
      (truth, message),
      (truth, message),
    ]
    checks[bad_position] = (truth, Some(sequence_var("ostatic_missing")))
    ostatic_reject(ostatic_object([], checks))
  }
}

///|
test "object assertion statics check unused locals and distinguish field labels" {
  let truth = ordering_leaf("true", Literal(true))
  ostatic_reject(
    ostatic_object([("unused", sequence_var("ostatic_missing"))], [
      (truth, None),
    ]),
  )
  let fields = [(reflect_string("ostatic_field"), sequence_num(42))]
  ostatic_reject(
    ostatic_object([], [(sequence_var("ostatic_field"), None)], fields~),
  )
  ostatic_reject(
    ostatic_object([], [(truth, Some(sequence_var("ostatic_field")))], fields~),
  )
}

///|
test "object assertion child binders do not escape to messages or other pairs" {
  let truth = ordering_leaf("true", Literal(true))
  let private_condition = sequence_local([("ostatic_private", truth)], truth)
  let private_message = sequence_local(
    [("ostatic_private", reflect_string("not-demanded"))],
    reflect_string("not-demanded"),
  )
  let leaked = sequence_var("ostatic_private")
  for
    checks in [
      [(private_condition, Some(leaked))],
      [(private_condition, None), (leaked, None)],
      [(truth, Some(private_message)), (truth, Some(leaked))],
    ] {
    ostatic_reject(ostatic_object([], checks))
  }
}

///|
test "object key assertions cannot acquire new self super or object locals" {
  let truth = ordering_leaf("true", Literal(true))
  let name = reflect_string("key")
  for context in ["self", "super"] {
    let access = pair_access(context)
    for
      key in [
        ostatic_assert(access, None, name),
        ostatic_assert(truth, Some(access), name),
      ] {
      ostatic_reject(ostatic_object([], [], fields=[(key, sequence_num(42))]))
    }
  }
  let key = ostatic_assert(truth, Some(sequence_var("ostatic_key")), name)
  ostatic_reject(
    ostatic_object([("ostatic_key", name)], [], fields=[(key, sequence_num(42))]),
  )
}

///|
test "object assertion statics see later recursive locals and self super scope" {
  for context in ["self", "super"] {
    let access = pair_access(context)
    let object = ostatic_object(
      [
        ("first", sequence_var("later")),
        ("later", access),
        ("unused", ordering_error("unused-object-local")),
      ],
      [
        (
          ordering_binary(sequence_var("first"), "==", sequence_var("first")),
          Some(sequence_var("later")),
        ),
      ],
      fields=[(reflect_string("n"), sequence_num(42))],
    )
    ostatic_admit(object)
    ostatic_admit(
      ordering_binary(
        reflect_object([(reflect_string("n"), 1, sequence_num(42))]),
        "+",
        object,
      ),
    )
  }
}

///|
test "object static admission defers assertion types errors and false results" {
  for
    condition in [
      sequence_num(1),
      ordering_error("condition-not-demanded"),
      ordering_leaf("false", Literal(false)),
    ] {
    ostatic_admit(
      ostatic_object([], [
        (condition, Some(ordering_error("message-not-demanded"))),
      ]),
    )
  }
}
