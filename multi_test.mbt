///|
test "multi JSON files preserve formatting, visibility and filename keys" {
  let files = @moonjsonnet.evaluate_multi(
    "{'b.json':[], 'a.json':{x:1}, hidden::error 'hidden'}",
  )
  assert_eq(files.length(), 2)
  assert_eq(files["a.json"], "{\n   \"x\": 1\n}\n")
  assert_eq(files["b.json"], "[ ]\n")
  assert_eq(@moonjsonnet.evaluate_multi("{}").length(), 0)
  let keys = @moonjsonnet.evaluate_multi("{'':1,'../x':2,'/x':3,'x\\u0000y':4}")
  assert_eq(keys[""], "1\n")
  assert_eq(keys["../x"], "2\n")
  assert_eq(keys["/x"], "3\n")
  assert_eq(keys["x\u0000y"], "4\n")
}

///|
test "multi string files have no added newline and retain raw bytes" {
  let files = @moonjsonnet.evaluate_multi(
    "{a:'',b:'é😀\\u0000\\n'}",
    string_output=true,
  )
  assert_eq(files["a"], "")
  assert_eq(files["b"], "é😀\u0000\n")
  assert_eq(@moonjsonnet.evaluate_multi("{}", string_output=true).length(), 0)
}

///|
test "multi deeply manifests values before validating the output shape" {
  for
    (source, string_output, kind) in [
      ("42", false, @moonjsonnet.Type),
      ("[error 'forced']", false, @moonjsonnet.Runtime),
      ("{assert false}", false, @moonjsonnet.Assertion),
      ("{a:{x:error 'forced'}}", true, @moonjsonnet.Runtime),
      ("{a:function() 1}", true, @moonjsonnet.Type),
      ("{a:42}", true, @moonjsonnet.Type),
      ("{a:{assert false}}", true, @moonjsonnet.Assertion),
    ] {
    try @moonjsonnet.evaluate_multi(source, string_output~) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, kind)
    } noraise {
      _ => fail("expected multi output error")
    }
  }
}

///|
test "multi JSON payloads share one serialized budget" {
  let limits = @moonjsonnet.Limits::default()
  let source = "{a:{x:1},b:{y:2}}"
  let files = @moonjsonnet.evaluate_multi(source, limits={
    ..limits,
    output_bytes: 26,
  })
  assert_eq(files["a"], "{\n   \"x\": 1\n}\n")
  assert_eq(files["b"], "{\n   \"y\": 2\n}\n")
  try
    @moonjsonnet.evaluate_multi(source, limits={ ..limits, output_bytes: 25, })
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected shared serialized output budget")
  }
}

///|
test "multi preserves shared parameter and callback state" {
  let messages : Array[String] = []
  let id : @moonjsonnet.NativeFunction = {
    params: ["x"],
    callback: args => args[0],
  }
  let files = @moonjsonnet.evaluate_multi(
    "function(x) local n=std.trace('once',std.native('id')(std.extVar('n'))); {a:n,b:n,c:x,d:std.thisFile}",
    filename="diagnostic",
    anonymous=true,
    ext_code=Map([("n", "21*2")]),
    tla_vars=Map([("x", Json::string("TLA"))]),
    native_functions=Map([("id", id)]),
    trace=(_, s) => messages.push(s),
  )
  assert_eq(files["a"], "42\n")
  assert_eq(files["b"], "42\n")
  assert_eq(files["c"], "\"TLA\"\n")
  assert_eq(files["d"], "\"\"\n")
  assert_eq(messages, ["once"])
}

///|
test "multi supports custom text and binary imports" {
  let origins : Array[String] = []
  let files = @moonjsonnet.evaluate_multi(
    "{a:import 'code',b:importbin 'data'}",
    anonymous=true,
    resolver=fn(from, path) {
      origins.push(from)
      { id: path, text: "42", }
    },
    binary_resolver=fn(from, path) {
      origins.push(from)
      { id: path, bytes: b"\x00\xff", }
    },
  )
  assert_eq(files["a"], "42\n")
  assert_eq(files["b"], "[\n   0,\n   255\n]\n")
  assert_eq(origins, ["", ""])
}
