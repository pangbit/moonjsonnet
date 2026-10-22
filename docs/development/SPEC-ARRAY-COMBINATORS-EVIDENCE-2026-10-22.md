# Array combinator contract evidence, 2026-10-22

This is a bounded continuation of the
[proposal-aligned conformance work](SPEC-CONFORMANCE.md), using the fixed Google
Jsonnet commit bbb38f1020be1f5aed560928fb839b2c448cefb4. Expectations were recorded
in the [array contract review](SPEC-ARRAY-COMBINATORS-REVIEW.md) before execution.
All new inputs are synthetic literals and local callback counters, with no
business data or private application text. The private proposal was not edited
or added to Git.

## Boundary adjudication

The formal makeArray rule does not specify an exceptional/normalization policy
for negative or fractional sizes. range delegates its computed cardinality to
makeArray. The filter rule selects results equal to true without an explicit
Boolean-result premise; the prose does not uniquely resolve the invalid-result
domain. Rejection is a candidate interpretation, not a uniquely established
criterion. No implementation change or normative passing assertion was added
for these cases.

Eleven [observation inputs](../../tests/spec-array-boundary-observations.json)
were run against baseline 05154c4111a4d61880bcfc4bcf0df60e74294a09. Negative integral
makeArray/range cardinalities produced empty arrays, fractional cardinalities
failed, and all six nonboolean filter variants failed. These observations have
no acceptance status. The local boundary report identifies the actual input,
observer and CLI hashes independently.

## Established failures and minimal fixes

The corrected baseline ran 23 groups: 18 passed and five failed. Four failures
showed foldl/foldr forcing an unused callback on empty input or forcing the
original init before a callback that ignores it. The fifth showed flatMap
reading its input before rejecting a nonfunction callback: the native read
counter was 1 instead of 0.

Local implementation commit bdd43e49d28c87fe6fb5eeb8b02e1663c027d82d:

- Passes the original init thunk into the first fold callback; an empty sequence
  returns init without using func. Every new accumulator head stays strict, as
  required by the fixed source's tailstrict recursive call.
- Retains iterative array/string folds, callback order, resource checks and
  lazy nested payloads. It does not broaden the existing sequence type domain.
- Validates flatMap's function before demanding arr, retaining its existing
  array/string result implementation and lazy array payloads.

The initial 17/23 result included one test-construction error: function()0 had
been put in the nonfunction callback list. It is a function. That input was
removed from that list before the corrected baseline; its role as an invalid
size remains. The original log and initial sources are retained. No product
failure was silently discarded, and no frozen Go/C++ result was rewritten.
Old local strict-Go assertions were replaced with the independently established
source criteria; original copies remain in the local evidence directory.

## Per-function reviewed subset

All five signatures have required public parameters and no optional defaults.
Missing/extra/unknown parameters fail on demanded calls without evaluating
rejected argument expressions. Unselected calls remain lazy. Explicit null in
slice supplies its bound/step defaults; omission is a binding failure.

| Function and test | Normal and boundary | Error and lazy/immutable |
| --- | --- | --- |
| makeArray, [build tests](../../spec_array_build_test.mbt) | Integer indices, reordered names, callback defaults overridden, zero/negative zero, function-valued elements | Invalid size/function heads, deferred bodies, demand order [2,0], cached repeated selection; allocation-limit check separately protects host policy |
| foldl, [joint fold tests](../../spec_array_fold_test.mbt) | Left association, array/Unicode string, names, unchanged source/init arrays | Empty callback unused, original init optional to first callback, strict intermediate heads, lazy fields/elements, left-to-right native visits |
| foldr, [joint fold tests](../../spec_array_fold_test.mbt) | Right association, element before accumulator, Unicode string, unchanged source/init | Same empty/init distinction, intermediate errors retained, lazy nested payloads, right-to-left native visits |
| flatMap, [flatMap tests](../../spec_array_flatmap_test.mbt) | Arrays/strings, Unicode codepoints, empty/all-empty output, reordered names | Function rejected before input read, needed callback heads/errors, unused elements and returned payloads lazy, unchanged source |
| slice, [slice and shared binding tests](../../spec_array_slice_test.mbt) | Explicit null defaults, names, positive step, negative/large bounds, Unicode | Invalid step/bounds even on empty input, demanded end error, unused overflowing progression skipped, shared selected thunk executes once and input unchanged |

The 23 groups comprise four makeArray groups, nine joint fold groups, five
flatMap groups, four slice groups and one shared signature group. Existing P0
fractional-index/slice-timing tests protect earlier behavior and are not new
coverage for this batch. The
[public map](SPEC-PUBLIC-STDLIB-INVENTORY.md) now records reviewed subsets for
22 of 153 candidate identifiers. R denotes only the stated assertions, never a
complete function pass.

