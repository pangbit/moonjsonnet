# Object assertions: normative adjudication and matrix closeout

**DESUGAR-ASSERT is complete as a constructor transfer relative to its child
judgments.** Its expression/object condition, optional message, continuation,
local-binding and assertion-pair transfer is recorded in the existing
rule_review structure. This does not establish whole conformance of any child.
N0 and R0 below are explicitly excluded, unresolved normative questions.

This is a documentation/metadata closeout of e16dafe. No interpreter or test
source changes, new behavior cases, semantic reruns or upstream executions are
included. Prior behavior remains attached to the commits and sources in the
[U2 closeout](SPEC-ASSERTION-CONJUNCTION-EVIDENCE-2026-10-22.md), with its links
to the self, prefix and object-local reviews.

## Fixed source authority

Only existing local public-source copies at official Jsonnet
bbb38f1020be1f5aed560928fb839b2c448cefb4 were read:

| Fixed primary source | Role in this decision |
| --- | --- |
| [Formal specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html) | Desugaring, substitution, indexing, inheritance and manifestation equations |
| [Language guide](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md) | Layered field-context interpretation at 368-372; its 655-667 unfinished-parts comment includes assertion/self scope and recursion |
| [Standard-library source](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet) and [library reference](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html) | Definitions of library functions, not a replacement for language keyword or checking-state rules |

| Cached input | SHA-256 |
| --- | --- |
| spec.html | bbac3701ef0316fc29de6c543049ae8f0f78c876bdd94fbf6ab845b2023a720a |
| language.md | c55666af13894c8100c84fb053e647cd0ca516f3bb554d0ced29dfa83c3772be |
| stdlib.html | 0eb80c0ccaf781c4c2c1bc06a22d2d6e57f9866f41c0b62431b5ca4f510e6853 |
| upstream-std.jsonnet | e76dd6b8e51a2ca041b292dadea9c5521aeea5781b0ffe7c2c683865e7e45351 |

The library hashes agree with the existing pinned inventory generator. The
library source uses expression assertions, for example in substr at 41-44,
and defines assertEqual as a function/conditional/error at 842-850. It contains
no super token and supplies no evaluator rule for object-assertion reentry.
These definitions do not close either question below. No Go/C++ evaluator
source or behavior is used as a normative substitute.

## N0: assertion-super rewriting is not derivable as printed

The object-inherit equation at 2293-2333 constructs a lower-prefix expression
e_s, then writes its super replacement for right-hand field expressions in
the overlapping-field clause. Its result instead appends the left and right
assertion expressions without writing that replacement on right assertions.
The subsequent object-index rule at 2215-2228 replaces remaining super in
assertions by the empty object.

The issue is visible without executing a program. Consider this symbolic
surface term, solely for inspecting the written rules:

    ({x:true} + {assert super.x, value:1}).value

desugar_assert at 1351-1363 places the condition under the object bindings.
That introduces no lower-prefix binding for super. After the written
inheritance result and assertion indexing substitution, the condition needs
an x field from the empty object. There is no successful empty-object lookup
derivation. The layered interpretation used in the earlier bounded behavior
review would instead place the assertion in the right layer and find x in
the left layer.

The guide defines current-layer lookup for fields, but does not explicitly
assign this assertion transformation; its unfinished-scope comment includes
assertions. The layer interpretation is a reasonable account of intent, not
a missing formal inference that may be supplied from passing implementations.
Generic keyword substitution only operates when a replacement is invoked;
it cannot invent the absent inheritance replacement. The outer-self/super
capture and additive-field desugarings also do not write an assertion-list
prefix transformation.

**Adjudication: unresolved formal prefix transfer.** The printed reading
does not derive the reviewed layer behavior, and the surrounding prose or
fixed library does not unambiguously repair it. This is a concrete mismatch
between the formal fragment and a plausible layered interpretation, not a
reason to change the interpreter to a guessed reading.

