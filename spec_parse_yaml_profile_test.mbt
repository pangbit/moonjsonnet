// Project extension controls only: normative acceptance is null.
// Public parseYaml does not promise empty-input or multi-document packaging.

///|
test "parseYaml preserves explicit empty input and collection stream compatibility profiles" {
  for data in ["\n", "# comment"] {
    sequence_value(yaml_parse_call(data), Json::null())
  }
  sequence_failure(yaml_parse_call(""), @moonjsonnet.Runtime, None)
  // Untagged overflow text has no fixed public scalar-schema classification.
  sequence_value(yaml_parse_call("{ok: [1],bad: [1e309]}"), {
    "ok": [1],
    "bad": ["1e309"],
  })
  sequence_value(yaml_parse_call("{a: 1}\n---\n[2]"), [{ "a": 1 }, [2]])
  sequence_value(yaml_parse_call("---\n{a: 1}"), [{ "a": 1 }])
  // The current extension decodes one document per chunk. No complete-stream
  // or trailing-data validation promise is inferred from the public paragraph.
  sequence_value(yaml_parse_call("{a: 1}\n...\nignored"), { "a": 1 })
}

///|
test "parseYaml extension propagates failures of every actually decoded document" {
  for
    data in [
      "{ok: 1}\n---\na", "{ok: 1}\n---\n{bad: [2}", "{ok: 1}\n---\n[.inf]", "---",
    ] {
    sequence_failure(
      sequence_call("type", [yaml_parse_call(data)]),
      @moonjsonnet.Runtime,
      None,
    )
  }
}
