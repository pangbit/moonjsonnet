// Independent base64 byte contract at google/jsonnet bbb38f1020be1f5aed560928fb839b2c448cefb4.
// Fixed public range/alphabet/padding and std.jsonnet codepoint conversion.
// Pending baseline: do not replace these expectations with interpreter output.
// Negative and fractional array elements are separate ungraded observations.

///|
fn base64_contract_call(
  input : OrderingExpr,
  named~ : Bool = false,
) -> OrderingExpr {
  rounding_apply("base64", [(if named { Some("input") } else { None }, input)])
}

///|
fn base64_contract_bytes(values : Array[Int32]) -> OrderingExpr {
  ordering_array(values.map(sequence_num))
}

///|
fn base64_contract_reject(input : OrderingExpr) -> Unit raise {
  for handmade in [false, true] {
    let call = base64_contract_call(input)
    assert_eq(
      ordering_program(ordering_unused(call), handmade).evaluate(
        limits=sequence_limits(),
      ),
      42,
    )
    try
      ordering_program(call, handmade).evaluate(limits=sequence_limits())
    catch {
      @moonjsonnet.Error(d) =>
        assert_true(
          d.kind == @moonjsonnet.Runtime ||
          d.kind == @moonjsonnet.Type ||
          d.kind == @moonjsonnet.Assertion,
        )
    } noraise {
      value => fail("required base64 failure became " + value.stringify())
    }
  }
}

///|
test "B64-C01 one required input binds positionally by name and through aliases" {
  let function = additive_select(sequence_var("std"), "base64")
  sequence_value(sequence_call("length", [function]), 1)
  for named in [false, true] {
    sequence_value(base64_contract_call(reflect_string("foo"), named~), "Zm9v")
    sequence_value(
      base64_contract_call(base64_contract_bytes([102, 111, 111]), named~),
      "Zm9v",
    )
  }
  sequence_value(
    sequence_local(
      [("f", function)],
      shared_mode_call(sequence_var("f"), [
        (Some("input"), reflect_string("foo")),
      ]),
    ),
    "Zm9v",
  )
  sequence_value(
    base64_contract_call(
      ordering_array([
        deletion_number("1.0", 1.0),
        deletion_number("-0.0", -0.0),
      ]),
    ),
    "AQA=",
  )
}

///|
test "B64-C02 missing extra duplicate and unknown bindings reject before argument demand" {
  let bad = ordering_error("binding-must-skip")
  for
    args in [
      [],
      [(Some("str"), bad)],
      [(Some("arr"), bad)],
      [(None, bad), (None, bad)],
      [(None, bad), (Some("input"), bad)],
    ] {
    deletion_binding_reject(rounding_apply("base64", args))
  }
}

///|
test "B64-C03 empty String and Array return an empty String" {
  for input in [reflect_string(""), ordering_array([])] {
    let call = base64_contract_call(input)
    sequence_value(call, "")
    sequence_value(sequence_call("type", [call]), "string")
    sequence_value(sequence_call("length", [call]), 0)
  }
}

///|
test "B64-C04 literal ASCII vectors cover all padding residues and alphabet edges" {
  for
    (input, expected) in [
      ("f", "Zg=="),
      ("fo", "Zm8="),
      ("foo", "Zm9v"),
      ("foob", "Zm9vYg=="),
      ("fooba", "Zm9vYmE="),
      ("foobar", "Zm9vYmFy"),
      ("\u0000", "AA=="),
      ("\u007f", "fw=="),
    ] {
    sequence_value(
      base64_contract_call(reflect_string(input)),
      Json::string(expected),
    )
  }
  sequence_value(
    base64_contract_call(base64_contract_bytes([251, 255, 255])),
    "+///",
  )
}

///|
test "B64-C05 source Latin1 String codepoints encode as the corresponding single bytes" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.base64('é'),std.base64([233]),std.base64('ÿ'),std.base64([255])]",
    ),
    ["6Q==", "6Q==", "/w==", "/w=="],
  )
}

///|
test "B64-C06 handmade AST and named Latin1 input retain the same byte contract" {
  let value = ordering_array([
    base64_contract_call(reflect_string("é"), named=true),
    base64_contract_call(base64_contract_bytes([233]), named=true),
    base64_contract_call(reflect_string("ÿ")),
    base64_contract_call(base64_contract_bytes([255])),
  ])
  assert_eq(ordering_program(value, true).evaluate(limits=sequence_limits()), [
    "6Q==", "6Q==", "/w==", "/w==",
  ])
}