The blocked claims are full object-inherit assertion-super substitution,
object-index on inherited super-dependent assertions, and the corresponding
SUBSTITUTION prefix algebra. A primary clarification must specify the
assertion's defining prefix, final receiver and capture boundary through
locals/functions/nested objects. This closeout proposes no replacement formula.

## R0: the paper has no in-progress assertion-checking state

R0 names the formal qualification already recorded before AC2 execution; it
is not a new behavioral group. object-index requires all assertions whenever
an object is indexed. Neither the object value representation at 1786-1836
nor that rule gives an in-progress or already-checked state.

Again, this is symbolic rule inspection only:

    o = {assert self.ok, ok:true, value:1}
    o.value

After assertion desugaring, proving the outer lookup requires its conditional
condition o.ok. Applying object-index to that lookup requires the same
assertion conditional again. The ordinary finite big-step reading therefore
has a repeating proof obligation even though the field graph itself is
acyclic. Reordering the rule's premises does not discharge that obligation.
Substitution/local-binding rules do not mark an object as being checked.

A checking state, removal of active assertions, or an explicit coinductive
interpretation would be an additional semantic choice. The fixed text states
none of them here. Source-level library functions cannot define the missing
language evaluation premise. The local implementation's in-progress guard
explains AS/AL/AC behavior, but does not prove one of those semantic choices
from the paper.

**Adjudication: unresolved formal checking-state model.** Bounded operational
reentry remains accepted relative to the previously stated self-field
contract. No finite derivation from the printed state-free rule is claimed.
The blocked claims are formal object-index for self-dependent assertions and
its use by manifest-object. A primary clarification must say how an assertion's
lookup of the same object interacts with active checks while retaining all
assertions. It need not standardize callback counts, error order, cache lifetime
or host resource policy, which remain outside this constructor review.

## What this assertion cluster has closed

| Component | Source-bound decision retained |
| --- | --- |
| Field demand, recursive top-level manifestation, empty/hidden-only objects | O3/O4/O5 retain their explicit assertion and laziness controls |
| Final receiver and detached condition/message functions | AS1-AS3 retain the reviewed self, message and condition-error boundary |
| Lower function prefixes in assertion branches | AX1/AX2 retain the bounded layer-model behavior; N0 prevents lifting it to a formal prefix theorem |
| Object-local definitions and nested capture | AL1/AL2 close U1 relative to existing self/root and child judgments |
| All retained assertions and finite reentry | AC1/AC2 close U2 behavior without prescribing assertion order; R0 prevents claiming the paper's state-free finite derivation |
| Expression/object assertion constructor transfer | The completed case analysis in the U2 report preserves children/pairs, checks the condition before the continuation, evaluates messages only on false, and wraps both object branches in local bindings |

There is no remaining U1/U2 behavior test list in this cluster. The last row
is relative to child static/evaluation, binding, Boolean and error-conversion
judgments. N0/R0 and whole child conformance are excluded rather than marked
passed. Exact human error presentation remains outside standardization under
spec 2845-2852. Top-level manifestation and std.manifestJson visible-field
traversal retain their distinct paths and separate obligations.

## Existing-schema completion record and counting

The DESUGAR-ASSERT clause now has decision=complete with the restricted
assertion-constructor-transfer review form in rule_review. The record pins
the four exact assertion desugaring equations at 1213-1219 and 1356-1363,
constructor roles, inspected implementation hashes, old evidence hashes,
child assumptions and mandatory N0/R0/whole-child exclusions.

The validator accepts this form only for the DESUGAR-ASSERT prose clause.
It reuses the existing normal/evidence, empty in-scope remainder, exclusion,
inspection and snapshot checks. Its state is completed-constructor-review;
it is not a completed named inference rule. Static-error N/A is limited to
the desugaring constructor relative to child static judgments, not a claim
that invalid children are accepted or all static rules are complete.

The accurate language inventory is 70 named rules plus 24 initial
prose/grammar obligations:

