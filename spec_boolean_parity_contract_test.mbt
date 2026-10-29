// Pinned Jsonnet bbb38f1020be1f5aed560928fb839b2c448cefb4.
// Boolean xor/xnor and small integral parity share a documented/source domain.
// Fractional or large parity and nonboolean xor/xnor admission are excluded.
// Literal oracles; ordinary source and independently constructed caller ASTs.

///|
test "BP1 xor and xnor retain the complete Boolean truth tables" {
  for
    (x, y, xor_value, xnor_value) in [
      (false, false, false, true),
      (false, true, true, false),
      (true, false, true, false),
      (true, true, false, true),
    ] {
    for (name, expected) in [("xor", xor_value), ("xnor", xnor_value)] {
      transfer_value(
        sequence_call(name, [reflect_bool(x), reflect_bool(y)]),
        Json::boolean(expected),
      )
    }
  }
}

///|
test "BP2 parity retains literal small signed integer results" {
  // These exact small integers avoid the recorded round/integral-part conflict.
  for
    (input, even, odd) in [
      (-16, true, false),
      (-11, false, true),
      (-3, false, true),
      (-2, true, false),
      (-1, false, true),
      (0, true, false),
      (1, false, true),
      (2, true, false),
      (3, false, true),
      (10, true, false),
      (11, false, true),
      (16, true, false),
    ] {
    transfer_value(
      sequence_call("isEven", [sequence_num(input)]),
      Json::boolean(even),
    )
    transfer_value(
      sequence_call("isOdd", [sequence_num(input)]),
      Json::boolean(odd),
    )
  }
}

///|
test "BP3 shared predicate binding preserves names arity and aliased inputs" {
  let cases : Array[(String, Array[String], Array[OrderingExpr], Bool)] = [
    ("xor", ["x", "y"], [reflect_bool(true), reflect_bool(false)], true),
    ("xnor", ["x", "y"], [reflect_bool(true), reflect_bool(false)], false),
    ("isEven", ["x"], [sequence_num(2)], true),
    ("isOdd", ["x"], [sequence_num(2)], false),
  ]
  for (name, labels, safe, expected) in cases {
    let function = ordering_leaf(
      "std." + name,
      Index(sequence_var("std").tree, reflect_string(name).tree),
    )
    transfer_value(
      sequence_call("length", [function]),
      Json::number(labels.length().to_double()),
    )
    let positional : Array[(String?, OrderingExpr)] = safe.map(value => {
      (None, value)
    })
    let named : Array[(String?, OrderingExpr)] = safe.mapi((i, value) => {
      (Some(labels[i]), value)
    })
    let forms = [positional, named]
    if labels.length() == 2 {
      forms.push([(Some("y"), safe[1]), (Some("x"), safe[0])])
      forms.push([(None, safe[0]), (Some("y"), safe[1])])
    }
    for args in forms {
      transfer_value(rounding_apply(name, args), Json::boolean(expected))
      transfer_value(
        sequence_local(
          [("f", function)],
          shared_mode_call(sequence_var("f"), args),
        ),
        Json::boolean(expected),
      )
    }
    let extra = positional.copy()
    extra.push((None, safe[0]))
    let unknown = positional.copy()
    unknown.push((Some("unknown"), safe[0]))
    let conflict = positional.copy()
    conflict.push((Some("x"), safe[0]))
    let invalid : Array[Array[(String?, OrderingExpr)]] = [
      [],
      extra,
      unknown,
      conflict,
    ]
    for missing in 0..<labels.length() {
      invalid.push(named.filter(pair => pair.0 != Some(labels[missing])))
    }
    for args in invalid {
      transfer_reject(rounding_apply(name, args))
      transfer_reject(
        sequence_local(
          [("f", function)],
          shared_mode_call(sequence_var("f"), args),
        ),
      )
    }
    let alias_args : Array[(String?, OrderingExpr)] = [
      (Some("x"), sequence_var("saved")),
    ]
    if labels.length() == 2 {
      alias_args.push((Some("y"), safe[1]))
    }
    let original = if labels.length() == 2 {
      Json::boolean(true)
    } else {
      Json::number(2)
    }
    transfer_value(
      sequence_local(
        [
          ("original", safe[0]),
          ("saved", sequence_var("original")),
          ("f", function),
        ],
        ordering_array([
          shared_mode_call(sequence_var("f"), alias_args),
          shared_mode_call(sequence_var("f"), alias_args),
          sequence_var("original"),
          sequence_var("saved"),
        ]),
      ),
      Json::array([
        Json::boolean(expected),
        Json::boolean(expected),
        original,
        original,
      ]),
    )
  }
}

///|
test "BP4 predicates propagate sole required errors and parity rejects nonnumbers" {
  let needed = ordering_error("predicate-required")
  for name in ["xor", "xnor"] {
    // Both Boolean values matter; neither operand has an absorbing value.
    for safe in [reflect_bool(false), reflect_bool(true)] {
      for args in [[needed, safe], [safe, needed]] {
        let call = sequence_call(name, args)
        transfer_reject(call)
        transfer_reject(sequence_call("type", [call]))
      }
    }
  }
  for name in ["isEven", "isOdd"] {
    for
      value in [
        needed,
        ordering_leaf("null", Literal(Json::null())),
        reflect_bool(false),
        reflect_bool(true),
        reflect_string("2"),
        ordering_array([]),
        reflect_object([]),
      ] {
      transfer_reject(sequence_call(name, [value]))
    }
    transfer_reject(sequence_call("type", [sequence_call(name, [needed])]))
  }
  // No nonboolean xor/xnor success or failure oracle is imposed here.
}

///|
test "BP5 unused predicate calls retain ordinary lazy branches and arguments" {
  let unread = ordering_error("predicate-unused")
  for name in ["xor", "xnor", "isEven", "isOdd"] {
    let args = [unread]
    if name == "xor" || name == "xnor" {
      args.push(unread)
    }
    let call = sequence_call(name, args)
    transfer_value(ordering_unused(call), 42)
    transfer_value(transfer_if(reflect_bool(false), call, sequence_num(9)), 9)
    transfer_value(ordering_binary(reflect_bool(false), "&&", call), false)
    transfer_value(ordering_binary(reflect_bool(true), "||", call), true)
    let ignore_argument = ordering_leaf(
      "function(unused) 8",
      Func(
        [{ name: "unused", default_value: None, range: None, }],
        sequence_num(8).tree,
      ),
    )
    transfer_value(shared_mode_call(ignore_argument, [(None, call)]), 8)
  }
}
