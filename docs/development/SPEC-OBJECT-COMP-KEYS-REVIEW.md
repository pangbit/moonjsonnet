# Object-comprehension dynamic keys: pre-execution criteria

Base source: 7f2d5bf242be394a897787d2196db0d769d8ab0b. Fixed official Jsonnet:
bbb38f1020be1f5aed560928fb839b2c448cefb4. Cached spec.html SHA-256:
bbac3701ef0316fc29de6c543049ae8f0f78c876bdd94fbf6ab845b2023a720a;
language.md SHA-256:
c55666af13894c8100c84fb053e647cd0ca516f3bb554d0ced29dfa83c3772be.
These inputs and literal expectations precede new execution. Neither
implementation output nor Go/C++ behavior determines the oracle.

## Fixed clauses and selected gap

The [fixed object-comp rule](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#execution)
at lines 2183-2200 evaluates key expressions, requires distinct non-null names
and stores substituted body expressions only for non-null keys. It has no
body-value evaluation premise. A demanded existing field therefore cannot
bypass a duplicate elsewhere in the same object's construction.

The [comprehension desugaring](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#desugaring)
at lines 1168-1189 creates fresh iterator tuples and binds generator names
separately in keys and bodies. This supplies the iteration capture expectation,
relative to the existing generator/local/array child judgments.

C2/A3 already review empty/all-null suppression; C3 reviews structural key
demand and selected-body caching; C4/A4 review simple duplicate Runtime errors
before bodies; C1 reviews nested/sequential generator scope. C7 supplies
key/body error-phase controls. Reuse those meanings without rerunning or
counting their earlier outcomes as fresh.

The missing combination is a collision between different tuples from two
generators, plus mixed null/retained names with bodies evaluated after the
iteration has finished. This group adds no general key-type, filter/domain,
object-local, self/super/root or full comprehension-constructor campaign.

## Independent source and handmade-AST inputs

Outer x=99/y=88 are shadowed by for x in [1,2], for y in [0,x]. There are four
tuples: (1,0), (1,1), (2,0), (2,2). A key observer receives and returns the name
computed by Jsonnet: null when y=0; first when x=1; otherwise second, or first
in the collision variant. Repeated null names must be filtered, not rejected.

Every body first records its x/y tuple, then raises null-key-body-marker for
y=0, raises retained-body-marker for x=2, or returns [x,y]. The observer returns
literal true. Thus a null body is erroneous but must never be selected, while
the second retained value is an error that must remain lazy until demanded.

| Probe | Required source and independent handmade-AST result |
| --- | --- |
| CK1: unused colliding object | An unused o.first binding returns 42 with no key/body observations; Program creation succeeds |
| CK1: collision on structural demand | std.type(o) rejects Runtime after observing (1,1)->first and (2,2)->first; no body runs |
| CK1: an early existing field cannot bypass a later collision | Direct o.first also rejects Runtime during construction, with both collision tuples present and zero body entries |
| CK2: mixed null/retained shape | [std.type(o),std.length(o)] is [object,2]. The four tuple/name observations are exactly (1,0)->null, (1,1)->first, (2,0)->null, (2,2)->second; no body runs |
| CK2: retained first body stays in its defining iteration | o.first returns [1,1], with only body tuple (1,1) observed; the retained second error and both null bodies remain unforced |
| CK2: actual second-value demand | o.second raises Runtime with retained-body-marker and only body tuple (2,2) observed |
| CK2: construction precedes selected value work | A sticky observer verifies all four successful key tuples were already present whenever any body entered |

Observer maps compare membership/name values, not key order or universal call
counts. CK1 does not require unrelated keys after a detected collision to run.
There is only one collision class, and body nonexecution distinguishes its
Runtime from the deliberately erroneous values. Entry identity and the explicit
body marker are embedding phase controls, not standardized diagnostic wording.

Trees are separately handmade with the neutral forms_ast helper, retaining
its virtual forms-ast entry identity; no parser export supplies their shape
or expectations. Every evaluation uses steps=5000, depth=48 and stack=64.
All domains and graphs are finite. No malformed-source Syntax equivalence is
claimed for typed ASTs.

## Review and stopping point

Inspect key evaluation/null filtering/duplicate rejection before value storage,
per-iteration child environments, captured field environments and array/local
preservation in AST conversion. Accept only this bounded dynamic-collision,
mixed-null and delayed-value capture contract if outcomes and dataflow agree.
Do not mark the whole object-comp or desugaring/substitution rows complete.

The starting 94-row matrix is 8 completed named rules, 1 relative constructor
review, 41 partial rows and 44 unreviewed rows. Existing N0/R0 assertion
questions remain separate and are not on these assertion-free paths.

One local worker at reduced priority, existing frozen dependencies and directed
native debug checks only. No full suite, remote/platform run, installation,
push, tag, imported-file, private-document or network I/O is included.
