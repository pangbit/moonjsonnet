# Array ordering: bounded source and AST evidence

**Decision: the predefined finite array-ordering group is reviewed complete.**
Source and independently constructed typed ASTs agree on empty/prefix cases,
nested first differences, necessary element demand and static/runtime error
boundaries. The [pre-execution criteria](SPEC-ARRAY-ORDERING-REVIEW.md) fixes
the scope and literal oracle. No interpreter change was required and no named
rule or constructor-transfer completion is added.

## Fixed oracle and retained controls

The [official specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#execution)
at bbb38f1020be1f5aed560928fb839b2c448cefb4 defines five cmp-array branches
(2448-2510): both arrays empty; only the left empty; only the right empty;
different first elements; equal first elements followed by recursive tail
comparison. The < and <= rules (2360-2378, 2404-2420) expose the resulting
sign without requiring a registered std.cmp function. Scalar child rules
(2514-2538) and numeric prose (2796-2804) supply ordinary integer and
Unicode-codepoint order. The
[language reference](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md)
independently states lazy array elements and the shorter-prefix/first-difference
definition (202-222). Static all-element/two-operand traversal follows chk-array
and chk-binary (1613-1617, 1674-1682).

The earlier [language syntax test](../../language_test.mbt) already has one
ordinary nested < result. The [array source-function tests](../../array_std_test.mbt)
have basic internal comparison-helper results, an empty-helper result and
broad error controls. Existing numeric-library and array-laziness reviews keep
their original scope. Those tests are retained controls, not rerun results in
this batch. The missing operator/handmade-AST combination includes skipped
erroneous tails and observed recursive demand; it does not declare internal
helpers or sorting accepted public contracts.

## Actual outcomes

The [new tests](../../spec_array_ordering_test.mbt) use Array, Binary, Local,
Fail and Call constructors separately from source generation. No tree is
exported from the parser. Shared fixture literals describe inputs; the
expected booleans are literal pairs, not results of a host or interpreter
comparison. Both entry paths use the same virtual ordering-entry identity.

| Probe and necessary branch | Actual (<, <=) result through both entry paths |
| --- | --- |
| AO1: empty / empty | (false,true), the equal sign |
| AO1: empty / [error] and its reverse | (true,true) / (false,false), with no payload failure |
| AO1: [1] / [1,error] and its reverse | (true,true) / (false,false), with the unmatched payload unforced |
| AO1: first elements 1/2 and 2/1 | (true,true) / (false,false), with both erroneous tails unforced |
| AO1: equal finite nested arrays | (false,true), including equal nested nonempty and empty arrays |
| AO1: nested first difference | (true,true), with error-valued inner and outer tails unforced |
| AO1: equal nested prefix, then outer 2/3 | (true,true); the outer deciding pair is reached |
| AO1: nested empty / nonempty | (true,true), without the nonempty nested payload |
| AO1: U+E000 / U+1F600 after an equal numeric prefix | (true,true), consistent with codepoints rather than UTF-16 code-unit order; later errors stay lazy |
| AO2: observed nested common prefix | Both operators return true. Only L0/R0, LN0/RN0 and LN1/RN1 are present; LT/RT are absent |
| AO2: the same comparison in an unused binding | 42 with an empty observation map |
| AO3: required outer, equal-prefix and nested explicit errors | Runtime with exactly outer-left, outer-right, required-left, required-right or nested-required as applicable |
| AO3: noncomparable or mismatched operands | Type for boolean/null elements, mixed number/string and number/array elements, and array/non-array outer partners |
| AO3: the same parse-valid failing expressions unused | 42 through both entry paths |
| AO3: unknown names in either skipped array tail or binary operand | Static at Program creation, also under an unused binding, for both operators and entry paths |

Observation maps collapse repeated IDs. Membership establishes necessary prefix
demand and omitted tails without prescribing left/right callback order or a
universal callback count. Each explicit failure fixture has only one demanded
error, so no order among independent failures supplies an oracle. Runtime/Type
categories, the entry identity and literal error markers are embedding phase
controls; the specification's execution model uses successful versus stuck
evaluation. No malformed-source Syntax equivalence or full static constructor
is claimed. Every evaluation has steps=5000, depth=48 and stack=64, with finite
arrays of at most three elements.

## Dataflow review

eval.mbt evaluates the two operand containers and passes them to the binary
operator. Array literals store element expressions as pending thunks; they do
not manifest or evaluate every element. operators.mbt dispatches < and <=
through compare_values and converts a negative/zero/positive result to the
appropriate boolean.

compare_arrays visits only the common index range, forces the current pair
and recursively compares it. The first nonzero child result returns
immediately. If every common pair is equal, the two lengths decide. A zero
common range therefore implements the three empty cases without touching
payloads, and equal prefixes reach the length case without forcing unmatched
elements. Recursive array values use the same path. Ordinary numeric children
use Double comparison; string children use codepoint arrays. The selected
integer and codepoint controls do not prove every scalar producer or value.

AST conversion preserves binary children and ordered array elements. Scope
validation visits every array element and both binary operands before
evaluation, independently of later comparison demand. These paths and the
observed needed-prefix/skipped-tail distinction support the selected contract
beyond a passing group count. No product defect was observed.

## Execution identity and preserved first failure

Base source: 27ddda4daaed67ede29779efed49b5fd6e79c448, tree
d6bd7e3485dae5022104eaff4dea1052d66131d7. Raw records are in
/tmp/moonjsonnet-array-ordering.4zpc310f. baseline.json pins the clean start,
selected implementation, existing controls and official sources. before-run.json
and test-before.mbt preserve the original new inputs.

The first directed invocation exited 1 **at compilation**, before semantic
tests ran: the new ordering_program helper used an open raise annotation,
which made its JsonnetError-only catch a partial match under --deny-warn.
The sole correction was the helper signature:

    ) -> @moonjsonnet.Program raise {
    ) -> @moonjsonnet.Program raise @moonjsonnet.JsonnetError {

This is a test-only exception annotation, not a changed oracle, weaker check
or interpreter fix. focused-tests.log, focused-result.json and the original
test/manifest retain the failure. signature-only.diff and
test-after-signature.mbt retain the exact correction. before-semantic.json
pins the corrected bytes; criteria and expected outcomes are unchanged.

The second invocation, the **first semantic execution**, passed **3/3, exit 0**:

    nice -n 10 env RUST_LOG=error moon test spec_array_ordering_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize

focused-semantic-result.json and focused-semantic.log bind that result to the
corrected test. Source/AST variants within these three groups are not separate
rule completions. No semantic rerun followed matrix/documentation changes.
Measured local tools were moon/moonrun 0.1.20260920 (914d7da), moonc
v0.10.14+7d59c7ec9 on Darwin arm64.

| Subsequent check | Result |
| --- | --- |
| Native root type check | Exit 0 with --frozen --deny-warn -j 1 |
| Info then fmt; script fmt --check | All exited 0; tested bytes unchanged and no .mbti changes |
| Matrix validation/regeneration | Exit 0 on first invocation; assertion anchors, source hashes and existing completion records validated |
| Tracked/staged-only documentation checker | Exit 0: 162 files and 1199 local/current-source links; root layout, language candidates, README parity and migration targets passed |
| Whitespace and exact file scope | Staged/worktree diff checks passed; exactly the seven intended new-test, criteria, evidence and matrix files |

The sequential checks used reduced priority and one worker where supported;
installed info/fmt expose no worker-count option. checks.json and individual
logs preserve their actual commands and exits.

## Matrix decision and remaining scope

All 94 inventory IDs remain: 70 named rules plus 24 initial prose/grammar
obligations. Thirteen previously unreviewed named rows and EXEC-OPERATORS
receive bounded subset evidence; STATIC-TRAVERSAL gains the adjacent unknown-name
controls. These are **14 unreviewed-to-partial transitions, zero new completed
judgments**, not fourteen newly conforming rules. Existing completion records
are unchanged. The [matrix](SPEC-LANGUAGE-MATRIX.md) now has **8 completed named
reviews, 1 constructor transfer relative to children, 55 partial rows and 30
unreviewed rows**. Whole-language conformance and inferred execution stay false.

The five finite array branches are covered as this group, but no generic
constructor-transfer record or whole head/scalar child judgment is asserted.
Direct scalar operands, other relational operators, complete numeric/Unicode
boundaries, sorting, equality, public comparison helpers and host cycle/resource
policies remain outside this decision. No public-library completion is added.
[Go/C++ comparison](SPEC-LANGUAGE-COMPARISON-2026-10-22.md) remains separate and
unknown for these new probes. The
[assertion adjudication](SPEC-OBJECT-ASSERTION-ADJUDICATION-2026-10-22.md) and
N0/R0 remain unchanged; these paths contain no assertions or self/super.

A distinct next candidate is the four still-unreviewed boolean &&/|| rules:
shortcuts, required right-hand demand and static-versus-runtime boundaries.
Existing lazy controls should be reused rather than expanded into more array
or object microgroups. That candidate has not been started here.

| Identity | SHA-256 |
| --- | --- |
| Pre-execution criteria | 19e47fa9cf82b1cacbbe82009eae5407d2186024dbda19405de00467da64fe90 |
| Original test rejected by compile gate | cf095d28243a189fdf781e71b42df8cf2e4e85a664fd5a9ca09a6a1596580242 |
| Signature-corrected, executed test | b0734a9fca7196cc28c1f11800c874edb1373b86fe73acb9d02c1b3d1e13361a |
| Preserved first compile log | 2c9befbc7f15f450774f250646a1a52d5d05e9c2cc65eb943b02d55d7f4b94bf |
| Passing semantic log | 97372d6d024ba8fb9a214e3a9a3495ca88a0631086280e8b2271682e11ea6fb0 |
| operators.mbt | a93a2d005dd74b7a07ac9fa6d1a585a4fda46d7a8ce6c97dda8e3c83a30b3209 |

Temporary records are not an archival guarantee; committed criteria/tests and
the [machine-readable matrix](spec-language-matrix.json) preserve the accepted
scope and oracle. Summary log hashes alone do not identify executed source.
All fixtures are synthetic and use no imported/private files or network I/O.
Standard/default, one worker and reduced priority were retained. No full suite,
remote/browser/CLI run, installation, push or tag occurred. Product code,
dependencies, existing test files and public interfaces are unchanged.

## Comparison core constructor closure

The later review closes seven named comparison constructors, relative to their
stated child judgments. It supersedes the earlier absence of named-rule decisions
for these seven rows only. The fixed [execution rules and numeric prose](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#execution)
(2448–2538, 2796–2804) supply the definitions; implementation results are not the
oracle. AO1–3 and [RS1–3](SPEC-RELATIONAL-SIGN-2026-10-23.md) retain their original
executed evidence and hashes, without being rerun for this closure.

| Named judgment | Constructor argument | Independent witnesses |
| --- | --- | --- |
| cmp-number | The explicit less/greater/otherwise branches exhaust admitted finite IEEE values, including equal signed zeros. No subtraction or conversion supplies the sign. | CC1, CC3–4, RS1/3 |
| cmp-string | Compare codepoints at the first unequal position; equal common prefixes reduce to codepoint length order. | CC2–4, RS1/3 |
| cmp-array-left-empty | Zero common length skips payloads; shorter left length has negative sign. | AO1/3, RS2 |
| cmp-array-right-empty | Zero common length skips payloads; longer left length has positive sign. | AO1/3, RS2 |
| cmp-array-both-empty | Zero common length and equal lengths produce zero sign. | AO1/3, RS2 |
| cmp-array-first-different | The first nonzero child result returns immediately, preserving its sign without reading either tail. | AO1–3, RS2/3 |
| cmp-array-first-equal | Each consumed pair has zero sign; advancing one index is the recursive tail judgment. Exhausting the common prefix leaves the same length order. | AO1–3, RS2/3 |

For the last rule, induction on the finite common-prefix length establishes the
loop invariant; nested comparisons assume their own child judgments. The private
Int result represents the abstract result by `sgn`, not by a required magnitude:
the SDK Compare contract promises negative/zero/positive, and `c != 0`, immediate
return and the three `<`, `<=`, `>=` consumers preserve this abstraction. Admitted
Strings iterate Unicode codepoints; producer encoding and unmatched surrogate
representations are separate. Required head/child failures and skipped tails
remain explicit; Runtime/Type markers are additional embedding checks.

At unchanged source `3bf2a62b26ffb297d3fe0c24505db6e97b09ba04`, the sole new native
selection passed **4/4**, exit 0 (9.817 s), after check/outline exited 0:
`moon test spec_comparison_core_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize`.
The [new fixture](../../spec_comparison_core_test.mbt) SHA-256 is
`eba515de8347ecc020ff9324f7148a0dbdab6f166a1f6f4b1b8daa9399c4bd71`;
unchanged operators.mbt is `a93a2d005dd74b7a07ac9fa6d1a585a4fda46d7a8ce6c97dda8e3c83a30b3209`.
No product defect or fix was found. Full/release/Linux, CLI, consumer and Go/C++
runs were not performed for this batch; whole-language acceptance remains open.

The restricted `comparison-core-transfer` metadata pins all seven exact statements,
roles, admitted domains, abstract signs, child premises and current inspection/test
hashes. All six `core-` negative controls rejected before output; final positive
readback exited 0 (5.614 s), verified 229 test IDs and the 35 completed named,
1 relative constructor, 56 partial and 2 unreviewed rows, reusing the six
hash-verified negative results without rerunning them. Two prior positive
failures remain preserved: the missing pinned stdlib.html was supplied unchanged,
and the wrapper's Object assumption was corrected to the existing single-element
Option Array representation without changing record content. The final
`core-controls-fixed-positive/result.json` SHA-256 is
`7f912f0ad3fa588c1c5861fb4d56510c7c829590e2a6144dfc312feb6c62f9cb`;
no semantic test was rerun during metadata validation.
Exactly sixteen old stdlib inspection hashes in length-object, object-has-ex,
object-fields-ex, length-string, length-array and type-object are rebound from
`a151cb46f68753d60cdc3c9fac5979b056c68832c5486883e91226d3c847ab4a` to
`078d0c869808096e54d1a1bd92196dbc34e19e9ea4fe91e51505e3ea45b96950`:
the historical/current files differ only in the equals parameter-label split,
so every inspected body, argument, decision and witness is unchanged. A0 and the
printed greater-than conflict remain unresolved; PE0/B0/N0/R0 and all unrelated
rows retain their status. No public std.cmp API, arbitrary producer, cycle/resource,
callback-count or independent-error-priority contract is added.
