///|
// Enable upstream definitions only after their dependencies and behavior have
// been validated. Native fields override the source layer in Vm::base_env.
fn source_standard_function(name : String) -> Bool {
  match name {
    "map"
    | "mapWithIndex"
    | "reverse"
    | "foldl"
    | "sum"
    | "avg"
    | "range"
    | "substr"
    | "assertEqual"
    | "objectFields"
    | "objectFieldsAll"
    | "objectHas"
    | "objectHasAll"
    | "objectRemoveKey"
    | "remove"
    | "removeAt"
    | "manifestJson"
    | "split"
    | "equalsIgnoreCase"
    | "format"
    | "isString"
    | "isNumber"
    | "isBoolean"
    | "isObject"
    | "isArray"
    | "isFunction"
    | "trim"
    | "isEmpty"
    | "round"
    | "isInteger"
    | "isDecimal"
    | "slice" => true
    _ => false
  }
}

///|
// Keep source bodies for native accelerators whose inherited calls must bind
// object-local std to the final receiver. Canonical calls still use the native.
// Methods with known source/native profile conflicts remain excluded.
fn inherited_standard_function(name : String) -> Bool {
  match name {
    "sort"
    | "foldr"
    | "flatMap"
    | "join"
    | "strReplace"
    | "toString"
    | "abs"
    | "lines"
    | "equals"
    | "member"
    | "contains"
    | "parseInt"
    | "manifestJsonEx"
    | "manifestYamlDoc" => true
    _ => false
  }
}

///|
fn standard_library_expression() -> Expr raise {
  let source = parse(standard_library_source(), "<std>", 512)
  guard source.kind is Obj(fields, locals, assertions, assertion_sites) else {
    raise problem(Runtime, source.loc, "standard library must be an object")
  }
  let enabled = fields
    .filter(fn(field) {
      match field.key.kind {
        Literal(String(name)) =>
          source_standard_function(name) ||
          inherited_standard_function(name) ||
          (match name {
            "uniq"
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
    .map(fn(field) {
      if field.key.kind is Literal(String("removeAt")) {
        // idx (documentation) versus at (fixed source) is unresolved. Keep the
        // existing public i spelling without adding aliases; forward lazily and
        // positionally to the unchanged fixed definition for the actual work.
        let loc = field.value.loc
        let args : Array[(String?, Expr)] = [
          (None, { kind: Var("arr"), loc, end: None, }),
          (None, { kind: Var("i"), loc, end: None, }),
        ]
        {
          ..field,
          value: {
            kind: Func(
              [
                { name: "arr", default_value: None, range: None, },
                { name: "i", default_value: None, range: None, },
              ],
              { kind: Call(field.value, args, false), loc, end: None, },
            ),
            loc,
            end: None,
          },
        }
      } else {
        field
      }
    })
  {
    kind: Obj(enabled, locals, assertions, assertion_sites),
    loc: source.loc,
    end: source.end,
  }
}
