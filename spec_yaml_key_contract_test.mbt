// Fixed executable bareSafe criteria: SPEC-YAML-DEMAND-2026-10-25.md.
// Field text is literal; no second classifier or YAML parser supplies the oracle.

///|
fn yaml_key_doc(key : String, quote~ : Bool = false) -> OrderingExpr {
  yaml_demand_doc(
    reflect_object([(reflect_string(key), 1, sequence_num(0))]),
    reflect_bool(false),
    reflect_bool(quote),
  )
}

///|
fn yaml_key_cases(cases : Array[(String, String)]) -> Unit raise {
  for (key, expected) in cases {
    sequence_value(yaml_key_doc(key), Json::string(expected))
  }
}

///|
test "YK1 YAML bare keys use the exact ASCII gate and reserved word set" {
  yaml_key_cases([
    ("a/b", "a/b: 0"),
    (
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-/.", "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-/.: 0",
    ),
    ("a b", "\"a b\": 0"),
    ("a:b", "\"a:b\": 0"),
    ("a+b", "\"a+b\": 0"),
    ("a@b", "\"a@b\": 0"),
    ("é", "\"é\": 0"),
    ("", "\"\": 0"),
    ("true", "\"true\": 0"),
    ("false", "\"false\": 0"),
    ("yes", "\"yes\": 0"),
    ("no", "\"no\": 0"),
    ("on", "\"on\": 0"),
    ("off", "\"off\": 0"),
    ("y", "\"y\": 0"),
    ("n", "\"n\": 0"),
    (".nan", "\".nan\": 0"),
    ("-.inf", "\"-.inf\": 0"),
    ("+.inf", "\"+.inf\": 0"),
    (".inf", "\".inf\": 0"),
    ("null", "\"null\": 0"),
    ("-", "\"-\": 0"),
    ("---", "\"---\": 0"),
    ("TrUe", "\"TrUe\": 0"),
    ("NULL", "\"NULL\": 0"),
    (".NaN", "\".NaN\": 0"),
    ("nan", "nan: 0"),
    ("NAN", "NAN: 0"),
    ("inf", "inf: 0"),
    ("INF", "INF: 0"),
    ("infinity", "infinity: 0"),
    ("-inf", "-inf: 0"),
    ("-infinity", "-infinity: 0"),
    (".infinity", ".infinity: 0"),
  ])
}

///|
test "YK2 YAML date and integer key predicates count dashes without parsing" {
  yaml_key_cases([
    ("_", "\"_\": 0"),
    ("__", "\"__\": 0"),
    ("_1_", "\"_1_\": 0"),
    ("1__2", "\"1__2\": 0"),
    ("-_", "\"-_\": 0"),
    ("0", "\"0\": 0"),
    ("01", "\"01\": 0"),
    ("-123", "\"-123\": 0"),
    ("1-2", "\"1-2\": 0"),
    ("--", "\"--\": 0"),
    ("1--2", "\"1--2\": 0"),
    ("--1", "\"--1\": 0"),
    ("2026-10-27", "\"2026-10-27\": 0"),
    ("1---2", "1---2: 0"),
    ("----", "----: 0"),
    ("_--", "_--: 0"),
    ("--_", "--_: 0"),
    ("0_--", "0_--: 0"),
    ("1a2", "1a2: 0"),
  ])
}

///|
test "YK3 YAML binary key classification preserves prefix case and conservative digits" {
  yaml_key_cases([
    ("0b29", "\"0b29\": 0"),
    ("0b10", "\"0b10\": 0"),
    ("0b_", "\"0b_\": 0"),
    ("0bb", "\"0bb\": 0"),
    ("0bB", "\"0bB\": 0"),
    ("0b--", "\"0b--\": 0"),
    ("-0b--9", "\"-0b--9\": 0"),
    ("-0b", "\"-0b\": 0"),
    ("0b", "0b: 0"),
    ("0B10", "0B10: 0"),
    ("-0B10", "-0B10: 0"),
    ("x0b10", "x0b10: 0"),
    ("0ba", "0ba: 0"),
  ])
}

