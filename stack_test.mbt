///|
fn stack_result(
  source : String,
  stack : Int,
) -> Json raise @moonjsonnet.JsonnetError {
  @moonjsonnet.evaluate(source, limits={
    ..@moonjsonnet.Limits::default(),
    stack,
  })
}

///|
fn stack_error(source : String, stack : Int) -> Unit raise {
  try stack_result(source, stack) catch {
    @moonjsonnet.Error(d) => {
      assert_eq(d.kind, @moonjsonnet.Limit)
      assert_eq(d.message, "max stack frames exceeded.")
    }
  } noraise {
    _ => fail("expected stack exhaustion: " + source)
  }
}

///|
test "runtime frames count lazy work and manifestation rather than AST nodes" {
  assert_eq(stack_result("1+2*3", 1), 7)
  assert_eq(stack_result("std.thisFile", 1), Json::string("<input>"))
  for
    (source, minimum, expected) in [
      ("local x=1; x+x", 2, Json::number(2)),
      ("local x=1,y=x; y", 3, Json::number(1)),
      ("[[1]]", 3, Json::array([Json::array([1])])),
      ("{local x=1,a:x}.a", 3, Json::number(1)),
      ("({a:1}+{a+:2}).a", 3, Json::number(3)),
      ("{a+:2}.a", 3, Json::number(2)),
      ("{assert (function() true)(),a:1}.a", 3, Json::number(1)),
      ("(function(x=1) x)()", 3, Json::number(1)),
      ("std.length('abc')", 2, Json::number(3)),
    ] {
    stack_error(source, minimum - 1)
    assert_eq(stack_result(source, minimum), expected)
  }
}

///|
test "tailstrict releases only trimmable runtime frames before forcing arguments" {
  let strict = "local f(n)=if n==0 then 42 else f(n-1) tailstrict; f(1000) tailstrict"
  stack_error(strict, 1)
  assert_eq(stack_result(strict, 2), 42)
  let normal = "local f(n)=if n==0 then 42 else f(n-1) tailstrict; f(1000)"
  stack_error(normal, 2)
  assert_eq(stack_result(normal, 3), 42)
  assert_eq(stack_result("1+(function(x) x)(1) tailstrict", 2), 2)
  let mixed = "local f(n)=if n==0 then 42 else f(n-1); f(3) tailstrict"
  stack_error(mixed, 4)
  assert_eq(stack_result(mixed, 5), 42)
  // Sibling work must observe the released function frame, even after the
  // strict function tail-calls a builtin or a normal closure.
  assert_eq(
    stack_result(
      "((function() std.length([]))() tailstrict)+(function() 1)()", 2,
    ),
    1,
  )
  assert_eq(
    stack_result(
      "((function() (function() 1)())() tailstrict)+(function() 1)()", 2,
    ),
    2,
  )
}

///|
test "imports and code parameters consume frames but ready strings do not" {
  let limits = { ..@moonjsonnet.Limits::default(), stack: 1, }
  assert_eq(
    @moonjsonnet.evaluate(
      "function(x) x",
      tla_vars=Map([("x", Json::string("ready"))]),
      limits~,
    ),
    Json::string("ready"),
  )
  for source in ["import 'one'", "function(x) x"] {
    try
      @moonjsonnet.evaluate(source, limits~, tla_code=Map([("x", "1")]), resolver=fn(
        _,
        path,
      ) {
        { id: path, text: "1", }
      })
    catch {
      @moonjsonnet.Error(d) =>
        assert_eq(d.message, "max stack frames exceeded.")
    } noraise {
      _ => fail("expected a lazy frame")
    }
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "local x=import 'one'; x+x",
      limits={ ..limits, stack: 3, },
      resolver=fn(_, path) { { id: path, text: "1", } },
    ),
    2,
  )
  assert_eq(
    @moonjsonnet.evaluate("importstr 'one'", limits~, resolver=fn(_, path) {
      { id: path, text: "ready", }
    }),
    Json::string("ready"),
  )
}

///|
test "stack validation and output modes retain independent budgets" {
  let limits = @moonjsonnet.Limits::default()
  assert_eq(limits.stack, 500)
  for stack in [0, -1] {
    try @moonjsonnet.evaluate("1", limits={ ..limits, stack, }) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
    } noraise {
      _ => fail("expected invalid limits")
    }
  }
  assert_eq(
    @moonjsonnet.evaluate_text("'x'", string_output=true, limits={
      ..limits,
      stack: 1,
    }),
    "x\n",
  )
  assert_eq(
    @moonjsonnet.evaluate_stream("[1]", limits={ ..limits, stack: 2, }),
    ["1\n"],
  )
  assert_eq(
    @moonjsonnet.evaluate_multi("{a:1}", limits={ ..limits, stack: 2, })["a"],
    "1\n",
  )
  try
    @moonjsonnet.evaluate("local f(n)=f(n+1); f(0)", limits={
      ..limits,
      stack: 2147483647,
      depth: 20,
    })
  catch {
    @moonjsonnet.Error(d) => {
      assert_eq(d.kind, @moonjsonnet.Limit)
      assert_eq(d.message, "evaluation depth limit exceeded")
    }
  } noraise {
    _ => fail("expected independent depth limit")
  }
}
