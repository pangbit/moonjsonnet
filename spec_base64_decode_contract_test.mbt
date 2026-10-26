// Independent canonical Base64 decoder contract at google/jsonnet
// bbb38f1020be1f5aed560928fb839b2c448cefb4. DecodeBytes returns octets;
// deprecated Decode maps those octets through char, not decodeUTF8.
// Malformed encodings and disputed non-String admission are ungraded separately.

///|
fn base64_decode_call(
  name : String,
  input : OrderingExpr,
  named? : Bool = false,
) -> OrderingExpr {
  rounding_apply(name, [(if named { Some("str") } else { None }, input)])
}

///|
fn base64_decode_byte_json(bytes : Array[Int]) -> Json {
  Json::array(bytes.map(n => Json::number(n.to_double())))
}

///|
fn base64_decode_reject(value : OrderingExpr) -> Unit raise {
  for handmade in [false, true] {
    assert_eq(
      ordering_program(ordering_unused(value), handmade).evaluate(
        limits=sequence_limits(),
      ),
      42,
    )
    try
      ordering_program(value, handmade).evaluate(limits=sequence_limits())
    catch {
      @moonjsonnet.Error(d) =>
        assert_true(
          d.kind == @moonjsonnet.Runtime || d.kind == @moonjsonnet.Type,
        )
    } noraise {
      result => fail("required decoder error became " + result.stringify())
    }
  }
}

///|
fn base64_decode_single_strings(handmade : Bool) -> Unit raise {
  let calls : Array[OrderingExpr] = []
  let expected : Array[Json] = []
  for (text, encoded) in base64_contract_single_vectors() {
    calls.push(base64_decode_call("base64Decode", reflect_string(encoded)))
    expected.push(Json::string(text))
  }
  assert_eq(
    ordering_program(ordering_array(calls), handmade).evaluate(
      limits=sequence_limits(),
    ),
    Json::array(expected),
  )
}

///|
test "B64D-C01 required str bindings aliases empty results and result heads" {
  for name in ["base64DecodeBytes", "base64Decode"] {
    let function = additive_select(sequence_var("std"), name)
    sequence_value(sequence_call("length", [function]), 1)
    let expected = if name == "base64DecodeBytes" {
      Json::array([])
    } else {
      Json::string("")
    }
    for named in [false, true] {
      let call = base64_decode_call(name, reflect_string(""), named~)
      sequence_value(call, expected)
      sequence_value(sequence_call("length", [call]), 0)
      sequence_value(
        sequence_call("type", [call]),
        Json::string(
          if name == "base64DecodeBytes" {
            "array"
          } else {
            "string"
          },
        ),
      )
    }
    sequence_value(
      sequence_local(
        [("f", function)],
        shared_mode_call(sequence_var("f"), [(Some("str"), reflect_string(""))]),
      ),
      expected,
    )
  }
  for
    (encoded, text) in [
      ("Zg==", "f"),
      ("Zm8=", "fo"),
      ("Zm9v", "foo"),
      ("Zm9vYg==", "foob"),
      ("Zm9vYmE=", "fooba"),
      ("Zm9vYmFy", "foobar"),
      ("AA==", "\u0000"),
      ("fw==", "\u007f"),
    ] {
    sequence_value(
      base64_decode_call("base64Decode", reflect_string(encoded), named=true),
      Json::string(text),
    )
  }
}

///|
test "B64D-C02 binding errors reject before supplied argument demand" {
  let bad = ordering_error("binding-must-skip")
  for name in ["base64DecodeBytes", "base64Decode"] {
    for
      args in [
        [],
        [(Some("input"), bad)],
        [(Some("arr"), bad)],
        [(None, bad), (None, bad)],
        [(None, bad), (Some("str"), bad)],
      ] {
      deletion_binding_reject(rounding_apply(name, args))
    }
  }
}

///|
test "B64D-C03 source naive decoding preserves byte codepoints instead of UTF8 text" {
  assert_eq(
    @moonjsonnet.evaluate(
      "[std.base64Decode('6Q=='),std.base64Decode('/w==')," +
      "std.base64Decode('w6k='),std.base64Decode('AAH/')]",
    ),
    ["\u00e9", "\u00ff", "\u00c3\u00a9", "\u0000\u0001\u00ff"],
  )
}

///|
test "B64D-C04 handmade AST named decoding preserves byte codepoints" {
  let calls = ["6Q==", "/w==", "w6k=", "AAH/"].map(encoded => {
    base64_decode_call("base64Decode", reflect_string(encoded), named=true)
  })
  assert_eq(
    ordering_program(ordering_array(calls), true).evaluate(
      limits=sequence_limits(),
    ),
    ["\u00e9", "\u00ff", "\u00c3\u00a9", "\u0000\u0001\u00ff"],
  )
}