///|
test "B64-C07 every single byte from zero through 255 has an independent literal encoding" {
  let calls : Array[OrderingExpr] = []
  let expected : Array[Json] = []
  for n, (text, encoded) in base64_contract_single_vectors() {
    calls.push(
      ordering_array([
        base64_contract_call(reflect_string(text)),
        base64_contract_call(base64_contract_bytes([n])),
      ]),
    )
    expected.push([Json::string(encoded), Json::string(encoded)])
  }
  sequence_value(ordering_array(calls), Json::array(expected))
}

///|
test "B64-C08 mixed high byte sequences preserve grouping length and zero bytes" {
  for (text, bytes, encoded) in base64_contract_group_vectors() {
    let expected = Json::string(encoded)
    sequence_value(base64_contract_call(reflect_string(text)), expected)
    sequence_value(
      base64_contract_call(base64_contract_bytes(bytes), named=true),
      expected,
    )
  }
}

///|
test "B64-C09 other input types and nonnumeric array elements report evaluation errors" {
  let nil = ordering_leaf("null", Literal(Json::null()))
  let function = make_function([], ordering_error("uncalled-body"))
  let object = reflect_object([
    (reflect_string("hidden"), 2, ordering_error("unread-field")),
  ])
  for input in [nil, reflect_bool(true), sequence_num(0), function, object] {
    base64_contract_reject(input)
  }
  for
    element in [
      nil,
      reflect_bool(false),
      reflect_string("1"),
      ordering_array([]),
      object,
      function,
    ] {
    base64_contract_reject(ordering_array([element]))
  }
}

///|
test "B64-C10 codepoints and integers above 255 are outside the admitted byte range" {
  for text in ["\u0100", "中", "😀", "a\u0100"] {
    base64_contract_reject(reflect_string(text))
  }
  for bytes in [[256], [0, 256], [65535], [1114111]] {
    base64_contract_reject(base64_contract_bytes(bytes))
  }
}

///|
test "B64-C11 required input and element errors propagate before result head observations" {
  for
    input in [
      ordering_error("base64-demanded"),
      ordering_array([ordering_error("base64-demanded")]),
      ordering_array([
        sequence_num(0),
        sequence_num(255),
        ordering_error("base64-demanded"),
      ]),
    ] {
    let call = base64_contract_call(input)
    for
      observation in [
        call,
        sequence_call("type", [call]),
        sequence_call("length", [call]),
      ] {
      sequence_failure(
        observation,
        @moonjsonnet.Runtime,
        Some("base64-demanded"),
      )
    }
  }
}

///|
test "B64-C12 unselected calls hidden fields and unused parameters remain lazy" {
  for
    input in [
      "error 'unused-base64'", "[error 'unused-base64']", "[256]", "'中'",
    ] {
    let call = "std.base64(" + input + ")"
    assert_eq(
      @moonjsonnet.evaluate(
        "local unused=" +
        call +
        "; [if false then " +
        call +
        " else 42,true || " +
        call +
        ",false && " +
        call +
        ",({hidden::" +
        call +
        ",value:42}).value," +
        "(function(unused)42)(" +
        call +
        "),[" +
        call +
        ",42][1]]",
      ),
      [42, true, false, 42, 42, 42],
    )
  }
}

///|
test "B64-C13 encoding leaves the source array aliases and mapped values immutable" {
  let original = base64_contract_bytes([0, 233, 255])
  let a = sequence_var("a")
  sequence_value(
    sequence_local(
      [("a", original)],
      ordering_array([
        base64_contract_call(a),
        a,
        base64_contract_call(a, named=true),
        a,
      ]),
    ),
    ["AOn/", [0, 233, 255], "AOn/", [0, 233, 255]],
  )
  assert_eq(
    @moonjsonnet.evaluate(
      "local a=[0,233,255]; local b=std.map(function(x)x,a); [std.base64(b),a,b]",
    ),
    ["AOn/", [0, 233, 255], [0, 233, 255]],
  )
}

