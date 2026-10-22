# Inherited function fields: bounded receiver-retention evidence

**Decision: the specified plain inherited-function receiver-retention group is
reviewed complete.** Selecting f=function()self.n from a particular receiver
retains that receiver in the resulting function, including after earlier base
demand, sibling/descendant extension, extraction and rehosting. The
[pre-execution criteria](SPEC-INHERITED-SELF-REVIEW.md) restrict this decision to
ordinary fields, constant n overrides and zero-argument functions. It does not
complete object-index, object-inherit, SUBSTITUTION or general closure algebra.

## Why this gap was selected

The starting inventory has 44 unreviewed and 42 partial rows. The relevant
object-index/object-inherit/SUBSTITUTION rows are partial: O2 already supplies
scalar late-self and unchanged-original controls, and F6 method-default controls.
Those existing assertions do not independently exercise warmed inherited
function fields, detached receiver identity and rehosting through handmade ASTs.
Shared layer environments and cached function fields make cross-receiver
contamination a concrete risk. This behavior gap was selected ahead of filling
more static-transfer rows or unreviewed reflection labels.

The fixed [official specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#execution)
is bbb38f1020be1f5aed560928fb839b2c448cefb4. object-index lines 2215-2228 bind
self to the indexed receiver; object-inherit lines 2293-2333 preserve the
inherited field bodies. Keyword substitution at lines 2038-2138 supplies the
relevant capture boundary. The fixed
[language reference](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#inheritance)
lines 368-372 identify the current object when its field is selected; lines
413-438 distinguish that receiver from a fixed object reference. Lexical
function capture then preserves the selected receiver when the value is moved.
Neither Go/C++ results nor the implementation's output supplies these oracles.

## Actual behavior and necessary controls

The [new probes](../../spec_inherited_self_test.mbt) separately author source
and handmade AST programs; no parsed/exported tree or source/copy equality is
used as an independent value oracle.

| Clause within the selected group | Independent result and executed evidence |
| --- | --- |
| A warmed base field must not bind derived functions to the base | SR1 first requires base.f()=1 in a condition, then interleaves extracted functions from two siblings and a descendant. The explicit result [1,2,3,2,1,4,3,1,2] distinguishes the receiver values and retains the original |
| Moving a function value is not a new method binding | SR1 stores the function selected from n=2 in holder with n=99; holder.g() still returns 2 |
| Selecting a function does not run its body | SR2's original receiver lacks n, yet inspecting original/derived function types returns two function tags with zero body callbacks |
| A detached inherited function uses its own receiver on invocation | SR2 invokes the saved derived function, returns 7 and records the sole callback argument 7 |
| A healthy derived object cannot repair the original receiver | SR3 first requires derived.f()=7 and records derived-ok, then invokes the extracted original function. It rejects Runtime because the original still lacks n |
| Error phase and path | Both Programs create successfully before SR3 evaluation. An incorrect derived result returns normally and fails the test; an earlier failure lacks derived-ok. No exact error text or unrelated first-error ordering is assumed |

The Runtime category and entry identity are embedding boundary controls.
Callback roles observe body demand; they do not establish universal field
memoization, failure retry or host cache lifetime. O2/F6 are reused for their
existing meanings and current source hashes, without rerunning them or adding
their old executions to this batch.

## Implementation dataflow supporting the bounded decision

The review follows receiver identity rather than relying on the number of
fields or tests. Object addition concatenates layer descriptions and calls
object_value, which allocates fresh per-object field-cache and scope maps.
Field lookup creates the selected layer's scope for that object identity;
scope binds self to the full receiver, not the original layer's object.

eval.mbt creates Closure(params, body, env) with that field environment.
Invocation uses the closure's outer environment through call_env, rather than
the environment of a later holder field. Merely storing the resulting value
does not reevaluate the original function expression with holder's self.
This accounts for the warmed-base, distinct-receiver, detached and rehosting
controls together. The missing-n case also exercises the boundary where no
field exists on the original receiver after a healthy derived call.

This is a bounded engineering review supported by necessary executions and
inspected dataflow, not a machine-checked proof of arbitrary field bodies,
inheritance shapes or all child judgments. No product defect was observed
within the selected group, and no implementation change was needed.

## Execution identity and validation

Base source: dff979e20e5ebe759b81f8b162e031c40d711bab, tree
2b5968bfb72f488c34fd8b80b48ee07b4a5412b8, plus the new test identified below.
Pre-run manifests pin the criteria, exact executed test and inspected/reused
sources. Existing Darwin arm64 tools: moon/moonrun 0.1.20260920 (914d7da),
moonc v0.10.14+7d59c7ec9. All fixtures/callbacks are self-made, with no actual
imported-file, private-document or network I/O.

The initial invocation exited 1 before executing tests: the new MoonBit test
assembled a string with an unparenthesized conditional suffix. Adding the
required parentheses corrected only the test adapter; criteria, expected
values and product code were unchanged. The initial source and compile log
remain retained and are not reclassified as passing behavior.

The corrected focused native debug command passed **3/3, exit 0**:

```sh
nice -n 10 env RUST_LOG=error moon test spec_inherited_self_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize
```

No second semantic run followed mapping/documentation edits. Reused groups and
older full-suite/platform results are not added to this count. Subsequent
typecheck, info/format and matrix commands ran sequentially with frozen
dependencies and reduced priority; one worker was specified where supported.
Installed info/fmt have no worker-count option. No product source, dependency or
public interface changed.

The [matrix](SPEC-LANGUAGE-MATRIX.md) remains **8 completed named rules,
42 partial rows and 44 unreviewed rows**, with 70 named rules and 24 initial
prose/grammar rows. Only evidence/remaining-scope text for object-index,
object-inherit and SUBSTITUTION changes; all row completion states are unchanged.
SR3 is a later-demand boundary for inheritance, not a failed object-addition
judgment. Public stdlib remains 35/153 partial reviews; whole-language
conformance remains false.

| Final check | Result |
| --- | --- |
| Root native check | Exit 0 with --frozen --deny-warn -j 1 |
| Root info then fmt; script fmt --check | All exited 0; no .mbti changes |
| Matrix regeneration | Exit 0; assertion locations, counts and source hashes validated |
| Tracked/staged-only documentation checker | Exit 0; 145 files and 1095 local/current-source links passed |
| Whitespace and exact file scope | Working/staged diffs pass git diff --check; exactly seven scoped files, with no existing implementation/interface changes |

| Retained artifact / inspected source | SHA-256 |
| --- | --- |
| Pre-execution criteria | 1372f3c2d5198bfc4b0d676963ab5c94d635fbd4f26f9e48ae8c61d7b3f70c6e |
| Initial test source | d6a068f9415113e7b6f8b7f85e4c9d2b59572782cfe12cf66bd3fc31705de0f5 |
| Initial compile-failure log | f73d69f21859f53170de86c4534559fa95d98c5efb10e901192f5c50488bb0dd |
| Executed test source | 0a387afc9ba8bc35ba54a7ada36f8c1ef9f27d5c88f40393cfea73a371b7f780 |
| Passing 3/3 summary log | 97372d6d024ba8fb9a214e3a9a3495ca88a0631086280e8b2271682e11ea6fb0 |
| objects.mbt | 06fe3700af7171f9b67a9641a35c92d541849409bcd009e34428ee0456079436 |
| operators.mbt | a93a2d005dd74b7a07ac9fa6d1a585a4fda46d7a8ce6c97dda8e3c83a30b3209 |
| eval.mbt | f75c9e3fd45506a140711eaf21c09625dfa9879798ccc1ac40adc1f2983f55c3 |

Raw evidence: /tmp/moonjsonnet-inherited-self.ujUICj. Temporary files are not an
archival delivery guarantee. Committed tests, criteria and
[assertion mappings](spec-language-matrix.json) retain the actual oracles and
source-bound scope. Test counts and summary hashes alone do not establish
source identity or conformance; the retained input/command records bind them.

Super prefix lookup, nested-root $, object locals, assertions, visibility,
computed/additive/nested fields, comprehension and equality behavior, full
inheritance/closure algebra, GC/reentry, host limits and diagnostics remain
unadjudicated here. [Go/C++ comparison](SPEC-LANGUAGE-COMPARISON-2026-10-22.md)
stays separate and unknown for these cases. Older macOS/Linux evidence retains
its original source identity. No full test suite, release build, remote run,
verification on another platform, dependency installation, push or tag occurred.
