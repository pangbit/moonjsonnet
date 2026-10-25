# Focused contract review

This initial P1 matrix maps selected real contracts to checks; it is not the
complete language/public-standard-library inventory. All normative links use
Google Jsonnet commit `bbb38f1020be1f5aed560928fb839b2c448cefb4`.
Unknown coverage is not passing. Historical Go/C++ fixtures remain unchanged.
The separate [official public inventory](SPEC-PUBLIC-STDLIB-REVIEW.md) now lists
fixed documentation/source/specification API candidates and maps each to reviewed
subsets or explicit unknown dimensions. It does not use registration as acceptance.
The [ten-function foundation evidence](SPEC-FOUNDATIONS-EVIDENCE-2026-10-22.md)
adds parameter/default and N/E/L/B assertions with actual range failures and a
minimal public-dispatch fix; it does not relabel older Go snapshots as reviewed.

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

Implemented in `2cee5de679c78c1ffbadc1e70e905d2228143938`: closure and builtin
lengths count all declared parameters. The four deterministic groups in
[spec_length_test.mbt](../../spec_length_test.mbt) cover defaults, methods,
source/builtin/native functions, unchanged call binding and lazy defaults/body.
Affected tests passed 24/24; full native debug and release each passed 345/345
before the subsequent P1 additions. The latest [P1 stage](SPEC-P1-EVIDENCE-2026-10-22.md)
records fresh same-source aggregate and CLI evidence.

The original three-group proposal failed two function/default groups. Automatic
approval review initially rejected the local behavior-change commit because it
did not recognize sufficient user authorization; those commands did not execute.
After the user's exact confirmation, one formal retry succeeded. The committed
eight-file candidate was checked against the already tested hashes without
rerunning unchanged inputs. The approval is resolved; no further approval for
this completed action is pending. Earlier failure/candidate evidence is retained:

- `/tmp/moonjsonnet-spec-review.dyOCji/pending-length-fix.patch`
- `/tmp/moonjsonnet-spec-review.dyOCji/spec_length_test.pending.mbt`
- `/tmp/moonjsonnet-spec-review.dyOCji/before.log`
- `/tmp/moonjsonnet-spec-review.dyOCji/length-after.log`

