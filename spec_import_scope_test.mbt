// Fixed spec.html Core Syntax defines lazy import loading and independent
// static checking of each imported file.

///|
test "imported free variables cannot capture caller locals" {
  let mut reads = 0
  let resolver : (String, String) -> @moonjsonnet.Source raise = (_, _) => {
    reads += 1
    { id: "dep.libsonnet", text: "x", }
  }
  let entry = @moonjsonnet.Program::parse(
    "local x=42; import 'dep'",
    filename="entry.jsonnet",
  )
  assert_eq(reads, 0)
  try entry.evaluate(resolver~) catch {
    @moonjsonnet.Error(d) => {
      assert_eq(d.kind, @moonjsonnet.Static)
      assert_eq(d.location.file, "dep.libsonnet")
      assert_true(d.context.iter().any(loc => loc.file == "entry.jsonnet"))
    }
  } noraise {
    _ => fail("imported x captured the caller local")
  }
  assert_eq(reads, 1)
}

///|
test "unused imports never resolve even when the target would fail parsing" {
  let mut reads = 0
  let resolver : (String, String) -> @moonjsonnet.Source raise = (_, _) => {
    reads += 1
    { id: "unavailable.libsonnet", text: "{", }
  }
  for
    (source, expected) in [
      ("local unused=import 'dep'; 42", 42),
      ("if false then import 'dep' else 42", 42),
      ("(function(unused)42)(import 'dep')", 42),
      ("(function(unused=import 'dep')42)()", 42),
      ("({good:42,hidden::import 'dep'}).good", 42),
      ("std.length([import 'dep'])", 1),
    ] {
    let program = @moonjsonnet.Program::parse(source)
    assert_eq(program.evaluate(resolver~), Json::number(expected.to_double()))
    assert_eq(reads, 0)
  }
}

///|
test "import syntax and statics are checked only when the import is forced" {
  for
    (text, kind) in [
      ("missing", @moonjsonnet.Static),
      ("{", @moonjsonnet.Syntax),
    ] {
    let evaluator = @moonjsonnet.Evaluator::new()
    let mut reads = 0
    evaluator.set_importer(resolver=(_, _) => {
      reads += 1
      { id: "dep.libsonnet", text, }
    })
    let entry = @moonjsonnet.Program::parse(
      "local unused=import 'dep'; if std.extVar('force') then unused else 42",
      filename="entry.jsonnet",
    )
    evaluator.ext_var("force", false)
    assert_eq(evaluator.evaluate(entry), 42)
    assert_eq(reads, 0)
    evaluator.ext_var("force", true)
    try evaluator.evaluate(entry) catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, kind)
        assert_eq(d.location.file, "dep.libsonnet")
        assert_true(d.context.iter().any(loc => loc.file == "entry.jsonnet"))
      }
    } noraise {
      _ => fail("forced import did not report its own compile error")
    }
    assert_eq(reads, 1)
  }
  assert_eq(
    @moonjsonnet.evaluate("local x=42; import 'dep'", resolver=(_, _) => {
      id: "dep.libsonnet",
      text: "local x=7; x",
    }),
    7,
  )
}
