// Independent expectations: SPEC-LANGUAGE-FORMS-REVIEW.md, fixed before probes.

///|
fn forms_value(source : String, expected : Json) -> Unit raise {
  let program = @moonjsonnet.Program::parse(source, filename="forms.jsonnet")
  assert_eq(program.evaluate(), expected)
  assert_eq(@moonjsonnet.Program::from_ast(program.ast()).evaluate(), expected)
}

///|
fn forms_runtime(
  source : String,
  kind : @moonjsonnet.ErrorKind,
  message? : String,
) -> Unit raise {
  let program = @moonjsonnet.Program::parse(source, filename="forms.jsonnet")
  for entry in [program, @moonjsonnet.Program::from_ast(program.ast())] {
    try entry.evaluate() catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, kind)
        assert_eq(d.location.file, "forms.jsonnet")
        if message is Some(message) {
          assert_eq(d.message, message)
        }
      }
    } noraise {
      _ => fail("expected evaluation failure: " + source)
    }
  }
}

///|
test "recursive local groups bind forward references and mutually recursive functions" {
  forms_value("local a=b,b=42;a", 42)
  forms_value(
    "local even(n)=if n==0 then true else odd(n-1),odd(n)=if n==0 then false else even(n-1); [even(6),odd(5),even(5)]",
    [true, true, false],
  )
  forms_value("local x=error 'outer'; local x=42,y=x; [x,y]", [42, 42])
  forms_value("local a=error 'unused',b=b; 42", 42)
}

///|
test "duplicate local groups and sibling scope fail statically before unused execution" {
  for
    source in [
      "local x=1,x=2;42", "if false then local x=1,x=2;x else 42", "local f()=1,f=2;42",
      "{same:1,same:2}", "{['same']:1,['same']:2}", "{local x=1,local x=2,a:42}",
      "{local x=1,[v]:42,local x=2 for v in []}", "local x=(local inner=42;inner),unused=inner;42",
      "[x for x in y for y in []]", "{[x]:42 for x in y for y in []}", "local unused=[x for x in []];x",
    ] {
    try
      @moonjsonnet.Program::parse(source, filename="static-forms.jsonnet")
    catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Static)
        assert_eq(d.location.file, "static-forms.jsonnet")
      }
    } noraise {
      _ => fail("invalid source escaped static validation: " + source)
    }
  }
}

///|
test "recursive local aliases share one demanded initializer and skip unused ones" {
  let mut calls = 0
  let tick : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      calls += 1
      Json::number(calls.to_double())
    },
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "local unused=std.native('tick')(),a=std.native('tick')(),b=a,c=b; [c,b,a,c]",
      native_functions=Map([("tick", tick)]),
    ),
    [1, 1, 1, 1],
  )
  assert_eq(calls, 1)
}

///|
test "recursive object local aliases rebind final self and keep lexical super" {
  forms_value(
    "local o={base:2}+{local a=b,local b=self.base+super.base,x:a}; [o.x,(o+{base:3}).x,o.x]",
    [4, 5, 4],
  )
}

///|
test "comprehension domains shadow sequentially and preserve Cartesian order" {
  forms_value("[[x,y] for x in [1,2] for y in [x,x+10]]", [
    [1, 1],
    [1, 11],
    [2, 2],
    [2, 12],
  ])
  forms_value("local x=['a','b']; {[x]:x for x in x}", { "a": "a", "b": "b" })
  forms_value("[x for x in [1,2] for x in [x+10]]", [11, 12])
  forms_value("{[x]:x for x in ['outer'] for x in ['a','b']}", {
    "a": "a",
    "b": "b",
  })
}

///|
test "comprehensions skip excluded domains and keep generated payloads lazy" {
  forms_value("[error 'body' for x in [1] if false for y in error 'domain']", [])
  forms_value(
    "{[error 'key']:error 'body' for x in [1] if false for y in error 'domain'}",
    {},
  )
  forms_value("std.length([error 'body' for x in [1,2]])", 2)
  forms_value("[if x==1 then 42 else error 'unused' for x in [1,2]][0]", 42)
  forms_value("{[error 'key']:error 'body' for x in []}", {})
  forms_value("{[null]:error 'body' for x in [1,2]}", {})
  forms_value("std.length({['a']:42 for x in [error 'unused iterator']})", 1)
}

