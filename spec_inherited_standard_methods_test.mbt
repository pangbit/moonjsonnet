// Fixed Jsonnet bbb38f1020be1f5aed560928fb839b2c448cefb4 std.jsonnet binds
// object-local std to self. Literal expectations below distinguish inherited
// dependency overrides from both std and std + {}. Trees are handmade.

///|
fn inherited_standard_override(
  name : String,
  params : Array[String],
  body : OrderingExpr,
) -> OrderingExpr {
  ordering_binary(
    sequence_var("std"),
    "+",
    reflect_object([(reflect_string(name), 2, make_function(params, body))]),
  )
}

///|
fn inherited_standard_call(
  library : OrderingExpr,
  name : String,
  args : Array[(String, OrderingExpr)],
) -> OrderingExpr {
  shared_mode_call(
    additive_select(library, name),
    args.map(arg => (Some(arg.0), arg.1)),
  )
}

///|
fn inherited_standard_check(
  library : OrderingExpr,
  name : String,
  args : Array[(String, OrderingExpr)],
  changed : Json,
  ordinary : Json,
) -> Unit raise {
  for
    control in [
      sequence_var("std"),
      ordering_binary(sequence_var("std"), "+", reflect_object([])),
    ] {
    sequence_value(inherited_standard_call(control, name, args), ordinary)
  }
  sequence_value(inherited_standard_call(library, name, args), changed)
}

///|
test "inherited string composition observes receiver dependencies and empty extensions" {
  let zero = inherited_standard_override("length", ["x"], sequence_num(0))
  inherited_standard_check(
    zero,
    "join",
    [
      ("sep", reflect_string("-")),
      ("arr", ordering_array([reflect_string("a"), reflect_string("b")])),
    ],
    "",
    "a-b",
  )
  let joined = inherited_standard_override(
    "join",
    ["sep", "arr"],
    reflect_string("joined"),
  )
  inherited_standard_check(
    joined,
    "strReplace",
    [
      ("str", reflect_string("a,b")),
      ("from", reflect_string(",")),
      ("to", reflect_string("/")),
    ],
    "joined",
    "a/b",
  )
  inherited_standard_check(
    joined,
    "lines",
    [("arr", ordering_array([reflect_string("a"), reflect_string("b")]))],
    "joined",
    "a\nb\n",
  )
  inherited_standard_check(
    inherited_standard_override("type", ["x"], reflect_string("string")),
    "toString",
    [("a", sequence_num(7))],
    7,
    "7",
  )
  // The unoverridden lines -> join dependency must retain this same receiver.
  sequence_value(
    inherited_standard_call(zero, "lines", [
      ("arr", ordering_array([reflect_string("a")])),
    ]),
    "",
  )
}

///|
test "inherited checks observe receiver predicates while operators keep private bindings" {
  let unequal = inherited_standard_override(
    "primitiveEquals",
    ["x", "y"],
    reflect_bool(false),
  )
  inherited_standard_check(
    unequal,
    "equals",
    [("a", sequence_num(1)), ("b", sequence_num(1))],
    false,
    true,
  )
  inherited_standard_check(
    inherited_standard_override("count", ["arr", "x"], sequence_num(0)),
    "member",
    [("arr", ordering_array([sequence_num(1)])), ("x", sequence_num(1))],
    false,
    true,
  )
  inherited_standard_check(
    inherited_standard_override("any", ["arr"], reflect_bool(false)),
    "contains",
    [("arr", ordering_array([sequence_num(1)])), ("elem", sequence_num(1))],
    false,
    true,
  )
  let absolute = [("n", sequence_num(-3))]
  for
    control in [
      sequence_var("std"),
      ordering_binary(sequence_var("std"), "+", reflect_object([])),
    ] {
    sequence_value(inherited_standard_call(control, "abs", absolute), 3)
  }
  sequence_failure(
    inherited_standard_call(
      inherited_standard_override(
        "isNumber",
        ["v"],
        ordering_error("inherited abs predicate"),
      ),
      "abs",
      absolute,
    ),
    @moonjsonnet.Runtime,
    Some("inherited abs predicate"),
  )
  // Changing public std does not rebind the equality operators or xor/xnor.
  sequence_value(
    sequence_local(
      [("library", unequal)],
      sequence_local(
        [("std", sequence_var("library"))],
        ordering_array([
          sequence_call("equals", [sequence_num(1), sequence_num(1)]),
          ordering_binary(sequence_num(1), "==", sequence_num(1)),
          sequence_call("xor", [reflect_bool(true), reflect_bool(true)]),
          sequence_call("xnor", [reflect_bool(true), reflect_bool(true)]),
        ]),
      ),
    ),
    [false, true, false, true],
  )
  // A false type comparison leaves both equality operands unneeded.
  sequence_value(
    inherited_sequence_call(unequal, "equals", [
      ordering_error("unused equality left"),
      ordering_error("unused equality right"),
    ]),
    false,
  )
}

