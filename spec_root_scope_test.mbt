// Fixed independent criteria: SPEC-ROOT-SCOPE-REVIEW.md. All trees are
// handmade; no parser/export round trip supplies their shape or expected value.

///|
fn root_ast(kind : @moonjsonnet.AstKind) -> @moonjsonnet.Ast {
  { kind, loc: { file: "root-scope-entry", line: 1, column: 1, }, end: None, }
}

///|
fn root_var(name : String) -> @moonjsonnet.Ast {
  root_ast(Var(name))
}

///|
fn root_path(name : String, fields : Array[String]) -> @moonjsonnet.Ast {
  let mut tree = root_var(name)
  for field in fields {
    tree = root_ast(Index(tree, root_ast(Literal(Json::string(field)))))
  }
  tree
}

///|
fn root_call(target : @moonjsonnet.Ast) -> @moonjsonnet.Ast {
  root_ast(Call(target, [], false))
}

///|
fn root_object(fields : Array[(String, @moonjsonnet.Ast)]) -> @moonjsonnet.Ast {
  root_ast(
    Obj(
      fields.map(pair => {
        key: root_ast(Literal(Json::string(pair.0))),
        value: pair.1,
        visibility: 1,
        additive: false,
      }),
      [],
      [],
    ),
  )
}

///|
fn root_local(
  bindings : Array[(String, @moonjsonnet.Ast)],
  body : @moonjsonnet.Ast,
) -> @moonjsonnet.Ast {
  root_ast(
    Local(
      bindings.map(pair => { name: pair.0, value: pair.1, range: None, }),
      body,
    ),
  )
}

///|
fn root_extend(
  base : @moonjsonnet.Ast,
  fields : Array[(String, @moonjsonnet.Ast)],
) -> @moonjsonnet.Ast {
  root_ast(Binary("+", base, root_object(fields)))
}

///|
fn root_probe_function() -> @moonjsonnet.Ast {
  root_ast(
    Func(
      [],
      root_ast(Arr([root_path("$", ["tag"]), root_path("self", ["tag"])])),
    ),
  )
}

///|
fn root_factory_object(tag : Int32, inner : Int32) -> @moonjsonnet.Ast {
  root_object([
    ("tag", root_ast(Literal(Json::number(tag.to_double())))),
    (
      "inner",
      root_object([
        ("tag", root_ast(Literal(Json::number(inner.to_double())))),
        ("f", root_probe_function()),
      ]),
    ),
  ])
}

///|
fn root_program(
  source : String,
  tree : @moonjsonnet.Ast,
  handmade : Bool,
) -> @moonjsonnet.Program raise @moonjsonnet.JsonnetError {
  if handmade {
    @moonjsonnet.Program::from_ast(tree)
  } else {
    @moonjsonnet.Program::parse(source, filename="root-scope-entry")
  }
}

///|
test "nested root and self remain distinct after inheritance extraction and rehosting" {
  let source = "local root={tag:10,inner:{tag:1,f:function()[$.tag,self.tag]}}," +
    "derived=root+{tag:20},nested=root.inner+{tag:2}," +
    "other=derived.inner+{tag:3,localRoot:$.tag},saved=other.f,holder={tag:999,f:saved};" +
    "[root.inner.f(),derived.inner.f(),nested.f(),other.f(),other.localRoot,saved(),holder.f(),root.inner.f()]"
  let tree = root_local(
    [
      ("root", root_factory_object(10, 1)),
      (
        "derived",
        root_extend(root_var("root"), [("tag", root_ast(Literal(20)))]),
      ),
      (
        "nested",
        root_extend(root_path("root", ["inner"]), [
          ("tag", root_ast(Literal(2))),
        ]),
      ),
      (
        "other",
        root_extend(root_path("derived", ["inner"]), [
          ("tag", root_ast(Literal(3))),
          ("localRoot", root_path("$", ["tag"])),
        ]),
      ),
      ("saved", root_path("other", ["f"])),
      (
        "holder",
        root_object([("tag", root_ast(Literal(999))), ("f", root_var("saved"))]),
      ),
    ],
    root_ast(
      Arr([
        root_call(root_path("root", ["inner", "f"])),
        root_call(root_path("derived", ["inner", "f"])),
        root_call(root_path("nested", ["f"])),
        root_call(root_path("other", ["f"])),
        root_path("other", ["localRoot"]),
        root_call(root_var("saved")),
        root_call(root_path("holder", ["f"])),
        root_call(root_path("root", ["inner", "f"])),
      ]),
    ),
  )
  for handmade in [false, true] {
    let program = root_program(source, tree, handmade)
    assert_eq(program.evaluate(), [
      [10, 1],
      [20, 1],
      [10, 2],
      [20, 3],
      3,
      [20, 3],
      [20, 3],
      [10, 1],
    ])
  }
}

