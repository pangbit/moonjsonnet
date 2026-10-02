///|
// go-jsonnet v0.21.0 testdata/native1..7 and native_nonexistent golden cases.
test "upstream native JSON callback fixtures" {
  let functions : Map[String, @moonjsonnet.NativeFunction] = Map([
    (
      "jsonToString",
      { params: ["x"], callback: args => Json::string(args[0].stringify()), },
    ),
  ])
  for
    (source, expected) in [
      ("std.native(\"jsonToString\")(\"test\")", Json::string("\"test\"")),
      ("std.native(\"jsonToString\")({})", Json::string("{}")),
      (
        "std.native(\"jsonToString\")({\"x\":{\"y\":\"z\"},\"xx\":42})",
        Json::string("{\"x\":{\"y\":\"z\"},\"xx\":42}"),
      ),
      ("std.native(\"jsonToString\")(x={})", Json::string("{}")),
      ("std.native(\"nonexistent\")", Json::null()),
    ] {
    assert_eq(
      @moonjsonnet.evaluate(source, native_functions=functions),
      expected,
    )
  }
  for
    source in [
      "std.native(\"jsonToString\")(error \"xxx\")", "std.native(\"jsonToString\")(function()42)",
      "std.native(\"jsonToString\")(y={})",
    ] {
    try @moonjsonnet.evaluate(source, native_functions=functions) catch {
      @moonjsonnet.Error(_) => ()
    } noraise {
      _ => fail("expected upstream error outcome")
    }
  }
}

///|
test "native registration JSON conversion named arguments and higher order calls" {
  let calls : Array[Array[Json]] = []
  let pair : @moonjsonnet.NativeFunction = {
    params: ["left", "right"],
    callback: fn(args) {
      calls.push(args)
      Json::array(args)
    },
  }
  let identity : @moonjsonnet.NativeFunction = {
    params: ["x"],
    callback: args => args[0],
  }
  let source =
    #|local f=std.native('pair');
    #|[f(right={a:[null,true,'é😀'],h::error 'hidden'},left=42),
    #| std.map(std.native('id'),[false,{},[]]),
    #| std.type(f),std.isFunction(f),std.length(f),std.native('missing'),f==null]
  let result = @moonjsonnet.evaluate(
    source,
    native_functions=Map([("pair", pair), ("id", identity)]),
  )
  assert_eq(result, [
    [42, { "a": [null, true, "é😀"] }],
    [false, {}, []],
    "function",
    true,
    2,
    null,
    false,
  ])
  assert_eq(calls.length(), 1)
  assert_eq(calls[0], [42, { "a": [null, true, "é😀"] }])
  assert_eq(@moonjsonnet.evaluate("std.native('pair')"), Json::null())
}

///|
test "native eager ordered manifestation lazy memoization and host errors" {
  let events : Array[String] = []
  let f : @moonjsonnet.NativeFunction = {
    params: ["a", "b"],
    callback: fn(args) {
      events.push("host")
      Json::array(args)
    },
  }
  let functions = Map([("f", f)])
  let source =
    #|local x=std.native('f')(b=std.trace('b',2),a={z:std.trace('az',1),a:std.trace('aa',0)});
    #|[x,x]
  let result = @moonjsonnet.evaluate(source, native_functions=functions, trace=fn(
    _,
    s,
  ) {
    events.push(s)
  })
  assert_eq(result, [[{ "a": 0, "z": 1 }, 2], [{ "a": 0, "z": 1 }, 2]])
  assert_eq(events, ["aa", "az", "b", "host"])
  for
    source in [
      "std.native('f')(function()0,1)", "std.native('f')({assert false},1)", "std.native('f')([error 'eager'],1)",
      "std.native('f')(1)", "std.native('f')(1,2,3)", "std.native('f')(a=1,c=2)",
      "std.native('f') == std.native('f')", "std.manifestJson(std.native('f'))",
    ] {
    try @moonjsonnet.evaluate(source, native_functions=functions) catch {
      @moonjsonnet.Error(_) => ()
    } noraise {
      _ => fail("expected error: " + source)
    }
  }
  assert_eq(events, ["aa", "az", "b", "host"])
  let bad : @moonjsonnet.NativeFunction = {
    params: [],
    callback: fn(_) raise { fail("host failure") },
  }
  try
    @moonjsonnet.evaluate(
      "\nstd.native('bad')()",
      filename="host.jsonnet",
      native_functions=Map([("bad", bad)]),
    )
  catch {
    @moonjsonnet.Error(d) => {
      assert_eq(d.kind, @moonjsonnet.Runtime)
      assert_eq(d.location.file, "host.jsonnet")
      assert_eq(d.location.line, 2)
      assert_true(d.message.contains("host failure"))
    }
  } noraise {
    _ => fail("expected host error")
  }
}

