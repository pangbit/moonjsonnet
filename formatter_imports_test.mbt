///|
test "formatter import sorting uses raw UTF-8 lexical keys and preserves groups" {
  assert_eq(
    @moonjsonnet.format_source(
      "local z=import 'z';local a=import 'aaa-long';[z,a]",
    ),
    "local a = import 'aaa-long';\nlocal z = import 'z';\n[z, a]\n",
  )
  assert_eq(
    @moonjsonnet.format_source(
      "local x=import '\u{10000}';local y=import '\u{e000}';[x,y]",
    ),
    "local y = import '\u{e000}';\nlocal x = import '\u{10000}';\n[x, y]\n",
  )
  let source = "local z=import 'z';\n\nlocal a=import 'a';[z,a]"
  assert_eq(
    @moonjsonnet.format_source(source),
    "local z = import 'z';\n\nlocal a = import 'a';\n[z, a]\n",
  )
  assert_eq(
    @moonjsonnet.format_source(
      "local a=import 'z';local b=import 'b';local a=import 'a';[a,b]",
    ),
    "local a = import 'z';\nlocal b = import 'b';\nlocal a = import 'a';\n[a, b]\n",
  )
}

///|
test "formatter sorted imports retain values and lazy import request order" {
  for
    source in [
      "local z=import 'z',a=import 'a';[z,a]", "local z=import 'z'; // z\nlocal a=import 'a'; // a\n[z,a]",
      "local a=import 'z';local a=import 'a';a", "local z=import 'z';local unused=import 'a';z",
      "local z=import 'z';local a=import 'a',v=1;[z,a,v]",
    ] {
    let original_requests : Array[String] = []
    let formatted_requests : Array[String] = []
    let original = @moonjsonnet.evaluate(source, resolver=fn(_, path) {
      original_requests.push(path)
      { id: path, text: Json::string(path).stringify(), }
    })
    let formatted = @moonjsonnet.format_source(source)
    let actual = @moonjsonnet.evaluate(formatted, resolver=fn(_, path) {
      formatted_requests.push(path)
      { id: path, text: Json::string(path).stringify(), }
    })
    assert_eq(actual, original)
    assert_eq(formatted_requests, original_requests)
    assert_eq(@moonjsonnet.format_source(formatted), formatted)
  }
}

///|
test "formatter import switch source isolation and reference non-idempotence" {
  let source = "local z=import 'z',a=import 'a';[z,a]"
  let document = @moonjsonnet.ParsedSource::parse(source)
  let options = {
    ..@moonjsonnet.FormatOptions::default(),
    sort_imports: false,
  }
  assert_eq(
    document.format(options~),
    "local z = import 'z', a = import 'a'; [z, a]\n",
  )
  assert_eq(
    document.format(),
    "local a = import 'a';\nlocal z = import 'z';\n[z, a]\n",
  )
  assert_eq(document.text(), source)
  let first = @moonjsonnet.format_source(
    "local x=import '\\u0062';local y=import 'a';[x,y]",
  )
  assert_eq(first, "local x = import 'b';\nlocal y = import 'a';\n[x, y]\n")
  assert_eq(
    @moonjsonnet.format_source(first),
    "local y = import 'a';\nlocal x = import 'b';\n[x, y]\n",
  )
}