///|
test "comprehension shape constructs keys before forcing cached selected bodies" {
  let mut keys = 0
  let mut bodies = 0
  let key : @moonjsonnet.NativeFunction = {
    params: ["x"],
    callback: args => {
      keys += 1
      args[0]
    },
  }
  let body : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      bodies += 1
      Json::number(bodies.to_double())
    },
  }
  assert_eq(
    @moonjsonnet.evaluate(
      "local o={[std.native('key')(x)]:std.native('body')() for x in ['a','b']}; [std.length(o),std.type(o),o.b,o.b]",
      native_functions=Map([("key", key), ("body", body)]),
    ),
    [2, "object", 1, 1],
  )
  assert_eq((keys, bodies), (2, 1))
  assert_eq(
    @moonjsonnet.evaluate(
      "local o={[null]:std.native('body')() for x in ['a','b']}; std.type(o)",
      native_functions=Map([("body", body)]),
    ),
    "object",
  )
  assert_eq((keys, bodies), (2, 1))
}

///|
test "duplicate and invalid comprehension keys fail before any body callbacks" {
  let mut keys = 0
  let mut bodies = 0
  let key : @moonjsonnet.NativeFunction = {
    params: ["x"],
    callback: args => {
      keys += 1
      args[0]
    },
  }
  let body : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      bodies += 1
      42
    },
  }
  for
    (source, kind, expected_keys) in [
      (
        "std.type({[std.native('key')(x)]:std.native('body')() for x in ['same','same']})",
        @moonjsonnet.Runtime,
        2,
      ),
      (
        "std.type({[std.native('key')(x)]:std.native('body')() for x in [1]})",
        @moonjsonnet.Type,
        1,
      ),
    ] {
    let program = @moonjsonnet.Program::parse(source)
    for entry in [program, @moonjsonnet.Program::from_ast(program.ast())] {
      keys = 0
      bodies = 0
      try
        entry.evaluate(native_functions=Map([("key", key), ("body", body)]))
      catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, kind)
      } noraise {
        _ => fail("invalid key construction succeeded")
      }
      assert_eq((keys, bodies), (expected_keys, 0))
    }
  }
}

///|
test "nonboolean comprehension filters reject before later native domains" {
  let mut domains = 0
  let domain : @moonjsonnet.NativeFunction = {
    params: [],
    callback: _ => {
      domains += 1
      []
    },
  }
  for
    source in [
      "[x for x in [1] if 0 for y in std.native('domain')()]", "{[x]:42 for x in ['a'] if 0 for y in std.native('domain')()}",
    ] {
    let program = @moonjsonnet.Program::parse(source)
    for entry in [program, @moonjsonnet.Program::from_ast(program.ast())] {
      try entry.evaluate(native_functions=Map([("domain", domain)])) catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Type)
      } noraise {
        _ => fail("nonboolean filter accepted")
      }
      assert_eq(domains, 0)
    }
  }
}

///|
test "comprehension fields inherit self super locals and root without freezing originals" {
  forms_value(
    "local o={n:10}+{local k=self.n+super.n,[x]:k+x for x in ['a','b']}; [o.a,(o+{n:20}).a,o.a]",
    ["20a", "30a", "20a"],
  )
  forms_value(
    "local o={name:'a',rows:{[self.name]:$.name for x in [0]}}; [o.rows,(o+{name:'b'}).rows]",
    [{ "a": "a" }, { "b": "b" }],
  )
}

///|
test "comprehension key and filter errors remain runtime after valid parsing" {
  forms_runtime(
    "std.type({[error 'key']:error 'body' for x in [1]})",
    @moonjsonnet.Runtime,
    message="key",
  )
  forms_runtime(
    "({[x]:error 'body' for x in ['a']}).a",
    @moonjsonnet.Runtime,
    message="body",
  )
  for
    source in [
      "std.type({['same']:error 'unused body' for x in [1,2]})", "std.type({['s'+'ame']:1,['same']:2})",
    ] {
    forms_runtime(source, @moonjsonnet.Runtime)
  }
  for
    source in [
      "std.type({[1]:error 'body' for x in [1]})", "[x for x in [1] if 0]", "{[x]:42 for x in ['a'] if 0}",
      "[x for x in 1]", "{[x]:42 for x in 1}",
    ] {
    forms_runtime(source, @moonjsonnet.Type)
  }
  forms_value("[x for x in [1] if false for y in 1]", [])
  forms_value("{[x]:42 for x in ['a'] if false for y in 1}", {})
}