///|
test "B64-C14 explicit UTF8 encoding remains distinct from byte String interpretation" {
  sequence_value(
    base64_contract_call(sequence_call("encodeUTF8", [reflect_string("é")])),
    "w6k=",
  )
  sequence_value(sequence_call("encodeUTF8", [reflect_string("é")]), [195, 169])
  sequence_value(
    sequence_call("decodeUTF8", [base64_contract_bytes([195, 169])]),
    "é",
  )
}

///|
test "B64-C15 the full byte alphabet retains one unwrapped padded result" {
  let vectors = base64_contract_single_vectors()
  let text = vectors.map(pair => pair.0).join("")
  let bytes : Array[Int32] = []
  for n in 0..<256 {
    bytes.push(n)
  }
  let expected = Json::string(base64_contract_full_vector())
  sequence_value(base64_contract_call(reflect_string(text)), expected)
  sequence_value(base64_contract_call(base64_contract_bytes(bytes)), expected)
}

// Literal data below is generated before execution from octet arithmetic;
// neither a Jsonnet interpreter nor a product encoder supplies the oracle.

///|
fn base64_contract_single_vectors() -> Array[(String, String)] {
  [
    ("\u0000", "AA=="),
    ("\u0001", "AQ=="),
    ("\u0002", "Ag=="),
    ("\u0003", "Aw=="),
    ("\u0004", "BA=="),
    ("\u0005", "BQ=="),
    ("\u0006", "Bg=="),
    ("\u0007", "Bw=="),
    ("\b", "CA=="),
    ("\t", "CQ=="),
    ("\n", "Cg=="),
    ("\u000b", "Cw=="),
    ("\u000c", "DA=="),
    ("\r", "DQ=="),
    ("\u000e", "Dg=="),
    ("\u000f", "Dw=="),
    ("\u0010", "EA=="),
    ("\u0011", "EQ=="),
    ("\u0012", "Eg=="),
    ("\u0013", "Ew=="),
    ("\u0014", "FA=="),
    ("\u0015", "FQ=="),
    ("\u0016", "Fg=="),
    ("\u0017", "Fw=="),
    ("\u0018", "GA=="),
    ("\u0019", "GQ=="),
    ("\u001a", "Gg=="),
    ("\u001b", "Gw=="),
    ("\u001c", "HA=="),
    ("\u001d", "HQ=="),
    ("\u001e", "Hg=="),
    ("\u001f", "Hw=="),
    (" ", "IA=="),
    ("!", "IQ=="),
    ("\"", "Ig=="),
    ("#", "Iw=="),
    ("$", "JA=="),
    ("%", "JQ=="),
    ("&", "Jg=="),
    ("'", "Jw=="),
    ("(", "KA=="),
    (")", "KQ=="),
    ("*", "Kg=="),
    ("+", "Kw=="),
    (",", "LA=="),
    ("-", "LQ=="),
    (".", "Lg=="),
    ("/", "Lw=="),
    ("0", "MA=="),
    ("1", "MQ=="),
    ("2", "Mg=="),
    ("3", "Mw=="),
    ("4", "NA=="),
    ("5", "NQ=="),
    ("6", "Ng=="),
    ("7", "Nw=="),
    ("8", "OA=="),
    ("9", "OQ=="),
    (":", "Og=="),
    (";", "Ow=="),
    ("<", "PA=="),
    ("=", "PQ=="),
    (">", "Pg=="),
    ("?", "Pw=="),
    ("@", "QA=="),
    ("A", "QQ=="),
    ("B", "Qg=="),
    ("C", "Qw=="),
    ("D", "RA=="),
    ("E", "RQ=="),
    ("F", "Rg=="),
    ("G", "Rw=="),
    ("H", "SA=="),
    ("I", "SQ=="),
    ("J", "Sg=="),
    ("K", "Sw=="),
    ("L", "TA=="),
    ("M", "TQ=="),
    ("N", "Tg=="),
    ("O", "Tw=="),
    ("P", "UA=="),
    ("Q", "UQ=="),
    ("R", "Ug=="),
    ("S", "Uw=="),
    ("T", "VA=="),
    ("U", "VQ=="),
    ("V", "Vg=="),
    ("W", "Vw=="),
    ("X", "WA=="),
    ("Y", "WQ=="),
    ("Z", "Wg=="),
    ("[", "Ww=="),
    ("\\", "XA=="),
    ("]", "XQ=="),
    ("^", "Xg=="),
    ("_", "Xw=="),
    ("`", "YA=="),
    ("a", "YQ=="),
    ("b", "Yg=="),
    ("c", "Yw=="),
    ("d", "ZA=="),
    ("e", "ZQ=="),
    ("f", "Zg=="),
    ("g", "Zw=="),
    ("h", "aA=="),
    ("i", "aQ=="),
    ("j", "ag=="),
    ("k", "aw=="),
    ("l", "bA=="),
    ("m", "bQ=="),
    ("n", "bg=="),
    ("o", "bw=="),
    ("p", "cA=="),
    ("q", "cQ=="),
    ("r", "cg=="),
    ("s", "cw=="),
    ("t", "dA=="),
    ("u", "dQ=="),
    ("v", "dg=="),
    ("w", "dw=="),
    ("x", "eA=="),
    ("y", "eQ=="),
    ("z", "eg=="),
    ("{", "ew=="),
    ("|", "fA=="),
    ("}", "fQ=="),
    ("~", "fg=="),
    ("\u007f", "fw=="),
    ("\u0080", "gA=="),
    ("\u0081", "gQ=="),
    ("\u0082", "gg=="),
    ("\u0083", "gw=="),
    ("\u0084", "hA=="),
    ("\u0085", "hQ=="),
    ("\u0086", "hg=="),
    ("\u0087", "hw=="),
    ("\u0088", "iA=="),
    ("\u0089", "iQ=="),
    ("\u008a", "ig=="),
    ("\u008b", "iw=="),
    ("\u008c", "jA=="),
    ("\u008d", "jQ=="),
    ("\u008e", "jg=="),
    ("\u008f", "jw=="),
    ("\u0090", "kA=="),
    ("\u0091", "kQ=="),
    ("\u0092", "kg=="),
    ("\u0093", "kw=="),
    ("\u0094", "lA=="),
    ("\u0095", "lQ=="),
    ("\u0096", "lg=="),
    ("\u0097", "lw=="),
    ("\u0098", "mA=="),
    ("\u0099", "mQ=="),
    ("\u009a", "mg=="),
    ("\u009b", "mw=="),
    ("\u009c", "nA=="),
    ("\u009d", "nQ=="),
    ("\u009e", "ng=="),
    ("\u009f", "nw=="),
    ("\u00a0", "oA=="),
    ("\u00a1", "oQ=="),
    ("\u00a2", "og=="),
    ("\u00a3", "ow=="),
    ("\u00a4", "pA=="),
    ("\u00a5", "pQ=="),
    ("\u00a6", "pg=="),
    ("\u00a7", "pw=="),
    ("\u00a8", "qA=="),
    ("\u00a9", "qQ=="),
    ("\u00aa", "qg=="),
    ("\u00ab", "qw=="),
    ("\u00ac", "rA=="),
    ("\u00ad", "rQ=="),
    ("\u00ae", "rg=="),
    ("\u00af", "rw=="),
    ("\u00b0", "sA=="),
    ("\u00b1", "sQ=="),
    ("\u00b2", "sg=="),
    ("\u00b3", "sw=="),
    ("\u00b4", "tA=="),
    ("\u00b5", "tQ=="),
    ("\u00b6", "tg=="),
    ("\u00b7", "tw=="),
    ("\u00b8", "uA=="),
    ("\u00b9", "uQ=="),
    ("\u00ba", "ug=="),
    ("\u00bb", "uw=="),
    ("\u00bc", "vA=="),
    ("\u00bd", "vQ=="),
    ("\u00be", "vg=="),
    ("\u00bf", "vw=="),
    ("\u00c0", "wA=="),
    ("\u00c1", "wQ=="),
    ("\u00c2", "wg=="),
    ("\u00c3", "ww=="),
    ("\u00c4", "xA=="),
    ("\u00c5", "xQ=="),
    ("\u00c6", "xg=="),
    ("\u00c7", "xw=="),
    ("\u00c8", "yA=="),
    ("\u00c9", "yQ=="),
    ("\u00ca", "yg=="),
    ("\u00cb", "yw=="),
    ("\u00cc", "zA=="),
    ("\u00cd", "zQ=="),
    ("\u00ce", "zg=="),
    ("\u00cf", "zw=="),
    ("\u00d0", "0A=="),
    ("\u00d1", "0Q=="),
    ("\u00d2", "0g=="),
    ("\u00d3", "0w=="),
    ("\u00d4", "1A=="),
    ("\u00d5", "1Q=="),
    ("\u00d6", "1g=="),
    ("\u00d7", "1w=="),
    ("\u00d8", "2A=="),
    ("\u00d9", "2Q=="),
    ("\u00da", "2g=="),
    ("\u00db", "2w=="),
    ("\u00dc", "3A=="),
    ("\u00dd", "3Q=="),
    ("\u00de", "3g=="),
    ("\u00df", "3w=="),
    ("\u00e0", "4A=="),
    ("\u00e1", "4Q=="),
    ("\u00e2", "4g=="),
    ("\u00e3", "4w=="),
    ("\u00e4", "5A=="),
    ("\u00e5", "5Q=="),
    ("\u00e6", "5g=="),
    ("\u00e7", "5w=="),
    ("\u00e8", "6A=="),
    ("\u00e9", "6Q=="),
    ("\u00ea", "6g=="),
    ("\u00eb", "6w=="),
    ("\u00ec", "7A=="),
    ("\u00ed", "7Q=="),
    ("\u00ee", "7g=="),
    ("\u00ef", "7w=="),
    ("\u00f0", "8A=="),
    ("\u00f1", "8Q=="),
    ("\u00f2", "8g=="),
    ("\u00f3", "8w=="),
    ("\u00f4", "9A=="),
    ("\u00f5", "9Q=="),
    ("\u00f6", "9g=="),
    ("\u00f7", "9w=="),
    ("\u00f8", "+A=="),
    ("\u00f9", "+Q=="),
    ("\u00fa", "+g=="),
    ("\u00fb", "+w=="),
    ("\u00fc", "/A=="),
    ("\u00fd", "/Q=="),
    ("\u00fe", "/g=="),
    ("\u00ff", "/w=="),
  ]
}

