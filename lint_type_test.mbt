///|
test "lint infers recursive values and function results without execution" {
  for
    source in [
      "local f(x)=if x then 42 else f(true);f(false)()", "local x={a:x,b:42};x.a.a.b()",
      "local a=[b,42],b=[a,'x'];a[0][0][1]()", "(import 'lib')()",
    ] {
    let issues = @moonjsonnet.lint([{ id: "entry", text: source, }], resolver=fn(
      _,
      path,
    ) {
      { id: path, bytes: b"42", }
    })
    assert_eq(issues.map(d => d.message), [
      "Called value must be a function, but it is assumed to be a number",
    ])
  }
}

///|
test "lint checks function arguments and preserves parameter abstraction" {
  for
    (source, expected) in [
      ("(function(x) x)(1,x=2)", ["Argument x already provided"]),
      ("(function(x) x)(y=1)", ["function has no parameter y"]),
      ("(function(x) x)()", ["Missing argument: x"]),
      (
        "(function() 42)(1)",
        ["Too many arguments: got 1, but expected at most 0"],
      ),
      ("function(x=1) x()", []),
      ("function(x) x.foo(1)", []),
    ] {
    assert_eq(
      @moonjsonnet.lint([{ id: "entry", text: source, }]).map(d => d.message),
      expected,
    )
  }
}

///|
test "lint standard-library types follow the pinned analysis declarations" {
  for
    (source, message) in [
      (
        "std.length([])()", "Called value must be a function, but it is assumed to be a number",
      ),
      (
        "!std.range(1,2)[0]", "Operand is not a boolean, it is assumed to be a number",
      ),
      (
        "std.base64DecodeBytes('')()", "Called value must be a function, but it is assumed to be a number",
      ),
      (
        "~std.stringChars('x')[0]", "Operand is not a number, it is assumed to be a string",
      ),
    ] {
    assert_eq(
      @moonjsonnet.lint([{ id: "entry", text: source, }]).map(d => d.message),
      [message],
    )
  }
}

///|
test "lint type graph limits terminate recursive index expansion" {
  let bindings = []
  for i in 0..<40 {
    bindings.push("x\{i}=x\{i+1}[0]")
  }
  bindings.push("x40=[]")
  let source = "local " + bindings.join(",") + ";x0"
  try
    @moonjsonnet.lint([{ id: "entry", text: source, }], limits={
      ..@moonjsonnet.Limits::default(),
      depth: 20,
      steps: 2000,
    })
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected bounded type index expansion")
  }
  assert_eq(@moonjsonnet.lint([{ id: "entry", text: "42", }]).length(), 0)
}

///|
test "lint graph work is bounded and object assertions retain lexical analysis" {
  try
    @moonjsonnet.lint([{ id: "entry", text: "42", }], limits={
      ..@moonjsonnet.Limits::default(),
      steps: 100,
    })
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected graph work limit")
  }
  assert_eq(
    @moonjsonnet.lint([
      { id: "entry", text: "local x=1; {assert x, assert 42(), a:1}", },
    ]).length(),
    0,
  )
  assert_eq(
    @moonjsonnet.lint([
      { id: "entry", text: "{}['\\u0000\\u0007\\u007f\\u00a0\\u00ad\\u2028']", },
    ]).map(d => d.message),
    ["Indexed object has no field \"\\x00\\a\\x7f\\u00a0\\u00ad\\u2028\""],
  )
}
