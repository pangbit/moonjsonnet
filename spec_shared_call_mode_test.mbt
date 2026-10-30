// Bounded dispatch review: SPEC-YAML-DEMAND-2026-10-25.md.
// Ordinary calls have fixed-rule oracles; tailstrict is a separate regression profile.

///|
fn shared_mode_call(
  callee : OrderingExpr,
  args : Array[(String?, OrderingExpr)],
  strict~ : Bool = false,
) -> OrderingExpr {
  {
    source: "(" +
    callee.source +
    ")(" +
    args
    .map(arg => {
      (match arg.0 {
        Some(name) => name + "="
        None => ""
      }) +
      "(" +
      arg.1.source +
      ")"
    })
    .join(",") +
    ")" +
    (if strict { " tailstrict" } else { "" }),
    tree: ordering_ast(
      Call(callee.tree, args.map(arg => (arg.0, arg.1.tree)), strict),
    ),
  }
}

///|
test "shared ordinary calls keep supplied and default errors lazy across aliases and named forms" {
  let function = sort_contract_optional(
    ordering_error("unused-default"),
    sequence_var("x"),
  )
  let forms : Array[Array[(String?, OrderingExpr)]] = [
    [(None, sequence_num(7))],
    [(None, sequence_num(7)), (None, ordering_error("unused-supplied"))],
    [
      (Some("extra"), ordering_error("unused-supplied")),
      (Some("x"), sequence_num(7)),
    ],
    [(Some("x"), sequence_num(7)), (Some("extra"), sequence_num(9))],
  ]
  for args in forms {
    sequence_value(shared_mode_call(function, args), 7)
    sequence_value(
      sequence_local(
        [("f", function)],
        shared_mode_call(sequence_var("f"), args),
      ),
      7,
    )
  }
}

///|
test "shared tailstrict regression forces supplied and default heads without nested payloads" {
  let function = sort_contract_optional(
    ordering_error("strict-default-head"),
    sequence_var("x"),
  )
  for use_alias in [false, true] {
    let callee = if use_alias { sequence_var("f") } else { function }
    for
      (args, marker) in [
        ([(None, sequence_num(7))], "strict-default-head"),
        (
          [
            (Some("extra"), ordering_error("strict-supplied-head")),
            (Some("x"), sequence_num(7)),
          ],
          "strict-supplied-head",
        ),
      ] {
      let call = shared_mode_call(callee, args, strict=true)
      sequence_failure(
        if use_alias {
          sequence_local([("f", function)], call)
        } else {
          call
        },
        @moonjsonnet.Runtime,
        Some(marker),
      )
    }
  }
  sequence_value(
    shared_mode_call(
      function,
      [(Some("extra"), sequence_num(9)), (Some("x"), sequence_num(7))],
      strict=true,
    ),
    7,
  )
  for
    extra in [
      ordering_array([ordering_error("nested-unused")]),
      reflect_object([(reflect_string("h"), 1, ordering_error("field-unused"))]),
      make_function([], ordering_error("body-uncalled")),
    ] {
    sequence_value(
      shared_mode_call(
        function,
        [(None, sequence_num(7)), (None, extra)],
        strict=true,
      ),
      7,
    )
    sequence_value(
      shared_mode_call(
        sort_contract_optional(extra, sequence_var("x")),
        [(None, sequence_num(7))],
        strict=true,
      ),
      7,
    )
  }
}

///|
test "source routed foldl and deletion closures retain lazy and explicit strict argument modes" {
  let unused = ordering_error("source-unused-head")
  let cases : Array[(String, Array[(String?, OrderingExpr)], Json)] = [
    (
      "foldl",
      [
        (Some("init"), sequence_num(42)),
        (Some("func"), unused),
        (Some("arr"), ordering_array([])),
      ],
      42,
    ),
    ("remove", [(Some("elem"), unused), (Some("arr"), ordering_array([]))], []),
    (
      "objectRemoveKey",
      [(Some("key"), unused), (Some("obj"), reflect_object([]))],
      {},
    ),
    // Positional only: idx/at/i naming is not adjudicated here.
    ("removeAt", [(None, ordering_array([])), (None, unused)], []),
  ]
  for (name, args, expected) in cases {
    let function = additive_select(sequence_var("std"), name)
    for use_alias in [false, true] {
      let callee = if use_alias { sequence_var("f") } else { function }
      let normal = shared_mode_call(callee, args)
      let strict = shared_mode_call(callee, args, strict=true)
      sequence_value(
        if use_alias {
          sequence_local([("f", function)], normal)
        } else {
          normal
        },
        expected,
      )
      sequence_failure(
        if use_alias {
          sequence_local([("f", function)], strict)
        } else {
          strict
        },
        @moonjsonnet.Runtime,
        Some("source-unused-head"),
      )
    }
  }
}

