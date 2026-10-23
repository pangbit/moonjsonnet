// Independent criteria: SPEC-EXPRESSION-LISTS-2026-10-23.md.
// These are source grammar controls, not a parser/export round trip.

///|
fn list_shape(tree : @moonjsonnet.Ast) -> Json {
  // Extend only the fixture projection; leave old precedence evidence intact.
  match tree.kind {
    Arr(items) => ["array", Json::array(items.map(list_shape))]
    Func(params, body) =>
      [
        "function",
        Json::array(
          params.map(p => {
            Json::array([
              Json::string(p.name),
              match p.default_value {
                Some(value) => list_shape(value)
                None => Json::null()
              },
            ])
          }),
        ),
        list_shape(body),
      ]
    Call(callee, args, strict) =>
      [
        "call",
        list_shape(callee),
        Json::array(
          args.map(arg => {
            Json::array([
              match arg.0 {
                Some(name) => Json::string(name)
                None => Json::null()
              },
              list_shape(arg.1),
            ])
          }),
        ),
        Json::boolean(strict),
      ]
    Local(bindings, body) =>
      [
        "local",
        Json::array(
          bindings.map(b => {
            Json::array([Json::string(b.name), list_shape(b.value)])
          }),
        ),
        list_shape(body),
      ]
    Index(base, key) => ["index", list_shape(base), list_shape(key)]
    _ => prec_shape(tree)
  }
}

///|
fn list_function(
  params : Array[(String, @moonjsonnet.Ast?)],
  body : @moonjsonnet.Ast,
) -> @moonjsonnet.Ast {
  ordering_ast(
    Func(params.map(p => { name: p.0, default_value: p.1, range: None, }), body),
  )
}

///|
fn list_call(
  callee : @moonjsonnet.Ast,
  args : Array[(String?, @moonjsonnet.Ast)],
) -> @moonjsonnet.Ast {
  ordering_ast(Call(callee, args, false))
}

///|
fn list_syntax_shape(value : OrderingExpr) -> Unit raise {
  let document = @moonjsonnet.SyntaxDocument::parse(
    value.source,
    filename="expression-lists",
  )
  assert_eq(document.text(), value.source)
  assert_eq(
    list_shape(document.ast()),
    list_shape(value.tree),
    msg=value.source,
  )
}

///|
fn list_scope(value : OrderingExpr) -> OrderingExpr {
  sequence_local([("f", ordering_error("list-unused-head"))], value)
}

///|
test "expression lists retain empty trailing comma and adjacent delimiter shapes" {
  let one = prec_n(1)
  let two = prec_n(2)
  let a = prec_v("a")
  let b = prec_v("b")
  let f = prec_v("f")
  let single = ordering_ast(Arr([one]))
  let pair = ordering_ast(Arr([one, two]))
  let function = list_function(
    [("a", None), ("b", Some(two))],
    prec_b("+", a, b),
  )
  let cases : Array[(Array[String], @moonjsonnet.Ast)] = [
    (["[]", "[/**/]"], ordering_ast(Arr([]))),
    (["[1]", "[1,]", "[1/**/,// trailing\n]"], single),
    (["[1,2]", "[1,2,]", "[1/**/,/**/2/**/,/**/]"], pair),
    (["[[1,],[2,],]"], ordering_ast(Arr([single, ordering_ast(Arr([two]))]))),
    (
      ["function()42", "function/**/(/**/)/**/42"],
      list_function([], prec_n(42)),
    ),
    (["function(a)a", "function(a,)a"], list_function([("a", None)], a)),
    (["function(a,b=2)a+b", "function(a,b=2,)a+b"], function),
    (["function(a=1,b,)b"], list_function([("a", Some(one)), ("b", None)], b)),
    (["f()", "f/**/(/**/)"], list_call(f, [])),
    (["f(1)", "f(1,)"], list_call(f, [(None, one)])),
    (["f(a=1)", "f(a=1,)"], list_call(f, [(Some("a"), one)])),
    (
      ["f(1,b=2)", "f(1,/**/b/**/=/**/2,/**/)"],
      list_call(f, [(None, one), (Some("b"), two)]),
    ),
    (["f(b=2,a=1,)"], list_call(f, [(Some("b"), two), (Some("a"), one)])),
    (["f([1,2,],)"], list_call(f, [(None, pair)])),
    (
      ["(function(a,)a)(42,)"],
      list_call(list_function([("a", None)], a), [(None, prec_n(42))]),
    ),
    (
      ["local x=1;x"],
      sequence_local([("x", token_number("1"))], sequence_var("x")).tree,
    ),
    (
      ["local x=1,y=2;x+y", "local/**/x/**/=/**/1/**/,/**/y=2/**/;/**/x+y"],
      sequence_local(
        [("x", token_number("1")), ("y", token_number("2"))],
        ordering_binary(sequence_var("x"), "+", sequence_var("y")),
      ).tree,
    ),
    (
      ["local f(a,b=2,)=a+b;f(1,b=2,)"],
      sequence_local([("f", { source: "", tree: function, })], {
        source: "",
        tree: list_call(f, [(None, one), (Some("b"), two)]),
      }).tree,
    ),
  ]
  for (spellings, tree) in cases {
    for source in spellings {
      let value : OrderingExpr = { source, tree, }
      list_syntax_shape(value)
      sequence_value(ordering_unused(list_scope(value)), 42)
    }
  }
}

