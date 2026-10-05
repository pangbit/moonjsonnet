///|
// Parameter code uses its synthetic filename for diagnostics and std.thisFile,
// but imports resolve from an empty origin (go-jsonnet codeToPV/prepareExtVars).
fn Vm::prepare_parameters(
  self : Vm,
  values : Map[String, Json],
  code : Map[String, String],
  kind : String,
) -> Map[String, Int] {
  let result : Map[String, Int] = Map([])
  let env : Env = { parent: None, names: Map([]), import_from: "", }
  for name, json in values {
    if !code.contains(name) {
      let loc : Location = { file: "<\{kind}:\{name}>", line: 1, column: 1, }
      result[name] = self.store(
        match json {
          String(text) => Ready(Str(text))
          _ => Pending({ kind: Literal(json), loc, }, env)
        },
      )
    }
  }
  for name, source in code {
    let loc : Location = { file: "<\{kind}:\{name}>", line: 1, column: 1, }
    result[name] = self.store(Code(source, loc))
  }
  result
}
