///|
test "fractional precision follows Go power evaluation" {
  assert_eq(
    @moonjsonnet.evaluate(
      "['%.*f'%[1.5,1.25],'%.*e'%[1.5,12.5],'%.*g'%[1.5,12.5]]",
    ),
    @json.parse(
      "[\"1.8.3772233983162003\",\"1.8.3772233983162003e+01\",\"14.0.20526680779794471\"]",
    ),
  )
}

///|
test "fractional precision covers signed halves and rounded integral parts" {
  assert_eq(
    @moonjsonnet.evaluate(
      "['%.*f'%[p,1.25] for p in [-1.5,-0.5,0.25,0.5,0.75,1.25,1.75,2.5,3.75]]",
    ),
    @json.parse(
      "[\"17.0\",\"2.0\",\"1.0.22172058996107702\",\"1.0.83772233983162048\",\"1.1.3765867480965088\",\"1.4.2172058996107715\",\"1.13.7658674809650918\",\"1.78.772233983161982\",\"1.1405.5867480965089271\"]",
    ),
  )
}

///|
test "fractional precision retains arithmetic and output limits" {
  for p in ["309.5", "-324.5"] {
    try @moonjsonnet.evaluate("'%.*f'%[\{p},1]") catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
    } noraise {
      _ => fail("expected non-finite format arithmetic error")
    }
  }
  let limits = @moonjsonnet.Limits::default()
  try
    @moonjsonnet.evaluate("'%.*f'%[1.5,1.25]", limits={
      ..limits,
      output_bytes: 10,
    })
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected formatted output limit")
  }
}
