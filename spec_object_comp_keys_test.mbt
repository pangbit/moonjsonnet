// Independent criteria: SPEC-OBJECT-COMP-KEYS-REVIEW.md. Reuse only neutral
// forms_ast construction; all new trees and literal oracles are handmade.

///|
fn comp_keys_var(name : String) -> @moonjsonnet.Ast {
  forms_ast(Var(name))
}

///|
fn comp_keys_std(
  name : String,
  args : Array[@moonjsonnet.Ast],
) -> @moonjsonnet.Ast {
  forms_ast(
    Call(
      forms_ast(
        Index(comp_keys_var("std"), forms_ast(Literal(Json::string(name)))),
      ),
      args.map(arg => (None, arg)),
      false,
    ),
  )
}

///|
fn comp_keys_native(
  name : String,
  args : Array[@moonjsonnet.Ast],
) -> @moonjsonnet.Ast {
  forms_ast(
    Call(
      comp_keys_std("native", [forms_ast(Literal(Json::string(name)))]),
      args.map(arg => (None, arg)),
      false,
    ),
  )
}

///|
fn comp_keys_index(field : String) -> @moonjsonnet.Ast {
  forms_ast(Index(comp_keys_var("o"), forms_ast(Literal(Json::string(field)))))
}

///|
fn comp_keys_tree(
  collision : Bool,
  result : @moonjsonnet.Ast,
) -> @moonjsonnet.Ast {
  let x = comp_keys_var("x")
  let y = comp_keys_var("y")
  let name = forms_ast(
    If(
      forms_ast(Binary("==", y, forms_ast(Literal(0)))),
      forms_ast(Literal(null)),
      forms_ast(
        If(
          forms_ast(Binary("==", x, forms_ast(Literal(1)))),
          forms_ast(Literal("first")),
          forms_ast(Literal(if collision { "first" } else { "second" })),
        ),
      ),
    ),
  )
  let body = forms_ast(
    If(
      comp_keys_native("body", [x, y]),
      forms_ast(
        If(
          forms_ast(Binary("==", y, forms_ast(Literal(0)))),
          forms_ast(Fail(forms_ast(Literal("null-key-body-marker")))),
          forms_ast(
            If(
              forms_ast(Binary("==", x, forms_ast(Literal(2)))),
              forms_ast(Fail(forms_ast(Literal("retained-body-marker")))),
              forms_ast(Arr([x, y])),
            ),
          ),
        ),
      ),
      forms_ast(Literal(null)),
    ),
  )
  let object = forms_ast(
    ObjectComp(
      comp_keys_native("key", [name, x, y]),
      body,
      [
        For("x", forms_ast(Arr([forms_ast(Literal(1)), forms_ast(Literal(2))]))),
        For("y", forms_ast(Arr([forms_ast(Literal(0)), x]))),
      ],
      [],
    ),
  )
  forms_ast(
    Local(
      [
        { name: "x", value: forms_ast(Literal(99)), range: None, },
        { name: "y", value: forms_ast(Literal(88)), range: None, },
        { name: "o", value: object, range: None, },
      ],
      result,
    ),
  )
}

///|
fn comp_keys_source(collision : Bool) -> String {
  "local x=99,y=88,o={" +
  "[std.native('key')(if y==0 then null else if x==1 then 'first' else '" +
  (if collision { "first" } else { "second" }) +
  "',x,y)]:" +
  "if std.native('body')(x,y) then " +
  "if y==0 then error 'null-key-body-marker' else " +
  "if x==2 then error 'retained-body-marker' else [x,y] else null " +
  "for x in [1,2] for y in [0,x]};"
}

///|
fn comp_keys_natives(
  keys : Map[String, Json],
  bodies : Map[String, Bool],
  ready : Ref[Bool],
) -> Map[String, @moonjsonnet.NativeFunction] {
  Map([
    (
      "key",
      {
        params: ["name", "x", "y"],
        callback: args => {
          keys[args[1].stringify() + ":" + args[2].stringify()] = args[0]
          args[0]
        },
      },
    ),
    (
      "body",
      {
        params: ["x", "y"],
        callback: args => {
          bodies[args[0].stringify() + ":" + args[1].stringify()] = true
          if !keys.contains("1:0") ||
            !keys.contains("1:1") ||
            !keys.contains("2:0") ||
            !keys.contains("2:2") {
            ready.val = false
          }
          true
        },
      },
    ),
  ])
}

