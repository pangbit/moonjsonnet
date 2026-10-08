///|
test "raw syntax tree retains all expression forms and exact trivia" {
  for
    source in [
      " /*head*/ (1.20E+003) //tail\r\n", "[null,true,false,@'it''s',\"中\"]", "local f(x=1,y=2)=x+y,z=3; f(z,y=4) tailstrict",
      "function(x=1,y) if x then y else error 'no'", "assert true:'yes'; [~1,!false,-2,+3]",
      "{local f(x=1)=x, assert self.a>0:'bad',a:1,b+:2,h::3,v:::4,['k'](x=1):x}",
      "{} {a:1}", "[x+y for x in [1,2] if true for y in [3]]", "{local x=1,[y]:x for y in ['a'] if true}",
      "[1,2][0]", "foo.bar", "[1,2,3][1:2:1]", "import 'missing'", "importstr 'missing'",
      "importbin 'missing'", "|||\n  text\n|||", "1 + 2 * 3 == 7 && true", "unknown + self.a + super.x + $",
    ] {
    let document = @moonjsonnet.SyntaxDocument::parse(source, filename="raw")
    let tree = document.raw_ast()
    assert_eq(tree.text(), source)
    let stack : Array[@moonjsonnet.RawPart] = [Child(tree.root)]
    let lexical : Array[@moonjsonnet.SourcePart] = []
    while stack.pop() is Some(part) {
      match part {
        Text(text) => lexical.push(text)
        Child(node) =>
          for i = node.parts.length() - 1; i >= 0; i = i - 1 {
            stack.push(node.parts[i])
          }
      }
    }
    lexical.append(tree.final_fodder)
    assert_true(
      lexical.map(p => (p.kind, p.text, p.range)) ==
      document.parts().map(p => (p.kind, p.text, p.range)),
    )
    assert_eq(tree.clone().text(), source)
    assert_eq(tree.format(), document.format())
    assert_eq(
      @moonjsonnet.format_node(tree.root, final_fodder=tree.final_fodder),
      document.format(),
    )
    assert_eq(document.text(), source)
    ignore(@moonjsonnet.SyntaxDocument::parse(tree.format()))
  }
  assert_true(@moonjsonnet.RawAst::parse("(42)").root.kind is Parens)
  assert_true(@moonjsonnet.RawAst::parse("{} {}").root.kind is ApplyBrace)
  assert_true(@moonjsonnet.RawAst::parse("foo.bar").root.kind is DotIndex)
}

///|
test "raw syntax edits and clones isolate nodes and final fodder" {
  let source = "/*head*/ [1,2] //end\r\n"
  let document = @moonjsonnet.SyntaxDocument::parse(source)
  let tree = document.raw_ast()
  let clone = tree.clone()
  let stack = [tree.root]
  let mut changed = false
  while stack.pop() is Some(node) {
    for i, part in node.parts {
      match part {
        Child(child) => stack.push(child)
        Text(part) =>
          if part.kind is TokenText && part.text == "1" {
            node.parts[i] = Text({ ..part, text: "42", })
            changed = true
          }
      }
    }
  }
  assert_true(changed)
  for i, part in tree.final_fodder {
    if part.kind is LineComment {
      tree.final_fodder[i] = { ..part, text: "// changed\r", }
    }
  }
  assert_eq(tree.text(), "/*head*/ [42,2] // changed\r\n")
  assert_eq(tree.format(), "/*head*/ [42, 2]  // changed\n")
  assert_eq(clone.text(), source)
  assert_eq(document.text(), source)
  assert_eq(document.raw_ast().text(), source)
  let refreshed = @moonjsonnet.RawAst::parse(tree.text())
  assert_eq(refreshed.format(), tree.format())
}

///|
test "raw cloning isolates repeated occurrences of a shared child" {
  let original = @moonjsonnet.RawAst::parse("[42]")
  let shared : @moonjsonnet.RawNode = {
    kind: Binary("+"),
    range: original.root.range,
    parts: [Child(original.root), Child(original.root)],
  }
  let copy = shared.clone()
  guard copy.parts is [Child(left), Child(right)] else {
    fail("shared raw children")
  }
  left.parts.clear()
  assert_eq(right.text(), "[42]")
  assert_eq(original.text(), "[42]")
}

///|
test "raw deep trees use iterative build text clone and formatting" {
  let source = "0" + "+1".repeat(3999)
  let limits = { ..@moonjsonnet.SyntaxLimits::default(), parser_depth: 8, }
  let raw = @moonjsonnet.RawAst::parse(source, limits~)
  assert_eq(raw.text(limits~), source)
  assert_eq(raw.clone(limits~).text(limits~), source)
  assert_eq(raw.format(limits~), "0" + " + 1".repeat(3999) + "\n")
  let mut current = raw.root
  let mut depth = 0
  while current.kind is Binary("+") {
    let children = current.parts.filter_map(part => {
      match part {
        Child(child) => Some(child)
        Text(_) => None
      }
    })
    assert_eq(children.length(), 2)
    current = children[0]
    depth += 1
  }
  assert_eq(depth, 3999)
  assert_eq(current.kind, @moonjsonnet.RawNodeKind::Number)
}

///|
test "raw edited trees retain complete admission and parser errors" {
  let limits = @moonjsonnet.SyntaxLimits::default()
  let parts : Array[@moonjsonnet.RawPart] = []
  let cycle : @moonjsonnet.RawNode = { kind: Array, range: None, parts, }
  parts.push(Child(cycle))
  for
    operation in [
      () => ignore(cycle.text(limits={ ..limits, tree_depth: 32, })),
      () => ignore(cycle.clone(limits={ ..limits, nodes: 32, })),
      () => {
        ignore(@moonjsonnet.format_node(cycle, limits={ ..limits, steps: 32, }))
      },
    ] {
    try operation() catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
    } noraise {
      _ => fail("cyclic raw syntax accepted")
    }
  }
  parts.clear()
  let tree = @moonjsonnet.RawAst::parse("[42]")
  for
    constrained in [
      { ..limits, source_bytes: 3, },
      { ..limits, nodes: 1, },
      { ..limits, steps: 1, },
      { ..limits, tree_depth: 1, },
    ] {
    try tree.format(limits=constrained) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
    } noraise {
      _ => fail("raw syntax budget ignored")
    }
  }
  tree.root.parts.clear()
  try tree.format() catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Syntax)
  } noraise {
    _ => fail("edited invalid syntax accepted")
  }
}

///|
test "raw final fodder shares export and clone work budgets" {
  let source = "42" + " /* tail */".repeat(20)
  let document = @moonjsonnet.SyntaxDocument::parse(source)
  let limits = { ..@moonjsonnet.SyntaxLimits::default(), steps: 10, }
  try document.raw_ast(limits~) catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("final export work ignored")
  }
  let raw = document.raw_ast()
  try raw.clone(limits~) catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("final clone work ignored")
  }
}
