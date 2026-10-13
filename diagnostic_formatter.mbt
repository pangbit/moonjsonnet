// Portions adapted from google/go-jsonnet v0.21.0 (Apache-2.0).
// https://github.com/google/go-jsonnet/tree/67968688d9952f50662e979fab1bef889d0d3e57
// Source: error_formatter.go
// Source: runtime_error.go
// Source: ast/location.go
// Copyright 2017 Google Inc. All rights reserved.
// Modifications: Adapted trace cropping and source/color rendering to MoonBit diagnostics.
// License and retained attribution: LICENSE and NOTICE at the module root.

///|
/// Source spans and synthetic runtime sites share the same trace representation.
pub(all) enum TraceLocation {
  Source(SourceRange)
  Synthetic(String)
} derive(Eq, Debug)

///|
pub extend TraceLocation with Eq::{equal, not_equal}

///|
pub extend TraceLocation with @debug.Debug::{to_repr}

///|
pub(all) struct TraceFrame {
  location : TraceLocation
  name : String
} derive(Eq, Debug)

///|
pub extend TraceFrame with Eq::{equal, not_equal}

///|
pub extend TraceFrame with @debug.Debug::{to_repr}

///|
pub fn TraceLocation::format(self : TraceLocation) -> String {
  match self {
    Source(range) => range.format()
    Synthetic(message) => message
  }
}

///|
/// Go-style error rendering is separate from the legacy Diagnostic::format.
/// Source text is supplied by the host. Color transforms the selected static
/// source fragment; runtime traces do not invoke color, matching pinned Go.
pub struct DiagnosticFormatter {
  priv mut max_trace : Int
  priv mut color : ((String) -> String)?
  priv sources : Map[String, String]
}

///|
pub fn DiagnosticFormatter::new() -> DiagnosticFormatter {
  { max_trace: 20, color: None, sources: Map([]), }
}

///|
pub fn DiagnosticFormatter::set_max_trace(
  self : DiagnosticFormatter,
  size : Int,
) -> Unit {
  self.max_trace = size
}

///|
pub fn DiagnosticFormatter::set_color(
  self : DiagnosticFormatter,
  color? : (String) -> String,
) -> Unit {
  self.color = color
}

///|
pub fn DiagnosticFormatter::set_source(
  self : DiagnosticFormatter,
  source : Source,
) -> Unit {
  self.sources[source.id] = source.text
}

///|
pub fn DiagnosticFormatter::clear_sources(self : DiagnosticFormatter) -> Unit {
  self.sources.clear()
}

///|
/// Configure subsequent explicit error rendering without changing execution or
/// import caches. Omit formatter to restore a fresh default renderer per call.
pub fn Evaluator::set_diagnostic_formatter(
  self : Evaluator,
  formatter? : DiagnosticFormatter,
) -> Unit raise JsonnetError {
  self.idle()
  self.diagnostic_formatter = formatter
}

///|
pub fn Evaluator::format_error(
  self : Evaluator,
  diagnostic : Diagnostic,
) -> String {
  self.diagnostic_formatter
  .unwrap_or_else(DiagnosticFormatter::new)
  .format(diagnostic)
}

///|
pub fn Evaluator::format_error_bytes(
  self : Evaluator,
  diagnostic : Diagnostic,
) -> Bytes {
  self.diagnostic_formatter
  .unwrap_or_else(DiagnosticFormatter::new)
  .format_bytes(diagnostic)
}

///|
pub fn DiagnosticFormatter::format(
  self : DiagnosticFormatter,
  diagnostic : Diagnostic,
) -> String {
  @utf8.decode_lossy(self.format_bytes(diagnostic), ignore_bom=false)
}

