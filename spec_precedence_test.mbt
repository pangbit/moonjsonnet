// Fixed table/oracle: SPEC-PRECEDENCE-2026-10-22.md.
// The table below is transcribed from the pinned specification, not queried
// from the private parser. Handmade trees never use parser-exported children.

///|
fn prec_v(name : String) -> @moonjsonnet.Ast {
  ordering_ast(Var(name))
}

///|
fn prec_n(value : Int) -> @moonjsonnet.Ast {
  ordering_ast(NumberLiteral(value.to_string()))
}

///|
fn prec_b(
  symbol : String,
  left : @moonjsonnet.Ast,
  right : @moonjsonnet.Ast,
) -> @moonjsonnet.Ast {
  ordering_ast(Binary(symbol, left, right))
}

///|
fn prec_u(symbol : String, child : @moonjsonnet.Ast) -> @moonjsonnet.Ast {
  ordering_ast(Unary(symbol, child))
}

///|
fn prec_levels() -> Array[Array[String]] {
  [
    ["*", "/", "%"],
    ["+", "-"],
    ["<<", ">>"],
    ["<", ">", "<=", ">=", "in"],
    ["==", "!="],
    ["&"],
    ["^"],
    ["|"],
    ["&&"],
    ["||"],
  ]
}

///|
fn prec_optional(tree : @moonjsonnet.Ast?) -> Json {
  match tree {
    Some(value) => prec_shape(value)
    None => Json::null()
  }
}

///|
fn prec_shape(tree : @moonjsonnet.Ast) -> Json {
  // Discard only source ranges/locations. Symbols, raw numbers, child order,
  // binder/default scopes, named arguments and strictness remain observable.
  match tree.kind {
    NumberLiteral(raw) => ["number", Json::string(raw)]
    Literal(value) => ["literal", value]
    Var(name) => ["var", Json::string(name)]
    Unary(symbol, child) => ["unary", Json::string(symbol), prec_shape(child)]
    Binary(symbol, left, right) =>
      ["binary", Json::string(symbol), prec_shape(left), prec_shape(right)]
    Index(base, key) => ["index", prec_shape(base), prec_shape(key)]
    Slice(base, start, end, step) =>
      [
        "slice",
        prec_shape(base),
        prec_optional(start),
        prec_optional(end),
        prec_optional(step),
      ]
    Call(callee, args, strict) =>
      [
        "call",
        prec_shape(callee),
        Json::array(
          args.map(a => {
            Json::array([
              match a.0 {
                Some(name) => Json::string(name)
                None => Json::null()
              },
              prec_shape(a.1),
            ])
          }),
        ),
        Json::boolean(strict),
      ]
    Func(params, body) =>
      [
        "function",
        Json::array(
          params.map(p => {
            Json::array([Json::string(p.name), prec_optional(p.default_value)])
          }),
        ),
        prec_shape(body),
      ]
    Local(bindings, body) =>
      [
        "local",
        Json::array(
          bindings.map(b => {
            Json::array([Json::string(b.name), prec_shape(b.value)])
          }),
        ),
        prec_shape(body),
      ]
    If(condition, yes, no) =>
      ["if", prec_shape(condition), prec_shape(yes), prec_shape(no)]
    Assert(condition, message, body) =>
      [
        "assert",
        prec_shape(condition),
        prec_optional(message),
        prec_shape(body),
      ]
    Fail(message) => ["error", prec_shape(message)]
    ImportFile(path, text) =>
      ["import", Json::string(path), Json::boolean(text)]
    ImportBinary(path) => ["importbin", Json::string(path)]
    _ => abort("unexpected constructor in the frozen precedence fixtures")
  }
}

///|
fn prec_check(source : String, tree : @moonjsonnet.Ast) -> Unit raise {
  let parsed = @moonjsonnet.SyntaxDocument::parse(source).ast()
  assert_eq(prec_shape(parsed), prec_shape(tree), msg=source)
  // Mixed type operators in the structural grid need not be evaluated.
  // Both entries still undergo static/admission checks in a bounded context.
  let scoped = sequence_local(
    [
      ("a", token_number("1")),
      ("b", token_number("2")),
      ("c", token_number("3")),
    ],
    { source, tree, },
  )
  sequence_value(ordering_unused(scoped), 42)
}

///|
test "precedence table orders every binary pair with left association" {
  let levels = prec_levels()
  let a = prec_v("a")
  let b = prec_v("b")
  let c = prec_v("c")
  let mut pairs = 0
  for left_level = 0; left_level < levels.length(); left_level = left_level + 1 {
    for right_level = 0
        right_level < levels.length()
        right_level = right_level + 1 {
      for left in levels[left_level] {
        for right in levels[right_level] {
          // Earlier table entry binds tighter; ties associate left.
          let expected = if left_level <= right_level {
            prec_b(right, prec_b(left, a, b), c)
          } else {
            prec_b(left, a, prec_b(right, b, c))
          }
          prec_check("a " + left + " b " + right + " c", expected)
          pairs += 1
        }
      }
    }
  }
  assert_eq(pairs, 361)
  for symbols in levels {
    for symbol in symbols {
      prec_check(
        "a " + symbol + " (b " + symbol + " c)",
        prec_b(symbol, a, prec_b(symbol, b, c)),
      )
    }
  }
  prec_check("(a + b) * c", prec_b("*", prec_b("+", a, b), c))
  prec_check("a * (b + c)", prec_b("*", a, prec_b("+", b, c)))
}

