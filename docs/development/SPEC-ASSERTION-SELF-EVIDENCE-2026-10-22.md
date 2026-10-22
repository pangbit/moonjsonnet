# Inherited assertion closures: bounded execution evidence

**Decision: the predefined inherited assertion final-self and field-demand
group is reviewed complete.** An original object's successful check does not
authorize a derived receiver; condition and failure-message functions capture
that receiver's self. This is the ordinary-field group in the
[pre-execution criteria](SPEC-ASSERTION-SELF-REVIEW.md), not completion of
object assertions, inheritance, substitution or manifestation as a whole.

## Fixed normative basis and selected gap

The [official specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html)
at bbb38f1020be1f5aed560928fb839b2c448cefb4 supplies independent expectations:
object assertions desugar into a conditional with an error only in the false
branch (lines 1351-1363); indexing evaluates the selected receiver's assertions
before yielding the field (2215-2228); inheritance retains assertions
(2293-2333). Keyword substitution recurses into functions while respecting
nested object capture (2038-2123). No Go/C++ result supplies the oracle.

O3 already covers direct self conditions on original/derived receivers and
visible/hidden accesses; O5 covers simple check reuse, success-message laziness
and failed-field suppression. Their retained mappings are reused without a
new execution claim. The new gap is a previously checked original combined
with an inherited assertion whose condition and message are function closures.
Fixtures contain one assertion, plain non-additive fields and no super.

## Actual source and independent handmade-AST outcomes

The [new test file](../../spec_assertion_self_test.mbt) builds source and typed
AST inputs separately. Trees do not come from parser/export round trips.
The predicate n==required is evaluated inside Jsonnet; the native condition
recorder always returns true. Message and payload callbacks record self values
and return a fixed marker or the requested number. Expected results and event
arrays are literal assertions fixed before execution.

| Required clause | Executed outcome through both entry paths |
| --- | --- |
| AS1: compatible derived assertion closes over current self | After original.value returns 2, derived n=required=3 returns 3. Condition observations are (2,2,original) and (3,3,compatible); matching payloads run, with no message |
| AS2: checked originals do not lend their assertion state | Original value 2 is actually demanded first. Derived n=3/required=2 then rejects Assertion with assertion-self-marker, rather than inheriting the original success |
| AS2: failure-message closure shares the derived context | Events end with condition(3,2,bad), message(3,2,bad). The derived payload does not run |
| AS3: construction/metadata are distinct from field demand | An explicit std.type(derived) guard constructs the derived object. Metadata and unused-field modes yield object/42 with zero condition/message/payload events |
| AS3: a condition exception is not a false assertion | Actual field demand enters condition(3,2,bad) and raises Runtime with condition-self-marker. Neither message nor payload runs |

All valid inputs are accepted at Program creation. Error categories, entry
identity and fixed markers distinguish unambiguous embedding phases; no
malformed-source Syntax counterpart or complete static judgment is claimed.
Callback traces additionally guard this implementation's demand/cache behavior,
without asserting a universal call-count policy or ordering among multiple
independently failing assertions.

## Dataflow supporting the bounded acceptance

Object addition concatenates layer descriptions and allocates a new object.
objects.mbt initializes that object's assertion state, error slot, field cache
and scope cache separately. It therefore retains assertion expressions without
copying a successful check from the original receiver.

On actual field selection, field calls check_assertions before the selected
field body. Each assertion uses its layer's environment with self bound to
the entire current receiver. Function values capture that environment, and
call_env builds from the captured environment. The selected condition and
message functions consequently see the same final receiver even after the
original's value and assertion have already been evaluated.

The assertion evaluator executes the message only when its Boolean condition
is false. An exception while evaluating the condition propagates before
Boolean conversion/message evaluation and before the selected field body.
Construction stores assertions without evaluating them; type inspection does
not index a field. AST conversion preserves each condition/message pair and
function body, while static checking accepts their object context.

The in-progress assertion guard permits these self-field reads without
recursively restarting the same check. This inspected path explains the
finite fixtures, but is not acceptance of arbitrary assertion recursion,
multiple assertions, persistent sessions or equality interactions. The code
review and explicit distinguishing outcomes support this scoped decision
beyond the number of tests. No product defect was observed or fix required.

## Manifestation distinction and unresolved scope

