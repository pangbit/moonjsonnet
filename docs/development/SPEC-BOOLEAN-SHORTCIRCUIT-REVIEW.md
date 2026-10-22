# Boolean operators: pre-execution criteria and completion boundary

Base source: 805e3705c26875f94a89e6460baa36f9b7fa90e2. Fixed official Jsonnet:
bbb38f1020be1f5aed560928fb839b2c448cefb4. Cached spec.html SHA-256:
bbac3701ef0316fc29de6c543049ae8f0f78c876bdd94fbf6ab845b2023a720a;
language.md SHA-256:
c55666af13894c8100c84fb053e647cd0ca516f3bb554d0ced29dfa83c3772be.
These criteria and literal outcomes precede execution. Neither implementation
output nor Go/C++ behavior defines an expectation.

## Fixed clauses and reused evidence

The [fixed specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#execution)
defines boolean-and-shortcut, boolean-and-longcut, boolean-or-shortcut and
boolean-or-longcut at 2542-2581. The shortcut rules require only false/true
respectively on the left and have no right-evaluation premise. The longcuts
require true/false on the left and transfer the required right result b.
chk-binary (1675-1679) checks both operand expressions, without a type premise
or runtime shortcut. Errors are modeled as stuck execution (1764-1766).
The [language example](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md)
at 154-159 independently explains short-circuit demand.

Existing source checks in moonjsonnet_test, spec_aggregate_test,
spec_foundation_calls_test and spec_string_calls_test already skip explicit
errors, overflow and invalid calls behind false && / true ||. Reuse that
established scope without adding their old executions to this batch or
repeating a standard-library overflow/call campaign. New tests need the full
Boolean table, independent handmade ASTs, lexical operands, necessary right
demand, dynamic-left versus static-child rejection, and skipped non-Boolean
right shapes. Neutral builders from spec_array_ordering_test are reusable;
none of its comparison groups needs to execute.

## Independent outcomes

| Probe | Required source and independent typed-AST result |
| --- | --- |
| BS1: all four Boolean input pairs | For (false,false), (false,true), (true,false), (true,true), literal (&&, ||) outputs are (false,false), (false,true), (false,true), (true,true). Operands read local x/y through named observers. Left is present; right is present only when the applicable longcut requires it. |
| BS1: whole operation unused | 42 with no observer IDs, including operations which would otherwise require the right operand. |
| BS2: invalid left outer kind | Each of null, number, string, array, object and function rejects at evaluation before the right observer or nested array/object/function payload. The same operation unused returns 42. |
| BS2: statically legal, non-Boolean right behind a shortcut | false && value gives false; true || value gives true for all six non-Boolean outer kinds. No right type check or nested payload is forced. |
| BS2: required failures | A left error propagates left-required without a right callback. true && error and false || error propagate right-required. Each unused whole operation returns 42. |
| BS3: skipped children remain statically checked | Unknown left or right names reject Static at Program creation, for both operators, shortcut/longcut left values and unused wrappers. Evaluation is never entered. |
| BS3: grammar boundary | Source missing either operand rejects Syntax. Typed Binary nodes cannot express missing children, so no AST Syntax counterpart is claimed. |

Observer maps compare ID membership, not a universal invocation count or an
order among independent callbacks. Type/Runtime names, virtual ordering-entry
identity and explicit marker strings are embedding phase controls. Normative
failure here is stuck execution; diagnostic wording is not standardized.

## B0: longcut non-Boolean right result remains unknown

Both printed longcut formulas say e_R evaluates to b without an explicit
Boolean membership premise or a local declaration of b's domain. Calling the
operators Boolean suggests a Boolean metavariable, but that alone is not an
explicit derivation of mandatory rejection for a non-Boolean right result.
The language example uses Boolean results and does not resolve that boundary.
Public std.all/std.any source definitions have their own explicit isBoolean
guards; those library contracts do not amend these operator rules.

Therefore only Boolean right transfer and required explicit errors have
independent verdicts in this batch. Forced non-Boolean RHS cases are not
executed as normative passing/failing probes. Do not infer a missing guard
from the current boolean helper, change the evaluator to guess an alternative,
or let Go/C++ behavior resolve B0. The longcut rows retain this specific
unadjudicated endpoint; more behavior microgroups cannot settle the text.

## Constructor review and stopping point

The two explicit shortcut judgments may be recorded complete relative to
their left-evaluation child only if execution and constructor inspection
agree: the matching left Boolean determines the result without evaluating or
type-checking the right at runtime, while independent static validation still
visits both operands. This does not complete the child evaluator, chk-binary,
grammar, host AST admission or longcut judgments. The two longcut rows receive
reviewed Boolean/error subset evidence and retain B0, not a completed record.

Inspect the shared environment passed to both operands, exhaustive Boolean
gate, host-language shortcut expression, source/AST preservation and static
two-child traversal. Keep the existing N0/R0 assertion questions unchanged.
All fixtures are finite and assertion-free, bounded by steps=5000, depth=48
and stack=64. Use one reduced-priority worker with frozen local dependencies;
no full suite, remote/browser/CLI run, installation, push, tag, private/imported
file or network I/O is included.
