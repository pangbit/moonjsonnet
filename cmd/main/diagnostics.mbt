///|
// Only presentation uses the entry's invocation path. This copies locations
// without changing canonical source identities or user-authored messages.
fn entry_diagnostic(
  diagnostic : @moonjsonnet.Diagnostic,
  entry_name : (String, String)?,
) -> @moonjsonnet.Diagnostic {
  guard entry_name is Some((canonical, display)) else { return diagnostic }
  let rename = fn(location : @moonjsonnet.Location) {
    if location.file == canonical {
      { ..location, file: display, }
    } else {
      location
    }
  }
  {
    ..diagnostic,
    location: rename(diagnostic.location),
    context: diagnostic.context.map(rename),
    trace: diagnostic.trace.map(fn(frame) {
      match frame.location {
        @moonjsonnet.Source(range) =>
          {
            ..frame,
            location: @moonjsonnet.Source({
              begin: rename(range.begin),
              end: rename(range.end),
            }),
          }
        @moonjsonnet.Synthetic(_) => frame
      }
    }),
  }
}

///|
fn entry_trace(
  location : @moonjsonnet.Location,
  message : String,
  entry_name : (String, String)?,
) -> String {
  let file = match entry_name {
    Some((canonical, display)) if location.file == canonical => display
    _ => location.file
  }
  "TRACE: \{file}:\{location.line} \{message}"
}
