///|
test "canonical aliases share the host source cache" {
  let host = FileHost::new("examples/environments")
  let first = host.resolve("", "template.libsonnet")
  let second = host.resolve("", "../environments/./template.libsonnet")
  assert_eq(first.id, second.id)
  assert_eq(host.cache.length(), 1)
}
