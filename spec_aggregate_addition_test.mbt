// Frozen Array-input criteria: SPEC-AGGREGATE-ADDITION-2026-10-25.md.
// Literal values and independent handmade ASTs; no interpreter-result oracle.

///|
fn aggregate_apply(name : String, items : Array[OrderingExpr]) -> OrderingExpr {
  sequence_call(name, [ordering_array(items)])
}

///|
test "sum uses actual left associative addition for mixed String Array elements" {
  for
    (items, expected) in [
      ([sequence_num(1), reflect_string("2"), sequence_num(3)], "123"),
      ([reflect_string("a"), reflect_string("b")], "0ab"),
      ([sequence_num(1), reflect_string("😀"), sequence_num(2)], "1😀2"),
      (
        [
          reflect_string(""),
          reflect_bool(true),
          ordering_leaf("null", Literal(Json::null())),
        ],
        "0truenull",
      ),
    ] {
    sequence_value(aggregate_apply("sum", items), Json::string(expected))
    sequence_value(
      sequence_call("type", [aggregate_apply("sum", items)]),
      "string",
    )
  }
}

///|
test "aggregate finite checks apply to numeric additions before a String transition" {
  let big = deletion_number("1e308", 1.0e308)
  let negative = deletion_number("-1e308", -1.0e308)
  for name in ["sum", "avg"] {
    for prefix in [[big, big], [negative, negative]] {
      sequence_failure(
        sequence_call("type", [
          aggregate_apply(name, prefix + [reflect_string("unreached")]),
        ]),
        @moonjsonnet.Runtime,
        None,
      )
    }
  }
  // These are String concatenations, not overflowing Number additions.
  sequence_value(
    sequence_call("type", [
      aggregate_apply("sum", [reflect_string(""), big, big]),
    ]),
    "string",
  )
  sequence_failure(
    aggregate_apply("avg", [reflect_string(""), big, big]),
    @moonjsonnet.Type,
    None,
  )
}

///|
test "avg completes the additive reduction before attempting its numeric quotient" {
  for name in ["sum", "avg"] {
    for
      prefix in [
        [sequence_num(1), reflect_string("2")],
        [reflect_string(""), sequence_num(3)],
      ] {
      sequence_failure(
        sequence_call("type", [
          aggregate_apply(
            name,
            prefix + [ordering_error("required-after-string")],
          ),
        ]),
        @moonjsonnet.Runtime,
        Some("required-after-string"),
      )
    }
  }
  sequence_failure(
    aggregate_apply("avg", [sequence_num(1), reflect_string("2")]),
    @moonjsonnet.Type,
    None,
  )
}

///|
test "aggregate Array arithmetic admits finite extrema and rounded subnormal underflow" {
  let tiny = deletion_number("5e-324", 5.0e-324)
  let large = deletion_number("1.7976931348623157e308", 1.7976931348623157e308)
  sequence_value(aggregate_apply("sum", [tiny, tiny]), Json::number(1.0e-323))
  sequence_value(aggregate_apply("avg", [tiny, sequence_num(0)]), 0)
  for name in ["sum", "avg"] {
    sequence_value(
      aggregate_apply(name, [large]),
      Json::number(1.7976931348623157e308),
    )
    sequence_value(aggregate_apply(name, [tiny]), Json::number(5.0e-324))
  }
}

///|
test "aggregate String paths remain lazy when unused hidden or explicitly short circuited" {
  let needed = aggregate_apply("avg", [
    sequence_num(1),
    reflect_string("x"),
    ordering_error("hidden-required"),
  ])
  let predicate = ordering_binary(
    sequence_call("type", [needed]),
    "==",
    reflect_string("number"),
  )
  let object = reflect_object([
    (reflect_string("bad"), 2, needed),
    (reflect_string("good"), 1, sequence_num(42)),
  ])
  sequence_value(
    ordering_array([
      ordering_unused(needed),
      ordering_binary(reflect_bool(false), "&&", predicate),
      ordering_binary(reflect_bool(true), "||", predicate),
      additive_select(object, "good"),
    ]),
    [42, false, true, 42],
  )
  sequence_failure(needed, @moonjsonnet.Runtime, Some("hidden-required"))
}

///|
test "aggregate String coercion demands output payloads only after the String transition" {
  let bad = ordering_error("required-coercion-payload")
  for
    value in [
      ordering_array([bad]),
      reflect_object([(reflect_string("x"), 1, bad)]),
    ] {
    sequence_failure(aggregate_apply("sum", [value]), @moonjsonnet.Type, None)
    for name in ["sum", "avg"] {
      sequence_failure(
        sequence_call("type", [
          aggregate_apply(name, [reflect_string(""), value]),
        ]),
        @moonjsonnet.Runtime,
        Some("required-coercion-payload"),
      )
    }
  }
  sequence_value(
    sequence_call("type", [
      aggregate_apply("sum", [
        reflect_string(""),
        ordering_array([sequence_num(7)]),
      ]),
    ]),
    "string",
  )
  sequence_failure(
    aggregate_apply("sum", [
      reflect_string(""),
      make_function([], ordering_error("uncalled-body")),
    ]),
    @moonjsonnet.Type,
    None,
  )
}
