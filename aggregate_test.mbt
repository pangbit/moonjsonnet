///|
test "sum and avg preserve left to right addition and finite numeric results" {
  for
    (source, expected) in [
      (
        "[std.sum([]),std.sum([1,2,3]),std.avg(arr=[1,2,3]),std.sum([1e16,1,-1e16])]",
        "[0,6,2,0]",
      ),
      (
        "[std.length(std.sum),std.length(std.avg),std.objectHas(std,'sum')]", "[1,1,false]",
      ),
      ("std.sum(std.range(1,1000))", "500500"),
      ("std.sum([1,'2'])", "\"12\""),
      ("std.sum('123')", "\"0123\""),
    ] {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
  for
    source in [
      "std.avg([])", "std.avg({})", "std.sum([true])", "std.avg([null])", "std.sum([1,error 'forced'])",
      "std.sum()", "std.avg(xs=[1])",
    ] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_true(d.kind != @moonjsonnet.Unsupported)
    } noraise {
      _ => fail("expected error: " + source)
    }
  }
  let limits = @moonjsonnet.Limits::default()
  try
    @moonjsonnet.evaluate("std.sum(std.makeArray(10000,function(i)i))", limits={
      ..limits,
      steps: 1000,
    })
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected step limit")
  }
}

// Frozen Go nonfinite outputs remain in tests/go-differential.json and the
// historical aggregate report. They are compatibility evidence, not permitted
// Jsonnet numbers. Normative overflow and lazy cases live in spec_aggregate_test.mbt.

///|
test "aggregate failure is diagnosed before downstream consumers" {
  for expr in ["std.type(x)", "std.toString(x)", "x > 0", "[1][x]"] {
    try @moonjsonnet.evaluate("local x=std.sum([1e308,1e308]); " + expr) catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Runtime)
        assert_eq(d.message, "Overflow")
      }
    } noraise {
      _ => fail("expected overflow before consumer: " + expr)
    }
  }
}
