// Criteria: SPEC-IMPORT-CLOSURE-REVIEW.md. Only neutral root_* builders are
// reused. Entry trees are handmade; imported modules are synthetic Source.text.

///|
fn import_closure_limits() -> @moonjsonnet.Limits {
  { ..@moonjsonnet.Limits::default(), steps: 20000, depth: 64, stack: 96, }
}

///|
fn import_closure_module() -> String {
  "local x=10,dep=import 'dep';" +
  "{x:11,nested:{x:12,make:function(seed=dep.a)" +
  "local saved=x+seed;function(arg=dep.b)[x,seed,saved,arg,self.x,$.x]}}"
}

///|
fn import_closure_source(
  from : String,
  path : String,
  module_text : String,
  dep_text : String,
  requests : Map[(String, String), Bool],
) -> @moonjsonnet.Source raise {
  requests[(from, path)] = true
  match (from, path) {
    ("root-scope-entry", "module") =>
      { id: "closure-module.libsonnet", text: module_text, }
    ("closure-module.libsonnet", "dep") =>
      { id: "closure-dep.libsonnet", text: dep_text, }
    _ => fail("unexpected synthetic import origin or path")
  }
}

///|
fn import_closure_call(
  target : @moonjsonnet.Ast,
  args : Array[@moonjsonnet.Ast],
) -> @moonjsonnet.Ast {
  root_ast(Call(target, args.map(arg => (None, arg)), false))
}

///|
fn import_closure_type(value : @moonjsonnet.Ast) -> @moonjsonnet.Ast {
  import_closure_call(root_path("std", ["type"]), [value])
}

///|
fn import_closure_factory() -> @moonjsonnet.Ast {
  root_ast(
    Index(
      root_ast(
        Index(
          root_ast(ImportFile("module", false)),
          root_ast(Literal("nested")),
        ),
      ),
      root_ast(Literal("make")),
    ),
  )
}

///|
fn import_closure_entry(result : @moonjsonnet.Ast) -> @moonjsonnet.Ast {
  root_local(
    [
      ("x", root_ast(Literal(900))),
      (
        "dep",
        root_object([("a", root_ast(Literal(90))), ("b", root_ast(Literal(91)))]),
      ),
      ("factory", import_closure_factory()),
      ("closed", root_call(root_var("factory"))),
    ],
    root_ast(
      Index(
        root_object([("x", root_ast(Literal(700))), ("value", result)]),
        root_ast(Literal("value")),
      ),
    ),
  )
}

///|
fn import_closure_entry_source(result : String) -> String {
  "local x=900,dep={a:90,b:91},factory=(import 'module').nested.make," +
  "closed=factory();{x:700,value:" +
  result +
  "}.value"
}

///|
fn import_closure_caller(value : @moonjsonnet.Ast) -> @moonjsonnet.Ast {
  root_local(
    [("caller", root_ast(Literal(777)))],
    root_ast(
      Index(
        root_extend(root_object([("x", root_ast(Literal(99)))]), [
          ("x", root_ast(Literal(100))),
          ("value", value),
        ]),
        root_ast(Literal("value")),
      ),
    ),
  )
}

///|
test "imported factory closures retain module locals self root and dependency origin" {
  let result = root_ast(
    Arr([
      root_call(root_var("closed")),
      root_local(
        [
          ("x", root_ast(Literal(800))),
          (
            "dep",
            root_object([
              ("a", root_ast(Literal(80))),
              ("b", root_ast(Literal(81))),
            ]),
          ),
        ],
        root_call(root_var("closed")),
      ),
      import_closure_call(
        import_closure_call(root_var("factory"), [root_var("x")]),
        [root_path("self", ["x"])],
      ),
      root_call(
        import_closure_call(root_var("factory"), [root_path("$", ["x"])]),
      ),
    ]),
  )
  let source = import_closure_entry_source(
    "[closed(),(local x=800,dep={a:80,b:81};closed())," +
    "factory(x)(self.x),factory($.x)()]",
  )
  let tree = import_closure_entry(result)
  for handmade in [false, true] {
    let requests : Map[(String, String), Bool] = Map([])
    let program = root_program(source, tree, handmade)
    assert_eq(requests.length(), 0)
    assert_eq(
      program.evaluate(
        resolver=(from, path) => {
          import_closure_source(
            from,
            path,
            import_closure_module(),
            "{a:2,b:3,dormant:error 'dep-unused'}",
            requests,
          )
        },
        limits=import_closure_limits(),
      ),
      [
        [10, 2, 12, 3, 12, 11],
        [10, 2, 12, 3, 12, 11],
        [10, 900, 910, 700, 12, 11],
        [10, 700, 710, 3, 12, 11],
      ],
    )
    assert_true(requests.contains(("root-scope-entry", "module")))
    assert_true(requests.contains(("closure-module.libsonnet", "dep")))
    assert_eq(requests.length(), 2)
  }
}

