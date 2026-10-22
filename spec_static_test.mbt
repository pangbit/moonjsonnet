// Fixed spec.html chk-function requires unique formal parameter names.

///|
test "duplicate formal parameters fail statically before any invocation" {
  for
    source in [
      "function(x,x) 0", "function(x,x=1) 0", "function(x=1,x) 0", "if false then function(x,x) x else 42",
      "local f(x,x)=0; 42", "{method(x,x):0}", "local unused=function(x,x) error 'body'; 42",
    ] {
    try
      @moonjsonnet.Program::parse(source, filename="duplicate.jsonnet")
    catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Static)
        assert_eq(d.location.file, "duplicate.jsonnet")
        assert_eq(d.message, "duplicate parameter 'x'")
        if source == "function(x,x) 0" {
          assert_eq(d.location.column, 12)
        }
      }
    } noraise {
      _ => fail("duplicate parameters were accepted: " + source)
    }
  }
}

///|
test "public AST validation rejects duplicate formal parameters" {
  let loc : @moonjsonnet.Location = {
    file: "duplicate-ast",
    line: 1,
    column: 1,
  }
  let p : @moonjsonnet.AstParameter = {
    name: "x",
    default_value: None,
    range: None,
  }
  let body : @moonjsonnet.Ast = { kind: Literal(42), loc, end: None, }
  for params in [[p, p], [p, { ..p, default_value: Some(body), }]] {
    try
      @moonjsonnet.Program::from_ast({
        kind: Func(params, body),
        loc,
        end: None,
      })
    catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Static)
        assert_eq(d.location.file, "duplicate-ast")
      }
    } noraise {
      _ => fail("duplicate parameters escaped AST validation")
    }
  }
}

///|
test "distinct parameter scopes still allow lexical shadowing and lazy defaults" {
  assert_eq(
    @moonjsonnet.evaluate(
      "local x=9; [(function(x=1)x)(),(function(y=x)y)(),(function(x)function(x)x)(1)(2),(function(x=error 'unused')42)()]",
    ),
    [1, 9, 2, 42],
  )
}
