// Portions adapted from google/go-jsonnet v0.21.0 (Apache-2.0).
// https://github.com/google/go-jsonnet/tree/67968688d9952f50662e979fab1bef889d0d3e57
// Source: ast/location.go
// Source: ast/ast.go
// Copyright 2017 Google Inc. All rights reserved.
// Copyright 2016 Google Inc. All rights reserved.
// Modifications: Adapted source-location contracts to MoonBit UTF-8 ranges and local AST metadata.
// License and retained attribution: LICENSE and NOTICE at the module root.

///|
/// Half-open source range. Lines and UTF-8 byte columns are one-based.
pub(all) struct SourceRange {
  begin : Location
  end : Location
} derive(Debug, Eq)

///|
pub extend SourceRange with @debug.Debug::{to_repr}

///|
pub extend SourceRange with Eq::{equal, not_equal}

///|
/// Return retained source coordinates, or None for a synthetic/unlocated node.
///
/// ```mbt check
/// test {
///   let node = @moonjsonnet.Program::parse("'中'", filename="example").ast()
///   assert_eq(node.source_range().unwrap().format(), "example:1:1-6")
/// }
/// ```
pub fn Ast::source_range(self : Ast) -> SourceRange? {
  self.end.map(end => { begin: self.loc, end, })
}

///|
/// Render the same-file range using Go's location-range notation.
pub fn SourceRange::format(self : SourceRange) -> String {
  let a = self.begin
  let b = self.end
  let prefix = if a.file.is_empty() { "" } else { a.file + ":" }
  if a.line == b.line {
    if a.column == b.column {
      "\{prefix}\{a.line}:\{a.column}"
    } else {
      "\{prefix}\{a.line}:\{a.column}-\{b.column}"
    }
  } else {
    "\{prefix}(\{a.line}:\{a.column})-(\{b.line}:\{b.column})"
  }
}