| Classification | Count |
| --- | --- |
| Completed named-rule reviews | 8: 6 static, 2 evaluation; unchanged |
| Completed prose constructor transfers relative to children | 1: DESUGAR-ASSERT |
| Manually reviewed partial rows | 41 |
| Unreviewed rows | 44 |
| Total inventory rows | 94 |

The JSON keeps completed_rule_rows for the 8 named reviews and adds
completed_constructor_rows=1. Thus 8+1+41+44=94; no prose review is silently
counted as a ninth named rule. complete_conformance and execution_inferred
remain false. object-index, object-inherit, SUBSTITUTION and manifest-object
are not completed by this record. The public-library inventory is unchanged:
153 candidate functions still lack whole-contract acceptance; no library
function completion is added.

## Metadata verification and source identity

Base: e16dafedb6cece0cb23d78c3f4d593055fee2096, tree
c656ba413e74a449f9a2a7286b6382a8d50c6313. The before manifest freezes all 291
tracked .mbt/.mbti files and all four public reference hashes. Source/test
snapshots in the constructor record are reused evidence, not executions
performed during this closeout.

Metadata controls passed positive generation above and rejection before output
of: this form attached to another clause; empty child assumptions; changed
fixed formula; omitted N0 exclusion; stale inspected-source hash.
Negative inputs live only in a temporary mirror of explicitly selected public
tracked files plus this report. Neither the real mapping nor user files are
temporarily overwritten by negative controls.

| Final check | Result |
| --- | --- |
| Positive matrix regeneration and exact counter/state scope | Exit 0; only DESUGAR-ASSERT changes completion state; 8 named + 1 relative constructor + 41 partial + 44 unreviewed |
| Five negative metadata controls | All five rejected at their intended guards before output; real inputs remained unchanged |
| Info then fmt; script fmt --check | All exited 0; all 291 frozen source/interface files remain unchanged |
| Tracked/staged-only documentation checker | Exit 0; 158 files and 1160 local/current-source links passed |
| Source/interface hashes, whitespace and exact file scope | All 291 frozen files and four references unchanged; working/staged git diff --check passes; exactly six scoped files |
| Semantic tests / upstream executions / network | Zero; none requested or performed |

Raw records: /tmp/moonjsonnet-assertion-closeout.6rhebi0p. Temporary artifacts
are not an archival guarantee; the committed review record, report and
[machine-readable matrix](spec-language-matrix.json) retain the decision.
Historical macOS/Linux or CLI counts are not extended to this commit.

One execution-channel interruption occurred before the record-writing shell
started. Read-only recovery confirmed the script/record/continuation absent
and only the earlier generator patch present; the write then ran once.
Later reconnect steering was followed by another HEAD/index/file-state check.
No commit or uncertain mutation was blindly repeated.

The next different high-risk rule suggested is object-comp's computed key
validity, null omission and duplicate-name rejection with lazy field values.
Map its existing C-series controls first, then identify an actual missing
obligation. This is a recommendation only; no comprehension work is started.

Standard/default and one local worker are retained. No interpreter edits,
new behavior cases, semantic reruns, full suite, installation, remote execution,
external issue publication, private-document reading, push or tag is included.

## Complete shared assertion-domain review atf3871b8

This is one current review of the shared rule domain, not another per-function
exception. The earlier N0/R0 analysis, constructor scope, old test evidence and
historical counts above remain intact. Fixed inputs are still Google Jsonnet
bbb38f1020be1f5aed560928fb839b2c448cefb4; all four reference hashes were checked
again. Base f3871b8 has688 clean tracked entries. New expected outcomes and the
classification below precede execution; no Go/C++ behavior supplies an oracle.

### Where the fixed materials agree

