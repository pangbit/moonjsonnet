///|
pub(all) enum FormatStringStyle {
  DoubleQuotes
  SingleQuotes
  PreserveQuotes
} derive(Eq)

///|
pub(all) enum FormatCommentStyle {
  HashComments
  SlashComments
  PreserveComments
} derive(Eq)

///|
/// Formatting controls corresponding to go-jsonnet formatter.Options.
/// Formatter compatibility is still in progress; see docs/GO-PARITY.md.
pub(all) struct FormatOptions {
  indent : Int
  max_blank_lines : Int
  string_style : FormatStringStyle
  comment_style : FormatCommentStyle
  pretty_field_names : Bool
  pad_arrays : Bool
  pad_objects : Bool
  /// Sort groups of top-level code imports; groups with duplicate names retain order.
  sort_imports : Bool
  use_implicit_plus : Bool
  strip_everything : Bool
  strip_comments : Bool
  strip_all_but_comments : Bool
}

///|
pub fn FormatOptions::default() -> FormatOptions {
  {
    indent: 2,
    max_blank_lines: 2,
    string_style: SingleQuotes,
    comment_style: SlashComments,
    pretty_field_names: true,
    pad_arrays: false,
    pad_objects: true,
    sort_imports: true,
    use_implicit_plus: true,
    strip_everything: false,
    strip_comments: false,
    strip_all_but_comments: false,
  }
}

///|
/// Format source without evaluation or import resolution. Compatibility with
/// all Go formatting passes is not yet complete.
pub fn format_source(
  source : String,
  filename? : String = "<input>",
  options? : FormatOptions = FormatOptions::default(),
  limits? : Limits = Limits::default(),
) -> String raise JsonnetError {
  ParsedSource::parse(source, filename~, limits~).format(options~, limits~)
}

///|
/// Format the retained source; the parsed document is not mutated.
pub fn ParsedSource::format(
  self : ParsedSource,
  options? : FormatOptions = FormatOptions::default(),
  limits? : Limits = Limits::default(),
) -> String raise JsonnetError {
  let loc = self.expression.loc
  check_limits(limits, loc)
  if @utf8.encode(self.text()).length() > limits.source_bytes {
    raise problem(Limit, loc, "source byte limit exceeded")
  }
  check_ast_depth(self.expression, limits.depth) catch {
    Error(d) => raise Error(d)
    e => raise problem(Runtime, loc, e.to_string())
  }
  format_tokens(self.tokens, self.expression, options, limits, loc)
}

///|
pub extend FormatStringStyle with Eq::{equal, not_equal}

///|
pub extend FormatCommentStyle with Eq::{equal, not_equal}
