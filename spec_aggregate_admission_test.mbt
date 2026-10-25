// Frozen sum/avg and necessary foldl contract: SPEC-AGGREGATE-ADMISSION-2026-10-25.md.
// Independent literal expectations; source and handmade AST entries.

///|
fn aggregate_admit_call(
  name : String,
  input : OrderingExpr,
  named? : Bool = false,
) -> OrderingExpr {
  rounding_apply(name, [(if named { Some("arr") } else { None }, input)])
}

///|
fn aggregate_empty_shapes() -> Array[OrderingExpr] {
  [
    reflect_object([]),
    reflect_object([
      (reflect_string("hidden"), 2, ordering_error("hidden-unused")),
    ]),
    make_function([], ordering_error("zero-body-uncalled")),
  ]
}

///|
fn aggregate_nonempty_shapes() -> Array[OrderingExpr] {
  [
    reflect_object([(reflect_string("x"), 1, ordering_error("field-unused"))]),
    make_function(["x"], ordering_error("one-body-uncalled")),
    sort_contract_optional(
      ordering_error("default-unused"),
      ordering_error("body-uncalled"),
    ),
  ]
}

///|
test "aggregate source signatures retain one required arr and lazy binding rejection" {
  let input = ordering_array([sequence_num(2), sequence_num(4)])
  for (name, expected) in [("sum", Json::number(6)), ("avg", Json::number(3))] {
    let function = additive_select(sequence_var("std"), name)
    sequence_value(sequence_call("length", [function]), 1)
    sequence_value(aggregate_admit_call(name, input), expected)
    sequence_value(aggregate_admit_call(name, input, named=true), expected)
    let aliased_call : OrderingExpr = {
      source: "f(arr=(" + input.source + "))",
      tree: ordering_ast(
        Call(sequence_var("f").tree, [(Some("arr"), input.tree)], false),
      ),
    }
    sequence_value(sequence_local([("f", function)], aliased_call), expected)
    let bad = ordering_error("binding-must-skip")
    for
      args in [
        [],
        [(None, bad), (None, bad)],
        [(Some("xs"), bad)],
        [(None, bad), (Some("arr"), bad)],
      ] {
      deletion_binding_reject(rounding_apply(name, args))
    }
  }
}

///|
test "sum traverses admitted Strings as Unicode characters with numeric zero seed" {
  for
    (text, expected) in [
      ("", Json::number(0)),
      ("123", Json::string("0123")),
      ("1e309", Json::string("01e309")),
      ("😀e\u0301\u0000", Json::string("0😀e\u0301\u0000")),
    ] {
    for named in [false, true] {
      sequence_value(
        aggregate_admit_call("sum", reflect_string(text), named~),
        expected,
      )
    }
  }
  let char_sum = make_function(
    ["acc", "char"],
    ordering_binary(
      sequence_var("acc"),
      "+",
      sequence_call("codepoint", [sequence_var("char")]),
    ),
  )
  sequence_value(
    sequence_call("foldl", [
      char_sum,
      reflect_string("😀e\u0301"),
      sequence_num(0),
    ]),
    129382,
  )
}

///|
test "avg checks empty String before reduction and rejects the completed String quotient" {
  for named in [false, true] {
    sequence_failure(
      aggregate_admit_call("avg", reflect_string(""), named~),
      @moonjsonnet.Runtime,
      Some("Cannot calculate average of an empty array."),
    )
    for text in ["1", "123", "😀e\u0301", "\u0000"] {
      sequence_failure(
        sequence_call("type", [
          aggregate_admit_call("avg", reflect_string(text), named~),
        ]),
        @moonjsonnet.Type,
        None,
      )
    }
  }
}

///|
test "aggregate zero length Objects and Functions do not require indexing payloads or bodies" {
  for input in aggregate_empty_shapes() {
    for named in [false, true] {
      sequence_value(aggregate_admit_call("sum", input, named~), 0)
      sequence_failure(
        aggregate_admit_call("avg", input, named~),
        @moonjsonnet.Runtime,
        Some("Cannot calculate average of an empty array."),
      )
    }
  }
}

///|
test "aggregate nonempty Object and Function length admits shape then required numeric indexing fails" {
  for input in aggregate_nonempty_shapes() {
    for name in ["sum", "avg"] {
      for named in [false, true] {
        sequence_failure(
          sequence_call("type", [aggregate_admit_call(name, input, named~)]),
          @moonjsonnet.Type,
          None,
        )
      }
    }
  }
}

///|
test "aggregate scalar rejection required input errors and whole call laziness remain separate" {
  for name in ["sum", "avg"] {
    for
      input in [
        ordering_leaf("null", Literal(Json::null())),
        reflect_bool(true),
        sequence_num(7),
      ] {
      sequence_failure(
        aggregate_admit_call(name, input),
        @moonjsonnet.Type,
        None,
      )
    }
    sequence_failure(
      sequence_call("type", [
        aggregate_admit_call(name, ordering_error("input-required")),
      ]),
      @moonjsonnet.Runtime,
      Some("input-required"),
    )
    let needed = aggregate_admit_call(name, ordering_error("call-must-skip"))
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
  }
}

///|
test "required source foldl handles empty length and avoids indexing ignored Object or Function elements" {
  let unused_func = ordering_error("unused-function")
  for input in aggregate_empty_shapes() {
    sequence_value(
      sequence_call("foldl", [unused_func, input, sequence_num(42)]),
      42,
    )
    sequence_failure(
      sequence_call("foldl", [
        unused_func,
        input,
        ordering_error("initial-required"),
      ]),
      @moonjsonnet.Runtime,
      Some("initial-required"),
    )
  }
  let count = make_function(
    ["acc", "unused"],
    ordering_binary(sequence_var("acc"), "+", sequence_num(1)),
  )
  for i, input in aggregate_nonempty_shapes() {
    sequence_value(
      sequence_call("foldl", [count, input, sequence_num(0)]),
      Json::number(if i == 2 { 2.0 } else { 1.0 }),
    )
  }
}
