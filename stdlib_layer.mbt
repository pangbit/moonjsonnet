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
// Thin wrappers keep their callees' reviewed input profiles.
// Reviewed profile differences use the local adapters below. Integral-part
// parity remains native because its chosen contract rejects the round formula.
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
    | "base64Decode"
    | "stripChars"
    | "startsWith"
    | "endsWith"
    | "lstripChars"
    | "rstripChars"
    | "minArray"
    | "maxArray"
    | "splitLimit"
    | "splitLimitR"
    | "base64"
    | "base64DecodeBytes"
    | "manifestTomlEx"
    | "manifestJsonEx"
    | "manifestYamlDoc" => true
    _ => false
  }
}

///|
// The public compatibility wrapper keeps two parameters. Only this private
// marker admits the documentation/source spellings as aliases of its i slot;
// ordinary functions, including user replacements named removeAt, are unchanged.
fn remove_at_named_arguments(
  params : Array[ExprParameter],
  body : Expr?,
  args : Array[(String?, Int)],
) -> Array[(String?, Int)] {
  if params.length() != 2 ||
    params[0].name != "arr" ||
    params[1].name != "i" ||
    params[0].default_value is Some(_) ||
    params[1].default_value is Some(_) {
    return args
  }
  guard body is Some({ kind: Local(bindings, _), .. }) else { return args }
  if bindings.length() != 1 ||
    bindings[0].name != "$removeAtAliases" ||
    !(bindings[0].value.kind is StandardFunction("removeAt")) {
    return args
  }
  args.map(pair => {
    let name = match pair.0 {
      Some("idx") | Some("at") => Some("i")
      _ => pair.0
    }
    (name, pair.1)
  })
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
        // Keep existing i calls and admit documented idx / fixed-source at as
        // explicit compatibility aliases. The unforced private node marks only
        // this closure; aliases do not become extra parameters or public names.
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
              {
                kind: Local(
                  [
                    {
                      name: "$removeAtAliases",
                      value: {
                        kind: StandardFunction("removeAt"),
                        loc,
                        end: None,
                      },
                      range: None,
                    },
                  ],
                  { kind: Call(field.value, args, false), loc, end: None, },
                ),
                loc,
                end: None,
              },
            ),
            loc,
            end: None,
          },
        }
      } else {
        match field.key.kind {
          Literal(String(name)) =>
            { ..field, value: inherited_profile_expression(name, field.value), }
          _ => field
        }
      }
    })
  {
    kind: Obj(enabled, locals, assertions, assertion_sites),
    loc: source.loc,
    end: source.end,
  }
}