///|
fn comp_keys_program(
  source : String,
  tree : @moonjsonnet.Ast,
  handmade : Bool,
) -> @moonjsonnet.Program raise @moonjsonnet.JsonnetError {
  if handmade {
    @moonjsonnet.Program::from_ast(tree)
  } else {
    @moonjsonnet.Program::parse(source, filename="forms-ast")
  }
}

///|
fn comp_keys_limits() -> @moonjsonnet.Limits {
  { ..@moonjsonnet.Limits::default(), steps: 5000, depth: 48, stack: 64, }
}

///|
test "dynamic tuple key collisions fail construction before any selected value" {
  for mode in ["unused", "shape", "field"] {
    let suffix = match mode {
      "unused" => "(local unused=o.first;42)"
      "shape" => "std.type(o)"
      _ => "o.first"
    }
    let body = match mode {
      "unused" =>
        forms_ast(
          Local(
            [{ name: "unused", value: comp_keys_index("first"), range: None, }],
            forms_ast(Literal(42)),
          ),
        )
      "shape" => comp_keys_std("type", [comp_keys_var("o")])
      _ => comp_keys_index("first")
    }
    let source = comp_keys_source(true) + suffix
    let tree = comp_keys_tree(true, body)
    for handmade in [false, true] {
      let keys : Map[String, Json] = Map([])
      let bodies : Map[String, Bool] = Map([])
      let ready = Ref(true)
      let program = comp_keys_program(source, tree, handmade)
      let natives = comp_keys_natives(keys, bodies, ready)
      assert_eq(keys.length(), 0)
      if mode == "unused" {
        assert_eq(
          program.evaluate(native_functions=natives, limits=comp_keys_limits()),
          42,
        )
        assert_eq(keys.length(), 0)
      } else {
        try
          program.evaluate(native_functions=natives, limits=comp_keys_limits())
        catch {
          @moonjsonnet.Error(d) => {
            assert_eq(d.kind, @moonjsonnet.Runtime)
            assert_eq(d.location.file, "forms-ast")
          }
        } noraise {
          _ => fail("a selected early field bypassed a dynamic key collision")
        }
        assert_eq(keys.get("1:1"), Some(Json::string("first")))
        assert_eq(keys.get("2:2"), Some(Json::string("first")))
      }
      assert_eq(bodies.length(), 0)
    }
  }
}

///|
test "mixed null keys retain lazy values and each iteration definition context" {
  for mode in ["shape", "first", "second"] {
    let suffix = match mode {
      "shape" => "[std.type(o),std.length(o)]"
      "first" => "o.first"
      _ => "o.second"
    }
    let body = match mode {
      "shape" =>
        forms_ast(
          Arr([
            comp_keys_std("type", [comp_keys_var("o")]),
            comp_keys_std("length", [comp_keys_var("o")]),
          ]),
        )
      "first" => comp_keys_index("first")
      _ => comp_keys_index("second")
    }
    let source = comp_keys_source(false) + suffix
    let tree = comp_keys_tree(false, body)
    for handmade in [false, true] {
      let keys : Map[String, Json] = Map([])
      let bodies : Map[String, Bool] = Map([])
      let ready = Ref(true)
      let program = comp_keys_program(source, tree, handmade)
      let natives = comp_keys_natives(keys, bodies, ready)
      assert_eq(keys.length(), 0)
      if mode == "second" {
        try
          program.evaluate(native_functions=natives, limits=comp_keys_limits())
        catch {
          @moonjsonnet.Error(d) => {
            assert_eq(d.kind, @moonjsonnet.Runtime)
            assert_eq(d.location.file, "forms-ast")
            assert_eq(d.message, "retained-body-marker")
          }
        } noraise {
          _ => fail("a demanded retained comprehension error was suppressed")
        }
        assert_true(bodies.contains("2:2"))
        assert_eq(bodies.length(), 1)
      } else {
        let expected : Json = if mode == "shape" {
          ["object", 2]
        } else {
          [1, 1]
        }
        assert_eq(
          program.evaluate(native_functions=natives, limits=comp_keys_limits()),
          expected,
        )
        if mode == "shape" {
          assert_eq(bodies.length(), 0)
        } else {
          assert_true(bodies.contains("1:1"))
          assert_eq(bodies.length(), 1)
        }
      }
      assert_eq(keys.length(), 4)
      assert_eq(keys.get("1:0"), Some(Json::null()))
      assert_eq(keys.get("1:1"), Some(Json::string("first")))
      assert_eq(keys.get("2:0"), Some(Json::null()))
      assert_eq(keys.get("2:2"), Some(Json::string("second")))
      assert_true(ready.val)
    }
  }
}
