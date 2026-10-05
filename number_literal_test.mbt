///|
test "numeric spellings and overflow survive parsing and AST round trips" {
  let program = @moonjsonnet.Program::parse("1.20E+003", filename="number")
  let tree = program.ast().clone()
  guard tree.kind is NumberLiteral(raw) else { fail("numeric token") }
  assert_eq(raw, "1.20E+003")
  assert_eq(tree.source_range().unwrap().format(), "number:1:1-10")
  assert_eq(@moonjsonnet.Program::from_ast(tree).evaluate(), 1200)
  let huge = @moonjsonnet.Program::parse("1e309", filename="huge")
  let copied = @moonjsonnet.Program::from_ast(huge.ast().clone())
  for p in [huge, copied] {
    try p.evaluate() catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Runtime)
        assert_eq(d.message, "overflow")
        assert_eq(d.location, { file: "huge", line: 1, column: 1, })
      }
    } noraise {
      _ => fail("expected overflow")
    }
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "local x=1e309; if false then x else [1e-99999,0e99999]",
    ),
    [0, 0],
  )
  assert_eq(@moonjsonnet.evaluate("std.length([1e309])"), 1)
  assert_eq(@moonjsonnet.evaluate("(function(x) 42)(1e309)"), 42)
}

///|
test "manually constructed numeric tokens validate lexical shape without conversion" {
  let loc : @moonjsonnet.Location = { file: "manual", line: 1, column: 1, }
  for
    raw in [
      "", "-1", "+1", "01", "1.", ".1", "NaN", "Infinity", "1e+", "1_0", " 1", "1 ",
      "1+2",
    ] {
    try
      @moonjsonnet.Program::from_ast({
        kind: NumberLiteral(raw),
        loc,
        end: None,
      })
    catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Static)
        assert_eq(d.message, "invalid AST numeric literal")
      }
    } noraise {
      _ => fail("invalid numeric token accepted")
    }
  }
  let huge : @moonjsonnet.Ast = {
    kind: NumberLiteral("1e99999"),
    loc,
    end: None,
  }
  let valid = @moonjsonnet.Program::from_ast({
    kind: If({ kind: Literal(false), loc, end: None, }, huge, {
      kind: Literal(42),
      loc,
      end: None,
    }),
    loc,
    end: None,
  })
  assert_eq(valid.evaluate(), 42)
}