## Validation identity

Validation source: 6c0f65a8bfbebce9f89d19b8e35c52dba91f75ce, tree
145165a07a778cd94f8bc8aaaf68d43416cf5d80. The tracked tree was clean for final
execution; pre-existing private untracked material was excluded. Platform:
Darwin arm64. Existing toolchain: moon/moonrun 0.1.20260920 (914d7da), moonc
v0.10.14+7d59c7ec9. Tests/builds were serial with -j 2; no tool/dependency upgrade.

| Check | Result |
| --- | --- |
| Corrected independent baseline | 18/23; five real failures |
| New regressions after implementation fix | 23/23 |
| Affected sequence/array/aggregate/object callers | 60/60 |
| Native debug aggregate at validation source | 407/407 |
| Native release aggregate at validation source | 407/407 |
| Final CLI/P0/error/lazy and three scenarios | 53/53; clean tracked source, release CLI and embedded executable |
| Native warning-denying check, moon info then moon fmt | Passed; no public .mbti changes |
| Documentation validator after final evidence | 118 files / 875 local links passed |
| Final formatting and whitespace checks | Passed; no public .mbti changes |

The six additional CLI cases cover unused fold callbacks/initial values,
flatMap's function-before-input error, and makeArray/slice normal and lazy
results. The retained P0 failures return exit 1 with empty stdout; normal/lazy
cases return the expected JSON. Environment and monitoring configuration outputs
match their checked-in fixtures. Embedded-library and CLI checks include valid
configuration, invalid/missing parameters, assertions, controlled import escape
and step limits. The report records every input hash and exact output/status.

Local raw evidence is retained under
/tmp/moonjsonnet-array-contracts.Rq05wY. Original failures are not overwritten.

| Artifact | SHA-256 |
| --- | --- |
| before-initial.log | 5f750f44097c5ff574a1b58a4263493e64bbceeb62e5febe336597475007e240 |
| before-corrected.log | 08d3327be2a75eafd8873e1d812c47e54de0b03f55b5c7f239bf6b228f98e9f5 |
| after.log | e00f1886813512e48b6cbecc5532bd9ff1a8e3f19ba2703d5a3cb69467c2ebca |
| affected.log | 02eaa5841e008a231c51a023aa1d07eb5c9363a20e86dbb6e25dbe43bb22a654 |
| boundary-observations.json | 52047fa5b99863828a6fdadd6214faae0052b3f5b8d8063f6f5b3bda1a68f353 |
| Boundary observation input fixture | e215897208b983a67419833701f129ae3a0e85c3b60a6d0f9e4758cbbb4b1671 |
| Final CLI fixture | 0e8e89ce8746c98c180459aacce1f952fb09fe159fde8d0498c03b2713be9354 |
| Final acceptance tool | b090d63dee048a727094108695fa0bc6af0e6dde23a8b453e000976cd34e62c5 |
| Manual public coverage mapping | d4d57e2911210a1104f1d7ec8f440542272c3eb7f39ac15741453df45d3782d8 |
| native-debug.log and native-release.log, identical count summaries | 4e67894ea4016447eacde2c6991151dd5219ac9b1baa2b3a5d0367a7ee6d6b05 |
| acceptance/report.json | 7f9e32ca8f4ecc98c0272a57a7075884b0e9e670739c9497b2383a40be50cac7 |
| acceptance/cases.json | fddf948f0e9aa3811c82feb3d963c4e6946d4ecc02a9fe2dd2abda0ed289bf41 |
| Release CLI executable | 3ab8b5f0d896821697a4ba705b38aa903a50c519b80bc497fbe0ab92a5f391a4 |
| Release embedded executable | 06e70e7f51b7ad2f23ef9d71b516c21bccce66d1fe4b57db1cc68a7aefa36515 |

## Remaining scope

Unresolved: negative/nonintegral cardinalities, nonboolean filter returns,
makeArray callback declaration-count wording, folds on empty objects/functions
outside the advertised sequence domain, and flatMap null/string return cases
outside documented callback kinds. removeAt parameter naming, Xml/XML spelling
and YAML-stream default conflicts remain unchanged. Other public contracts and
all language rules still require individual adjudication and mapping.

No Linux validation, upload, remote access, push, release or tag was performed.
Earlier local Linux packets remain evidence for their own commits. A new local
packet may be rebound after this stable batch; execution still needs the parent
to arrange the precise authorized Linux scope. There is no local approval or
environment blocker. This stage does not establish complete conformance.
