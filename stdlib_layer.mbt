///|
// Enable upstream definitions only after their dependencies and behavior have
// been validated. Native fields override the source layer in Vm::base_env.
fn source_standard_function(name : String) -> Bool {
  match name {
    "map"
    | "mapWithIndex"
    | "range"
    | "substr"
    | "assertEqual"
    | "objectFields"
    | "objectFieldsAll"
    | "objectHas"
    | "objectHasAll"
    | "manifestJson"
    | "split"
    | "format"
    | "isString"
    | "isNumber"
    | "isBoolean"
    | "isObject"
    | "isArray"
    | "isFunction"
    | "slice" => true
    _ => false
  }
}

///|
fn standard_library_expression() -> Expr raise {
  let source = parse(standard_library_source(), "<std>", 512)
  guard source.kind is Obj(fields, locals, assertions, assertion_sites) else {
    raise problem(Runtime, source.loc, "standard library must be an object")
  }
  let enabled = fields.filter(fn(field) {
    match field.key.kind {
      Literal(String(name)) =>
        source_standard_function(name) ||
        (match name {
          "sort"
          | "uniq"
          | "set"
          | "setUnion"
          | "setInter"
          | "setDiff"
          | "setMember"
          | "mergePatch"
          | "get"
          | "objectValues"
          | "objectValuesAll"
          | "objectKeysValues"
          | "objectKeysValuesAll"
          | "mapWithKey"
          | "prune"
          | "all"
          | "any"
          | "flattenArrays"
          | "flattenDeepArray"
          | "filterMap"
          | "count"
          | "repeat"
          | "find"
          | "deepJoin"
          | "min"
          | "max"
          | "clamp"
          | "__compare"
          | "__compare_array"
          | "__array_less"
          | "__array_greater"
          | "__array_less_or_equal"
          | "__array_greater_or_equal"
          | "pi"
          | "deg2rad"
          | "rad2deg"
          | "log2"
          | "log10"
          | "sign"
          | "mod" => true
          "asciiLower"
          | "asciiUpper"
          | "stringChars"
          | "parseHex"
          | "parseOctal"
          | "escapeStringJson"
          | "escapeStringPython"
          | "escapeStringBash"
          | "escapeStringDollars"
          | "escapeStringXML"
          | "findSubstr"
          | "resolvePath" => true
          "manifestJsonMinified"
          | "manifestToml"
          | "manifestYamlStream"
          | "manifestPython"
          | "manifestPythonVars"
          | "manifestIni"
          | "manifestXmlJsonml" => true
          _ => false
        })
      _ => false
    }
  })
  {
    kind: Obj(enabled, locals, assertions, assertion_sites),
    loc: source.loc,
    end: source.end,
  }
}
