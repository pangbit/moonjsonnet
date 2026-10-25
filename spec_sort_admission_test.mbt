// Fixed-source admission adjudication in SPEC-SORT-DEMAND-2026-10-25.md.
// No reference interpreter, native callback count, or first-error oracle.

///|
fn sort_admission_limits() -> @moonjsonnet.Limits {
  { ..@moonjsonnet.Limits::default(), steps: 200000, depth: 128, stack: 256, }
}

///|
fn sort_admission_value(
  value : OrderingExpr,
  handmade : Bool,
  expected : Json,
) -> Unit raise {
  assert_eq(
    ordering_program(value, handmade).evaluate(limits=sort_admission_limits()),
    expected,
  )
}

///|
fn sort_admission_failure(
  value : OrderingExpr,
  handmade : Bool,
  kind : @moonjsonnet.ErrorKind,
) -> Unit raise {
  let program = ordering_program(value, handmade)
  try program.evaluate(limits=sort_admission_limits()) catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, kind)
  } noraise {
    _ => fail("fixed sort definition requires a failure")
  }
}

///|
fn sort_admission_shape(value : OrderingExpr) -> OrderingExpr {
  sequence_local(
    [("sorted", value)],
    ordering_array([
      sequence_call("type", [sequence_var("sorted")]),
      sequence_call("length", [sequence_var("sorted")]),
    ]),
  )
}

///|
fn sort_admission_strings(handmade : Bool) -> Unit raise {
  for text in ["", "a", "😀"] {
    for key in [None, Some(ordering_error("sort-short-string-unused-key"))] {
      let value = sort_demand_call(reflect_string(text), key, true)
      sort_admission_value(value, handmade, Json::string(text))
      sort_admission_value(sequence_call("type", [value]), handmade, "string")
    }
  }
  sort_admission_value(
    sort_demand_call(reflect_string("ba"), None, false),
    handmade,
    ["a", "b"],
  )
  sort_admission_value(
    sort_demand_call(reflect_string("😀aé"), None, true),
    handmade,
    ["a", "é", "😀"],
  )
  sort_admission_value(
    sort_demand_call(reflect_string("a\u0000"), None, false),
    handmade,
    ["\u0000", "a"],
  )
  let descending = make_function(
    ["x"],
    ordering_leaf(
      "-std.codepoint(x)",
      Unary("-", sequence_call("codepoint", [sequence_var("x")]).tree),
    ),
  )
  sort_admission_value(
    sort_demand_call(reflect_string("a😀é"), Some(descending), true),
    handmade,
    ["😀", "é", "a"],
  )
  for n in [30, 31, 32] {
    let builder = StringBuilder()
    let expected : Array[Json] = []
    for _ in 0..<n {
      builder.write_string("a")
      expected.push(Json::string("a"))
    }
    sort_admission_value(
      sort_demand_call(reflect_string(builder.to_string()), None, false),
      handmade,
      Json::array(expected),
    )
  }
}

///|
test "source sort admission follows String identity character ordering and slice seam" {
  sort_admission_strings(false)
}

///|
test "handmade sort admission follows String identity character ordering and slice seam" {
  sort_admission_strings(true)
}

