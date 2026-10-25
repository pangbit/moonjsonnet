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
| P0-IMM | Language reference, Values; stdlib remove/removeAt descriptions | `local a=[1,2,3,4]; local b=std.removeAt(a,1); [b,a]` is `[[1,3,4],[1,2,3,4]]`; aliases, earlier map/slice and chained deletions preserve originals; length does not force payloads | [spec_remove_test.mbt](../../spec_remove_test.mbt), [remove_test.mbt](../../remove_test.mbt) | [std_remove.mbt](../../std_remove.mbt) | Original mutated / corrected local regression passes |
| P0-NUM | Language reference, Number | sum/avg overflow is a runtime error at the first invalid addition, including before comparison/type/string consumers or later operands; unused/short-circuited/hidden values stay lazy | [spec_aggregate_test.mbt](../../spec_aggregate_test.mbt), [aggregate_test.mbt](../../aggregate_test.mbt) | [stdlib.mbt](../../stdlib.mbt) | Inf/NaN succeeded / corrected local regression passes |
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
