# Precedence: combined review and evidence

## Frozen criteria

Base: 5651ae9f9ddb04af66ceff9ab0eea39171ab9f3b. Official Jsonnet:
bbb38f1020be1f5aed560928fb839b2c448cefb4. Scope: the explicit operator
table, left association, parentheses, call/index chains and the maximal
right extent of five expression-bearing forms. This is a cohesive syntax
review with independent typed groupings and selected demand controls, not
completion of expression grammar, operator evaluation or desugaring.

The [fixed associativity and precedence section](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#associativity_precedence)
orders these tiers from highest to lowest:

1. Call, bracket index and dot access.
2. Unary `+ - ! ~`.
3. Binary `* / %`.
4. `+ -`.
5. `<< >>`.
6. `< > <= >= in`.
7. `== !=`.
8. `&`.
9. `^`.
10. `|`.
11. `&&`.
12. `||`.

The same section specifies left association, parentheses overriding
grouping, and maximal right consumption for assert/error/function/if/local
and the three import forms. The
[surface grammar](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#abstract_syntax)
and [dot desugaring](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#desugaring)
determine the constructors. This table is transcribed independently into
the test; neither parser precedence numbers nor observed output constructs
an expectation. For each `a L b R c`, an earlier or tied L tier means
`(a L b) R c`; otherwise it means `a L (b R c)`. These are declarative
consequences of the fixed table, including all same-tier operator pairs.

The grammar gives imports a string terminal, while the maximal-RHS prose
also names imports. This batch does not settle unparenthesized trailing
operators as an import-extent/grammar judgment. It uses only unambiguous
parenthesized import leaves, without resolving any file. Object brace
application is also outside the explicit table review. These exclusions
prevent a whole SYN-PRECEDENCE completion claim, regardless of passing grids.

| Probe | Independent required outcomes |
| --- | --- |
| SP1: binary table | All 19x19 ordered symbol pairs have exactly the specified tree and left association on ties. Explicit right parentheses override every symbol's association; mixed-tier parentheses override precedence. |
| SP2: unary | Each of four unary symbols binds above each of 19 binary symbols on either side. Nested prefixes preserve their syntactically ordered operands; parentheses can expand a unary operand. |
| SP3: postfix | All nine call/index/dot chain pairs nest left. Each postfix form binds above every unary and binary tier on either side. Slice brackets retain the same postfix extent. |
| SP4: right extent | Local/function/assert/error/if constructors own their right-hand expression tails. Cases include a local or if on a binary RHS, assert condition/message/body delimiters, nested-if else binding and an explicit parenthesized-if boundary. Parenthesized code/text/binary import leaves have an explicit endpoint and stay unresolved. |
| SP5: observable boundaries | 8-3-1, 32/4/2 and 16>>1>>1 yield 4; 1+2*3 yields 7 versus parenthesized 9; 1<<1+2 yields 8; ~1+2 yields 0. If extent gives 1 versus parenthesized 4. Function-call multiplication gives 9; unary over a called identity then +4 gives 2. Boolean grouping preserves a dormant error and forces only the required marker. `error 'a'+'b'` raises ab, versus parenthesized error raising a. Chained comparison admits then fails Type; an unselected unknown name rejects Static; malformed source rejects Syntax. |

Parsed trees are projected to constructor/symbol/raw-number/ordered-child
shapes and compared with separately manufactured typed trees. Only source
locations/ranges are discarded. Symbols, binders/defaults, argument names,
strictness and optional children remain distinct. The syntax projection is
not an evaluation oracle. Both source and handmade mixed-type grids undergo
Program static/admission checks inside a bounded a/b/c environment and an
unused binding yielding 42; their intentionally mismatched runtime types
are never forced. Selected semantic answers above are literal, not generated
by the parser, another interpreter or the structural projection.

Reuse [raw syntax controls](../../raw_ast_test.mbt),
[operator token boundaries](../../parser_diagnostic_test.mbt), and the
[Boolean](SPEC-BOOLEAN-SHORTCIRCUIT-EVIDENCE-2026-10-22.md),
[unary](SPEC-UNARY-STATIC-EVIDENCE-2026-10-22.md) and
[conditional](SPEC-CONDITIONAL-EVIDENCE-2026-10-22.md) reviews. Existing
round trips do not become independent AST or precedence proofs. Their
current execution is the explicitly authorized 5651ae9 integration run,
separate from the upcoming five directed groups. B0's forced non-Boolean
RHS domain and A0/N0/R0 remain unadjudicated. Complete number lexing,
conversion rounding and fresh Go/C++ compatibility remain unproved.

No product change is planned without a preserved failure against this
oracle. New fixtures are finite, native debug, one worker at reduced
priority, steps=20000/depth=64/stack=96. No further full suite is planned
without a new product defect justifying a run bound to its final commit.
No release/Linux/remote/browser/install/push, private document or new
dependency is included. Results will be appended after this prefix is frozen.

<!-- Criteria above are frozen before execution; evidence is appended below. -->

## Integration at the numeric fix

The parent explicitly authorized one Mac native debug whole existing suite
at **5651ae9f9ddb04af66ceff9ab0eea39171ab9f3b**, because numeric lexing is a
shared entry point. Before starting, HEAD/tree were verified, the worktree
was clean and no MoonBit compiler/test worker was running. The command was:

    nice -n 10 env RUST_LOG=error moon test --target native --frozen --deny-warn -j 1 --no-parallelize

It passed **539/539, exit 0**, in 45.286 seconds. HEAD and the clean worktree
were unchanged afterward. Raw:
/tmp/moonjsonnet-native-integration.1l9iek65; result.json pins the commit,
tree, argv, duration and output SHA-256
90712195ff496697f90acecdfdec58f6e348f6690a0f5e169aa128eb14211b1b.
This is the newly measured 5651ae9 Mac debug integration result, separate
from older platform totals, release/Linux and external CLI shell scenarios.
It preceded the new precedence fixtures; it is not a claim that a later
commit's full enlarged suite has run. No further whole suite was needed
because this batch makes no product change.

## Directed execution and adjudication

The first directed command stopped at compile time: four C-style for-loop
updates used unsupported `+=` syntax. No semantic test ran. Their updates
were changed only to `name = name + 1`, then formatted. The first test bytes
and compiler log are retained. All groupings, literal outcomes and the frozen
oracle prefix stayed unchanged. The corrected five groups passed **5/5,
exit 0**, in 15.214 seconds:

    nice -n 10 env RUST_LOG=error moon test spec_precedence_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize

SP1 verifies the entire literal binary table, every same-tier left grouping
and the explicit parenthesis overrides. SP2 verifies the unary tier in both
binary positions and prefix nesting. SP3 verifies all call/index/dot chain
pairs, their unary/binary boundaries and the two slice extents. SP4 verifies
the five expression-bearing right extents, nested-if delimiters and the
unambiguous parenthesized import leaves. SP5's fixed numeric/Boolean results
and error markers discriminate grouping with actual source and independent
AST evaluation; Static/Type/Runtime/Syntax remain distinct. The mixed-type
structural grids stay inside an unused binding and are not forced. No import
resolver/file access, product defect or interpreter change occurred.

These establish the bounded explicit-table and five-form contracts above.
They do not establish complete SYN-PRECEDENCE: the unparenthesized import
string-terminal/maximal-RHS interaction, braced object application and all
named/default/tailstrict/comprehension grammar boundaries remain outside
this decision. In particular, existing computed-import diagnostics are not
used to infer a new normative import-extent oracle. The table/projection
also does not prove all child/operator evaluation, token languages or source
resource policies. B0's non-Boolean RHS is still untested/unadjudicated here;
A0/N0/R0, full numerical rounding and fresh Go/C++ compatibility are unchanged.

Native check, required info then fmt, script format check and fixed-source
matrix validation all exited 0. The executed test bytes did not change;
product files, reused tests, public .mbti and every existing named completion
record are unchanged. Matrix schema is unchanged, so its old negative-control
suites are not rerun. Only SP1-SP5 evidence and the SYN-PRECEDENCE clause
gain new mappings; no completion is added. The
[94-row matrix](SPEC-LANGUAGE-MATRIX.md) has **12 completed named reviews
(6 static, 6 evaluation), 1 relative prose constructor, 59 partial and 22
unreviewed rows**. No conformance rate is inferred from grid/test counts.

Raw: /tmp/moonjsonnet-precedence.2tc65px3. baseline.json/before-run.json pin
the base/tree, inspected and reused source hashes, fixed public documents,
criteria, test, argv and evaluator limits. first-result.json preserves the
compiler-only failure; corrected-result.json preserves the actual 5/5 pass;
checks.json and matrix/validation.json preserve local metadata results.
Criteria-prefix SHA-256:
9fc3f423eec7e42bde1493bb4f84652c2a89165119dc86306412b4c82a9cb29f;
executed corrected test:
77c48b9b7cc730acd6bb1044319768ea6afb4c82214c5a03a75ba529dfe0456a;
passing log: 30a04d9fb9b3e8b0c88d173d0654b97191bd61de5cd6b067b91b74f25115ca4a.
The frozen criteria prefix is preserved byte-for-byte. The raw
documentation-result.json and final result.json record tracked/staged-only
documentation validation and exact commit/index/worktree readback. All test
workers are sequential and awaited; local tools remain moon/moonrun
0.1.20260920 (914d7da), moonc v0.10.14+7d59c7ec9, Darwin arm64. Temporary
evidence is not an archival guarantee; committed criteria/tests retain
the bounded contract. No full enlarged-suite, remote or push claim is made.

Next candidate: the unreviewed object-has-ex/object-fields-ex visibility,
inherited-key and value-laziness contract, first mapping existing object and
stdlib assertions. It has not been started here.
