///|
// Enable upstream definitions only after their dependencies and behavior have
// been validated. Native fields override the source layer in Vm::base_env.
fn standard_library_expression() -> Expr raise {
  let source = parse(standard_library_source(), "<std>", 512)
  guard source.kind is Obj(fields, locals, assertions) else {
    raise problem(Runtime, source.loc, "standard library must be an object")
  }
  let enabled = fields.filter(fn(field) {
    match field.key.kind {
      Literal(String(name)) =>
        match name {
          "uniq"
          | "set"
          | "setUnion"
          | "setInter"
          | "setDiff"
          | "setMember"
          | "mergePatch" => true
          _ => false
        }
      _ => false
    }
  })
  { kind: Obj(enabled, locals, assertions), loc: source.loc, }
}
