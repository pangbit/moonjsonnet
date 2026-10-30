// Frozen independent criteria: SPEC-EXTREMA-COMPARISON-2026-10-23.md.
// Pending baseline. No non-Array or exact callback-count oracle is introduced.

///|
fn extrema_comparison_reject(
  value : OrderingExpr,
  handmade : Bool,
  marker : String?,
) -> Unit raise {
  assert_eq(
    ordering_program(ordering_unused(value), handmade).evaluate(
      limits=sequence_limits(),
    ),
    42,
  )
  let program = ordering_program(value, handmade)
  try program.evaluate(limits=sequence_limits()) catch {
    @moonjsonnet.Error(d) => {
      assert_true(d.kind == @moonjsonnet.Runtime || d.kind == @moonjsonnet.Type)
      if marker is Some(text) {
        assert_eq(d.kind, @moonjsonnet.Runtime)
        assert_eq(d.message, text)
      }
    }
  } noraise {
    _ => fail("extrema skipped a required comparison")
  }
}

///|
fn extrema_singleton_domain(name : String, handmade : Bool) -> Unit raise {
  let unread = ordering_error("extrema-comparison-unread-body")
  for
    invalid in [
      merge_patch_object([]),
      reflect_bool(false),
      ordering_leaf("null", Literal(Json::null())),
      make_function([], unread),
      ordering_array([reflect_bool(true)]),
      ordering_array([ordering_array([merge_patch_object([])])]),
    ] {
    for
      value in [
        extrema_demand_call(name, ordering_array([invalid]), None, None),
        extrema_demand_call(
          name,
          ordering_array([sequence_num(7)]),
          Some(make_function(["item"], invalid)),
          None,
        ),
      ] {
      // Observe the result head, avoiding function/nested-value manifestation.
      extrema_comparison_reject(sequence_call("type", [value]), handmade, None)
    }
  }
}

///|
test "source minArray compares singleton values and explicit keys" {
  extrema_singleton_domain("minArray", false)
}

///|
test "handmade minArray compares singleton values and explicit keys" {
  extrema_singleton_domain("minArray", true)
}

///|
test "source maxArray compares singleton values and explicit keys" {
  extrema_singleton_domain("maxArray", false)
}

///|
test "handmade maxArray compares singleton values and explicit keys" {
  extrema_singleton_domain("maxArray", true)
}

///|
fn extrema_initial_key_comparison(name : String, handmade : Bool) -> Unit raise {
  let marker = "extrema-initial-key-tail"
  let unread = ordering_error(marker)
  let first = ordering_array([sequence_num(0), unread])
  let numeric_key = make_function(
    ["item"],
    ordering_array([sequence_var("item"), unread]),
  )
  for
    value in [
      extrema_demand_call(
        name,
        ordering_array([sequence_num(7)]),
        Some(make_function(["item"], first)),
        None,
      ),
      extrema_demand_call(name, ordering_array([first]), None, None),
      extrema_demand_call(
        name,
        ordering_array([first, ordering_array([sequence_num(1)])]),
        None,
        None,
      ),
      extrema_demand_call(
        name,
        ordering_array([sequence_num(0), sequence_num(1)]),
        Some(numeric_key),
        None,
      ),
      extrema_demand_call(
        name,
        ordering_array([sequence_num(7)]),
        Some(
          make_function(["item"], ordering_array([ordering_array([]), first])),
        ),
        None,
      ),
    ] {
    extrema_comparison_reject(
      sequence_call("type", [value]),
      handmade,
      Some(marker),
    )
  }
}

///|
test "source minArray demands the initial self comparison key prefix" {
  extrema_initial_key_comparison("minArray", false)
}

///|
test "handmade minArray demands the initial self comparison key prefix" {
  extrema_initial_key_comparison("minArray", true)
}

///|
test "source maxArray demands the initial self comparison key prefix" {
  extrema_initial_key_comparison("maxArray", false)
}