Existing O3/O4 and the
[object contract audit](SPEC-OBJECT-CONTRACTS-EVIDENCE-2026-10-22.md) retain
their earlier evidence: top-level manifestation checks failing assertions on
empty or hidden-only objects, while structural operations may avoid field
indexing. std.manifestJson's visible-field traversal is a different library
path. That difference alone establishes no defect or normative exemption;
upstream behavior cannot waive the specification. These paths were not newly
executed, changed or adjudicated by this scalar field-demand group.

Assertion super prefixes, nested object/local/additive contexts, multiple
assertions/order, defaults/nonstring messages, condition type errors,
equality/reentry and all manifestation/stdlib combinations remain open. Only
object-index, object-inherit, DESUGAR-ASSERT and SUBSTITUTION receive new
bounded mappings. AS2/AS3 happen after construction and are not new errors of
object addition. All four broader rows remain partial.

## Execution identity and final checks

Base source: b2b3233a64a262c34cbe81337da2ebde9b67e6f0, tree
1356aebd05c659c899f56e065c87bb961d3e34e7, plus the test identified below.
The retained pre-run manifest pins exact criteria/test bytes and all inspected
implementation/reused sources. Those hashes remained unchanged after the run,
formatting and matrix updates. Existing local Darwin arm64 tooling:
moon/moonrun 0.1.20260920 (914d7da), moonc v0.10.14+7d59c7ec9.

One focused native debug invocation passed **3/3, exit 0**, on its first run:

```sh
nice -n 10 env RUST_LOG=error moon test spec_assertion_self_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize
```

The three groups jointly cover the selected clauses through source and
handmade AST; their count is not a measure of whole-rule conformance. There
was no second semantic run after mapping/documentation changes. Sequential
frozen typecheck, info/format and matrix checks used reduced priority and
one worker where supported; installed info/fmt expose no worker option.
Product implementation, dependencies and public interfaces are unchanged.

| Final check | Result |
| --- | --- |
| Root native check | Exit 0 with --frozen --deny-warn -j 1 |
| Root info then fmt; script fmt --check | All exited 0; no .mbti changes |
| Matrix regeneration | Exit 0; assertion anchors/locations and source hashes validated |
| Tracked/staged-only documentation checker | Exit 0; 151 files and 1136 local/current-source links passed |
| Whitespace and exact file scope | Working/staged diffs pass git diff --check; exactly seven scoped files, with no product/interface changes |

The [language matrix](SPEC-LANGUAGE-MATRIX.md) retains **8 completed named
rules, 42 partial rows and 44 unreviewed rows**, across 70 named rules and
24 initial prose/grammar obligations. Every completion state is unchanged.
Whole-language acceptance and inferred execution remain false; no public
stdlib function review is added. The
[Go/C++ comparison](SPEC-LANGUAGE-COMPARISON-2026-10-22.md) stays separate
and unknown for these new probes. Older aggregate/platform results retain
their own source identity and are not added to this directed result.

| Retained artifact / inspected source | SHA-256 |
| --- | --- |
| Pre-execution criteria | 20d50b99265b10ac0a06fb63db77f9af40fb5b4bea3f29f32654842969d453f2 |
| Executed test file | eaf067af506d8151d87cfe8f8cbe2527580cabb6d5a8b73ea2a56a88072faaf6 |
| Passing 3/3 summary log | 97372d6d024ba8fb9a214e3a9a3495ca88a0631086280e8b2271682e11ea6fb0 |
| objects.mbt | 06fe3700af7171f9b67a9641a35c92d541849409bcd009e34428ee0456079436 |
| operators.mbt | a93a2d005dd74b7a07ac9fa6d1a585a4fda46d7a8ce6c97dda8e3c83a30b3209 |
| eval.mbt | f75c9e3fd45506a140711eaf21c09625dfa9879798ccc1ac40adc1f2983f55c3 |
| ast_convert.mbt | bd3fbff39ccdfc2d177d41435d7a33e96014ae206697c902be69ec2b11d5beed |

Raw records: /tmp/moonjsonnet-assertion-scope.UX56Ow, including
before-run.json, criteria-before.md, test-before.mbt, focused-result.json,
checks.json and individual logs. Temporary files are not an archival delivery
guarantee; committed criteria/tests and the
[machine-readable matrix](spec-language-matrix.json) retain the oracles and
source-bound scope. Summary counts/hashes alone are not source identity.

All fixtures use synthetic virtual callbacks without imports, private
documents or network I/O. Standard/default execution was retained. No full
suite, release/CLI/platform run, remote execution, new dependency, push or tag
occurred.
