// Shared batch criteria: SPEC-SEQUENCE-STRUCTURE-2026-10-22.md.
// Only neutral ordering_* builders are reused; every new tree is handmade.

///|
fn sequence_limits() -> @moonjsonnet.Limits {
  { ..@moonjsonnet.Limits::default(), steps: 20000, depth: 64, stack: 96, }
}

///|
fn sequence_num(n : Int) -> OrderingExpr {
  ordering_leaf(n.to_string(), Literal(Json::number(n.to_double())))
}

///|
fn sequence_var(name : String) -> OrderingExpr {
  ordering_leaf(name, Var(name))
}

///|
fn sequence_call(name : String, args : Array[OrderingExpr]) -> OrderingExpr {
  {
    source: "std." +
    name +
    "(" +
    args.map(a => "(" + a.source + ")").join(",") +
    ")",
    tree: ordering_ast(
      Call(
        ordering_ast(
          Index(
            ordering_ast(Var("std")),
            ordering_ast(Literal(Json::string(name))),
          ),
        ),
        args.map(a => (None, a.tree)),
        false,
      ),
    ),
  }
}

///|
fn sequence_local(
  bindings : Array[(String, OrderingExpr)],
  body : OrderingExpr,
) -> OrderingExpr {
  {
    source: "local " +
    bindings.map(b => b.0 + "=(" + b.1.source + ")").join(",") +
    ";" +
    body.source,
    tree: ordering_ast(
      Local(
        bindings.map(b => { name: b.0, value: b.1.tree, range: None, }),
        body.tree,
      ),
    ),
  }
}

///|
fn sequence_gate(
  checks : Array[(OrderingExpr, Int)],
  result : OrderingExpr,
) -> OrderingExpr {
  let mut out = result
  let mut i = checks.length()
  while i > 0 {
    i -= 1
    let condition = ordering_binary(
      checks[i].0,
      "==",
      sequence_num(checks[i].1),
    )
    let marker = "sequence-gate-" + i.to_string()
    out = {
      source: "if (" +
      condition.source +
      ") then (" +
      out.source +
      ") else error " +
      Json::string(marker).stringify(),
      tree: ordering_ast(
        If(condition.tree, out.tree, ordering_error(marker).tree),
      ),
    }
  }
  out
}

///|
fn sequence_value(value : OrderingExpr, expected : Json) -> Unit raise {
  for handmade in [false, true] {
    assert_eq(
      ordering_program(value, handmade).evaluate(limits=sequence_limits()),
      expected,
    )
  }
}

///|
fn sequence_failure(
  value : OrderingExpr,
  kind : @moonjsonnet.ErrorKind,
  marker : String?,
) -> Unit raise {
  for handmade in [false, true] {
    assert_eq(
      ordering_program(ordering_unused(value), handmade).evaluate(
        limits=sequence_limits(),
      ),
      42,
    )
    let program = ordering_program(value, handmade)
    try program.evaluate(limits=sequence_limits()) catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, kind)
        if marker is Some(text) {
          assert_eq(d.message, text)
        }
      }
    } noraise {
      _ => fail("required sequence failure was suppressed")
    }
  }
}

///|
test "sequence concatenation preserves all elements and lazy seam payloads" {
  let empty = ordering_array([])
  let left = ordering_array([sequence_num(10), sequence_num(20)])
  let right = ordering_array([sequence_num(30), sequence_num(40)])
  let cases : Array[(OrderingExpr, OrderingExpr, Json)] = [
    (empty, empty, []),
    (empty, left, [10, 20]),
    (left, empty, [10, 20]),
    (left, right, [10, 20, 30, 40]),
  ]
  for (a, b, expected) in cases {
    sequence_value(ordering_binary(a, "+", b), expected)
  }
  sequence_value(sequence_call("length", [empty]), 0)
  let joined = ordering_binary(
    ordering_array([sequence_num(10), ordering_error("left-payload")]),
    "+",
    ordering_array([sequence_num(30), ordering_error("right-payload")]),
  )
  let index = fn(n : Int) -> OrderingExpr {
    {
      source: "c[" + n.to_string() + "]",
      tree: ordering_ast(Index(ordering_ast(Var("c")), sequence_num(n).tree)),
    }
  }
  sequence_value(
    sequence_local(
      [("c", joined)],
      ordering_array([
        sequence_call("type", [sequence_var("c")]),
        sequence_call("length", [sequence_var("c")]),
        index(0),
        index(2),
      ]),
    ),
    ["array", 4, 10, 30],
  )
  sequence_value(
    sequence_call("length", [
      ordering_binary(
        ordering_array([ordering_error("left-payload")]),
        "+",
        ordering_array([ordering_error("right-payload")]),
      ),
    ]),
    2,
  )
}

