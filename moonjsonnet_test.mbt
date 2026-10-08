///|
test "laziness recursion lexical scope defaults comprehensions" {
  let cases = [
    ("local unused = error 'unused'; 42", "42"),
    ("local f(x) = if x == 0 then 1 else x * f(x-1); f(6)", "720"),
    ("local x = 3, f(y=x, z=y+1) = z; local x = 99; f()", "4"),
    ("local f(x, y=error 'unused') = x; f(x=1)", "1"),
    ("[x*y for x in [1,2] for y in [3,4] if y > 3]", "[4,8]"),
    ("{[x]: x for x in ['a','b']}", "{\"a\":\"a\",\"b\":\"b\"}"),
    ("local a = {x: 1, y: self.x}; [a.y, (a + {x: 2}).y, a.y]", "[1,2,1]"),
    ("({x: 1, secret:: 3} + {x: super.x + 1, secret: 4})", "{\"x\":2}"),
    ("({x:: 1} + {x::: 2})", "{\"x\":2}"),
    (
      "{x: 2, nested: { x: 3, root: $.x, own: self.x }}", "{\"nested\":{\"own\":3,\"root\":2,\"x\":3},\"x\":2}",
    ),
    ("{local n = self.x + 1, x: 1, y: n} + {x: 4}", "{\"x\":4,\"y\":5}"),
    ("{xs: [1]} + {xs+: [2]}", "{\"xs\":[1,2]}"),
    ("std.map(function(x) x * 2, [1,2,3])", "[2,4,6]"),
    (
      "[std.length('你好😀'), '你好😀'[2], std.substr('你好😀',1,2)]",
      "[3,\"😀\",\"好😀\"]",
    ),
    ("{assert self.x > 0, x: 1}", "{\"x\":1}"),
    ("[false && error 'no', true || error 'no']", "[false,true]"),
  ]
  for (input, expected) in cases {
    assert_eq(@moonjsonnet.evaluate(input), @json.parse(expected))
  }
}

///|
test "structured errors preserve category and source" {
  let cases = [
    ("{", @moonjsonnet.Syntax),
    ("local x=missing; 1", @moonjsonnet.Static),
    ("1 + true", @moonjsonnet.Type),
    ("assert false: 'bad'; 1", @moonjsonnet.Assertion),
    ("{assert self.a > 0, a: -1}", @moonjsonnet.Assertion),
    ("1/0", @moonjsonnet.Runtime),
    ("1e308 * 10", @moonjsonnet.Runtime),
    ("import 'no.libsonnet'", @moonjsonnet.Import),
    ("std.__missingForDiagnosticTest()", @moonjsonnet.Unsupported),
    ("local x=x; x", @moonjsonnet.Limit),
  ]
  for (input, kind) in cases {
    try @moonjsonnet.evaluate(input, filename="case.jsonnet") catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, kind)
        assert_eq(d.location.file, "case.jsonnet")
        assert_true(d.location.line > 0)
      }
    } noraise {
      _ => fail("expected error: \{input}")
    }
  }
}

///|
test "import caching isolated scope and cycle diagnostics" {
  let count = Ref(0)
  let resolver : (String, String) -> @moonjsonnet.Source raise = fn(
    _from,
    path,
  ) {
    count.val += 1
    @moonjsonnet.Source::{ id: path, text: "{x: 42}", }
  }
  assert_eq(
    @moonjsonnet.evaluate("[(import 'a').x, (import 'a').x]", resolver~),
    @json.parse("[42,42]"),
  )
  assert_eq(count.val, 1)
  try
    @moonjsonnet.evaluate("import 'a'", resolver=fn(_from, path) {
      { id: path, text: "import 'a'", }
    })
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Import)
  } noraise {
    _ => fail("expected import cycle")
  }
}

///|
test "resource limits" {
  let limits = @moonjsonnet.Limits::default()
  for
    (source, bounds) in [
      ("local f(x)=f(x+1); f(0)", { ..limits, depth: 20, }),
      ("std.range(0, 100)", { ..limits, steps: 10, }),
      ("'😀😀'", { ..limits, output_bytes: 8, }),
      ("123456", { ..limits, source_bytes: 3, }),
    ] {
    try @moonjsonnet.evaluate(source, limits=bounds) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
    } noraise {
      _ => fail("expected limit error")
    }
  }
}

///|
test "regressions for standard string manifests static super and token names" {
  assert_eq(
    @moonjsonnet.evaluate("std.toString({b:2,a:[1,2]})"),
    Json::string("{\"a\": [1, 2], \"b\": 2}"),
  )
  assert_eq(
    @moonjsonnet.evaluate("local string=1,number=2,EOF=3; string+number+EOF"),
    Json::number(6),
  )
  try @moonjsonnet.evaluate("{a:super}") catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
  } noraise {
    _ => fail("expected static error")
  }
  try
    @moonjsonnet.evaluate("std.foldl(function(a,b)b,[1,2],error 'unused')")
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
  } noraise {
    _ => fail("foldl must force its initial value, as in go-jsonnet")
  }
}

///|
test "flat syntax tree and exponential allocation are bounded" {
  let b = StringBuilder()
  b.write_char('1')
  for _ in 0..<1000 {
    b.write_string("+1")
  }
  try @moonjsonnet.evaluate(b.to_string()) catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected AST depth error")
  }
  let limits = @moonjsonnet.Limits::default()
  try
    @moonjsonnet.evaluate(
      "local f(n)=if n==0 then [0] else local a=f(n-1); a+a; std.length(f(30))",
      limits={ ..limits, output_bytes: 1024, },
    )
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected allocation limit")
  }
}

///|
test "pretty manifestation cannot bypass intermediate output budget" {
  let limits = @moonjsonnet.Limits::default()
  try
    @moonjsonnet.evaluate("std.length(std.manifestJson([[[[[1]]]]]))", limits={
      ..limits,
      output_bytes: 30,
    })
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected pretty output limit")
  }
}

///|
test "import syntax and resolver failures retain calling context" {
  let syntax : (String, String) -> @moonjsonnet.Source raise = (_, _) => {
    id: "child",
    text: "{",
  }
  let missing : (String, String) -> @moonjsonnet.Source raise = (_, _) => {
    raise @moonjsonnet.Error({
      kind: @moonjsonnet.Import,
      message: "missing",
      location: { file: "child", line: 1, column: 1, },
      context: [],
      trace: [],
    })
  }
  for resolver in [syntax, missing] {
    try
      @moonjsonnet.evaluate(
        "local f() = import 'child'; f()",
        filename="parent",
        resolver~,
      )
    catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.location.file, "child")
        assert_eq(d.context.length(), 2)
        assert_eq(d.context[0].file, "parent")
        assert_eq(d.context[1].file, "parent")
      }
    } noraise {
      _ => fail("expected located import error")
    }
  }
}
