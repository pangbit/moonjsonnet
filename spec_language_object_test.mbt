// Independent oracle: docs/development/SPEC-LANGUAGE-REVIEW.md.

///|
test "language object keys exclude new self locals and comprehension self" {
  for
    source in [
      "{[self.key]:1}", "{local k='x',[k]:1}", "{[self.key]:x for x in [1]}", "if false then {[self.key]:1} else 42",
      "if false then {local k='x',[k]:1} else 42", "if false then {[self.key]:x for x in [1]} else 42",
    ] {
    try
      @moonjsonnet.Program::parse(source, filename="object-scope.jsonnet")
    catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Static)
        assert_eq(d.location.file, "object-scope.jsonnet")
      }
    } noraise {
      _ => fail("object key captured its own object scope: " + source)
    }
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "{key:'x',nested:{[self.key]:self.key,key:'inner'}}.nested",
    ),
    { "x": "inner", "key": "inner" },
  )
}

///|
test "language inherited fields separate late self super root and original objects" {
  assert_eq(
    @moonjsonnet.evaluate(
      "local a={x:1,y:self.x}; local b=a+{x:super.x+1,z:super.y}; [a.y,b.y,b.z,a.y]",
    ),
    [1, 2, 2, 1],
  )
  assert_eq(
    @moonjsonnet.evaluate(
      "local base={x:1,n:{x:2,r:$.x,s:self.x}}; [base.n,(base+{x:3}).n]",
    ),
    [{ "x": 2, "r": 1, "s": 2 }, { "x": 2, "r": 3, "s": 2 }],
  )
}

///|
test "language inherited assertions use final self for access and manifestation" {
  assert_eq(@moonjsonnet.evaluate("{assert self.x>0,x:-1}+{x:2}"), { "x": 2 })
  for
    source in [
      "local a={assert self.x>0,x:1}; (a+{x:-1}).x", "local a={assert self.x>0,x:1}; a+{x:-1}",
      "({assert false,hidden::1}).hidden", "({assert false,visible:1}).visible",
    ] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Assertion)
    } noraise {
      _ => fail("object assertion was not checked: " + source)
    }
  }
}

///|
test "language manifestation checks assertion only objects recursively" {
  for
    source in [
      "{assert false}", "{outer:{assert false}}", "[{assert false}]", "{assert false,hidden::error 'unforced field'}",
    ] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Assertion)
    } noraise {
      _ => fail("manifestation omitted an assertion-only object: " + source)
    }
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.type({assert false}),std.length([{assert false}]),{hidden::{assert false}},(function(unused)42)({assert false})]",
    ),
    ["object", 1, {}, 42],
  )
}

///|
test "language assertions cache checks and do not force messages or failed fields" {
  let mut checks = 0
  let mut payloads = 0
  let check : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      checks += 1
      true
    },
  }
  let payload : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      payloads += 1
      42
    },
  }
  let natives = Map([("check", check), ("payload", payload)])
  assert_eq(
    @moonjsonnet.evaluate(
      "local o={assert std.native('check')():std.native('payload')(),a:1,b:2}; [o.a,o.b,o.a]",
      native_functions=natives,
    ),
    [1, 2, 1],
  )
  assert_eq((checks, payloads), (1, 0))
  try
    @moonjsonnet.evaluate(
      "({assert false:'failed',a:std.native('payload')()}).a",
      native_functions=natives,
    )
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Assertion)
  } noraise {
    _ => fail("false assertion allowed the selected field")
  }
  assert_eq((checks, payloads), (1, 0))
}

///|
test "language visibility inheritance controls JSON output and direct access" {
  for
    (left, right, shown) in [
      (":", ":", true),
      (":", "::", false),
      (":", ":::", true),
      ("::", ":", false),
      ("::", "::", false),
      ("::", ":::", true),
      (":::", ":", true),
      (":::", "::", false),
      (":::", ":::", true),
    ] {
    let source = "local o={x" + left + "1}+{x" + right + "2}; [o,o.x]"
    let fields : Map[String, Json] = if shown {
      Map([("x", 2)])
    } else {
      Map([])
    }
    assert_eq(@moonjsonnet.evaluate(source), [Json::object(fields), 2])
  }
  assert_eq(
    @moonjsonnet.evaluate("{hidden::error 'unused'}+{hidden:function()0}"),
    {},
  )
}

///|
test "language JSON conversion rejects demanded nested functions and errors" {
  for
    (source, kind) in [
      ("[function()0]", @moonjsonnet.Type),
      ("{a:function()0}", @moonjsonnet.Type),
      ("{a:[{b:function()0}]}", @moonjsonnet.Type),
      ("{hidden::function()0}+{hidden:::function()0}", @moonjsonnet.Type),
      ("[error 'demanded']", @moonjsonnet.Runtime),
      ("{a:{b:error 'demanded'}}", @moonjsonnet.Runtime),
      ("{hidden::1}+{hidden:::error 'demanded'}", @moonjsonnet.Runtime),
    ] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, kind)
    } noraise {
      _ =>
        fail("JSON conversion accepted a demanded non-JSON result: " + source)
    }
  }
  assert_eq(@moonjsonnet.evaluate("[{a::function()error 'body'}]"), [{}])
}
