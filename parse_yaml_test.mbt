///|
fn parse_yaml_test(
  source : String,
  limits? : @moonjsonnet.Limits = @moonjsonnet.Limits::default(),
) -> Json raise @moonjsonnet.JsonnetError {
  @moonjsonnet.evaluate(
    "std.parseYaml(str=" + Json::string(source).stringify() + ")",
    limits~,
  )
}

///|
test "parseYaml YAML 1.1 scalars and recursive collections" {
  assert_eq(
    parse_yaml_test("!<tag:example.com,%C0%80> value"),
    Json::string("value"),
  )
  assert_eq(parse_yaml_test("!<tag:yaml.org,2002:int> '012'"), 10)
  assert_eq(
    parse_yaml_test("!<tag:example.com,%E4%B8%AD> value"),
    Json::string("value"),
  )
  assert_eq(parse_yaml_test("\ufeffa: 1\u0085b: 2"), { "a": 1, "b": 2 })
  assert_eq(
    parse_yaml_test("{a: [YES,off,~,012,08,0xFF], b: 'true', c: é😀}"),
    { "a": [true, false, null, 10, 8, 255], "b": "true", "c": "é😀" },
  )
  assert_eq(
    parse_yaml_test(
      "[9223372036854775807,18446744073709551615,-9223372036854775808]",
    ),
    [9223372036854775807.0, 18446744073709551615.0, -9223372036854775808.0],
  )
  assert_eq(
    parse_yaml_test("literal: |\n  one\n  two\nfolded: >-\n  one\n  two\n"),
    { "literal": "one\ntwo\n", "folded": "one two" },
  )
  assert_eq(parse_yaml_test("{a: [1,2],e:}"), { "a": [1, 2], "e:": null })
  assert_eq(
    parse_yaml_test(
      "[!!int '012',!!str 12,!!bool 'yes',!!float '12',!custom 3]",
    ),
    [10, "12", true, 12, "3"],
  )
  assert_eq(
    parse_yaml_test("[!!binary 'SGVsbG8=',!!binary '/w==',!!binary 'AA==']"),
    ["Hello", "�", "\u0000"],
  )
}

///|
test "parseYaml document splitting mirrors Go reader" {
  for
    (source, expected) in [
      ("\n", Json::null()),
      ("# comment", Json::null()),
      ("---", Json::array([Json::null()])),
      ("---\n---\n", Json::array([Json::null()])),
      ("1\n---\nfalse\n---\n", Json::array([1, false])),
      ("# comment\n---\n1", Json::array([null, 1])),
      ("--- # comment\n1", Json::number(1)),
      ("1\n...\nignored", Json::number(1)),
      ("1\n--- ignored", Json::number(1)),
    ] {
    assert_eq(parse_yaml_test(source), expected)
  }
}

///|
test "parseYaml anchors merges duplicate keys and key conversion" {
  assert_eq(parse_yaml_test("a: &a {x: 1}\nb: *a\nc: {<<: *a,z: 2}"), {
    "a": { "x": 1 },
    "b": { "x": 1 },
    "c": { "x": 1, "z": 2 },
  })
  assert_eq(
    parse_yaml_test(
      "{v: {a: 9, <<: {a: 1,b: 2}}, z: {<<: [{a: 1}, {a: 2,b: 3}]}}",
    ),
    { "v": { "a": 1, "b": 2 }, "z": { "a": 1, "b": 3 } },
  )
  assert_eq(parse_yaml_test("{x: 1,x: 2,'<<': 3}"), { "x": 2, "<<": 3 })
  assert_eq(parse_yaml_test("{0.1: a,1e-5: b,1e6: c,-0.0: d,yes: e,.inf: f}"), {
    "0.1": "a",
    "1e-05": "b",
    "1e+06": "c",
    "-0": "d",
    "true": "e",
    ".inf": "f",
  })
  assert_eq(parse_yaml_test("[&a 1,*a,&a 2,*a]"), [1, 1, 2, 2])
}

///|
test "parseYaml rejects invalid input without escaping diagnostics" {
  for
    source in [
      "a: 1\u0000b: 2", "a: \u0001", "a: \u007f", "{a: &a [{x: 1}],b: {<<: *a}}",
    ] {
    try parse_yaml_test(source) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
    } noraise {
      _ => fail("expected invalid YAML")
    }
  }
  for
    source in [
      "", "[", "*missing", "{a: &a [*a]}", "{<<: [1]}", "{null: 1}", "{18446744073709551615: 1}",
      "? [1,2]\n: 3", ".inf", "!!int '1.0'", "!!bool maybe", "!!timestamp 2023-02-29",
      "!!timestamp 2024-01-01T99:00:00Z", "!!timestamp 2024-01-01extra",
    ] {
    try parse_yaml_test(source) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
    } noraise {
      _ => fail("expected YAML rejection: " + source)
    }
  }
  try @moonjsonnet.evaluate("std.parseYaml(42)") catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Type)
  } noraise {
    _ => fail("expected string")
  }
}

///|
test "parseYaml bounds parser nesting alias expansion and output" {
  let deep = "[".repeat(5000) + "0" + "]".repeat(5000)
  let mut aliases = "a0: &a0 abcdefghijklmnopqrstuvwxyz\n"
  for i in 1..<15 {
    aliases += "a\{i}: &a\{i} [*a\{i-1},*a\{i-1}]\n"
  }
  for
    (source, limits) in [
      (deep, { ..@moonjsonnet.Limits::default(), depth: 32, }),
      (aliases, { ..@moonjsonnet.Limits::default(), output_bytes: 1024, }),
      ("[1,2,3,4,5]", { ..@moonjsonnet.Limits::default(), steps: 10, }),
    ] {
    try parse_yaml_test(source, limits~) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
    } noraise {
      _ => fail("expected YAML resource bound")
    }
  }
}
