///|
fn main raise {
  let root = "examples/embedded/config"
  let valid = @fs.evaluate_file(
    "main.jsonnet",
    root~,
    ext_vars=Map([("replicas", Json::number(3))]),
  )
  println(valid.stringify())
  for
    (value, expected) in [
      (Json::string("bad"), "replicas must be numeric"),
      (Json::number(0), "replicas out of range"),
    ] {
    try
      @fs.evaluate_file(
        "main.jsonnet",
        root~,
        ext_vars=Map([("replicas", value)]),
      )
    catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Assertion)
        assert_eq(d.message, expected)
        println(d.to_string())
      }
    } noraise {
      _ => fail("expected invalid parameter rejection")
    }
  }
  let host = @fs.FileHost::new(root)
  try host.resolve("", "../../../moon.mod") catch {
    @moonjsonnet.Error(d) => {
      assert_eq(d.kind, @moonjsonnet.Import)
      println(d.to_string())
    }
  } noraise {
    _ => fail("expected root escape rejection")
  }
}