///|
fn base64_contract_group_vectors() -> Array[(String, Array[Int32], String)] {
  [
    ("\u0000", [0], "AA=="),
    ("\u0000\u007f", [0, 127], "AH8="),
    ("\u0000\u007f\u0080", [0, 127, 128], "AH+A"),
    ("\u0000\u007f\u0080\u00e9", [0, 127, 128, 233], "AH+A6Q=="),
    ("\u0000\u007f\u0080\u00e9\u00ff", [0, 127, 128, 233, 255], "AH+A6f8="),
    (
      "\u0000\u007f\u0080\u00e9\u00ff\u0001",
      [0, 127, 128, 233, 255, 1],
      "AH+A6f8B",
    ),
    (
      "\u0000\u007f\u0080\u00e9\u00ff\u0001\u00fe",
      [0, 127, 128, 233, 255, 1, 254],
      "AH+A6f8B/g==",
    ),
    (
      "\u0000\u007f\u0080\u00e9\u00ff\u0001\u00fe ",
      [0, 127, 128, 233, 255, 1, 254, 32],
      "AH+A6f8B/iA=",
    ),
    (
      "\u0000\u007f\u0080\u00e9\u00ff\u0001\u00fe A",
      [0, 127, 128, 233, 255, 1, 254, 32, 65],
      "AH+A6f8B/iBB",
    ),
    (
      "\u0000\u007f\u0080\u00e9\u00ff\u0001\u00fe A\u0000",
      [0, 127, 128, 233, 255, 1, 254, 32, 65, 0],
      "AH+A6f8B/iBBAA==",
    ),
  ]
}

///|
fn base64_contract_full_vector() -> String {
  "AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0BBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYGFiY2RlZmdoaWprbG1ub3BxcnN0dXZ3eHl6e3x9fn+AgYKDhIWGh4iJiouMjY6PkJGSk5SVlpeYmZqbnJ2en6ChoqOkpaanqKmqq6ytrq+wsbKztLW2t7i5uru8vb6/wMHCw8TFxsfIycrLzM3Oz9DR0tPU1dbX2Nna29zd3t/g4eLj5OXm5+jp6uvs7e7v8PHy8/T19vf4+fr7/P3+/w=="
}
