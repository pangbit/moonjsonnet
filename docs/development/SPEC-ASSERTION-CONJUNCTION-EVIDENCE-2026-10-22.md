# Assertion conjunction and finite reentry: U2 closeout

This report records the e16dafe behavioral batch. The subsequent
[normative/matrix closeout](SPEC-OBJECT-ASSERTION-ADJUDICATION-2026-10-22.md)
records the relative DESUGAR-ASSERT constructor decision and separately blocks
N0/R0 formal claims. The original execution identity and results below remain
historical; they were not rerun for the metadata closeout.

**Decision: U2's bounded behavioral endpoint is closed.** Both assertion
lists, including multiple pairs within each operand, survive field override.
The finite self-field dependency completes without losing later checks or
reusing an original receiver's successful state. U1 remains closed in its
declared scope. The
[pre-execution criteria](SPEC-ASSERTION-CONJUNCTION-REVIEW.md) distinguish the
normatively decidable conjunction clause from operational reentry acceptance.

**The expression/object assertion constructor transfer review is complete
relative to its child judgments.** This closes the previously requested
review work; it does not complete all object/index/inheritance rules or
invent a formal assertion-checking state. N0 remains unresolved.

## Fixed normative scope and order independence

The [official specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html)
is fixed at bbb38f1020be1f5aed560928fb839b2c448cefb4. object-inherit retains
left and right assertion lists (2293-2333); object-index quantifies over all
assertions before yielding a field (2215-2228). Its value discussion treats
reordering object assertions as immaterial (1793-1796). These establish
retention/conjunction, not a particular traversal or first error.

AC1's predicates have no self/super references. Four unique-false controls
prove each position remains effective; one two-false control accepts either
failure. It does not require all callbacks after failure or prefer the
implementation's current layer order. Observer maps collapse repetitions
and compare membership, never sequences or universal call counts.

AC2 uses the previously reviewed self-field contract and a length-three
acyclic numeric dependency. The printed state-free object-index rule has no
explicit in-progress checking premise. Its literal recursive use is not
silently identified with the implementation's guard. Thus the finite result
is bounded operational acceptance relative to that child contract, not a new
finite formal derivation from the equation. This qualification was recorded
before execution. No new fixture uses super, and passing it cannot resolve
N0's missing assertion-super rewrite.

## Actual source and independent handmade-AST outcomes

The [new test file](../../spec_assertion_conjunction_test.mbt) constructs
source and typed trees separately, reusing unchanged neutral AST/program
helpers and their virtual assertion-self-entry identity. Expected values,
false-ID sets and receiver contexts are fixed independently of execution.
Callbacks only observe IDs or return their explicit supplied values.

| Selected U2 clause | Observed result through both entry paths |
| --- | --- |
| Both lists and both positions in each list are retained | Left L0/L1 and right R0/R1 all appear in the deduplicated all-true set, with selected value 42 |
| Field replacement cannot erase assertions | Right value replaces an error-valued left value. Each of L0, L1, R0 and R1 separately made uniquely false still raises Assertion before the selected payload |
| Multiple failures do not impose an order oracle | L0/R1 false accepts either matching ID; no full trace or preferred first assertion is required |
| Construction/unused access avoids the checks | An explicit type guard constructs the merged object. The two-failure metadata/unused modes yield object/42 with no condition, message or payload observations |
| Original receiver and merged receiver have independent checks | Original seed=1/goal=3 is actually checked through left.value==3; the merged receiver with seed=10/goal=12 then returns 12 |
| Finite reentry does not drop checks | The set contains L0/L1 at context 3 and all four IDs at context 12. It imposes no order among them |
| Error-valued successful messages stay lazy | Every AC2 message is an explicit error; all four merged predicates succeed without evaluating any message |

Every evaluation explicitly uses steps=5000, depth=48 and stack=64. The input
graph is seed, next=seed+1, done=next+1, with no recursive fields/functions.
If an assertion checker incorrectly restarts recursively, these bounds force
a prompt failure; a Limit result is never accepted as success. No unbounded
cycle or stress run was executed.

## Structural argument and reused evidence