///|
test "B64D-C05 byte decoder preserves all octets mixed groups and the full alphabet" {
  let calls : Array[OrderingExpr] = []
  let expected : Array[Json] = []
  for n, (_, encoded) in base64_contract_single_vectors() {
    calls.push(base64_decode_call("base64DecodeBytes", reflect_string(encoded)))
    expected.push(base64_decode_byte_json([n]))
  }
  sequence_value(ordering_array(calls), Json::array(expected))
  for (_, bytes, encoded) in base64_contract_group_vectors() {
    sequence_value(
      base64_decode_call(
        "base64DecodeBytes",
        reflect_string(encoded),
        named=true,
      ),
      base64_decode_byte_json(bytes),
    )
  }
  let bytes : Array[Int] = []
  for n in 0..<256 {
    bytes.push(n)
  }
  sequence_value(
    base64_decode_call(
      "base64DecodeBytes",
      reflect_string(base64_contract_full_vector()),
    ),
    base64_decode_byte_json(bytes),
  )
  sequence_value(
    base64_decode_call("base64DecodeBytes", reflect_string("+///")),
    [251, 255, 255],
  )
}

///|
test "B64D-C06 source single byte Strings preserve every codepoint zero through 255" {
  base64_decode_single_strings(false)
}

///|
test "B64D-C07 handmade single byte Strings preserve every codepoint zero through 255" {
  base64_decode_single_strings(true)
}

///|
test "B64D-C08 mixed lengths preserve naive codepoints and zero bytes" {
  for (text, _, encoded) in base64_contract_group_vectors() {
    let call = base64_decode_call("base64Decode", reflect_string(encoded))
    sequence_value(call, Json::string(text))
    sequence_value(
      sequence_call("length", [call]),
      Json::number(text.iter().count().to_double()),
    )
  }
}

///|
test "B64D-C09 full byte alphabet decoding yields the exact naive String" {
  let text = base64_contract_single_vectors().map(pair => pair.0).join("")
  let call = base64_decode_call(
    "base64Decode",
    reflect_string(base64_contract_full_vector()),
  )
  sequence_value(call, Json::string(text))
  sequence_value(sequence_call("length", [call]), 256)
}

///|
test "B64D-C10 explicit UTF8 decoding retains valid text as a separate operation" {
  let cases : Array[(String, Array[Int], String)] = [
    ("", [], ""),
    ("AA==", [0], "\u0000"),
    ("Zm9v", [102, 111, 111], "foo"),
    ("w6k=", [195, 169], "é"),
    ("5Lit", [228, 184, 173], "中"),
    ("8J+YgA==", [240, 159, 152, 128], "😀"),
  ]
  for (encoded, bytes, text) in cases {
    let decoded = base64_decode_call(
      "base64DecodeBytes",
      reflect_string(encoded),
    )
    sequence_value(decoded, base64_decode_byte_json(bytes))
    sequence_value(sequence_call("decodeUTF8", [decoded]), Json::string(text))
    sequence_value(
      sequence_call("decodeUTF8", [base64_contract_bytes(bytes)]),
      Json::string(text),
    )
    sequence_value(
      sequence_call("encodeUTF8", [reflect_string(text)]),
      base64_decode_byte_json(bytes),
    )
  }
}

///|
test "B64D-C11 required input errors and unambiguous invalid heads cannot become results" {
  let nil = ordering_leaf("null", Literal(Json::null()))
  for name in ["base64DecodeBytes", "base64Decode"] {
    let call = base64_decode_call(name, ordering_error("decode-required"))
    for
      value in [
        call,
        sequence_call("type", [call]),
        sequence_call("length", [call]),
      ] {
      sequence_failure(value, @moonjsonnet.Runtime, Some("decode-required"))
    }
    for input in [nil, reflect_bool(false), sequence_num(1)] {
      base64_decode_reject(base64_decode_call(name, input))
    }
  }
}

///|
test "B64D-C12 unselected decoder calls remain lazy and repeated byte aliases stay intact" {
  for name in ["base64DecodeBytes", "base64Decode"] {
    let call = "std." + name + "(error 'decode-unused')"
    assert_eq(
      @moonjsonnet.evaluate(
        "local unused=" +
        call +
        ";[if false then " +
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
  assert_eq(
    @moonjsonnet.evaluate(
      "local text='AAH/';local a=std.base64DecodeBytes(text);" +
      "[a,std.map(function(x)x,a),text,a]",
    ),
    [[0, 1, 255], [0, 1, 255], "AAH/", [0, 1, 255]],
  )
}