///|
test "native return conversion is eager and copies mutable JSON" {
  let shared : Json = { "x": { "a": [1] } }
  let functions : Map[String, @moonjsonnet.NativeFunction] = Map([
    ("get", { params: [], callback: fn(_) { shared }, }),
    (
      "change",
      {
        params: [],
        callback: fn(_) raise {
          guard shared is { "x": { "a": Array(a), .. }, .. } else {
            fail("shape")
          }
          a[0] = 2
          Json::null()
        },
      },
    ),
    (
      "bad",
      {
        params: [],
        callback: fn(_) {
          Json::object(Map([("unused", Json::number(1.0 / 0.0))]))
        },
      },
    ),
  ])
  assert_eq(
    @moonjsonnet.evaluate(
      "local v=std.native('get')(); [std.type(v),std.native('change')(),v]",
      native_functions=functions,
    ),
    ["object", null, { "x": { "a": [1] } }],
  )
  try
    @moonjsonnet.evaluate(
      "std.type(std.native('bad')())",
      native_functions=functions,
    )
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Runtime)
  } noraise {
    _ => fail("expected eager nonfinite rejection")
  }
}

///|
test "native argument output budget and recursive result depth" {
  let f : @moonjsonnet.NativeFunction = {
    params: ["x"],
    callback: args => args[0],
  }
  let functions = Map([("id", f)])
  assert_eq(
    @moonjsonnet.evaluate(
      "std.native('id')('1234')",
      native_functions=functions,
      limits={ ..@moonjsonnet.Limits::default(), output_bytes: 6, },
    ),
    Json::string("1234"),
  )
  for source in ["std.native('id')('12345')", "['a',std.native('id')('12')]"] {
    try
      @moonjsonnet.evaluate(source, native_functions=functions, limits={
        ..@moonjsonnet.Limits::default(),
        output_bytes: 6,
      })
    catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
    } noraise {
      _ => fail("expected output budget")
    }
  }
  let items : Array[Json] = []
  let cycle = Json::array(items)
  items.push(cycle)
  let cyclic : @moonjsonnet.NativeFunction = {
    params: [],
    callback: fn(_) { cycle },
  }
  try
    @moonjsonnet.evaluate(
      "std.native('cycle')()",
      native_functions=Map([("cycle", cyclic)]),
    )
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected depth bound")
  }
  items.clear()
}

///|
test "trace location ordering laziness memoization and imported callbacks" {
  let events : Array[(@moonjsonnet.Location, String)] = []
  let trace = fn(loc, s) { events.push((loc, s)) }
  let source =
    #|local unused=std.trace('unused',0);
    #|local x=std.trace('outer',std.trace('inner',{x:std.trace('field',1)}));
    #|[x,x]
  let result = @moonjsonnet.evaluate(source, filename="trace.jsonnet", trace~)
  assert_eq(result, [{ "x": 1 }, { "x": 1 }])
  assert_eq(events.map(e => e.1), ["inner", "outer", "field"])
  for (loc, _) in events {
    assert_eq(loc.file, "trace.jsonnet")
    assert_eq(loc.line, 2)
  }
  events.clear()
  for source in ["std.trace('unprinted',error 'rest')", "std.trace(123,0)"] {
    try @moonjsonnet.evaluate(source, trace~) catch {
      @moonjsonnet.Error(_) => ()
    } noraise {
      _ => fail("expected trace error")
    }
  }
  assert_eq(events.length(), 0)
  let f : @moonjsonnet.NativeFunction = { params: [], callback: fn(_) { 42 }, }
  assert_eq(
    @moonjsonnet.evaluate(
      "import 'lib'",
      resolver=fn(_, _) {
        {
          id: "library.jsonnet",
          text: "\nstd.trace('library',std.native('answer')())",
        }
      },
      native_functions=Map([("answer", f)]),
      trace~,
    ),
    42,
  )
  assert_eq(events[0].0.file, "library.jsonnet")
  assert_eq(events[0].0.line, 2)
  assert_eq(events[0].1, "library")
}