///|
test "precedence keeps unary operands above all binary tiers" {
  let a = prec_v("a")
  let b = prec_v("b")
  for unary in ["+", "-", "!", "~"] {
    for symbols in prec_levels() {
      for binary in symbols {
        prec_check(
          unary + " a " + binary + " b",
          prec_b(binary, prec_u(unary, a), b),
        )
        prec_check(
          "a " + binary + " " + unary + " b",
          prec_b(binary, a, prec_u(unary, b)),
        )
      }
    }
    for inner in ["+", "-", "!", "~"] {
      prec_check(unary + " " + inner + " a", prec_u(unary, prec_u(inner, a)))
    }
  }
  prec_check("-(a + b)", prec_u("-", prec_b("+", a, b)))
}

///|
fn prec_postfix(base : @moonjsonnet.Ast, form : Int) -> @moonjsonnet.Ast {
  match form {
    0 => ordering_ast(Call(base, [(None, prec_v("b"))], false))
    1 => ordering_ast(Index(base, prec_v("b")))
    _ => ordering_ast(Index(base, ordering_ast(Literal("field"))))
  }
}

///|
test "precedence chains calls indexing and dot access before unary and binary" {
  let suffixes = ["(b)", "[b]", ".field"]
  let a = prec_v("a")
  let c = prec_v("c")
  for first = 0; first < suffixes.length(); first = first + 1 {
    for second = 0; second < suffixes.length(); second = second + 1 {
      prec_check(
        "a" + suffixes[first] + suffixes[second],
        prec_postfix(prec_postfix(a, first), second),
      )
    }
    for unary in ["+", "-", "!", "~"] {
      prec_check(
        unary + " a" + suffixes[first],
        prec_u(unary, prec_postfix(a, first)),
      )
    }
    for symbols in prec_levels() {
      for binary in symbols {
        prec_check(
          "a" + suffixes[first] + " " + binary + " c",
          prec_b(binary, prec_postfix(a, first), c),
        )
        prec_check(
          "c " + binary + " a" + suffixes[first],
          prec_b(binary, c, prec_postfix(a, first)),
        )
      }
    }
  }
  let sliced = ordering_ast(Slice(a, Some(prec_v("b")), Some(c), None))
  prec_check("-a[b:c]", prec_u("-", sliced))
  prec_check("a[b:c] + a", prec_b("+", sliced, a))
}

///|
test "precedence long expression bodies retain their maximal right extent" {
  let a = prec_v("a")
  let b = prec_v("b")
  let c = prec_v("c")
  let tail = prec_b("+", a, prec_b("*", b, c))
  let truth = ordering_ast(Literal(true))
  let local_tree = ordering_ast(
    Local([{ name: "x", value: a, range: None, }], prec_b("+", prec_v("x"), b)),
  )
  prec_check("local x=a; x+b", local_tree)
  prec_check(
    "a * local x=b; x+c",
    prec_b(
      "*",
      a,
      ordering_ast(
        Local(
          [{ name: "x", value: b, range: None, }],
          prec_b("+", prec_v("x"), c),
        ),
      ),
    ),
  )
  prec_check(
    "function(x) x+b*c",
    ordering_ast(
      Func(
        [{ name: "x", default_value: None, range: None, }],
        prec_b("+", prec_v("x"), prec_b("*", b, c)),
      ),
    ),
  )
  prec_check(
    "assert a<b : a+b; a+b*c",
    ordering_ast(Assert(prec_b("<", a, b), Some(prec_b("+", a, b)), tail)),
  )
  prec_check("error a+b*c", ordering_ast(Fail(tail)))
  prec_check(
    "if true then a else b+c",
    ordering_ast(If(truth, a, prec_b("+", b, c))),
  )
  prec_check(
    "(if true then a else b)+c",
    prec_b("+", ordering_ast(If(truth, a, b)), c),
  )
  prec_check(
    "a + if true then b else c+a",
    prec_b("+", a, ordering_ast(If(truth, b, prec_b("+", c, a)))),
  )
  prec_check(
    "if true then if false then a else b else c",
    ordering_ast(
      If(truth, ordering_ast(If(ordering_ast(Literal(false)), a, b)), c),
    ),
  )
  // Parenthesized leaves have an explicit extent without interpreting the
  // unparenthesized import/string restriction against the maximal-RHS prose.
  for
    (keyword, tree) in [
      ("import", ordering_ast(ImportFile("opaque", false))),
      ("importstr", ordering_ast(ImportFile("opaque", true))),
      ("importbin", ordering_ast(ImportBinary("opaque"))),
    ] {
    prec_check("(" + keyword + " 'opaque') + a", prec_b("+", tree, a))
  }
}