///|
test "handmade maxArray demands the initial self comparison key prefix" {
  extrema_initial_key_comparison("maxArray", true)
}

///|
fn extrema_predicate_before_payload(
  name : String,
  handmade : Bool,
) -> Unit raise {
  let marker = "extrema-key-condition"
  for
    key in [
      make_function(["item"], ordering_error(marker)),
      make_function(["item"], ordering_array([ordering_error(marker)])),
    ] {
    let value = extrema_demand_call(
      name,
      ordering_array([
        rewrite_gate(reflect_string("selected-payload"), sequence_num(7)),
      ]),
      Some(key),
      None,
    )
    for observation in [value, sequence_call("type", [value])] {
      let counts : Map[String, Int32] = Map([])
      let scoped = additive_probe_scope(observation)
      assert_eq(
        ordering_program(ordering_unused(scoped), handmade).evaluate(
          native_functions=rewrite_natives(counts),
          limits=sequence_limits(),
        ),
        42,
      )
      assert_eq(counts.length(), 0)
      let program = ordering_program(scoped, handmade)
      try
        program.evaluate(
          native_functions=rewrite_natives(counts),
          limits=sequence_limits(),
        )
      catch {
        @moonjsonnet.Error(d) => {
          assert_eq(d.kind, @moonjsonnet.Runtime)
          assert_eq(d.message, marker)
        }
      } noraise {
        _ => fail("required key condition error was suppressed")
      }
      assert_eq(
        counts.length(),
        0,
        msg="failed key condition must skip selection",
      )
    }
    // The condition and selected branch are dependent, not independent errors.
    let pure = extrema_demand_call(
      name,
      ordering_array([ordering_error("extrema-unselected-branch")]),
      Some(key),
      None,
    )
    extrema_comparison_reject(pure, handmade, Some(marker))
    extrema_comparison_reject(
      sequence_call("type", [pure]),
      handmade,
      Some(marker),
    )
  }
}

///|
test "source minArray requires its key condition before the selected payload" {
  extrema_predicate_before_payload("minArray", false)
}

///|
test "handmade minArray requires its key condition before the selected payload" {
  extrema_predicate_before_payload("minArray", true)
}

///|
test "source maxArray requires its key condition before the selected payload" {
  extrema_predicate_before_payload("maxArray", false)
}

///|
test "handmade maxArray requires its key condition before the selected payload" {
  extrema_predicate_before_payload("maxArray", true)
}

///|
test "extrema singleton comparison retains comparable keys and selected result demand" {
  let unread = ordering_error("extrema-comparison-unused-payload")
  for name in ["minArray", "maxArray"] {
    for
      key in [
        sequence_num(0),
        reflect_string("e\u0301\u0000😀"),
        ordering_array([]),
        ordering_array([sequence_num(0), ordering_array([reflect_string("x")])]),
      ] {
      sequence_value(
        extrema_demand_call(
          name,
          ordering_array([sequence_num(7)]),
          Some(make_function(["item"], key)),
          None,
        ),
        7,
      )
    }
    for
      (payload, expected) in [
        (merge_patch_object([("bad", unread)]), "object"),
        (ordering_array([unread]), "array"),
        (make_function([], unread), "function"),
        (reflect_bool(true), "boolean"),
        (ordering_leaf("null", Literal(Json::null())), "null"),
      ] {
      sequence_value(
        sequence_call("type", [
          extrema_demand_call(
            name,
            ordering_array([payload]),
            Some(make_function(["item"], sequence_num(0))),
            None,
          ),
        ]),
        Json::string(expected),
      )
    }
    sequence_failure(
      extrema_demand_call(
        name,
        ordering_array([ordering_error("extrema-required-selection")]),
        Some(make_function(["item"], sequence_num(0))),
        None,
      ),
      @moonjsonnet.Runtime,
      Some("extrema-required-selection"),
    )
  }
}