Object addition retains complete layer arrays and creates a new object with
fresh assertion, scope and field-cache state. AST conversion maps every
condition/message pair without dropping elements. check_assertions iterates
every layer and every pair. Its in-progress return prevents restarting the
same check during self-field reads; control returns to the outer pair loop,
which continues. Completed state is assigned only after all loops succeed.
The error-defer path resets in-progress state before propagating failure.
field checks assertions before running its selected body.

This explains why the original's completed check does not authorize the
merged receiver, why later pairs remain effective after a reentrant read,
and why both left and right assertions remain despite a replaced value.
The inspected traversal explains list sizes beyond the finite controls;
the controls do not turn the paper's missing state model into a proof.
No product defect was observed or fix needed.

AS already supplies independent receiver/check-state controls, AL supplies
object-local and nested capture, and SP/AX supply their separate prefix
behavior/limitations. They are reused with their original source identity,
not rerun or added to this batch. All new callbacks and graphs are synthetic.

## Completed constructor transfer review

The fixed desugaring clauses are expression assertions (1213-1219), object
binding introduction (1131-1165) and desugar_assert (1351-1363). The following
case analysis closes their constructor transfer relative to child checking,
evaluation, Boolean, local binding and error-conversion judgments. Those
children retain their own partial/completed scopes.

| Constructor role | Inspected transfer argument and reused control |
| --- | --- |
| Preserve condition, optional message and expression continuation | ast_convert.mbt preserves Assert's three children and every Obj local/assertion pair. No constructor-specific transformation drops a branch or list item |
| Statically visit children even when dynamically unused | validate.mbt unconditionally visits expression condition/message/body and all object-local/assertion children under the correct scope. This is structural delegation relative to child checking, not a new whole-variable/binder proof |
| Condition evaluation and Boolean gate | Vm::assertion evaluates the condition, then calls the exhaustive shared boolean helper. IF4 already supplies the non-Boolean child controls; AS/AL supply condition-error and binding cases |
| Expression continuation only after success | eval.mbt calls assertion before assigning expr=body. On false/error it raises before that assignment; on true it continues in an environment differing only in diagnostic context. diagnostic_trace.mbt preserves semantic Env fields with a structure spread. AR0 already independently controls expression success/failure and lazy messages |
| Message only on false, with omission handled | objects.mbt evaluates/coerces Some(message) only under !holds; None supplies the default. AR0 covers omitted-message failure and successful-condition laziness plus finite conversion controls. Exact human default text is outside standardization under spec 2845-2852; general error conversion remains a child judgment |
| Object local scope wraps both branches | The layer scope binds locals after current self is installed and is shared by condition/message evaluation. U1 supplies the distinguishing shadowing/nested capture outcomes and binding dataflow |
| Deferred object demand and complete retained lists | Construction stores local/assertion arrays; actual indexing/manifestation invokes checking. O3/O4/O5, AS/AL and AC1/AC2 cover the accepted demand components; inheritance and reentrant field judgments remain explicit children, including their formal limits |

This is a manual engineering constructor review, not a machine-checked proof
of arbitrary children, grammar, host hooks, resource accounting, equality or
all object operations. It supplies the concrete relative decision instead of
asking for more assertion behavioral microgroups.

## Remaining normative adjudication and matrix closure positions

| Position | Current closure decision / exact remainder |
| --- | --- |
| DESUGAR-ASSERT | Expression/object constructor transfer is reviewed complete relative to children above. This is ready for an explicit prose-constructor completion record; no further assertion behavior tests are requested. The current generator only encodes completed named rules and rejects a prose rule_review, so this batch retains its partial row state instead of labeling it as a named inference rule |
| object-inherit assertion-list component | U2 retention/conjunction component is closed. Whole object-inherit still has independent inheritance/association, additive and computed-name obligations; N0's assertion-super transformation is unresolved |
| object-index assertion component | Conjunction plus the accepted operational self/reentry contract are closed in scope. A literal formal acceptance still needs the state-free rule's treatment of in-progress self-index checking clarified. General target/key/missing-field errors and equality interactions are separate row obligations |
| SUBSTITUTION | AS/AL/AC receiver/local-capture components have their bounded decisions; AX retains its layer-model prefix decision. N0 and the full binder/self/super/root algebra are not proved |
| manifest-object | Existing O3/O4 ordinary recursive/empty/hidden-only assertion-demand evidence remains reusable; no new manifestation execution or whole-row decision is added |

