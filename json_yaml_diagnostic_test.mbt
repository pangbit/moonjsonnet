///|
test "JSON scanner diagnostics preserve context byte quoting and EOF rules" {
  for
    (data, expected) in [
      ("{", "unexpected end of JSON input"),
      ("[1 x]", "invalid character 'x' after array element"),
      ("{\"x\"1}", "invalid character '1' after object key"),
      ("\"\\q\"", "invalid character 'q' in string escape code"),
      ("é", "invalid character 'Ã' looking for beginning of value"),
      ("-", "invalid character ' ' in numeric literal"),
    ] {
    try
      @moonjsonnet.evaluate(
        "std.parseJson(" + Json::string(data).stringify() + ")",
      )
    catch {
      @moonjsonnet.Error(d) =>
        assert_eq(d.message, "failed to parse JSON: " + expected)
    } noraise {
      _ => fail("malformed JSON accepted")
    }
  }
}

///|
test "YAML errors preserve parser scanner and directive semantics" {
  for
    (data, expected) in [
      ("[broken", "line 1: did not find expected ',' or ']'"),
      ("a:\n\t1", "line 2: found character that cannot start any token"),
      ("*missing", "unknown anchor 'missing' referenced"),
      ("%YAML 1.2\n---\na", "found incompatible YAML document"),
      ("%YAML 1.1\n---\na", "line 1: did not find expected <document start>"),
      ("!unknown!a x", "found undefined tag handle"),
    ] {
    try
      @moonjsonnet.evaluate(
        "std.parseYaml(" + Json::string(data).stringify() + ")",
      )
    catch {
      @moonjsonnet.Error(d) =>
        assert_eq(
          d.message,
          "failed to parse YAML: error converting YAML to JSON: yaml: " +
          expected,
        )
    } noraise {
      _ => fail("malformed YAML accepted")
    }
  }
  try @moonjsonnet.evaluate("std.parseYaml('a')") catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
  } noraise {
    _ => fail("scalar YAML root was accepted")
  }
}
