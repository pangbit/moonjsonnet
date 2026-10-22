# Boolean operators: four-rule review and bounded execution evidence

**Decision: boolean-and-shortcut and boolean-or-shortcut are complete transfer
judgments relative to their left-evaluation child.** The four-rule review also
verifies Boolean longcut results and required errors, but leaves both longcut
judgments partial because B0, the printed right-result domain, is unadjudicated.
No interpreter fix or whole child/static-language completion follows from the
passing tests. The [pre-execution criteria](SPEC-BOOLEAN-SHORTCIRCUIT-REVIEW.md)
pins these distinctions and the independent expectations.

## Fixed clauses and reused controls

The [official specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#execution)
at bbb38f1020be1f5aed560928fb839b2c448cefb4 supplies the four rules
(2542-2581). Each shortcut has one left-Boolean premise and no right-evaluation
premise. Each longcut instead requires the right result. chk-binary checks
both operand expressions (1675-1679); execution demand does not change that
static obligation. The
[fixed language reference](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md)
explains short-circuiting with a lazy function argument (154-159).

Existing [basic language tests](../../moonjsonnet_test.mbt),
[aggregate controls](../../spec_aggregate_test.mbt),
[foundation call controls](../../spec_foundation_calls_test.mbt) and
[string call controls](../../spec_string_calls_test.mbt) already skip explicit
errors, overflow and invalid calls behind false && / true ||. BS0 now maps
the existing foundation-call assertions without a fresh execution, new AST
claim or new public-library acceptance. The other retained controls keep
their original source-bound histories. This batch repeats no library-error
campaign and adds none of those earlier test/platform totals.

The [new file](../../spec_boolean_shortcircuit_test.mbt) reuses only neutral
builders from [array ordering](../../spec_array_ordering_test.mbt). They pair
separately constructed typed nodes with source and preserve the virtual
ordering-entry identity; no Boolean tree comes from parser export. No old
array comparison group executes. New lexical x/y bindings and literal expected
truth outputs are independent of actual interpreter results.

## Actual source and independent-AST outcomes

| Probe | Actual outcome through both entry paths |
| --- | --- |
| BS1: false,false | (&&, ||) gives (false,false) |
| BS1: false,true | (false,true) |
| BS1: true,false | (false,true) |
| BS1: true,true | (true,true) |
| BS1: operand demand | L is present; R is present only for true && or false ||. Both operands read their own local x/y bindings |
| BS1: whole operation unused | 42 with no observer IDs for every Boolean input/operator |
| BS2: non-Boolean left outer kind | All six kinds reject Type, with no right, array-element, object-field or function-body observer entry; unused operations return 42 |
| BS2: non-Boolean right behind a shortcut | false && value returns false and true || value returns true for all six kinds, without type/payload demand |
| BS2: required errors | A left error propagates left-required with no right observation; true && error and false || error propagate right-required; unused whole operations return 42 |
| BS3: unknown names | Either operand rejects Static at Program creation, for both Boolean left values, both operators and unused wrappers |
| BS3: missing operand | Source-only Syntax failure; no malformed typed-Binary equivalence is asserted |

Observer maps collapse repetitions and compare membership. Neither callback
multiplicity nor order among independent effects is a normative acceptance
condition. Explicit required errors have literal markers; Type/Runtime,
ordering-entry identity and marker wording are embedding phase controls, not
standardized diagnostics. Normative failure is stuck execution.

All inputs are finite, assertion-free and bounded by steps=5000, depth=48 and
stack=64. Unknown-name cases never enter evaluation. Type failure is dynamic:
all six non-Boolean left shapes create Programs successfully. Conversely, a
runtime shortcut never excuses a statically invalid right expression.

## Constructor argument and completion boundary

eval.mbt evaluates the left expression in env, then uses the exhaustive shared
Boolean gate. On the matching false && or true || value, the host shortcut
expression returns that Boolean without invoking self.eval(b, env) or the
right Boolean gate. This branch has no dependence on the right expression's
kind, payload or evaluation judgment. On the other left value the code enters
the right evaluation in the same env. BS1 observes lexical child bindings and
the necessary IDs; BS2 separates omitted work from actual errors and outer
left-type rejection.

runtime_types.mbt's Bool arm returns its value; its other arm rejects every
other Value variant without manifesting payloads. validate.mbt unconditionally
visits both binary children. AST conversion preserves the operator and both
expressions, so runtime selection does not bypass static admission. These
constructor cases, fixed one-premise formulas and executed boundary controls
support exactly the two shortcut decisions. They assume the left child
judgment and do not complete that evaluator, chk-binary, source grammar,
host AST admission, native semantics or any public-library contract.

### B0 remains a normative question

The two longcut formulas contain e_R evaluated to b without an explicit
Boolean-membership premise in those formulas. A Boolean-metavariable reading
is plausible; the fixed language example does not demonstrate a non-Boolean
right result. No explicit operator-right gate was established from the cached
fixed reference documents. The official std.all/std.any definitions have
their own isBoolean assertions, which do not amend the operator rules.

Consequently, Boolean right transfer and explicit-error propagation have
independent verdicts, but rejection versus transfer of a forced non-Boolean
RHS remains **unknown**. No such probe is counted passing or failing here.
The current Boolean helper's behavior is implementation evidence, not an
oracle for B0; Go/C++ behavior cannot settle it either. The interpreter was
not changed to guess a reading. This specific domain adjudication is the
remaining longcut endpoint; additional behavior microgroups cannot resolve
the printed text. N0/R0 and the earlier assertion adjudication are unchanged.

## Execution identity and validation

Base: 805e3705c26875f94a89e6460baa36f9b7fa90e2, tree
2dc15040740d92d169e831c691470befa0a62df9, plus the new test identified below.
Raw records: /tmp/moonjsonnet-boolean-shortcircuit.u7dc5esh. baseline.json and
before-run.json pin the clean source, implementation, retained controls,
neutral builders, criteria and new test. criteria-before.md and test-before.mbt
preserve the pre-execution inputs. These bytes stayed unchanged through
format/matrix work.

The first directed native debug invocation passed **3/3, exit 0**:

    nice -n 10 env RUST_LOG=error moon test spec_boolean_shortcircuit_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize

Only BS1-BS3 executed. Their internal source/AST/value variants do not become
extra completed rules. No product defect was observed, no product file was
modified and no semantic rerun followed metadata/documentation edits. Actual
local tools were moon/moonrun 0.1.20260920 (914d7da), moonc
v0.10.14+7d59c7ec9 on Darwin arm64.

| Check | Result |
| --- | --- |
| Native root type check | Exit 0, --frozen --deny-warn -j 1 |
| Info then fmt; script fmt --check | All exited 0; tested bytes and public .mbti files unchanged |
| Matrix validation/regeneration | First invocation exited 0; exact formulas, premise roles, anchors and inspected/test hashes validated |
| New review-form rejection controls | 6/6 rejected at the intended guards before output, in an isolated temporary mirror |
| Tracked/staged-only documentation checker | Exit 0: 164 files and 1217 local/current-source links; root layout, language candidates, README parity and migration targets passed |
| Whitespace and exact scope | Staged/worktree diff checks passed; exactly the seven intended test, criteria, evidence and matrix files |

The new Boolean review form accepts only the two shortcut names and fixed
statements, requires the matching left premise, child assumptions, boundary
evidence and a mandatory B0 exclusion, and retains generic inspection/test
hash checks. Its six negative controls reject use on a longcut, missing child
assumptions, a changed formula, a wrong premise, a missing B0 exclusion and a
stale inspection hash. Copies contain only enumerated repository evidence and
new test/criteria files. No real mapping/source was mutated and no malformed
control emitted a matrix. negative-results.json and per-control logs retain
the actual guards and exits. These are tooling checks, not semantic tests.

All checks were sequential, at reduced priority and one worker where supported;
installed info/fmt expose no worker-count option. No full suite, remote,
browser/CLI run, installation, push or tag occurred. Fixtures contain no
imported/private files or network I/O. Standard/default was retained.

## Exact matrix state and next candidate

The 94 inventory IDs remain unchanged: 70 named rules and 24 initial
prose/grammar obligations. The two shortcut rows move from unreviewed to
completed named transfer reviews; the two longcuts move to partial with B0.
Existing chk-binary, STATIC-TRAVERSAL and EXEC-OPERATORS receive scoped mappings.
The [matrix](SPEC-LANGUAGE-MATRIX.md) is now **10 completed named reviews
(6 static, 4 evaluation), 1 constructor transfer relative to children, 57
partial rows and 26 unreviewed rows**. The existing prose constructor record
is unchanged. No partial-row count is a conformance rate; whole-language
acceptance and inferred execution remain false. The
[Go/C++ comparison](SPEC-LANGUAGE-COMPARISON-2026-10-22.md) stays separate and
unknown for the new probes. Public-library completion counts are unchanged.

A distinct next candidate is CORE-IMPORT code imports returning closures:
lexical isolation and nested dependency scope, reusing I1-I3 and keeping host
cache/canonicalization policy questions separate. It has not been started.

| Identity | SHA-256 |
| --- | --- |
| Pre-execution criteria | adc99e1f4d07d78574f167ff6276b47282ea7c1add68ab5f4efd8bae3119d119 |
| Executed new test | 730b05bfade40138c803a0223387fee8b11f92117fcc1996dda46cf8c71109ef |
| Reused neutral builder file | b0734a9fca7196cc28c1f11800c874edb1373b86fe73acb9d02c1b3d1e13361a |
| Reused BS0 source | 7cdf4c0397458504515322c6b14893628f0ed3ba31a99ee75a7af2654f0a28c1 |
| Passing summary log | 97372d6d024ba8fb9a214e3a9a3495ca88a0631086280e8b2271682e11ea6fb0 |
| Updated matrix tool | e85a100054bc3e0bd28e96f5dd55b92355e66c72b737dc648de540e867f6ee2f |

Temporary records are not an archival guarantee. Committed criteria/tests and
the [machine-readable matrix](spec-language-matrix.json) preserve the actual
scope and oracles; equal summary log hashes do not identify the executed
source. Product code, dependencies, existing tests and public interfaces are
unchanged.
