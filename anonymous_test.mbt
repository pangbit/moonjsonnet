///|
test "anonymous snippets use diagnostic names and empty import origins" {
  let requests : Array[(String, String)] = []
  let trace : Array[(@moonjsonnet.Location, String)] = []
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.thisFile, std.extVar('x'),std.trace('entry',import 'lib')]",
      filename="<cmdline>",
      anonymous=true,
      ext_code=Map([("x", "std.thisFile")]),
      resolver=fn(from, path) {
        requests.push((from, path))
        { id: "lib.jsonnet", text: "std.thisFile", }
      },
      trace=fn(loc, s) { trace.push((loc, s)) },
    ),
    ["", "<extvar:x>", "lib.jsonnet"],
  )
  assert_eq(requests, [("", "lib")])
  assert_eq(trace[0].0.file, "<cmdline>")
  try
    @moonjsonnet.evaluate("\nmissing", filename="<stdin>", anonymous=true)
  catch {
    @moonjsonnet.Error(d) => {
      assert_eq(d.kind, @moonjsonnet.Static)
      assert_eq(d.location.file, "<stdin>")
      assert_eq(d.location.line, 2)
    }
  } noraise {
    _ => fail("expected diagnostic source name")
  }
}
