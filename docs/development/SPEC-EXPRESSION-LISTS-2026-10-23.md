# Expression list syntax and admission boundaries

## Frozen criteria

Base 7af550d6ee087ec5863334819154ff2906d2959d. Official Jsonnet remains
bbb38f1020be1f5aed560928fb839b2c448cefb4. The fixed
[surface grammar](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#abstract_syntax)
defines repetition/optionality (251-269), Array literals (299-308), calls
(370-381), locals (392-407), functions (453-467), bind (670-695), args
(697-716), params and param (720-743). In normalized notation:

```text
array    = '[' [expr {',' expr} [',']] ']'
function = 'function' '(' [params] ')' expr
call     = expr '(' [args] ')'
params   = param {',' param} [',']
param    = id ['=' expr]
args     = expr {',' expr} {',' id '=' expr} [',']
         | id '=' expr {',' id '=' expr} [',']
local    = 'local' bind {',' bind} ';' expr
bind     = id '=' expr | id '(' [params] ')' '=' expr
```

An optional trailing comma is inside the nonempty Array/parameter/argument
production; it cannot create an empty item or an empty comma-only list. A
local expression has at least one bind and no optional comma before its
semicolon. A missing expression, separator or matching delimiter is rejected
even in an unused binding or unselected branch. These are consequences of
the productions, not observed parser behavior. Comments act as whitespace
under the fixed [lexical rules](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#lexing).

| Group | Independent required outcomes |
| --- | --- |
| EL1 | Empty/single/multiple lists, allowed trailing commas, required/default formals, positional/named/mixed legal arguments, nested adjacent delimiters and local function bindings have the manually declared ordered shapes. Space/comment variants preserve the same shapes. Both source and independently built AST entries statically admit when unused and yield 42; error-valued f is not demanded. |
| EL2 | Leading/repeated commas, missing commas/expressions/closing delimiters, wrong separators, incomplete function bodies, empty/trailing-comma locals and an extra adjacent expression reject at source creation. Direct, unused-local and unselected-branch wrappers all reject. Malformed source has no claimed typed-AST counterpart. |
| EL3 | Valid list syntax with a free missing name parses as syntax but rejects Static through source and independent AST Program creation, including unused wrappers. Valid error-valued elements/defaults/supplied arguments/locals stay lazy when unneeded. Actual demand produces its isolated Runtime marker; a numeric callee instead fails Type only when demanded. Literal results/markers, not a parser or another interpreter, are the oracle. |

The [API contract](../reference/API.md) separates SyntaxDocument parsing,
Program static admission and evaluation. Syntax/Static/Type/Runtime tags and
entry identities are embedding checks; the fixed grammar does not define
these host diagnostic names. The test projects retained semantic syntax onto
Array/Func/Call/Local/Index and the existing precedence shapes, discarding only
locations/ranges. Expected constructors, ordered children, optional defaults
and argument names come from handwritten trees. AST admission/evaluation is
separate corroboration, not a proof of source syntax. No parser round trip or
interpreter-derived expected output is used.

Reuse PREC1-PREC5, LN1-LN3, OT1-OT3, AP1/AP3-AP7, F1/F5 and IF1 in their
original bounded scopes; do not rerun them. This batch does not complete all
expression alternatives, named/positional ordering or duplicate-identity
diagnostics, every child/binding/default rule, tailstrict, object/member/brace
application, comprehension/slice grammar, unparenthesized import extent,
unbounded nesting, source resources or Unicode policies. All prior
A0/B0/N0/R0/PE0, printed greater-than and malformed-||| limits remain intact.
SYN-EXPR can gain scoped evidence only and must remain partial.

Run three bounded native debug groups at nice 10, frozen -j 1, no parallel
testing. Preserve an actual failure before any minimal product repair. Use
schema v2 without extending metadata machinery. No full suite, upstream
comparison, remote/browser/install/push, private proposal or new dependency.

<!-- Criteria above are frozen before execution; append results below. -->

## Results

The first invocation stopped at compilation: the host fixture variable local
is reserved by MoonBit and deny-warn rejected it. No semantic test ran. The
original formatted test and compiler log are retained. Only that declaration
and its use were renamed to local_value; source samples, assertions and this
frozen criteria prefix stayed unchanged. This was a fixture repair, not a
Jsonnet product defect or an altered expected outcome.

The corrected first semantic invocation passed **3/3**, exit 0, in 9.622 seconds:
`nice -n 10 moon test spec_expression_lists_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize`.
Its SHA-256 remained
`a28036727517e12ab3e27243f613eafc56172aa764b0432192196cb1d1a793c0`
through final checks. No product repair or further semantic rerun was needed.

EL1 establishes the listed source shapes independently of evaluating an AST;
the separate unused Program checks admit both entries without forcing f.
EL2 rejects every listed malformed source in both parser-facing APIs and all
three wrappers before evaluation. EL3 instead admits valid syntax, then
rejects its missing child statically even when unused. Its legal error-bearing
lists distinguish dormant payload/default/supplied/local values from actual
Runtime demand, and a valid numeric-callee syntax from demanded Type failure.

Root check, info, fmt, script-format check and schema-v2 matrix generation each
exited 0. Product sources, interfaces, old tests, checker and harness remain
unchanged. All 182 old evidence objects, 68 named review records and 23 other
prose records were preserved; only EL1-EL3 and the SYN-EXPR row were added or
updated. The mapping now has **185 canonical case IDs**, not 185 new tests.

The 94-row matrix is **28 named complete (9 static, 19 evaluation), 1 relative
constructor complete, 62 partial, 3 unreviewed**. SYN-EXPR is partial: this
bounded list contract and the reused precedence/token evidence do not prove
all grammar alternatives or the excluded child/diagnostic/resource domains.
No unknown was converted to a passing rule. No old semantic group, full suite,
Go/C++ comparison, remote operation or push ran; the historical 539/539 result
still applies only to 5651ae9. Raw receipts are at
`/tmp/moonjsonnet-expression-lists.6hr79s3n`.

A useful next distinct contract is additive-field desugaring in DESUGAR-FIELDS,
using its explicit super-presence formula and existing inheritance/hidden-field
evidence, without reopening assertion N0/R0 or unrelated grammar questions.
