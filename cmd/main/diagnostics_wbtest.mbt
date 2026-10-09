///|
test "entry diagnostic paths preserve canonical identities and message data" {
  let canonical = "/root/entry.jsonnet"
  let location : @moonjsonnet.Location = {
    file: canonical,
    line: 1,
    column: 2,
  }
  let imported : @moonjsonnet.Location = {
    file: "/root/imported.libsonnet",
    line: 3,
    column: 4,
  }
  let diagnostic : @moonjsonnet.Diagnostic = {
    kind: @moonjsonnet.Runtime,
    message: "literal " + canonical,
    location,
    context: [location, imported],
    trace: [
      { location: @moonjsonnet.Synthetic("During evaluation"), name: "", },
      {
        location: @moonjsonnet.Source({ begin: imported, end: imported, }),
        name: "import",
      },
      {
        location: @moonjsonnet.Source({
          begin: location,
          end: { ..location, column: 5, },
        }),
        name: "$",
      },
    ],
  }
  let rendered = @moonjsonnet.DiagnosticFormatter::new().format(
    entry_diagnostic(diagnostic, Some((canonical, "entry.jsonnet"))),
  )
  assert_eq(
    rendered, "RUNTIME ERROR: literal /root/entry.jsonnet\n\tentry.jsonnet:1:2-5\t$\n\t/root/imported.libsonnet:3:4\timport\n\tDuring evaluation\t\n",
  )
  assert_eq(diagnostic.location.file, canonical)
  assert_eq(diagnostic.context[0].file, canonical)
  assert_true(
    diagnostic.trace[2].location is @moonjsonnet.Source(range) &&
    range.begin.file == canonical &&
    range.end.file == canonical,
  )
  assert_eq(
    @moonjsonnet.DiagnosticFormatter::new().format(
      entry_diagnostic(diagnostic, None),
    ),
    @moonjsonnet.DiagnosticFormatter::new().format(diagnostic),
  )
}

///|
test "entry trace display preserves message bytes and imported filenames" {
  let canonical = "/root/entry.jsonnet"
  let location : @moonjsonnet.Location = {
    file: canonical,
    line: 4,
    column: 9,
  }
  let names = Some((canonical, "entry.jsonnet"))
  assert_eq(
    entry_trace(location, "literal " + canonical + "\n中", names),
    "TRACE: entry.jsonnet:4 literal /root/entry.jsonnet\n中",
  )
  assert_eq(location.file, canonical)
  assert_eq(
    entry_trace(
      { ..location, file: "/root/imported.libsonnet", },
      "import",
      names,
    ),
    "TRACE: /root/imported.libsonnet:4 import",
  )
  assert_eq(
    entry_trace(location, "original", None),
    "TRACE: /root/entry.jsonnet:4 original",
  )
}

///|
test "entry trace presentation retains canonical std.thisFile value" {
  let canonical = "/root/entry.jsonnet"
  let lines = []
  let value = @moonjsonnet.evaluate(
    "std.trace('entry', std.thisFile)",
    filename=canonical,
    trace=(location, message) => {
      lines.push(
        entry_trace(location, message, Some((canonical, "entry.jsonnet"))),
      )
    },
  )
  assert_eq(value, Json::string(canonical))
  assert_eq(lines, ["TRACE: entry.jsonnet:1 entry"])
}

///|
test "entry syntax diagnostics retain source snippets under display names" {
  let canonical = "/root/entry.jsonnet"
  let source = "local"
  let formatter = @moonjsonnet.DiagnosticFormatter::new()
  formatter.set_source({ id: "entry.jsonnet", text: source, })
  try @moonjsonnet.Program::parse(source, filename=canonical) catch {
    @moonjsonnet.Error(diagnostic) => {
      let display = entry_diagnostic(
        diagnostic,
        Some((canonical, "entry.jsonnet")),
      )
      assert_eq(display.location.file, "entry.jsonnet")
      assert_eq(diagnostic.location.file, canonical)
      assert_true(
        formatter
        .format(display)
        .has_prefix(
          "entry.jsonnet:1:6 Expected token IDENTIFIER but got end of file\n",
        ),
      )
    }
  } noraise {
    _ => fail("expected syntax diagnostic")
  }
}
