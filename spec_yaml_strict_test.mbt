// Adjacent mode control frozen before repair: strict forces heads, not unused types.

///|
fn yaml_demand_strict(call : OrderingExpr) -> OrderingExpr {
  guard call.tree.kind is Call(callee, args, _) else {
    abort("strict YAML fixture must be a call")
  }
  {
    source: call.source + " tailstrict",
    tree: ordering_ast(Call(callee, args, true)),
  }
}

///|
test "YAML tailstrict forces bound option heads without validating unused condition types" {
  sequence_failure(
    yaml_demand_strict(
      yaml_demand_doc(
        sequence_num(1),
        ordering_error("strict-indent-required"),
        reflect_bool(true),
      ),
    ),
    @moonjsonnet.Runtime,
    Some("strict-indent-required"),
  )
  sequence_failure(
    yaml_demand_strict(
      yaml_demand_doc(
        sequence_num(1),
        reflect_bool(false),
        ordering_error("strict-quote-required"),
      ),
    ),
    @moonjsonnet.Runtime,
    Some("strict-quote-required"),
  )
  sequence_value(
    yaml_demand_strict(
      yaml_demand_doc(
        sequence_num(1),
        sequence_num(0),
        ordering_leaf("null", Literal(Json::null())),
      ),
    ),
    "1",
  )
  sequence_value(
    yaml_demand_strict(
      yaml_demand_doc(
        sequence_num(1),
        ordering_array([ordering_error("nested-option-unused")]),
        reflect_bool(true),
      ),
    ),
    "1",
  )
  deletion_binding_reject(
    yaml_demand_strict(
      rounding_apply("manifestYamlDoc", [
        (Some("unknown"), ordering_error("binding-must-skip")),
      ]),
    ),
  )
  sequence_value(
    yaml_demand_strict(
      yaml_demand_doc(
        assertion_paths_object([], reflect_bool(false), None),
        reflect_bool(false),
        reflect_bool(true),
      ),
    ),
    "{}",
  )
}
