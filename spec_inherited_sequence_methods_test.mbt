// Fixed Jsonnet bbb38f1020be1f5aed560928fb839b2c448cefb4 std.jsonnet defines
// object-local std=self. Inherited foldr and flatMap must use the final receiver.
// Source and handmade ASTs share only neutral builders, not parser output.

///|
fn inherited_sequence_library(count : Int) -> OrderingExpr {
  ordering_binary(
    sequence_var("std"),
    "+",
    reflect_object([
      (reflect_string("length"), 2, make_function(["x"], sequence_num(count))),
    ]),
  )
}

///|
fn inherited_sequence_call(
  library : OrderingExpr,
  name : String,
  args : Array[OrderingExpr],
) -> OrderingExpr {
  value_head_call(additive_select(library, name), args)
}

///|
fn inherited_sequence_results(library : OrderingExpr) -> OrderingExpr {
  let input = ordering_array([sequence_num(1), sequence_num(2)])
  ordering_array([
    inherited_sequence_call(library, "foldr", [
      make_function(
        ["x", "acc"],
        ordering_binary(sequence_var("x"), "+", sequence_var("acc")),
      ),
      input,
      sequence_num(42),
    ]),
    inherited_sequence_call(library, "flatMap", [
      make_function(["x"], ordering_array([sequence_var("x")])),
      input,
    ]),
  ])
}

///|
test "inherited sequence methods use the final receiver length" {
  let cases : Array[(Int, Json)] = [(0, [42, []]), (1, [43, [1]])]
  for (count, expected) in cases {
    sequence_value(
      inherited_sequence_results(inherited_sequence_library(count)),
      expected,
    )
  }
  // Extending an already derived receiver must replace its earlier length.
  sequence_value(
    inherited_sequence_results(
      ordering_binary(
        inherited_sequence_library(0),
        "+",
        reflect_object([
          (reflect_string("length"), 2, make_function(["x"], sequence_num(1))),
        ]),
      ),
    ),
    [43, [1]],
  )
}

///|
test "inherited sequence closures keep extracted and super receivers when forwarded" {
  let cases : Array[(OrderingExpr, Json)] = [
    (inherited_sequence_library(1), [43, [1]]),
    (sequence_var("std"), [45, [1, 2]]),
  ]
  for (library, expected) in cases {
    let holder = reflect_object([
      (reflect_string("foldr"), 2, sequence_var("saved_fold")),
      (reflect_string("flatMap"), 2, sequence_var("saved_map")),
      (reflect_string("length"), 2, make_function(["x"], sequence_num(0))),
    ])
    let expression = sequence_local(
      [("library", library)],
      sequence_local(
        [
          ("saved_fold", additive_select(sequence_var("library"), "foldr")),
          ("saved_map", additive_select(sequence_var("library"), "flatMap")),
          ("holder", holder),
        ],
        sequence_local(
          [("std", ordering_error("caller std must stay unused"))],
          inherited_sequence_results(sequence_var("holder")),
        ),
      ),
    )
    sequence_value(expression, expected)
  }
  let parent = ordering_leaf("super", Var("super"))
  let wrappers = reflect_object([
    (
      reflect_string("foldr"),
      2,
      make_function(
        ["func", "arr", "init"],
        inherited_sequence_call(parent, "foldr", [
          sequence_var("func"),
          sequence_var("arr"),
          sequence_var("init"),
        ]),
      ),
    ),
    (
      reflect_string("flatMap"),
      2,
      make_function(
        ["func", "arr"],
        inherited_sequence_call(parent, "flatMap", [
          sequence_var("func"),
          sequence_var("arr"),
        ]),
      ),
    ),
  ])
  sequence_value(
    inherited_sequence_results(
      ordering_binary(inherited_sequence_library(1), "+", wrappers),
    ),
    [43, [1]],
  )
}

///|
test "inherited foldr and flatMap preserve their different source demand boundaries" {
  let zero = inherited_sequence_library(0)
  sequence_value(
    inherited_sequence_call(zero, "foldr", [
      ordering_error("unused fold callback"),
      ordering_error("unused fold input"),
      sequence_num(42),
    ]),
    42,
  )
  sequence_value(
    inherited_sequence_call(inherited_sequence_library(1), "foldr", [
      make_function(["x", "acc"], sequence_var("x")),
      ordering_array([sequence_num(7), ordering_error("unused fold tail")]),
      ordering_error("unused fold initial"),
    ]),
    7,
  )
  let callback = make_function(["x"], ordering_error("unused flatMap body"))
  sequence_value(
    inherited_sequence_call(zero, "flatMap", [
      callback,
      ordering_array([ordering_error("unused flatMap element")]),
    ]),
    [],
  )
  let failures : Array[(OrderingExpr, String)] = [
    (
      inherited_sequence_call(zero, "foldr", [
        ordering_error("unused fold callback"),
        ordering_error("unused fold input"),
        ordering_error("required fold initial"),
      ]),
      "required fold initial",
    ),
    (
      inherited_sequence_call(zero, "flatMap", [
        ordering_error("required flatMap callback"),
        ordering_array([]),
      ]),
      "required flatMap callback",
    ),
    (
      inherited_sequence_call(zero, "flatMap", [
        callback,
        ordering_error("required flatMap input"),
      ]),
      "required flatMap input",
    ),
  ]
  for (expression, marker) in failures {
    sequence_failure(expression, @moonjsonnet.Runtime, Some(marker))
  }
}

///|
test "native only library fields do not fall back to user fields below std" {
  let lower = reflect_object([
    (reflect_string("length"), 2, make_function(["x"], sequence_num(-100))),
    (reflect_string("type"), 2, make_function(["x"], reflect_string("poison"))),
  ])
  let library = ordering_binary(lower, "+", sequence_var("std"))
  sequence_value(
    ordering_array([
      inherited_sequence_call(library, "length", [
        ordering_array([sequence_num(1), sequence_num(2)]),
      ]),
      inherited_sequence_call(library, "type", [ordering_array([])]),
    ]),
    [2, "array"],
  )
}
