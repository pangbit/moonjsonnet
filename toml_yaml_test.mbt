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
test "YAML layout quoting and visible fields" {
  for
    (source, expected) in [
      (
        "std.manifestYamlDoc({a:[1,2],b:{x:true}})", "\"a\":\n- 1\n- 2\n\"b\":\n  \"x\": true",
      ),
      ("std.manifestYamlDoc({a:[1,2]},true,false)", "a:\n  - 1\n  - 2"),
      ("std.manifestYamlDoc('x\\n\\n')", "|\n  x\n  "),
      ("std.manifestYamlDoc(1,0)", "1"),
      ("std.manifestYamlDoc({assert false})", "{}"),
      (
        "std.manifestYamlDoc({'true':1,'1e309':2,'x0xffz':3,'a/b':4},quote_keys=false)",
        "1e309: 2\na/b: 4\n\"true\": 1\nx0xffz: 3",
      ),
      ("std.manifestYamlStream([])", "---\n\n...\n"),
    ] {
    assert_eq(@moonjsonnet.evaluate(source), Json::string(expected))
  }
}

///|
fn toml_yaml_expect_error(source : String) -> Unit raise {
  try @moonjsonnet.evaluate(source) catch {
    @moonjsonnet.Error(d) => assert_true(d.kind != @moonjsonnet.Unsupported)
  } noraise {
    _ => fail("expected error: " + source)
  }
}

///|
fn toml_yaml_expect_limit(source : String) -> Unit raise {
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

///|
test "TOML rejects a nonobject body" {
  toml_yaml_expect_error("std.manifestToml([])")
}

///|
test "TOML rejects a visible null value" {
  toml_yaml_expect_error("std.manifestToml({a:null})")
}

///|
test "TOML empty body leaves supplied numeric indentation unused" {
  // Fixed bbb38f std.jsonnet 965-981, 995-996 (stdlib_source.mbt +6 lines):
  // objectFields({})=[] gives kvp=[], sections=[''], and the final join is ''.
  // No path reads indent. The documented String domain does not specify an
  // eager check of unused arguments; consumed nonstring coercion is separate.
  assert_eq(@moonjsonnet.evaluate("std.manifestTomlEx({},1)"), Json::string(""))
}

///|
test "YAML rejects a missing required value" {
  toml_yaml_expect_error("std.manifestYamlDoc(quote_keys=false)")
}

///|
test "YAML propagates a visible field error" {
  toml_yaml_expect_error("std.manifestYamlDoc({a:error 'forced'})")
}

///|
test "YAML propagates a nested array error" {
  toml_yaml_expect_error("std.manifestYamlDoc({a:[1,error 'nested']})")
}

///|
test "YAML rejects a function value" {
  toml_yaml_expect_error("std.manifestYamlDoc(function()0)")
}

///|
test "TOML recursive object respects resource limits" {
  toml_yaml_expect_limit("std.manifestToml({x:self})")
}

///|
test "YAML recursive object respects resource limits" {
  toml_yaml_expect_limit("std.manifestYamlDoc({x:self})")
}

///|
test "YAML repeated string respects output limit" {
  toml_yaml_expect_limit("std.manifestYamlDoc({a:std.repeat('x',100)})")
}