///|
test "imported unused function bodies cannot capture caller namespaces" {
  let context = import_closure_caller(
    root_ast(
      Arr([
        root_var("caller"),
        root_path("self", ["x"]),
        root_path("super", ["x"]),
        root_path("$", ["x"]),
      ]),
    ),
  )
  for handmade in [false, true] {
    assert_eq(
      root_program(
        "local caller=777;({x:99}+{x:100,value:[caller,self.x,super.x,$.x]}).value",
        context, handmade,
      ).evaluate(limits=import_closure_limits()),
      [777, 100, 99, 100],
    )
  }
  let tree = import_closure_caller(
    import_closure_type(root_ast(ImportFile("module", false))),
  )
  let source = "local caller=777;({x:99}+{x:100,value:std.type(import 'module')}).value"
  for body in ["caller", "self.x", "super.x", "$.x"] {
    for handmade in [false, true] {
      let requests : Map[(String, String), Bool] = Map([])
      let program = root_program(source, tree, handmade)
      assert_eq(requests.length(), 0)
      try
        program.evaluate(
          resolver=(from, path) => {
            import_closure_source(
              from,
              path,
              "function()" + body,
              "error 'unused-dependency'",
              requests,
            )
          },
          limits=import_closure_limits(),
        )
      catch {
        @moonjsonnet.Error(d) => {
          assert_eq(d.kind, @moonjsonnet.Static)
          assert_eq(d.location.file, "closure-module.libsonnet")
        }
      } noraise {
        _ => fail("an imported function captured the caller's namespaces")
      }
      assert_true(requests.contains(("root-scope-entry", "module")))
      assert_eq(requests.length(), 1)
    }
  }
}

///|
test "imported closure defaults defer nested dependency compile and runtime failures" {
  let failures : Array[(String, @moonjsonnet.ErrorKind)] = [
    ("function(", @moonjsonnet.Syntax),
    ("local unused=function() x;{a:2,b:3}", @moonjsonnet.Static),
    ("{a:error 'dep-default-required',b:3}", @moonjsonnet.Runtime),
  ]
  for (dep_text, kind) in failures {
    for mode in ["factory-type", "closure-type", "override", "force"] {
      let (result_source, result) = match mode {
        "factory-type" =>
          ("std.type(factory)", import_closure_type(root_var("factory")))
        "closure-type" =>
          ("std.type(closed)", import_closure_type(root_var("closed")))
        "override" =>
          (
            "factory(5)(7)",
            import_closure_call(
              import_closure_call(root_var("factory"), [root_ast(Literal(5))]),
              [root_ast(Literal(7))],
            ),
          )
        _ => ("closed()", root_call(root_var("closed")))
      }
      let source = import_closure_entry_source(result_source)
      let tree = import_closure_entry(result)
      for handmade in [false, true] {
        let requests : Map[(String, String), Bool] = Map([])
        let program = root_program(source, tree, handmade)
        assert_eq(requests.length(), 0)
        let resolver : (String, String) -> @moonjsonnet.Source raise = (
          from,
          path,
        ) => {
          import_closure_source(
            from,
            path,
            import_closure_module(),
            dep_text,
            requests,
          )
        }
        if mode == "force" {
          try
            program.evaluate(resolver~, limits=import_closure_limits())
          catch {
            @moonjsonnet.Error(d) => {
              assert_eq(d.kind, kind)
              assert_eq(d.location.file, "closure-dep.libsonnet")
              if kind == @moonjsonnet.Runtime {
                assert_eq(d.message, "dep-default-required")
              }
            }
          } noraise {
            _ => fail("a required imported dependency failure was suppressed")
          }
          assert_true(requests.contains(("closure-module.libsonnet", "dep")))
          assert_eq(requests.length(), 2)
        } else {
          assert_eq(
            program.evaluate(resolver~, limits=import_closure_limits()),
            if mode == "override" {
              Json::array([10, 5, 15, 7, 12, 11])
            } else {
              Json::string("function")
            },
          )
          assert_true(!requests.contains(("closure-module.libsonnet", "dep")))
          assert_eq(requests.length(), 1)
        }
        assert_true(requests.contains(("root-scope-entry", "module")))
      }
    }
  }
}
