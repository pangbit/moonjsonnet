# makeArray and bounded PE0 adjudication

## Frozen criteria

Base: 56ef58b5f37ba60ba2b73de445b5ce4645d0116b. Official Jsonnet:
bbb38f1020be1f5aed560928fb839b2c448cefb4. This batch first reviews PE0's
applicability question, then tests one makeArray cardinality/function/lazy
element contract. The pre-run manifest pins this exact criteria prefix.

### PE0: applicability review before new execution

Sources: fixed spec [operational semantics](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#semantics),
[Value grammar](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#jsonnet_values),
[primitiveEquals rule](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#execution),
[== desugaring](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#desugaring),
[official equals source](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1582-L1616),
[stdlib introduction](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html)
and [language equality/equivalence](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#equivalence-and-equality).

The notation review finds v explicitly ranges over Value = Primitive union
Object union Function union Array (spec.html 1809-1857). Runtime errors are
modeled as stuck execution (1760-1767, 2845-2851). That explains missing
derivations; it does not make a matching rule disappear. The primitiveEquals
rule (2606-2614) has two value premises and the result equation
`b = primitive(v) AND v=v'`; primitive membership is not a separate
applicability premise. No separate primitiveEquals entry exists in this
version's stdlib.html; its introduction delegates primitive builtin behavior
to the spec. The four fixed texts do not explicitly define the metavalue
equality relation's domain or state it is restricted to Primitive.

Therefore the proposed automatic resolution, "only primitive pairs have a
rule, other values are stuck", is not established by the written rule.
It could be made consistent by explicitly defining metavalue equality as
partial outside Primitive, but that is an extra applicability assumption.
Nor may language == be silently substituted for the mathematical relation
v=v': they are different levels and the text gives no such definition.

The precise conditional conflict uses the *same* function value F:

1. With total mathematical equality on Value and ordinary Boolean logic,
   primitive(F) is false, so the printed equation yields false for
   primitiveEquals(F,F), irrespective of F=F's truth value. This reading is
   applicable to all admitted same-function values, without running a body.
2. The fixed equals source sends equal function type names through its final
   primitiveEquals call, and == desugars to that equals. Thus reading 1 makes
   F==F false. But language.md 99-107 defines false as unequal, makes a value
   observationally equivalent to itself, and says equivalent values cannot
   be unequal; it also disallows checking function equality. For this same
   F, that account cannot permit a false equality result.

Those two conclusions cannot both hold under the total-relation reading.
The partial-relation interpretation can avoid conclusion 1, but no found
fixed passage selects it or specifies its nonscalar domain. Arrays/objects
are not automatically subject to the function == restriction: their
primitiveEquals rejection needs its own relation-domain justification.
Thus PE0 is refined to an underdefined **metavalue equality/applicability
domain**, with a conditional function self-equality contradiction, rather
than an unconditional claim that every nonscalar conflicts with language
equality. Minimal clarification: does v=v' in this rule apply only to
Primitive pairs (and what happens on Array/Object/Function), or is it total,
in which case how is F==F reconciled with the fixed delegation/prose?
This is not strictly decidable from the located same-version texts.
No new implementation comparison, six-null replay, upstream contact or
product change is justified by this review alone. Original null history
and A0/B0/N0/R0 remain intact. No new PE0 semantic expectation is added.

### makeArray: independent oracle and existing coverage

The [fixed makeArray rule](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#execution)
requires both e down n and e' down f in Function, returning an array of
applications f(0) through f(n-1). The
[public contract](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#std-makeArray)
requires an array of sz elements initialized by func(index). The
[Array description](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#array)
gives finite lengths and lazy elements. A finite array's cardinality is a
nonnegative integer: a negative/fractional sz cannot be the result's element
count, so successful clamping/truncation violates this size contract. This
is a cardinality inference from the public contract, independent of local
or Go/C++ behavior; the printed rule does not separately spell out n's domain.
Negative zero is numerically zero. Invalid size kinds cannot denote a count.
The f-in-Function premise is required even when n=0; its body is not required.
Only an actual selected element requires that callback application/arity.

Reuse [array construction tests](../../spec_array_build_test.mbt) for
indices, defaults, zero-size head checks, deferred body/caching and bounded
allocation; [sequence tests](../../sequence_test.mbt) for lazy arity and
[slice/API tests](../../spec_array_slice_test.mbt) for generic call boundaries.
The old sequence test's makeArray(-1, f) => [] is an implementation expectation,
not a normative exception to the cardinality contract. Preserve its original
file and the first new failing regression before any necessary minimal fix.
Other old evidence is mapped without rerunning all files; 539/539 still
belongs only to 5651ae9, not this later enlarged suite.

| Probe | Independent required outcomes |
| --- | --- |
| MA1: size and indices | The fixed affine initializer returns [], [5], [5,15,25] for 0/1/3; -0 yields []. No unrequested index is manufactured. |
| MA2: invalid cardinalities | -1, -2 and 1.5 reject Runtime rather than return a differently sized array; non-Number size kinds reject Type. Erroneous initializer bodies are not invoked. Unused whole calls remain lazy. |
| MA3: heads versus bodies | Zero still requires a Function head and propagates a function-head error; invalid function value kinds reject Type. A size-head error propagates separately. Zero/length-only valid functions do not execute bodies; unknown initializer names still reject Static even at zero and unused. No competing-error order is required. |
| MA4: actual element application | Shape length 3 and repeated index 1 yield [3,21,21] while other bodies error; actually requesting index 0 raises its marker. A two-required-formal Function can make an empty array and a one-element shape, but demanding that element fails at ordinary application. This is not whole function-call conformance. |

Every new source and public typed AST is built independently with neutral
ordering_*/sequence_*/reflection helpers; no parser export or observed output
generates an expected answer. Error kinds/marker strings are embedding phase
controls; wording, error priority, callback side-effect order, host-size
limits and all generic application/static judgments remain separate. Only
bounded sizes -2 through 3 are evaluated; no huge allocation is requested.
This batch does not claim whole-language, numeric rounding, API or Go/C++
conformance. Tests use native debug, nice 10, -j 1, no parallel test execution,
steps=20000/depth=64/stack=96. No full suite, release/Linux/remote/browser,
installation, push, private document or new dependency is included.

<!-- Criteria above are frozen before execution; evidence is appended below. -->

## Execution and fix

The first directed run against the unchanged interpreter completed **4
groups: 3 passed, 1 failed, exit 2**. MA2 stops at its first source -1 case:
the unused whole call succeeds as intended, but actual constructor demand
returns successfully instead of rejecting the impossible cardinality. The
original sequence test also expected [] for that input. Both original files,
the frozen oracle and the first failure are retained. Later MA2 fixtures
are not presumed to have executed before this first failure.

The minimal product fix adds only a size<0 Runtime guard after the existing
integer check in the makeArray branch. No callback body, generic invocation,
argument-head evaluation order, zero-size path or other builtin is changed.
The old negative-size [] example is moved, with its input unchanged, to the
existing Runtime rejection table. This expectation change follows the
pre-run sz-element/cardinality criterion, not observed fixed output or a
lowered threshold. It intentionally changes that historical compatibility
behavior; fresh Go/C++ compatibility is unmeasured.

The **identical** new test then passed **4/4, exit 0**:

    nice -n 10 env RUST_LOG=error moon test spec_make_array_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize

MA1 yields the fixed positional outputs and -0 empty case. MA2 rejects both
negative integers, the fraction and every other value kind at the intended
Runtime/Type boundaries without calling the initializer body. MA3 requires
valid/function heads even at zero while preserving body/whole-call laziness
and Static admission. MA4 demands only the selected initializer application;
shape formation does not pre-run a missing-argument call. Separate actual
element demand raises its marker or ordinary application error. No extra
element is forced to satisfy the oracle.

Two directly adjacent files ran once, sequentially with the same native
debug/frozen/deny-warn/nice 10/-j 1/no-parallelize flags: sequence_test.mbt
**5/5** and spec_array_build_test.mbt **4/4**, all exit 0. The latter includes
its existing large requested-size allocation rejection, bounded at 5000
steps with zero initializer calls; only the new MA fixtures have sizes -2
through 3. No unbounded allocation or full suite was run. The final directed
results are four new groups plus nine adjacent groups, not an enlarged-suite
result or new whole-library acceptance.

Native check, required info then fmt, script fmt and matrix validation all
exit 0. No public .mbti changes. Only the makeArray branch differs in
stdlib.mbt; all bytes outside that branch and all reviewed anchors remain
identical. Existing length-array/string and object-has-ex/fields-ex reviews
retain their scope/children and are re-pinned from source hash
279bd70043cce3a665ab9699b70c5109dcb6ec4ee9b5d8ffcb273c869684e224 to
c98c92f45860380fed4e259d125b2df098393b7808fcc7d5b764cf576bbf6499.
The raw inspection-review.json preserves the arm comparison and rationale;
no old completion is broadened. No metadata schema change or negative-suite
repetition is needed.

## PE0 disposition and remaining scope

The applicability review above is complete as a bounded text review, with
no new PE0 runtime experiment. The value rule at spec.html 2153-2160
explicitly includes Function and derives F down F, so both value premises
are available for the chosen same-function witness. Stuck execution cannot
by itself supply the missing Primitive-only applicability premise. A partial
metavalue relation remains a possible interpretation, not a located fixed
definition. Thus the minimum unresolved question is exactly that relation's
domain (or a correction reconciling the function result/delegation/prose),
not whether a current implementation rejects. The function contradiction
is conditional on the total-relation reading; Array/Object applicability
must not be inferred from a language-level function restriction. The
[prior PE0 record](SPEC-PRIMITIVE-EQUALS-2026-10-22.md) gains only this
clarification; its original text/history and six null raw outcomes are
preserved, with no new rejection assertion or equality product edit.

The [94-row matrix](SPEC-LANGUAGE-MATRIX.md) is **14 completed named reviews
(6 static, 8 evaluation), 1 relative prose constructor, 61 partial and 18
unreviewed rows**. makeArray gains a bounded partial contract, including the
repaired negative cardinality and source/AST demand boundaries. General
count conversion/host limits, arbitrary Function/native/default/strictness
interactions, producer/invocation/static judgments and std rebinding remain
outside this decision. PE0 stays explicit and A0/B0/N0/R0 are unchanged;
neither test counts nor source matches establish whole conformance.

Raw: /tmp/moonjsonnet-make-array.h_j3sbd6. baseline.json/before-run.json pin
the base/tree, original source/old expectations, fixed public sources, test,
criteria, argv and budgets. first-result.json preserves the original 3/4
failure; post-fix-result.json and adjacent-results.json retain actual passes;
checks.json and matrix/validation.json retain metadata results. Criteria
prefix SHA-256:
d0f3ca58b97b47708a471e0a0c82bad11af23b3966c0307309d0e51a3d974827;
unchanged pre/post-fix test:
2528ec26e9449cd6bc1a9acb2819258c79dca4d24d1916b3a263008a0c867554;
first failure log: bdf0274b253b5f8f7f13bb5e347982639cf844f1101684e9b363cb377ec60431;
passing log: 68e3eed91ee5d217ff66600d731275bc52d0148ef97ff479d64faef8d2e15499.
The frozen prefix/test and prior PE0 raw hash are unchanged. One transient
exec recovery failure occurred before its first read command started, so
its later mutations did not run. A successful readback confirmed the two
product/test files matched baseline and no post-fix input existed; only then
was the fix applied once. All issued processes were awaited. Final
documentation-result.json and result.json retain tracked/staged-only docs
validation and exact commit/readback status. Tools remain moon/moonrun
0.1.20260920 (914d7da), moonc v0.10.14+7d59c7ec9, Darwin arm64. Historical
539/539 still belongs only to 5651ae9. Temporary raw files are not archival
guarantees; committed sources/criteria retain the failure, repair and limits.

Next distinct candidate: filter's predicate demand, stable retained indices
and element laziness, first mapping existing sequence controls. It has not
been started here. PE0 should await normative clarification rather than
further identical implementation probes.