| Rule domain | Fixed authority and consequence |
| --- | --- |
| Assertion construction and message demand | spec1213-1219 and1351-1363 lower expression/object assertions to a conditional/error. A true condition skips the message; a false one requires it. Construction retains assertions as unevaluated expressions, spec1786-1796. |
| Object inheritance | spec2293-2333 retains both operands' assertion lists. Constant predicates need no disputed self/super transformation. Override of a field cannot erase those predicates. No first-failure order is stated. |
| Field access | spec2215-2228 requires the object's assertions for a selected visible or hidden field. This is not the same as type, length or Ex key reflection. |
| Core manifestation | spec2877-2883 and2974-2988 require assertions even with zero visible fields, then recursively manifest visible fields/array elements. Hidden field values stay unused. |
| JSON-library rendering | fixed std.jsonnet1048-1100 defines String rendering through visible field iteration and actual v[k] reads. An assertion-only/hidden-only object is not indexed. Compact style gives {}; default manifestJson gives the exact String {newline newline}. This differs from core manifestation without contradicting it. |
| Genuine cyclic demand | Finite execution/JSON derivations cannot discharge a repeated cyclic field/local premise with no base. A configured Runtime/Limit rejection is a bounded host observation, not a specified loop detector or error text. Skipped cyclic fields/messages/conditions remain lazy when their path does not demand them. |

