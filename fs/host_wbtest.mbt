///|
test "canonical aliases share the host source cache" {
  let host = FileHost::new("examples/environments")
  let first = host.resolve("", "template.libsonnet")
  let second = host.resolve("", "../environments/./template.libsonnet")
  assert_eq(first.id, second.id)
  assert_eq(host.cache.length(), 1)
  let binary = host.resolve_binary("", "./template.libsonnet")
  assert_eq(binary.id, first.id)
  assert_eq(@utf8.decode(binary.bytes), first.text)
  assert_eq(host.binary_cache.length(), 1)
}