N0 is still the exact missing explicit right-hand assertion-super rewrite.
The formal reentry interpretation is a source-model qualification of the
already reviewed self-index child contract, not another missing behavioral
microgroup. These questions require primary normative adjudication, not more
passing implementations or additional samples. No formula is supplied from
implementation behavior. U1 and the declared U2 behavioral endpoints now have
no residual test list; a prose completion encoding is a concrete matrix-format
task, not a new semantic campaign.

Top-level manifest-object versus std.manifestJson visible-field traversal
retains its prior distinction and separate normative responsibilities. Host
cache lifetime, divergence/resource policies, CLI/platform behavior and
arbitrary equality are not silently made prerequisites for the constructor
transfer decision.

## Execution identity and final checks

Base source: 0719f40d160f46208153e9d234a2a45dfe3749d0, tree
2dc7f4240da40fbb9c439e4b9573967c4d384f6a, plus the new test below. The retained
pre-run manifest pins exact criteria/test/implementation/reused-helper bytes.
The additional diagnostic environment source was checked against that base.
All those bytes remained unchanged after execution and matrix/format work.
Existing local Darwin arm64 tooling: moon/moonrun 0.1.20260920 (914d7da),
moonc v0.10.14+7d59c7ec9.

The single directed native debug invocation passed **2/2, exit 0**, first run:

```sh
nice -n 10 env RUST_LOG=error moon test spec_assertion_conjunction_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize
```

The two groups include source/handmade-AST cases; test count is not a
conformance measure. Older AS/AL/AX/AR0/IF4 or aggregate/platform outcomes are
not added to it. No semantic rerun followed mapping/documentation edits.

| Final check | Result |
| --- | --- |
| Native root check | Exit 0 with --frozen --deny-warn -j 1 |
| Info then fmt; script fmt --check | All exited 0; no .mbti changes |
| Matrix validation/regeneration | Exit 0 on first invocation; anchors, locations and source hashes validated |
| Tracked/staged-only documentation checker | Exit 0; 157 files and 1156 local/current-source links passed |
| Whitespace and exact scope | Working/staged git diff --check passes; exactly nine scoped files, with no product/interface changes |

Only four clause mappings change: object-index, object-inherit,
DESUGAR-ASSERT and SUBSTITUTION. All row states are unchanged in the
[matrix](SPEC-LANGUAGE-MATRIX.md): **8 completed named rules, 42 partial rows,
44 unreviewed rows**, 70 named rules and 24 initial prose/grammar rows.
Whole-language acceptance and inferred execution remain false. Product code,
dependencies and public interfaces are unchanged. The
[Go/C++ comparison](SPEC-LANGUAGE-COMPARISON-2026-10-22.md) stays separate and
unknown for these new cases.

| Artifact / source | SHA-256 |
| --- | --- |
| Pre-execution criteria | 2fd8607d7dbf265ccb0c46cbfad76bffa6ee59273dbb7cb2559f303e020a58ef |
| Executed new test | 737b61a9ad4bb78a506f25be00c1c4533a75f2711390bae6023e79d388e380c9 |
| Passing 2/2 summary log | ddd0722f90fd133207ca9e423fc1faa05c3608f3be5c5eb4fdbea4259682b120 |
| objects.mbt | 06fe3700af7171f9b67a9641a35c92d541849409bcd009e34428ee0456079436 |
| diagnostic_trace.mbt | 77acadcefa568a59944499ca5457811880a48b3d9fcbf6ac12a3a5eb3e3e57a4 |

Raw records: /tmp/moonjsonnet-assertion-conjunction.ugovu24p, including
before-run.json, criteria-before.md, test-before.mbt, supporting-source.json,
focused-result.json, checks.json and logs. Temporary records are not an
archival guarantee; committed tests/criteria and the
[machine-readable matrix](spec-language-matrix.json) retain actual scope and
oracles. Summary counts/hashes alone are not source identity or conformance.

Checks ran sequentially at reduced priority with one worker where supported;
installed info/fmt have no worker option. Standard/default was retained.
Fixtures use no imported-file, private-document or network I/O. No full suite,
remote/platform/CLI run, installation, push or tag occurred.
