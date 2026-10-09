///|
test "numeric indices truncate toward zero before bounds checks" {
  let cases = [
    ("[10,20,30][-0.9]", "10"),
    ("[10,20,30][1.9]", "20"),
    ("'你😀a'[1.9]", "\"😀\""),
    ("[1,error 'unused'][0.9]", "1"),
    ("'你😀a'[-0.9]", "\"你\""),
  ]
  for (source, expected) in cases {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
}

///|
test "fractional slices retain fractional progression and lazy elements" {
  let cases = [
    ("[0,1,2][0.5:2.5:0.5]", "[0,1,1,2]"),
    ("[0,1,2][-0.5:]", "[2]"),
    ("[0,1,2][:1.5]", "[0,1]"),
    ("'你😀a'[0.5:2.5:0.5]", "\"你😀😀a\""),
    ("std.slice([0,1,2],0.5,2.5,0.5)", "[0,1,1,2]"),
    ("[0,error 'unused',2][0.5::2]", "[0,2]"),
  ]
  for (source, expected) in cases {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
}

///|
test "bitwise operands use signed 64 bit conversion" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[9223372036854775808&1,9223372036854775808>>1,1<<9223372036854775808,~9223372036854775808,~1e100,~-1e100]",
    ),
    @json.parse(
      if @number.reference_amd64() {
        "[0,-4611686018427387904,1,9223372036854775808,9223372036854775808,9223372036854775808]"
      } else {
        "[1,4611686018427387904,-9223372036854775808,-9223372036854775808,-9223372036854775808,9223372036854775808]"
      },
    ),
  )
  assert_eq(
    @moonjsonnet.evaluate(
      "[9007199254740994&3,1e16>>2,-1e16>>2,3.9&1,-3.9&1,9223372036854774784|1,-9223372036854775808&1]",
    ),
    @json.parse(
      "[2,2500000000000000,-2500000000000000,1,1,9223372036854774784,0]",
    ),
  )
}

///|
test "shifts wrap at 64 bits and reduce the count modulo 64" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[2<<62,1<<63,-1<<63,-9223372036854775808<<1,-9223372036854775808>>63,1<<64,1<<65,-8>>65,1<<0.9,1<<9007199254740994]",
    ),
    @json.parse(
      "[-9223372036854775808,-9223372036854775808,-9223372036854775808,0,-1,1,2,-4,1,4]",
    ),
  )
}

///|
test "numeric conversion rejects invalid bounds before native conversion" {
  let cases = [
    ("[1][-1.1]", @moonjsonnet.Runtime),
    ("[1][1.1]", @moonjsonnet.Runtime),
    ("[1][1e300]", @moonjsonnet.Runtime),
    ("[1][-1e300]", @moonjsonnet.Runtime),
    ("[][0.5]", @moonjsonnet.Runtime),
    ("[1][true]", @moonjsonnet.Type),
    ("{x:1}[0.5]", @moonjsonnet.Type),
    ("std.makeArray(1.5,function(i)i)", @moonjsonnet.Runtime),
    ("9223372036854777856&1", @moonjsonnet.Runtime),
    ("-9223372036854777856|1", @moonjsonnet.Runtime),
    ("1|9223372036854777856", @moonjsonnet.Runtime),
    ("1<<-0.1", @moonjsonnet.Runtime),
    ("1&true", @moonjsonnet.Type),
  ]
  for (source, kind) in cases {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, kind)
    } noraise {
      _ => fail("expected error: \{source}")
    }
  }
}

///|
test "small positive slice steps remain bounded by the step budget" {
  let limits = @moonjsonnet.Limits::default()
  try
    @moonjsonnet.evaluate("[0,1][::0.000001]", limits={ ..limits, steps: 100, })
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected slice step limit")
  }
}
