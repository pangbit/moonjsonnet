// Independent oracle: docs/development/SPEC-LANGUAGE-REVIEW.md.
// These assertions test clauses, rather than importing upstream expectations.

///|
test "language defaults distinguish definition caller and formal environments" {
  assert_eq(
    @moonjsonnet.evaluate("local x=10,f(a=x,b=a)=[a,b]; local x=99; [f(),f(x)]"),
    [[10, 10], [99, 99]],
  )
  assert_eq(
    @moonjsonnet.evaluate(
      "local f(a=b,b=7)=[a,b]; [f(),f(b=9),f(a=3),f(4,5),f(b=6,a=2)]",
    ),
    [[7, 7], [9, 9], [3, 7], [4, 5], [2, 6]],
  )
  assert_eq(
    @moonjsonnet.evaluate(
      "local f(a=1,b,c=a+b)=[a,b,c]; [f(b=4),f(2,b=5),f(c=9,b=3)]",
    ),
    [[1, 4, 5], [2, 5, 7], [1, 3, 9]],
  )
}

///|
test "language explicit arguments override lazy defaults and ignore recursive defaults" {
  for
    source in [
      "(function(a=error 'default')a)(a=42)", "(function(a=a)42)()", "(function(a=b,b=a)42)()",
      "(function(a=error 'unused')42)()", "(function(a)42)(error 'unused')", "(function(a=error 'unused',b=42)b)()",
    ] {
    assert_eq(@moonjsonnet.evaluate(source), 42)
  }
}

///|
test "language defaults cache once per call and share dependent parameters" {
  let mut calls = 0
  let next : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      calls += 1
      Json::number(calls.to_double())
    },
  }
  let natives = Map([("next", next)])
  assert_eq(
    @moonjsonnet.evaluate(
      "local f(a=std.native('next')(),b=a)=[a,b,a]; [f(),f()]",
      native_functions=natives,
    ),
    [[1, 1, 1], [2, 2, 2]],
  )
  assert_eq(calls, 2)
  assert_eq(
    @moonjsonnet.evaluate(
      "local f(a=std.native('next')(),b=a)=42; [f(),f(a=7)]",
      native_functions=natives,
    ),
    [42, 42],
  )
  assert_eq(calls, 2)
}

///|
test "language invalid binding executes no argument default or body callbacks" {
  let mut calls = 0
  let bump : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      calls += 1
      1
    },
  }
  for
    source in [
      "(function(a,b=std.native('bump')())std.native('bump')())()", "(function(a=std.native('bump')())std.native('bump')())(unknown=std.native('bump')())",
      "(function(a)std.native('bump')())(std.native('bump')(),a=std.native('bump')())",
      "(function(a)std.native('bump')())(std.native('bump')(),std.native('bump')())",
    ] {
    let program = @moonjsonnet.Program::parse(source)
    try program.evaluate(native_functions=Map([("bump", bump)])) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
    } noraise {
      _ => fail("invalid function binding succeeded: " + source)
    }
    assert_eq(calls, 0)
  }
}

///|
test "language statics traverse unused defaults bodies and named arguments" {
  for
    source in [
      "local unused=function(a=missing)42; 42", "(function(a=missing)a)(a=42)", "if false then function()missing else 42",
      "if false then (function(a)a)(a=1,a=2) else 42", "(function(a,b)a)(b=a,a=42)",
      "local f(a)=a; a",
    ] {
    try
      @moonjsonnet.Program::parse(source, filename="function-scope.jsonnet")
    catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Static)
        assert_eq(d.location.file, "function-scope.jsonnet")
      }
    } noraise {
      _ =>
        fail(
          "invalid function scope was not rejected before evaluation: " + source,
        )
    }
  }
}

///|
test "language method defaults retain late self and lexical super" {
  assert_eq(
    @moonjsonnet.evaluate(
      "local a={x:1,f(y=self.x):y}; local b=a+{x:2}; [a.f(),b.f(),a.f()]",
    ),
    [1, 2, 1],
  )
  assert_eq(
    @moonjsonnet.evaluate(
      "local a={x:1}+{x:2,f(y=super.x):y}; [a.f(),(a+{x:3}).f()]",
    ),
    [1, 1],
  )
}
