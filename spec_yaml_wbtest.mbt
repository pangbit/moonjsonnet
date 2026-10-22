///|
test "P0 YAML rejects nonfinite internal values defensively" {
  let evaluator = Evaluator::new()
  ignore(evaluator.evaluate(Program::parse("0")))
  guard evaluator.state is Some(vm) else { fail("missing VM state") }
  let loc = { file: "synthetic-nonfinite", line: 1, column: 1, }
  for number in [1.0 / 0.0, -1.0 / 0.0, 0.0 / 0.0] {
    let out = ManifestText::new(1000, loc)
    try vm.yaml_value(Num(number), false, true, "", 0, out, loc) catch {
      Error(d) => assert_eq(d.kind, Runtime)
      e => raise e
    } noraise {
      _ => fail("expected YAML number error")
    }
    assert_eq(out.text(), "")
  }
}
