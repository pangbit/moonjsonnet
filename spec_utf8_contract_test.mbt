// Criteria: docs/development/SPEC-STRING-CONTRACTS-EVIDENCE-2026-10-22.md.
// Valid UTF-8 contract at google/jsonnet bbb38f1020be1f5aed560928fb839b2c448cefb4.
// Literal scalar/byte pairs are independent oracles in both directions.
// Malformed byte recovery, invalid scalar Strings and diagnostic order are excluded.

///|
fn utf8_contract_bytes(bytes : Array[Int]) -> OrderingExpr {
  ordering_array(bytes.map(n => sequence_num(n)))
}

///|
fn utf8_contract_byte_json(bytes : Array[Int]) -> Json {
  Json::array(bytes.map(n => Json::number(n.to_double())))
}

///|
fn utf8_contract_pair(text : String, bytes : Array[Int]) -> Unit raise {
  sequence_value(
    sequence_call("encodeUTF8", [reflect_string(text)]),
    utf8_contract_byte_json(bytes),
  )
  sequence_value(
    sequence_call("decodeUTF8", [utf8_contract_bytes(bytes)]),
    Json::string(text),
  )
}

///|
test "UTF8-C01 one byte scalar endpoints have independent bidirectional values" {
  utf8_contract_pair("\u0000", [0])
  utf8_contract_pair("\u007f", [127])
}

///|
test "UTF8-C02 two byte scalar endpoints have independent bidirectional values" {
  utf8_contract_pair("\u0080", [194, 128])
  utf8_contract_pair("\u07ff", [223, 191])
}

///|
test "UTF8-C03 three byte endpoints and scalar gap edges preserve valid text" {
  utf8_contract_pair("\u0800", [224, 160, 128])
  utf8_contract_pair("\ud7ff", [237, 159, 191])
  utf8_contract_pair("\ue000", [238, 128, 128])
  utf8_contract_pair("\uffff", [239, 191, 191])
}

///|
test "UTF8-C04 four byte scalar endpoints have independent bidirectional values" {
  utf8_contract_pair("\u{10000}", [240, 144, 128, 128])
  utf8_contract_pair("\u{10ffff}", [244, 143, 191, 191])
}

///|
test "UTF8-C05 mixed widths retain exact boundaries and complete consumption" {
  let text = "\u0000\u007f\u0080\u07ff\u0800\ud7ff\ue000\uffff\u{10000}\u{10ffff}"
  let bytes = [
    0, 127, 194, 128, 223, 191, 224, 160, 128, 237, 159, 191, 238, 128, 128, 239,
    191, 191, 240, 144, 128, 128, 244, 143, 191, 191,
  ]
  utf8_contract_pair(text, bytes)
  sequence_value(
    sequence_call("length", [
      sequence_call("encodeUTF8", [reflect_string(text)]),
    ]),
    26,
  )
  sequence_value(
    sequence_call("length", [
      sequence_call("decodeUTF8", [utf8_contract_bytes(bytes)]),
    ]),
    10,
  )
}

///|
test "UTF8-C06 documented parameter names also work through function aliases" {
  let cases : Array[(String, String, OrderingExpr, Json)] = [
    ("encodeUTF8", "str", reflect_string("\u0080"), [194, 128]),
    ("decodeUTF8", "arr", utf8_contract_bytes([194, 128]), "\u0080"),
  ]
  for (name, parameter, input, expected) in cases {
    sequence_value(rounding_apply(name, [(Some(parameter), input)]), expected)
    sequence_value(
      sequence_local(
        [("convert", additive_select(sequence_var("std"), name))],
        shared_mode_call(sequence_var("convert"), [(Some(parameter), input)]),
      ),
      expected,
    )
  }
}

///|
test "UTF8-C07 fully demanded conversions propagate their only input error" {
  for name in ["encodeUTF8", "decodeUTF8"] {
    sequence_failure(
      sequence_call(name, [ordering_error("utf8-required-input")]),
      @moonjsonnet.Runtime,
      Some("utf8-required-input"),
    )
  }
}

///|
test "UTF8-C08 fully demanded decoding cannot swallow a required byte error" {
  // Each input has one error, with ASCII elsewhere. No competing error order
  // or malformed byte recovery policy participates in these expectations.
  let bad = ordering_error("utf8-required-byte")
  for
    input in [
      ordering_array([bad, sequence_num(65), sequence_num(66)]),
      ordering_array([sequence_num(65), bad, sequence_num(66)]),
      ordering_array([sequence_num(65), sequence_num(66), bad]),
    ] {
    sequence_failure(
      sequence_call("decodeUTF8", [input]),
      @moonjsonnet.Runtime,
      Some("utf8-required-byte"),
    )
  }
}

///|
test "UTF8-C09 unselected conversion expressions remain lazy in both entries" {
  let bad = ordering_error("utf8-unused")
  let calls = [
    sequence_call("encodeUTF8", [bad]),
    sequence_call("decodeUTF8", [bad]),
    sequence_call("decodeUTF8", [ordering_array([sequence_num(65), bad])]),
  ]
  for call in calls {
    sequence_value(ordering_unused(call), 42)
    let branch : OrderingExpr = {
      source: "if false then (" + call.source + ") else 42",
      tree: ordering_ast(
        If(reflect_bool(false).tree, call.tree, sequence_num(42).tree),
      ),
    }
    sequence_value(branch, 42)
    sequence_value(ordering_binary(reflect_bool(false), "&&", call), false)
    sequence_value(ordering_binary(reflect_bool(true), "||", call), true)
    sequence_value(
      additive_select(
        reflect_object([
          (reflect_string("hidden"), 2, call),
          (reflect_string("value"), 1, sequence_num(42)),
        ]),
        "value",
      ),
      42,
    )
    sequence_value(
      shared_mode_call(make_function(["unused"], sequence_num(42)), [
        (None, call),
      ]),
      42,
    )
    sequence_value(make_index(ordering_array([call, sequence_num(42)]), 1), 42)
  }
}

///|
test "UTF8-C10 conversion preserves byte aliases and repeated String values" {
  let bytes = utf8_contract_bytes([244, 143, 191, 191, 0, 194, 128])
  let array = sequence_var("bytes")
  let decoded = sequence_var("text")
  sequence_value(
    sequence_local(
      [("bytes", bytes), ("text", sequence_call("decodeUTF8", [array]))],
      ordering_array([
        array,
        decoded,
        array,
        sequence_call("map", [make_function(["x"], sequence_var("x")), array]),
        sequence_call("encodeUTF8", [decoded]),
        decoded,
      ]),
    ),
    [
      [244, 143, 191, 191, 0, 194, 128],
      "\u{10ffff}\u0000\u0080",
      [244, 143, 191, 191, 0, 194, 128],
      [244, 143, 191, 191, 0, 194, 128],
      [244, 143, 191, 191, 0, 194, 128],
      "\u{10ffff}\u0000\u0080",
    ],
  )
}

///|
test "UTF8-C11 interior FEFF and NUL remain data with exact scalar and byte lengths" {
  let text = "A\ufeff\u0000B"
  let bytes = [65, 239, 187, 191, 0, 66]
  utf8_contract_pair(text, bytes)
  sequence_value(
    sequence_call("length", [
      sequence_call("encodeUTF8", [reflect_string(text)]),
    ]),
    6,
  )
  sequence_value(
    sequence_call("length", [
      sequence_call("decodeUTF8", [utf8_contract_bytes(bytes)]),
    ]),
    4,
  )
}