///|
test "YK4 YAML float key classification uses dot exponent and dash counts" {
  yaml_key_cases([
    ("1.0e309", "\"1.0e309\": 0"),
    ("1.0e-9999", "\"1.0e-9999\": 0"),
    ("1e3", "1e3: 0"),
    ("1e-9999", "1e-9999: 0"),
    ("1E3", "1E3: 0"),
    ("1.0E3", "\"1.0E3\": 0"),
    (".", "\".\": 0"),
    (".e", "\".e\": 0"),
    ("E.", "\"E.\": 0"),
    ("1._2", "\"1._2\": 0"),
    ("__.e_", "\"__.e_\": 0"),
    ("1.--2", "\"1.--2\": 0"),
    ("-.e-", "\"-.e-\": 0"),
    ("1.2.3", "1.2.3: 0"),
    ("1.2ee3", "1.2ee3: 0"),
    ("1.2eE3", "1.2eE3: 0"),
    ("1.2---3", "1.2---3: 0"),
    ("1.0ee309", "1.0ee309: 0"),
    ("1.0e+3", "\"1.0e+3\": 0"),
  ])
}

///|
test "YK5 YAML hexadecimal key classification uses anchored original case prefixes" {
  yaml_key_cases([
    ("x0xffz", "x0xffz: 0"),
    ("0x-", "\"0x-\": 0"),
    ("-0x", "\"-0x\": 0"),
    ("0x", "0x: 0"),
    ("0Xaf", "0Xaf: 0"),
    ("-0Xaf", "-0Xaf: 0"),
    ("0xaf", "\"0xaf\": 0"),
    ("0xAF", "\"0xAF\": 0"),
    ("-0xAF", "\"-0xAF\": 0"),
    ("0xx", "\"0xx\": 0"),
    ("-0x_", "\"-0x_\": 0"),
    ("0x--", "0x--: 0"),
    ("0xG", "0xG: 0"),
    ("0xfg", "0xfg: 0"),
    ("x0xff", "x0xff: 0"),
  ])
}

///|
test "YK6 YAML key classification composes with nesting forced quotes streams and budgets" {
  for
    (key, expected) in [
      ("nan", "\"nan\": 0"),
      ("1e3", "\"1e3\": 0"),
      ("0B10", "\"0B10\": 0"),
      ("0Xaf", "\"0Xaf\": 0"),
      ("a/b", "\"a/b\": 0"),
    ] {
    sequence_value(yaml_key_doc(key, quote=true), Json::string(expected))
  }
  let object = reflect_object([
    (reflect_string("x0xffz"), 1, sequence_num(3)),
    (
      reflect_string("outer"),
      1,
      ordering_array([
        reflect_object([(reflect_string("0b29"), 1, sequence_num(1))]),
        reflect_object([(reflect_string("1e3"), 1, sequence_num(2))]),
      ]),
    ),
  ])
  let expected = "outer:\n  - \"0b29\": 1\n  - 1e3: 2\nx0xffz: 3"
  sequence_value(
    yaml_demand_doc(object, reflect_bool(true), reflect_bool(false)),
    Json::string(expected),
  )
  for ending in [false, true] {
    sequence_value(
      yaml_demand_stream(
        ordering_array([object]),
        reflect_bool(true),
        reflect_bool(false),
        reflect_bool(ending),
      ),
      Json::string(
        "---\n" + expected + "\n" + (if ending { "...\n" } else { "" }),
      ),
    )
  }
  for
    (rendered, text) in [
      (yaml_key_doc("1.0e309"), "\"1.0e309\": 0"),
      (yaml_key_doc("1e3"), "1e3: 0"),
      (yaml_key_doc("0b29"), "\"0b29\": 0"),
      (yaml_key_doc("x0xffz"), "x0xffz: 0"),
    ] {
    let bytes = text.length()
    let call = sequence_call("length", [rendered])
    for handmade in [false, true] {
      let program = ordering_program(call, handmade)
      // All budget text is ASCII; observing length avoids outer JSON quoting.
      assert_eq(
        program.evaluate(limits={ ..sequence_limits(), output_bytes: bytes, }),
        Json::number(bytes.to_double()),
      )
      try
        program.evaluate(limits={
          ..sequence_limits(),
          output_bytes: bytes - 1,
        })
      catch {
        @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
      } noraise {
        _ => fail("YAML key output accepted a one-byte-short budget")
      }
    }
  }
}
