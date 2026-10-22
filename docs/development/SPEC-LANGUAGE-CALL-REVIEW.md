# Application entry paths: expectations before probes

Starting source: `e61af72`. Fixed sources are Google Jsonnet
`bbb38f1020be1f5aed560928fb839b2c448cefb4`:
[specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html)
(`chk-apply`, `chk-function`, `apply`, substitution and local recursion) and
[language reference](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md)
(lexical scope, Function and Function Parameters). Expectations below precede
the first new execution and are independent of reference-implementation output.

Existing F1-F6, spec_static, arguments and ast tests already cover ordinary
source argument reordering, scalar forward defaults, unused recursive defaults,
ordinary invalid binding nonexecution and duplicate declarations. Those are
regression controls, not newly discovered gaps. The remaining selected dimensions
are handmade valid/invalid calls, finite recursive function-valued defaults and
callee-versus-argument forcing. No new fully covered rule is claimed.

| Selected dimension | Independent expected outcome |
| --- | --- |
| Function-valued defaults close over formal bindings | `local x=10,f(a=x,g=function()a)=g(); local a=99; [f(),f(20),f(g=function()a)]` gives `[10,20,99]`; construct the equivalent AST without parsing |
| Default closures may recurse through other formals | Mutually recursive default functions f/g capture the same call's x; default x=42 and supplied x=7 yield `[42,7]` despite outer x=100 |
| Handmade AST binding follows ordinary application | Missing/unknown/positional-plus-named duplicate/extra arguments create a Program then fail Runtime, with zero supplied-argument/default/body native callbacks |
| Callee evaluation precedes argument demand | A native head returning 7 runs once, then application fails Type with zero argument callbacks; an error-valued head raises its exact Runtime marker before arguments |
| An object head is not manifested as a prerequisite to rejecting a call | Calling an assertion-bearing object fails Type, without checking its assertion or argument payload |
| Unused invalid runtime calls remain lazy | Calls with non-function heads or invalid bindings inside unused locals/branches return 42 and execute zero head/argument callbacks |
| Semantic invalidity is checked before binding | Duplicate named arguments and undefined supplied expressions reject Static even in unused calls; handmade ASTs are tested separately |
| Malformed source cannot form a Program | Missing default/argument expressions or closing delimiter reject Syntax; this has no malformed-text equivalent in a handmade semantic AST |

Missing/unknown/duplicate/extra ordinary binding expectations retain the existing
reviewed application contract. Exact error wording is a tool contract; new native
counters test nonexecution. Static and runtime cases use separate Program
creation/evaluation steps. Source syntax failures are not labeled handmade-AST
static failures. Positional-after-named fine diagnostic classification and
tailstrict forcing/order are not newly adjudicated here. No stdlib parameter-name
conflict, divergent-default resource category or Go/C++ equivalence is decided.

Only focused single-worker native checks and a small independent source CLI
corpus are planned. CLI source/runtime rendering and exit 1 are checked separately
from the library's Syntax/Static/Type/Runtime kinds. No full aggregate, release,
remote or platform campaign is part of this batch.
