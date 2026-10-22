# Importbin byte substitution and adjacent static judgments

**Decision: the fixed Core Syntax line-916 importbin byte-value substitution
sentence is reviewed complete within the criteria below.** Successful supplied
bytes become an array with identical length/order/repetitions and unsigned values
0-255. No rejecting byte value exists. This does not complete target resolution,
resource/error policy, cache identity or the entire CORE-IMPORT matrix row.

The [criteria written before execution](SPEC-IMPORTBIN-BYTES-REVIEW.md) pin Google
Jsonnet `bbb38f1020be1f5aed560928fb839b2c448cefb4`. The selected sentence has a
different contract from the adjacent premise-free static judgments: it constrains
the demanded runtime value. No new inventory rows or duplicate static test groups
were added to raise a count.

## Independent outcomes

| Obligation / phase | Executed result and limit |
| --- | --- |
| Byte values, length and order | Source and handmade ImportBinary AST each match exact JSON for a nonmonotone permutation of all 256 values |
| Empty and repeated values | Both entry paths produce the explicit empty/repeated/high-bit/NUL arrays |
| Opaque binary content | Both paths preserve malformed UTF-8 bytes and return the numeric bytes of error 1, rather than decoding or executing that text |
| Laziness | Five unused source contexts and two handmade local/branch contexts return 42 with zero virtual requests |
| Syntax at source creation | Three nonliteral/computed operands raise Syntax before evaluation; no malformed-text equivalent is claimed for the typed AST |
| Static at Program creation | Undefined siblings raise Static in source and handmade AST; valid import leaves do not suppress surrounding checks |
| Resolver failure during evaluation | Source and handmade leaves create successfully, then raise public Import for disabled/failing virtual resolvers; failing callbacks run once and retain the entry identity |
| Repeated identical request | New handmade case returns two exact arrays with one callback; the already-existing source case is reused, not counted as new |
| Negative byte / Type / Runtime inside successful substitution | N/A: every Byte value is legal. Public Import above is a runtime-phase boundary category, not Type or Runtime |

The implementation review generalizes beyond these finite sequence lengths:
eval.mbt dispatches ImportBinary directly to import_binary; imports.mbt iterates
source.bytes in order and appends one Ready Num(b.to_int().to_double()) per byte.
There is no text decoder, parser or code evaluator in that conversion loop.
Limits may stop evaluation and are outside this successful-value contract. This
is an engineering review, not a machine-checked proof or general loading claim.

## Shared static evidence, without duplicate tests

chk-import and chk-importbin have the same empty-premise form as the completed
chk-importstr judgment. Their wildcard constructor cases are unconditionally
accepted by validate.mbt, preserved by ast_convert.mbt and unrestricted by
import-specific ast_validate.mbt checks. Neither environment nor resolver is
consulted. The existing ast_test creation of all three forms is reused; its
original/exported-AST equality is not used as an independent runtime oracle.
I1-I3 and the new handmade binary construction protect adjacent boundaries.

The [matrix](SPEC-LANGUAGE-MATRIX.md) now records **three completed named static
judgments, 42 partial rows and 49 unreviewed rows**, still 70 named rules plus
24 initial prose/grammar rows. The two adjacent completions reuse the constructor
argument; they do not represent two new independently executed test groups.
CORE-IMPORT remains partial while explicitly recording its completed byte-value
sentence and listing the broader row's remaining obligations. Public stdlib
coverage stays at 35/153 partially reviewed functions.

## Executed validation identity

Test/criteria commit: `10982a4574028095c252d27365c9414293205bdf`; tree
`9e28752a51dfa60e154980351f14d77f1ce81460`. No interpreter implementation or public
interface changed. Existing Darwin arm64 tools: moon/moonrun 0.1.20260920
(914d7da), moonc v0.10.14+7d59c7ec9. All imported fixtures were self-made virtual
Bytes/callbacks; the tests performed no actual imported-file or network I/O.

One affected native debug run passed **26/26**, comprising four new groups and
22 existing groups, without adding the counts of reused assertions. Command:
`moon test spec_importbin_bytes_test.mbt ast_test.mbt language_test.mbt
evaluator_imports_test.mbt spec_import_scope_test.mbt spec_importstr_static_test.mbt
--target native --frozen --deny-warn -j 1`, with RUST_LOG=error. Root-package
moon check passed with --frozen --deny-warn -j 1. Root moon info then moon fmt
passed; no .mbti changed. Installed moon info has no -j option; its corrected
root-package invocation did no build work, and formatting ran one changed-file
task. No second semantic test run was needed after documentation/mapping changes.

| Retained artifact | SHA-256 |
| --- | --- |
| Pre-execution criteria | c65922636e24f240c585e3f5155a2c5426e53208dcdb0140a993e6d1b8503baf |
| New test file | 86ef28d64434865b8ad76b553478546fcc876a7866c0095a43b1af420b3df46d |
| Affected 26/26 log | 87401a4cbc4cddeb67eab1b97b48b8137260b9ed0411d731c7cb3ac2d95c7193 |
| imports.mbt | df4728b32aa8f9e01feb96e12ff690edd61be224cbb369e34498d5d8ebb52b56 |
| eval.mbt | f75c9e3fd45506a140711eaf21c09625dfa9879798ccc1ac40adc1f2983f55c3 |

Raw local evidence: `/tmp/moonjsonnet-importbin-bytes.eeS8aD`. Temporary logs are
not an archival delivery guarantee; tests, criteria, assertion mappings and
inspected static/test hashes are committed.

## Explicit remaining work

Canonical aliases and path resolution, cycles, full code-import isolation,
importstr/import UTF-8 decoding, cross-mode/source/value/failure cache identity
and lifetimes, host permissions/error retry/reentry, resolver replacement and
resource accounting remain outside this acceptance. Exact-request observations
do not establish those contracts. Full grammar and malformed AST metadata remain
separate obligations. No CLI exit status, release/full regression, fresh Go/C++
comparison, additional platform or remote run was executed. Compatibility remains
[unknown in the separate report](SPEC-LANGUAGE-COMPARISON-2026-10-22.md), and the
frozen af188da Linux result is not rebound to this source. No push, tag or release.