///|
/// Preserve malformed-Unicode diagnostic bytes, which pinned Go may truncate
/// inside a UTF-8 character. The String API normalizes those bytes instead.
pub fn DiagnosticFormatter::format_bytes(
  self : DiagnosticFormatter,
  diagnostic : Diagnostic,
) -> Bytes {
  if (diagnostic.kind == Syntax || diagnostic.kind == Static) &&
    diagnostic.trace.any(frame => frame.location is Synthetic(_)) {
    let source = self.sources.get(diagnostic.location.file).unwrap_or("")
    let output = b"RUNTIME ERROR: ".to_array()
    output.append(diagnostic.format_syntax_bytes(source).to_array())
    output.append(b"\n".to_array())
    let frames = @utf8.encode(
      self.runtime_text({ ..diagnostic, kind: Runtime, message: "", }),
    )
    output.append(frames[b"RUNTIME ERROR: \n".length():].to_array())
    return Bytes::from_array(output)
  }
  if diagnostic.kind == Syntax || diagnostic.kind == Static {
    let source = self.sources.get(diagnostic.location.file)
    let header = diagnostic.format_syntax_bytes(source.unwrap_or(""))
    let result = header.to_array()
    result.append(b"\n".to_array())
    if source is Some(source) {
      let range = diagnostic
        .syntax_error_site(source)
        .map(site => site.1)
        .unwrap_or({ begin: diagnostic.location, end: diagnostic.location, })
      if diagnostic_source_parts(source, range)
        is Some((before, selected, after)) {
        result.append(
          @utf8.encode(
            "\n" +
            before +
            self.color.map(color => color(selected)).unwrap_or(selected) +
            after +
            "\n",
          ).to_array(),
        )
      }
    }
    result.append(b"\n".to_array())
    return Bytes::from_array(result)
  }
  @utf8.encode(self.runtime_text(diagnostic))
}

///|
fn DiagnosticFormatter::runtime_text(
  self : DiagnosticFormatter,
  diagnostic : Diagnostic,
) -> String {
  let output = StringBuilder()
  output.write_string("RUNTIME ERROR: " + diagnostic.message + "\n")
  let size = diagnostic.trace.length()
  let above = self.max_trace / 2
  let below = self.max_trace - above
  let mut index = 0
  while index < size {
    if self.max_trace > 0 && index >= above && index < size - below {
      output.write_string("\t...\n")
      index = size - below
    } else {
      let frame = diagnostic.trace[size - index - 1]
      output.write_string(
        "\t" + frame.location.format() + "\t" + frame.name + "\n",
      )
      index += 1
    }
  }
  output.to_string()
}

///|
fn diagnostic_source_parts(
  source : String,
  range : SourceRange,
) -> (String, String, String)? {
  let bytes = @utf8.encode(source)
  if bytes.length() > SyntaxLimits::default().source_bytes ||
    range.begin.line < 1 ||
    range.begin.column < 1 ||
    range.end.line < range.begin.line ||
    range.end.column < 1 {
    return None
  }
  let mut line = 1
  let mut line_start = 0
  let mut first_line = -1
  let mut selected_start = -1
  let mut selected_end = -1
  let mut last_line = -1
  for index = 0; index <= bytes.length(); index = index + 1 {
    if index == bytes.length() || bytes[index] == 10 {
      if line == range.begin.line &&
        range.begin.column - 1 <= index - line_start {
        first_line = line_start
        selected_start = line_start + range.begin.column - 1
      }
      if line == range.end.line && range.end.column - 1 <= index - line_start {
        selected_end = line_start + range.end.column - 1
        last_line = index
        break
      }
      line += 1
      line_start = index + 1
    }
  }
  if first_line < 0 ||
    selected_start < 0 ||
    selected_end < selected_start ||
    last_line < selected_end {
    return None
  }
  Some(
    (
      @utf8.decode(bytes[first_line:selected_start], ignore_bom=false),
      @utf8.decode(bytes[selected_start:selected_end], ignore_bom=false),
      @utf8.decode(bytes[selected_end:last_line], ignore_bom=false),
    ),
  ) catch {
    _ => None
  }
}
