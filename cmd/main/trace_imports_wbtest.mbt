///|
test "import trace names use cached local requests and nested display parents" {
  let host = @fs.FileHost::new("/")
  let id = "/real/library.libsonnet"
  host.attempts["/project/library.libsonnet"] = Some({ id, bytes: b"", })
  let names = Map([("/real/main.jsonnet", "project/main.jsonnet")])
  assert_eq(
    import_trace_name(
      host,
      "/real/main.jsonnet",
      "./library.libsonnet",
      id,
      names,
      [],
    ),
    "project/library.libsonnet",
  )
  names[id] = "project/alias.libsonnet"
  let nested = "/real/nested.libsonnet"
  host.attempts["/project/nested.libsonnet"] = Some({ id: nested, bytes: b"", })
  assert_eq(
    import_trace_name(host, id, "./nested.libsonnet", nested, names, []),
    "project/nested.libsonnet",
  )
  assert_eq(host.attempts.length(), 2)
  let location : @moonjsonnet.Location = { file: id, line: 3, column: 5, }
  assert_eq(
    source_trace(location, "literal " + id + "\n中", names),
    "TRACE: project/alias.libsonnet:3 literal /real/library.libsonnet\n中",
  )
  assert_eq(location.file, id)
}

///|
test "import trace names follow cached library priority and raw absolute spelling" {
  let host = @fs.FileHost::new("/")
  let id = "/real/library.libsonnet"
  host.attempts["/library.libsonnet"] = None
  host.attempts["/high/library.libsonnet"] = Some({ id, bytes: b"", })
  host.attempts["/low/library.libsonnet"] = Some({ id, bytes: b"", })
  let names = Map([("/app/main.jsonnet", "main.jsonnet")])
  assert_eq(
    import_trace_name(
      host,
      "/app/main.jsonnet",
      "library.libsonnet",
      id,
      names,
      ["low", "high"],
    ),
    "high/library.libsonnet",
  )
  let absolute = "/real/dots/../library.libsonnet"
  host.attempts[absolute] = Some({ id, bytes: b"", })
  assert_eq(import_trace_name(host, "", absolute, id, names, []), absolute)
  assert_eq(import_trace_name(host, "", "missing", id, names, []), id)
  assert_eq(host.attempts.length(), 4)
}
