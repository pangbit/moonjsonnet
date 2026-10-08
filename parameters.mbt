///|
// Parameter code uses its synthetic filename for diagnostics and std.thisFile,
// but imports resolve from an empty origin (go-jsonnet codeToPV/prepareExtVars).
// Parsed parameters preserve their AST origin while binding std.thisFile to the
// same synthetic name (go-jsonnet nodeToPV); they are checked/forced lazily.
fn Vm::prepare_parameters(
  self : Vm,
  values : Map[String, Json],
  code : Map[String, String],
  programs : Map[String, Program],
  kind : String,
) -> Map[String, Int] {
  let result : Map[String, Int] = Map([])
  let env : Env = {
    parent: None,
    names: Map([]),
    import_from: "",
    debug_visible: None,
    diagnostic_context: ("$", "anonymous"),
  }
  for name, json in values {
    if !code.contains(name) && !programs.contains(name) {
      let loc : Location = { file: "<\{kind}:\{name}>", line: 1, column: 1, }
      result[name] = self.store(
        match json {
          String(text) => Ready(Str(text))
          _ => Pending({ kind: Literal(json), loc, end: None, }, env)
        },
      )
    }
  }
  for name, source in code {
    if programs.contains(name) {
      continue
    }
    let loc : Location = { file: "<\{kind}:\{name}>", line: 1, column: 1, }
    result[name] = self.store(Code(source, loc))
  }
  for name, program in programs {
    let loc : Location = { file: "<\{kind}:\{name}>", line: 1, column: 1, }
    result[name] = self.store(ParsedParameter(program, loc))
  }
  result
}
