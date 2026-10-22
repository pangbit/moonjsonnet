// Fixed spec.html Core Syntax: importbin substitutes raw bytes as integers
// from 0 through 255. All fixtures below are self-made virtual data.

///|
fn importbin_node(kind : @moonjsonnet.AstKind) -> @moonjsonnet.Ast {
  { kind, loc: { file: "virtual-entry", line: 1, column: 1, }, end: None, }
}

///|
test "importbin substitutes every unsigned byte in source and handmade AST" {
  // Multiplication by 73 permutes all residues modulo 256, preserving an
  // intentionally nonmonotone order. The value oracle is numeric, not a decode.
  let permutation = [ for i in 0..<256 => (i * 73 + 19) % 256 ]
  let cases : Array[(Bytes, Json)] = [
    (
      Bytes::from_array(permutation.map(n => n.to_byte())),
      Json::array(permutation.map(n => Json::number(n.to_double()))),
    ),
    (b"", []),
    (b"\xff\x80\x00\x80\xff", [255, 128, 0, 128, 255]),
    (b"\xff\x00\xc0\xaf\xed\xa0\x80", [255, 0, 192, 175, 237, 160, 128]),
    (b"error 1", [101, 114, 114, 111, 114, 32, 49]),
  ]
  for (bytes, expected) in cases {
    let requests : Array[(String, String)] = []
    let binary_resolver : (String, String) -> @moonjsonnet.BinarySource raise = (
      from,
      path,
    ) => {
      requests.push((from, path))
      { id: "virtual-data", bytes, }
    }
    let source = @moonjsonnet.Program::parse(
      "importbin 'data'",
      filename="virtual-entry",
    )
    let handmade = @moonjsonnet.Program::from_ast(
      importbin_node(ImportBinary("data")),
    )
    assert_eq(requests.length(), 0)
    for program in [source, handmade] {
      requests.clear()
      assert_true(program.ast().kind is ImportBinary(path) && path == "data")
      assert_eq(program.evaluate(binary_resolver~), expected)
      assert_eq(requests, [("virtual-entry", "data")])
    }
  }
}

///|
test "unused importbin source and handmade expressions make zero requests" {
  let requests : Array[(String, String)] = []
  let binary_resolver : (String, String) -> @moonjsonnet.BinarySource raise = (
    from,
    path,
  ) => {
    requests.push((from, path))
    fail("unused virtual binary import was demanded")
  }
  for
    source in [
      "local unused=importbin 'data';42", "if false then importbin 'data' else 42",
      "(function(unused)42)(importbin 'data')", "(function(unused=importbin 'data')42)()",
      "{hidden::importbin 'data',answer:42}.answer",
    ] {
    assert_eq(
      @moonjsonnet.Program::parse(source).evaluate(binary_resolver~),
      42,
    )
    assert_eq(requests.length(), 0)
  }
  let leaf = importbin_node(ImportBinary("data"))
  for
    kind in [
      @moonjsonnet.AstKind::If(
        importbin_node(Literal(false)),
        leaf,
        importbin_node(Literal(42)),
      ),
      Local(
        [{ name: "unused", value: leaf, range: None, }],
        importbin_node(Literal(42)),
      ),
    ] {
    let program = @moonjsonnet.Program::from_ast(importbin_node(kind))
    assert_eq(program.evaluate(binary_resolver~), 42)
    assert_eq(requests.length(), 0)
  }
}

///|
test "importbin separates creation errors from demanded resolver failures" {
  for source in ["importbin 0", "importbin ('data')", "importbin 'a'+'b'"] {
    try @moonjsonnet.Program::parse(source, filename="virtual-entry") catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Syntax)
        assert_eq(d.location.file, "virtual-entry")
      }
    } noraise {
      _ => fail("nonliteral importbin source accepted")
    }
  }
  try @moonjsonnet.Program::parse("[importbin 'data',missing]") catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
  } noraise {
    _ => fail("source importbin waived surrounding statics")
  }
  try
    @moonjsonnet.Program::from_ast(
      importbin_node(
        Arr([
          importbin_node(ImportBinary("data")),
          importbin_node(Var("missing")),
        ]),
      ),
    )
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
  } noraise {
    _ => fail("handmade importbin waived surrounding statics")
  }
  let source = @moonjsonnet.Program::parse(
    "importbin 'data'",
    filename="virtual-entry",
  )
  let handmade = @moonjsonnet.Program::from_ast(
    importbin_node(ImportBinary("data")),
  )
  for program in [source, handmade] {
    try program.evaluate() catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Import)
        assert_eq(d.location.file, "virtual-entry")
      }
    } noraise {
      _ =>
        fail("demanded binary import unexpectedly succeeded without resolver")
    }
    let mut reads = 0
    try
      program.evaluate(binary_resolver=(_, _) => {
        reads += 1
        fail("virtual unavailable")
      })
    catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Import)
        assert_true(d.message.contains("virtual unavailable"))
        assert_eq(d.location.file, "virtual-entry")
      }
    } noraise {
      _ => fail("demanded failing virtual resolver unexpectedly succeeded")
    }
    assert_eq(reads, 1)
  }
}

///|
test "handmade repeated importbin demands share one request and exact bytes" {
  let leaf = importbin_node(ImportBinary("data"))
  let program = @moonjsonnet.Program::from_ast(
    importbin_node(Arr([leaf, leaf])),
  )
  let requests : Array[(String, String)] = []
  let result = program.evaluate(binary_resolver=(from, path) => {
    requests.push((from, path))
    {
      id: "virtual-data",
      bytes: if requests.length() == 1 {
        b"\x00\xff\x80\x00"
      } else {
        b"*"
      },
    }
  })
  assert_eq(result, [[0, 255, 128, 0], [0, 255, 128, 0]])
  assert_eq(requests, [("virtual-entry", "data")])
}