///|
test "sequence aliases survive deletion before and after warm concatenation" {
  let len = fn(name : String) { sequence_call("length", [sequence_var(name)]) }
  let removed_len = fn(name : String, i : Int) {
    sequence_call("length", [
      sequence_call("removeAt", [sequence_var(name), sequence_num(i)]),
    ])
  }
  let identity = ordering_leaf(
    "function(x)x",
    Func(
      [{ name: "x", default_value: None, range: None, }],
      ordering_ast(Var("x")),
    ),
  )
  let bindings = [
    ("left", ordering_array([sequence_num(10), sequence_num(20)])),
    ("right", ordering_array([sequence_num(30), sequence_num(40)])),
    ("left_alias", sequence_var("left")),
    ("right_alias", sequence_var("right")),
    (
      "joined",
      ordering_binary(sequence_var("left"), "+", sequence_var("right")),
    ),
    ("alias", sequence_var("joined")),
    ("cold", ordering_binary(sequence_var("left"), "+", sequence_var("right"))),
    (
      "twice",
      ordering_binary(sequence_var("joined"), "+", sequence_var("left")),
    ),
    ("mapped", sequence_call("map", [identity, sequence_var("joined")])),
  ]
  let result = ordering_array([
    sequence_var("left_alias"),
    sequence_var("right_alias"),
    sequence_var("joined"),
    sequence_var("alias"),
    sequence_var("cold"),
    sequence_var("twice"),
    sequence_var("mapped"),
  ])
  for removals_first in [false, true] {
    let input_deletions = [
      (removed_len("left", 0), 1),
      (removed_len("right", 1), 1),
    ]
    let warm = [
      (len("joined"), 4),
      (len("alias"), 4),
      (len("twice"), 6),
      (len("mapped"), 4),
    ]
    let checks = (if removals_first {
        input_deletions + warm
      } else {
        warm + input_deletions
      }) +
      [(removed_len("joined", 1), 3)]
    sequence_value(sequence_local(bindings, sequence_gate(checks, result)), [
      [10, 20],
      [30, 40],
      [10, 20, 30, 40],
      [10, 20, 30, 40],
      [10, 20, 30, 40],
      [10, 20, 30, 40, 10, 20],
      [10, 20, 30, 40],
    ])
  }
}

///|
test "sequence length counts String codepoints and requires the evaluated child" {
  let cases : Array[(String, String, Int)] = [
    ("''", "", 0),
    ("'😀'", "😀", 1),
    ("'e\\u0301😀'", "é😀", 3),
  ]
  for (source, value, size) in cases {
    sequence_value(
      sequence_call("length", [
        ordering_leaf(source, Literal(Json::string(value))),
      ]),
      Json::number(size.to_double()),
    )
  }
  let text = ordering_leaf("'e\\u0301😀'", Literal("é😀"))
  sequence_value(
    sequence_call("length", [
      ordering_binary(text, "+", ordering_leaf("'Z'", Literal("Z"))),
    ]),
    4,
  )
  let failed = sequence_call("length", [
    ordering_binary(text, "+", ordering_error("string-required")),
  ])
  sequence_failure(failed, @moonjsonnet.Runtime, Some("string-required"))
  sequence_value(ordering_unused(sequence_call("length", [text])), 42)
}

///|
test "sequence boundaries separate required heads selected payloads and statics" {
  let empty = ordering_array([])
  for
    (left, right, marker) in [
      (ordering_error("left-head"), empty, "left-head"),
      (empty, ordering_error("right-head"), "right-head"),
    ] {
    sequence_failure(
      sequence_call("length", [ordering_binary(left, "+", right)]),
      @moonjsonnet.Runtime,
      Some(marker),
    )
  }
  let joined = ordering_binary(
    ordering_array([sequence_num(10), ordering_error("left-payload")]),
    "+",
    ordering_array([sequence_num(30), ordering_error("right-payload")]),
  )
  for (n, marker) in [(1, "left-payload"), (3, "right-payload")] {
    sequence_failure(
      {
        source: "(" + joined.source + ")[" + n.to_string() + "]",
        tree: ordering_ast(Index(joined.tree, sequence_num(n).tree)),
      },
      @moonjsonnet.Runtime,
      Some(marker),
    )
  }
  for
    value in [
      ordering_binary(empty, "+", sequence_num(0)),
      ordering_binary(sequence_num(0), "+", empty),
      sequence_call("length", [sequence_num(0)]),
    ] {
    sequence_failure(value, @moonjsonnet.Type, None)
  }
  let invalid = ordering_binary(
    ordering_array([sequence_num(10)]),
    "+",
    ordering_array([ordering_leaf("seq_missing", Var("seq_missing"))]),
  )
  for
    value in [
      sequence_call("length", [invalid]),
      {
        source: "(" + invalid.source + ")[0]",
        tree: ordering_ast(Index(invalid.tree, sequence_num(0).tree)),
      },
    ] {
    for handmade in [false, true] {
      try ordering_program(value, handmade) catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
      } noraise {
        _ => fail("an unused sequence tail escaped static checking")
      }
    }
  }
  try @moonjsonnet.Program::parse("[1]+") catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Syntax)
  } noraise {
    _ => fail("a missing concat operand escaped source parsing")
  }
}