///|
test "malformed expression lists reject before any lazy branch can hide them" {
  let malformed = [
    "[,]", "[1,,]", "[1,,2]", "[1 2]", "[1;2]", "[1)", "[1,", "[1,/* closed */",
    "function(,)42", "function(a,,b)42", "function(a b)42", "function(a=)42", "function(a;b)42",
    "function(a]42", "function(a,)", "function a 42", "f(,)", "f(1,,)", "f(1 2)",
    "f(a=)", "f(1;2)", "f(1]", "f(1,", "f(1)2", "local ;42", "local ,x=1;42", "local x=1,;42",
    "local x=1,,y=2;42", "local x=1 y=2;42", "local x=;42", "local x=1;", "local x=1:42",
  ]
  for source in malformed {
    for
      wrapped in [
        source,
        "local unused=(" + source + ");42",
        "if false then (" + source + ") else 42",
      ] {
      try
        @moonjsonnet.SyntaxDocument::parse(wrapped, filename="expression-lists")
      catch {
        @moonjsonnet.Error(d) => {
          assert_eq(d.kind, @moonjsonnet.Syntax, msg=wrapped)
          assert_eq(d.location.file, "expression-lists")
        }
      } noraise {
        _ => fail("malformed source list admitted as syntax: " + wrapped)
      }
      try
        @moonjsonnet.Program::parse(wrapped, filename="expression-lists")
      catch {
        @moonjsonnet.Error(d) => {
          assert_eq(d.kind, @moonjsonnet.Syntax, msg=wrapped)
          assert_eq(d.location.file, "expression-lists")
        }
      } noraise {
        _ => fail("malformed source list admitted as a Program: " + wrapped)
      }
    }
  }
}

///|
test "valid expression list syntax keeps static rejection separate from deferred demand" {
  let missing = prec_v("missing")
  for
    value in [
      { source: "[missing,]", tree: ordering_ast(Arr([missing])), },
      {
        source: "function(a=missing,)42",
        tree: list_function([("a", Some(missing))], prec_n(42)),
      },
      {
        source: "f(missing,)",
        tree: list_call(prec_v("f"), [(None, missing)]),
      },
      {
        source: "local x=missing,y=42;y",
        tree: sequence_local(
          [("x", sequence_var("missing")), ("y", token_number("42"))],
          sequence_var("y"),
        ).tree,
      },
    ] {
    list_syntax_shape(value)
    for expression in [list_scope(value), ordering_unused(list_scope(value))] {
      for handmade in [false, true] {
        try ordering_program(expression, handmade) catch {
          @moonjsonnet.Error(d) => {
            assert_eq(d.kind, @moonjsonnet.Static)
            assert_eq(d.message, "Unknown variable: missing")
            assert_eq(d.location.file, "ordering-entry")
          }
        } noraise {
          _ => fail("valid list syntax hid an unknown child name")
        }
      }
    }
  }
  let default = ordering_error("list-default")
  let supplied = ordering_error("list-supplied")
  let params = [("a", None), ("b", Some(default.tree))]
  let choose_a = list_function(params, prec_v("a"))
  let choose_b = list_function(params, prec_v("b"))
  let required = [(None, prec_n(42))]
  let explicit = [(None, prec_n(42)), (Some("b"), supplied.tree)]
  let local_value = sequence_local(
    [("x", ordering_error("list-local")), ("y", token_number("42"))],
    sequence_var("y"),
  )
  for
    value in [
      {
        source: "[42,error 'list-unread',][0]",
        tree: ordering_ast(
          Index(
            ordering_ast(Arr([prec_n(42), ordering_error("list-unread").tree])),
            prec_n(0),
          ),
        ),
      },
      {
        source: "(function(a,b=error 'list-default',)a)(42,)",
        tree: list_call(choose_a, required),
      },
      {
        source: "(function(a,b=error 'list-default',)a)(42,b=error 'list-supplied',)",
        tree: list_call(choose_a, explicit),
      },
      { source: "local x=error 'list-local',y=42;y", tree: local_value.tree, },
    ] {
    list_syntax_shape(value)
    sequence_value(value, 42)
    sequence_value(ordering_unused(value), 42)
  }
  for
    (source, tree, kind, marker) in [
      (
        "(function(a,b=error 'list-default',)b)(42,)",
        list_call(choose_b, required),
        @moonjsonnet.Runtime,
        Some("list-default"),
      ),
      (
        "(function(a,b=error 'list-default',)b)(42,b=error 'list-supplied',)",
        list_call(choose_b, explicit),
        @moonjsonnet.Runtime,
        Some("list-supplied"),
      ),
      (
        "local x=error 'list-local',y=42;x",
        sequence_local(
          [("x", ordering_error("list-local")), ("y", token_number("42"))],
          sequence_var("x"),
        ).tree,
        @moonjsonnet.Runtime,
        Some("list-local"),
      ),
      (
        "42(1,)",
        list_call(prec_n(42), [(None, prec_n(1))]),
        @moonjsonnet.Type,
        None,
      ),
    ] {
    let value : OrderingExpr = { source, tree, }
    list_syntax_shape(value)
    sequence_failure(value, kind, marker)
  }
}
