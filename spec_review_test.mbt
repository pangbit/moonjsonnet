// Independent boundary review of the P0 fixes. All inputs are synthetic.

///|
test "finite numbers fail at their producing expression before type inspection" {
  for
    source in [
      "std.type(1.7976931348623159e308)", "std.type(1e308 * 1e308)", "std.type(std.pow(1e308,2))",
      "std.type(std.hypot(1.7e308,1.7e308))", "std.type(std.parseJson('1e309'))",
      "std.type(std.parseYaml('.inf'))", "std.type(std.parseYaml('.nan'))", "std.type(std.avg([1e308,1e308,-1e308]))",
    ] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
    } noraise {
      _ => fail("nonfinite producer returned a value: " + source)
    }
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "[(function(unused)42)(std.sum([1e308,1e308])),std.type(1.7976931348623157e308),std.hypot(1e308,1e308)<1.5e308]",
    ),
    [42, "number", true],
  )
  for number in [1.0 / 0.0, 0.0 / 0.0] {
    let callback : @moonjsonnet.NativeFunction = {
      params: [],
      callback: _ => Json::number(number),
    }
    try
      @moonjsonnet.evaluate(
        "std.type(std.native('bad')())",
        native_functions=Map([("bad", callback)]),
      )
    catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
    } noraise {
      _ => fail("native result escaped finite validation")
    }
  }
}

///|
test "deletion shares cached payloads without forcing removed or retained errors" {
  let mut calls = 0
  let once : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      calls += 1
      42
    },
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "local a=[std.native('once')(),error 'removed',3]; local b=std.removeAt(a,1); [std.length(b),b[0],a[0],a[2]]",
      native_functions=Map([("once", once)]),
    ),
    [2, 42, 42, 3],
  )
  assert_eq(calls, 1)
  assert_eq(
    @moonjsonnet.evaluate(
      "local a=[error 'removed',error 'retained']; local b=std.removeAt(a,0); [std.length(b),std.removeAt(b,0),std.length(a)]",
    ),
    [1, [], 2],
  )
}

///|
test "Unicode codepoint and slice boundaries retain exact error timing" {
  assert_eq(
    @moonjsonnet.evaluate(
      "local s='😀e\\u0301\\u0000'; [std.length(s),s[0],s[1],s[2],std.codepoint(s[3]),s[0:3:2]]",
    ),
    [4, "😀", "e", "́", 0, "😀́"],
  )
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.length([error 'payload',2,3][0.5::1]),[7,error 'payload'][::0.5][0],'😀e\\u0301'[0:2.5]]",
    ),
    [3, 7, "😀é"],
  )
  try @moonjsonnet.evaluate("[error 'payload',2,3][0.5::1][0]") catch {
    @moonjsonnet.Error(d) => {
      assert_eq(d.kind, @moonjsonnet.Runtime)
      assert_eq(d.message, "Index must be a finite integer")
    }
  } noraise {
    _ => fail("expected index validation before payload")
  }
  for source in ["'😀'[1]", "''[0]", "'😀e\\u0301'[-0.1:]"] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
    } noraise {
      _ => fail("invalid Unicode index succeeded: " + source)
    }
  }
}

///|
test "YAML propagates runtime type assertion errors and leaves evaluator usable" {
  let evaluator = @moonjsonnet.Evaluator::new()
  for
    (source, kind) in [
      (
        "std.manifestYamlDoc({a:[{b:[error 'first']}],z:error 'later'})",
        @moonjsonnet.Runtime,
      ),
      ("std.manifestYamlDoc({a:[std.sum(null)],z:0})", @moonjsonnet.Type),
      (
        "std.manifestYamlDoc({a:{assert false,b:1},z:error 'later'})",
        @moonjsonnet.Assertion,
      ),
      ("std.manifestYamlDoc({a:[std.manifestYamlDoc]})", @moonjsonnet.Runtime),
    ] {
    try evaluator.evaluate(@moonjsonnet.Program::parse(source)) catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, kind)
        assert_true(d.message != "later")
      }
    } noraise {
      _ => fail("YAML returned partial success: " + source)
    }
    assert_eq(evaluator.evaluate(@moonjsonnet.Program::parse("42")), 42)
  }
  // String summation is valid. The original input now has only its z error.
  try
    evaluator.evaluate(
      @moonjsonnet.Program::parse(
        "std.manifestYamlDoc({a:[std.sum('not-array')],z:error 'later'})",
      ),
    )
  catch {
    @moonjsonnet.Error(d) => {
      assert_eq(d.kind, @moonjsonnet.Runtime)
      assert_eq(d.message, "later")
    }
  } noraise {
    _ => fail("expected the original later field error after valid String sum")
  }
  assert_eq(evaluator.evaluate(@moonjsonnet.Program::parse("42")), 42)
  assert_eq(
    evaluator.evaluate(
      @moonjsonnet.Program::parse(
        "std.manifestYamlDoc({hidden::function()error 'unused'})",
      ),
    ),
    Json::string("{}"),
  )
}
