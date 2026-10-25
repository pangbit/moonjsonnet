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

///|
// These are object/closure/private-binding composition controls, not a sort hook API.
test "language standard function aliases preserve lexical binding when forwarded or shadowed" {
  let input = ordering_array([sequence_num(2), sequence_num(1)])
  let root_sort = additive_select(sequence_var("std"), "sort")
  let shadowed = sequence_local(
    [("saved", root_sort)],
    sequence_local(
      [("std", ordering_error("lexical std must stay captured"))],
      value_head_call(sequence_var("saved"), [input]),
    ),
  )
  let forwarded = sequence_local(
    [("saved", root_sort)],
    value_head_call(
      additive_select(
        reflect_object([
          (reflect_string("sort"), 2, sequence_var("saved")),
          (reflect_string("length"), 2, make_function(["x"], sequence_num(0))),
        ]),
        "sort",
      ),
      [input],
    ),
  )
  sequence_value(shadowed, [1, 2])
  sequence_value(forwarded, [1, 2])
}

///|
test "language inherited source library fields resolve self in their final object" {
  let input = ordering_array([sequence_num(2), sequence_num(1)])
  let derived = ordering_binary(
    sequence_var("std"),
    "+",
    reflect_object([
      (reflect_string("length"), 2, make_function(["x"], sequence_num(0))),
    ]),
  )
  // The exact pinned body takes the length<=1 branch, without comparing keys.
  sequence_value(value_head_call(additive_select(derived, "sort"), [input]), [
    2, 1,
  ])
}

///|
test "language super lookup and extracted inherited methods retain final self" {
  let input = ordering_array([sequence_num(2), sequence_num(1)])
  let run = make_function(
    ["arr"],
    value_head_call(
      additive_select(ordering_leaf("super", Var("super")), "sort"),
      [sequence_var("arr")],
    ),
  )
  let derived = ordering_binary(
    sequence_var("std"),
    "+",
    reflect_object([
      (reflect_string("length"), 2, make_function(["x"], sequence_num(0))),
      (reflect_string("run"), 2, run),
    ]),
  )
  sequence_value(value_head_call(additive_select(derived, "run"), [input]), [
    2, 1,
  ])
  sequence_value(
    sequence_local(
      [("saved", additive_select(derived, "sort"))],
      sequence_local(
        [("std", ordering_error("call scope must not rebind a closure"))],
        value_head_call(sequence_var("saved"), [input]),
      ),
    ),
    [2, 1],
  )
}

///|
test "language inherited source methods retain the private library for slicing" {
  let derived = ordering_binary(
    sequence_var("std"),
    "+",
    reflect_object([
      (
        reflect_string("slice"),
        2,
        make_function(
          ["value", "start", "end", "step"],
          ordering_error(
            "public receiver slice must not replace private syntax",
          ),
        ),
      ),
    ]),
  )
  let elements : Array[OrderingExpr] = []
  for _ in 0..<31 {
    elements.push(sequence_num(7))
  }
  let input = ordering_array(elements)
  let call = value_head_call(additive_select(derived, "sort"), [
    input,
    make_function(["x"], sequence_num(0)),
  ])
  // A composition regression under the existing slice/comparison child profile;
  // it is not an adjudication of the malformed greater-than conclusions.
  for handmade in [false, true] {
    sort_admission_value(sequence_call("type", [call]), handmade, "array")
  }
}
