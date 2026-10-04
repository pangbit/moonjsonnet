///|
test "text output uses Go layout, escaping and numeric representation" {
  assert_eq(
    @moonjsonnet.evaluate_text("{z::error 'hidden',b:[[],{},-0],a:0.1}"),
    "{\n   \"a\": 0.10000000000000001,\n   \"b\": [\n      [ ],\n      { },\n      -0\n   ]\n}\n",
  )
  assert_eq(
    @moonjsonnet.evaluate_text("['<>&\\u0080\\u2028',1e-8,1e21]"),
    "[\n   \"<>&\\u0080\u2028\",\n   1e-08,\n   1000000000000000000000\n]\n",
  )
  assert_eq(@moonjsonnet.evaluate_text("std.sum([1e308,1e308])"), "+Inf\n")
  assert_eq(@moonjsonnet.evaluate_text("[]"), "[ ]\n")
  assert_eq(@moonjsonnet.evaluate_text("{}"), "{ }\n")
  assert_eq(
    @moonjsonnet.evaluate_text("1000000000000000100"),
    "1000000000000000128\n",
  )
}

///|
test "plain strings preserve bytes and append exactly one newline" {
  for
    (source, expected) in [
      ("''", "\n"),
      ("'é😀\\u0000\\n'", "é😀\u0000\n\n"),
      ("'\\u2028\\u0080'", "\u2028\u0080\n"),
      ("'\\\"\\\\'", "\"\\\n"),
    ] {
    assert_eq(@moonjsonnet.evaluate_text(source, string_output=true), expected)
  }
  let limits = @moonjsonnet.Limits::default()
  assert_eq(
    @moonjsonnet.evaluate_text("'\\n'", string_output=true, limits={
      ..limits,
      output_bytes: 1,
    }),
    "\n\n",
  )
}

///|
test "plain output rejects other types without traversing them" {
  for
    source in [
      "null", "true", "1", "[error 'unforced']", "{assert false,x:error 'unforced'}",
      "function() function() 1",
    ] {
    try @moonjsonnet.evaluate_text(source, string_output=true) catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Type)
        assert_true(d.message.contains("expected string"))
      }
    } noraise {
      _ => fail("expected string type error")
    }
  }
}

///|
test "stream documents share evaluation but have separate indentation" {
  let traces : Array[String] = []
  assert_eq(
    @moonjsonnet.evaluate_stream(
      "local x=std.trace('once',42); [x,{x:x},[],{}]",
      trace=(_, message) => traces.push(message),
    ),
    ["42\n", "{\n   \"x\": 42\n}\n", "[ ]\n", "{ }\n"],
  )
  assert_eq(traces, ["once"])
  assert_eq(@moonjsonnet.evaluate_stream("[]"), [])
}

///|
test "stream manifests all visible values before its top-level type check" {
  for
    (source, kind) in [
      ("'x'", @moonjsonnet.Type),
      ("{x:1}", @moonjsonnet.Type),
      ("{x:error 'forced'}", @moonjsonnet.Runtime),
      ("{assert false}", @moonjsonnet.Assertion),
      ("[1,error 'forced']", @moonjsonnet.Runtime),
      ("[function() 1]", @moonjsonnet.Type),
    ] {
    try @moonjsonnet.evaluate_stream(source) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, kind)
    } noraise {
      _ => fail("expected manifestation error")
    }
  }
}

///|
test "text and stream enforce actual serialized payload budgets" {
  let limits = @moonjsonnet.Limits::default()
  let text = "{\n   \"x\": 1\n}"
  assert_eq(
    @moonjsonnet.evaluate_text("{x:1}", limits={
      ..limits,
      output_bytes: text.length(),
    }),
    text + "\n",
  )
  for
    (source, string_output, bytes) in [
      ("{x:1}", false, text.length() - 1),
      ("'😀'", true, 3),
      ("0.1", false, 3),
    ] {
    try
      @moonjsonnet.evaluate_text(source, string_output~, limits={
        ..limits,
        output_bytes: bytes,
      })
    catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
    } noraise {
      _ => fail("expected output budget error")
    }
  }
  // Compact [0.1,0.2,0.3] fits, while their expanded payloads exceed 30 bytes.
  try
    @moonjsonnet.evaluate_stream("[0.1,0.2,0.3]", limits={
      ..limits,
      output_bytes: 30,
    })
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected shared stream payload budget")
  }
  assert_eq(
    @moonjsonnet.evaluate_stream("[1,2]", limits={ ..limits, output_bytes: 5, }),
    ["1\n", "2\n"],
  )
}

///|
test "new output APIs preserve parameters, anonymous origins and callbacks" {
  let imports : Array[String] = []
  let resolver = fn(from : String, path : String) -> @moonjsonnet.Source raise {
    guard path == "parameter" else { fail("unexpected import") }
    imports.push(from)
    { id: path, text: "'é😀'", }
  }
  assert_eq(
    @moonjsonnet.evaluate_text(
      "function(x) std.thisFile + std.extVar('p') + x",
      anonymous=true,
      ext_code=Map([("p", "import 'parameter'")]),
      tla_code=Map([("x", "'!'")]),
      resolver~,
      string_output=true,
    ),
    "é😀!\n",
  )
  assert_eq(imports, [""])
  let native : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => Json::string("native"),
  }
  assert_eq(
    @moonjsonnet.evaluate_stream(
      "function(x) [std.native('f')(),x,std.thisFile]",
      filename="main",
      tla_vars=Map([("x", Json::number(42))]),
      native_functions=Map([("f", native)]),
    ),
    ["\"native\"\n", "42\n", "\"main\"\n"],
  )
}
