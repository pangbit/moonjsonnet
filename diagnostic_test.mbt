///|
test "context cropping keeps both ends and leaves diagnostics intact" {
  let context : Array[@moonjsonnet.Location] = [
    { file: "inner", line: 2, column: 3, },
    { file: "middle1", line: 4, column: 5, },
    { file: "middle2", line: 6, column: 7, },
    { file: "outer", line: 8, column: 9, },
  ]
  let d : @moonjsonnet.Diagnostic = {
    kind: @moonjsonnet.Runtime,
    message: "é😀\u0000\nfailed",
    location: { file: "origin", line: 1, column: 2, },
    context,
    trace: [],
  }
  let header = "origin:1:2: Runtime: é😀\u0000\nfailed"
  let full = header +
    "\n  at inner:2:3\n  at middle1:4:5\n  at middle2:6:7\n  at outer:8:9"
  assert_eq(d.to_string(), full)
  for limit in [0, -1, 4, 5, 2147483647] {
    assert_eq(d.format(max_trace=limit), full)
  }
  assert_eq(d.format(max_trace=1), header + "\n  ...\n  at outer:8:9")
  assert_eq(
    d.format(max_trace=2),
    header + "\n  at inner:2:3\n  ...\n  at outer:8:9",
  )
  assert_eq(
    d.format(max_trace=3),
    header + "\n  at inner:2:3\n  ...\n  at middle2:6:7\n  at outer:8:9",
  )
  assert_eq(d.context.length(), 4)
  assert_eq(d.to_string(), full)
  assert_eq({ ..d, context: [], }.format(max_trace=1), header)
}

///|
test "evaluation context is retained after rendering" {
  try
    @moonjsonnet.evaluate(
      "local f(x)=if x==0 then error 'failure' else f(x-1); f(8)",
    )
  catch {
    @moonjsonnet.Error(d) => {
      assert_eq(d.kind, @moonjsonnet.Runtime)
      assert_eq(d.context.length(), 9)
      let full = d.to_string()
      assert_true(d.format(max_trace=3).contains("\n  ..."))
      assert_eq(d.context.length(), 9)
      assert_eq(d.format(), full)
    }
  } noraise {
    _ => fail("expected runtime diagnostic")
  }
}
