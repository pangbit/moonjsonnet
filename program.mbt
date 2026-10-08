///|
/// A validated program with fixed source identity. Its AST is isolated and can be
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
        trace: [],
      })
  }
}

///|
/// Return an editable deep copy of the program's semantic AST. Mutating this
/// tree cannot alter the program, imported caches, or another returned copy.
pub fn Program::ast(self : Program) -> Ast {
  export_ast(self.expression)
}

///|
/// Copy and validate a manually constructed or edited AST without execution.
/// Depth and steps bound conversion, including cycles in caller-owned arrays.
/// There is no source text byte count for a synthetic AST. Evaluation retains
/// all ordinary runtime limits. Filename defaults to the root location's file;
/// individual node locations are retained for diagnostics.
///
/// ```mbt check
/// test {
///   let tree = @moonjsonnet.Program::parse("21").ast()
///   let edited = { ..tree, kind: @moonjsonnet.AstKind::Binary("*", tree, tree), }
///   assert_eq(@moonjsonnet.Program::from_ast(edited).evaluate(), 441)
/// }
/// ```
pub fn Program::from_ast(
  tree : Ast,
  filename? : String,
  anonymous? : Bool = false,
  limits? : Limits = Limits::default(),
  assertion_ranges? : Map[String, SourceRange] = Map([]),
) -> Program raise JsonnetError {
  try {
    check_limits(limits, tree.loc)
    let reader : AstReader = { limits, nodes: 0, assertion_ranges, }
    let expression = reader.read(tree, 0)
    validate(expression, ["std"], false)
    {
      expression,
      filename: filename.unwrap_or(tree.loc.file),
      anonymous,
      source_bytes: 0,
    }
  } catch {
    Error(d) => raise Error(d)
    e => raise problem(Runtime, tree.loc, e.to_string())
  }
}

///|
/// Copy a tree (including a subtree with free variables), checking shape and
/// depth/node budgets. Scope validation happens when constructing a Program.
pub fn Ast::clone(
  self : Ast,
  limits? : Limits = Limits::default(),
) -> Ast raise JsonnetError {
  check_limits(limits, self.loc)
  let reader : AstReader = { limits, nodes: 0, assertion_ranges: Map([]), }
  export_ast(reader.read(self, 0))
}
