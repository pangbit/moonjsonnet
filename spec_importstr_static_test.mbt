// The named rule is a premise-free static judgment. Runtime controls below
// protect its boundary; they are not acceptance of the entire import system.

///|
fn importstr_ast(kind : @moonjsonnet.AstKind) -> @moonjsonnet.Ast {
  { kind, loc: { file: "virtual-entry", line: 1, column: 1, }, end: None, }
}

///|
test "chk importstr accepts opaque canonical strings in source and handmade AST" {
  for path in ["", "missing+self+super+$", "\u0000", "目录/😀\n"] {
    let source = "importstr " + Json::string(path).stringify()
    let parsed = @moonjsonnet.Program::parse(source)
    assert_true(parsed.ast().kind is ImportFile(p, true) && p == path)
    let synthetic = @moonjsonnet.Program::from_ast(
      importstr_ast(ImportFile(path, true)),
    )
    assert_true(synthetic.ast().kind is ImportFile(p, true) && p == path)
  }
}

///|
test "chk importstr ignores surrounding static names and object context" {
  for
    source in [
      "local std=0; importstr 'opaque'", "function(x) importstr 'opaque'", "{field:importstr 'opaque'}",
      "{[importstr 'opaque']:0}", "if false then importstr 'opaque' else 42",
    ] {
    ignore(@moonjsonnet.Program::parse(source))
  }
  let leaf = importstr_ast(ImportFile("opaque", true))
  for
    kind in [
      @moonjsonnet.AstKind::Local(
        [{ name: "std", value: importstr_ast(Literal(0)), range: None, }],
        leaf,
      ),
      Func([{ name: "x", default_value: None, range: None, }], leaf),
      Obj(
        [
          {
            key: importstr_ast(Literal("field")),
            value: leaf,
            visibility: 1,
            additive: false,
          },
        ],
        [],
        [],
      ),
      If(importstr_ast(Literal(false)), leaf, importstr_ast(Literal(42))),
    ] {
    let program = @moonjsonnet.Program::from_ast(importstr_ast(kind))
    assert_eq(program.ast().loc.file, "virtual-entry")
  }
}

///|
test "importstr static acceptance does not resolve targets or parse opaque data" {
  let data = "missing + self.x + super.x + $\n{ not valid code\u0000"
  let requests : Array[(String, String)] = []
  let resolver : (String, String) -> @moonjsonnet.Source raise = (from, path) => {
    requests.push((from, path))
    assert_eq(path, "opaque")
    { id: "virtual-data", text: data, }
  }
  let source = @moonjsonnet.Program::parse(
    "local missing=42,std=0; importstr 'opaque'",
    filename="virtual-entry",
  )
  let synthetic = @moonjsonnet.Program::from_ast(
    importstr_ast(ImportFile("opaque", true)),
  )
  assert_eq(requests.length(), 0)
  for program in [source, synthetic] {
    requests.clear()
    assert_eq(program.evaluate(resolver~), Json::string(data))
    assert_eq(requests, [("virtual-entry", "opaque")])
  }
  requests.clear()
  for
    source in [
      "local unused=importstr 'opaque';42", "(function(unused)42)(importstr 'opaque')",
      "{hidden::importstr 'opaque',answer:42}.answer",
    ] {
    assert_eq(@moonjsonnet.Program::parse(source).evaluate(resolver~), 42)
    assert_eq(requests.length(), 0)
  }
}

///|
test "importstr does not waive grammar or surrounding static rejection" {
  for source in ["importstr 42", "importstr ('opaque')", "importstr 'a'+'b'"] {
    try @moonjsonnet.Program::parse(source) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Syntax)
    } noraise {
      _ => fail("nonliteral importstr source accepted")
    }
  }
  try @moonjsonnet.Program::parse("[importstr 'opaque',missing]") catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
  } noraise {
    _ => fail("importstr suppressed another expression's statics")
  }
  let tree = importstr_ast(
    Arr([
      importstr_ast(ImportFile("opaque", true)),
      importstr_ast(Var("missing")),
    ]),
  )
  try @moonjsonnet.Program::from_ast(tree) catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Static)
  } noraise {
    _ => fail("handmade importstr suppressed surrounding statics")
  }
}
