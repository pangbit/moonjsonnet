///|
test "complete examples match fixed expected JSON" {
  let host = @fs.FileHost::new(".")
  for dir in ["environments", "dashboards"] {
    let path = "examples/\{dir}"
    let expected = @json.parse(host.resolve("", path + "/expected.json").text)
    let actual = @fs.evaluate_file(path + "/main.jsonnet")
    assert_eq(actual, expected)
  }
  let config = @fs.evaluate_file(
    "examples/embedded/config/main.jsonnet",
    ext_vars=Map([("replicas", Json::number(3))]),
  )
  assert_eq(
    config,
    @json.parse(
      "{\"app\":\"checkout\",\"port\":8080,\"retries\":3,\"replicas\":3}",
    ),
  )
}

///|
test "embedded config rejects invalid parameters and limits with source diagnostics" {
  for
    (variables, limits, kind) in [
      (Map([]), @moonjsonnet.Limits::default(), @moonjsonnet.Runtime),
      (
        Map([("replicas", Json::string("bad"))]),
        @moonjsonnet.Limits::default(),
        @moonjsonnet.Assertion,
      ),
      (
        Map([("replicas", Json::number(0))]),
        @moonjsonnet.Limits::default(),
        @moonjsonnet.Assertion,
      ),
      (
        Map([("replicas", Json::number(3))]),
        { ..@moonjsonnet.Limits::default(), steps: 1, },
        @moonjsonnet.Limit,
      ),
    ] {
    try
      @fs.evaluate_file(
        "main.jsonnet",
        root="examples/embedded/config",
        ext_vars=variables,
        limits~,
      )
    catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, kind)
        assert_true(!d.location.file.is_empty())
        assert_true(d.location.line > 0 && d.location.column > 0)
        // A one-step budget can expire during standard-library setup, before
        // the entry program or its call context exists.
        if kind != @moonjsonnet.Limit {
          assert_true(d.location.file.has_suffix("main.jsonnet"))
          assert_true(!d.context.is_empty() || !d.trace.is_empty())
        }
      }
    } noraise {
      _ => fail("embedded config accepted invalid input")
    }
  }
  let host = @fs.FileHost::new("examples/embedded/config")
  try host.resolve("", "../../../moon.mod") catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Import)
  } noraise {
    _ => fail("embedded host accepted root escape")
  }
}
