# Object reflection Ex: combined review and evidence

## Frozen criteria

Base: 21c90e35e4d8ecf3c28022e731e982182745b082. Official Jsonnet:
bbb38f1020be1f5aed560928fb839b2c448cefb4. The coherent contract is
object-has-ex/object-fields-ex over evaluated objects, field names and a
Boolean hidden flag, with source/independent-AST and public wrapper controls.

The [fixed rules](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#execution)
define membership by `exists i: f=f_i and (h_i != :: or b')`; enumeration is
the set of names satisfying the same predicate, in nondecreasing order.
The specification defines f as a String; the Boolean connective requires a
Boolean flag. The object-value description leaves field payloads and
assertions unevaluated. These queries require the object head/name/flag,
not field values. Distinct failing arguments are tested separately; no
premise ordering or callback execution order is inferred from the formulas.

The [fixed hidden-inheritance law](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#hidden_inheritance)
preserves the prior separator when the right separator is `:`, otherwise
uses the right separator. The [language visibility description](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#visibilities)
defines hidden/default/forced-visible and makes field values irrelevant to
visibility. The [official wrapper definitions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1558-L1568)
map objectFields/objectHas to Ex(false), and their All variants to Ex(true).
The [public objectHas documentation](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#std-objectHas)
also states object/String type requirements. Exact String/codepoint order,
not normalization or grapheme equivalence, determines names and sorting.
No Go/C++ or observed local output supplies an expected result.

Reuse the unchanged [source reflection tests](../../spec_object_reflection_test.mbt):
missing/null/empty/null-key omission, all nine separator combinations,
unique inherited Unicode sorting, field/assertion callback non-execution,
object/name type errors and required computed names. Reuse the direct Ex
source example in [object_std_test.mbt](../../object_std_test.mbt).
Their existing 539/539 execution belongs only to 5651ae9 Mac native debug;
it predates later new tests. No fresh whole suite or repeated old reflection
file is needed. The callback assertion evidence remains scoped; it does
not resolve N0 assertion-super rewriting or R0's paper reentry model.

Only missing direct Ex/handmade-AST combinations are new:

| Probe | Independent required outcomes |
| --- | --- |
| EX1: inherited sets and lazy values | Empty has no keys; hidden-only has keys only with hidden=true. Three layers yield visible [h,n,new], all [a,h,n,new,x], once each. Default after hidden stays hidden; forced-visible restores visibility; null-valued n exists; null key is omitted. All four wrappers match Ex flags, no error-valued field is read. A separate actual field read must raise field-payload. |
| EX2: exact Unicode | Inherited duplicate names collapse; sorted names are empty, NUL, decomposed e+acute, composed e-acute, U+E000, U+1F600. Both accent spellings and NUL exist exactly; e and NUL+x do not. All payloads error and stay unevaluated. Source literal escaping and direct typed Strings are separate inputs. |
| EX3: demand and phase | Non-object head, non-String name and non-Boolean flag fail Type. Object-head/name/flag/computed-key errors propagate their single marker even on empty or missing queries; an unused whole call stays lazy. A statically unknown hidden payload rejects Static even when the call is unused. No multi-error order is asserted. |

New trees use public AstKind constructors with field separators mapped to
1/2/3, not parser exports. Neutral ordering_*/sequence_* helpers provide
construction/evaluation only; all expected arrays/Booleans/markers are fixed
above. Ex positional calls are normative controls; private/native keyword
parameter spellings, full wrapper signatures and generic application remain
separate embedding contracts. Error category names are phase controls, not
normative diagnostic wording. Existing Syntax controls need not be repeated.

If executed controls and constructor inspection close the transfer, only
the two named judgments relative to their evaluated child domains may be
recorded complete. The proof must show exact membership, deduplication,
visibility filtering and sorted ready name values without payload demand.
It assumes already admitted Object/String/Boolean values and effective
field visibility; it does not complete object producers, inheritance,
assertion closures, string/token construction or arbitrary invocation.
A0/B0/N0/R0 remain unadjudicated, with no whole-language or public-library
acceptance inferred from test counts. If the restricted metadata form is
extended, invalid rule/formula/domain/demand/exclusion/snapshot controls must
be rejected without changing real inputs.

All new fixtures are finite, one-worker native debug at reduced priority,
steps=20000/depth=64/stack=96. No full suite, release/Linux/remote/browser,
new dependency, installation, push, private document or external issue is
included. Preserve any first failure before a necessary minimal product fix;
otherwise do not edit product code. Results will be appended after freezing
this exact criteria prefix.

<!-- Criteria above are frozen before execution; evidence is appended below. -->

## Execution and adjudication

The first directed native debug run passed **3/3, exit 0**, in 6.009 seconds:

    nice -n 10 env RUST_LOG=error moon test spec_object_ex_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize

EX1 produced exactly the visible/all inherited key vectors, presence flags
and wrapper equivalents, including empty/hidden-only/null/omitted controls.
Only the separate actual read raised field-payload. EX2 preserved distinct
composed/decomposed/NUL names, unique inherited names and the literal scalar
ordering without reading any field. EX3 separated required heads/keys/flags,
Type and adjacent Static rejection from unused whole-call laziness. Source
and independent typed entries agree. No product defect or interpreter fix
was observed; no semantic rerun or old reflection-file rerun was needed.

The fixed execution prose additionally states that String comparisons are
lexicographic by Unicode codepoint (spec.html lines 2802-2804), supporting
the already-frozen ordering oracle. The constructor argument is independent
of the finite test count:

1. Vm::has_field checks exactly the union of names in the admitted object
   layers. The effective visibility fold leaves the prior Boolean on `:`,
   clears it on `::`, and sets it on `:::`. Induction over finite layers
   matches the fixed hidden-status law, without evaluating a payload.
2. objectHasEx returns union membership AND (include-hidden OR effective
   visibility), exactly the rule's existential predicate, including absent
   fields. The explicit object/name/flag arguments are forced to their
   value heads; the transfer never calls Vm::field or check_assertions.
3. Vm::keys places each layer name in a map, so each exact name occurs once;
   it filters with the identical visibility predicate and sorts with
   compare_unicode. That comparator compares the first differing scalar,
   or sequence length after a common prefix. All eligible names are emitted
   once in the required nondecreasing String order.
4. objectFieldsEx wraps those names as Ready(Str(...)) elements. No returned
   element is a deferred object field read. Thus arbitrary field expressions
   and pending assertion bodies cannot affect this transfer's result.

These close **object-has-ex and object-fields-ex relative to their evaluated
Object/String/Boolean children and admitted effective field representation**.
Their producers and generic invocation/std binding remain assumed. Reusing
the effective visibility lemma does not complete the object-inherit rule,
assertion-super N0, reentry R0 or whole field-value/static judgments. String
construction, encoding/resources, all public wrapper signatures and fresh
Go/C++ compatibility remain outside the decision. A0/B0 are also unchanged.
Error presentation and competing failing-argument order are not adjudicated.

The restricted object-reflection-transfer metadata form permits only these
two exact fixed formulas. It pins argument domains, result contract, no
payload demand, the enumeration name order, child assumptions, mandatory
exclusions, inspected source hashes and reviewed test snapshots. **8/8**
isolated controls reject wrong rule, changed formula, wrong name domain,
payload demand, UTF-16 order, missing child assumptions, missing N0/R0
exclusion and stale inspection at the intended guards before output. The
temporary tracked-source mirror never mutates real mappings or tests.
This tool validates provenance/scope metadata; the manual argument above
and executed controls support the decision, not textual matching alone.

Native check, required info then fmt, script fmt and real matrix validation
all exited 0. Product files, public .mbti, reused tests, prior evidence and
every prior completion record are unchanged. The
[94-row matrix](SPEC-LANGUAGE-MATRIX.md) now records **14 completed named
reviews (6 static, 8 evaluation), 1 relative prose constructor, 59 partial
and 20 unreviewed rows**. The two newly closed named transfers do not imply
completion of their child judgments, whole objects or the public library.
No percentage or whole-language acceptance is inferred.

Raw: /tmp/moonjsonnet-object-reflection.wot4yqlu. baseline.json/before-run.json
pin the base/tree, fixed public sources, inspected/reused files, test,
criteria, argv and limits. first-result.json is the actual first 3/3 pass;
checks.json and negative-results.json retain metadata outcomes. Criteria
prefix SHA-256:
f7fa9936cf764fa85089895255d4bc07b5610a982e277a735241fe2e6f30112f;
executed test: f3cca119cc1d990f71e63727e65f3f16c0be9f565b41d0feda9b6b86db84a141;
passing log: 97372d6d024ba8fb9a214e3a9a3495ca88a0631086280e8b2271682e11ea6fb0.
The frozen prefix and executed test remain byte-for-byte unchanged.
documentation-result.json and final result.json retain tracked/staged-only
document validation and exact commit/readback status. All workers are
sequential and awaited; local tools remain moon/moonrun 0.1.20260920
(914d7da), moonc v0.10.14+7d59c7ec9, Darwin arm64. The 539/539 integration
remains bound only to 5651ae9; it is not an enlarged-suite result at this
later commit. Temporary evidence is not an archival guarantee; committed
criteria/tests/metadata retain the contract and its boundaries.

Next candidate: the unreviewed primitiveEquals rule, first mapping existing
primitive/type-mismatch evidence and fixing the independent domain and
structure/function rejection oracle. It has not been started here.
