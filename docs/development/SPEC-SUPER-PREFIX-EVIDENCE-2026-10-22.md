# Super prefix with final self: bounded execution evidence

**Decision: the predefined plain-layer super-prefix/final-self group is
reviewed complete.** Super selects below the field's defining layer, while
the selected lower field still uses the final receiver for self. The
[pre-execution criteria](SPEC-SUPER-PREFIX-REVIEW.md) restrict acceptance to
the specified extension families, zero-argument functions and hidden/missing
prior-field boundaries. Entire object inheritance/indexing, keyword
substitution and visibility rules remain partial.

The fixed [official specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#execution)
is bbb38f1020be1f5aed560928fb839b2c448cefb4. object-index at lines 2215-2228,
object-inherit at lines 2293-2333 and keyword substitution at lines 2038-2138
supply the relevant receiver/prefix behavior. The fixed
[language reference](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#inheritance)
lines 368-372 explicitly distinguish final self lookup from the prefix below
the current layer. Hidden status does not remove a name from direct field
lookup. These clauses, rather than Go/C++ agreement or test/member counts,
select the expected outcomes.

## New behavior and reused evidence

The [new tests](../../spec_super_prefix_test.mbt) independently author source
and handmade AST programs. The expected scalars, arrays and callback roles
were fixed before execution; no source/export round trip supplies an oracle.

| Necessary condition | Actual result through both entry paths |
| --- | --- |
| Multilayer overrides | B.v=12 and C.v=113 include the appropriate lower definitions evaluated with final n=2/3; D.v=999 selects the latest override |
| A lower function keeps its own prefix | C.outer() and D.outer() reach B.f through super, yet B.f's own super remains below B. They yield [3,3] and [4,4], rather than intermediate/current v values |
| Extraction and rehosting | Extracted C.f and the same value stored in holder with n=99/v=999 both retain [3,3]; inherited D.f retains [4,4] |
| Exact normal oracle | SP1 returns [12,113,999,[3,3],[4,4],[3,3],[3,3],[4,4]] |
| Hidden prior field and final self | SP2 returns [1,7,99]: C.read reaches hidden A.h through B's prefix, but A.h's self.n observes final C.n=7, not a prefix object or current h=99 |
| Missing prefix cannot borrow newer names | SP3 reads C.x=99 first, then invokes the saved function defined in B. Its super.x still cannot see B.x=42 or C.x=99 and rejects Runtime |
| Hidden prior error cannot borrow a cached current value | With hidden A.x containing an explicit error, the same warm-current-field path demands A.x and preserves the predefined lower-super-marker |
| Actual demand timing | Programs create successfully. Function metadata and unused-invocation modes produce the explicit function/42 results with zero body events. Only forced invocation records body once and raises Runtime |

The current-value guard and body event distinguish the intended failure path
from an incorrect current lookup or a premature failure. Runtime category,
entry identity and the literal marker are embedding controls, not standardized
trace formatting or arbitrary first-error priorities.

O2/F6/O6 already supply scalar-super, default-parameter lexical-super and
visibility-pair controls. SR1-SR3 supply detached self receiver controls.
Those mapped assertions and their current source hashes are reused without
duplicating the groups or rebinding their older executions to this source.
No new full visibility, default-argument or general closure campaign occurred.

## Why the dataflow supports this bounded contract

Object addition preserves layer order in a fresh object. In objects.mbt,
scope binds self to ObjectValue(id, full_layer_count) and super to
ObjectValue(id, defining_layer). Field lookup begins at top-1, selects the
definition below the supplied prefix, and builds that definition's own scope
on the same full receiver identity. Reaching B.f from C's super therefore
does not turn B.f's super into C's prefix.

The cache key contains the selected layer and name within that receiver.
Warming current-layer x cannot replace a lower-layer x or manufacture a
missing prefix field. Direct lookup uses the layer's field map without the
visibility filter used by enumeration/manifestation, so hidden prior fields
remain reachable. Function values retain their environment, and invocation
uses that captured outer environment rather than a later holder's field scope.
This explains the prefix, final-self, warm-cache and extracted-function
controls together.

This is an engineering review supported by necessary executions and inspected
dataflow, not a proof of arbitrary layer shapes, field bodies or child
judgments. No product defect was observed in the selected group; no product
implementation change was needed. Missing-field/type matrices, arbitrary
inheritance/association, nested objects/$ and the remaining visibility/equality
algebra are not decided by these results.

## Execution identity and final checks

Base source: 43f491d8c7f5f4367fb919408ebceb3432824179, tree
5d38ef08421dcc363fceca9c1198cacc08ec40bd, plus the new test identified below.
The retained pre-run manifest pins the criteria, executed test, inspected
implementation and reused tests; those bytes remain unchanged after checks.
Existing Darwin arm64 tools: moon/moonrun 0.1.20260920 (914d7da),
moonc v0.10.14+7d59c7ec9. Fixtures are self-made with virtual callbacks and no
actual imported-file, private-document or network I/O.

The focused native debug invocation passed **3/3, exit 0**, on its first run:

```sh
nice -n 10 env RUST_LOG=error moon test spec_super_prefix_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize
```

Reused groups and older aggregate/platform results are not added to this
count. No second semantic run followed documentation/mapping changes.
Typecheck, info/format and matrix validation ran sequentially with frozen
dependencies and reduced priority, one worker where supported. Installed
info/fmt have no worker-count option. No implementation, dependency or public
interface changed.

The [matrix](SPEC-LANGUAGE-MATRIX.md) retains **8 completed named rules,
42 partial rows and 44 unreviewed rows**, still 70 named rules and 24 initial
prose/grammar rows. Only evidence/remaining-scope text for object-index,
object-inherit, HIDDEN-INHERITANCE and SUBSTITUTION changes; every row's
completion state is unchanged. SP3 is a later field-demand failure, not an
error of object addition. Public stdlib remains 35/153 partial reviews;
whole-language acceptance and inferred execution remain false.

| Final check | Result |
| --- | --- |
| Root native check | Exit 0 with --frozen --deny-warn -j 1 |
| Root info then fmt; script fmt --check | All exited 0; no .mbti changes |
| Matrix regeneration | Exit 0; assertion locations and source hashes validated |
| Tracked/staged-only documentation checker | Exit 0; 147 files and 1108 local/current-source links passed |
| Whitespace and exact file scope | Working/staged diffs pass git diff --check; exactly seven scoped files, with no existing implementation/interface changes |

| Retained artifact / inspected source | SHA-256 |
| --- | --- |
| Pre-execution criteria | 878ac8289edf32db5f14a4e0360f11e5bb36ba95e53136e46b551ed5b449ae94 |
| Executed test file | cd91fcc5d2c41b3a08a0ef669c36c255231b0d608ddf88085b6a4b9a6c95ef5e |
| Passing 3/3 summary log | 97372d6d024ba8fb9a214e3a9a3495ca88a0631086280e8b2271682e11ea6fb0 |
| objects.mbt | 06fe3700af7171f9b67a9641a35c92d541849409bcd009e34428ee0456079436 |
| operators.mbt | a93a2d005dd74b7a07ac9fa6d1a585a4fda46d7a8ce6c97dda8e3c83a30b3209 |
| eval.mbt | f75c9e3fd45506a140711eaf21c09625dfa9879798ccc1ac40adc1f2983f55c3 |

Raw evidence: /tmp/moonjsonnet-super-prefix.VKCC2Y. Temporary artifacts are not
an archival delivery guarantee. Committed criteria/tests and the
[machine-readable matrix](spec-language-matrix.json) retain actual oracles and
source-bound scope. Summary counts/hashes alone do not establish source
identity or conformance; the input/command records bind this result.

Object assertions/locals, additive/computed/nested fields, comprehensions,
parameters/defaults, complete inheritance/visibility/closure laws, GC/reentry,
failure retry, host metadata, resource/stack limits and diagnostic/CLI behavior
remain outside acceptance. [Go/C++ comparison](SPEC-LANGUAGE-COMPARISON-2026-10-22.md)
stays separate and unknown for these cases; older macOS/Linux evidence retains
its original source identity. No full test suite, release build, remote run,
verification on another platform, dependency installation, push or tag occurred.
