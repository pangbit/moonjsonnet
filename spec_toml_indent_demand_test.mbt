// Static candidate only: not formatted, compiled or executed.
// Fixed bbb38f std.jsonnet lines 918-998: indentation is used by nonempty
// multiline Arrays and emitted nested prefixes, not flat or empty output.
// Reconstructed embedded source, minus its extra final LF, matches fixed SHA-256
// e76dd6b8e51a2ca041b292dadea9c5521aeea5781b0ffe7c2c683865e7e45351.
// Literal layout oracles; source and independently constructed caller ASTs.
// First-parameter toml/value naming, nonstring coercion, numeric formatting,
// empty-key spelling, A0/N0/R0 and whole TOML acceptance remain outside scope.

///|
fn toml_indent_field(name : String, value : OrderingExpr) -> OrderingExpr {
  reflect_object([(reflect_string(name), 1, value)])
}

///|
fn toml_indent_call(
  value : OrderingExpr,
  indent : OrderingExpr,
  through_alias? : Bool = false,
  strict? : Bool = false,
) -> OrderingExpr {
  let function = additive_select(sequence_var("std"), "manifestTomlEx")
  let args : Array[(String?, OrderingExpr)] = [
    (None, value),
    (Some("indent"), indent),
  ]
  if through_alias {
    sequence_local(
      [("render", function)],
      shared_mode_call(sequence_var("render"), args, strict~),
    )
  } else {
    shared_mode_call(function, args, strict~)
  }
}

///|
test "TI1 flat and empty TOML output does not demand unused indentation" {
  let empty = reflect_object([])
  let cases : Array[(OrderingExpr, String)] = [
    (empty, ""),
    (toml_indent_field("a", sequence_num(1)), "a = 1"),
    (toml_indent_field("a", ordering_array([])), "a = []"),
    (toml_indent_field("a", empty), "\n\n[a]"),
    (
      toml_indent_field("a", ordering_array([empty, empty])),
      "\n\n[[a]]\n\n[[a]]",
    ),
    (
      reflect_object([
        (reflect_string("hidden"), 2, ordering_error("hidden-value-unused")),
      ]),
      "",
    ),
  ]
  for (value, expected) in cases {
    for through_alias in [false, true] {
      transfer_value(
        toml_indent_call(value, ordering_error("unused-indent"), through_alias~),
        Json::string(expected),
      )
    }
  }
}

///|
test "TI2 nonempty array lines and nested prefixes demand indentation" {
  for
    value in [
      toml_indent_field("a", ordering_array([sequence_num(1)])),
      toml_indent_field("a", toml_indent_field("b", sequence_num(1))),
      toml_indent_field("a", toml_indent_field("b", reflect_object([]))),
      toml_indent_field(
        "a",
        ordering_array([toml_indent_field("b", sequence_num(1))]),
      ),
    ] {
    for through_alias in [false, true] {
      let call = toml_indent_call(
        value,
        ordering_error("required-indent"),
        through_alias~,
      )
      // The sole user marker is an additional embedding diagnostic control;
      // no competing-error winner or upstream diagnostic spelling is required.
      sequence_failure(call, @moonjsonnet.Runtime, Some("required-indent"))
      sequence_failure(
        sequence_call("type", [call]),
        @moonjsonnet.Runtime,
        Some("required-indent"),
      )
    }
  }
}

///|
test "TI3 TOML whitespace indentation preserves nested and inline layouts" {
  let cases : Array[(OrderingExpr, String, String)] = [
    (
      reflect_object([
        (reflect_string("a"), 1, sequence_num(1)),
        (
          reflect_string("b"),
          1,
          ordering_array([reflect_bool(true), sequence_num(2)]),
        ),
      ]),
      "  ",
      "a = 1\nb = [\n  true,\n  2\n]",
    ),
    (
      toml_indent_field(
        "a",
        toml_indent_field(
          "b",
          ordering_array([sequence_num(1), sequence_num(2)]),
        ),
      ),
      "\t",
      "\n\n[a]\n\tb = [\n\t\t1,\n\t\t2\n\t]",
    ),
    (
      toml_indent_field(
        "a",
        ordering_array([
          sequence_num(1),
          toml_indent_field("b", sequence_num(2)),
          ordering_array([sequence_num(3), sequence_num(4)]),
        ]),
      ),
      "  ",
      "a = [\n  1,\n  { b = 2 },\n  [ 3, 4 ]\n]",
    ),
    (
      toml_indent_field(
        "a",
        ordering_array([
          toml_indent_field("b", sequence_num(1)),
          toml_indent_field("b", sequence_num(2)),
        ]),
      ),
      " ",
      "\n\n[[a]]\n b = 1\n\n[[a]]\n b = 2",
    ),
  ]
  for (value, indent, expected) in cases {
    transfer_value(
      toml_indent_call(value, reflect_string(indent)),
      Json::string(expected),
    )
    if indent == "  " {
      transfer_value(
        sequence_call("manifestToml", [value]),
        Json::string(expected),
      )
    }
  }
}

///|
test "TI4 strict TOML calls demand bound heads and unused whole calls stay lazy" {
  // tailstrict is an existing invocation-mode regression, not new normative
  // acceptance for the ordinary source-definition contract.
  let empty = reflect_object([])
  for through_alias in [false, true] {
    transfer_reject(
      toml_indent_call(
        empty,
        ordering_error("strict-indent"),
        through_alias~,
        strict=true,
      ),
    )
    transfer_reject(
      toml_indent_call(
        ordering_error("strict-value"),
        reflect_string("  "),
        through_alias~,
        strict=true,
      ),
    )
    transfer_value(
      toml_indent_call(empty, reflect_string("  "), through_alias~, strict=true),
      "",
    )
    transfer_value(
      ordering_unused(
        toml_indent_call(
          ordering_error("unused-value"),
          ordering_error("unused-indent"),
          through_alias~,
        ),
      ),
      42,
    )
  }
}

///|
test "TI5 TOML indentation deferral preserves required binding and String guards" {
  let function = additive_select(sequence_var("std"), "manifestTomlEx")
  transfer_value(sequence_call("length", [function]), 2)
  let empty = reflect_object([])
  let safe = reflect_string("  ")
  let invalid : Array[Array[(String?, OrderingExpr)]] = [
    [],
    [(None, empty)],
    [(Some("indent"), safe)],
    [(None, empty), (None, safe), (None, safe)],
    [(None, empty), (Some("unknown"), safe)],
    [(None, empty), (None, safe), (Some("indent"), safe)],
  ]
  for args in invalid {
    transfer_reject(shared_mode_call(function, args))
  }
  // Compatibility-only guard: demanded nonstrings still reject. The public
  // description's String domain versus source coercion is not resolved here.
  transfer_reject(
    toml_indent_call(
      toml_indent_field("a", ordering_array([sequence_num(1)])),
      make_function([], sequence_num(0)),
    ),
  )
}
