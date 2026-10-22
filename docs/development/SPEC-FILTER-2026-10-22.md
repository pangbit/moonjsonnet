# filter: Boolean membership and retained payloads

## Frozen criteria

Base: 7445b3fea92ffb6930d837c365efc0d33786fa5a. Official Jsonnet:
bbb38f1020be1f5aed560928fb839b2c448cefb4. Scope: one coherent filter
Function/Array-head, Boolean membership, retained-order and payload-laziness
contract with separate source/handmade AST controls. No whole language,
callback application or nonboolean predicate acceptance is inferred.

The [fixed filter rule](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#execution)
requires a Function and an Array, computes retained input indices whose
applications yield true, and returns the original element expressions at
those indices. The [public filter description](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#std-filter)
returns an array of all selected input elements. We read this array-filter
operation as the retained input subsequence in index order, including
duplicate-valued input positions; this is an explicit public-contract
inference, not a claim that the printed set alone states increasing j_i.
No rule/prose specifies the temporal order of independent predicate calls.
Output order and callback evaluation order are separate assertions.

The [fixed Array value/laziness description](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#array)
leaves individual elements lazy. To produce filter's finite Array head,
however, all membership decisions must be available to determine its retained
index list; length or first-output demand cannot skip an as-yet-needed
membership computation. A demanded predicate/application error prevents
that array head. Once membership is known, an excluded argument unused by
the predicate need not be evaluated; retaining an element also does not
force its payload or unrelated object fields. There is no filtering
desugaring into if here, and no competing-error order is standardized.

Existing [foundation array tests](../../spec_foundation_arrays_test.mbt)
already cover numeric selection/input preservation, empty input, non-array/
non-function errors, failed applications and retained/excluded payloads.
[Map/flatMap](../../array_std_test.mbt) and [fold](../../stdlib_contract_test.mbt)
controls remain separate: map can defer applications, whereas filter needs
membership results; fold's tailstrict accumulator is not a filter rule.
Reuse those assertions without replaying whole files. Their historical
539/539 execution belongs only to 5651ae9, not the present enlarged suite.
Only missing independent-AST combinations and discriminating timing/order
cases are new.

The [existing array-combinator adjudication](SPEC-ARRAY-COMBINATORS-REVIEW.md)
and [public inventory mapping](../../tests/spec-public-coverage.json) already
leave nonboolean filter results unresolved. A rule selecting true-returning
indices does not expressly distinguish rejecting nonbooleans from excluding
all non-true values; the public prose does not add that result-domain premise.
The Boolean-only if rule cannot simply be imported into this builtin. The
[old boundary observations](../../tests/spec-array-boundary-observations.json)
are not expectations or passing evidence and are not replayed. The project's
[compatibility policy](../reference/COMPATIBILITY.md) separately requires
Boolean predicates; it is not a fixed official domain clarification. This
batch therefore adds no hardcoded nonempty nonboolean rejection assertion
or new conformance credit for it. Empty input with a number-returning
Function is decidable: no predicate application occurs, so no nonboolean
result has been produced. That case must remain distinct from an invalid
non-Function argument head, even when the input is empty.

| Probe | Independent required outcomes |
| --- | --- |
| FL1: retained subsequence | All eight Boolean masks on input labels [20,10,20] select the literal expected subsequences, preserving multiplicity, unsorted order and original input. Object poison fields are never required by membership or label projection. |
| FL2: classification versus payload | Constant false discards erroneous element expressions untouched; constant true preserves three lazy slots, their shape and the safe middle element through aliases. Reading the first retained bad slot raises retained-payload. A later required membership error prevents length and first-result field access before premature-payload can be forced. Only one predicate fails, so no relative callback order is asserted. |
| FL3: heads/application/phase | Every non-Function kind fails Type even for empty input; non-Array kinds fail Type. Isolated Function/Array head errors propagate. Empty input never applies an erroneous or number-returning Function. A wrong-arity Function on nonempty input fails when membership is required even under length, unlike makeArray's delayed element application. Unknown names in an empty unused predicate still reject Static. |

All new trees use public AstKind constructors separately from source, with
neutral ordering_*/sequence_*/object/function builders. Masks, output vectors
and markers are literal; no parser export or evaluator result is an oracle.
Error category names are embedding phase controls, not standardized wording.
The whole filter call stays lazy when unused. General named/default/strict
callback protocols, resource limits, every child static/evaluation judgment
and the unresolved nonboolean-result domain remain outside this decision.
The public-subsequence reading is not a complete formal proof of the rule's
set enumeration, so no whole named-rule completion will be recorded.

Use only bounded native debug, nice 10, -j 1, no test parallelization,
steps=20000/depth=64/stack=96 and at most three input elements. No full suite,
release/Linux/remote/browser/install/push, private document, new dependency
or fresh Go/C++ run. Preserve any first failing regression before a minimal
product repair; otherwise change only tests/evidence/matrix. A0/B0/N0/R0/PE0
stay unadjudicated. Results follow this exact frozen prefix.

<!-- Criteria above are frozen before execution; evidence is appended below. -->

## Execution and adjudication

The first directed native debug run passed **3/3, exit 0**, in 5.596 seconds:

    nice -n 10 env RUST_LOG=error moon test spec_filter_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize

FL1 matches all literal mask/subsequence vectors, including the deliberately
unsorted duplicate labels and the unchanged original array. Neither selection
nor value projection reads a poison field. FL2 discards ignored erroneous
arguments, keeps erroneous retained slots lazy and permits the safe middle
slot through aliases. Actual bad-slot demand raises retained-payload. The
single membership-required failure prevents both length and first-result
field access before premature-payload can be read, independent of the order
in which the predicates themselves run. FL3 distinguishes required heads,
empty uncalled bodies, ordinary predicate-application arity failure and
Static checking of an unused zero-input predicate. The empty number-returning
Function is not invoked, so it produces no nonboolean predicate result.
Source and independently constructed AST entries agree.

No product defect was observed. Product code, public .mbti and all existing
test files stay unchanged; there is no interpreter fix, semantic rerun or
old-file/full-suite execution. Implementation inspection confirms that the
filter branch requires Function/Array heads, calls the predicate to decide
membership and retains original thunk references. The implementation loops
in input order, but that temporal behavior is not promoted to a universal
callback-order requirement. Native callback counts in reused historical
tests likewise remain embedding traces. Map's deferred applications and
fold's strict accumulator are not substituted as filter semantics.

Nonempty nonboolean predicate results remain the *existing* unresolved
public-array question. The fixed rule/prose does not newly establish a
Boolean-result rejection premise, and applying the separate conditional
rule would add an interpretation. The prior observations and public mapping
are unchanged byte-for-byte, no old CLI probe is replayed and no new
nonboolean rejection assertion or passing evidence ID is added. The
project's Boolean compatibility policy remains separate from this official
normative gap. The stable public-subsequence reading above supports these
bounded order controls, but is not an unconditional proof that the printed
set enumerates j_i in increasing order. No full filter-rule completion is
recorded. Required Boolean-domain callback errors propagate; this is not a
license to treat every non-true/failed result as false.

Native check, required info then fmt, script fmt and matrix validation all
exited 0. No completion form/schema or inspected source changes, so prior
metadata negative suites are not repeated. Only filter gains a scoped
partial row. The [94-row matrix](SPEC-LANGUAGE-MATRIX.md) is **14 completed
named reviews (6 static, 8 evaluation), 1 relative prose constructor, 62
partial and 17 unreviewed rows**. Existing named decisions and A0/B0/N0/R0/
PE0 remain unchanged; test or member counts are not conformance rates.

A minimal later-adjudication note is appended to the historical array
combinator review: its old makeArray undecided paragraph belongs to that
earlier baseline and is superseded only for direct makeArray cardinality by
the accepted 7445b3f review. Range and nonboolean filter questions are not
implicitly resolved. This is navigation/provenance clarification, not a
reopening of makeArray, an observation rewrite or a public-inventory upgrade.

Raw: /tmp/moonjsonnet-filter.f34dviax. baseline.json/before-run.json pin the
clean base/tree, fixed public source hashes, reused files, old observations,
test, criteria, argv and evaluator budgets. first-result.json retains the
actual first 3/3 result; checks.json and matrix/validation.json retain local
metadata outcomes. Criteria-prefix SHA-256:
6b8ce851d5521ce82dc36b56a7af3f725e3eccb67ca0659c7a4e7a0fb115c616;
executed test: 448e73f9a5810e72eecad905c9cffed2446d6a4e5b7acd8ac03e7070d31362fc;
passing log: 97372d6d024ba8fb9a214e3a9a3495ca88a0631086280e8b2271682e11ea6fb0.
The frozen prefix and test remain byte-for-byte unchanged, and the old
review prefix is preserved. documentation-result.json and final result.json
retain tracked/staged-only documentation checks and exact commit/readback.
All issued workers are sequential and awaited. Tools remain moon/moonrun
0.1.20260920 (914d7da), moonc v0.10.14+7d59c7ec9, Darwin arm64. Historical
539/539 belongs only to 5651ae9, not this enlarged suite. Temporary evidence
is not an archival guarantee; committed criteria/tests/metadata retain scope.

Next distinct candidate: length-object's visible-field count transfer,
composing the reviewed object-fields-ex and length-array children while
mapping existing hidden/assertion-laziness controls. It has not started here.
