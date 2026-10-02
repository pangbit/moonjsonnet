///|
test "TOML layouts and string contracts" {
  for
    (source, expected) in [
      ("std.manifestToml({a:1,b:[true,2]})", "a = 1\nb = [\n  true,\n  2\n]"),
      ("std.manifestToml({'':1,a:{b:2}})", "'' = 1\n\n[a]\n  b = 2"),
      ("std.manifestToml({a:[{},{}]})", "\n\n[[a]]\n\n[[a]]"),
      (
        "std.manifestToml({a:{b:[1,2]}})", "\n\n[a]\n  b = [\n    1,\n    2\n  ]",
      ),
      ("std.manifestToml({assert false,h::error 'hidden'})", ""),
      ("std.manifestToml({a:'\\u007f\\u2028'})", "a = \"\\u007f\u2028\""),
    ] {
    assert_eq(@moonjsonnet.evaluate(source), Json::string(expected))
  }
}

///|
test "YAML layout quoting and native error behavior" {
  for
    (source, expected) in [
      (
        "std.manifestYamlDoc({a:[1,2],b:{x:true}})", "\"a\":\n- 1\n- 2\n\"b\":\n  \"x\": true",
      ),
      ("std.manifestYamlDoc({a:[1,2]},true,false)", "a:\n  - 1\n  - 2"),
      ("std.manifestYamlDoc('x\\n\\n')", "|\n  x\n  "),
      ("std.manifestYamlDoc({a:[1,error 'nested']})", "\"a\":\n- 1\n"),
      ("std.manifestYamlDoc(function()0)", ""),
      ("std.manifestYamlDoc({assert false})", "{}"),
      (
        "std.manifestYamlDoc({'true':1,'1e309':2,'x0xffz':3,'a/b':4},quote_keys=false)",
        "1e309: 2\na/b: 4\n\"true\": 1\n\"x0xffz\": 3",
      ),
      ("std.manifestYamlStream([])", "---\n\n...\n"),
    ] {
    assert_eq(@moonjsonnet.evaluate(source), Json::string(expected))
  }
}

///|
test "TOML YAML parameter errors and resource limits" {
  for
    source in [
      "std.manifestToml([])", "std.manifestToml({a:null})", "std.manifestTomlEx({},1)",
      "std.manifestYamlDoc(quote_keys=false)", "std.manifestYamlDoc(1,0)", "std.manifestYamlDoc({a:error 'forced'})",
    ] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_true(d.kind != @moonjsonnet.Unsupported)
    } noraise {
      _ => fail("expected error: " + source)
    }
  }
  for
    source in [
      "std.manifestToml({x:self})", "std.manifestYamlDoc({x:self})", "std.manifestYamlDoc({a:std.repeat('x',100)})",
    ] {
    let limits = {
      ..@moonjsonnet.Limits::default(),
      depth: 20,
      output_bytes: 64,
    }
    try @moonjsonnet.evaluate(source, limits~) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
    } noraise {
      _ => fail("expected resource limit: " + source)
    }
  }
}