The final receipt is `/tmp/moonjsonnet-length.Fli1ZD/COMMITTED.txt`. Historical
reports and the rejected candidate records describe their original source and
must not be relabeled as passing current-source evidence.

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
| std.sort source-defined input/result/demand and language context | Fixed e_std/source body plus object/closure/private-library rules | [demand](../../spec_sort_demand_test.mbt), [contract](../../spec_sort_contract_test.mbt), [admission](../../spec_sort_admission_test.mbt), [existing object cases](../../spec_language_object_test.mbt), [context boundary](SPEC-SORT-DEMAND-2026-10-25.md#standard-receiver-composition-and-comparison-boundary) | [sort](../../sort.mbt), [source selection](../../stdlib_layer.mbt), [field evaluation](../../objects.mbt), [private binding](../../imports.mbt) | Receiver baseline2/2 preserved then4/4 plus44 neighbor cases passed. This repairs ordinary inherited field capture, not a sort hook API; literal comparison conflict remains in the existing global matrix |
| std.sum(arr) | stdlib sum; language Number | [aggregate](../../aggregate_test.mbt), [spec_aggregate](../../spec_aggregate_test.mbt): empty/finite/type/error/overflow/hidden/short circuit | [builtin](../../stdlib.mbt) | Reviewed cases pass; public signature/error-order inventory still partial |
| std.avg(arr) | stdlib avg; language Number | [aggregate](../../aggregate_test.mbt), [spec_aggregate](../../spec_aggregate_test.mbt): empty rejection, finite result, overflow before cancellation | [builtin](../../stdlib.mbt) | Reviewed cases pass; full argument/default matrix pending |
| std.objectRemoveKey(obj,key) projection | Fixed std.jsonnet1788-1792, visible objectFields and original obj[k] lookup | [eight independent groups](../../spec_object_remove_key_test.mbt), [raw failures and four legacy migrations](SPEC-OBJECT-REMOVE-KEY-2026-10-25.md) | [source routing](../../stdlib_layer.mbt), [unchanged embedded definition](../../stdlib_source.mbt) | Preserved2-pass/6-failure baseline; one-line source dispatch repair passes8/8 plus3 migrated legacy and29 neighboring groups. Original receiver/closure capture, visible projection and demand are scoped; the explicit boundary continuation passes10/10 without a product change, leaving only shared N0/R0 child questions; no unconditional whole function or general language completion |
| std.remove(arr,elem) | stdlib remove and source definition | [remove](../../remove_test.mbt), [spec_remove](../../spec_remove_test.mbt) | [builtin](../../stdlib.mbt), [copy](../../std_remove.mbt) | Immutability verified; search/forcing semantics against all source-definition cases not adjudicated |
| std.removeAt positional deletion | stdlib removeAt; immutable values | [remove](../../remove_test.mbt), [spec_remove](../../spec_remove_test.mbt) | [builtin](../../stdlib.mbt), [copy](../../std_remove.mbt) | Positional copy/lazy cases pass; source/documentation behavior for every invalid index not fully adjudicated |
| std.removeAt named index | stdlib docs idx versus source at | Prior audit's idx/i/at probes | [builtin_params](../../stdlib.mbt) | UNRESOLVED; current i is not proof of conformance |
| std.length(function) | stdlib length plus function parameter definition | [spec_length](../../spec_length_test.mbt): defaults, methods, builtins/source/native functions, call/default/body laziness | [length](../../stdlib.mbt) | Fixed in 2cee5de; reviewed N/E/L/B cases pass; no required-only exception |
| std.length(array/string/object) | specification length rules and stdlib length | [stdlib contracts](../../stdlib_contract_test.mbt), [independent review](../../spec_review_test.mbt), prior candidate native/nonfunction group | [length](../../stdlib.mbt) | Existing coverage mapped; full type/error/visibility/default matrix not complete |
| std.manifestYamlDoc | stdlib source-defined aux behavior | [spec_yaml](../../spec_yaml_test.mbt), [independent review](../../spec_review_test.mbt), [TOML/YAML](../../toml_yaml_test.mbt): nested runtime/type/assertion/function errors, hidden fields, recovery | [yaml_value](../../manifest_yaml.mbt) | Reviewed errors propagate; full formatting, argument and option matrix pending |
| std.manifestYamlStream | stdlib source-defined stream behavior | [spec_yaml](../../spec_yaml_test.mbt), [TOML/YAML](../../toml_yaml_test.mbt): nested document errors and empty stream | [source layer](../../stdlib_source.mbt) | Partial coverage; all document-marker and quoting/indent options not established here |
| Object assertion versus std.manifestJson | specification manifestation and std.jsonnet manifestJsonEx | [CLI fixtures](../../tests/spec-acceptance.json): top-level assertion errors; empty-object JSON string path retains source-defined behavior | [manifest](../../manifest.mbt), [JSON string](../../manifest_json.mbt) | Kept distinct; no blanket assertion change; complete inheritance/assertion matrix pending |
| Unique formal parameter names | specification, Static Checking, chk-function | [spec_static](../../spec_static_test.mbt), [parameter ranges](../../parameter_range_test.mbt): bare/unused-branch/local/method declarations, public AST, error location, valid nested shadowing and lazy defaults | [validate Func](../../validate.mbt) | Two baseline groups failed; fixed in 0887fce; source/from_ast reject with Static before invocation; raw parsing remains a separate syntax-only API |
| Empty text-block lines and preserved line endings | specification, Lexing | [spec_text_block](../../spec_text_block_test.mbt), [spec_text_chomp](../../spec_text_chomp_test.mbt): byte-exact leading/interior/consecutive CRLF, mixed endings, tab indent, LF/bare-CR controls, one complete final newline removed, retained-source/AST values | [lexer](../../lexer.mbt) | Empty-line fix b982065; chomp fix e59151f after three actual failing groups; reviewed cases pass; complete malformed/whitespace-only-line matrix remains untested |
| Imported source isolation and lazy loading | specification, Core Syntax | [spec_import_scope](../../spec_import_scope_test.mbt): caller free variable rejected in child; own binding succeeds; unused branch/argument/default/hidden/array-length does not resolve; forcing exposes child Syntax/Static and parent context | [imports](../../imports.mbt) | Coverage gap closed for these cases; all three groups already passed before implementation changes; no import implementation fix needed; complete importstr/importbin/cache/identity matrix not established |

Next matrix work must enumerate the remaining individual language rules and
public functions, including signatures and normal/error/lazy/boundary subcases.
Internal reflected helpers must be identified separately. Existing compatibility
counts and newly passing local suites do not fill unmapped cells.
