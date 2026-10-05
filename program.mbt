///|
/// A validated program with fixed source identity. Its AST is private and can be
/// reused across evaluations; values, imports and resource counters are not shared.
pub struct Program {
  priv expression : Expr
  priv filename : String
  priv anonymous : Bool
  priv source_bytes : Int
}

///|
/// Parse and statically validate source without evaluating it or resolving imports.
/// Creation enforces source and parser/AST depth limits. Evaluation rechecks source
/// bytes and AST depth against its own limits, without reparsing the source.
///
/// ```mbt check
/// test {
///   let program = @moonjsonnet.Program::parse("std.extVar('x') * 2")
///   assert_eq(program.evaluate(ext_vars=Map([("x", 21)])), 42)
///   assert_eq(program.evaluate(ext_vars=Map([("x", 3)])), 6)
/// }
/// ```
pub fn Program::parse(
  source : String,
  filename? : String = "<input>",
  anonymous? : Bool = false,
  limits? : Limits = Limits::default(),
) -> Program raise JsonnetError {
  let loc : Location = { file: filename, line: 1, column: 1, }
  try {
    check_limits(limits, loc)
    let source_bytes = @utf8.encode(source).length()
    if source_bytes > limits.source_bytes {
      raise problem(Limit, loc, "source byte limit exceeded")
    }
    {
      expression: parse(source, filename, limits.depth),
      filename,
      anonymous,
      source_bytes,
    }
  } catch {
    Error(d) => raise Error(d)
    e =>
      raise Error({
        kind: Runtime,
        location: loc,
        message: e.to_string(),
        context: [],
      })
  }
}
