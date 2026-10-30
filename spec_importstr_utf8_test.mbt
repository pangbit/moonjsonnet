// Fixed Core Syntax requires UTF-8 text substitution. Diagnostic categories and
// retained-request checks below are separately classified embedding boundaries.

///|
fn utf8_text_ast(kind : @moonjsonnet.AstKind) -> @moonjsonnet.Ast {
  { kind, loc: { file: "virtual-utf8-entry", line: 1, column: 1, }, end: None, }
}

///|
fn utf8_text_programs(
  unused~ : Bool = false,
) -> Array[@moonjsonnet.Program] raise {
  let leaf = utf8_text_ast(ImportFile("data", true))
  let source = if unused {
    "if false then importstr 'data' else 42"
  } else {
    "importstr 'data'"
  }
  let tree = if unused {
    utf8_text_ast(
      If(utf8_text_ast(Literal(false)), leaf, utf8_text_ast(Literal(42))),
    )
  } else {
    leaf
  }
  [
    @moonjsonnet.Program::parse(source, filename="virtual-utf8-entry"),
    @moonjsonnet.Program::from_ast(tree),
  ]
}

///|
test "importstr decodes explicit UTF8 scalar boundaries in source and handmade AST" {
  let cases : Array[(Bytes, String)] = [
    (b"", ""),
    (b"\x00\x7f\r\n\t", "\u0000\u007f\r\n\t"),
    (b"\xc2\x80\xdf\xbf", "\u0080\u07ff"),
    (
      b"\xe0\xa0\x80\xed\x9f\xbf\xee\x80\x80\xef\xbf\xbf", "\u0800\ud7ff\ue000\uffff",
    ),
    (b"\xf0\x90\x80\x80\xf4\x8f\xbf\xbf", "\u{10000}\u{10ffff}"),
    (b"\xc3\xa9 e\xcc\x81", "é e\u0301"),
    (b"A\xef\xbb\xbfZ", "A\ufeffZ"),
    (b"\xef\xbf\xbd", "�"),
    (b"error '\\u0041'\r\n{\x00", "error '\\u0041'\r\n{\u0000"),
  ]
  let programs = utf8_text_programs()
  for (bytes, expected) in cases {
    for program in programs {
      let requests : Array[(String, String)] = []
      let evaluator = @moonjsonnet.Evaluator::new()
      evaluator.set_importer(binary_resolver=(from, path) => {
        requests.push((from, path))
        { id: "virtual-utf8-data", bytes, }
      })
      let actual = evaluator.evaluate(program)
      assert_eq(actual, Json::string(expected))
      assert_eq(requests, [("virtual-utf8-entry", "data")])
    }
  }
}

///|
test "importstr rejects malformed UTF8 bytes only on source and handmade demand" {
  let malformed : Array[Bytes] = [
    b"\x80", b"\xbf", b"\xc0\xaf", b"\xc1\xbf", b"\xc2", b"\xc2\x20", b"\xe0\x80\x80",
    b"\xe1\x80", b"\xe1\x20\x80", b"\xed\xa0\x80", b"\xed\xbf\xbf", b"\xf0\x80\x80\x80",
    b"\xf0\x90\x80", b"\xf1\x20\x80\x80", b"\xf4\x90\x80\x80", b"\xf5\x80\x80\x80",
    b"\xff", b"a\x80b",
  ]
  let programs = utf8_text_programs()
  for bytes in malformed {
    for program in programs {
      let mut reads = 0
      let evaluator = @moonjsonnet.Evaluator::new()
      evaluator.set_importer(binary_resolver=(_, _) => {
        reads += 1
        { id: "virtual-utf8-data", bytes, }
      })
      try evaluator.evaluate(program) catch {
        @moonjsonnet.Error(d) => {
          // Rejection is normative. This category and provenance are host
          // regression expectations, not a specified Jsonnet diagnostic format.
          assert_eq(d.kind, @moonjsonnet.Import)
          assert_eq(d.location.file, "virtual-utf8-data")
          assert_true(
            d.context.iter().any(loc => loc.file == "virtual-utf8-entry"),
          )
        }
      } noraise {
        _ => fail("malformed UTF8 became a successful string import")
      }
      assert_eq(reads, 1)
    }
  }
}

///|
test "importstr unused invalid data stays lazy and retained bytes still reject" {
  let demanded = utf8_text_programs()
  let unused = utf8_text_programs(unused=true)
  for i in 0..<2 {
    let evaluator = @moonjsonnet.Evaluator::new()
    let requests : Array[(String, String)] = []
    evaluator.set_importer(binary_resolver=(from, path) => {
      requests.push((from, path))
      { id: "virtual-utf8-data", bytes: b"\xff", }
    })
    assert_eq(evaluator.evaluate(unused[i]), 42)
    assert_eq(requests.length(), 0)
    for _ in 0..<2 {
      try evaluator.evaluate(demanded[i]) catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Import)
      } noraise {
        _ => fail("retained malformed bytes became a successful string")
      }
    }
    // This observes the existing embedding byte-cache policy for one exact
    // request. It does not complete a normative general failure-cache rule.
    assert_eq(requests, [("virtual-utf8-entry", "data")])
  }
}

///|
test "importstr repeated source and handmade requests return exact Unicode text" {
  let leaf = utf8_text_ast(ImportFile("data", true))
  let programs = [
    @moonjsonnet.Program::parse(
      "[importstr 'data',importstr 'data']",
      filename="virtual-utf8-entry",
    ),
    @moonjsonnet.Program::from_ast(utf8_text_ast(Arr([leaf, leaf]))),
  ]
  for program in programs {
    let requests : Array[(String, String)] = []
    let evaluator = @moonjsonnet.Evaluator::new()
    evaluator.set_importer(binary_resolver=(from, path) => {
      requests.push((from, path))
      { id: "virtual-utf8-data", bytes: b"\xc3\xa9\xf0\x9f\x98\x80\x00", }
    })
    let result = evaluator.evaluate(program)
    assert_eq(result, ["é😀\u0000", "é😀\u0000"])
    assert_eq(requests, [("virtual-utf8-entry", "data")])
  }
}
