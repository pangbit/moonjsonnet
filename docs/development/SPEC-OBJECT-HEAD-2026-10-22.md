# Object length/type transfers: combined record

## Frozen criteria

Base: 3726b0e58ef6c83f855b87f2aa19b82a92e1b754. Official Jsonnet:
bbb38f1020be1f5aed560928fb839b2c448cefb4. The matrix has unreviewed
length-object and partial type-object, whose remaining text names computed
key failures. Both share the evaluated Object-head premise, so one small
batch reviews their transfers and the same necessary construction controls.
No further object/assertion microgroup is introduced.

The [fixed length-object rule](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#execution)
prints the premise `std.length(std.objectFieldsEx(e,false) down n`, with one
closing parenthesis missing. Preserve that exact source in metadata. The
explicit interpreted composition is `std.length(std.objectFieldsEx(e,false))
down n`: the field-name array is the sole argument of length. The completed
object-fields-ex transfer with literal false and length-array count transfer,
together with the [public length description](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#std-length),
corroborate that reading: count unique visible names, including forced-visible
fields and inherited names after override. This delimiter blemish supplies
no competing hidden/all-fields or field-value interpretation; it is not a
silent source repair or a newly inferred general rule.

The same fixed section defines type-object by `e down v in Object` implying
`std.type(e) down "object"`. A ready Object head suffices; values need not be
read. Any construction/key error prevents either transfer from receiving
that head. The old type-object remaining text concerns this producer child:
completion here will assume that child judgment, not falsely claim every
computed-key producer/AST form is now tested or complete.

Reuse the [object-fields-ex review](SPEC-OBJECT-REFLECTION-EX-2026-10-22.md)
for all separator combinations, inherited deduplication, Unicode identity,
and payload/assertion non-demand. Reuse the
[length-array transfer](SPEC-SEQUENCE-STRUCTURE-2026-10-22.md),
[length overload controls](../../spec_length_test.mbt), and
[type tags/laziness](../../spec_foundation_types_test.mbt). Existing TYPE,
TYPELAZY/O4 and Ex assertions are source-bound mappings, not new executions.
The [matrix](SPEC-LANGUAGE-MATRIX.md) records object-fields-ex and length-array
as completed relative to their own children, not whole-language axioms.
Do not repeat the nine separator cases or assertion closure/reentry tests.
Only the following missing consumer combinations are new:

| Probe | Independent required outcomes |
| --- | --- |
| OH1: counts and tag | Each observation is [length(o), type(o), length(fieldsEx(o,false)), length(fieldsEx(o,true))]. Empty gives [0,object,0,0]; hidden-only gives [0,object,0,1]; base with two visible/one hidden gives [2,object,2,3]; override/hidden/forced-visible/new-key overlay gives [3,object,3,4]. Empty String key plus an omitted null key gives [1,object,1,1]. Every field payload errors but remains unread. Expected counts are literal counts of frozen key sets, not derived from observed Ex output. |
| OH2: common child boundary | Isolated required object-head and computed-key errors propagate their fixed marker through length/type; an unused whole call stays lazy. Unknown hidden field expressions reject Static even when the summary is unused. Only unsupported Null/Boolean/Number length arguments reject Type; Array/String/Function overloads are separate and are not declared invalid object inputs. |

Every source and public AST is independently built with neutral existing
object/array/call helpers. No parser-exported tree or runtime value creates
an oracle. New objects contain no assertions; old assertion evidence is
reused only to characterize the assumed ready head and transfer non-demand.
N0/R0 rewriting/reentry, full object construction/inheritance, all child
expression/static judgments, std rebinding/generic invocation, other type/
length overloads and resource/encoding/rounding/Go-C++ acceptance stay out.
A0/B0/PE0 also remain unchanged. Error labels are embedding controls, not
normative wording or competing-failure order requirements.

If constructor inspection and execution agree, record only length-object
(under the explicit composition reading) and type-object completed relative
to their children. A restricted metadata form must pin raw and interpreted
statements, Object domain, result, head-only demand, dependencies and mandatory
N0/R0 exclusions; malformed controls must reject before emitting output.
The required official stdlib.html snapshot is pinned alongside spec/language.

Two bounded native debug groups, nice 10, -j 1, no parallel test execution,
steps=20000/depth=64/stack=96. No old semantic/full-suite repetition, remote,
release/Linux/browser/install/push, private document or new dependency.
Preserve any true first failure before a minimal product fix; otherwise
only evidence/tests/matrix change. The exact prefix is frozen before running.

<!-- Criteria above are frozen before execution; evidence is appended below. -->

## Result and bounded decision

The first directed native debug run passed **2/2, exit 0** in 5.193 s, with
both source parsing and independently constructed public AST admission.
No interpreter change was needed. Executed test SHA-256:
`026febcc69f4f2f243685569002b81c44fc8ed176aabe15f7e36a970eda648de`;
log SHA-256:
`ddd0722f90fd133207ca9e423fc1faa05c3608f3be5c5eb4fdbea4259682b120`.
All reused tests, product sources and four fixed official snapshots retain
their pre-run bytes. This run does not repeat or extend historical totals;
the full 539-test result remains bound only to 5651ae9.

The [length implementation](../../stdlib.mbt) counts
`self.keys(id, top, false)`, exactly the vector used by the completed
object-fields-ex(false) transfer. Each Ex element is a ready String, so the
completed length-array child yields that vector's cardinality. The
[key helper](../../objects.mbt) supplies unique inherited names filtered by
effective visibility, with no field read. This establishes length-object
under the explicitly stated composition reading, within admitted host
bounds. It reuses the Ex visibility proof instead of re-proving inheritance.

The same intrinsic dispatcher forces the argument head before selecting
either overload. A child failure propagates; a ready Object reaches the
exhaustive `ObjectValue(_, _) => "object"` tag arm. Neither transfer visits
field values or pending assertion bodies. Thus type-object is complete
relative to the evaluated Object child. Its old computed-key-failure gap is
not reclassified as every producer case having passed: child construction
remains assumed, while OH2 verifies two concrete propagation boundaries.

The restricted metadata form accepts only these two rules, their exact raw
and interpreted statements, Object domain, head-only demand and required
dependencies/exclusions. **10/10 isolated negative controls** rejected at
their intended guards before emitting output: foreign rule, repaired raw
text, changed interpretation/domain/result/demand/dependency, missing child
assumptions/N0-R0 exclusion, and stale inspected implementation. The real
mapping and sources were unchanged by these controls. Native `moon check`,
`moon info`, `moon fmt`, script format check and matrix validation exited 0;
no public `.mbti` changed. A preparation-only anchor mismatch was corrected
before writing the mapping; executed tests and expectations never changed.

The 94-row matrix now records **16 completed named judgments** (6 static,
10 evaluation), **1 constructor transfer relative to children**, **61
partial**, and **16 unreviewed**. These are scoped review decisions, not a
language conformance rate. A0/B0/N0/R0/PE0 and the existing non-Boolean filter
question remain unresolved; no Go/C++ acceptance claim is added.

Raw frozen criteria, first run, source identities, metadata controls and
checks: `/tmp/moonjsonnet-object-head.zsklolzd`. The next distinct priority is
the unreviewed string-concat rule: its toString/manifestation dependency can
force nested values, so coercion and error/laziness boundaries need their
own fixed oracle. That work is outside this batch.
