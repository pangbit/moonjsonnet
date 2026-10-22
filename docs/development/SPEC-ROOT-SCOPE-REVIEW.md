# Nested lexical root scope: pre-execution criteria

Base source: ff3e77c82e45131c837909c4cc6acb2a78614e70. Fixed official Jsonnet:
bbb38f1020be1f5aed560928fb839b2c448cefb4. Cached spec.html SHA-256:
bbac3701ef0316fc29de6c543049ae8f0f78c876bdd94fbf6ab845b2023a720a;
language.md SHA-256:
c55666af13894c8100c84fb053e647cd0ca516f3bb554d0ced29dfa83c3772be.
The following inputs and expected outcomes precede new execution. No Go/C++
or actual interpreter output determines them.

## Exact normative basis and bounded scope

The [fixed desugaring specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#desugaring)
at lines 1131-1165 starts desugaring with object-context flag false, adds the
object-local binding $=self when that flag is false, and leaves existing binds
alone for an object already lexically inside another object. The function rule
at line 1208 passes the same definition-context flag into the body. Thus $ is
a lexical root binding, not a process-wide root or the most recent caller's self.

Inheritance/indexing at lines 2215-2228 and 2293-2333 gives the outer root
binding its receiver: selecting an inherited outer field can bind its root to
the derived outer receiver. A nested object's own self is separate. Extending
an already selected nested object does not rewrite inherited fields' captured
outer root; a newly added standalone object literal may introduce its own $.

The pinned language page still lists precise $ semantics as unfinished in its
lines 655-661 comment. This batch relies on the explicit object/function
context rules above, not an invented complete prose definition or Go/C++ parity.
It does not adjudicate the full desugaring system, computed keys, object locals,
comprehensions, super/additive/hidden fields, assertions or arbitrary binders.

## Independent required outcomes

| Probe | Expected result through source and separately handmade AST |
| --- | --- |
| Nested self differs from root | Root tag=10 and inner tag=1 give an extracted inner f()=[$.tag,self.tag] result [10,1] |
| Outer versus inner inheritance | Deriving outer tag=20 gives [20,1]; extending the selected original/derived inner objects to tag=2/3 gives [10,2]/[20,3], retaining their lexical outer roots |
| New standalone right-hand layer | The derived inner is extended outside any object with tag=3,localRoot=$.tag; its inherited f still returns [20,3], while localRoot is 3 |
| Function extraction/rehosting | Saving that inherited function and storing it in a holder with tag=999 retain [20,3]; the original root.inner function still returns [10,1] |
| Exact first oracle | [[10,1],[20,1],[10,2],[20,3],3,[20,3],[20,3],[10,1]] |
| Factory definition controls root scope | A factory defined outside objects returns its own root tag=30 and inner tag=4 even when called from a root field. An inside-root factory returns an object with tag=40/inner tag=5 but retains its defining root tag=10, or 20 when selected from the derived outer root |
| Exact factory/extraction oracle | [[30,4],[10,5],[30,4],[20,5],[30,4],[10,5]]; saved factory and extracted result functions retain those lexical roots |
| Runtime root failure is not inner self | Inner needed=99 is read first. Its saved function then reads $.needed, which is missing or an explicit root error. Metadata and unused invocation return function/42 with zero body entries; actual invocation enters once then raises Runtime, preserving the explicit error marker |
| A caller cannot grant a missing lexical root | A global getter=function()$.needed remains Static even if its invocation is a field of an object with needed=99; both entry paths reject at Program creation |

Numeric/array expectations and callback roles are explicit. The body-entry
callback and inner-value guard separate true root demand from premature failure
or wrong inner selection. Static/Runtime, entry identity and the literal marker
are embedding phase controls, not general mandated diagnostics or error ordering.
No malformed-source Syntax equivalence is claimed for typed ASTs.

## Reused controls and limitations

O2 already distinguishes scalar nested self/$ under outer inheritance; C6
contains a source/exported-AST comprehension root control. SR/SP cover detached
self and super receivers. Reuse their exact assertion meanings without repeating
their groups or counting their older executions as current. New handmade trees
must not come from parser/export round trips.

Inspect preservation/introduction of the root binding in field environments,
closure environment capture and definition-environment invocation, plus AST
preservation of Var("$") and static rejection outside object scope. The review
is bounded to ordinary named fields, plain extension and zero-argument factories
or functions, with finite literal values. Entire DESUGAR-ROOT/object/substitution
rows remain partial, regardless of the outcome.

Other root/key/local/comprehension/default combinations, full inheritance and
closure algebra, host metadata, GC/reentry, resources, traces and CLI/platform
behavior remain open. Fixtures are self-made virtual callbacks without imported
files, private documents or network I/O. No full suite, remote run, dependency
installation, push or tag is included.
