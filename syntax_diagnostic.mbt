///|
/// Render a raw-parser diagnostic in Go formatter style, without a final LF.
/// Successful lexing supplies the offending token's exclusive end position;
/// lexer failures and EOF retain a point location. This is a syntax rendering
/// helper, not an evaluator stack formatter. Source lookup is limited to 1 MiB.
/// Computed import operands are reparsed under default syntax budgets to recover
/// their complete range; budget failure falls back to the opening token.
pub fn Diagnostic::format_syntax(self : Diagnostic, source : String) -> String {
  self.render_syntax_site(self.syntax_error_site(source))
}

///|
fn Diagnostic::render_syntax_site(
  self : Diagnostic,
  site : (Token, SourceRange)?,
) -> String {
  let point = ({ begin: self.location, end: self.location, } : SourceRange).format()
  (match site {
    Some((_, range)) => range.format()
    None => point
  }) +
  " " +
  self.message
}

///|
fn Diagnostic::syntax_error_site(
  self : Diagnostic,
  source : String,
) -> (Token, SourceRange)? {
  if (self.kind == Syntax || self.kind == Static) &&
    @utf8.encode(source).length() <= SyntaxLimits::default().source_bytes {
    let tokens = lex(source, self.location.file) catch { _ => [] }
    for i, token in tokens {
      if token.loc == self.location && token.text != "<eof>" {
        let end = if self.message == "Computed imports are not allowed" {
          // The parser rejects a complete import operand, rather than just its
          // opening token. Reuse its bounded expression parser to recover that
          // range, including grouping parentheses, without resolving imports.
          let limits = SyntaxLimits::default()
          let parser : Parser = {
            tokens,
            pos: i,
            depth: 0,
            max_depth: limits.parser_depth,
            expression_end: token.loc,
            raw_spans: None,
          }
          try {
            let operand = parser.expr(0)
            check_ast_depth(operand, limits.tree_depth)
            check_ast_nodes(operand, limits.nodes)
            parser.expression_end
          } catch {
            _ => token.end
          }
        } else {
          token.end
        }
        return Some((token, { begin: token.loc, end, }))
      }
    }
  }
  None
}

///|
/// Render exact raw-parser diagnostic bytes, without a final LF. Fixed Go
/// truncates malformed Unicode context at four bytes, potentially splitting a
/// UTF-8 character; this byte API preserves that behavior. The String helper
/// retains the normalized message exposed by Diagnostic instead.
pub fn Diagnostic::format_syntax_bytes(
  self : Diagnostic,
  source : String,
) -> Bytes {
  let site = self.syntax_error_site(source)
  let rendered = self.render_syntax_site(site)
  if site is Some((token, _)) && token.value is Some(String(raw)) {
    for
      marker in [
        "Unicode escape sequence was malformed: ", "Unicode low surrogate escape sequence was malformed: ",
      ] {
      if rendered.find(marker) is Some(i) {
        let bytes = @utf8.encode(raw)
        if bytes.length() >= 4 {
          let prefix = @utf8.encode(rendered[:i + marker.length()].to_owned()).to_array()
          prefix.append(bytes[:4].to_array())
          return Bytes::from_array(prefix)
        }
      }
    }
  }
  @utf8.encode(rendered)
}
