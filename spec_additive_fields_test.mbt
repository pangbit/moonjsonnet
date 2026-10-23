// Fixed independent oracle and DF0 limit: SPEC-ADDITIVE-FIELDS-2026-10-23.md.

///|
struct AdditiveMember {
  source : String
  field : @moonjsonnet.AstField
}

///|
fn additive_select(value : OrderingExpr, name : String) -> OrderingExpr {
  let key = reflect_string(name)
  {
    source: (if value.source == "super" {
      "super"
    } else {
      "(" + value.source + ")"
    }) +
    "[" +
    key.source +
    "]",
    tree: ordering_ast(Index(value.tree, key.tree)),
  }
}

///|
fn additive_formula(key : OrderingExpr, rhs : OrderingExpr) -> OrderingExpr {
  let parent = ordering_leaf("super", Var("super"))
  let exists : OrderingExpr = {
    source: "(" + key.source + ") in super",
    tree: ordering_ast(Binary("in", key.tree, parent.tree)),
  }
  let prior : OrderingExpr = {
    source: "super[" + key.source + "]",
    tree: ordering_ast(Index(parent.tree, key.tree)),
  }
  let sum = ordering_binary(prior, "+", rhs)
  {
    source: "if (" +
    exists.source +
    ") then (" +
    sum.source +
    ") else (" +
    rhs.source +
    ")",
    tree: ordering_ast(If(exists.tree, sum.tree, rhs.tree)),
  }
}

///|
fn additive_member(
  spelling : String,
  key : OrderingExpr,
  body_key : OrderingExpr,
  visibility : Int,
  rhs : OrderingExpr,
  expanded : Bool,
) -> AdditiveMember {
  let value = if expanded { additive_formula(body_key, rhs) } else { rhs }
  let separator = match visibility {
    2 => "::"
    3 => ":::"
    _ => ":"
  }
  {
    source: spelling +
    (if expanded { "" } else { "+" }) +
    separator +
    "(" +
    value.source +
    ")",
    field: {
      key: key.tree,
      value: value.tree,
      visibility,
      additive: !expanded,
    },
  }
}

///|
fn additive_plain(name : String, value : OrderingExpr) -> AdditiveMember {
  {
    source: Json::string(name).stringify() + ":(" + value.source + ")",
    field: {
      key: reflect_string(name).tree,
      value: value.tree,
      visibility: 1,
      additive: false,
    },
  }
}

///|
fn additive_object(fields : Array[AdditiveMember]) -> OrderingExpr {
  {
    source: "{" + fields.map(f => f.source).join(",") + "}",
    tree: ordering_ast(Obj(fields.map(f => f.field), [], [])),
  }
}

///|
fn additive_k(
  spelling : String,
  visibility : Int,
  rhs : OrderingExpr,
  expanded : Bool,
) -> AdditiveMember {
  additive_member(
    spelling,
    reflect_string("k"),
    reflect_string("k"),
    visibility,
    rhs,
    expanded,
  )
}

///|
fn additive_probe_scope(value : OrderingExpr) -> OrderingExpr {
  sequence_local(
    [("probe", sequence_call("native", [reflect_string("rewrite-probe")]))],
    value,
  )
}

///|
test "additive separator visibility and hidden prefix presence defer payload demand" {
  let visibility_table = [
    (1, 1, true),
    (1, 2, false),
    (1, 3, true),
    (2, 1, false),
    (2, 2, false),
    (2, 3, true),
    (3, 1, true),
    (3, 2, false),
    (3, 3, true),
  ]
  for (left_visibility, right_visibility, visible) in visibility_table {
    for spelling in ["k", "\"k\"", "[\"k\"]"] {
      for expanded in [false, true] {
        let left = rewrite_gate(reflect_string("L"), sequence_num(10))
        let right = rewrite_gate(reflect_string("R"), sequence_num(3))
        let base = reflect_object([(reflect_string("k"), left_visibility, left)])
        let overlay = additive_object([
          additive_k(spelling, right_visibility, right, expanded),
        ])
        let object = ordering_binary(base, "+", overlay)
        let o = sequence_var("o")
        for mode in ["unused", "names", "read"] {
          let body = match mode {
            "unused" => sequence_num(42)
            "names" =>
              ordering_array([
                sequence_call("objectFields", [o]),
                sequence_call("objectFieldsAll", [o]),
              ])
            _ =>
              ordering_array([additive_select(o, "k"), additive_select(o, "k")])
          }
          let value = additive_probe_scope(
            sequence_local([("o", object)], body),
          )
          let expected : Json = match mode {
            "unused" => 42
            "names" =>
              Json::array([
                if visible {
                  Json::array(["k"])
                } else {
                  Json::array([])
                },
                ["k"],
              ])
            _ => [13, 13]
          }
          for handmade in [false, true] {
            let counts : Map[String, Int] = Map([])
            let program = ordering_program(value, handmade)
            assert_eq(counts.length(), 0)
            assert_eq(
              program.evaluate(
                native_functions=rewrite_natives(counts),
                limits=sequence_limits(),
              ),
              expected,
            )
            assert_eq(
              counts.get("L").unwrap_or(0),
              if mode == "read" {
                1
              } else {
                0
              },
            )
            assert_eq(
              counts.get("R").unwrap_or(0),
              if mode == "read" {
                1
              } else {
                0
              },
            )
            assert_eq(counts.length(), if mode == "read" { 2 } else { 0 })
          }
        }
      }
    }
  }
}

