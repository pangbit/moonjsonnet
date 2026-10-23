// Fixed four-group composition criteria: SPEC-IMPORT-VALIDATION-2026-10-23.md.
// Entry ASTs are handmade. Imported modules are controlled Source.text values.

///|
fn import_validation_fixture(path : String) -> @moonjsonnet.Source {
  match path {
    "bad-default" =>
      {
        id: "memory/bad-default.libsonnet",
        text: "function(config=caller_default) 42",
      }
    "bad-message" =>
      {
        id: "memory/bad-message.libsonnet",
        text: "{assert true:caller_message,value:42}",
      }
    "factory" =>
      {
        id: "memory/factory.libsonnet",
        text: "function(config=import 'bad-message') config",
      }
    "config" =>
      {
        id: "memory/config.libsonnet",
        text: "local policy=42;{assert policy==42,limit:1,value:self.limit,hidden::error 'unselected-field'}",
      }
    _ => abort("unknown controlled import fixture")
  }
}

///|
fn import_validation_resolve(
  from : String,
  path : String,
  requests : Map[(String, String), Bool],
) -> @moonjsonnet.Source raise {
  match (from, path) {
    ("ordering-entry", "bad-default")
    | ("ordering-entry", "bad-message")
    | ("ordering-entry", "factory")
    | ("ordering-entry", "config")
    | ("memory/factory.libsonnet", "bad-message") => {
      requests[(from, path)] = true
      import_validation_fixture(path)
    }
    _ => fail("unexpected controlled import origin or path")
  }
}

///|
fn import_validation_file(path : String) -> OrderingExpr {
  ordering_leaf(
    "import " + Json::string(path).stringify(),
    ImportFile(path, false),
  )
}

///|
fn import_validation_call(
  target : OrderingExpr,
  args : Array[(String?, OrderingExpr)],
) -> OrderingExpr {
  {
    source: "(" +
    target.source +
    ")(" +
    args
    .map(pair => {
      pair.0.map(name => name + "=").unwrap_or("") + "(" + pair.1.source + ")"
    })
    .join(",") +
    ")",
    tree: ordering_ast(
      Call(target.tree, args.map(pair => (pair.0, pair.1.tree)), false),
    ),
  }
}

///|
fn import_validation_static(
  program : @moonjsonnet.Program,
  requests : Map[(String, String), Bool],
  source_id : String,
) -> Unit raise {
  try
    program.evaluate(
      resolver=(from, path) => import_validation_resolve(from, path, requests),
      limits=import_closure_limits(),
    )
  catch {
    @moonjsonnet.Error(d) => {
      assert_eq(d.kind, @moonjsonnet.Static)
      assert_eq(d.location.file, source_id)
    }
  } noraise {
    _ => fail("an imported invalid default or message escaped static checking")
  }
}

///|
test "import validation rejects caller capture in an uninvoked function default" {
  let entry = sequence_local(
    [("caller_default", sequence_num(99))],
    sequence_call("type", [import_validation_file("bad-default")]),
  )
  for handmade in [false, true] {
    let requests : Map[(String, String), Bool] = Map([])
    let program = ordering_program(entry, handmade)
    assert_eq(requests.length(), 0)
    import_validation_static(program, requests, "memory/bad-default.libsonnet")
    assert_true(requests.contains(("ordering-entry", "bad-default")))
    assert_eq(requests.length(), 1)
  }
}

///|
test "import validation checks a true assertion message before observing object type" {
  let entry = sequence_local(
    [("caller_message", reflect_string("caller"))],
    sequence_call("type", [import_validation_file("bad-message")]),
  )
  for handmade in [false, true] {
    let requests : Map[(String, String), Bool] = Map([])
    let program = ordering_program(entry, handmade)
    assert_eq(requests.length(), 0)
    import_validation_static(program, requests, "memory/bad-message.libsonnet")
    assert_true(requests.contains(("ordering-entry", "bad-message")))
    assert_eq(requests.length(), 1)
  }
}

///|
test "import validation skips dormant and overridden dependencies but checks a forced default" {
  for mode in ["unused", "factory-type", "override", "force"] {
    let factory = import_validation_file("factory")
    let body = match mode {
      "unused" =>
        sequence_local(
          [("unused", import_validation_file("bad-message"))],
          sequence_num(42),
        )
      "factory-type" => sequence_call("type", [factory])
      "override" =>
        import_validation_call(factory, [
          (
            Some("config"),
            reflect_object([(reflect_string("limit"), 1, sequence_num(7))]),
          ),
        ])
      _ => import_validation_call(factory, [])
    }
    let entry = sequence_local(
      [("caller_message", reflect_string("caller"))],
      body,
    )
    for handmade in [false, true] {
      let requests : Map[(String, String), Bool] = Map([])
      let program = ordering_program(entry, handmade)
      assert_eq(requests.length(), 0)
      if mode == "force" {
        import_validation_static(
          program, requests, "memory/bad-message.libsonnet",
        )
        assert_true(requests.contains(("ordering-entry", "factory")))
        assert_true(
          requests.contains(("memory/factory.libsonnet", "bad-message")),
        )
        assert_eq(requests.length(), 2)
      } else {
        let expected : Json = match mode {
          "unused" => 42
          "factory-type" => "function"
          _ => { "limit": 7 }
        }
        assert_eq(
          program.evaluate(
            resolver=(from, path) => {
              import_validation_resolve(from, path, requests)
            },
            limits=import_closure_limits(),
          ),
          expected,
        )
        assert_true(
          !requests.contains(("memory/factory.libsonnet", "bad-message")),
        )
        assert_true(!requests.contains(("ordering-entry", "bad-message")))
        if mode == "unused" {
          assert_eq(requests.length(), 0)
        } else {
          assert_true(requests.contains(("ordering-entry", "factory")))
          assert_eq(requests.length(), 1)
        }
      }
    }
  }
}

///|
test "import validation preserves module policy and final receiver across a config override" {
  let entry = sequence_local(
    [
      ("policy", sequence_num(99)),
      ("base", import_validation_file("config")),
      (
        "derived",
        ordering_binary(
          sequence_var("base"),
          "+",
          reflect_object([(reflect_string("limit"), 1, sequence_num(2))]),
        ),
      ),
    ],
    ordering_array([
      pair_expr("[]", sequence_var("base"), reflect_string("value")),
      pair_expr("[]", sequence_var("derived"), reflect_string("value")),
      pair_expr("[]", sequence_var("base"), reflect_string("value")),
    ]),
  )
  for handmade in [false, true] {
    let requests : Map[(String, String), Bool] = Map([])
    let program = ordering_program(entry, handmade)
    assert_eq(requests.length(), 0)
    assert_eq(
      program.evaluate(
        resolver=(from, path) => import_validation_resolve(from, path, requests),
        limits=import_closure_limits(),
      ),
      [1, 2, 1],
    )
    assert_true(requests.contains(("ordering-entry", "config")))
    assert_eq(requests.length(), 1)
  }
}