Primary links:
[assert lowering](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#L1213-L1219),
[object assertion lowering](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#L1351-L1363),
[index](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#L2215-L2228),
[inheritance](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#L2293-L2333),
[core manifestation](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#L2974-L2988),
[JSON library body](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1048-L1100).

### N0: one explicit prefix conflict and the assertion-specific missing clause

The ordinary-field control sharpens the earlier assertion-only finding.
Assume the two operand values below have already been constructed, so this
argument does not choose an interpretation of general field desugaring DF0.

```text
left  = {x:true}
right = {v:super.x}
term  = (left + right).v
```

The [layered field promise](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#L348-L372)
gives true: v belongs to the right layer and its super.x finds left.x. The
printed object-inherit rule only places the e_s prefix replacement in the
shared-name right-field clause (2316-2318). It retains the right-only field
expression e-prime-R unchanged in2323-2324. object-index then substitutes {}
for its remaining super. The selected body needs {}.x, which has no field
lookup derivation. Thus the literal finite rule profile cannot deliver true.
The field-name sets are disjoint, avoiding the unrelated multi-common-field
printing issue. These two promises cannot both be the same execution judgment:

| Minimal control | Layered guide | Literal finite inheritance/index rules |
| --- | --- | --- |
| ({x:true}+{v:super.x}).v | true | No successful lookup derivation |
| ({x:true}+{x:super.x}).x | true | Prefix rewrite exists for the shared field; no N0 dependence |

The assertion-specific symbolic witness is:

```text
({ok:true}+{assert super.ok,v:1}).v
```

Printed assertion-list union2321-2322 writes no prefix replacement, and index
replaces the remaining super by {}. It cannot yield1 under the same finite
reading. A layer-prefix extension yields1. For assertions themselves, unlike
the ordinary-field control, the guide explicitly leaves detailed scope
unfinished at655-667. This is a missing assertion-specific transfer, not an
invented explicit guide theorem about assertions. The fixed library supplies
no keyword-substitution rule to fill it. The ordinary-field control establishes
an actual formal/guide conflict in the shared inheritance fragment; it must
not be mislabeled as only a lack of runtime samples.

### R0: acyclic data still repeats the checking premise

```text
local o={assert self.ok,ok:true,v:1}; o.v
```

With the printed desugaring, lookup of v first requires a conditional whose
condition is o.ok. Deriving o.ok requires that same assertion conditional,
which requires o.ok again as a proper subderivation. No minimal finite proof
height exists. The data field ok:true is not itself cyclic; this is a checking
premise cycle. The value grammar has no active/already-checked state. Merely
changing premise order or memoizing in an implementation does not add a paper
rule. The guide's unfinished self/assert/recursion scope and ordinary library
expressions do not specify coinduction, active-assertion exclusion or a new
checking-state judgment.

The literal finite profile therefore has no successful value derivation. A
separately declared active-check extension yields1, while still refusing a
real ok:self.ok field cycle. Both cannot supply one unconditional expected
answer. This is a definition/model gap, not evidence that the fixed guide
explicitly mandates that particular extension or callback/cache policy.

### Frozen probe matrix and separate verdict classes

The new [independent path file](../../spec_object_assertion_paths_test.mbt)
contains five agreed groups at indices0-4 and two profile-only groups at5-6.
Source and public ASTs are independently built using neutral constructors;
all expected values and explicit error markers are literal. No parser export
or observed interpreter result creates an expectation. Each group has source
and handmade entries. The two profile groups have a declared conditional
oracle only; normative acceptance is null, and they must not enter passing
N0/R0 language evidence or whole-rule counts.

| ID/class | Frozen required result or declared profile |
| --- | --- |
| APATH1 agreed | False/error/non-Boolean conditions stay unused under type/length/key reflection, an unused selection, an array head count and hidden nesting. Literal metadata is [object,1,[v],[h,v],1,42,{}]. |
| APATH2 agreed | False assertions fail core manifestation for empty/hidden/visible/nested objects and arrays. True empty/hidden objects yield {}. Both inherited constant assertion lists survive even without fields and after adding a selected harmless field. |
| APATH3 agreed | Visible/hidden reads require flat assertions. True checks skip a cyclic message; false checks fail, needed condition/message errors propagate, and a non-Boolean condition rejects. One shared super field and inherited self fields with constant assertions have independent true/2 results; no assertion-specific prefix or self-condition reentry is involved. |
| APATH4 agreed | Compact rendering returns {} for assertion-only/hidden-only false objects, {outer:{}}/[{}] for nested empty false objects; default manifestJson returns the exact String with two newlines. A visible indexed field instead requires the false assertion and rejects. These are not universal top-level manifestation paths. |
| APATH5 agreed | Hidden cyclic field values are not manifested. Actual selected field/local-condition cycles produce no finite JSON value under bounded Runtime/Limit handling. Type/unused/empty library traversals skip them where applicable. Acyclic self-field access under identical limits returns1. |
| N0-P profile only | Current layered-prefix interpretation returns true for the new right field and1 for the assertion-super witness. The raw finite-paper alternatives above remain recorded, not marked failed implementation tests. |
| R0-P profile only | Current active-check interpretation returns1 for the minimal self predicate and compatible inherited receiver; a false final predicate rejects. It still refuses a genuine self-field cycle. These do not prove a finite state-free derivation. |

Runtime/Type/Assertion labels here are existing embedding phase controls;
only the appropriate no-value/success contract and supplied isolated marker
are inferred from the clauses. The cycle helper excludes Unsupported and
parse/static failures; it permits Runtime or configured Limit without claiming
which detector, timing or message the normative language requires. All ordinary
fields used to distinguish error paths are harmless unless their non-demand is
itself the required successful observation. No independently competing error
winner, assertion iteration order, callback count or cache lifetime is asserted.

### Authority and stopping boundary

No replacement rule is silently adopted. A correction/authoritative profile
must specify right-only-field and right-assertion defining prefixes/final self,
and whether self-dependent checks use finite rejection, checking state or an
explicit recursive interpretation. If active-check exclusion is selected it
must still retain remaining assertions and actual field-cycle demand; it need
not standardize memoization or native traces. The current implementation's
layer_scope/check_assertions explain its conditional behavior, not the missing
normative selection. No Go/C++ result supplies that selection.

Inspect [objects.mbt](../../objects.mbt), [core manifest](../../manifest.mbt)
and [library traversal](../../manifest_json.mbt) against the agreed path table.
First run a native check and the five agreed probes. Only an agreed failure
justifies a product fix. Then run the two separately named profile probes to
record current source/AST compatibility, never to certify N0/R0. Freeze all
inputs and keep original failures if any. Each command is local native debug,
frozen/deny-warn/j1/no-parallelize as applicable, closed stdin and bounded300s.
No full suite, new SSH/remote window, Go/C++, standalone delivery campaign,
installation, upstream edit, private proposal or push is included. After this
one domain review, stop the conflict branches rather than probing per function.

<!-- This domain decision and all criteria precede execution. -->

### Current executions, evidence classes and final decision

The native check passed first time, exit0 in0.511s. With product bytes unchanged,
the five agreed groups at indices0-4 passed **5/5,exit0,7.733s**. The two explicitly
conditional profile groups at indices5-6 passed **2/2,exit0,0.202s** in a separate
command. They confirm source/handmade compatibility with the declared current
layer-prefix/active-check interpretation; their normative acceptance is null.
They are not combined into seven normative passes or N0/R0 rule completion.
Both raw stderr files are empty. There was no failure, expected-value change,
fixture type repair, snapshot update or interpreter correction in this review.

The agreed probes establish the promised route differences on this source:
core manifestation checks empty/hidden/nested objects and inherited constant
assertions; field access checks harmless visible/hidden payloads; reflection
and unused values defer checks. The fixed library's no-visible-field String
walk does not index the input, even when nested, but a visible read does require
its assertions. Genuine demanded field/local-condition cycles do not return a
finite value, while hidden/unused paths and true-condition messages remain lazy.
No result was inferred from all paths merely having an object input.

The ordinary new-right-field N0 control follows the guide in this implementation,
while the raw printed result cannot establish the same true. The assertion-super
and finite-data self-predicate controls follow the declared extension; neither
adds the missing paper transformation/state. No uncontroversial implementation
defect was reproduced, so changing objects.mbt to pick a paper/guide alternative
would be unjustified. The explicit prefix conflict and missing assertion/reentry
clauses are the remaining normative obstacles, not an unexecuted microtest list.
All three conflict branches stop here pending a correction or explicit source
interpretation from the specification authority. No upstream issue was posted.

The current matrix adds only APATH1-APATH5. All220 older canonical evidence
objects and all prior completion records stay unchanged; the two profile-only
names have no assertion-evidence IDs. No later-demand failure is mapped as a new
intrinsic object-addition error. The DESUGAR-ASSERT constructor transfer remains
relative to children with N0/R0 exclusions. No new rule or language acceptance
is claimed. Public function records remain66 subsets/zero whole functions.

Required native info and fmt passed, exit0 in0.329s and0.048s. The frozen
seven-case file is unchanged; all inspected product files and public interfaces
stay unchanged. No prior AS/AX/AL/AC or historical full-suite result was rerun or
promoted to the current source. Raw inputs, exact commands/environment/closed
stdin/300s bounds, outputs, elapsed and owned-group exit receipts remain at
`/tmp/moonjsonnet-assertion-domain.paaex37n`. Temporary paths are not an archival
availability guarantee.

| Artifact | SHA-256 |
| --- | --- |
| Frozen domain criteria | `f7db54ea5c932dfd1b9817b0b31a0a22d7115f3a0c71e985d333afd5ce85b7e7` |
| Frozen seven-case file | `a6cb41c025eb6e7120f6f70a6681efe0f8095f4bfbea754fe64a6350ef96ebc3` |
| Agreed-only stdout | `30a04d9fb9b3e8b0c88d173d0654b97191bd61de5cd6b067b91b74f25115ca4a` |
| Conditional-profile-only stdout | `ddd0722f90fd133207ca9e423fc1faa05c3608f3be5c5eb4fdbea4259682b120` |

No new SSH/remote window, full suite, release, standalone API/CLI delivery,
reference interpreter, installation, private proposal or push was used. Old
failure evidence is intact. The758 historical count is not current acceptance,
and no conditional profile result overrides an unadjudicated source clause.
