///|
test "evaluator queries share source and AST caches without execution" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let mut reads = 0
  let mut calls = 0
  let traces = []
  evaluator.native_function("tick", {
    params: [],
    callback: fn(_) {
      calls += 1
      42
    },
  })
  evaluator.set_trace(fn(_, message) { traces.push(message) })
  evaluator.set_importer(binary_resolver=fn(_, path) {
    reads += 1
    {
      id: "lib/" + path,
      bytes: if path == "main" {
        b"std.trace('run',std.native('tick')()) + (import 'dep')"
      } else {
        b"1"
      },
    }
  })
  assert_eq(evaluator.resolve_import("entry", "main"), "lib/main")
  assert_eq(evaluator.import_data("entry", "main").id, "lib/main")
  let (program, id) = evaluator.import_program("entry", "main")
  assert_eq(id, "lib/main")
  assert_eq(evaluator.find_dependencies("entry", ["main"]), ["lib/dep"])
  assert_eq((reads, calls), (2, 0))
  assert_eq(traces, [])
  let entry = @moonjsonnet.Program::parse("import 'main'", filename="entry")
  assert_eq(evaluator.evaluate(entry), 43)
  assert_eq(evaluator.evaluate(entry), 43)
  assert_eq((reads, calls), (2, 1))
  assert_eq(evaluator.evaluate(program), 43)
  assert_eq((reads, calls), (2, 2))
  assert_eq(traces, ["run", "run"])
  evaluator.ext_var("unrelated", 1)
  assert_eq(evaluator.find_dependencies("entry", ["main"]), ["lib/dep"])
  assert_eq((reads, calls), (2, 2))
  assert_eq(evaluator.evaluate(entry), 43)
  assert_eq((reads, calls), (2, 3))
}

///|
test "evaluator raw queries preserve invalid UTF8 and unified import callbacks" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let mut reads = 0
  evaluator.set_importer(binary_resolver=fn(_, path) {
    reads += 1
    { id: path, bytes: b"\xff\x00", }
  })
  assert_eq(evaluator.resolve_import("entry", "data"), "data")
  assert_eq(evaluator.import_data("entry", "data").bytes, b"\xff\x00")
  assert_eq(
    evaluator.evaluate(
      @moonjsonnet.Program::parse("importbin 'data'", filename="entry"),
    ),
    [255, 0],
  )
  for _ in 0..<2 {
    try evaluator.import_program("entry", "data") catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Import)
        assert_eq(d.message, "invalid UTF-8")
        assert_eq(d.location.file, "data")
      }
    } noraise {
      _ => fail("expected invalid UTF8")
    }
  }
  assert_eq(reads, 1)
  evaluator.set_importer(resolver=fn(_, path) { { id: path, text: "'é'", } })
  assert_eq(evaluator.import_data("", "data").bytes, b"'\xc3\xa9'")
  assert_eq(
    evaluator.evaluate(@moonjsonnet.Program::parse("import 'data'")),
    Json::string("é"),
  )
  assert_eq(
    evaluator.evaluate(@moonjsonnet.Program::parse("importbin 'data'")),
    [39, 195, 169, 39],
  )
  evaluator.set_importer(resolver=fn(_, path) { { id: path, text: "2", } }, binary_resolver=fn(
    _,
    path,
  ) {
    { id: path, bytes: b"1", }
  })
  assert_eq(evaluator.evaluate(@moonjsonnet.Program::parse("import 'data'")), 1)
}

///|
test "evaluator imported program errors retain source until importer replacement" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let mut reads = 0
  let mut text = "missing"
  let resolver : (String, String) -> @moonjsonnet.Source raise = (_, path) => {
    reads += 1
    { id: path, text, }
  }
  evaluator.set_importer(resolver~)
  for _ in 0..<2 {
    try evaluator.import_program("", "bad") catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Static)
        assert_eq(d.location.file, "bad")
      }
    } noraise {
      _ => fail("expected static validation failure")
    }
  }
  assert_eq(reads, 1)
  text = "std.thisFile"
  evaluator.set_importer(resolver~)
  let (program, id) = evaluator.import_program("", "bad")
  assert_eq(id, "bad")
  assert_eq(program.evaluate(), Json::string("bad"))
  assert_eq(reads, 2)
}

///|
test "evaluator query and scan budgets reset and cover cached sources" {
  let evaluator = @moonjsonnet.Evaluator::new()
  evaluator.set_importer(binary_resolver=fn(_, path) {
    {
      id: path,
      bytes: if path == "main" {
        b"import 'dep'"
      } else {
        b"[[[[[42]]]]]"
      },
    }
  })
  ignore(evaluator.find_dependencies("", ["main"]))
  evaluator.set_limits({ ..@moonjsonnet.Limits::default(), import_bytes: 1, })
  try evaluator.import_data("", "main") catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected cached source byte budget")
  }
  evaluator.set_limits({ ..@moonjsonnet.Limits::default(), imports: 1, })
  assert_eq(evaluator.resolve_import("", "main"), "main")
  try evaluator.find_dependencies("", ["main"]) catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected cumulative import count")
  }
  evaluator.set_limits({ ..@moonjsonnet.Limits::default(), depth: 4, })
  try evaluator.import_program("", "dep") catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected cached AST depth")
  }
  try evaluator.find_dependencies("", ["main"]) catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected cached scan AST depth")
  }
  evaluator.set_limits(@moonjsonnet.Limits::default())
  assert_eq(evaluator.find_dependencies("", ["main"]), ["dep"])
}

///|
test "evaluator query callbacks reject reentry and restore idle state" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let mut reentries = 0
  evaluator.set_importer(binary_resolver=(_, path) => {
    try evaluator.resolve_import("", "again") catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Runtime)
        reentries += 1
      }
    } noraise {
      _ => fail("expected reentry guard")
    }
    { id: path, bytes: b"42", }
  })
  assert_eq(evaluator.resolve_import("", "once"), "once")
  assert_eq(reentries, 1)
  let (program, _) = evaluator.import_program("", "once")
  assert_eq(evaluator.evaluate(program), 42)
}
