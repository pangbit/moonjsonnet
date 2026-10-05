///|
test "lint tracks lexical references including dead code and object scopes" {
  for
    (source, expected) in [
      ("local x=1;42", ["Unused variable: x"]),
      ("local x=1,y=x;42", ["Unused variable: y"]),
      ("local x=1;local x=2;x", ["Unused variable: x"]),
      ("local x=1;function(x) x", ["Unused variable: x"]),
      ("local x=1;function(y=x) 42", []),
      ("local x=1;if false then x else 42", []),
      ("{local x=1,assert x==1,a:42}", []),
      ("local x='a';{local x=1,[x]:42}", ["Unused variable: x"]),
      ("[42 for x in [1]]", []),
      ("{local unused=1,[x]:42 for x in ['a']}", ["Unused variable: unused"]),
      ("function(unused) 42", []),
    ] {
    assert_eq(
      @moonjsonnet.lint([{ id: "entry", text: source, }]).map(d => d.message),
      expected,
    )
  }
}

///|
test "lint local cycles follow eager reference edges without evaluation" {
  for
    source in [
      "local x=x;42", "local x=y,y=x;42", "local x=x+1;42", "local x=if true then 42 else x;42",
    ] {
    assert_eq(
      @moonjsonnet.lint([{ id: "entry", text: source, }]).map(d => d.message),
      ["Endless loop in local definition"],
    )
  }
  for
    source in [
      "local x=[x];42", "local x=function() x;42", "local x={a:x};42", "local x=1%x;42",
      "local x=[1][x:];42", "local x=(function(a) 1)(x) tailstrict;42", "error 'not executed'",
    ] {
    assert_eq(@moonjsonnet.lint([{ id: "entry", text: source, }]).length(), 0)
  }
}

///|
test "lint imports check dead branches and raw bytes but not imported warnings" {
  let requests = []
  let resolver : (String, String) -> @moonjsonnet.BinarySource raise = (
    from,
    path,
  ) => {
    requests.push((from, path))
    {
      id: path,
      bytes: if path == "lib" {
        b"local unused=1;import 'entry'"
      } else if path == "entry" {
        b"42"
      } else {
        b"\xff\x00"
      },
    }
  }
  assert_eq(
    @moonjsonnet.lint(
      [
        {
          id: "entry",
          text: "[if false then import 'lib' else 42,importstr 'raw',importbin 'raw']",
        },
      ],
      resolver~,
    ).length(),
    0,
  )
  assert_eq(requests, [("entry", "lib"), ("lib", "entry"), ("entry", "raw")])
  let issues = @moonjsonnet.lint([
    { id: "entry", text: "{assert (import 'missing')==1,a:42}", },
  ])
  assert_eq(issues.length(), 1)
  assert_true(issues[0].message.contains("imports disabled"))
}

///|
test "lint collects independent parse errors but aborts on resource limits" {
  let issues = @moonjsonnet.lint([
    { id: "bad", text: "missing", },
    { id: "good", text: "local unused=1;42", },
  ])
  assert_eq(issues.length(), 2)
  assert_eq(issues[0].location.file, "bad")
  assert_eq(issues[1].message, "Unused variable: unused")
  try
    @moonjsonnet.lint([{ id: "entry", text: "local x=x;42", }], limits={
      ..@moonjsonnet.Limits::default(),
      steps: 1,
    })
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected lint limit")
  }
}

///|
test "lint long flat variable cycles use an iterative graph walk" {
  let bindings = []
  for i in 0..<2000 {
    bindings.push("x\{i}=x\{(i+1)%2000}")
  }
  let source = "local " + bindings.join(",") + ";42"
  assert_eq(
    @moonjsonnet.lint([{ id: "entry", text: source, }]).map(d => d.message),
    ["Endless loop in local definition"],
  )
}