///|
test "object factories keep their definition root context instead of the caller root" {
  let source = "local make=function(){tag:30,inner:{tag:4,f:function()[$.tag,self.tag]}}," +
    "root={tag:10,make:function(){tag:40,inner:{tag:5,f:function()[$.tag,self.tag]}},outside:make()}," +
    "derived=root+{tag:20},savedMaker=derived.make,fo=root.outside.inner.f,fi=root.make().inner.f;" +
    "[root.outside.inner.f(),root.make().inner.f(),derived.outside.inner.f(),savedMaker().inner.f(),fo(),fi()]"
  let root_made = root_call(root_path("root", ["make"]))
  let saved_made = root_call(root_var("savedMaker"))
  let root_inner = root_ast(Index(root_made, root_ast(Literal("inner"))))
  let saved_inner = root_ast(Index(saved_made, root_ast(Literal("inner"))))
  let root_f = root_ast(Index(root_inner, root_ast(Literal("f"))))
  let saved_f = root_ast(Index(saved_inner, root_ast(Literal("f"))))
  let tree = root_local(
    [
      ("make", root_ast(Func([], root_factory_object(30, 4)))),
      (
        "root",
        root_object([
          ("tag", root_ast(Literal(10))),
          ("make", root_ast(Func([], root_factory_object(40, 5)))),
          ("outside", root_call(root_var("make"))),
        ]),
      ),
      (
        "derived",
        root_extend(root_var("root"), [("tag", root_ast(Literal(20)))]),
      ),
      ("savedMaker", root_path("derived", ["make"])),
      ("fo", root_path("root", ["outside", "inner", "f"])),
      ("fi", root_f),
    ],
    root_ast(
      Arr([
        root_call(root_path("root", ["outside", "inner", "f"])),
        root_call(root_f),
        root_call(root_path("derived", ["outside", "inner", "f"])),
        root_call(saved_f),
        root_call(root_var("fo")),
        root_call(root_var("fi")),
      ]),
    ),
  )
  for handmade in [false, true] {
    let program = root_program(source, tree, handmade)
    assert_eq(program.evaluate(), [
      [30, 4],
      [10, 5],
      [30, 4],
      [20, 5],
      [30, 4],
      [10, 5],
    ])
  }
}

///|
test "root lookup errors remain deferred and cannot borrow a nested self field" {
  let entered = root_call(
    root_ast(
      Call(
        root_path("std", ["native"]),
        [(None, root_ast(Literal("entered")))],
        false,
      ),
    ),
  )
  let function = root_ast(
    Func(
      [],
      root_ast(If(entered, root_path("$", ["needed"]), root_ast(Literal(null)))),
    ),
  )
  for explicit_error in [false, true] {
    let source_root = if explicit_error {
      "{needed:error 'root-marker',inner:{needed:99,f:function()if std.native('entered')() then $.needed else null}}"
    } else {
      "{inner:{needed:99,f:function()if std.native('entered')() then $.needed else null}}"
    }
    let fields = [
      (
        "inner",
        root_object([("needed", root_ast(Literal(99))), ("f", function)]),
      ),
    ]
    if explicit_error {
      fields.push(("needed", root_ast(Fail(root_ast(Literal("root-marker"))))))
    }
    let bindings = [
      ("root", root_object(fields)),
      ("held", root_path("root", ["inner", "f"])),
    ]
    let prefix = "local root=" +
      source_root +
      ",held=root.inner.f;if root.inner.needed==99 then "
    for mode in ["metadata", "unused", "forced"] {
      let suffix = match mode {
        "metadata" => "std.type(held)"
        "unused" => "(local unused=held();42)"
        _ => "held()"
      }
      let source = prefix + suffix + " else null"
      let body = match mode {
        "metadata" =>
          root_ast(
            Call(root_path("std", ["type"]), [(None, root_var("held"))], false),
          )
        "unused" =>
          root_local(
            [("unused", root_call(root_var("held")))],
            root_ast(Literal(42)),
          )
        _ => root_call(root_var("held"))
      }
      let tree = root_local(
        bindings,
        root_ast(
          If(
            root_ast(
              Binary(
                "==",
                root_path("root", ["inner", "needed"]),
                root_ast(Literal(99)),
              ),
            ),
            body,
            root_ast(Literal(null)),
          ),
        ),
      )
      for handmade in [false, true] {
        let events : Array[String] = []
        let natives : Map[String, @moonjsonnet.NativeFunction] = Map([
          (
            "entered",
            {
              params: [],
              callback: _ => {
                events.push("body")
                true
              },
            },
          ),
        ])
        let program = root_program(source, tree, handmade)
        assert_eq(events, [])
        if mode == "forced" {
          try program.evaluate(native_functions=natives) catch {
            @moonjsonnet.Error(d) => {
              assert_eq(d.kind, @moonjsonnet.Runtime)
              assert_eq(d.location.file, "root-scope-entry")
              if explicit_error {
                assert_eq(d.message, "root-marker")
              }
            }
          } noraise {
            _ =>
              fail(
                "root lookup borrowed inner self or the inner-value guard failed",
              )
          }
          assert_eq(events, ["body"])
        } else {
          let expected : Json = if mode == "metadata" { "function" } else { 42 }
          assert_eq(program.evaluate(native_functions=natives), expected)
          assert_eq(events, [])
        }
      }
    }
  }
}

///|
test "an object caller cannot supply a missing lexical root to an outside function" {
  let source = "local getter=function()$.needed; {needed:99,value:getter()}"
  let tree = root_local(
    [("getter", root_ast(Func([], root_path("$", ["needed"]))))],
    root_object([
      ("needed", root_ast(Literal(99))),
      ("value", root_call(root_var("getter"))),
    ]),
  )
  for handmade in [false, true] {
    try root_program(source, tree, handmade) catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Static)
        assert_eq(d.location.file, "root-scope-entry")
      }
    } noraise {
      _ =>
        fail("call-site object granted a lexical root to an outside function")
    }
  }
}
