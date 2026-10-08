///|
test "formatter nested expression contexts preserve values and retained source" {
  let options = @moonjsonnet.FormatOptions::default()
  let sources = [
    "local f(x)=\nif x then\n1\nelse\n2;f(true)", "local y=1,z=2,\nx=3;[y,z,x]",
    "local\ny=1,z=2;[y,z]", "local a=local b=1,\nc=2;b+c,\nd=3;a+d", "{\nlocal f(\nx,y)= {\nx:x\n},v:f(1,2)\n}",
    "{x:[\n1\n]+(\nif true then [] else [\n2\n]\n)+[\n3\n]}", "{\nx:(\n'lol'\n),y:(1\n+2)+(\n3\n)\n}",
    "[\n[1,2 // before comma\n,3],(1+\n2),\n(\n3\n)\n]", "{\nx:if true then\n1\nelse\n2\n,\n}",
    "[1 // before comma\n,\n// closing\n]", "{\nassert true:\n'ok',x:1\n}", "[0,1,2][1:\n2]\n",
  ]
  for source in sources {
    let document = @moonjsonnet.ParsedSource::parse(source)
    let expected = @moonjsonnet.evaluate(source)
    for
      style in [
        options,
        { ..options, indent: 4, },
        { ..options, indent: 0, },
        { ..options, pad_arrays: true, pad_objects: false, },
        { ..options, strip_comments: true, },
      ] {
      let actual = document.format(options=style)
      assert_eq(@moonjsonnet.evaluate(actual), expected)
      assert_eq(@moonjsonnet.format_source(actual, options=style), actual)
      assert_eq(document.text(), source)
    }
  }
}

///|
test "formatter comma fodder remains attached to its closing delimiter" {
  let source = "[1 // before comma\n,\n// closing\n]"
  assert_eq(
    @moonjsonnet.format_source(source),
    "[\n  1,  // before comma\n  // closing\n]\n",
  )
  assert_eq(
    @moonjsonnet.format_source(source, options={
      ..@moonjsonnet.FormatOptions::default(),
      strip_all_but_comments: true,
    }),
    "// closing\nnull\n",
  )
}

///|
test "formatter expression planning is bounded by the shared step budget" {
  let source = Array::make(80, "1").join("+")
  ignore(@moonjsonnet.format_source(source))
  try
    @moonjsonnet.format_source(source, limits={
      ..@moonjsonnet.Limits::default(),
      steps: 100,
    })
  catch {
    @moonjsonnet.Error(d) => {
      assert_eq(d.kind, @moonjsonnet.Limit)
      assert_eq(d.message, "format step limit exceeded")
    }
  } noraise {
    _ => fail("expected bounded indentation planning")
  }
}
