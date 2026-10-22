# Inherited function fields: receiver retention criteria

Base source: dff979e20e5ebe759b81f8b162e031c40d711bab. Fixed official Jsonnet:
bbb38f1020be1f5aed560928fb839b2c448cefb4. Retained spec.html SHA-256:
bbac3701ef0316fc29de6c543049ae8f0f78c876bdd94fbf6ab845b2023a720a;
language.md SHA-256:
c55666af13894c8100c84fb053e647cd0ca516f3bb554d0ced29dfa83c3772be.
The expectations below are fixed before new execution, independently of Go/C++,
parser/export round trips or actual interpreter output.

## Gap selection from the current inventory

The inventory has 44 unreviewed rows and 42 partial rows. Relevant object-index,
object-inherit and SUBSTITUTION rows are partial. O2 already covers scalar
late-self rebinding and unchanged originals; F6 covers method defaults. The
missing high-risk combination is independent handmade ASTs plus inherited
function extraction after the base field was already demanded, sibling/descendant
receivers, and storing an extracted function in another object.

The unreviewed reflection builtins are not this gap. Full super layer lookup and
nested-root $ scope remain separate candidates; this batch selects neither.
No count or member inventory is used to declare object conformance.

## Fixed clauses and bounded acceptance

[Object indexing and inheritance](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#execution)
at spec lines 2215-2228 and 2293-2333 combine the receiver substitution at field
selection with inherited field bodies. Keyword substitution at lines 2038-2138
protects nested object boundaries, rather than turning a detached function into
a newly bound method on each call.

The [fixed language reference](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#inheritance)
at lines 368-372 explicitly assigns a field's current-object context when that
specific object's field is indexed. Lines 413-438 distinguish a fixed object
reference from dynamic self. Together with lexical function evaluation, this
requires an extracted function value to retain the receiver chosen during field
selection; copying that function value into a different field does not replace
its lexical receiver.

This group concerns ordinary field f=function()self.n, plain constant n
overrides, object extension, extraction and rehosting. The instrumented body
uses a virtual identity callback solely to observe demand. There are no super/$
expressions, object locals, assertions, computed keys, additive or hidden fields,
comprehensions, parameters/defaults or recursive method calls.

| Dimension | Independent required result, through source and handmade AST |
| --- | --- |
| Warm base and independent receivers | Force base.f()=1 before demanding extensions. Original, two siblings and a further descendant retain n=1/2/3/4 independently, including repeated detached calls |
| Rehosting boundary | Store the function extracted from the n=2 receiver in holder with n=99; holder.g() still returns 2 |
| Exact normal oracle | The predefined normal array is [1,2,3,2,1,4,3,1,2]; it is not computed from the tested output |
| Function-body laziness | Base lacks n, yet merely retrieving base.f and derived.f and inspecting their function type succeeds with zero body callbacks |
| Actual detached demand | The derived receiver supplies n=7; invoking its saved function returns 7 with the single body callback receiving 7 |
| Missing original field after healthy derived demand | First require derived.f()=7, record a checked callback, then invoke the saved base.f value; the base still lacks n and fails Runtime after Program creation. A bad derived result returns normally and must fail the test |

The error and callback event controls distinguish paths without inventing an
error-text or evaluation-order requirement among unrelated failures. Public
Runtime and entry identity are embedding phase controls. No universal cache
lifetime, callback memoization or failure-retry policy is inferred.

## Reuse, review and exclusions

Reuse O2/F6 for their exact scalar/default meanings rather than duplicating
those test groups or adding old executions to this batch. Inspect fresh
object/cache construction, receiver-specific field scopes, closure environment
capture and invocation through that environment to explain these outcomes
beyond just the array's cardinality. Source and handmade trees must be separately
authored; expected values/callback roles must not come from implementation output.

This closes only the specified receiver-retention group if its necessary cases
and dataflow review succeed. Entire object-index/object-inherit/SUBSTITUTION
rows remain partial. Arbitrary closure/binder algebra, super/$, nested objects,
assertions, visibility, field-name construction, equality, inheritance algebra,
host metadata, GC/reentry, resource limits, diagnostics and CLI/platform behavior
remain outside acceptance. All data are self-made; no private document,
imported-file or network I/O, full suite, remote run, new dependency, push or tag.
