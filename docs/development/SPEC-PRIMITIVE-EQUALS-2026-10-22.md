# Primitive equality: combined review and evidence

## Frozen criteria

Base: 979e2e4f1311dc63149e4d0cfffd7e6049c6eff0. Official Jsonnet:
bbb38f1020be1f5aed560928fb839b2c448cefb4. Scope: primitive scalar and
disjoint-type equality, finite numeric/String edges, demanded argument heads
and the unresolved same-type nonscalar boundary. Three interfaces are kept
distinct; no rejection or recursive behavior is transferred by analogy.

The [fixed primitiveEquals rule](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#execution)
requires both operands to evaluate to values and defines
`b = (v in String or Boolean or Number or v=null) and v=v'`.
For primitive pairs this is value equality without coercion; disjoint value
types cannot be equal. The [fixed value description](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#equivalence-and-equality)
also excludes equality across types and defines Strings as codepoint
sequences, finite binary64 Numbers and functions as values with unevaluated
bodies. Numeric +0/-0 compare equal under IEEE754; nonfinite producer
expressions must error rather than supply NaN/Inf as successful operands.
Exact finite 2^53 boundary integers and the already established finite
maximal/subnormal producers do not establish all conversion/rounding rules.

The [fixed == desugaring](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#desugaring)
uses the official equals function. The [official equals definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1582-L1616)
checks type names, then recursively compares array shapes/elements or visible
object keys/values, otherwise calls primitiveEquals. Thus a length-mismatched
array comparison can return false without forcing an element under equals
and ==; that is not a primitiveEquals rejection or recursion rule. Only
shared, independently justified scalar/disjoint-type answers are tested
across all three interfaces. Generic calls, std shadowing and full equals
or == semantics remain separate.

**PE0: fixed nonscalar-domain conflict.** The printed primitiveEquals rule
places primitive membership in its result conjunction, not as a premise.
Its literal total-predicate reading returns false for a nonprimitive left
value. Yet the official equals definition forwards same-type functions to
primitiveEquals, while the language description says function equality
cannot be checked, including some containers of functions. Treating all
same-type nonscalars as false would therefore make the fixed function
equality descriptions inconsistent. There is no fixed public primitiveEquals
documentation overriding this formula: the stdlib introduction delegates
primitive builtin semantics to the specification. The intended scope of
the formula versus runtime domain rejection needs adjudication. No guessed
missing precondition or implementation behavior repairs the paper rule.

Current implementation inspection separately shows cross-type false and
same-type Array/Object/Function rejection before payload traversal; older
[object_std tests](../../object_std_test.mbt) include those rejections with
only a non-Unsupported category check. These are implementation/compatibility
observations, not a normative oracle. Bounded CLI probes may collect actual
same-type rejection/recursive-interface outcomes with **null expected
verdicts**, preserving all exits/logs. They are not passing conformance cases
or fresh Go/C++ comparisons. Native-function equality remains unexecuted
here. PE0 blocks a complete primitiveEquals record; no product change is
justified solely by this conflict.

Reuse the unchanged [existing equality/shape controls](../../object_std_test.mbt),
[finite producer controls](../../spec_foundation_numbers_test.mbt),
[numeric token/overflow tests](../../number_literal_test.mbt) and
[Unicode identity review](SPEC-OBJECT-REFLECTION-EX-2026-10-22.md).
Existing source-only or exported-AST tests do not become independent typed
evidence. Their historical 539/539 execution belongs only to 5651ae9 Mac
debug, before later new tests. No old file or full suite is rerun here.

| Probe | Independent required outcomes |
| --- | --- |
| PG1: primitive truth table | Literal identity table for null, false, true, 0, 1, empty String, String 0 and String true; no type coercion. primitiveEquals/equals/== independently agree only on this shared domain. |
| PG2: finite and String edges | Both zero-sign orders and 1 versus 1.0e0 are equal; 2^53 and its predecessor differ; a maximal finite value equals itself; positive subnormal differs from zero. Composed/decomposed accents differ, literal/escaped astral spellings agree, NUL differs from empty but equals itself, case differs. |
| PG3: disjoint classes | Both directions of every distinct type among Null/Boolean/Number/String/Array/Object/Function return false, with erroneous array/object payloads and function bodies undemanded. A builtin function differs from Number in both directions. Separate equals/== mismatched array shapes return false without an element read; the same-type primitiveEquals result stays PE0. |
| PG4: demand and phases | One explicit failing operand at a time propagates its marker; either demanded overflow producer errors, and an unused whole call stays lazy. An unselected unknown operand rejects Static even in an unused call; unfinished source rejects Syntax. No multi-error ordering or nonfinite-success expectation exists. |

Sources and handmade public ASTs are constructed separately with neutral
ordering_*/sequence_*/reflection helpers; expected matrices, Booleans and
markers are literal. For two finite controls, direct typed numeric values
are independent from source decimal conversion; other raw token controls
do not hide conversion in host constants. No parser export, local evaluator
or upstream implementation generates expected answers.

All fixtures are bounded native debug, one worker at reduced priority,
steps=20000/depth=64/stack=96. Observational CLI probes use the same bounded
local evaluator, code supplied as arguments, no import or output file.
A0/B0/N0/R0 remain unknown; PE0 is additional and local to this domain.
No whole lexical/rounding/library acceptance, full suite, release/Linux,
remote/browser/install/push/private document or new dependency is included.
Any unambiguous product failure must be preserved before a minimal fix;
otherwise only tests/evidence/matrix change. Results follow the frozen prefix.

<!-- Criteria above are frozen before execution; evidence is appended below. -->

## Execution and adjudication

The first directed native debug run passed **4/4, exit 0**, in 10.051 seconds:

    nice -n 10 env RUST_LOG=error moon test spec_primitive_equals_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize

PG1 matches the literal primitive truth matrix through all three interfaces,
without coercing Boolean/Number/String. PG2 preserves the two zero-sign
orders, exact finite controls and literal String/codepoint identities. PG3
returns false for every disjoint type pair without reading error-valued
array/object payloads or invoking a function; the separate equals/== shape
gate controls also stay lazy. PG4 requires both operand heads, rejects either
overflow producer before comparison and preserves unused-call laziness,
Static and source-only Syntax boundaries. Source and independent typed AST
inputs agree. No primitiveEquals same-type nonscalar verdict is asserted.

Native check, required info then fmt, script fmt and matrix validation all
exited 0. Test bytes, product, public .mbti, reused tests and every prior
completion record stayed unchanged. No new metadata completion form is
introduced, so prior metadata negative suites need not be repeated. There
is no adjudicated product defect requiring a fix; PE0 prevents treating the
known nonscalar discrepancy as either an accepted implementation or a fully
specified repair. No semantic/full-suite rerun or upstream execution occurred.

## Separate PE0 observations

After the native test completed, one CLI sanity case returned true for
primitiveEquals(1,1). Six sequential, bounded local CLI probes recorded these
implementation outcomes with **expected=null and normative_acceptance=null**:

| Synthetic source case | Observed CLI outcome |
| --- | --- |
| primitiveEquals([],[]) | Exit 1, primitive array-domain error |
| primitiveEquals({}, {}) | Exit 1, primitive object-domain error |
| primitiveEquals(two functions whose bodies error) | Exit 1, primitive function-domain error |
| primitiveEquals(two arrays whose elements error) | Exit 1, primitive array-domain error |
| equals(function()0,function()0) | Exit 1, function equality error |
| (function()0)==(function()0) | Exit 1, function equality error |

The raw observations-input.json froze exact sources before these probes;
observations-result.json and individual observe-*.json preserve full argv,
stdout, stderr, duration and exits. Each command uses nice 10, moon run
cmd/main --frozen --target native -j 1 and explicit steps=20000/depth=64/
stack=96, supplying source by -e. JSONNET_PATH is removed from the child
environment; no import, private input or output file is used. A delayed
transport response was awaited until its original execution session was
known; the command was not replayed. All seven child runs were awaited.

These are current source-only local CLI observations, not Go/C++ comparisons,
independent-AST nonscalar proofs or passing language assertions. Native
function pairs were not executed. Existing API source inspection shows the
same-type rejection branches; that inspection does not supply a normative
oracle. No new hardcoded rejection expectation was added to a test or to
the matrix. PE0 remains a concrete blocker for same-type Array/Object/
Function primitiveEquals false versus rejection, and for reconciling the
printed rule with the fixed equals delegation and function-equality prose.
A fixed-source clarification or explicit normative adjudication is needed
before closing this part; no external issue has been opened.

The [94-row matrix](SPEC-LANGUAGE-MATRIX.md) is **14 completed named reviews
(6 static, 8 evaluation), 1 relative prose constructor, 60 partial and 19
unreviewed rows**. Only primitiveEquals gains a partial assertion mapping;
PE0 is explicit in its remaining obligations. The four PG evidence groups
cover only the scoped primitive/disjoint-type/demand subcontracts. The six
PE0 observations have no assertion-evidence mappings or acceptance count.
No full recursive equals/==, producer, lexical or rounding judgment follows.
A0/B0/N0/R0 remain unknown; PE0 is not used to weaken their boundaries.

Raw: /tmp/moonjsonnet-primitive-equals.s88ihvxc. baseline.json/before-run.json
pin the clean base/tree, fixed public-source hashes, inspected/reused files,
test, criteria, argv and budgets. first-result.json retains the first 4/4
pass; checks.json and matrix/validation.json retain metadata results.
Criteria-prefix SHA-256:
ad88def99c8f36997eb990df327da2e7d05c6a255ae5e5638a01b027d1d9981f;
executed test: 0d67a459511e3f84426e992d391337f87f8ac6fce084e267acc61e708dee9fe8;
passing log: 68e3eed91ee5d217ff66600d731275bc52d0148ef97ff479d64faef8d2e15499.
The frozen prefix and executed test remain byte-for-byte unchanged.
documentation-result.json and final result.json retain tracked/staged-only
documentation validation and exact commit/readback status. Local tools
remain moon/moonrun 0.1.20260920 (914d7da), moonc v0.10.14+7d59c7ec9,
Darwin arm64. The 539/539 integration still belongs only to 5651ae9, not
this enlarged suite. Temporary evidence is not an archival guarantee;
committed criteria/tests/metadata retain the bounded decision and PE0.

Next distinct candidate: makeArray's size/function domain and lazy indexed
element contract, first mapping existing sequence and callback evidence.
It has not been started here; PE0 should not grow into repeated behavior
microprobes without new normative evidence.

## Subsequent bounded applicability review

At base 56ef58b, a [strict same-version review](SPEC-MAKEARRAY-2026-10-22.md)
examined the Value grammar, value rule, stuck-execution model, metavalue
relations, public stdlib introduction, equals source and language equality.
It does not establish a Primitive-only applicability restriction: v ranges
over Value, and the primitive predicate is in the result equation. No found
passage defines metavalue equality only for Primitive. Conversely, treating
that relation as total makes the false result for a function F compared with
itself pass through equals/==, inconsistent with the language's rule that
observationally equivalent values cannot be unequal. A partial-relation
interpretation can avoid that conclusion, but its domain is not specified.

PE0 is therefore more precisely an underdefined **metavalue equality/rule
applicability domain**, with a conditional function self-equality conflict.
It is not an unconditional claim that all nonscalar primitiveEquals behavior
contradicts the language's separate == contract. Array/Object rejection
does not follow merely from the function restriction. The linked review
gives exact source ranges, applicable premises, both incompatible conclusions
under the total reading, and the minimum clarification needed. No new PE0
semantic test or interpreter change is justified; the original six null
CLI observations, raw hashes and historical outcomes remain unchanged.
