# Assertion super prefixes: behavior and acceptance endpoints

**Decision: the selected assertion-specific layered behavior passed review
without a product defect.** Conditions and failing messages can extract lower
function fields without changing either defining prefix or final self.
The fixed inheritance equation's assertion-prefix rewrite remains an explicit
normative gap; this report does not claim formal equivalence or complete any
broader matrix row. The
[pre-execution criteria](SPEC-ASSERTION-SUPER-REVIEW.md) fixed both the behavior
and this qualification before new execution.

## Normative source and qualification

All sources are pinned to official Jsonnet
bbb38f1020be1f5aed560928fb839b2c448cefb4. The
[language reference](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#inheritance)
at lines 368-372 defines final-receiver self and super below the current
defining layer. The
[specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html)
supplies assertion conditional/error desugaring (1351-1363), assertion demand
on indexing (2215-2228), inheritance retaining assertions (2293-2333), and
keyword substitution through functions/locals (2038-2123).

These definitions give the independently chosen layered target: a C-layer
assertion's super selects B.probe; the selected B function's own super selects
A, and both scopes keep final self=D. However, the printed object-inherit
equation unions assertions without explicitly writing a transformation of
right-hand assertions' super. The language page's unfinished-scope comment
also includes assertions. A passing target behavior does not supply the
missing formal step. No equation is silently corrected, and no upstream
behavior is used to waive this gap.

## New behavior and existing evidence reuse

[AX1/AX2](../../spec_assertion_super_test.mbt) add only assertion-specific
extraction and message demand. SP1/SP3 already cover ordinary function-field
extraction, lexical prefixes and missing/error demand. AS1-AS3 already cover
assertion condition/message self, independent receiver checks and condition
exceptions. Their mappings and previous outcomes are reused, not rerun or
added to the new test count. Neutral AST/program helpers are reused from the
unchanged assertion-self test file, with its stable virtual entry identity;
all new trees and literal expectations are independently handwritten.

| Selected clause | Actual source and handmade-AST outcome |
| --- | --- |
| AX1: assertion extraction uses its own prefix | Four layers have n=1/2/3/4. C's assertion extracts B.probe despite unusable replacement functions in C/D |
| AX1: the extracted function keeps a separate prefix and final self | B.probe observes A.n=1 and D.n=4. D.value returns 4; events are condition(1,4), payload(4) |
| AX1: successful assertion leaves its super message untouched | A.problem is an explicit error, but no message event or failure occurs |
| AX2: constructing D does not demand its assertion | With a false predicate and missing/erroneous A.problem, an explicit type guard constructs D. Metadata and unused-field modes yield object/42 with zero events |
| AX2: failure-message extraction preserves both prefixes | Actual value demand records condition(1,4), then message(1,4). B.message keeps A as its own prefix while observing self=D |
| AX2: lower message failures cannot borrow newer replacements | Missing A.problem and an explicit assertion-super-marker both reject Runtime despite B/C/D problem strings; the explicit marker survives. No payload runs |

AX2 exercises an error while evaluating the false branch's message. AS2's
message instead evaluates successfully before an Assertion failure; AS3's
Runtime arises inside the condition before any message. These are distinct
boundaries. This group finishes with scalar results/errors, so it makes no
new top-level manifestation or std.manifestJson claim.

Native observations distinguish required dependent evaluations; no first-error
order among independent assertions or universal native-call-count policy is
inferred. Runtime/Assertion tags, virtual file identity and fixed markers are
embedding controls, not standardized human diagnostics.

## Implementation argument

check_assertions iterates defining layers and uses layer_scope(id,i), rather
than the prefix associated with whichever field lookup entered the check.
That scope binds self to the full receiver and super to the prefix below i.
The C assertion therefore selects B.probe/message even when D.value initiated
the check. When those lower fields are selected, field creates scopes from
their own defining B layer, giving their bodies A as super and D as self.

Functions retain their definition environments; local saved bindings and the
wrapper functions do not introduce a new object scope. The in-progress guard
allows field selections made by an assertion to reenter without restarting
the same assertion. Finally, the false-branch gate in Vm::assertion defers
message extraction until the predicate is false and propagates its failure
before the payload. No product implementation or public interface changed.

## Object-assertion acceptance ledger

This ledger records the 260a131 batch. Subsequent
[U1 object-local](SPEC-ASSERTION-LOCAL-EVIDENCE-2026-10-22.md) and
[U2 conjunction/constructor](SPEC-ASSERTION-CONJUNCTION-EVIDENCE-2026-10-22.md)
reviews close the bounded behavioral endpoints below. N0 remains unresolved;
the U2 report also states the formal scope of self-index reentry. The original
evidence and execution results below retain their own source identity.

This ledger concerns the object-assertion constructor and its direct demand
contract, relative to the child expression/name/Boolean/error judgments. It
does not require all object, equality, stdlib or host contracts to be complete.
The matrix's DESUGAR-ASSERT row also includes expression assertions, whose
separate constructor review is stated below. A reviewed component is not
whole-row completion; reused tests have not been freshly executed here.

| Component | Current adjudication and evidence that can discharge it |
| --- | --- |
| Store assertions without evaluating them at object construction | Reviewed for the ordinary object path: O4, AS3, AX2 and eval.mbt's storage of the assertion array. Metadata/unused selection does not index the object |
| Check assertions on actual field access, including hidden fields | Reviewed: O3/O5, AS1-AS3 and AX1/AX2, plus field's unconditional check before its body. Hidden direct access is already in O3; no duplicate new hidden case is needed |
| Check before top-level JSON manifestation even with no visible fields | Reviewed for the ordinary recursive path: O3/O4 and manifest.mbt call check_assertions before visible-key enumeration. Empty, hidden-only, nested object and array cases already have independent oracles |
| Conditions and successful messages are lazy in the required branches | Reviewed: O5, AS2/AS3 and AX1/AX2. Condition error, successfully evaluated false-branch message, and message-evaluation error are now distinct |
| Assertion condition/message closure self follows the selected receiver | Reviewed ordinary function/field path: AS1/AS2 and receiver-local assertion/scope state. This includes an actually checked original before a derived receiver |
| Assertion-specific extraction preserves super prefixes | Layered behavior reviewed by AX1/AX2, reusing SP1/SP3. Formal assertion-prefix rewriting remains N0 below; behavioral passes cannot close it |
| Non-Boolean condition rejection | Can close relative to the existing conditional child review: IF4 independently covers every non-Boolean outer kind with latent payloads. eval.mbt's If and objects.mbt's assertion both evaluate the condition then call the same exhaustive runtime_types.mbt boolean helper. Its Bool arm returns the value; its only other arm raises Type before either message or payload. This is a code-path argument, not a newly executed assertion-type probe |
| Omitted messages and finite scalar/aggregate message conversion | Existing error_value_test.mbt independently checks omitted-message failure, true-condition error-message laziness, and eight explicit conversion controls. These are newly reused as AR0. objects.mbt calls the same coerce_string only after false. General conversion remains the error-expression child obligation |
| Human default-message wording | Not a semantic blocker: fixed spec lines 2845-2852 explicitly leave human error presentation unstandardized. The desugaring literal is Assertion failed; this embedding's object diagnostic is Object assertion failed. AR0 retains that distinction without calling upstream wording normative |
| Static traversal of all assertion pairs | The constructor's traversal can close relative to child checking by source review: validate.mbt unconditionally visits each condition and optional message in object scope, and ast_convert.mbt preserves all pairs. Existing normal AST controls support that route. No fresh unused-unbound-message negative control is claimed, and the child variable/binder rules retain their own status |
| Ordinary local saved function binding inside an assertion | AX1/AX2 review this lexical extraction form. This is not an object-local declaration; the latter is U1 |

The following are concrete unresolved endpoints, rather than an open-ended
requirement to test every expression shape:

| ID | Actual gap | Finite acceptance endpoint |
| --- | --- | --- |
| N0 | The pinned equation does not explicitly specify the assertion-specific super transformation | Produce a primary-source derivation or explicit specification clarification for assertion-layer prefix preservation. Until then retain the separate layered behavioral target and the formal gap. Running more Go/C++ cases cannot discharge it |
| U1 | Object-local bindings and nested-object keyword capture specifically inside assertion conditions/messages have not been independently adjudicated | Review the bind/layer-scope and nested-object substitution paths relative to their child judgments. Add one source/handmade-AST binding fixture where an object-local helper is used by both branches, an outer same-name binding cannot win, and an inner object's self remains distinct from the assertion receiver. Include the false-branch message result and an unused error-valued local; reuse existing root/function proofs instead of retesting all binders. ast_test.mbt's local/assert example only compares a parser round trip with itself and is a candidate, not an independent oracle |
| U2 | Conjunction/retention of multiple assertions from both inheritance operands, including terminating reentrant field dependencies | Inspect the complete assertion-array/layer loop and state reset. Use a finite two-assertion fixture split across operands: both true succeeds, each operand's sole false assertion separately prevents the selected payload, and field override does not remove either assertion. Include one terminating self-field dependency while a check is in progress. Do not require an ordering between two independently false assertions; spec treats object assertion order as immaterial |

U1/U2 are missing behavioral adjudications; N0 is a normative-source gap.
No defect has been established in these unresolved cases. The current code
walks every layer/pair, but source plausibility alone is not recorded as a
new passing U1/U2 scenario. Exact callback counts/order beyond dependencies,
divergence budgets, GC and persistent-session invalidation are host policies,
not additional unbounded constructor acceptance requirements. Existing
evaluator_test.mbt failure-cache/invalidation checks remain host evidence.

The object-assertion sub-contract has a definite stopping point: discharge
U1/U2 with the finite distinguishing outcomes and structural arguments above,
and explicitly resolve or retain N0 according to the normative scope being
claimed. Then record a constructor-level decision relative to its named
children, with no residual blanket requirement for all expression shapes.
A literal formal-conformance decision including super must resolve N0 first.
Completing DESUGAR-ASSERT additionally needs an explicit short expression
Assert constructor review: existing AR0 and the shared assertion evaluator
already provide controls; eval.mbt/validate.mbt must show that the continuation
is used only after success and all children are statically visited. This is
review work, not an instruction to begin another semantic campaign here.

Equality assertion interactions belong to EXEC-OPERATORS and their object
comparison rules. std.manifestJson traverses visible fields through its
library definition, whereas manifest-object checks assertions before visible
enumeration. The existing object contract audit preserves that distinction;
neither upstream agreement nor this ledger exempts either path from its own
normative obligations. Neither contract needs to be silently folded into the
object-assertion constructor's stopping point.

## Execution identity and final checks

Base source: c61772651d5ea3a7efe110baabbed2697f23bf3e, tree
a4639ff03cd211509b17ffc5c11513076a421b71, plus the new test below. The pre-run
manifest pins exact criteria, new tests, reused helper/tests and implementation
bytes. Supporting Boolean sources were additionally checked byte-for-byte
against that base. None changed during mapping or final checks.
Existing local Darwin arm64 tooling: moon/moonrun 0.1.20260920 (914d7da),
moonc v0.10.14+7d59c7ec9.

One native debug invocation passed **2/2, exit 0**, on its first run:

```sh
nice -n 10 env RUST_LOG=error moon test spec_assertion_super_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize
```

Only the two new assertion-specific groups executed. AR0/IF4, SP/AS and older
aggregate/platform outcomes are not added to that count. There was no semantic
rerun after mapping or report edits. The first matrix check rejected an
overly strict source anchor crossing formatter-inserted whitespace before
writing outputs. Correcting only that mapping anchor allowed a matrix-only
retry to pass; the original rejection is retained. No criteria, test, oracle
or product code changed for the retry.

| Final check | Result |
| --- | --- |
| Native root check | Exit 0 with --frozen --deny-warn -j 1 |
| Info then fmt; script fmt --check | All exited 0; no .mbti changes |
| Matrix validation/regeneration | Final retry exited 0; original anchor rejection retained |
| Tracked/staged-only documentation checker | Exit 0; 153 files and 1148 local/current-source links passed |
| Whitespace and exact scope | Working/staged git diff --check passes; exactly seven scoped files, with no product/interface changes |

The [language matrix](SPEC-LANGUAGE-MATRIX.md) adds only bounded mappings to
object-index, object-inherit, DESUGAR-ASSERT and SUBSTITUTION. All four remain
partial, as do all their prior states. Inventory remains **8 completed named
rules, 42 partial rows, 44 unreviewed rows** across 70 named rules and 24
initial prose/grammar rows. Whole-language acceptance and inferred execution
remain false; no public stdlib function completion is added. The
[Go/C++ comparison](SPEC-LANGUAGE-COMPARISON-2026-10-22.md) stays separate and
unknown for these new cases.

| Artifact / source | SHA-256 |
| --- | --- |
| Pre-execution criteria | e39dafcdc17f52684f0127c408fe8b49a0d4c682d944da87bce6ddc4f62e1407 |
| Executed new test | d118e17f3fd36f4bcfaa5ebbd6ec4131cb8794c738a6826cac0ea7c23b24f884 |
| Passing 2/2 summary log | ddd0722f90fd133207ca9e423fc1faa05c3608f3be5c5eb4fdbea4259682b120 |
| Reused assertion-self helper/test file | eaf067af506d8151d87cfe8f8cbe2527580cabb6d5a8b73ea2a56a88072faaf6 |
| objects.mbt | 06fe3700af7171f9b67a9641a35c92d541849409bcd009e34428ee0456079436 |
| runtime_types.mbt | eb8a948f5aa45e57ba9417753d9d97e80e55ab4a35cd8524dc51a6a950f3e8e9 |
| Reused conditional runtime controls | ed86e469169c41f8a7c4badc881152175525dd18c29282d48a23d5be31542ccf |

Raw records: /tmp/moonjsonnet-assertion-super.ih4y77jh, including before-run.json,
criteria-before.md, test-before.mbt, supporting-source.json, focused-result.json,
checks.json, matrix-retry.json and individual logs. Temporary artifacts are not
an archival guarantee; committed inputs and the
[machine-readable matrix](spec-language-matrix.json) preserve the scope and
oracles. Counts/summary hashes alone are not source identity or conformance.

Checks ran sequentially with reduced priority and one worker where supported;
installed info/fmt have no worker option. Standard/default execution was
retained. All fixtures are synthetic and perform no imported-file, private
document or network I/O. No full suite, remote/platform/CLI run, new dependency,
push or tag occurred.
