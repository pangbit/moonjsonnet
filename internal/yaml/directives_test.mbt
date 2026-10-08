///|
test "legal version and multiple distinct tag directives retain their declarations" {
  let parser = @yaml.Parser::new(
    "%YAML 1.1\n%TAG !a! tag:example.com,2026:\n%TAG !b! tag:other.com,2026:\n---\n[!a!foo x, !b!bar y]",
  )
  let tags : Array[(String, String)] = []
  while true {
    let (event, _) = parser.next_token()
    match event {
      @yaml.Scalar(tag=Some(tag), ..) => tags.push((tag.handle, tag.suffix))
      @yaml.StreamEnd => break
      _ => ()
    }
  }
  assert_eq(tags, [
    ("tag:example.com,2026:", "foo"),
    ("tag:other.com,2026:", "bar"),
  ])
}
