# Specification conformance work

## Acceptance contract

The final target is complete Jsonnet v0.21.0 conformance, with normative sources
fixed at Google Jsonnet `bbb38f1020be1f5aed560928fb839b2c448cefb4`:
[language reference](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md),
[specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html),
[standard-library documentation](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html),
and its referenced [source definitions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet).
Go/C++ execution is separate comparison evidence. Explicit normative violations
cannot be waived by compatibility exceptions. Ambiguities and untested behavior
remain unresolved, not passing. This document summarizes engineering requirements;
it does not reproduce or amend the private application document.

Final acceptance requires:

- Every lexical, grammar, static-checking, evaluation and JSON manifestation rule,
  including finite numbers, Unicode, scope, laziness, inheritance, visibility,
  assertions and imports.
- Every public standard-library contract, including parameter names, defaults,
  return values, errors and when arguments or elements are forced. Reflection
  registration counts include internal helpers and do not prove these contracts.
- A rule-by-rule matrix covering ordinary results, static errors, runtime errors,
  lazy and boundary cases, linked to implementation and executed evidence.
- Native debug/release evidence on macOS ARM64 and Linux AMD64 for the library,
  CLI and environment/monitoring/embedded-application examples. Evidence must bind
  source, toolchain, binary and input hashes. The embedded scenario includes
  parameters, controlled imports, structured results, diagnostic context and
  rejection of invalid parameters, assertions, import escape and resource limits.
- CLI success/output and nonzero failure behavior, formatting with comments,
  binding diagnostics, installable native library, runnable examples, source,
  licenses, attribution and API/CLI documentation.

JS/Wasm, LSP and package management are outside the platform/tool scope. Host
permissions and resource limits do not reduce language or public-library scope.
Historical raw upstream results and failure classifications remain preserved.
The original application and any personal details must not be added to commits.

