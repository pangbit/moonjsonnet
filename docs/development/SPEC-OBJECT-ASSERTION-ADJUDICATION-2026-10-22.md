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
