# Assertion object locals and nested capture: pre-execution criteria

Base source: 260a13124ec9ecb2688c6bb516b893d517cce0cb. Fixed official Jsonnet:
bbb38f1020be1f5aed560928fb839b2c448cefb4. Cached spec.html SHA-256:
bbac3701ef0316fc29de6c543049ae8f0f78c876bdd94fbf6ab845b2023a720a;
language.md SHA-256:
c55666af13894c8100c84fb053e647cd0ca516f3bb554d0ced29dfa83c3772be.
The following inputs and literal outcomes precede new execution. Neither
interpreter output nor Go/C++ behavior determines them.

## U1 scope and independent normative basis

The [fixed specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#desugaring)
at lines 1131-1165 supplies an object's local bindings to its assertions.
desugar_assert at lines 1351-1363 wraps the entire conditional/error body in
those bindings, so both condition and failure message use the object-local
definition environment rather than an outer same-name binding. Local-variable
substitution at lines 2260-2270 retains the binding environment. Keyword
substitution at lines 2038-2123 stops at nested object bodies; a captured local
receiver alias is distinct from that nested object's own self.

Object/function context rules at lines 1131-1165 and 1208 preserve lexical
root bindings inside an object-local helper. RT1/RT2 have already reviewed
these root/self boundaries; R4 covers ordinary object-local aliases with
inherited self. AS1-AS3 cover assertion self, lazy messages and field demand.
Reuse their existing meanings without rerunning or adding their old outcomes
to this batch. The new difference is that object-local definitions used by
assertions create a nested object/function and remain bound in both branches.

N0 concerns the missing explicit assertion-super rewrite in the pinned
inheritance equation. No fixture here uses super, so N0 does not affect these
U1 oracles. Its unresolved status must be retained. U2 multi-assertion
conjunction/reentry is outside this batch; each assertion-bearing object has
exactly one assertion.

## Fixture and required source/handmade-AST outcomes

An outer helper raises outer-helper-marker and an outer receiver has tag=99.
Root tag=10 contains a child with tag=2 and expected=[2,30,10]. The child has
object locals receiver=self, helper=function(){tag:30,read:function()
[receiver.tag,self.tag,$.tag]}, and unused=error unused-local-marker.
Its condition samples helper().read(), records condition(sample), then
compares sample to self.expected. Its message records message(helper().read())
and returns object-local-message-marker. Its selected value records and
returns payload(helper().read()). The unused local must never be forced.

The root is inherited with tag=20; its selected child is then inherited with
tag=3. That final child's expected value is [3,30,20], or [99,30,20] in the
false-condition variant. A second variant replaces the helper initializer
with a localInit callback followed by error object-local-init-marker.
Callbacks are observers returning literal true, a fixed message or the
supplied JSON value; the assertion predicate stays in Jsonnet.

| Probe | Independent required result |
| --- | --- |
| AL1: original and inherited/nested definition contexts | Demand original root.child.value, then final picked.value. Result [[2,30,10],[3,30,20]]; events are condition([2,30,10]), payload([2,30,10]), condition([3,30,20]), payload([3,30,20]). Outer helper/receiver cannot replace object-local definitions |
| AL1: distinct captures | The receiver alias follows the final selected child 2/3; the helper's nested self remains 30; its lexical root is 10/20. The assertion message and unused local remain untouched |
| AL2: construction and unused-field boundary | For false-condition and erroneous-local-initializer variants, an explicit type guard constructs picked. Metadata/unused modes yield object/42 with zero events |
| AL2: false-condition message uses the same object-local helper | Actual picked.value demand records condition([3,30,20]), message([3,30,20]), then raises Assertion with object-local-message-marker. No payload or unused-local error runs |
| AL2: local initializer error is lazy but propagates when demanded | Actual field demand records only local-init, then raises Runtime with object-local-init-marker before condition/message/payload observation. The outer helper's marker must not replace it |

Each source program has a separately handmade typed AST. Reuse neutral AST and
entry helpers from spec_assertion_self_test.mbt, including the stable virtual
assertion-self-entry identity. Build explicit Obj locals/condition/message
arrays without parser export. Both routes must create valid programs with
zero callback activity. Error categories, file identity and fixed markers
are embedding phase controls, not standardized human diagnostics.

## Acceptance and limits

Inspect scope/layer_scope binding object locals after installing the current
self, lazy recursive binding capture, nested-object/function environments and
preservation of local/condition/message arrays in conversion/validation. Use
the explicit outcomes plus those structural paths to decide U1 relative to
the previously reviewed self/root and child-expression judgments. This is
not a new proof of every binder, nested object shape or root operation.

Keep broader matrix states unchanged. Report U1's decision separately from
U2's unexecuted endpoint and N0's unresolved formal source gap. Run only these
new groups, one local worker at reduced priority with frozen existing
dependencies. No full suite, remote/platform run, installation, push, tag,
imported-file, private-document or network I/O is included.
