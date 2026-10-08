///|
test "error values and assertion messages use bounded Jsonnet string conversion" {
  for
    (expression, expected) in [
      ("1", "1"),
      ("true", "true"),
      ("null", "null"),
      ("[]", "[ ]"),
      ("{}", "{ }"),
      ("[1,false,null]", "[1, false, null]"),
      ("{b:2,a:1,hidden::error 'unused'}", "{\"a\": 1, \"b\": 2}"),
      ("['\\u007f\\u0080\\u009f']", "[\"\\u007f\\u0080\\u009f\"]"),
    ] {
    for prefix in ["error ", "assert false:", "{assert false:"] {
      let suffix = match prefix {
        "error " => ""
        "assert false:" => ";42"
        _ => ",a:42}"
      }
      let source = prefix + expression + suffix
      try @moonjsonnet.evaluate(source) catch {
        @moonjsonnet.Error(d) => assert_eq(d.message, expected)
      } noraise {
        _ => fail("error value should fail")
      }
    }
  }
  // A successful condition leaves even a non-string message unevaluated.
  assert_eq(@moonjsonnet.evaluate("assert true:error 'unused';42"), 42)
  assert_eq(@moonjsonnet.evaluate("{assert true:error 'unused',a:42}"), {
    "a": 42,
  })
  for
    (source, expected) in [
      ("assert false;42", "Assertion failed"),
      ("{assert false,a:42}", "Object assertion failed."),
      ("error function() 42", "couldn't manifest function as JSON"),
      ("error [error 'nested']", "nested"),
    ] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_eq(d.message, expected)
    } noraise {
      _ => fail("expected conversion failure")
    }
  }
  let limits = @moonjsonnet.Limits::default()
  try
    @moonjsonnet.evaluate("error ['too long']", limits={
      ..limits,
      output_bytes: 2,
    })
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("conversion escaped output budget")
  }
}

///|
test "slice lowering preserves hidden standard alias and parameter laziness" {
  assert_eq(@moonjsonnet.evaluate("local std=null;[1,2][:]"), [1, 2])
  assert_eq(@moonjsonnet.evaluate("std.length([error 'unused'][0:1])"), 1)
  assert_eq(@moonjsonnet.evaluate("[1,error 'unused'][0:1]"), [1])
  try @moonjsonnet.evaluate("[error 'unused'][::0]") catch {
    @moonjsonnet.Error(d) =>
      assert_eq(d.message, "got 0 but step must be greater than 0")
  } noraise {
    _ => fail("zero step accepted")
  }
}

///|
test "cached generated calls retain closures and arguments across heap collection" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let reads = Ref(0)
  evaluator.set_importer(resolver=(_, _) => {
    reads.val += 1
    {
      id: "library",
      text: "local n=41;{a:std.makeArray(1,function(i)n+i),b:std.map(function(x)x+1,[41])}",
    }
  })
  for
    (source, expected) in [
      ("std.length((import 'library').a)", 1),
      ("(import 'library').a[0]", 41),
      ("std.length((import 'library').b)", 1),
      ("(import 'library').b[0]", 42),
    ] {
    assert_eq(
      evaluator.evaluate(@moonjsonnet.Program::parse(source)),
      Json::number(expected.to_double()),
    )
  }
  assert_eq(reads.val, 1)
}
