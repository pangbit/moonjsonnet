# Fixed public standard-library inventory

Generated from the pinned official sources by [tools/spec-public-inventory.mbtx](../../tools/spec-public-inventory.mbtx).
This is an inventory and partial coverage map, not conformance acceptance.
See [review method and unresolved contracts](SPEC-PUBLIC-STDLIB-REVIEW.md).

D = documentation heading; I = inline official API declaration/reference; S = source export; F = specification function.
R = manually reviewed subset of a dimension; U = unreviewed/unmapped. R never means the complete contract passes.
Candidate references may only reflect a function or expect a Go-specific result; they do not earn N/E/L/B coverage.

Signatures are transcribed independently; conflicting names/defaults are not normalized. Full evidence is in [the JSON inventory](spec-public-inventory.json).

| Function | D/I declaration | S/F declaration | N/E/L/B | Existing test-reference candidates |
| --- | --- | --- | --- | --- |
| `abs` | I: `std.abs(n)` | S: `std.abs(n)` | R/R/R/R | [spec_foundation_calls_test.mbt:5](../../spec_foundation_calls_test.mbt#L5); [spec_foundation_numbers_test.mbt:5](../../spec_foundation_numbers_test.mbt#L5) |
| `acos` | I: `std.acos(x)` | Native/not defined in std.jsonnet | U/U/U/U | [std_math_test.mbt:10](../../std_math_test.mbt#L10) |
| `all` | D: `std.all(arr)` | S: `std.all(arr)` | U/U/U/U | [array_std_test.mbt:6](../../array_std_test.mbt#L6) |
| `any` | D: `std.any(arr)` | S: `std.any(arr)` | U/U/U/U | [array_std_test.mbt:6](../../array_std_test.mbt#L6) |
| `asciiLower` | D: `std.asciiLower(str)` | S: `std.asciiLower(str)` | U/U/U/U | [std_string_test.mbt:6](../../std_string_test.mbt#L6) |
| `asciiUpper` | D: `std.asciiUpper(str)` | S: `std.asciiUpper(str)` | U/U/U/U | [std_string_test.mbt:6](../../std_string_test.mbt#L6) |
| `asin` | I: `std.asin(x)` | Native/not defined in std.jsonnet | U/U/U/U | [std_math_test.mbt:10](../../std_math_test.mbt#L10) |
| `assertEqual` | D: `std.assertEqual(a, b)` | S: `std.assertEqual(a, b)` | U/U/U/U | No direct test reference found |
| `atan` | I: `std.atan(x)` | Native/not defined in std.jsonnet | U/U/U/U | [std_math_test.mbt:10](../../std_math_test.mbt#L10) |
| `atan2` | I: `std.atan2(y, x)` | Native/not defined in std.jsonnet | U/U/U/U | [std_math_test.mbt:10](../../std_math_test.mbt#L10) |
| `avg` | D: `std.avg(arr)` | S: `std.avg(arr)` | R/R/R/R | [aggregate_test.mbt:6](../../aggregate_test.mbt#L6); [spec_aggregate_test.mbt:9](../../spec_aggregate_test.mbt#L9); [spec_review_test.mbt:9](../../spec_review_test.mbt#L9) |
| `base64` | D: `std.base64(input)` | S: `std.base64(input)` | U/U/U/U | [std_encoding_test.mbt:16](../../std_encoding_test.mbt#L16) |
| `base64Decode` | D: `std.base64Decode(str)` | S: `std.base64Decode(str)` | U/U/U/U | [std_encoding_test.mbt:20](../../std_encoding_test.mbt#L20) |
| `base64DecodeBytes` | D: `std.base64DecodeBytes(str)` | S: `std.base64DecodeBytes(str)` | U/U/U/U | [lint_type_test.mbt:111](../../lint_type_test.mbt#L111); [standard_native_diagnostics_test.mbt:8](../../standard_native_diagnostics_test.mbt#L8); [std_encoding_test.mbt:20](../../std_encoding_test.mbt#L20) |
| `ceil` | I: `std.ceil(x)` | Native/not defined in std.jsonnet | R/R/R/R | [spec_math_rounding_test.mbt:35](../../spec_math_rounding_test.mbt#L35) |
| `char` | D: `std.char(n)` | Native/not defined in std.jsonnet | R/R/R/R | [spec_string_calls_test.mbt:21](../../spec_string_calls_test.mbt#L21); [spec_string_scalar_test.mbt:5](../../spec_string_scalar_test.mbt#L5); [standard_character_test.mbt:5](../../standard_character_test.mbt#L5) |
| `clamp` | D: `std.clamp(x, minVal, maxVal)` | S: `std.clamp(x, minVal, maxVal)` | U/U/U/U | [array_std_test.mbt:29](../../array_std_test.mbt#L29) |
| `codepoint` | D: `std.codepoint(str)` | Native/not defined in std.jsonnet | R/R/R/R | [spec_review_test.mbt:71](../../spec_review_test.mbt#L71); [spec_string_calls_test.mbt:21](../../spec_string_calls_test.mbt#L21); [spec_string_scalar_test.mbt:5](../../spec_string_scalar_test.mbt#L5) |
| `contains` | D: `std.contains(arr, elem)` | S: `std.contains(arr, elem)` | U/U/U/U | [extrema_test.mbt:50](../../extrema_test.mbt#L50) |
| `cos` | I: `std.cos(x)` | Native/not defined in std.jsonnet | U/U/U/U | [std_math_test.mbt:10](../../std_math_test.mbt#L10) |
| `count` | D: `std.count(arr, x)` | S: `std.count(arr, x)` | U/U/U/U | [array_std_test.mbt:22](../../array_std_test.mbt#L22) |
| `decodeUTF8` | D: `std.decodeUTF8(arr)` | Native/not defined in std.jsonnet | U/U/U/U | [std_encoding_test.mbt:9](../../std_encoding_test.mbt#L9) |
| `deepJoin` | D: `std.deepJoin(arr)` | S: `std.deepJoin(arr)` | U/U/U/U | [array_std_test.mbt:27](../../array_std_test.mbt#L27) |
| `deg2rad` | I: `std.deg2rad(x)` | S: `std.deg2rad(x)` | U/U/U/U | [std_math_test.mbt:14](../../std_math_test.mbt#L14) |
| `encodeUTF8` | D: `std.encodeUTF8(str)` | Native/not defined in std.jsonnet | U/U/U/U | [std_encoding_test.mbt:6](../../std_encoding_test.mbt#L6) |
| `endsWith` | D: `std.endsWith(a, b)` | S: `std.endsWith(a, b)` | R/R/R/R | [spec_string_calls_test.mbt:21](../../spec_string_calls_test.mbt#L21); [spec_string_sequence_test.mbt:75](../../spec_string_sequence_test.mbt#L75) |
| `equals` | Not listed | S: `std.equals(a, b)` | U/U/U/U | [object_std_test.mbt:48](../../object_std_test.mbt#L48) |
| `equalsIgnoreCase` | D: `std.equalsIgnoreCase(str1, str2)` | S: `std.equalsIgnoreCase(str1, str2)` | U/U/U/U | [std_string_test.mbt:26](../../std_string_test.mbt#L26) |
| `escapeStringBash` | D: `std.escapeStringBash(str)` | S: `std.escapeStringBash(str_)` | U/U/U/U | [std_string_test.mbt:34](../../std_string_test.mbt#L34) |
| `escapeStringDollars` | D: `std.escapeStringDollars(str)` | S: `std.escapeStringDollars(str_)` | U/U/U/U | [std_string_test.mbt:34](../../std_string_test.mbt#L34) |
| `escapeStringJson` | D: `std.escapeStringJson(str)` | S: `std.escapeStringJson(str_)` | U/U/U/U | [std_string_test.mbt:34](../../std_string_test.mbt#L34) |
| `escapeStringPython` | D: `std.escapeStringPython(str)` | S: `std.escapeStringPython(str)` | U/U/U/U | [std_string_test.mbt:34](../../std_string_test.mbt#L34) |
| `escapeStringXML` | Not listed | S: `std.escapeStringXML(str_)` | U/U/U/U | [std_string_test.mbt:34](../../std_string_test.mbt#L34) |
| `escapeStringXml` | D: `std.escapeStringXml(str)` | Native/not defined in std.jsonnet | U/U/U/U | No direct test reference found |
| `exp` | I: `std.exp(x)` | Native/not defined in std.jsonnet | U/U/U/U | [std_math_test.mbt:10](../../std_math_test.mbt#L10) |
| `exponent` | I: `std.exponent(x)` | Native/not defined in std.jsonnet | U/U/U/U | [std_math_test.mbt:34](../../std_math_test.mbt#L34) |
| `extVar` | D: `std.extVar(x)` | Native/not defined in std.jsonnet | U/U/U/U | [anonymous_test.mbt:7](../../anonymous_test.mbt#L7); [ast_test.mbt:62](../../ast_test.mbt#L62); [debugger_test.mbt:101](../../debugger_test.mbt#L101) |
| `filter` | D: `std.filter(func, arr)` | Native/not defined in std.jsonnet | R/R/R/R | [remove_test.mbt:17](../../remove_test.mbt#L17); [spec_foundation_arrays_test.mbt:109](../../spec_foundation_arrays_test.mbt#L109); [spec_foundation_calls_test.mbt:6](../../spec_foundation_calls_test.mbt#L6) |
| `filterMap` | D: `std.filterMap(filter_func, map_func, arr)` | S: `std.filterMap(filter_func, map_func, arr)` | U/U/U/U | [array_std_test.mbt:18](../../array_std_test.mbt#L18) |
| `find` | D: `std.find(value, arr)` | S: `std.find(value, arr)` | U/U/U/U | [array_std_test.mbt:26](../../array_std_test.mbt#L26) |
| `findSubstr` | D: `std.findSubstr(pat, str)` | S: `std.findSubstr(pat, str)` | R/R/R/R | [spec_string_calls_test.mbt:21](../../spec_string_calls_test.mbt#L21); [spec_string_sequence_test.mbt:38](../../spec_string_sequence_test.mbt#L38); [std_string_test.mbt:14](../../std_string_test.mbt#L14) |
| `flatMap` | D: `std.flatMap(func, arr)` | S: `std.flatMap(func, arr)` | R/R/R/R | [sequence_combine_test.mbt:4](../../sequence_combine_test.mbt#L4); [spec_array_flatmap_test.mbt:5](../../spec_array_flatmap_test.mbt#L5); [spec_array_slice_test.mbt:62](../../spec_array_slice_test.mbt#L62) |
| `flattenArrays` | D: `std.flattenArrays(arr)` | S: `std.flattenArrays(arrs)` | R/R/R/R | [array_std_test.mbt:11](../../array_std_test.mbt#L11); [spec_flatten_test.mbt:4](../../spec_flatten_test.mbt#L4) |
| `flattenDeepArray` | D: `std.flattenDeepArray(value)` | S: `std.flattenDeepArray(value)` | R/R/R/R | [array_std_test.mbt:14](../../array_std_test.mbt#L14); [spec_flatten_test.mbt:31](../../spec_flatten_test.mbt#L31) |
| `floor` | I: `std.floor(x)` | Native/not defined in std.jsonnet | R/R/R/R | [spec_math_rounding_test.mbt:35](../../spec_math_rounding_test.mbt#L35) |
| `foldl` | D: `std.foldl(func, arr, init)` | S: `std.foldl(func, arr, init)` | R/R/R/R | [moonjsonnet_test.mbt:118](../../moonjsonnet_test.mbt#L118); [spec_array_fold_test.mbt:5](../../spec_array_fold_test.mbt#L5); [spec_array_slice_test.mbt:61](../../spec_array_slice_test.mbt#L61) |
| `foldr` | D: `std.foldr(func, arr, init)` | S: `std.foldr(func, arr, init)` | R/R/R/R | [sequence_combine_test.mbt:35](../../sequence_combine_test.mbt#L35); [spec_array_fold_test.mbt:5](../../spec_array_fold_test.mbt#L5); [spec_array_slice_test.mbt:61](../../spec_array_slice_test.mbt#L61) |
| `format` | D: `std.format(str, vals)` | S: `std.format(str, vals)` | U/U/U/U | [standard_native_diagnostics_test.mbt:41](../../standard_native_diagnostics_test.mbt#L41) |
| `get` | D: `std.get(o, f, default=null, inc_hidden=true)` | S: `std.get(o, f, default=null, inc_hidden=true)` | R/R/R/R | [object_std_test.mbt:10](../../object_std_test.mbt#L10); [spec_length_test.mbt:23](../../spec_length_test.mbt#L23); [spec_object_calls_test.mbt:15](../../spec_object_calls_test.mbt#L15) |
| `hypot` | I: `std.hypot(a, b)` | Native/not defined in std.jsonnet | U/U/U/U | [spec_review_test.mbt:8](../../spec_review_test.mbt#L8); [std_math_test.mbt:6](../../std_math_test.mbt#L6) |
| `isArray` | I: `std.isArray(v)` | S: `std.isArray(v)` | U/U/U/U | No direct test reference found |
| `isBoolean` | I: `std.isBoolean(v)` | S: `std.isBoolean(v)` | U/U/U/U | No direct test reference found |
| `isDecimal` | I: `std.isDecimal(x)` | S: `std.isDecimal(x)` | U/U/U/U | [std_math_test.mbt:22](../../std_math_test.mbt#L22) |
| `isEmpty` | D: `std.isEmpty(str)` | S: `std.isEmpty(str)` | U/U/U/U | [std_string_test.mbt:30](../../std_string_test.mbt#L30) |
| `isEven` | I: `std.isEven(x)` | S: `std.isEven(x)` | U/U/U/U | [std_math_test.mbt:22](../../std_math_test.mbt#L22) |
| `isFunction` | I: `std.isFunction(v)` | S: `std.isFunction(v)` | U/U/U/U | [native_test.mbt:57](../../native_test.mbt#L57) |
| `isInteger` | I: `std.isInteger(x)` | S: `std.isInteger(x)` | U/U/U/U | [std_math_test.mbt:22](../../std_math_test.mbt#L22) |
| `isNumber` | I: `std.isNumber(v)` | S: `std.isNumber(v)` | R/R/R/R | [spec_foundation_calls_test.mbt:5](../../spec_foundation_calls_test.mbt#L5); [spec_foundation_numbers_test.mbt:78](../../spec_foundation_numbers_test.mbt#L78); [spec_foundation_types_test.mbt:15](../../spec_foundation_types_test.mbt#L15) |
| `isObject` | I: `std.isObject(v)` | S: `std.isObject(v)` | U/U/U/U | No direct test reference found |
| `isOdd` | I: `std.isOdd(x)` | S: `std.isOdd(x)` | U/U/U/U | [std_math_test.mbt:22](../../std_math_test.mbt#L22) |
| `isString` | I: `std.isString(v)` | S: `std.isString(v)` | U/U/U/U | [standard_native_diagnostics_test.mbt:36](../../standard_native_diagnostics_test.mbt#L36) |
| `join` | D: `std.join(sep, arr)` | S: `std.join(sep, arr)` | R/R/R/R | [spec_join_test.mbt:9](../../spec_join_test.mbt#L9) |
| `length` | D: `std.length(x)` | Native/not defined in std.jsonnet | R/R/R/R | [aggregate_test.mbt:10](../../aggregate_test.mbt#L10); [arguments_test.mbt:4](../../arguments_test.mbt#L4); [array_std_test.mbt:25](../../array_std_test.mbt#L25) |
| `lines` | D: `std.lines(arr)` | S: `std.lines(arr)` | U/U/U/U | No direct test reference found |
| `log` | I: `std.log(x)` | Native/not defined in std.jsonnet | U/U/U/U | [std_math_test.mbt:10](../../std_math_test.mbt#L10) |
| `log10` | I: `std.log10(x)` | S: `std.log10(x)` | U/U/U/U | [std_math_test.mbt:14](../../std_math_test.mbt#L14) |
| `log2` | I: `std.log2(x)` | S: `std.log2(x)` | U/U/U/U | [std_math_test.mbt:14](../../std_math_test.mbt#L14) |
| `lstripChars` | D: `std.lstripChars(str, chars)` | S: `std.lstripChars(str, chars)` | U/U/U/U | [std_string_test.mbt:10](../../std_string_test.mbt#L10) |
| `makeArray` | D: `std.makeArray(sz, func)` | Native/not defined in std.jsonnet | R/R/R/R | [aggregate_test.mbt:29](../../aggregate_test.mbt#L29); [array_std_test.mbt:59](../../array_std_test.mbt#L59); [error_value_test.mbt:80](../../error_value_test.mbt#L80) |
| `manifestIni` | D: `std.manifestIni(ini)` | S: `std.manifestIni(ini)` | U/U/U/U | [std_manifest_test.mbt:33](../../std_manifest_test.mbt#L33) |
| `manifestJson` | D: `std.manifestJson(value)` | S: `std.manifestJson(value)` | R/R/R/R | [moonjsonnet_test.mbt:152](../../moonjsonnet_test.mbt#L152); [native_test.mbt:102](../../native_test.mbt#L102); [render_test.mbt:19](../../render_test.mbt#L19) |
| `manifestJsonEx` | D: `std.manifestJsonEx(value, indent, newline, key_val_sep)` | S: `std.manifestJsonEx(value, indent, newline='\n', key_val_sep=': ')` | R/R/R/R | [arguments_test.mbt:6](../../arguments_test.mbt#L6); [spec_length_test.mbt:23](../../spec_length_test.mbt#L23); [standard_native_diagnostics_test.mbt:15](../../standard_native_diagnostics_test.mbt#L15) |
| `manifestJsonMinified` | D: `std.manifestJsonMinified(value)` | S: `std.manifestJsonMinified(value)` | R/R/R/R | [std_manifest_test.mbt:12](../../std_manifest_test.mbt#L12); [spec_json_contracts_test.mbt:168](../../spec_json_contracts_test.mbt#L168) |
| `manifestPython` | D: `std.manifestPython(v)` | S: `std.manifestPython(v)` | U/U/U/U | [std_manifest_test.mbt:28](../../std_manifest_test.mbt#L28) |
| `manifestPythonVars` | D: `std.manifestPythonVars(conf)` | S: `std.manifestPythonVars(conf)` | U/U/U/U | [std_manifest_test.mbt:30](../../std_manifest_test.mbt#L30) |
| `manifestToml` | Not listed | S: `std.manifestToml(value)` | U/U/U/U | [standard_native_diagnostics_test.mbt:18](../../standard_native_diagnostics_test.mbt#L18); [toml_yaml_test.mbt:5](../../toml_yaml_test.mbt#L5) |
| `manifestTomlEx` | D: `std.manifestTomlEx(toml, indent)` | S: `std.manifestTomlEx(value, indent)` | U/U/U/U | [toml_yaml_test.mbt:42](../../toml_yaml_test.mbt#L42) |
| `manifestXmlJsonml` | D: `std.manifestXmlJsonml(value)` | S: `std.manifestXmlJsonml(value)` | U/U/U/U | [std_manifest_test.mbt:37](../../std_manifest_test.mbt#L37) |
| `manifestYamlDoc` | D: `std.manifestYamlDoc(value, indent_array_in_object=false, quote_keys=true)` | S: `std.manifestYamlDoc(value, indent_array_in_object=false, quote_keys=true)` | U/R/R/U | [spec_aggregate_test.mbt:49](../../spec_aggregate_test.mbt#L49); [spec_length_test.mbt:23](../../spec_length_test.mbt#L23); [spec_review_test.mbt:104](../../spec_review_test.mbt#L104) |
| `manifestYamlStream` | D: `std.manifestYamlStream(value, indent_array_in_object=false, c_document_end=false, quote_keys=true)` | S: `std.manifestYamlStream(value, indent_array_in_object=false, c_document_end=true, quote_keys=true)` | U/R/U/U | [spec_length_test.mbt:23](../../spec_length_test.mbt#L23); [spec_yaml_test.mbt:10](../../spec_yaml_test.mbt#L10); [toml_yaml_test.mbt:32](../../toml_yaml_test.mbt#L32) |
| `mantissa` | I: `std.mantissa(x)` | Native/not defined in std.jsonnet | U/U/U/U | [std_math_test.mbt:30](../../std_math_test.mbt#L30) |
| `map` | D: `std.map(func, arr)` | S: `std.map(func, arr)` | R/R/R/R | [error_value_test.mbt:80](../../error_value_test.mbt#L80); [moonjsonnet_test.mbt:18](../../moonjsonnet_test.mbt#L18); [native_test.mbt:56](../../native_test.mbt#L56) |
| `mapWithIndex` | D: `std.mapWithIndex(func, arr)` | S: `std.mapWithIndex(func, arr)` | U/U/U/U | [sequence_test.mbt:22](../../sequence_test.mbt#L22) |
| `mapWithKey` | D: `std.mapWithKey(func, obj)` | S: `std.mapWithKey(func, obj)` | U/U/U/U | [object_std_test.mbt:25](../../object_std_test.mbt#L25) |
| `max` | I: `std.max(a, b)` | S: `std.max(a, b)` | R/R/R/R | [array_std_test.mbt:29](../../array_std_test.mbt#L29); [spec_foundation_calls_test.mbt:5](../../spec_foundation_calls_test.mbt#L5); [spec_foundation_numbers_test.mbt:35](../../spec_foundation_numbers_test.mbt#L35) |
| `maxArray` | D: `std.maxArray(arr, keyF, onEmpty)` | S: `std.maxArray(arr, keyF=id, onEmpty=error 'Expected at least one element in array. Got none')` | U/U/U/U | [extrema_test.mbt:5](../../extrema_test.mbt#L5); [spec_length_test.mbt:23](../../spec_length_test.mbt#L23); [standard_native_diagnostics_test.mbt:13](../../standard_native_diagnostics_test.mbt#L13) |
| `md5` | D: `std.md5(s)` | Native/not defined in std.jsonnet | U/U/U/U | [digest_test.mbt:38](../../digest_test.mbt#L38) |
| `member` | D: `std.member(arr, x)` | S: `std.member(arr, x)` | U/U/U/U | [extrema_test.mbt:50](../../extrema_test.mbt#L50) |
| `mergePatch` | D: `std.mergePatch(target, patch)` | S: `std.mergePatch(target, patch)` | R/R/R/R | [sets_test.mbt:16](../../sets_test.mbt#L16); [spec_merge_patch_test.mbt:21](../../spec_merge_patch_test.mbt#L21) |
| `min` | I: `std.min(a, b)` | S: `std.min(a, b)` | R/R/R/R | [array_std_test.mbt:29](../../array_std_test.mbt#L29); [spec_foundation_calls_test.mbt:5](../../spec_foundation_calls_test.mbt#L5); [spec_foundation_numbers_test.mbt:25](../../spec_foundation_numbers_test.mbt#L25) |
| `minArray` | D: `std.minArray(arr, keyF, onEmpty)` | S: `std.minArray(arr, keyF=id, onEmpty=error 'Expected at least one element in array. Got none')` | U/U/U/U | [extrema_test.mbt:5](../../extrema_test.mbt#L5); [spec_length_test.mbt:23](../../spec_length_test.mbt#L23) |
| `mod` | I: `std.mod(a, b)` | S: `std.mod(a, b)` | U/U/U/U | [std_math_test.mbt:6](../../std_math_test.mbt#L6) |
| `modulo` | Not listed | F: `std.modulo(a, b)` | U/U/U/U | [std_math_test.mbt:6](../../std_math_test.mbt#L6) |
| `native` | Not listed | F: `std.native(x)` | U/U/U/U | [evaluator_import_ast_test.mbt:83](../../evaluator_import_ast_test.mbt#L83); [evaluator_imports_test.mbt:20](../../evaluator_imports_test.mbt#L20); [evaluator_test.mbt:6](../../evaluator_test.mbt#L6) |
| `objectFields` | D: `std.objectFields(o)` | S: `std.objectFields(o)` | R/R/R/R | [spec_object_calls_test.mbt:14](../../spec_object_calls_test.mbt#L14); [spec_object_get_test.mbt:104](../../spec_object_get_test.mbt#L104); [spec_object_reflection_test.mbt:5](../../spec_object_reflection_test.mbt#L5) |
| `objectFieldsAll` | D: `std.objectFieldsAll(o)` | S: `std.objectFieldsAll(o)` | R/R/R/R | [object_std_test.mbt:94](../../object_std_test.mbt#L94); [remove_test.mbt:69](../../remove_test.mbt#L69); [spec_object_calls_test.mbt:14](../../spec_object_calls_test.mbt#L14) |
| `objectFieldsEx` | Not listed | F: `parameter names not specified by formal rule` | U/U/U/U | [object_std_test.mbt:6](../../object_std_test.mbt#L6) |
| `objectHas` | D: `std.objectHas(o, f)` | S: `std.objectHas(o, f)` | R/R/R/R | [aggregate_test.mbt:10](../../aggregate_test.mbt#L10); [extrema_test.mbt:21](../../extrema_test.mbt#L21); [sequence_combine_test.mbt:84](../../sequence_combine_test.mbt#L84) |
| `objectHasAll` | D: `std.objectHasAll(o, f)` | S: `std.objectHasAll(o, f)` | R/R/R/R | [sequence_combine_test.mbt:84](../../sequence_combine_test.mbt#L84); [sequence_test.mbt:76](../../sequence_test.mbt#L76); [sets_test.mbt:37](../../sets_test.mbt#L37) |
| `objectHasEx` | Not listed | F: `parameter names not specified by formal rule` | U/U/U/U | [object_std_test.mbt:6](../../object_std_test.mbt#L6) |
| `objectKeysValues` | D: `std.objectKeysValues(o)` | S: `std.objectKeysValues(o)` | U/U/U/U | [object_std_test.mbt:16](../../object_std_test.mbt#L16) |
| `objectKeysValuesAll` | D: `std.objectKeysValuesAll(o)` | S: `std.objectKeysValuesAll(o)` | U/U/U/U | [object_std_test.mbt:19](../../object_std_test.mbt#L19) |
| `objectRemoveKey` | D: `std.objectRemoveKey(obj, key)` | S: `std.objectRemoveKey(obj, key)` | U/U/U/U | [object_std_test.mbt:23](../../object_std_test.mbt#L23) |
| `objectValues` | D: `std.objectValues(o)` | S: `std.objectValues(o)` | R/R/R/R | [object_std_test.mbt:13](../../object_std_test.mbt#L13); [spec_object_calls_test.mbt:15](../../spec_object_calls_test.mbt#L15); [spec_object_get_test.mbt:104](../../spec_object_get_test.mbt#L104) |
| `objectValuesAll` | D: `std.objectValuesAll(o)` | S: `std.objectValuesAll(o)` | U/U/U/U | [object_std_test.mbt:14](../../object_std_test.mbt#L14) |
| `parseHex` | D: `std.parseHex(str)` | S: `std.parseHex(str)` | R/R/R/R | [std_string_test.mbt:22](../../std_string_test.mbt#L22); [spec_integer_parsers_test.mbt:38](../../spec_integer_parsers_test.mbt#L38) |
| `parseInt` | D: `std.parseInt(str)` | S: `std.parseInt(str)` | R/R/R/R | [std_string_test.mbt:22](../../std_string_test.mbt#L22); [spec_integer_parsers_test.mbt:38](../../spec_integer_parsers_test.mbt#L38) |
| `parseJson` | D: `std.parseJson(str)` | Native/not defined in std.jsonnet | R/R/R/R | [json_yaml_diagnostic_test.mbt:14](../../json_yaml_diagnostic_test.mbt#L14); [spec_review_test.mbt:8](../../spec_review_test.mbt#L8); [spec_string_concat_test.mbt:19](../../spec_string_concat_test.mbt#L19) |
| `parseOctal` | D: `std.parseOctal(str)` | S: `std.parseOctal(str)` | R/R/R/R | [std_string_test.mbt:22](../../std_string_test.mbt#L22); [spec_integer_parsers_test.mbt:38](../../spec_integer_parsers_test.mbt#L38) |
| `parseYaml` | D: `std.parseYaml(str)` | Native/not defined in std.jsonnet | U/U/U/U | [json_yaml_diagnostic_test.mbt:38](../../json_yaml_diagnostic_test.mbt#L38); [parse_yaml_test.mbt:7](../../parse_yaml_test.mbt#L7); [spec_review_test.mbt:9](../../spec_review_test.mbt#L9) |
| `pow` | I: `std.pow(x, n)` | Native/not defined in std.jsonnet | R/R/R/R | [spec_foundation_calls_test.mbt:6](../../spec_foundation_calls_test.mbt#L6); [spec_foundation_numbers_test.mbt:45](../../spec_foundation_numbers_test.mbt#L45); [spec_review_test.mbt:7](../../spec_review_test.mbt#L7) |
| `primitiveEquals` | Not listed | F: `parameter names not specified by formal rule` | U/U/U/U | [object_std_test.mbt:59](../../object_std_test.mbt#L59); [spec_primitive_equals_test.mbt:170](../../spec_primitive_equals_test.mbt#L170) |
| `prune` | D: `std.prune(a)` | S: `std.prune(a)` | R/R/R/R | [object_std_test.mbt:29](../../object_std_test.mbt#L29); [spec_prune_test.mbt:9](../../spec_prune_test.mbt#L9) |
| `rad2deg` | I: `std.rad2deg(x)` | S: `std.rad2deg(x)` | U/U/U/U | [std_math_test.mbt:14](../../std_math_test.mbt#L14) |
| `range` | D: `std.range(from, to)` | S: `std.range(from, to)` | R/R/R/R | [aggregate_test.mbt:12](../../aggregate_test.mbt#L12); [lint_type_test.mbt:108](../../lint_type_test.mbt#L108); [moonjsonnet_test.mbt:90](../../moonjsonnet_test.mbt#L90) |
| `remove` | D: `std.remove(arr, elem)` | S: `std.remove(arr, elem)` | R/U/R/R | [remove_test.mbt:5](../../remove_test.mbt#L5); [spec_aggregate_test.mbt:44](../../spec_aggregate_test.mbt#L44); [spec_remove_test.mbt:12](../../spec_remove_test.mbt#L12) |
| `removeAt` | D: `std.removeAt(arr, idx)` | S: `std.removeAt(arr, at)` | R/U/R/R | [program_parameters_test.mbt:181](../../program_parameters_test.mbt#L181); [program_test.mbt:187](../../program_test.mbt#L187); [remove_test.mbt:7](../../remove_test.mbt#L7) |
| `repeat` | D: `std.repeat(what, count)` | S: `std.repeat(what, count)` | U/U/U/U | [array_std_test.mbt:23](../../array_std_test.mbt#L23); [toml_yaml_test.mbt:54](../../toml_yaml_test.mbt#L54) |
| `resolvePath` | Not listed | S: `std.resolvePath(f, r)` | U/U/U/U | [std_string_test.mbt:38](../../std_string_test.mbt#L38) |
| `reverse` | D: `std.reverse(arrs)` | S: `std.reverse(arr)` | U/U/U/U | [sequence_test.mbt:40](../../sequence_test.mbt#L40); [sort_test.mbt:72](../../sort_test.mbt#L72) |
| `round` | I: `std.round(x)` | S: `std.round(x)` | U/U/U/U | [std_math_test.mbt:26](../../std_math_test.mbt#L26) |
| `rstripChars` | D: `std.rstripChars(str, chars)` | S: `std.rstripChars(str, chars)` | U/U/U/U | [std_string_test.mbt:10](../../std_string_test.mbt#L10) |
| `set` | D: `std.set(arr, keyF=id)` | S: `std.set(arr, keyF=id)` | U/U/U/U | [sets_test.mbt:7](../../sets_test.mbt#L7) |
| `setDiff` | D: `std.setDiff(a, b, keyF=id)` | S: `std.setDiff(a, b, keyF=id)` | U/U/U/U | [sets_test.mbt:10](../../sets_test.mbt#L10) |
| `setInter` | D: `std.setInter(a, b, keyF=id)` | S: `std.setInter(a, b, keyF=id)` | U/U/U/U | [sets_test.mbt:9](../../sets_test.mbt#L9) |
| `setMember` | D: `std.setMember(x, arr, keyF=id)` | S: `std.setMember(x, arr, keyF=id)` | U/U/U/U | [sets_test.mbt:11](../../sets_test.mbt#L11) |
| `setUnion` | D: `std.setUnion(a, b, keyF=id)` | S: `std.setUnion(a, b, keyF=id)` | U/U/U/U | [sets_test.mbt:8](../../sets_test.mbt#L8) |
| `sha1` | D: `std.sha1(s)` | S: `std.sha1(str)` | U/U/U/U | [digest_test.mbt:40](../../digest_test.mbt#L40) |
| `sha256` | D: `std.sha256(s)` | S: `std.sha256(str)` | U/U/U/U | [sha256_test.mbt:25](../../sha256_test.mbt#L25) |
| `sha3` | D: `std.sha3(s)` | S: `std.sha3(str)` | U/U/U/U | [digest_test.mbt:49](../../digest_test.mbt#L49) |
| `sha512` | D: `std.sha512(s)` | S: `std.sha512(str)` | U/U/U/U | [digest_test.mbt:31](../../digest_test.mbt#L31) |
| `sign` | I: `std.sign(n)` | S: `std.sign(n)` | R/R/R/R | [spec_foundation_calls_test.mbt:5](../../spec_foundation_calls_test.mbt#L5); [spec_foundation_numbers_test.mbt:15](../../spec_foundation_numbers_test.mbt#L15); [std_math_test.mbt:14](../../std_math_test.mbt#L14) |
| `sin` | I: `std.sin(x)` | Native/not defined in std.jsonnet | U/U/U/U | [std_math_test.mbt:10](../../std_math_test.mbt#L10) |
| `slice` | D: `std.slice(indexable, index, end, step)` | S: `std.slice(indexable, index, end, step)` | R/R/R/R | [numeric_test.mbt:26](../../numeric_test.mbt#L26); [spec_array_slice_test.mbt:5](../../spec_array_slice_test.mbt#L5); [spec_index_test.mbt:32](../../spec_index_test.mbt#L32) |
| `sort` | D: `std.sort(arr, keyF=id)` | S: `std.sort(arr, keyF=id)` | U/U/U/U | [arguments_test.mbt:7](../../arguments_test.mbt#L7); [sort_test.mbt:4](../../sort_test.mbt#L4); [spec_length_test.mbt:23](../../spec_length_test.mbt#L23) |
| `split` | D: `std.split(str, c)` | S: `std.split(str, c)` | U/U/U/U | [standard_native_diagnostics_test.mbt:36](../../standard_native_diagnostics_test.mbt#L36) |
| `splitLimit` | D: `std.splitLimit(str, c, maxsplits)` | S: `std.splitLimit(str, c, maxsplits)` | U/U/U/U | [std_string_test.mbt:18](../../std_string_test.mbt#L18) |
| `splitLimitR` | D: `std.splitLimitR(str, c, maxsplits)` | S: `std.splitLimitR(str, c, maxsplits)` | U/U/U/U | [std_string_test.mbt:18](../../std_string_test.mbt#L18) |
| `sqrt` | I: `std.sqrt(x)` | Native/not defined in std.jsonnet | U/U/U/U | [std_math_test.mbt:6](../../std_math_test.mbt#L6) |
| `startsWith` | D: `std.startsWith(a, b)` | S: `std.startsWith(a, b)` | R/R/R/R | [spec_string_calls_test.mbt:21](../../spec_string_calls_test.mbt#L21); [spec_string_sequence_test.mbt:75](../../spec_string_sequence_test.mbt#L75) |
| `strReplace` | D: `std.strReplace(str, from, to)` | S: `std.strReplace(str, from, to)` | U/U/U/U | No direct test reference found |
| `stringChars` | D: `std.stringChars(str)` | S: `std.stringChars(str)` | R/R/R/R | [lint_type_test.mbt:114](../../lint_type_test.mbt#L114); [spec_string_calls_test.mbt:21](../../spec_string_calls_test.mbt#L21); [spec_string_sequence_test.mbt:5](../../spec_string_sequence_test.mbt#L5) |
| `stripChars` | D: `std.stripChars(str, chars)` | S: `std.stripChars(str, chars)` | U/U/U/U | [std_string_test.mbt:10](../../std_string_test.mbt#L10) |
| `substr` | D: `std.substr(str, from, len)` | S: `std.substr(str, from, len)` | R/R/R/R | [arguments_test.mbt:5](../../arguments_test.mbt#L5); [moonjsonnet_test.mbt:20](../../moonjsonnet_test.mbt#L20); [spec_string_calls_test.mbt:21](../../spec_string_calls_test.mbt#L21) |
| `sum` | D: `std.sum(arr)` | S: `std.sum(arr)` | R/R/R/R | [aggregate_test.mbt:6](../../aggregate_test.mbt#L6); [output_test.mbt:11](../../output_test.mbt#L11); [spec_aggregate_test.mbt:9](../../spec_aggregate_test.mbt#L9) |
| `tan` | I: `std.tan(x)` | Native/not defined in std.jsonnet | U/U/U/U | [std_math_test.mbt:10](../../std_math_test.mbt#L10) |
| `toString` | D: `std.toString(a)` | S: `std.toString(a)` | U/U/U/U | [aggregate_test.mbt:46](../../aggregate_test.mbt#L46); [debugger_test.mbt:159](../../debugger_test.mbt#L159); [moonjsonnet_test.mbt:105](../../moonjsonnet_test.mbt#L105) |
| `trace` | D: `std.trace(str, rest)` | Native/not defined in std.jsonnet | U/U/U/U | [anonymous_test.mbt:7](../../anonymous_test.mbt#L7); [evaluator_import_ast_test.mbt:83](../../evaluator_import_ast_test.mbt#L83); [evaluator_imports_test.mbt:20](../../evaluator_imports_test.mbt#L20) |
| `trim` | D: `std.trim(str)` | S: `std.trim(str)` | U/U/U/U | [std_string_test.mbt:30](../../std_string_test.mbt#L30) |
| `type` | D: `std.type(x)` | Native/not defined in std.jsonnet | R/R/R/R | [aggregate_test.mbt:46](../../aggregate_test.mbt#L46); [native_test.mbt:57](../../native_test.mbt#L57); [spec_aggregate_test.mbt:10](../../spec_aggregate_test.mbt#L10) |
| `uniq` | D: `std.uniq(arr, keyF=id)` | S: `std.uniq(arr, keyF=id)` | U/U/U/U | [sets_test.mbt:5](../../sets_test.mbt#L5) |
| `xnor` | D: `std.xnor(x, y)` | S: `std.xnor(x, y)` | U/U/U/U | [std_math_test.mbt:18](../../std_math_test.mbt#L18) |
| `xor` | D: `std.xor(x, y)` | S: `std.xor(x, y)` | U/U/U/U | [std_math_test.mbt:18](../../std_math_test.mbt#L18) |
