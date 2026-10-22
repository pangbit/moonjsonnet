///|
test "P0 JSON manifestation rejects nonfinite internal values defensively" {
  let evaluator = Evaluator::new()
  ignore(evaluator.evaluate(Program::parse("0")))
  guard evaluator.state is Some(vm) else { fail("missing VM state") }
  let loc = { file: "synthetic-nonfinite", line: 1, column: 1, }
  for number in [1.0 / 0.0, -1.0 / 0.0, 0.0 / 0.0] {
    try vm.manifest(Num(number), loc, 0) catch {
      Error(d) => assert_eq(d.kind, Runtime)
      e => raise e
    } noraise {
      _ => fail("expected JSON manifestation error")
    }
    try
      vm.manifest_json_ex(Num(number), ("", "", ":"), "", 0, 1000, loc)
    catch {
      Error(d) => assert_eq(d.kind, Runtime)
      e => raise e
    } noraise {
      _ => fail("expected JSON string manifestation error")
    }
  }
}