///|
fn sort_admission_other_heads(handmade : Bool) -> Unit raise {
  let unread = ordering_error("sort-object-or-function-body-unread")
  for n in [0, 1] {
    let object = merge_patch_object(if n == 0 { [] } else { [("v", unread)] })
    let function = make_function(if n == 0 { [] } else { ["x"] }, unread)
    for key in [None, Some(ordering_error("sort-short-head-unused-key"))] {
      sort_admission_value(
        sort_admission_shape(sort_demand_call(object, key, false)),
        handmade,
        Json::array(["object", Json::number(n.to_double())]),
      )
      sort_admission_value(
        sort_admission_shape(sort_demand_call(function, key, true)),
        handmade,
        Json::array(["function", Json::number(n.to_double())]),
      )
    }
  }
  // The source's <=30 branch defers arr[i], even when indexing would fail.
  for n in [2, 30, 31] {
    let fields : Array[(String, OrderingExpr)] = []
    let names : Array[String] = []
    for i in 0..<n {
      fields.push(("v" + i.to_string(), unread))
      names.push("p" + i.to_string())
    }
    for input in [merge_patch_object(fields), make_function(names, unread)] {
      let sorted = sort_demand_call(
        input,
        Some(make_function(["x"], sequence_num(0))),
        true,
      )
      if n <= 30 {
        sort_admission_value(
          sort_admission_shape(sorted),
          handmade,
          Json::array(["array", Json::number(n.to_double())]),
        )
        sort_admission_failure(
          make_index(sorted, 0),
          handmade,
          @moonjsonnet.Type,
        )
        sort_admission_failure(
          sequence_call("length", [sort_demand_call(input, None, false)]),
          handmade,
          @moonjsonnet.Type,
        )
      } else {
        // The long branch reaches slice's explicit String-or-Array assertion.
        sort_admission_failure(
          sequence_call("length", [sorted]),
          handmade,
          @moonjsonnet.Assertion,
        )
      }
    }
  }
  let native_input = sequence_call("native", [
    reflect_string("sort-function-input"),
  ])
  let calls = Ref(0)
  let natives : Map[String, @moonjsonnet.NativeFunction] = Map([
    (
      "sort-function-input",
      {
        params: ["x"],
        callback: _ => {
          calls.val += 1
          0
        },
      },
    ),
  ])
  assert_eq(
    ordering_program(
      sort_admission_shape(
        sort_demand_call(
          native_input,
          Some(ordering_error("sort-native-input-unused-key")),
          true,
        ),
      ),
      handmade,
    ).evaluate(native_functions=natives, limits=sort_admission_limits()),
    Json::array(["function", 1]),
  )
  assert_eq(calls.val, 0)
  let builtin_input = additive_select(sequence_var("std"), "length")
  sort_admission_value(
    sort_admission_shape(sort_demand_call(builtin_input, None, false)),
    handmade,
    ["function", 1],
  )
}

///|
test "source sort admission preserves Object Function heads and demanded index boundaries" {
  sort_admission_other_heads(false)
}

///|
test "handmade sort admission preserves Object Function heads and demanded index boundaries" {
  sort_admission_other_heads(true)
}

///|
test "sort admission skips every unused key head and incompatible call profile" {
  let unread = ordering_error("sort-unused-key-child")
  let keys = [
    ordering_leaf("null", Literal(Json::null())),
    reflect_bool(false),
    sequence_num(7),
    reflect_string("not a function"),
    ordering_array([unread]),
    merge_patch_object([("v", unread)]),
    make_function([], unread),
    make_function(["x", "y"], unread),
    ordering_error("sort-unused-key-expression"),
  ]
  for handmade in [false, true] {
    for
      (input, expected) in [
        (ordering_array([]), Json::array([])),
        (ordering_array([sequence_num(9)]), Json::array([9])),
      ] {
      for key in keys {
        for named in [false, true] {
          sort_admission_value(
            sort_demand_call(input, Some(key), named),
            handmade,
            expected,
          )
        }
      }
    }
  }
}

///|
test "sort independent key errors reject without promising a winning diagnostic" {
  let first = ordering_error("sort-independent-first")
  let second = ordering_error("sort-independent-second")
  let condition = ordering_binary(sequence_var("x"), "==", sequence_num(1))
  let body : OrderingExpr = {
    source: "if (" +
    condition.source +
    ") then (" +
    first.source +
    ") else (" +
    second.source +
    ")",
    tree: ordering_ast(If(condition.tree, first.tree, second.tree)),
  }
  let value = sequence_call("length", [
    sort_demand_call(
      ordering_array([sequence_num(1), sequence_num(2)]),
      Some(make_function(["x"], body)),
      false,
    ),
  ])
  for handmade in [false, true] {
    let program = ordering_program(value, handmade)
    try program.evaluate(limits=sort_admission_limits()) catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Runtime)
        assert_true(
          d.message == "sort-independent-first" ||
          d.message == "sort-independent-second",
        )
      }
    } noraise {
      _ => fail("sort concealed required key errors")
    }
  }
}