///|
test "higher order source and native consumers keep ordinary callback defaults lazy" {
  let body = ordering_binary(sequence_var("acc"), "+", sequence_num(1))
  let unused = ordering_error("callback-default-unused")
  let callback : OrderingExpr = {
    source: "function(acc,item,extra=(" +
    unused.source +
    "))(" +
    body.source +
    ")",
    tree: ordering_ast(
      Func(
        [
          { name: "acc", default_value: None, range: None, },
          { name: "item", default_value: None, range: None, },
          { name: "extra", default_value: Some(unused.tree), range: None, },
        ],
        body.tree,
      ),
    ),
  }
  for strict in [false, true] {
    sequence_value(
      shared_mode_call(
        additive_select(sequence_var("std"), "foldl"),
        [
          (Some("arr"), ordering_array([ordering_error("fold-item-unused")])),
          (Some("init"), sequence_num(0)),
          (Some("func"), callback),
        ],
        strict~,
      ),
      1,
    )
    sequence_value(
      shared_mode_call(
        additive_select(sequence_var("std"), "map"),
        [
          (None, sort_contract_optional(unused, sequence_num(7))),
          (None, ordering_array([ordering_error("map-item-unused")])),
        ],
        strict~,
      ),
      [7],
    )
    sequence_value(
      shared_mode_call(
        additive_select(sequence_var("std"), "sort"),
        [
          (Some("keyF"), sort_contract_optional(unused, sequence_var("x"))),
          (Some("arr"), ordering_array([sequence_num(2), sequence_num(1)])),
        ],
        strict~,
      ),
      [1, 2],
    )
  }
}

///|
test "explicit strict calls do not spread into ordinary YAML bodies or lose source Stream mode" {
  let unused = ordering_error("yaml-forwarded-head")
  let inner = yaml_demand_doc(sequence_num(1), unused, reflect_bool(true))
  sequence_value(
    shared_mode_call(make_function([], inner), [], strict=true),
    "1",
  )
  let function = make_function(
    ["value", "option"],
    yaml_demand_doc(
      sequence_var("value"),
      sequence_var("option"),
      reflect_bool(true),
    ),
  )
  let args : Array[(String?, OrderingExpr)] = [
    (None, sequence_num(1)),
    (None, unused),
  ]
  sequence_value(shared_mode_call(function, args), "1")
  sequence_failure(
    shared_mode_call(function, args, strict=true),
    @moonjsonnet.Runtime,
    Some("yaml-forwarded-head"),
  )
  let stream = yaml_demand_stream(
    ordering_array([sequence_num(1)]),
    unused,
    reflect_bool(true),
    reflect_bool(false),
  )
  sequence_value(stream, "---\n1\n")
  // The unchanged source Stream is a Closure; its explicit strict call forces
  // the unused option head before its ordinary map-to-Doc calls can skip it.
  sequence_failure(
    yaml_demand_strict(stream),
    @moonjsonnet.Runtime,
    Some("yaml-forwarded-head"),
  )
}

///|
test "ordinary and strict binding rejection precedes supplied default and body errors" {
  let bad = ordering_error("binding-must-skip")
  let function = sort_contract_optional(bad, bad)
  let cases : Array[(OrderingExpr, Array[(String?, OrderingExpr)])] = [
    (function, [(Some("unknown"), bad)]),
    (function, [(None, bad), (Some("x"), bad)]),
    (
      additive_select(sequence_var("std"), "foldl"),
      [(Some("func"), bad), (Some("arr"), ordering_array([]))],
    ),
    (
      additive_select(sequence_var("std"), "objectRemoveKey"),
      [(Some("unknown"), bad)],
    ),
    (
      additive_select(sequence_var("std"), "manifestYamlDoc"),
      [(Some("unknown"), bad)],
    ),
  ]
  for (callee, args) in cases {
    for strict in [false, true] {
      deletion_binding_reject(shared_mode_call(callee, args, strict~))
    }
  }
}
