# Assertion object locals and nested capture: U1 execution evidence

**Decision: the bounded U1 endpoint is closed**, relative to the existing
self/root and child-expression judgments. Object-local definitions used by
the assertion condition and failure message retain the selected receiver's
environment when a nested child is inherited. A helper's nested object keeps
its own self while retaining the captured receiver alias and lexical root.
The [pre-execution criteria](SPEC-ASSERTION-LOCAL-REVIEW.md) fix this scope;
this is not completion of all object locals, binders or assertion rules.

**U2 and N0 remain open.** No super reference occurs in these new fixtures,
so N0 does not affect their oracle. No object in this group has multiple
assertions, so U2 is neither executed nor closed by analogy.

## Fixed independent expectations

The normative source is the
[official specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#desugaring)
at bbb38f1020be1f5aed560928fb839b2c448cefb4. Object desugaring passes object
locals to assertions (lines 1131-1165); desugar_assert wraps both conditional
branches in those bindings (1351-1363). Local-variable substitution retains
the definition context (2260-2270), while keyword substitution respects nested
object capture (2038-2123). The object/function context rules preserve lexical
root bindings (1131-1165 and 1208). No other interpreter provides an oracle.

R4 already distinguishes ordinary inherited object-local aliases. RT1/RT2
review nested self and lexical roots; AS1-AS3 review assertion receiver self
and demand. Those are reused with their original source identities and are
not newly executed. The gap addressed here is the combination of object-local
definitions, an assertion's two branches and a helper-created nested object.

## Actual source and independent handmade-AST behavior

The [new probes](../../spec_assertion_local_test.mbt) reuse unchanged neutral
AST/program helpers, including their synthetic assertion-self-entry location.
They explicitly build Obj local bindings and assertion pairs. Neither tree
shape nor expected JSON comes from parser export or observed interpreter output.

| U1 clause | Observed outcome through source and handmade AST |
| --- | --- |
| Object-local helper/receiver shadow outer same-name bindings | The outer helper is error-valued and outer receiver.tag=99. Both normal paths still succeed with the local definitions; neither outer definition substitutes for them |
| A receiver alias captures the selected assertion object | Original child receiver.tag=2 and final inherited child receiver.tag=3 are distinguished in condition and payload values |
| Nested self remains distinct from captured receiver/root | A helper returns an object with tag=30 and read()=[receiver.tag,self.tag,$.tag]. AL1 yields exactly [[2,30,10],[3,30,20]] for original and inherited/nested contexts |
| The failure message uses the same object-local definition environment | AL2's false condition records condition([3,30,20]), then message([3,30,20]); it raises Assertion with object-local-message-marker and does not execute the payload |
| Unused object locals remain lazy | unused=error unused-local-marker is present in both successful and false-condition variants and is never forced |
| An erroneous local initializer is demanded at the correct boundary | A type guard constructs the final object. Metadata/unused-field modes return object/42 with no events; actual field demand records only local-init and raises Runtime with object-local-init-marker, before condition/message/payload observations |

The root is first inherited from tag=10 to tag=20, then its selected child is
inherited from tag=2 to tag=3. These distinct contexts make it impossible for
the same accidental outer binding, nested self or original receiver to satisfy
the literal expectations. The root checks are a control using the previously
reviewed lexical-root contract, not a new general root campaign.

All programs are statically valid and create with zero callback activity.
The Runtime/Assertion categories, entry identity and fixed error markers
distinguish unambiguous embedding phases, not prescribed diagnostic formatting.
Native observers return true, a fixed string or their supplied JSON value;
the comparison remains in Jsonnet. The event arrays also guard demand order
for these dependent operations, without specifying arbitrary multi-assertion
ordering or universal callback counts.

## Structural argument for U1

objects.mbt installs self for the full current receiver before binding that
layer's object locals. check_assertions obtains this layer scope for its
condition and message; field access with locals uses the same per-receiver,
per-layer scope. The original and derived objects have distinct scope and
assertion state, so they do not share a bound receiver by accident.

runtime_types.mbt's bind creates a child environment and stores each local
initializer as Pending with that same binding environment. Own names shadow
outer names without evaluating either initializer eagerly. receiver=self
therefore retains the selected assertion receiver when referenced later by
the helper's nested function, and the unused error-valued local stays pending.
R4's existing alias evidence supports the recursive-binding child contract;
no new recursive-local campaign is claimed.

Functions capture their definition environment, and call_env starts from that
environment. A new nested object establishes its own self while preserving
the captured receiver alias and existing root binding. This supplies the
distinct 2/3, 30 and 10/20 values in AL1/AL2. ast_convert.mbt preserves Obj
locals plus condition/message arrays; validate.mbt adds all local names before
visiting their values, fields and assertion pairs under object context.

The false-message branch uses the same scope, while a condition's demanded
local error propagates before message/payload execution. These paths and the
distinguishing outcomes discharge U1's declared finite endpoint beyond test
counts alone. No product defect was observed and no fix was necessary. This
is an engineering review relative to child judgments, not a machine-checked
proof of all bindings or object syntax.

## Current object-assertion endpoints

The [prior acceptance ledger](SPEC-ASSERTION-SUPER-EVIDENCE-2026-10-22.md)
retains its earlier source-bound results and now links this continuation.

| Endpoint | Current decision and stopping point |
| --- | --- |
| U1 object-local/nested capture | Closed for the predefined helper/alias, outer shadowing, ordinary inheritance and nested-object capture contract, including both assertion branches, unused locals and demanded local errors. General binder/root judgments retain their existing scopes |
| U2 multiple-assertion retention/reentry | Still untested here. Review the full pair/layer loop and state reset with two assertions split across inheritance operands: both true succeeds; each operand's false assertion separately blocks payload; overriding a field must not remove either assertion. Include one terminating self-field dependency during a check; impose no ordering between two independently false assertions |
| N0 assertion-super formal rewriting | Still unresolved. The pinned inheritance equation does not explicitly give the right-hand assertion-prefix rewrite. A primary-source derivation or clarification is needed for formal super-inclusive acceptance; the AX behavioral evidence cannot supply it |

The constructor-level endpoint remains finite: U2 needs its distinguishing
outcomes and structural argument; a claim of literal formal conformance
including super additionally needs N0 resolved. Neither is folded into U1.
DESUGAR-ASSERT also still needs its explicit combined expression/object
constructor decision relative to child judgments. Existing AR0/IF4 and the
static/source arguments remain reusable; no new default-message, condition
type, full static, equality, stdlib or host-session campaign is started here.
The top-level manifestation versus std.manifestJson distinction is unchanged.

## Execution identity and final checks

Base source: 260a13124ec9ecb2688c6bb516b893d517cce0cb, tree
7dcca41966c0911e7d79db9246f1aa61933051aa, plus the new test identified below.
The retained pre-run manifest pins criteria, test bytes, implementation and
reused helper/test files. Their bytes remained unchanged after execution,
formatting and matrix updates. Existing local Darwin arm64 tooling:
moon/moonrun 0.1.20260920 (914d7da), moonc v0.10.14+7d59c7ec9.

The single directed native debug invocation passed **2/2, exit 0**, on its
first run:

```sh
nice -n 10 env RUST_LOG=error moon test spec_assertion_local_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize
```

Only the two new groups executed; source and handmade-AST variants are inside
them. No old R4/RT/AS/AX or aggregate/platform outcomes are added to this count.
No semantic rerun followed mapping/documentation edits. Sequential frozen
typecheck, info/format and matrix commands used reduced priority and one
worker where supported; installed info/fmt have no worker option.

| Final check | Result |
| --- | --- |
| Native root check | Exit 0 with --frozen --deny-warn -j 1 |
| Info then fmt; script fmt --check | All exited 0; no .mbti changes |
| Matrix validation/regeneration | Exit 0 on first invocation; anchors, locations and source hashes validated |
| Tracked/staged-only documentation checker | Exit 0; 155 files and 1162 local/current-source links passed |
| Whitespace and exact scope | Working/staged git diff --check passes; exactly eight scoped files, with no product/interface changes |

The [language matrix](SPEC-LANGUAGE-MATRIX.md) adds only bounded AL1/AL2
mappings to object-index, object-inherit, DESUGAR-ASSERT and SUBSTITUTION.
All clause completion states remain unchanged: **8 completed named rules,
42 partial rows, 44 unreviewed rows**, across 70 named rules and 24 initial
prose/grammar rows. Product code, dependencies and public interfaces are
unchanged. Whole-language acceptance and inferred execution remain false.
[Go/C++ comparison](SPEC-LANGUAGE-COMPARISON-2026-10-22.md) stays separate and
unknown for these new probes; no public stdlib completion is added.

| Artifact / source | SHA-256 |
| --- | --- |
| Pre-execution criteria | 65a61cb697ad75eeeb20366f9b3c3821dac994922c4a7c183ddad5b58e25bc48 |
| Executed new test | 4ec20f1a324e8655c194e1b9d4aa1553218cb45d2d279e3c255e3eeab555a155 |
| Passing 2/2 summary log | ddd0722f90fd133207ca9e423fc1faa05c3608f3be5c5eb4fdbea4259682b120 |
| Reused assertion-self helper/test file | eaf067af506d8151d87cfe8f8cbe2527580cabb6d5a8b73ea2a56a88072faaf6 |
| objects.mbt | 06fe3700af7171f9b67a9641a35c92d541849409bcd009e34428ee0456079436 |
| runtime_types.mbt | eb8a948f5aa45e57ba9417753d9d97e80e55ab4a35cd8524dc51a6a950f3e8e9 |
| ast_convert.mbt | bd3fbff39ccdfc2d177d41435d7a33e96014ae206697c902be69ec2b11d5beed |

Raw records: /tmp/moonjsonnet-assertion-local.5q1j98qa, including before-run.json,
criteria-before.md, test-before.mbt, focused-result.json, checks.json and logs.
Temporary records are not an archival guarantee; committed tests/criteria and
the [machine-readable matrix](spec-language-matrix.json) retain oracles and
source-bound scope. Summary counts/hashes alone are not source identity.

Standard/default and one worker were retained. Fixtures are synthetic virtual
callbacks without imported-file, private-document or network I/O. No full
suite, remote/platform/CLI run, new dependency, push or tag occurred.
