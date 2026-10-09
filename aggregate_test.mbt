///|
test "sum and avg are numeric eager left to right aggregates" {
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
    ] {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
  for
    source in [
      "std.avg([])", "std.sum('123')", "std.avg({})", "std.sum([1,'2'])", "std.sum([true])",
      "std.avg([null])", "std.sum([1,error 'forced'])", "std.sum()", "std.avg(xs=[1])",
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

///|
test "aggregate nonfinite results propagate and retain Go scalar spellings" {
  let prefix = "local inf=std.sum([1e308,1e308]); local nan=std.sum([inf,-inf]); "
  assert_eq(
    @moonjsonnet.evaluate(prefix + "[nan,inf]").stringify(),
    "[NaN,+Inf]",
  )
  for
    (expr, expected) in [
      (
        "[std.type(inf),std.type(nan),std.avg([inf])>1e308]", "[\"number\",\"number\",true]",
      ),
      (
        "[std.toString(inf),std.toString(-inf),std.toString(nan),std.manifestJson(nan)]",
        "[\"+Inf\",\"-Inf\",\"NaN\",\"NaN\"]",
      ),
      (
        "[nan<1,nan>1,nan<=1,nan>=1,nan==nan,inf>1,-inf<0]", "[false,false,true,true,false,true,true]",
      ),
      (
        "[[nan]<[1],[nan]>[1],std.primitiveEquals(nan,nan),std.equals(nan,nan)]",
        "[false,false,false,false]",
      ),
      (
        "[std.toString(+inf),std.toString(-nan),std.toString(std.abs(-0)),std.toString(std.abs(inf)),std.toString(std.abs(nan))]",
        "[\"+Inf\",\"NaN\",\"0\",\"+Inf\",\"NaN\"]",
      ),
      ("'%s' % inf", "\"+Inf\""),
      ("std.slice([1,2],nan,null,null)", "[]"),
      ("std.slice([],null,null,nan)", "[]"),
    ] {
    assert_eq(@moonjsonnet.evaluate(prefix + expr), @json.parse(expected))
  }
  for (expr, expected) in [("inf", "+Inf"), ("-inf", "-Inf"), ("nan", "NaN")] {
    assert_eq(@moonjsonnet.evaluate(prefix + expr).stringify(), expected)
  }
  let (source, expected) = if @number.reference_amd64() {
    (
      "[nan&1,~nan,std.char(nan),'%c'%nan]", "[0,9223372036854775808,\"�\",\"�\"]",
    )
  } else {
    (
      "[[1][nan],nan&1,~nan,std.char(nan),'%c'%nan]", "[1,0,-1,\"\\u0000\",\"\\u0000\"]",
    )
  }
  assert_eq(@moonjsonnet.evaluate(prefix + source), @json.parse(expected))
}

///|
test "NaN index diagnostics retain the native Go integer conversion" {
  let prefix = "local inf=std.sum([1e308,1e308]); local nan=std.sum([inf,-inf]); "
  if @number.reference_amd64() {
    try @moonjsonnet.evaluate(prefix + "[1][nan]") catch {
      @moonjsonnet.Error(d) =>
        assert_eq(
          d.message,
          "Index -9223372036854775808 out of bounds, not within [0, 1)",
        )
    } noraise {
      _ => fail("expected amd64 NaN index error")
    }
  } else {
    assert_eq(@moonjsonnet.evaluate(prefix + "[1][nan]"), @json.parse("1"))
  }
  try @moonjsonnet.evaluate(prefix + "[][nan]") catch {
    @moonjsonnet.Error(d) =>
      assert_eq(
        d.message,
        if @number.reference_amd64() {
          "Index -9223372036854775808 out of bounds, not within [0, 0)"
        } else {
          "Index 0 out of bounds, not within [0, 0)"
        },
      )
  } noraise {
    _ => fail("expected empty NaN index error")
  }
}

///|
test "nonfinite format arithmetic and bounded conversions terminate with errors" {
  let prefix = "local inf=std.sum([1e308,1e308]); local nan=std.sum([inf,-inf]); "
  for
    expr in [
      "inf+1", "inf-inf", "nan*0", "std.floor(inf)", "std.ceil(nan)", "[1][inf]",
      "[][nan]", "inf&1", "std.makeArray(nan,function(i)i)", "'%d'%inf", "'%f'%inf",
      "'%g'%inf", "'%d'%nan", "'%f'%nan", "'%*s'%[nan,'x']", "'%.*f'%[nan,1]", "std.slice([1,2],null,null,nan)",
      "std.slice([1,2],null,null,inf)", "std.slice([1,2],-inf,null,null)", "std.slice([1,2],null,-inf,null)",
    ] {
    try @moonjsonnet.evaluate(prefix + expr) catch {
      @moonjsonnet.Error(d) => assert_true(d.kind != @moonjsonnet.Unsupported)
    } noraise {
      _ => fail("expected error: " + expr)
    }
  }
}
