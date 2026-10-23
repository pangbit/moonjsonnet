# Strict Boolean negation

## Frozen criteria

Base: c08fc916f5e4407d6fcc88a08ee5c43fc98f1b5a. Fixed official Jsonnet:
bbb38f1020be1f5aed560928fb839b2c448cefb4. The adjacent not-true/not-false
rules are unreviewed and have an unambiguous complete Boolean input domain.
This batch reviews their result constructors and strict operand-head contract.

The [fixed rules](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#execution)
(2586-2600) require e to evaluate to true and yield false, or e to evaluate to
false and yield true. No not rule accepts another value kind. Execution
errors are modeled as stuck judgments (1764-1766). Thus there is no implicit
truthiness for numbers, strings, arrays, objects or functions. The operand
judgment must succeed when the negation is demanded; an unused whole
expression retains normal Jsonnet laziness.

Reuse US1/US2/US3 from the [static unary review](SPEC-UNARY-STATIC-EVIDENCE-2026-10-22.md):
scope checking even when unused, the demanded-null Type boundary and bare
prefix source Syntax. The chk-unary constructor remains separately scoped.
Those passed groups are not repeated. Null is covered by US2; new domain
fixtures address the other value classes and deferred payloads instead.

| New group | Independent required outcome |
| --- | --- |
| NB1 | Literal pairs true/false and false/true agree through source and independently constructed Unary ASTs. A Boolean-producing observation is absent for an unused negation and present for a demanded one. Membership records operand demand, not callback timing or universal invocation counts. |
| NB2 | Zero/nonzero numbers, empty/nonempty strings, empty/poisoned arrays and objects, and a closure with an erroring body reject Type after the head is obtained. No nested payload is manifested and no function is called. Builtin/native function values also reject Type with no observation. A directly erroring operand propagates its isolated Runtime marker; ignoring every whole failure yields 42. |

The normative result pairs are literal, not calculated by a host ! operator.
All source/AST constructions use neutral existing helpers and no parser
export. Type categories/unique markers and native observations are embedding
controls; human error text and callback order are not standardized. Runtime
Type rejection of a non-Boolean head must not become a Static rejection of
an otherwise well-scoped expression.

The two named judgments may be completed relative to their admitted Boolean
operand child. No complete operand producer, static/grammar constructor,
other unary operator, object assertion/inheritance or public native contract
follows. A restricted metadata form must pin both exact formulas, Boolean
operand/result values, the ! operator, head-only demand, child assumptions,
source/test hashes and exclusions. Its targeted rejection controls must pass.

Two native debug groups, nice 10, -j 1, no parallel testing, with existing
steps=20000/depth=64/stack=96 limits. Preserve first real failures before any
minimal product fix. No full suite, repetition of passed old groups, remote,
browser, installation, new dependency, release/Linux, push or private external
source. A0/B0/N0/R0/PE0, greater-than print conflict, malformed ||| tokenization
and surrogate questions retain their previous status. Relative cmp-result
completion is unchanged and does not imply whole comparison conformance.

<!-- Criteria above are frozen before execution; evidence is appended below. -->

## Evidence and decision

The first native debug execution passed 2/2 groups, exit 0. The tested file
SHA-256 is `92edd8ad7eaac31c60676c8c7f3882f440c78391edd58a16d47ee0942465e3ac`;
its bytes remain unchanged after formatting and checks. No interpreter code,
existing tests, expected outcomes or public interfaces changed. There was no
product failure to repair and no Go/C++ compatibility execution.

[NB1/NB2](../../spec_negation_test.mbt) exercise both independent entry paths.
NB1 observes only whether a demanded Boolean operand was reached. NB2 obtains
the Type category before any poisoned container payload or function body is
used; a required error operand instead propagates its isolated Runtime marker.
The reused US1-US3 records preserve static validation of unused expressions,
null rejection and source-only missing-operand Syntax. They were not rerun.

Inspection exhausts the local constructor: Unary evaluates its child in the
same environment; the Boolean gate accepts only Bool and rejects every other
outer Value kind without walking payloads; complement wraps the opposite Bool.
Typed AST conversion keeps ! and its child. This closes **not-true/not-false
relative to the admitted Boolean operand judgment**. It proves neither every
operand producer nor all unary, comparison, static, grammar or object rules.
The separate completed chk-unary and cmp-sign scopes are unchanged.

The restricted `boolean-negation-transfer` form pins the two fixed equations,
operator, Boolean domain, literal operand/result pair, head-only demand,
child assumptions, exclusions and inspected/test hashes. Ten targeted negative
controls rejected foreign-rule reuse, formula/operator/domain/operand/result
changes, payload-demand widening, missing child assumptions/exclusions and a
stale implementation snapshot, each before producing a matrix. Positive
readback passed with 163 unique canonical file::case identities and unchanged
real inputs. Existing schema-v2 whole-JSON uniqueness and case-local anchors
remain in force; prior controls were not repeated.

The coverage edit adds only NB1/NB2 and the two rule records. All 161 previous
evidence records, 63 previous rule records and 24 prose/grammar records retain
their exact meanings and original bytes outside the two insertions. The
matrix has **24 completed named rules (6 static, 18 evaluation), 1 relative
constructor transfer, 59 partial rows and 10 unreviewed rows**, totaling 94.
This is an inventory of scoped decisions, not a language conformance rate.

Native `moon check --deny-warn`, `moon info`, root formatting, tool formatting
and fixed-source matrix generation exited 0. Semantic execution ran once;
metadata negative controls did not evaluate Jsonnet programs. The formatter's
initial sandbox attempt completed but could not set niceness; subsequent
checks and metadata controls ran with the authorized nice-10 host invocation.
All commands were sequential. The tracked/staged documentation gate is
`moon run --frozen -j 1 tools/documentation.mbtx`; its final receipt is retained
with the delivery readback. Full-suite 539/539 evidence still belongs only to
5651ae9, before these new tests.

Raw local receipts, frozen criteria, first test source/log/result, mapping
insertion audit and directed metadata logs are under
`/tmp/moonjsonnet-negation.bwbfvet_`. They are outside the commit. No remote,
new dependency, proposal document or push is involved. A0/B0/N0/R0/PE0, the
printed greater-than conflict and other previously listed unknowns remain
open. A useful next independent contract is quoted/verbatim string lexing and
escape/error boundaries, with surrogate policy explicitly kept separate.