The [2026-10-23 native package regression](SPEC-NATIVE-REGRESSION-2026-10-23.md#later-complete-regression-at-84eb1f7)
records debug and release each passing 713/713 at clean source commit
`84eb1f71d1f408b1aa0bd11526a83b31f51b58d0`, after membership and extrema
corrections. The earlier 672/672 results remain bound separately to 21ee800.
This refreshes local package regression evidence only; matrix coverage,
unresolved contracts and remaining integration/platform requirements are unchanged.

The [local application delivery subset at f23210c](SPEC-NATIVE-REGRESSION-2026-10-23.md#local-application-delivery-subset-at-f23210c)
passed two existing API groups and eleven independent CLI/embedded process cases
against one clean 682-entry source snapshot. This adds current macOS application
evidence only: debug API tests and release executables. It does not establish the
complete 67-case application suite, an independently installed package consumer,
Linux acceptance or a full package regression at f23210c.

The [2026-10-25 Linux record at 228cb25](SPEC-NATIVE-REGRESSION-2026-10-23.md#linux-native-evidence-at-228cb25)
adds same-source debug 734/734 and release 734/734 from separate windows, plus
11/11 existing release CLI/embedded process cases. The first release attempt's
600-second incomplete build and historical cleanup refusal remain preserved;
the successful window used a separately approved 1050-second build followed by
the unchanged complete test command. Source, full private-SDK fingerprints,
raw output, binaries and independent cleanup receipts are bound in that record.
This does not establish complete 67-case application acceptance, a package consumer,
new macOS 734 results, reference parity or full specification conformance.

## P0 normative matrix

This is a focused regression matrix, not the complete final conformance matrix.
All test inputs are synthetic and contain no business data. The first run at
`8e661f9` plus new tests had six groups: five failed, one lazy-boundary group
passed. The rows below identify the corresponding independently reproducible
checks. Files are linked to repository sources rather than private documents.

| ID | Fixed normative basis | Expected behavior and boundaries | Tests | Implementation | First result / corrected result |
| --- | --- | --- | --- | --- | --- |
| P0-IMM | Language reference, Values; stdlib remove/removeAt descriptions | `local a=[1,2,3,4]; local b=std.removeAt(a,1); [b,a]` is `[[1,3,4],[1,2,3,4]]`; aliases, earlier map/slice and chained deletions preserve originals; length does not force payloads | [spec_remove_test.mbt](../../spec_remove_test.mbt), [remove_test.mbt](../../remove_test.mbt) | [current source routes](../../stdlib_layer.mbt), [fixed definitions](../../stdlib_source.mbt), [retained native helper](../../std_remove.mbt) | Original mutated / corrected local regression passes |
| P0-NUM | Language reference, Number | sum/avg overflow is a runtime error at the first invalid addition, including before comparison/type/string consumers or later operands; unused/short-circuited/hidden values stay lazy | [spec_aggregate_test.mbt](../../spec_aggregate_test.mbt), [aggregate_test.mbt](../../aggregate_test.mbt) | [source routing](../../stdlib_layer.mbt), [finite operators](../../operators.mbt), [retained native fallback](../../stdlib.mbt) | Inf/NaN succeeded / corrected local regression passes |
| P0-NUM-OUT | Number requirement and manifestation into JSON | Defensive rejection of internal +/-Inf and NaN by JSON/YAML output paths | [spec_manifest_wbtest.mbt](../../spec_manifest_wbtest.mbt), [spec_yaml_wbtest.mbt](../../spec_yaml_wbtest.mbt) | [manifest.mbt](../../manifest.mbt), [manifest_json.mbt](../../manifest_json.mbt), [manifest_yaml.mbt](../../manifest_yaml.mbt) | Guard added; direct internal-value tests pass |
| P0-IDX | Specification, array-index; language reference, String | Fractional/huge/negative/out-of-bounds indices error before conversion or element access; integral doubles and Unicode code-point access succeed | [spec_index_test.mbt](../../spec_index_test.mbt), [numeric_test.mbt](../../numeric_test.mbt) | [eval.mbt](../../eval.mbt), array_index | Fractional indices truncated / corrected local regression passes |
| P0-SLICE | Specification slice desugaring and std.jsonnet slice definition | Array slices defer indexing errors until demanded; length still succeeds; strings remain strict; fractional end alone may select only integers | [spec_index_test.mbt](../../spec_index_test.mbt) | [slice.mbt](../../slice.mbt), [sequence.mbt](../../sequence.mbt) | Demanded fractional indices truncated / corrected local regression passes |
| P0-YAML | Stdlib documentation's source-defined behavior; std.jsonnet manifestYamlDoc aux | Nested errors and functions at root/array/object/stream levels fail the call; hidden fields remain lazy; no successful partial configuration | [spec_yaml_test.mbt](../../spec_yaml_test.mbt), [toml_yaml_test.mbt](../../toml_yaml_test.mbt) | [manifest_yaml.mbt](../../manifest_yaml.mbt) | Truncated/empty success / corrected local regression passes |

The slice decision follows the source definition's lazy array element expression
and strict string concatenation. It does not impose integer validation on every
slice bound or change unrelated integer conversions. Runtime diagnostic wording
is a tool contract; success versus runtime/static error is normative.

## First-stage evidence and remaining work

The subsequent [independent review and scenario report](SPEC-REVIEW-EVIDENCE-2026-10-22.md)
records full native release and focused CLI/application validation. The latest
[P1 stage](SPEC-P1-EVIDENCE-2026-10-22.md) records the approved function-length
fix, unique formal parameters, CRLF empty text-block lines and import isolation.
The subsequent [chomp and public-inventory stage](SPEC-CHOMP-EVIDENCE-2026-10-22.md)
resolves the final-CRLF boundary and maps official candidate signatures separately
from registration, with unknown coverage retained.
The [foundation stage](SPEC-FOUNDATIONS-EVIDENCE-2026-10-22.md) independently
reviews ten type/numeric/array contracts and corrects range endpoint narrowing;
its table separates reviewed dimensions, oracle corrections and unresolved cases.
The [array-combinator stage](SPEC-ARRAY-COMBINATORS-EVIDENCE-2026-10-22.md)
reviews five adjacent contracts, fixes fold/flatMap forcing and preserves
unresolved cardinality/predicate observations without granting passing status.
The [object-contract stage](SPEC-OBJECT-CONTRACTS-EVIDENCE-2026-10-22.md) reviews
six visibility/lookup functions, distinguishing structural reflection, selected
field assertions and lazy defaults without changing product implementation.
The [string/Unicode stage](SPEC-STRING-CONTRACTS-EVIDENCE-2026-10-22.md) reviews
seven public contracts and fixes fractional char IDs plus substring clipping and
guard/index forcing. Its newer source stays separate from frozen af188da Linux work.
The [language-clause stage](SPEC-LANGUAGE-EVIDENCE-2026-10-22.md) adds independent
function/default and object/assertion/JSON checks without changing the interpreter.
Its [language matrix](SPEC-LANGUAGE-MATRIX.md) enumerates 70 named inference
rules plus 24 initial prose/grammar obligations, with manually reviewed assertion
subsets and explicit unreviewed dimensions; full prose/desugaring decomposition
and conformance remain pending. [Go/C++ status](SPEC-LANGUAGE-COMPARISON-2026-10-22.md)
is separate from normative execution results.
The [recursive-binding/comprehension continuation](SPEC-LANGUAGE-FORMS-EVIDENCE-2026-10-22.md)
adds 15 assertion groups plus 30 source CLI checks for two formerly unreviewed
rules and adjacent scope/forcing dimensions. The focused single-worker affected
run passes 44/44 without a product fix; the matrix now has 43 partially reviewed
rows and 51 unreviewed rows. This does not change the public-stdlib coverage count.
The [application entry-path batch](SPEC-LANGUAGE-CALL-EVIDENCE-2026-10-22.md)
adds seven groups for handmade calls, recursive closure defaults and callee
forcing, validated by 29/29 affected checks and a 15/15 source CLI corpus.
These extend already partial rows; the 43/51 matrix and stdlib counts are unchanged.
The subsequent [chk-importstr review](SPEC-IMPORTSTR-STATIC-EVIDENCE-2026-10-22.md)
closes that premise-free static judgment using constructor analysis and 16/16
focused checks. The matrix now distinguishes one completed named rule, 43
partial rows and 50 unreviewed rows. Runtime import obligations and whole-language
acceptance remain incomplete; public stdlib counts do not change.
The [binary byte-substitution review](SPEC-IMPORTBIN-BYTES-EVIDENCE-2026-10-22.md)
at `10982a4` adds four virtual-import groups and passes one affected 26/26 native
debug run. It completes the bounded importbin byte-value sentence, including all
256 values through source and handmade AST; the broader CORE-IMPORT row remains
partial with explicit loading/cache/error-policy gaps. The adjacent chk-import
and chk-importbin static judgments reuse the shared constructor argument and
existing creation controls, rather than adding duplicate tests. The matrix now
records three completed named static judgments, 42 partial rows and 49 unreviewed
rows, with no new inventory rows or interpreter/API changes. Public stdlib counts
remain unchanged.
The [importstr UTF-8 review](SPEC-IMPORTSTR-UTF8-EVIDENCE-2026-10-22.md) at
`baf115c` adds four source/handmade-AST virtual-byte groups and passes 17/17
affected native debug checks after correcting a test-only host adapter. It
reviews BOM-free text substitution and strict malformed-byte rejection while
separating host diagnostic/cache observations from normative requirements.
Initial-BOM interpretation remains explicitly unknown. The 3/42/49 matrix,
stdlib counts and product/public interfaces are unchanged; CORE-IMPORT still
lists its broader loading, caching and host-policy gaps.
The subsequently released [approved Linux window](SPEC-LINUX-AF188DA-EVIDENCE-2026-10-22.md)
validated only the frozen af188da archive: native debug/release each 425/425,
CLI/application checks 59/59, with completed cleanup. This is not a Linux result
for the newer string/Unicode or language-stage source.
The counts below retain the original first-stage scope.

P0 fixes are local commits `001679a` (immutability), `dd3b9d0` (finite aggregates),
`ece4ff1` (integer indices/lazy slices), and `069b9de` (YAML errors).
Affected native debug suites passed 18/18, 27/27, 24/24 and 18/18 respectively;
these overlapping suite totals must not be added. Zero-warning checks passed,
and generated public interfaces did not change.

The baseline failure log is retained locally at
`/tmp/moonjsonnet-spec-p0.YGGswy/before.log` (SHA-256
`007fc185681075461aa34914b7235cff126160dbe507f245ea2e0dd9ec9a57c1`).
The previous read-only audit remains at its original temporary path, unchanged
(assessed-results SHA-256
`5aa933e4fdb0580760e00a0ebf8975dac2be8df838c88c3806a78f1de1eb47cf`).
Temporary evidence is local and is not an archival delivery guarantee.

Full acceptance remains pending. The first broader debug run found two existing
Program/parameter tests still expecting input mutation; their expected results
were corrected to the same immutable-array rule. The subsequent full native debug
run passed 336/336. Focused native release regressions passed 8/8, the extracted
archive consumer passed 31/31, and documentation validation passed 107 files and
530 links. These were macOS ARM64 results only; full release and CLI scenarios
were then pending and are covered by subsequent source-bound stage reports.
Linux and fresh Go/C++ runs remain pending for the changed implementation.

P1 must enumerate every language rule and public standard-library entry, rather
than treating the 163-member reflection inventory as the public contract list.
For each row, record source/expected/test/implementation/result, and explicitly
mark missing normal/error/lazy/boundary coverage as untested. In particular:

- `removeAt`'s documented `idx`, C++ source `at`, and current `i` are an unresolved
  named-argument conflict; this batch does not select a new signature.
- `std.length(function(a,b=1)a)` has now been adjudicated to require 2 under the
  fixed public documentation and fixed in `2cee5de` after the user's exact
  confirmation. The previous approval blocker is resolved. See the
  [contract review](SPEC-CONTRACT-REVIEW.md).
- `std.manifestJson({assert false})` is distinct from top-level manifestation;
  this batch preserves both existing paths and does not invent an assertion rule.
- Existing Go/C++ fixtures and historical exception reports are unchanged. Fresh
  differences caused by the normative fixes must be recorded separately on rerun.

No Linux upload/execution, database access, remote push, tag, publication,
toolchain upgrade or dependency upgrade is part of this stage. Linux execution
scope and host authorization remain for the parent task to arrange.


## Stage inventory after 0d06ded

The [current macOS native debug run](SPEC-NATIVE-REGRESSION-2026-10-23.md#macos-native-debug-regression-at-0d06ded)
passes816/816, exit0, skipped0 at clean0d06ded (703 inputs). No product or test
bytes changed in this closeout; old failures and migrations remain preserved.
This refreshes regression evidence, not whole-language acceptance.

| Initial P0 responsibility | Current implementation and regression status |
| --- | --- |
| IMM | Original arrays/aliases remain immutable through source remove/removeAt and map/slice compositions; original P0 and complete deletion responsibility tests pass in this run. The named idx/at/i conflict is separate. |
| NUM | sum/avg source reductions and finite operators reject actual nonfinite arithmetic at its producing step; unused expressions, short circuits and hidden fields stay lazy. Addition/coercion, non-Array admission and required foldl consumers are included. |
| NUM-OUT | Defensive internal Inf/NaN rejection in JSON/YAML remains tested; output checks do not substitute for producer checks. |
| IDX | Ordinary Array/String access rejects invalid fractional/huge/negative/range indices and retains Unicode codepoint units. Broader source-defined removeAt admission did not change ordinary indexing. |
| SLICE | Array slice indexing remains deferred until demanded, with length and strict String boundaries preserved. |
| YAML | Nested visible errors/functions cannot return successful partial text; hidden payloads remain lazy. The later option-demand correction and scoped strict dispatch are covered by current directed and full tests. No new swallowed-value defect was manufactured. |

These six scoped regressions are repaired at the current source; no remaining
confirmed initial-P0 implementation failure is recorded. Later sort, member,
extrema, deletion and aggregation repairs also have independent red/green
evidence and current regression coverage. Zero unconditional whole-function
acceptances does not mean those implementations or passing subsets are absent.
The language matrix still has28 named-rule reviews,1 constructor review relative
to children,63 partial rows,2 unreviewed rows and225 evidence IDs; child assumptions
and complete_conformance=false remain unchanged.

### Public evidence rather than registration counts

The [153-candidate inventory](SPEC-PUBLIC-STDLIB-INVENTORY.md) and
[66 exact manual records](../../tests/spec-public-coverage.json) identify every
currently mapped subset and its N/E/L/B assertions. The candidates retain both
XML spelling variants;153 is not153 resolved full contracts. There are87 entries
without a public manual contract record, grouped exhaustively below.

Unmapped is not proof of no implementation, no tests or no independent evidence.
In particular objectHasEx/objectFieldsEx already have independent language-rule
transfer reviews, primitiveEquals has bounded PG evidence, and hypot/parseYaml
have direct finite-producer controls in spec_review_test. Host native references
can instead be test instrumentation. Other literal candidate references require
assertion review before they earn coverage. This inventory does not falsely
classify all87 as zero-evidence functions or promote those cross-domain witnesses
to complete public contracts.

| Unmapped public-record family | Count | Exact candidate names |
| --- | --- | --- |
| Configuration, rendering and host | 12 | extVar, native, trace, format, toString, parseYaml, manifestIni, manifestPython, manifestPythonVars, manifestToml, manifestTomlEx, manifestXmlJsonml |
| String, byte encoding and paths | 17 | asciiLower, asciiUpper, base64, base64Decode, base64DecodeBytes, decodeUTF8, encodeUTF8, equalsIgnoreCase, escapeStringBash, escapeStringDollars, escapeStringJson, escapeStringPython, escapeStringXML, escapeStringXml, resolvePath, strReplace, trim |
| Sequence, predicates and sets | 15 | all, any, count, filterMap, find, isEmpty, mapWithIndex, repeat, reverse, set, setDiff, setInter, setMember, setUnion, uniq |
| Object projections | 6 | mapWithKey, objectFieldsEx, objectHasEx, objectKeysValues, objectKeysValuesAll, objectValuesAll |
| Type, equality and logic | 10 | assertEqual, equals, primitiveEquals, isArray, isBoolean, isFunction, isObject, isString, xnor, xor |
| Numeric domain and arithmetic | 25 | acos, asin, atan, atan2, clamp, cos, deg2rad, exp, exponent, hypot, isDecimal, isEven, isInteger, isOdd, log, log10, log2, mantissa, mod, modulo, rad2deg, round, sin, sqrt, tan |
| Digest conditional scope | 2 | sha256, sha512 |

The66 recorded subsets plus87 unmapped public records partition the153 candidates
without double-counting shared language obligations. The precise count with no
independent assertion anywhere is not established by this map; an absent textual
reference is insufficient, especially for dynamically constructed Ex calls.

### Shared normative questions, counted once

| Question class | Current decision and existing source |
| --- | --- |
| Printed formula conflicts | [A0](SPEC-SEQUENCE-STRUCTURE-2026-10-22.md): array-concat drops e0 in its conclusion despite append prose/library; [DF0](SPEC-ADDITIVE-FIELDS-2026-10-23.md): ordinary-field lowering uses key e as value instead of rhs e-prime; [greater-than](SPEC-RELATIONAL-SIGN-2026-10-23.md): printed cmp-sign conclusions conflict. Behavioral witnesses do not silently repair formulas. |
| Inheritance and assertion model | [N0/R0](SPEC-OBJECT-ASSERTION-ADJUDICATION-2026-10-22.md#complete-shared-assertion-domain-review-atf3871b8): right-only super prefix conflicts with the layered guide; assertion prefix/checking-state rules are missing. Agreed flat demand stays distinct from conditional inheritance/reentry profiles. |
| Underdefined applicability | [B0](SPEC-REMOVE-SEARCH-2026-10-25.md#b0-closeout-and-pivot) does not state the longcut RHS domain; [PE0](SPEC-PRIMITIVE-EQUALS-2026-10-22.md#subsequent-bounded-applicability-review) does not define metavalue equality/application domain. Conditional alternatives are not unconditional pairs of contradictory public promises. |
| Public documentation/source conflicts | [removeAt idx/at and current i](SPEC-PUBLIC-STDLIB-REVIEW.md#removeat-named-parameter-candidates), XML spelling, Stream end default false/true, isEven/isOdd integral-part/round and digest Go-only/stub scope remain unresolved in the existing public review. [HP0](SPEC-INTEGER-PARSERS-2026-10-23.md) covers parseHex punctuation aliases. |
| Unspecified details versus missing tests | [tailstrict TODO and call boundary](SPEC-YAML-DEMAND-2026-10-25.md#bounded-shared-call-follow-up-frozen-at-6569b9f), unrelated-error winner order and exact native callback counts cannot be invented as stronger public promises. Unreviewed input/encoding/numeric/resource cases remain evidence gaps; they are not all specification conflicts or implementation failures. |

These questions remain explicit; they are not normative waivers and are not
recounted for every dependent standard-library function. Go/C++ agreement cannot
settle them. No conflict branch is reopened by this status inventory.

### Recommended bounded batches and acceptance gates

1. Highest-value semantic batch: parseYaml's complete public input/return/error/
   demand responsibility. Reuse existing parser/finite diagnostics first, then
   freeze only missing independent ordinary, malformed/multiple-document, nested
   finite, type/binding, unused-call and resource cases within the fixed contract.
   Stop when that matrix is mapped and any demonstrated defect is repaired with
   unchanged-oracle directed regression; unsupported or contradictory source
   clauses stay explicit. No general YAML-format or new parser feature campaign.
2. Next risk group: encodeUTF8/decodeUTF8 and byte/String/base64 boundaries for
   configuration transport. Separate valid Unicode/byte contracts, error/demand
   and aliasing from unresolved malformed raw-text rules. Then cover the other
   configuration manifests' success-versus-error/output responsibility as a
   distinct batch; do not treat candidate references as evidence.
3. Sequence/object/type groups follow by shared implementation risk, reusing the
   existing Ex, primitive and combinator evidence before adding tests. Math and
   digest work needs independent numeric expectations and conditional API scope;
   it must not copy a reference implementation's outputs. Each batch ends at a
   finite signature/value/error/lazy/boundary map with actual source-bound results.

For delivery, use a stable source boundary rather than another environment loop:
if the next chosen parseYaml batch changes production, complete it and one
combined local debug regression before freezing the new source for macOS release
and Linux debug/release plus controlled API/CLI/embedded checks. If it needs no
production change, current0d06ded product bytes already supply that freeze point.
Schedule one same-source cross-mode/platform cohort, binding inputs/toolchain/
binaries and retaining failure, timeout and cleanup evidence. It must separately
close the full67-scenario application and independently installed consumer gaps;
the old11-process subset cannot establish those. Old228cb25 Linux734/734 evidence
is historical, not coverage of current product bytes. This turn starts none of
those validations or new semantic batches and returns for coordinator assessment.


## Input-converter cohort checkpoint at1a46122

The bounded parseYaml root, parseJson finite-data and shared native/YAML
String-key work is now closed for this batch. Its original failures, scope
limits, independent oracles and justified migrations remain in the linked
contract records. The subsequent [same-source macOS native debug regression](SPEC-NATIVE-REGRESSION-2026-10-23.md#macos-native-debug-regression-at1a46122)
passes835/835, failed/skipped0, exit0 on the fixed708-entry source. No product
or test changes were needed during full validation.835 package regressions
include conditional profiles and are not835 normative judgments.

This checkpoint supersedes only the earlier stage inventory's next parseYaml
batch and source-freeze recommendation: that finite batch is complete, the
current public map is67 subsets plus86 unmapped public records, and zero whole
functions are promoted. All225 language evidence records, shared disputes and
whole-conformance incomplete status remain unchanged. Unmapped public records
still do not prove absence of implementations or independent assertions.

Freeze1a46122 product/test/package/executable-README bytes for later release and
Linux scheduling. Reuse the existing reviewed minimum workflow with fresh
source/toolchain identity and adequate complete-test budget; do not inherit
228cb25 Linux results or silently reuse its near-exhausted120-second test cap.
No archive, SSH, release, standalone application/consumer or new semantic-domain
run starts here. The coordinator assesses that next cohort after this result.

## Same-source platform checkpoint at 97f0938

The [source-bound validation cohort](SPEC-NATIVE-REGRESSION-2026-10-23.md#same-source-validation-cohort-at-97f0938)
now records complete Linux debug F1 and release B, each 835/835 with zero failures
or skips and exit 0, plus D1's independent API 2/2 and CLI/embedded subset 11/11.
All Linux runs used the original 708-entry `9bdacec` archive, whose tree exactly
matches `97f0938` after the commit-message-only rewrite. macOS debug 835/835 was
actually run at `1a46122`; only two non-executable documentation records differ
from that source. Product, test, package, executable README and interface bytes
are unchanged. These are separate runs, not one combined test count.

The earlier A fingerprint failure, A2 timeout without statistics, and D1 partial
root diagnostic remain preserved. F1 supplies complete debug evidence; it does
not retroactively turn those attempts into passes. Evidence recovery, hash
verification and owned-process/directory cleanup have completed. This checkpoint
supersedes only the preceding recommendation to schedule this Linux cohort.
Current-source macOS release, all 67 application scenarios and a separately
installed package consumer still require their own acceptance; the 11-process
subset and in-package API examples do not establish them.

The fixed normative revision remains `bbb38f1020be1f5aed560928fb839b2c448cefb4`.
The [public review](SPEC-PUBLIC-STDLIB-REVIEW.md) still has 67 mapped subsets and
86 candidates without a manual public-contract record, out of 153 candidates;
zero unconditional whole-function acceptances are claimed. The
[language matrix](SPEC-LANGUAGE-MATRIX.md) retains 28 completed named-rule reviews,
one relative prose-constructor review, 63 partial rows, two unreviewed comparison
rules and 225 evidence IDs. The initial prose inventory is not an exhaustive
completed decomposition. Missing mapping does not prove a missing implementation
or an absence of independent assertions; these counts are not a conformance rate.

The scoped original immutability, finite-number/output, integer-index, lazy-slice
and YAML-error repairs are included in the tested source. No still-unfixed
original P0 defect is currently confirmed. The [shared normative questions](#shared-normative-questions-counted-once),
conditional profiles and unreviewed contract boundaries remain open and are
counted once, not once per dependent function. Overall specification conformance
remains **incomplete**. This documentation closeout adds no implementation,
oracle, matrix record, new test execution or new remote campaign.

## Base64 byte-domain correction after 2d34a66

The [bounded base64 contract record](SPEC-BASE64-CONTRACT-2026-10-26.md) adds an
independent String/codepoint-to-byte review. The unchanged fifteen groups first
passed 10 and failed 5: String codepoints 128..255 were incorrectly encoded as
UTF-8 bytes. The scoped String conversion repair passes 15/15 with the same
expectations, plus the existing encoding 2/2, argument 1/1 and scalar 4/4 groups.
The eighteen negative/fraction observations are unchanged and remain ungraded;
B64-R0/F0 are unresolved. One legacy `base64('é')` expectation migrates from
`w6k=` to `6Q==` with its fixed-definition derivation and original result retained.

The record binds directed-run and subsequently formatted test hashes separately;
product bytes and all public interfaces are unchanged by formatting. The later
[complete macOS native debug run](SPEC-BASE64-CONTRACT-2026-10-26.md#complete-macos-native-debug-regression-at-5ae6aab)
validates final `5ae6aabf4150fcf1e9114555f94d9e9419ac6249` and its 711 committed
inputs: actual 851/851 passed, failed/skipped 0, exit 0 in 152.930s. The eighteen
profile observations remain ungraded, with B64-R0/F0 unresolved. Input hashes
and clean repository state stayed stable, and all owned processes exited.
The earlier 835-test platform cohort is historical for this changed implementation;
current release, Linux and standalone CLI/API results are not claimed.
Generated inventory counts above remain checkpoint-specific; this closeout adds
the linked scoped evidence without regenerating that snapshot or promoting a
whole function. Overall specification conformance remains **incomplete**.

## Canonical Base64 decoding after b60c035

The [decoder contract record](SPEC-BASE64-DECODE-CONTRACT-2026-10-26.md) follows
the fixed definition that maps each decoded byte through `std.char`. Its twelve
independent groups first passed 6 and failed 6: `base64Decode` incorrectly
interpreted those bytes as UTF-8. The scoped final String conversion now passes
12/12 with unchanged independent expectations, including all previously blocked
C08/C09 source/AST and length branches. The original failures and historical
NOTRUN branches remain recorded.

The same 714-input candidate passed migrated encoding 2/2, encoder contract
15/15, argument 1/1 and String-scalar 4/4 groups, with check and all directed
commands exiting 0 in a 17.861s window. The 48 observations are byte-identical
to baseline and earn zero normative passes. Only two legacy decoded-String
expectations migrate with fixed-definition evidence; the shared Base64 parser,
byte decoder and explicit UTF-8 operations are unchanged. B64D-M0/A0, malformed
UTF-8 profiles and encoder B64-R0/F0 remain separate unresolved boundaries.

This adds bounded contract evidence without regenerating the historical inventory
or promoting a whole function. Full-suite, release, Linux and standalone CLI/API
have not run on this decoder repair; the preceding 851-test result applies to its
earlier source. Overall specification conformance remains **incomplete**.
