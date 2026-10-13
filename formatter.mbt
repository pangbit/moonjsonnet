// Portions adapted from google/go-jsonnet v0.21.0 (Apache-2.0).
// https://github.com/google/go-jsonnet/tree/67968688d9952f50662e979fab1bef889d0d3e57
// Source: internal/formatter/jsonnetfmt.go
// Source: internal/formatter/unparser.go
// Source: internal/parser/lexer.go
// Copyright 2019 Google Inc. All rights reserved.
// Copyright 2016 Google Inc. All rights reserved.
// Modifications: Implemented formatting controls and structural emission with local syntax containers and budgets.
// License and retained attribution: LICENSE and NOTICE at the module root.

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
/// See docs/COMPATIBILITY.md for the bounded formatter validation scope.
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
/// Format source without evaluation or import resolution.
/// See docs/COMPATIBILITY.md for the tested Go compatibility scope.
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
  format_tokens(
    self.tokens,
    self.expression,
    options,
    limits,
    loc,
    limits.depth,
    None,
  )
}

///|
pub extend FormatStringStyle with Eq::{equal, not_equal}

///|
pub extend FormatCommentStyle with Eq::{equal, not_equal}
