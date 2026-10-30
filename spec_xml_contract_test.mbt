// Fixed Jsonnet bbb38f1020be1f5aed560928fb839b2c448cefb4:
// std.jsonnet 1036-1046 and 1335-1351; stdlib.html #std-escapeStringXml and
// #std-manifestXmlJsonml. Both bodies are enabled without native overrides.
// Literal String escaping and finite JsonML layouts/demand through source and
// handmade caller ASTs. XML/Xml and str/str_ spelling remain unresolved; only
// the existing uppercase source member is exercised, with positional inputs.
// General coercion/numeric spelling, invalid XML names/control characters,
// raw-special-character JsonML policy, assertions/inheritance, cycles and
// resource thresholds are outside this finite source profile.

///|
fn xml_contract_call(
  name : String,
  args : Array[(String?, OrderingExpr)],
  through_alias~ : Bool = false,
) -> OrderingExpr {
  let function = additive_select(sequence_var("std"), name)
  if through_alias {
    sequence_local(
      [("saved_xml", function)],
      shared_mode_call(sequence_var("saved_xml"), args),
    )
  } else {
    shared_mode_call(function, args)
  }
}

///|
test "XML1 XML escaping replaces the five characters once per input character" {
  let cases : Array[(String, String)] = [
    ("", ""),
    ("<", "&lt;"),
    (">", "&gt;"),
    ("&", "&amp;"),
    ("\"", "&quot;"),
    ("'", "&apos;"),
    ("<&>\"'<&", "&lt;&amp;&gt;&quot;&apos;&lt;&amp;"),
    ("&amp; &#60; &lt;", "&amp;amp; &amp;#60; &amp;lt;"),
    ("é中😀e\u{0301}/= \\%$\n\r\t", "é中😀e\u{0301}/= \\%$\n\r\t"),
  ]
  // Replacement text is not reprocessed within this call; pre-existing
  // entities still contain an input ampersand and are escaped again.
  for (input, expected) in cases {
    transfer_value(
      sequence_call("escapeStringXML", [reflect_string(input)]),
      Json::string(expected),
    )
  }
}

///|
test "XML2 JsonML retains nested elements sorted attributes and explicit whitespace" {
  let p = reflect_string("p")
  for value in [ordering_array([p]), ordering_array([p, reflect_object([])])] {
    transfer_value(sequence_call("manifestXmlJsonml", [value]), "<p></p>")
  }
  let document = ordering_array([
    reflect_string("svg"),
    reflect_object([
      (reflect_string("width"), 1, sequence_num(100)),
      (reflect_string("height"), 1, sequence_num(50)),
    ]),
    reflect_string("\n  before "),
    ordering_array([
      p,
      reflect_object([
        (reflect_string("title"), 1, reflect_string("é😀")),
        (reflect_string("id"), 1, reflect_string("item")),
      ]),
      reflect_string("one"),
      ordering_array([reflect_string("br")]),
      reflect_string(" two"),
    ]),
    reflect_string(" after\n"),
  ])
  transfer_value(
    sequence_call("manifestXmlJsonml", [document]),
    "<svg height=\"50\" width=\"100\">\n  before <p id=\"item\" title=\"é😀\">one<br></br> two</p> after\n</svg>",
  )
  transfer_value(
    sequence_call("manifestXmlJsonml", [
      ordering_array([
        p,
        reflect_string(""),
        reflect_string("a"),
        reflect_string("b"),
      ]),
    ]),
    "<p>ab</p>",
  )
}

