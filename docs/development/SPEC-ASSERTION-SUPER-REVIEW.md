# Assertion functions and super prefixes: pre-execution criteria

Base source: c61772651d5ea3a7efe110baabbed2697f23bf3e. Fixed official Jsonnet:
bbb38f1020be1f5aed560928fb839b2c448cefb4. Cached spec.html SHA-256:
bbac3701ef0316fc29de6c543049ae8f0f78c876bdd94fbf6ab845b2023a720a;
language.md SHA-256:
c55666af13894c8100c84fb053e647cd0ca516f3bb554d0ced29dfa83c3772be.
The following expectations precede new execution. Neither implementation
output nor Go/C++ behavior selects them.

## Selected contract and normative qualification

The [fixed language reference](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#inheritance)
at lines 368-372 gives each function field a particular defining layer:
self searches the final receiver; super starts below that defining layer.
The [fixed specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html)
desugars an object assertion into a conditional/error under object bindings
(1351-1363), evaluates assertions on field demand (2215-2228) and retains them
through inheritance (2293-2333). Keyword substitution recurses through local
bindings and functions, stopping at nested object bodies (2038-2123).

The behavioral expectation composes these definitions: a C-layer assertion
extracting super.probe selects B.probe, whose own super still means A, while
both contexts retain the final D receiver for self. The same applies to a
function extracted only by the failing message branch. This is an independently
specified layered interpretation, not a reference-interpreter oracle.

There is a precise limit to formal acceptance. The printed object-inherit
equation unions right/left assertions but does not explicitly apply a prefix
rewrite to right-hand assertions. The language page also leaves detailed
assertion scope in its unfinished-scope comment. These fragments do not by
themselves prove the assertion-specific transformation. Record this gap even
if every layered-behavior probe passes; do not silently repair the equation,
claim a formal derivation, or complete the general rule on that basis.

## Existing coverage and the assertion-specific difference

SP1 already establishes extraction/rehosting for ordinary function fields;
SP3 establishes their missing/error prefix demand. AS1-AS3 establish final
self in condition/message functions, receiver-local checks and condition
exceptions. Reuse those mappings without repeating their scenarios or counting
their earlier executions as current. The new cases put extraction and nested
prefix selection inside the assertion condition and failure-message branches,
where checking a lower field reenters an in-progress assertion check.

Reuse existing AST construction/program-entry helpers from
spec_assertion_self_test.mbt, including their synthetic assertion-self-entry
identity. New trees are handmade independently of their source strings;
no parser/export round trip supplies their structure or expected values.

## Independent inputs and required outcomes

Four layers have n=1/2/3/4. B.probe is a function that records
condition(super.n,self.n) and returns [super.n,self.n]. B.message records
message(super.n,self.n), then reads super.problem. C defines an assertion
which locally extracts super.probe, invokes it through another function,
and compares its pair with [1,self.expected]. Its message similarly extracts
and invokes super.message. C and D contain unusable replacement probe/message
functions; B/C/D also have replacement problem strings. They must not satisfy
the lower functions' own A prefix. D.value records payload(self.n).

| Probe | Required source and independent AST outcome |
| --- | --- |
| AX1: condition extraction and two distinct prefixes | D.expected=4. D.value returns 4; events are condition(1,4), payload(4). C's assertion selects B.probe, then that function selects A.n with final self=D. No message runs, even though A.problem is an explicit error |
| AX2: metadata and unused selection | D.expected=0. For both missing A.problem and an explicit A.problem error, an explicit type guard constructs D. Metadata/unused-field modes return object/42 with zero events |
| AX2: failing message extraction | Actual D.value demand first records condition(1,4), then message(1,4), and rejects Runtime. An explicit A error preserves assertion-super-marker; a missing A.problem also rejects despite replacement problem strings in B/C/D. No payload runs |

AX2's predicate is false before the message. The new Runtime is therefore a
message-evaluation failure, distinct from AS2's successful string message
followed by Assertion, and AS3's condition-evaluation Runtime. Each fixture
has one assertion. Categories, virtual entry identity and literal markers are
embedding controls, not standardized error presentation or arbitrary ordering
between independent failures. Call traces guard this implementation's demand
behavior without imposing a universal native-call-count policy.

## Review and stopping point

Inspect check_assertions' layer-specific scope, full receiver versus prefix
bindings, closure capture/call environments, lower field selection and the
false-branch message gate. Accept the bounded behavior only when explicit
outcomes and this dataflow agree. Keep all broader matrix states unchanged.

The evidence report must list concrete remaining object-assertion clauses,
which existing independent assertions can already discharge, which tests are
only candidates, and finite acceptance endpoints. Separate the printed-rule
scope gap from missing behavioral evidence, and keep expression assertions,
stdlib traversal and host-session policy under their own obligations.

One local worker, reduced priority and existing frozen dependencies only.
No full suite, remote/platform run, installation, push or tag; no imported
files, private-document content or network I/O in these synthetic fixtures.
