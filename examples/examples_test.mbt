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