///|
test "XML3 explicit escaping composes with JsonML and hidden attributes stay unread" {
  let unread = ordering_error("xml-hidden-attribute")
  let hidden_only = reflect_object([(reflect_string("hidden"), 2, unread)])
  transfer_value(
    sequence_call("manifestXmlJsonml", [
      ordering_array([reflect_string("p"), hidden_only]),
    ]),
    "<p></p>",
  )
  let escaped = sequence_call("escapeStringXML", [reflect_string("<&>\"'")])
  let document = ordering_array([
    reflect_string("p"),
    reflect_object([
      (reflect_string("hidden"), 2, unread),
      (reflect_string("title"), 3, escaped),
    ]),
    escaped,
    ordering_array([reflect_string("span"), hidden_only, reflect_string(" end")]),
  ])
  // Expected XML is an independent literal, not a round-trip oracle or a
  // conclusion about raw special characters supplied directly to JsonML.
  transfer_value(
    sequence_call("manifestXmlJsonml", [document]),
    "<p title=\"&lt;&amp;&gt;&quot;&apos;\">&lt;&amp;&gt;&quot;&apos;<span> end</span></p>",
  )
}

///|
test "XML4 required XML inputs and JsonML payloads propagate sole errors" {
  let required = ordering_error("xml-required-payload")
  let p = reflect_string("p")
  let cases = [
    ("escapeStringXML", [required]),
    (
      "manifestXmlJsonml",
      [
        required,
        ordering_array([required]),
        ordering_array([p, required]),
        ordering_array([p, reflect_object([]), required]),
        ordering_array([p, ordering_array([reflect_string("span"), required])]),
        ordering_array([
          p,
          reflect_object([(reflect_string("title"), 1, required)]),
        ]),
      ],
    ),
  ]
  for (name, inputs) in cases {
    for input in inputs {
      for through_alias in [false, true] {
        let call = xml_contract_call(name, [(None, input)], through_alias~)
        // Sole-marker/kind checks are extra embedding controls. There is no
        // assertion about competing-error winners or internal forcing counts.
        transfer_error(call, "xml-required-payload")
        transfer_reject(sequence_call("type", [call]))
        transfer_value(
          shared_mode_call(make_function(["unused"], sequence_num(42)), [
            (None, call),
          ]),
          42,
        )
      }
    }
  }
}

///|
test "XML5 JsonML rejects nonarray roots and selected incomplete structures" {
  let p = reflect_string("p")
  for
    input in [
      ordering_leaf("null", Literal(Json::null())),
      reflect_bool(true),
      sequence_num(1),
      reflect_string("text"),
      reflect_object([]),
      make_function([], sequence_num(1)),
      ordering_array([]),
      ordering_array([sequence_num(1)]),
      ordering_array([p, sequence_num(1)]),
      ordering_array([p, reflect_object([]), ordering_array([])]),
    ] {
    // Root admission is explicit in the fixed body; the remaining finite
    // shapes fail when tag/child operations are required. No tag, message,
    // exhaustive JsonML schema or nonstring escape policy is inferred.
    transfer_reject(sequence_call("manifestXmlJsonml", [input]))
  }
}

///|
test "XML6 XML calls retain required arity aliases and unambiguous bindings" {
  let cases : Array[(String, OrderingExpr, String)] = [
    ("escapeStringXML", reflect_string("<&"), "&lt;&amp;"),
    (
      "manifestXmlJsonml",
      ordering_array([reflect_string("p"), reflect_string("text")]),
      "<p>text</p>",
    ),
  ]
  for (name, safe, expected) in cases {
    transfer_value(
      sequence_call("length", [additive_select(sequence_var("std"), name)]),
      1,
    )
    for through_alias in [false, true] {
      let labels = if name == "manifestXmlJsonml" {
        [None, Some("value")]
      } else {
        [None]
      }
      for label in labels {
        transfer_value(
          xml_contract_call(name, [(label, safe)], through_alias~),
          Json::string(expected),
        )
      }
      let invalid : Array[Array[(String?, OrderingExpr)]] = [
        [],
        [(None, safe), (None, safe)],
        [(Some("unknown"), safe)],
      ]
      if name == "manifestXmlJsonml" {
        invalid.push([(None, safe), (Some("value"), safe)])
      }
      for args in invalid {
        transfer_reject(xml_contract_call(name, args, through_alias~))
      }
    }
  }
}
