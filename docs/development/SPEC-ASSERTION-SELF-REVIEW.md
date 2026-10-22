# Inherited assertion closures: pre-execution criteria

Base source: b2b3233a64a262c34cbe81337da2ebde9b67e6f0. Fixed official Jsonnet:
bbb38f1020be1f5aed560928fb839b2c448cefb4. Cached spec.html SHA-256:
bbac3701ef0316fc29de6c543049ae8f0f78c876bdd94fbf6ab845b2023a720a;
language.md SHA-256:
c55666af13894c8100c84fb053e647cd0ca516f3bb554d0ced29dfa83c3772be.
These expectations precede execution of the new probes. Neither interpreter
output nor Go/C++ agreement supplies an oracle.

## Normative basis and selected gap

The [fixed specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html)
desugars an object assertion to a conditional yielding null or error at lines
1351-1363. The message belongs only to the failing branch. The object-index
rule at lines 2215-2228 evaluates assertions in the selected receiver's self
context before yielding its field. Object inheritance at lines 2293-2333
retains assertions from both operands; an earlier successful check of a
different object cannot discharge the derived receiver's assertion.

Keyword substitution at lines 2038-2123 recurses into functions while excluding
bodies captured by nested objects. A zero-argument function in the assertion
condition or failure message therefore captures the assertion's current self.
This batch uses plain fields and left-operand assertions without super, object
locals, nested objects or additive fields. It does not adjudicate their other
substitution or inheritance combinations.

Existing O3 covers direct self conditions, including repaired/invalid derived
receivers, visible/hidden access and manifestation. O5 covers simple assertion
reuse, lazy success messages and payload suppression. The missing combination
is an already checked original plus a derived receiver whose condition and
message are function closures. The new predicates remain Jsonnet expressions;
native callbacks only record context and return literal true, a fixed message,
or the requested numeric payload.

## Independent source and handmade-AST expectations

The original has n=required=2 and label=original. Its assertion condition is
function(){ record condition(n,required,label); n==required }, expressed using
an if around the recorder. Its message is a separately invoked zero-argument
function recording the same self fields and returning assertion-self-marker.
The selected value records payload(n,label) and returns n. Each new program
is built independently as source and a typed tree, without parser export.

| Probe | Required result and demand observations |
| --- | --- |
| AS1: compatible derived receiver | Change n=required=3 and label=compatible. First demand original.value==2, then derived.value. Result 3; events are condition(2,2,original), payload(2,original), condition(3,3,compatible), payload(3,compatible). No message runs |
| AS2: original success cannot authorize invalid derivation | Change n=3, keep required=2, label=bad. After original.value==2, actual derived.value demand fails Assertion with assertion-self-marker. Events are condition(2,2,original), payload(2,original), condition(3,2,bad), message(3,2,bad). The derived payload never runs |
| AS3: construction is separate from assertion demand | For a derived receiver whose condition function records then raises error condition-self-marker, std.type(derived) yields object and an unused derived.value yields 42, both with zero callback events. Both routes explicitly construct/type-inspect derived |
| AS3: condition exception is distinct from false | Actual derived.value demand records only condition(3,2,bad), then rejects Runtime with condition-self-marker. Neither the assertion message nor selected payload runs |

Both entry paths must accept the valid programs before evaluation, with zero
callback activity at Program creation. Error kind, entry file and literal
marker distinguish these unambiguous embedding phases. No malformed-source
Syntax counterpart or whole static-rule review is claimed for typed ASTs.
Exact callback traces also guard this implementation's demand/cache behavior;
they do not impose a universal native-call count or a first-error ordering
among multiple independently failing assertions. Each fixture has one assertion.

## Reuse, boundaries and acceptance limits

O3/O4 already establish top-level assertion-only and hidden-only failures and
recursive manifestation. Existing object reflection/get/objectValues audits
establish which structural operations avoid field indexing. Reuse their
reviewed meanings without rerunning them or counting old passes as current.
Top-level manifest-object checks assertions even with no visible fields;
std.manifestJson traversing visible fields follows a different library path.
That distinction is retained, and upstream compatibility does not exempt any
normative obligation. This group adds no new conclusion about either path.

Inspect receiver-local assertion state, inherited layer retention, final-self
scope construction, closure capture/call environments, and message/payload
gating. Accept only the bounded ordinary-field assertion-self contract if
explicit outcomes and dataflow agree. Keep object-index, object-inherit,
DESUGAR-ASSERT and SUBSTITUTION partial. Assertion super prefixes, multiple
assertions/order, equality/reentry interactions, all message types/defaults,
condition type failures and general object rules remain open.

Use one local worker and directed native debug execution with frozen existing
dependencies and reduced priority. No full suite, platform/remote run,
installation, push or tag is included. All inputs are synthetic virtual
callbacks, without imported-file, network or private-document I/O.