///|
test "additive defining prefixes retain final self across overrides and detached reads" {
  let access = additive_select
  let call = fn(value) { value_head_call(value, []) }
  let self_n = access(sequence_var("self"), "n")
  for expanded in [false, true] {
    let a = reflect_object([
      (reflect_string("n"), 1, sequence_num(1)),
      (reflect_string("k"), 1, self_n),
    ])
    let b = ordering_binary(
      sequence_var("a"),
      "+",
      additive_object([
        additive_plain("n", sequence_num(2)),
        additive_k(
          "k",
          1,
          ordering_binary(self_n, "+", sequence_num(10)),
          expanded,
        ),
      ]),
    )
    let c = ordering_binary(
      sequence_var("b"),
      "+",
      additive_object([
        additive_plain("n", sequence_num(3)),
        additive_k(
          "k",
          1,
          ordering_binary(self_n, "+", sequence_num(100)),
          expanded,
        ),
        additive_plain(
          "saved",
          make_function([], access(sequence_var("super"), "k")),
        ),
      ]),
    )
    let d = ordering_binary(
      sequence_var("c"),
      "+",
      reflect_object([
        (reflect_string("n"), 1, sequence_num(4)),
        (reflect_string("k"), 1, sequence_num(999)),
      ]),
    )
    let value = sequence_local(
      [
        ("a", a),
        ("b", b),
        ("c", c),
        ("d", d),
        ("from_c", access(sequence_var("c"), "saved")),
        ("from_d", access(sequence_var("d"), "saved")),
        (
          "holder",
          reflect_object([
            (reflect_string("n"), 1, sequence_num(99)),
            (reflect_string("f"), 1, sequence_var("from_c")),
            (reflect_string("g"), 1, sequence_var("from_d")),
          ]),
        ),
      ],
      ordering_array([
        access(sequence_var("b"), "k"),
        access(sequence_var("c"), "k"),
        access(sequence_var("d"), "k"),
        call(access(sequence_var("c"), "saved")),
        call(access(sequence_var("d"), "saved")),
        call(sequence_var("from_c")),
        call(sequence_var("from_d")),
        call(access(sequence_var("holder"), "f")),
        call(access(sequence_var("holder"), "g")),
        access(sequence_var("a"), "k"),
      ]),
    )
    sequence_value(value, [14, 119, 999, 16, 18, 16, 18, 16, 18, 1])
    for empty_left in [false, true] {
      let no_parent = additive_object([
        additive_k("k", 1, reflect_bool(false), expanded),
      ])
      let first = if empty_left {
        ordering_binary(reflect_object([]), "+", no_parent)
      } else {
        no_parent
      }
      let later = ordering_binary(
        sequence_var("first"),
        "+",
        reflect_object([
          (reflect_string("k"), 1, sequence_num(99)),
          (
            reflect_string("read"),
            1,
            make_function([], access(sequence_var("super"), "k")),
          ),
        ]),
      )
      sequence_value(
        sequence_local(
          [("first", first), ("later", later)],
          ordering_array([
            access(sequence_var("first"), "k"),
            access(sequence_var("later"), "k"),
            call(access(sequence_var("later"), "read")),
          ]),
        ),
        [false, 99, false],
      )
    }
  }
}

