///|
/// Original lexical material retained for source tooling.
pub(all) enum SourcePartKind {
  TokenText
  Whitespace
  LineComment
  BlockComment
} derive(Eq)

///|
pub extend SourcePartKind with Eq::{equal, not_equal}

///|
pub(all) struct SourcePart {
  kind : SourcePartKind
  text : String
  range : SourceRange
}

///|
/// Parsed source with exact lexical spelling and trivia, before scope checking.
/// Returned parts and AST containers are independent copies.
pub struct ParsedSource {
  priv tokens : Array[Token]
  priv expression : Expr
}

///|
/// Parse without evaluation or lexical-scope validation. Source and AST depth
/// limits apply. Undefined names can be retained for formatting or analysis;
/// Program::from_ast performs scope validation before execution.
pub fn ParsedSource::parse(
  source : String,
  filename? : String = "<input>",
  limits? : Limits = Limits::default(),
) -> ParsedSource raise JsonnetError {
  let loc : Location = { file: filename, line: 1, column: 1, }
  try {
    check_limits(limits, loc)
    if @utf8.encode(source).length() > limits.source_bytes {
      raise problem(Limit, loc, "source byte limit exceeded")
    }
    let tokens = lex(source, filename, retain_trivia=true)
    { tokens, expression: parse_tokens(tokens, limits.depth), }
  } catch {
    Error(d) => raise Error(d)
    e => raise problem(Runtime, loc, e.to_string())
  }
}

///|
/// Return tokens and intervening trivia in source order, including trailing
/// trivia. Ranges use one-based UTF-8 byte columns and exclusive ends.
pub fn ParsedSource::parts(self : ParsedSource) -> Array[SourcePart] {
  let parts = []
  for token in self.tokens {
    for trivia in token.leading {
      parts.push({ kind: trivia.kind, text: trivia.raw, range: trivia.range, })
    }
    if !token.raw.is_empty() {
      parts.push({
        kind: TokenText,
        text: token.raw,
        range: { begin: token.loc, end: token.end, },
      })
    }
  }
  parts
}

///|
/// Reconstruct the original source exactly, including comments and line endings.
pub fn ParsedSource::text(self : ParsedSource) -> String {
  let out = StringBuilder()
  for part in self.parts() {
    out.write_string(part.text)
  }
  out.to_string()
}

///|
/// Return an independent semantic AST view. It omits syntax sugar and trivia;
/// edits to this view do not change the retained source or its parts.
pub fn ParsedSource::ast(self : ParsedSource) -> Ast {
  export_ast(self.expression)
}