///|
test "inherited decimal parser captures the receiver through its object local helper" {
  let library = inherited_standard_override(
    "foldl",
    ["func", "arr", "init"],
    sequence_num(42),
  )
  inherited_standard_check(
    library,
    "parseInt",
    [("str", reflect_string("12"))],
    42,
    12,
  )
  let cases : Array[(OrderingExpr, Json)] = [
    (library, 42),
    (sequence_var("std"), 12),
  ]
  for (receiver, expected) in cases {
    sequence_value(
      sequence_local(
        [("saved", additive_select(receiver, "parseInt"))],
        sequence_local(
          [
            (
              "holder",
              reflect_object([
                (reflect_string("parseInt"), 2, sequence_var("saved")),
                (
                  reflect_string("foldl"),
                  2,
                  make_function(["func", "arr", "init"], sequence_num(99)),
                ),
              ]),
            ),
            ("std", ordering_error("unused caller std")),
          ],
          inherited_standard_call(sequence_var("holder"), "parseInt", [
            ("str", reflect_string("12")),
          ]),
        ),
      ),
      expected,
    )
  }
  let wrapper = reflect_object([
    (
      reflect_string("parseInt"),
      2,
      make_function(
        ["str"],
        inherited_sequence_call(
          ordering_leaf("super", Var("super")),
          "parseInt",
          [sequence_var("str")],
        ),
      ),
    ),
  ])
  sequence_value(
    inherited_standard_call(
      ordering_binary(library, "+", wrapper),
      "parseInt",
      [("str", reflect_string("12"))],
    ),
    42,
  )
}

///|
test "inherited JSON and YAML renderers use receiver escaping with lazy source options" {
  let library = inherited_standard_override(
    "escapeStringJson",
    ["str"],
    reflect_string("escaped"),
  )
  inherited_standard_check(
    library,
    "manifestJsonEx",
    [("value", reflect_string("a")), ("indent", reflect_string(""))],
    "escaped",
    "\"a\"",
  )
  inherited_standard_check(
    library,
    "manifestYamlDoc",
    [("value", reflect_string("a"))],
    "escaped",
    "\"a\"",
  )
  // The source wrapper must reach the inherited JSON accelerator as a method.
  sequence_value(
    inherited_sequence_call(library, "manifestJson", [reflect_string("a")]),
    "escaped",
  )
  sequence_value(
    inherited_standard_call(library, "manifestJsonEx", [
      ("value", reflect_string("a")),
      ("indent", ordering_error("unused JSON indent")),
      ("newline", ordering_error("unused JSON newline")),
      ("key_val_sep", ordering_error("unused JSON separator")),
    ]),
    "escaped",
  )
  sequence_value(
    inherited_standard_call(library, "manifestYamlDoc", [
      ("value", reflect_string("a")),
      ("indent_array_in_object", ordering_error("unused YAML indent")),
      ("quote_keys", ordering_error("unused YAML key option")),
    ]),
    "escaped",
  )
  for
    (name, args) in [
      (
        "manifestJsonEx",
        [("value", reflect_string("a")), ("indent", reflect_string(""))],
      ),
      ("manifestYamlDoc", [("value", reflect_string("a"))]),
    ] {
    sequence_failure(
      inherited_standard_call(
        inherited_standard_override(
          "escapeStringJson",
          ["str"],
          ordering_error("required inherited escape"),
        ),
        name,
        args,
      ),
      @moonjsonnet.Runtime,
      Some("required inherited escape"),
    )
  }
}
