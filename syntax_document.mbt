///|
/// Source-tooling budgets, independent of evaluator Limits. The complete tree
/// is admitted before export or formatting; parsing still has a recursive cap.
pub(all) struct SyntaxLimits {
  parser_depth : Int32
  tree_depth : Int32
  nodes : Int32
  steps : Int32
  source_bytes : Int32
  output_bytes : Int32
} derive(Debug)

///|
pub extend SyntaxLimits with @debug.Debug::{to_repr}

///|
pub fn SyntaxLimits::default() -> SyntaxLimits {
  {
    parser_depth: 200,
    tree_depth: 4096,
    nodes: 1000000,
    steps: 1000000,
    source_bytes: 1048576,
    output_bytes: 4194304,
  }
}

///|
fn check_syntax_limits(
  limits : SyntaxLimits,
  loc : Location,
) -> Unit raise JsonnetError {
  if limits.parser_depth <= 0 ||
    limits.parser_depth > 512 ||
    limits.tree_depth <= 0 ||
    limits.tree_depth > 16384 ||
    limits.nodes <= 0 ||
    limits.steps <= 0 ||
    limits.source_bytes <= 0 ||
    limits.output_bytes <= 0 {
    raise problem(
      Limit,
      loc,
      "syntax limits must be positive; parser depth at most 512; tree depth at most 16384",
    )
  }
}

///|
fn SyntaxLimits::output_limits(self : SyntaxLimits) -> Limits {
  {
    ..Limits::default(),
    depth: self.parser_depth,
    steps: self.steps,
    source_bytes: self.source_bytes,
    output_bytes: self.output_bytes,
  }
}

///|
/// Source document admitted with independent syntax budgets. It retains exact
/// spelling and trivia and never performs evaluation or import resolution.
/// Returning its semantic AST does not grant evaluator admission.
pub struct SyntaxDocument {
  priv document : ParsedSource
}

///|
pub fn SyntaxDocument::parse(
  source : String,
  filename~ : String = "<input>",
  limits~ : SyntaxLimits = SyntaxLimits::default(),
) -> SyntaxDocument raise JsonnetError {
  let loc : Location = { file: filename, line: 1, column: 1, }
  try {
    check_syntax_limits(limits, loc)
    if @utf8.encode(source).length() > limits.source_bytes {
      raise problem(Limit, loc, "source byte limit exceeded")
    }
    let tokens = lex(source, filename, retain_trivia=true)
    let expression = parse_tokens(
      tokens,
      limits.parser_depth,
      tree_depth=limits.tree_depth,
      node_limit=limits.nodes,
    )
    { document: { tokens, expression, }, }
  } catch {
    Error(d) => raise Error(d)
    e => raise problem(Runtime, loc, e.to_string())
  }
}

///|
/// Return the retained source exactly, including original line endings.
pub fn SyntaxDocument::text(self : SyntaxDocument) -> String {
  self.document.text()
}

///|
/// Return independent lexical parts with their original UTF-8 byte ranges.
pub fn SyntaxDocument::parts(self : SyntaxDocument) -> Array[SourcePart] {
  self.document.parts()
}

///|
/// Export an independent semantic AST iteratively. Program::from_ast checks
/// evaluator budgets and scope separately before execution.
pub fn SyntaxDocument::ast(self : SyntaxDocument) -> Ast {
  self.document.ast()
}

///|
/// Recheck source/tree/node budgets and format without mutating the document.
pub fn SyntaxDocument::format(
  self : SyntaxDocument,
  options~ : FormatOptions = FormatOptions::default(),
  limits~ : SyntaxLimits = SyntaxLimits::default(),
) -> String raise JsonnetError {
  let document = self.document
  let loc = document.expression.loc
  check_syntax_limits(limits, loc)
  if @utf8.encode(document.text()).length() > limits.source_bytes {
    raise problem(Limit, loc, "source byte limit exceeded")
  }
  check_ast_depth(document.expression, limits.tree_depth) catch {
    Error(d) => raise Error(d)
    e => raise problem(Runtime, loc, e.to_string())
  }
  check_ast_nodes(document.expression, limits.nodes) catch {
    Error(d) => raise Error(d)
    e => raise problem(Runtime, loc, e.to_string())
  }
  format_tokens(
    document.tokens,
    document.expression,
    options,
    limits.output_limits(),
    loc,
    limits.tree_depth,
    Some(limits.nodes),
  )
}

///|
/// Format source under independent syntax budgets, without evaluator admission.
///
/// ```mbt check
/// test {
///   assert_eq(@moonjsonnet.format_syntax_source("[1,2]"), "[1, 2]\n")
/// }
/// ```
pub fn format_syntax_source(
  source : String,
  filename~ : String = "<input>",
  options~ : FormatOptions = FormatOptions::default(),
  limits~ : SyntaxLimits = SyntaxLimits::default(),
) -> String raise JsonnetError {
  SyntaxDocument::parse(source, filename~, limits~).format(options~, limits~)
}
