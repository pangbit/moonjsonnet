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
records full native release and focused CLI/application validation. The counts
below retain the original first-stage scope.

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
530 links. These are macOS ARM64 results only. Full release, CLI scenario, Linux
and fresh Go/C++ runs remain pending. Binary and input hashes are recorded in a
separate source-bound stage report.

P1 must enumerate every language rule and public standard-library entry, rather
than treating the 163-member reflection inventory as the public contract list.
For each row, record source/expected/test/implementation/result, and explicitly
mark missing normal/error/lazy/boundary coverage as untested. In particular:

- `removeAt`'s documented `idx`, C++ source `at`, and current `i` are an unresolved
  named-argument conflict; this batch does not select a new signature.
- `std.length(function(a,b=1)a)` has now been adjudicated to require 2 under the
  fixed public documentation. The current result remains 1; the candidate fix
  was blocked by automatic approval review. See the [contract review](SPEC-CONTRACT-REVIEW.md).
- `std.manifestJson({assert false})` is distinct from top-level manifestation;
  this batch preserves both existing paths and does not invent an assertion rule.
- Existing Go/C++ fixtures and historical exception reports are unchanged. Fresh
  differences caused by the normative fixes must be recorded separately on rerun.

No Linux upload/execution, database access, remote push, tag, publication,
toolchain upgrade or dependency upgrade is part of this stage. Linux execution
scope and host authorization remain for the parent task to arrange.
