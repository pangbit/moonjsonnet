///|
test "language syntax and lazy slices" {
  assert_eq(
    @moonjsonnet.evaluate("[0,error 'unused',2][::2]").stringify(),
    "[0,2]",
  )
  assert_eq(
    @moonjsonnet.evaluate("'a你😀b'[1:-1]").stringify(),
    "\"你😀\"",
  )
  assert_eq(
    @moonjsonnet.evaluate("[~0,5&3,5|2,5^3,1<<40,-8>>2]").stringify(),
    "[-1,1,7,6,1099511627776,-2]",
  )
  assert_eq(@moonjsonnet.evaluate("[[1],[2]] < [[1],[3]]").stringify(), "true")
  assert_eq(
    @moonjsonnet.evaluate("|||-\n  first\n    second\n|||").stringify(),
    "\"first\\n  second\"",
  )
  assert_eq(
    @moonjsonnet.evaluate("'\\u0041\\ud83d\\ude00'").stringify(),
    "\"A😀\"",
  )
}

///|
test "object comprehension locals bind loop variables and final self" {
  let result = @moonjsonnet.evaluate(
    "({n:1}+{local f()=self.n+x,[x]:f(),local y=error 'unused' for x in ['a','b']})+{n:2}",
  )
  assert_eq(result, { "n": 2, "a": "2a", "b": "2b" })
}

///|
test "tailstrict trampoline forces parameters including defaults" {
  assert_eq(
    @moonjsonnet.evaluate(
      "local sum(n,a)=if n==0 then a else sum(n-1,a+n) tailstrict; sum(10000,0)",
    ).stringify(),
    "50005000",
  )
  for
    source in [
      "(function(x)1)(error 'forced') tailstrict", "(function(x=error 'forced')1)() tailstrict",
    ] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_true(d.kind is @moonjsonnet.Runtime)
    } noraise {
      _ => fail("strict argument was not forced")
    }
  }
}

///|
test "formatting conversions and ordinary std object" {
  assert_eq(
    @moonjsonnet.evaluate("'%.*s' % [error 'unused',42]").stringify(),
    "\"42\"",
  )
  assert_eq(
    @moonjsonnet.evaluate("'%#08x|%*.*f|%c' % [255,8,2,1.25,128512]").stringify(),
    "\"0x0000ff|    1.25|😀\"",
  )
  assert_eq(
    @moonjsonnet.evaluate("'%(x)s' % {x:'ok',unused:error 'unused'}").stringify(),
    "\"ok\"",
  )
  assert_eq(
    @moonjsonnet.evaluate(
      "[std, std.length(std), (std+{type(x):super.type(x)+'!'}).type(1)]",
    ).stringify(),
    "[{},0,\"number!\"]",
  )
  assert_eq(
    @moonjsonnet.evaluate("std.thisFile", filename="entry.jsonnet").stringify(),
    "\"entry.jsonnet\"",
  )
}

///|
test "binary import is byte preserving and memoized by canonical identity" {
  let mut reads = 0
  let result = @moonjsonnet.evaluate("[importbin 'data', importbin 'data']", binary_resolver=fn(
    _,
    _,
  ) {
    reads += 1
    { id: "data", bytes: b"\x00\xff\xfe\x80", }
  })
  assert_eq(reads, 1)
  assert_eq(result.stringify(), "[[0,255,254,128],[0,255,254,128]]")
}
