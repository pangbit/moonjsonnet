# Super prefix with final self: pre-execution criteria

Base source: 43f491d8c7f5f4367fb919408ebceb3432824179. Fixed official Jsonnet:
bbb38f1020be1f5aed560928fb839b2c448cefb4. Cached spec.html SHA-256:
bbac3701ef0316fc29de6c543049ae8f0f78c876bdd94fbf6ab845b2023a720a;
language.md SHA-256:
c55666af13894c8100c84fb053e647cd0ca516f3bb554d0ced29dfa83c3772be.
These expected values and demand paths precede new execution. Neither Go/C++
nor implementation output selects the oracles.

## Bounded contract and fixed clauses

The [fixed language reference](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#inheritance)
at lines 368-372 defines a layered object: self searches from the final top;
super starts below the current defining layer. Field context belongs to the
particular object being indexed. Therefore selecting a lower field through
super preserves the final receiver for that field's transitive self references.

[Object indexing/inheritance](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#execution)
at spec lines 2215-2228 and 2293-2333 supplies the receiver/prefix substitution.
Keyword substitution at lines 2038-2138, combined with lexical function
evaluation, preserves a selected function's defining super prefix after
extraction and rehosting. The [hidden-status rules](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#hidden_inheritance)
at lines 1867-1890 do not remove fields from direct lookup; object-index has
no visibility filter. Missing prefix fields have no successful lookup, and
explicit error payloads fail only when demanded.

This group uses ordinary named fields, plain object extension, zero-argument
functions, constant overrides and one hidden prior-layer field. It excludes
object assertions/locals, additive fields, computed keys, nested objects/$,
comprehensions, parameters/defaults and full inheritance/visibility algebra.

## Independent normal and failure oracles

| Probe | Required outcome through source and separately handmade AST |
| --- | --- |
| Multilayer prefix and final self | A defines n=1,v=self.n; B overrides n=2,v=super.v+10 and defines f()=[super.v,self.n]; C overrides n=3,v=super.v+100 and defines outer()=super.f(); D overrides n=4,v=999 |
| Extracted lexical prefix | B.v=12, C.v=113, D.v=999; C.outer()=[3,3], D.outer()=[4,4]. Extracted C.f, that same function stored in holder with n=99/v=999, and D.f yield [3,3], [3,3], [4,4] |
| Exact normal array | [12,113,999,[3,3],[4,4],[3,3],[3,3],[4,4]], written directly rather than generated from output |
| Hidden prior field | A has n=1,h::self.n; B adds read=super.h; C overrides n=7,h=99. [B.read,C.read,C.h] is [1,7,99]: hidden h remains directly reachable through the proper prefix and its self is still C when C.read is selected |
| Current/newer names cannot repair a missing prefix | A has no x; B has x=42 and f() reading super.x; C has x=99. Even after reading C.x=99, the extracted C.f must fail when its body demands super.x |
| Hidden erroneous prior field | Replace A by x::error with a fixed marker. After C.x=99 has been read, the same extracted function must demand the hidden A.x error, rather than reusing a current-layer cached x |
| Failure timing | Programs create successfully. Function-type inspection and an unused invocation leave the body-entry callback at zero; actual invocation records one body entry and raises Runtime. The explicit-error variant must retain its predefined marker |

A guard checks C.x=99 before each timing probe, so an incorrect current lookup
cannot be counted as the intended prefix failure. The body-entry callback
separates body execution from construction/selection. Runtime categories, entry
identity and the literal marker are embedding controls, not general prescribed
diagnostic wording, failure ordering or cache/retry policy.

## Existing evidence, review and open scope

O2 already covers scalar super with late self; F6 covers lexical super in method
defaults; O6 covers the nine visibility separator pairs. SR1-SR3 cover detached
self receivers. Reuse those mappings without duplicating the groups or adding
their old executions to this run. New cases target lower defining-layer scope,
not another general function/default or visibility campaign.

Inspect object layer concatenation, full-self versus prefix-super bindings,
field search below the prefix, per-layer cache keys and retained closure
environments. Necessary executions plus this dataflow review support only the
bounded contract. Entire object-index/object-inherit/SUBSTITUTION and hidden
inheritance rows remain partial. All other child rules, missing-field/type
matrices, visibility/equality laws, assertions, GC/reentry, resource limits,
host metadata, diagnostics and CLI/platform behavior remain open.

Fixtures are self-made strings/ASTs and virtual callbacks, without imported
files, private documents or network I/O. No full suite, remote run, dependency
installation, push or tag is included.