///|
test "nested additive names capture outer self and the outer defining super prefix" {
  let access = additive_select
  let outer_self_key = access(sequence_var("self"), "key")
  let outer_super_key = access(sequence_var("super"), "key")
  for expanded in [false, true] {
    let inner = additive_object([
      additive_plain("key", reflect_string("inner-child")),
      additive_member(
        "[self.key]",
        outer_self_key,
        sequence_var("captured_self_key"),
        1,
        sequence_num(3),
        expanded,
      ),
      additive_member(
        "[super.key]",
        outer_super_key,
        sequence_var("captured_super_key"),
        1,
        sequence_num(4),
        expanded,
      ),
    ])
    let inner = if expanded {
      sequence_local(
        [
          ("captured_self_key", outer_self_key),
          ("captured_super_key", outer_super_key),
        ],
        inner,
      )
    } else {
      inner
    }
    let a = reflect_object([
      (reflect_string("key"), 1, reflect_string("x")),
      (
        reflect_string("nested"),
        1,
        reflect_object([
          (reflect_string("key"), 1, reflect_string("inner-parent")),
          (reflect_string("x"), 1, sequence_num(10)),
          (reflect_string("y"), 1, sequence_num(20)),
          (reflect_string("z"), 1, sequence_num(30)),
        ]),
      ),
    ])
    let b = ordering_binary(
      sequence_var("a"),
      "+",
      additive_object([
        additive_plain("key", reflect_string("y")),
        additive_member(
          "nested",
          reflect_string("nested"),
          reflect_string("nested"),
          1,
          inner,
          expanded,
        ),
      ]),
    )
    let c = ordering_binary(
      sequence_var("b"),
      "+",
      reflect_object([(reflect_string("key"), 1, reflect_string("z"))]),
    )
    let tuple = fn(object) {
      ordering_array([
        access(object, "x"),
        access(object, "y"),
        access(object, "z"),
        access(object, "key"),
      ])
    }
    let value = sequence_local(
      [
        ("a", a),
        ("b", b),
        ("c", c),
        ("bn", access(sequence_var("b"), "nested")),
        ("cn", access(sequence_var("c"), "nested")),
        ("an", access(sequence_var("a"), "nested")),
      ],
      ordering_array([
        tuple(sequence_var("bn")),
        tuple(sequence_var("cn")),
        sequence_call("objectFields", [sequence_var("cn")]),
        ordering_array([
          access(sequence_var("an"), "x"),
          access(sequence_var("an"), "y"),
          access(sequence_var("an"), "z"),
        ]),
      ]),
    )
    sequence_value(value, [
      [14, 23, 30, "inner-child"],
      [14, 20, 33, "inner-child"],
      ["key", "x", "y", "z"],
      [10, 20, 30],
    ])
  }
}

///|
test "additive field errors null omission and missing parent function bodies keep demand boundaries" {
  for expanded in [false, true] {
    let left_error = reflect_object([
      (reflect_string("k"), 2, ordering_error("additive-left")),
    ])
    let left_ok = reflect_object([(reflect_string("k"), 1, sequence_num(10))])
    let right_ok = additive_object([
      additive_k("k", 1, sequence_num(3), expanded),
    ])
    let right_error = additive_object([
      additive_k("k", 1, ordering_error("additive-right"), expanded),
    ])
    let invalid_left = reflect_object([
      (reflect_string("k"), 1, ordering_leaf("null", Literal(Json::null()))),
    ])
    for
      (object, kind, marker) in [
        (
          ordering_binary(left_error, "+", right_ok),
          @moonjsonnet.Runtime,
          Some("additive-left"),
        ),
        (
          ordering_binary(left_ok, "+", right_error),
          @moonjsonnet.Runtime,
          Some("additive-right"),
        ),
        (right_error, @moonjsonnet.Runtime, Some("additive-right")),
        (ordering_binary(invalid_left, "+", right_ok), @moonjsonnet.Type, None),
      ] {
      sequence_value(sequence_call("objectFieldsAll", [object]), ["k"])
      sequence_failure(additive_select(object, "k"), kind, marker)
    }
    let null_key = ordering_leaf("null", Literal(Json::null()))
    let omitted = additive_object([
      additive_member(
        "[null]",
        null_key,
        null_key,
        1,
        ordering_error("omitted-additive-rhs"),
        expanded,
      ),
    ])
    sequence_value(omitted, Json::object(Map([])))
    sequence_value(sequence_call("objectFieldsAll", [omitted]), [])
    let bad_key = ordering_error("additive-key")
    let key_failure = additive_object([
      additive_member(
        "[error 'additive-key']",
        bad_key,
        bad_key,
        1,
        ordering_error("unread-key-rhs"),
        expanded,
      ),
    ])
    sequence_failure(
      sequence_call("objectFieldsAll", [key_failure]),
      @moonjsonnet.Runtime,
      Some("additive-key"),
    )
    let function = additive_object([
      additive_k(
        "k",
        1,
        make_function([], ordering_error("absent-function-body")),
        expanded,
      ),
    ])
    sequence_value(
      sequence_call("type", [additive_select(function, "k")]),
      "function",
    )
    sequence_failure(
      value_head_call(additive_select(function, "k"), []),
      @moonjsonnet.Runtime,
      Some("absent-function-body"),
    )
    let missing = sequence_var("additive_missing")
    for
      object in [
        additive_object([
          additive_member(
            "[additive_missing]",
            missing,
            missing,
            1,
            sequence_num(3),
            expanded,
          ),
        ]),
        additive_object([additive_k("k", 1, missing, expanded)]),
      ] {
      pair_reject(object)
    }
  }
}
