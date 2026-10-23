// Frozen independent criteria: SPEC-FUNCTION-STATIC-2026-10-23.md.
// Source and handmade AST share only literal fixture data, not a parser export.

///|
fn fscope_function(
  parameters : Array[(String, OrderingExpr?)],
  body : OrderingExpr,
) -> OrderingExpr {
  {
    source: "function(" +
    parameters
    .map(p => {
      match p.1 {
        None => p.0
        Some(value) => p.0 + "=(" + value.source + ")"
      }
    })
    .join(",") +
    ")(" +
    body.source +
    ")",
    tree: ordering_ast(
      Func(
        parameters.map(p => {
          name: p.0,
          default_value: p.1.map(value => value.tree),
          range: None,
        }),
        body.tree,
      ),
    ),
  }
}

///|
fn fscope_reject(value : OrderingExpr) -> Unit raise {
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
            "function scope accepted an invalid child (handmade=\{handmade}): " +
            expression.source,
          )
      }
    }
  }
}

///|
fn fscope_admit(value : OrderingExpr) -> Unit raise {
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
test "function statics check each optional default before invocation" {
  for bad_position in 0..<3 {
    let parameters : Array[(String, OrderingExpr?)] = [
      ("required", None),
      ("a", Some(sequence_num(42))),
      ("b", Some(sequence_num(42))),
      ("c", Some(sequence_num(42))),
    ]
    let name = parameters[bad_position + 1].0
    parameters[bad_position + 1] = (name, Some(sequence_var("fscope_missing")))
    fscope_reject(fscope_function(parameters, sequence_num(42)))
  }
}

///|
test "function statics check bodies independently of defaults or calls" {
  fscope_reject(fscope_function([], sequence_var("fscope_missing")))
  fscope_reject(
    fscope_function(
      [("required", None), ("optional", Some(sequence_num(42)))],
      sequence_var("fscope_missing"),
    ),
  )
}

///|
test "function default child binders do not escape to sibling defaults or body" {
  let private_local = sequence_local(
    [("fscope_private", sequence_num(42))],
    sequence_var("fscope_private"),
  )
  let private_function = make_function(
    ["fscope_private"],
    sequence_var("fscope_private"),
  )
  for child in [private_local, private_function] {
    fscope_reject(
      fscope_function(
        [("a", Some(child)), ("b", Some(sequence_var("fscope_private")))],
        sequence_num(42),
      ),
    )
    fscope_reject(
      fscope_function([("a", Some(child))], sequence_var("fscope_private")),
    )
  }
}

///|
test "function statics extend defaults and body with all formals and outer names" {
  fscope_admit(fscope_function([], sequence_num(42)))
  fscope_admit(
    fscope_function(
      [("required", None), ("optional", Some(sequence_var("required")))],
      sequence_var("optional"),
    ),
  )
  fscope_admit(
    fscope_function(
      [("a", Some(sequence_var("b"))), ("b", Some(sequence_var("a")))],
      sequence_var("a"),
    ),
  )
  fscope_admit(
    fscope_function([("a", Some(sequence_var("a")))], sequence_var("a")),
  )
  fscope_admit(
    sequence_local(
      [("outer", ordering_error("outer-not-demanded"))],
      fscope_function(
        [("a", Some(sequence_var("outer")))],
        sequence_var("outer"),
      ),
    ),
  )
  fscope_admit(
    sequence_local(
      [("a", ordering_error("shadowed-not-demanded"))],
      fscope_function([("a", None)], sequence_var("a")),
    ),
  )
}

///|
test "function statics do not create object permission for defaults or body" {
  for name in ["self", "super"] {
    let access = pair_access(name)
    for
      function in [
        fscope_function([("a", Some(access))], sequence_num(42)),
        fscope_function([("a", Some(sequence_num(42)))], access),
      ] {
      fscope_reject(function)
      // An enclosing object's key still uses its outer scope.
      fscope_reject(reflect_object([(function, 1, sequence_num(42))]))
    }
  }
}

///|
test "function statics preserve existing object permission for defaults and body" {
  for name in ["self", "super"] {
    let access = pair_access(name)
    for
      function in [
        fscope_function([("a", Some(access))], sequence_num(42)),
        fscope_function([("a", Some(sequence_num(42)))], access),
      ] {
      let value = if name == "super" {
        pair_inherited(function)
      } else {
        pair_field(function)
      }
      fscope_admit(value)
    }
  }
}

///|
test "function static admission neither evaluates nor typechecks its children" {
  for
    child in [
      ordering_error("function-child-not-demanded"),
      ordering_binary(sequence_num(1), "-", reflect_string("not-a-number")),
    ] {
    fscope_admit(fscope_function([("a", Some(child))], child))
  }
}
