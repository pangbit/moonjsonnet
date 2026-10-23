// Fixed-rule oracle: SPEC-OPERATOR-TOKENS-2026-10-23.md.
// Raw lexing is observed without requiring a valid expression grammar.

///|
fn op_character_text(value : Char) -> String {
  let out = StringBuilder()
  out.write_char(value)
  out.to_string()
}

///|
fn op_token_vector(
  source : String,
  expected : Array[String],
  block_value? : String? = None,
) -> Unit raise {
  for retain in [false, true] {
    let tokens = lex(source, "operator-token", retain_trivia=retain)
    assert_eq(tokens.filter(t => t.text != "<eof>").map(t => t.raw), expected)
    if block_value is Some(value) {
      assert_eq(tokens.filter(t => t.text == "<block>").map(t => t.value), [
        Some(Json::string(value)),
      ])
    }
  }
}

///|
fn op_lexical_error(source : String) -> Unit raise {
  for retain in [false, true] {
    try lex(source, "operator-token", retain_trivia=retain) catch {
      Error(d) => assert_eq(d.kind, Syntax)
      e => raise e
    } noraise {
      _ => fail("recognized malformed lexical construct was accepted")
    }
  }
}

///|
test "operator alphabet pairs and long runs obey greedy suffix constraints" {
  let alphabet = "!$:~+-&|^=<>*/%"
  let legal_ends = ":&|^=<>*/%"
  let single_only_ends = "+-~!$"
  for first in alphabet {
    let left = op_character_text(first)
    op_token_vector(left, [left])
    for last in legal_ends {
      let right = op_character_text(last)
      let pair = left + right
      // These two open comments, so their cases belong to the next group.
      if pair != "//" && pair != "/*" {
        op_token_vector(pair, [pair])
      }
    }
    for last in single_only_ends {
      let right = op_character_text(last)
      op_token_vector(left + right, [left, right])
    }
  }
  // Long expectations are literal rule derivations, not scanner snapshots.
  let runs : Array[(String, Array[String])] = [
    ("!==", ["!=="]),
    ("===", ["==="]),
    ("<<=", ["<<="]),
    (">>>", [">>>"]),
    ("++=", ["++="]),
    ("$::", ["$::"]),
    ("!$=", ["!$="]),
    ("~~=", ["~~="]),
    ("=+!$:", ["=+!$:"]),
    ("+--", ["+", "-", "-"]),
    ("=+!$", ["=", "+", "!", "$"]),
    ("~~~~", ["~", "~", "~", "~"]),
    ("!!!!", ["!", "!", "!", "!"]),
    ("$$$$", ["$", "$", "$", "$"]),
    ("+-+", ["+", "-", "+"]),
    ("**/", ["**/"]),
    ("a+=1.0e+2;", ["a", "+=", "1.0e+2", ";"]),
    ("{}[],.();", ["{", "}", "[", "]", ",", ".", "(", ")", ";"]),
    ("+a", ["+", "a"]),
  ]
  for (source, expected) in runs {
    op_token_vector(source, expected)
  }
}

///|
test "operator sentinels protect comments blocks and lexical failure boundaries" {
  let cases : Array[(String, Array[String])] = [
    ("//only", []),
    ("/*only*/", []),
    ("+//ignored\n=", ["+", "="]),
    ("=/*ignored*/=", ["=", "="]),
    ("=+/*ignored*/!", ["=", "+", "!"]),
    ("/*ignored*/+", ["+"]),
    ("=/*inner /*x*/+", ["=", "+"]),
    ("/ /", ["/", "/"]),
    ("/ *", ["/", "*"]),
    ("|| |", ["||", "|"]),
    ("| | |", ["|", "|", "|"]),
  ]
  for (source, expected) in cases {
    op_token_vector(source, expected)
  }
  let block = "|||\n  x\n|||"
  for (prefix, heads) in [("+", ["+"]), ("=+", ["=", "+"]), ("**", ["**"])] {
    op_token_vector(prefix + block, heads + [block], block_value=Some("x\n"))
  }
  for
    source in [
      "+/*unterminated", "+|||\n  x\n bad\n", "+|||\n  x\n", "+|||\n  x\n||", "+?",
      "+∧", "+\\=",
    ] {
    op_lexical_error(source)
  }
}
