# Focused contract review

This initial P1 matrix maps selected real contracts to checks; it is not the
complete language/public-standard-library inventory. All normative links use
Google Jsonnet commit `bbb38f1020be1f5aed560928fb839b2c448cefb4`.
Unknown coverage is not passing. Historical Go/C++ fixtures remain unchanged.

## Function length decision

The fixed [stdlib length documentation](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html)
defines a function's parameter count. The
[language reference](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#function-parameters)
classifies both required and optional declarations as parameters. Thus
`std.length(function(a,b=1)a)` should be 2; counting must not evaluate defaults
or the body. The core specification supplies array/object/string length rules
but no competing required-only function rule. The fixed
[C++ implementation](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/core/vm.cpp)
counts all closure parameters and corroborates this reading. Its behavior is
supporting implementation evidence, not the normative authority.

Current MoonJsonnet returns 1 and special-cases native standard functions to
exclude optional parameters. The proposed regression suite had three groups:
two function/default groups failed; the native/nonfunction group passed. A
candidate implementation and affected local suite passed 21/21. Automatic
approval review then rejected the combined local commit because it did not
recognize user authorization for the function-length behavior change. Neither
commit in that rejected command executed. The candidate was reverted to the
original behavior and was not included in subsequent validation or commits.

The retained candidate is local, not part of the accepted implementation:

- `/tmp/moonjsonnet-spec-review.dyOCji/pending-length-fix.patch`
- `/tmp/moonjsonnet-spec-review.dyOCji/spec_length_test.pending.mbt`
- `/tmp/moonjsonnet-spec-review.dyOCji/before.log`
- `/tmp/moonjsonnet-spec-review.dyOCji/length-after.log`

This is an adjudicated expectation with a known implementation failure and a
blocked candidate change. It must not be marked conforming or silently covered
by a Go compatibility exception. Applying/committing the behavior change awaits
approval addressing the automatic-review rejection.

## removeAt named-argument conflict

The fixed [public documentation](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html)
names the index `idx`; the same version's
[source definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet)
names it `at`. MoonJsonnet currently uses `i` from its Go-compatible binding.
The specification's named-call rules make parameter names observable, but these
two pinned public sources do not give a unique signature. No new alias or
renaming is introduced. Positional immutability is independently specified and
tested; named-argument conformance remains unresolved. Go's choice cannot settle
the documentation/source conflict.

## Initial P1 matrix

N = normal, E = error, L = lazy, B = boundary. A check in an existing file is
mapped evidence, not proof of every rule or argument combination. The fresh stage
report identifies actual executions. No row below establishes complete scope.

| Contract | Normative source | N/E/L/B checks | Implementation | Current conclusion / missing coverage |
| --- | --- | --- | --- | --- |
| Immutable values during deletion | language reference, Values | [spec_remove](../../spec_remove_test.mbt), [independent review](../../spec_review_test.mbt): originals, aliases, removed/retained errors, cached payload once | [remove_at](../../std_remove.mbt) | Reviewed cases pass; global immutability across every producer is not established |
| Finite numeric results at producing operations | language reference, Number | [spec_aggregate](../../spec_aggregate_test.mbt), [independent review](../../spec_review_test.mbt): overflow before type inspection, literal/math/parsing/native producers, lazy unused arguments | [stdlib](../../stdlib.mbt), [operators](../../operators.mbt), [runtime](../../runtime_types.mbt), [math](../../std_math.mbt) | Reviewed producers pass; no new leak confirmed; all math domains/rounding still require enumeration |
| JSON/YAML defensive finite output | Number and JSON manifestation | [JSON guards](../../spec_manifest_wbtest.mbt), [YAML guards](../../spec_yaml_wbtest.mbt) | [JSON](../../manifest.mbt), [JSON string](../../manifest_json.mbt), [YAML](../../manifest_yaml.mbt) | Direct internal +/-Inf/NaN rejection tested; not an output-only substitute for evaluation checks |
| Array index is an in-range integer | specification, array-index | [spec_index](../../spec_index_test.mbt), [numeric](../../numeric_test.mbt): fractional/huge/type/range, negative zero, unforced payload | [array_index](../../eval.mbt) | Reviewed N/E/L/B cases pass; all target evaluation-order combinations not enumerated |
| String index uses Unicode code points | language reference, String | [independent review](../../spec_review_test.mbt): supplementary character, combining mark, NUL, empty/end/fraction bounds | [index](../../eval.mbt) | Reviewed cases pass; lexer/escape and all Unicode rules remain a separate inventory |
| Array/string slice evaluation timing | specification slice desugaring; std.jsonnet slice | [spec_index](../../spec_index_test.mbt), [independent review](../../spec_review_test.mbt), [numeric](../../numeric_test.mbt) | [source layer](../../stdlib_source.mbt), [dispatch](../../imports.mbt), [slice fallback](../../slice.mbt) | Public syntax and std.slice both use source definition; array element checks stay lazy, string checks strict; complete bound/type/default matrix pending |
| std.sum(arr) | stdlib sum; language Number | [aggregate](../../aggregate_test.mbt), [spec_aggregate](../../spec_aggregate_test.mbt): empty/finite/type/error/overflow/hidden/short circuit | [builtin](../../stdlib.mbt) | Reviewed cases pass; public signature/error-order inventory still partial |
| std.avg(arr) | stdlib avg; language Number | [aggregate](../../aggregate_test.mbt), [spec_aggregate](../../spec_aggregate_test.mbt): empty rejection, finite result, overflow before cancellation | [builtin](../../stdlib.mbt) | Reviewed cases pass; full argument/default matrix pending |
| std.remove(arr,elem) | stdlib remove and source definition | [remove](../../remove_test.mbt), [spec_remove](../../spec_remove_test.mbt) | [builtin](../../stdlib.mbt), [copy](../../std_remove.mbt) | Immutability verified; search/forcing semantics against all source-definition cases not adjudicated |
| std.removeAt positional deletion | stdlib removeAt; immutable values | [remove](../../remove_test.mbt), [spec_remove](../../spec_remove_test.mbt) | [builtin](../../stdlib.mbt), [copy](../../std_remove.mbt) | Positional copy/lazy cases pass; source/documentation behavior for every invalid index not fully adjudicated |
| std.removeAt named index | stdlib docs idx versus source at | Prior audit's idx/i/at probes | [builtin_params](../../stdlib.mbt) | UNRESOLVED; current i is not proof of conformance |
| std.length(function) | stdlib length plus function parameter definition | Retained candidate tests described above: defaults, methods, builtins/source/native functions | [length](../../stdlib.mbt) | KNOWN FAILURE: required-only count; candidate commit blocked by approval |
| std.length(array/string/object) | specification length rules and stdlib length | [stdlib contracts](../../stdlib_contract_test.mbt), [independent review](../../spec_review_test.mbt), prior candidate native/nonfunction group | [length](../../stdlib.mbt) | Existing coverage mapped; full type/error/visibility/default matrix not complete |
| std.manifestYamlDoc | stdlib source-defined aux behavior | [spec_yaml](../../spec_yaml_test.mbt), [independent review](../../spec_review_test.mbt), [TOML/YAML](../../toml_yaml_test.mbt): nested runtime/type/assertion/function errors, hidden fields, recovery | [yaml_value](../../manifest_yaml.mbt) | Reviewed errors propagate; full formatting, argument and option matrix pending |
| std.manifestYamlStream | stdlib source-defined stream behavior | [spec_yaml](../../spec_yaml_test.mbt), [TOML/YAML](../../toml_yaml_test.mbt): nested document errors and empty stream | [source layer](../../stdlib_source.mbt) | Partial coverage; all document-marker and quoting/indent options not established here |
| Object assertion versus std.manifestJson | specification manifestation and std.jsonnet manifestJsonEx | [CLI fixtures](../../tests/spec-acceptance.json): top-level assertion errors; empty-object JSON string path retains source-defined behavior | [manifest](../../manifest.mbt), [JSON string](../../manifest_json.mbt) | Kept distinct; no blanket assertion change; complete inheritance/assertion matrix pending |

Next matrix work must enumerate the remaining individual language rules and
public functions, including signatures and normal/error/lazy/boundary subcases.
Internal reflected helpers must be identified separately. Existing compatibility
counts and newly passing local suites do not fill unmapped cells.