///|
test "precedence grouped values errors and lazy branches have fixed outcomes" {
  let cases : Array[(String, @moonjsonnet.Ast, Json)] = [
    ("8-3-1", prec_b("-", prec_b("-", prec_n(8), prec_n(3)), prec_n(1)), 4),
    ("32/4/2", prec_b("/", prec_b("/", prec_n(32), prec_n(4)), prec_n(2)), 4),
    (
      "16>>1>>1",
      prec_b(">>", prec_b(">>", prec_n(16), prec_n(1)), prec_n(1)),
      4,
    ),
    ("1+2*3", prec_b("+", prec_n(1), prec_b("*", prec_n(2), prec_n(3))), 7),
    ("(1+2)*3", prec_b("*", prec_b("+", prec_n(1), prec_n(2)), prec_n(3)), 9),
    ("1<<1+2", prec_b("<<", prec_n(1), prec_b("+", prec_n(1), prec_n(2))), 8),
    ("~1+2", prec_b("+", prec_u("~", prec_n(1)), prec_n(2)), 0),
    (
      "if true then 1 else 2+3",
      ordering_ast(
        If(
          ordering_ast(Literal(true)),
          prec_n(1),
          prec_b("+", prec_n(2), prec_n(3)),
        ),
      ),
      1,
    ),
    (
      "(if true then 1 else 2)+3",
      prec_b(
        "+",
        ordering_ast(If(ordering_ast(Literal(true)), prec_n(1), prec_n(2))),
        prec_n(3),
      ),
      4,
    ),
    (
      "(function(x) x+1)(2)*3",
      prec_b(
        "*",
        ordering_ast(
          Call(
            ordering_ast(
              Func(
                [{ name: "x", default_value: None, range: None, }],
                prec_b("+", prec_v("x"), prec_n(1)),
              ),
            ),
            [(None, prec_n(2))],
            false,
          ),
        ),
        prec_n(3),
      ),
      9,
    ),
    (
      "-(function(x) x)(2)+4",
      prec_b(
        "+",
        prec_u(
          "-",
          ordering_ast(
            Call(
              ordering_ast(
                Func(
                  [{ name: "x", default_value: None, range: None, }],
                  prec_v("x"),
                ),
              ),
              [(None, prec_n(2))],
              false,
            ),
          ),
        ),
        prec_n(4),
      ),
      2,
    ),
  ]
  for (source, tree, expected) in cases {
    prec_check(source, tree)
    sequence_value({ source, tree, }, expected)
  }
  let yes = ordering_ast(Literal(true))
  let no = ordering_ast(Literal(false))
  let dormant = ordering_error("dormant").tree
  let shortcut : OrderingExpr = {
    source: "true || false && (error 'dormant')",
    tree: prec_b("||", yes, prec_b("&&", no, dormant)),
  }
  prec_check(shortcut.source, shortcut.tree)
  sequence_value(shortcut, true)
  let required : OrderingExpr = {
    source: "false && (error 'dormant') || (error 'required')",
    tree: prec_b(
      "||",
      prec_b("&&", no, dormant),
      ordering_error("required").tree,
    ),
  }
  prec_check(required.source, required.tree)
  sequence_failure(required, @moonjsonnet.Runtime, Some("required"))
  for
    (source, tree, marker) in [
      (
        "error 'a'+'b'",
        ordering_ast(
          Fail(
            prec_b("+", ordering_ast(Literal("a")), ordering_ast(Literal("b"))),
          ),
        ),
        "ab",
      ),
      (
        "(error 'a')+'b'",
        prec_b(
          "+",
          ordering_ast(Fail(ordering_ast(Literal("a")))),
          ordering_ast(Literal("b")),
        ),
        "a",
      ),
    ] {
    prec_check(source, tree)
    sequence_failure({ source, tree, }, @moonjsonnet.Runtime, Some(marker))
  }
  let wrong_type : OrderingExpr = {
    source: "1 < 2 < 3",
    tree: prec_b("<", prec_b("<", prec_n(1), prec_n(2)), prec_n(3)),
  }
  prec_check(wrong_type.source, wrong_type.tree)
  sequence_failure(wrong_type, @moonjsonnet.Type, None)
  for handmade in [false, true] {
    let missing : OrderingExpr = {
      source: "true || false && precedence_missing",
      tree: prec_b("||", yes, prec_b("&&", no, prec_v("precedence_missing"))),
    }
    try ordering_program(ordering_unused(missing), handmade) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
    } noraise {
      _ => fail("unselected unknown name escaped static checking")
    }
  }
  for source in ["1+*2", "1+", "a[", "a(", "(a+b"] {
    try @moonjsonnet.SyntaxDocument::parse(source) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Syntax)
    } noraise {
      _ => fail("malformed source precedence fixture was admitted")
    }
  }
}
