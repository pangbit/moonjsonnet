# Public JSON input and output contracts

## Frozen priority and oracle

Base 110e4036041ebb2956767bd04d02659bb8c9a8d7. This batch selects parseJson,
manifestJsonEx, manifestJson and manifestJsonMinified from the public inventory.
None has manually mapped dimensions yet. The repository's
[engineering requirements](zh-CN/REQUIREMENTS.md) require JSON processing for
configuration generation, dashboard data and embedded structured results; the
[current acceptance contract](SPEC-CONFORMANCE.md) requires errors and demand
timing for every public function. This cohesive input/output group therefore
has direct user impact beyond adding another language subdomain. No private
application document is read, quoted or added.

Official Jsonnet remains bbb38f1020be1f5aed560928fb839b2c448cefb4:
[parseJson](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#std-parseJson)
(stdlib.html 1268-1290) parses JSON String data; the
[manifest declarations](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#std-manifestJsonEx)
(1535-1690) specify the value/indent/newline/key_val_sep interface and wrappers.
The fixed [source](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1048-L1094)
defines default newline '\n', key separator ': ', manifestJson's four spaces
and minified empty indent/newline with ':'. Its aux branch determines demand:

- Scalar null/Boolean/Number/String output does not read formatting options.
- Empty Array/Object output uses newline twice, without indent or key separator.
- Nonempty arrays use indent/newline; key separator is needed only for actual
  visible object fields, including nested fields.
- Visible values are traversed, hidden values are omitted, Function values fail
  without invoking their bodies, and required errors cannot become success.

Expected JSON values and small exact layouts are written independently. Parsed
manifestation strings are compared with literal expected JSON using the host
JSON parser, never product parseJson output as another product call's oracle.
Source calls and independent Call/Obj/Arr/Function ASTs are separate entries.
JSON payload syntax errors occur on call demand as Runtime, not source Syntax;
nonnumeric/nonstring host error tags and missing/unknown bindings are embedding
checks, not a standardized human diagnostic format.

| Group | Independent required outcomes |
| --- | --- |
| JC1 | Valid scalar/empty/nested JSON String fixtures, Unicode and standard escapes yield literal JSON values through positional/named str calls and independent ASTs. |
| JC2 | Malformed JSON and wrong outer argument types reject without forcing unrelated container/function payloads. Required input errors and scalar nonfinite production propagate; unused whole calls stay lazy. |
| JC3 | The three output APIs preserve literal visible JSON data and hidden errors, with declared named/default options, four-space/default and minified/custom layouts. No general float spelling or source-tree round trip supplies the expected result. |
| JC4 | Visible nested errors, Functions and required format options fail; Function bodies stay uncalled. Missing/unknown interface bindings fail before provided native gates. Unknown value expressions remain statically invalid even when unused. |
| JC5 | Source Ex calls skip error-valued format options in scalar/empty/array-only branches, yielding declared literal Strings. |
| JC6 | Independently built AST Ex calls satisfy the same fixed demand outcomes; parser export does not construct them. |

The suspected eager-formatting mismatch must first fail on unchanged product
code. Only then may the Ex path retain option thunks and force them in used
branches. Existing native/reference-oriented std_manifest error cases for scalar
unused indent/newline/key separator do not establish normative eagerness. If
the regression confirms the mismatch, preserve those original bytes and move
the three old cases to nonempty-array/empty-array/nonempty-object contexts where
their type/error checks are actually required. Keep the new unused-error
regressions and all literal expectations unchanged; do not make a guessed
blanket type-domain decision for unused invalid option values.

Reuse existing string-concat/manifest/finite/visibility evidence in its original
scope. In particular std.manifestJson's visible-field traversal and ordinary
top-level manifestation are distinct; no new assertion policy or N0/R0 result.
Duplicate JSON keys, malformed host Strings/surrogates, general decimal rounding,
all formatting/type/resource combinations and whole function conformance remain
unproved. YAML's documented best-effort/root restrictions are outside this group.
Language print conflicts, shift exclusions and A0/B0/N0/R0/PE0/DF0 remain intact.

Use existing public inventory/schema v2 tools. No new metadata framework. If
product changes, run affected output/argument/diagnostic/finite/reflection
neighbors once, rebind only demonstrably unchanged inspection anchors to the
new source hash, and retain all prior decisions. Single worker, nice 10, native
debug frozen -j 1, no parallel tests/full suite/remote/install/push/dependencies.

<!-- Criteria above are frozen before execution; append results below. -->

## Results and bounded correction

The first native debug run on unchanged product code ran six tests: four
passed, and JC5/JC6 failed (exit 2). Both the source calls and independent AST
calls incorrectly demanded unused format expressions. For example,
`std.manifestJsonEx(1, error 'unused')` must return the String `1`: the fixed
source's scalar branch never reads indent. Empty containers still demand
newline; nonempty arrays demand indent; actual visible object fields demand
key_val_sep. The first failure log and original product/test bytes are retained
in `/tmp/moonjsonnet-json-contracts.zk9x_k_t`.

The correction keeps manifestJsonEx's format arguments as existing VM thunk
IDs, rather than including them in the native dispatcher's eager parameter
loop. The visible-value renderer resolves a format argument only in a branch
that uses it and forwards the same IDs into nested containers. Existing fixed
String-style callers keep their private interface defaults. The change does
not add a public interface or modify the ordinary manifestation path.

Three legacy error cases formerly supplied invalid/failed options to a scalar
that does not use them. Their original bytes remain in the evidence directory;
their calls now use `[1]` for invalid indent, `[]` for invalid newline, and
`{x:1}` for failed key separator. The assertions still require errors in these
demanded contexts. All other legacy String inputs and nonlayout tokens are
unchanged. This correction follows the frozen plan above, rather than changing
the new regressions' expectations to match implementation behavior.

After the correction the exact first-run regression bytes passed 6/6. Their
SHA-256 remains
`4b6cf2af9358e616bab60e695a65ac7e47e454d83a722a493ae9a325826ac8d0`.
The affected tests ran serially once on the corrected source:

| Test file | Passed |
| --- | ---: |
| spec_json_contracts_test.mbt | 6/6 |
| std_manifest_test.mbt | 4/4 |
| arguments_test.mbt | 1/1 |
| standard_native_diagnostics_test.mbt | 2/2 |
| spec_manifest_wbtest.mbt | 1/1 |
| spec_string_concat_test.mbt | 4/4 |
| spec_object_ex_test.mbt | 3/3 |
| spec_object_head_test.mbt | 2/2 |
| spec_sequence_structure_test.mbt | 4/4 |

All nine commands exited 0: 27/27 in total, with nice 10, native debug,
`--frozen --deny-warn -j 1 --no-parallelize`. These are directed affected-path
checks, not a current full-suite result. The corrected product hashes are
stdlib.mbt
`a8bd68d2263344036a9c89975385754610b1ccc7d906fc213da7fe65157679a4`
and manifest_json.mbt
`319fc7f84c60fd65609af3cc4fbe84bfaa54f4d3107b114a7fca6737f93b08bc`.
The saved before/after receipts bind each test's bytes and log hash; check,
info, root formatting and the existing matrix script also exited 0. Generated
public interfaces are unchanged. No semantic check was repeated after these
receipts merely to refresh a report.

The one-off final scope audit initially stopped before staging or the docs
checker because prose rows carry a null rule_review. Its receipt is retained;
only that audit's null handling was corrected. No product, test expectation,
matrix data or existing checker changed to satisfy it.

## Inventory and evidence limits

The public inventory still lists 153 function candidates. Its manual map has
44 records, of which 41 functions have at least one reviewed dimension;
parseJson and the three JSON rendering APIs add normal/error/lazy/boundary
subsets. All 40 preexisting manual records are unchanged. A reviewed dimension
is not whole-function acceptance: every whole-contract status stays
unaccepted, and behavioral_conformance_proven stays false. JC1-JC6 are this
report's groups, not invented canonical language test IDs. Inventory source
hashes include both changed test files; their uncommitted-at-generation labels
describe the frozen generation inputs, not the final Git state.

The language matrix remains 94 rows: 28 completed named transfers (9 static,
19 evaluation), one constructor transfer completed relative to its child
judgments, 63 partial and two unreviewed. All 195 canonical evidence entries
and all decisions/clauses are unchanged. The product's shared stdlib file hash
changed, so 16 existing inspection anchors across six named reviews were
rebound: length-array, length-object, length-string, object-fields-ex,
object-has-ex and type-object. Their anchors and reasoning remain unchanged.
Removing the new Ex-only dispatch branch and restoring the old Ex match arm
reconstructs the entire prior stdlib file exactly; this byte check and the
affected neighbors support the limited rebindings. It is not a rerun or an
upgrade of those reviews. Schema v2 and both generators remain unchanged.

No new conclusion covers duplicate JSON keys, malformed host Strings or
surrogate policy, general decimal rounding or float rendering, all escaping
and resource combinations, every argument combination, exact error messages,
or unused invalid option *value types*. Unused error expressions and required
option failures have the specific evidence above. Output order in a failure
race is not adjudicated. YAML, ordinary top-level assertion manifestation,
N0/R0 and all other paper conflicts remain outside this correction. The two
unreviewed greater-than print conflicts and bounded-shift exclusions are
unchanged. No Go/C++ comparison, remote operation, new dependency, full suite
or push ran; the historical 539/539 full run remains bound only to 5651ae9.

Raw frozen criteria, first failure, after-fix results, scope/mapping audits,
generated inventories, final staged hashes and documentation/commit receipts
are retained in `/tmp/moonjsonnet-json-contracts.zk9x_k_t`.
