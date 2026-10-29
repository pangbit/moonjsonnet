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

## Mapping constructor-transfer at e42ef923

The fixed [mapWithIndex definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L281-L287) and [filterMap definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L832-L840) have the same required names and no defaults as their public signatures. Static review confirms canonical source routing in [stdlib_layer.mbt](../../stdlib_layer.mbt): mapWithIndex uses makeArray with func(i, arr[i]); filterMap composes map with filter. Neither definition adds a callback-result kind guard.

| Accepted constructor-transfer scope | Independent witnesses and assumed children |
| --- | --- |
| mapWithIndex: all public guards and Function + Array/String mapping obligations | [MT1/MT3–MT6/MT8–MT10](../../spec_mapping_transfer_test.mbt), existing sequence and binding controls; generic application, indexing, type/length, makeArray and child evaluation are premises. |
| filterMap: all public guards and composition obligations for Boolean predicates | MT2–MT5/MT7–MT10 plus existing array/filter controls; generic application, type/child evaluation and map/Boolean-filter judgments are premises. The [nonboolean predicate policy](SPEC-FILTER-2026-10-22.md#frozen-criteria) remains UNRESOLVED/NOTPASS and prevents unconditional acceptance. |

Both finite scopes are **accepted_constructor_transfer**, with no remaining obligations inside their stated scope. The tests cover required bindings, complete wrong outer-head guards, empty and demanded callback arity, membership versus output demand, isolated errors, unused calls and original aliases through source and independent handmade ASTs. Runtime/exact-marker assertions are additional embedding checks; exact callback counts, independent-error order and resource thresholds are not required. Before execution, static review strengthened MT5 by replacing error bodies with safe 7/true literals so arity rejection could not pass merely from a body failure; this was not a product or runtime failure.

On unchanged production source e42ef923d58f127fbf952e96fb7c4830f9a493ff, the single directed native debug run passed **21/21** (10 new + 11 existing), exit 0, 9.218 seconds; warning-denying check and matching outline also passed. The 723-input manifest remained stable. Commands:

```sh
moon check . --target native --frozen --deny-warn -j 1
moon test spec_mapping_transfer_test.mbt sequence_test.mbt array_std_test.mbt spec_filter_test.mbt arguments_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize
```

Fixture SHA-256: `c26df0a79e59b6ae5ae31ca08d2ee3776008c421b85b2c619fc6c00acdedf877`; retained `directed/receipt.json` SHA-256: `3cd7add9f9b5720a3aa6d3345416575c49129c38b4d803f238fe4bd0edf619ce`. Info/format checks changed no interface or original input; formatting preserved literals and operation tokens. No product fix, new full-suite/release/Linux/consumer/Go/C++ run or whole-language acceptance is claimed. The two new manual records preserve all 73 prior objects; historical inventory snapshots remain unchanged.

## Repeat and search-transfer at 2e288eef

The fixed [repeat](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L198-L203), [count](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L254) and [find](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1655-L1660) definitions are already source-enabled in [stdlib_layer.mbt](../../stdlib_layer.mbt). Their public names are respectively what/count, arr/x and value/arr, all required without defaults. Static branch review and the independent [RS1–RS9 source/handmade-AST fixture](../../spec_repeat_search_contract_test.mbt) close these finite responsibilities:

| Accepted constructor-transfer scope | Explicit child premises and witnesses |
| --- | --- |
| repeat: String/Array copies for nonnegative integral Number count; complete type/cardinality errors, output kind/order, lazy Array payloads, bindings and originals | makeArray cardinality, join, String/Array concatenation and ordinary evaluation; RS1/RS2/RS4/RS5/RS8/RS9 plus existing array/cardinality controls. |
| count: Array guard, all-occurrence count, empty-target laziness, complete comparison/error demand, bindings and originals | ==, Boolean filter, length and ordinary evaluation; RS3–RS9. |
| find: Array guard, all zero-based matching indices, empty-target laziness, complete comparison/error demand, bindings and originals | ==, Boolean filter, range/length/indexing and ordinary evaluation; RS3–RS9. |

Each scope is **accepted_constructor_transfer**, with `remaining_in_scope=[]`; the stated generic judgments are premises rather than new function-specific pending work. Isolated Runtime/exact-marker checks are extra embedding assertions. The fixed filterMap if branches only check argument types and then delegate membership to the primitive filter rule, so its [nonboolean-result question](SPEC-FILTER-2026-10-22.md#frozen-criteria) remains unresolved; count/find predicates instead obtain Boolean results from == or propagate its child error, and add no such policy question.

On unchanged production source 2e288eef6689e96d666c8583b9335f37b7f01c91, the single directed native debug run passed **16/16** (9 new + 7 existing), exit 0, 10.444 seconds; check and matching outline passed, and all 724 input hashes remained stable. Commands:

```sh
moon check . --target native --frozen --deny-warn -j 1
moon test spec_repeat_search_contract_test.mbt array_std_test.mbt spec_make_array_test.mbt arguments_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize
```

Fixture SHA-256: `9a88ca152951bbd08f511e78e84a4ef7673236de1b016ac0d46e6a19c52049b8`; retained `directed/receipt.json` SHA-256: `dc464b0d5bd926498497087996ba02512edf4b0889152c429a6808e3f4ebdd8d`. Info/format checks preserved interfaces, literals and operation tokens. No product fix or additional full-suite/release/Linux/consumer/Go/C++ run is claimed. Three new manual records preserve all 75 prior objects; historical inventory snapshots and whole-language status remain unchanged.

## Six set transfers at 6346da6e

The six embedded [fixed definitions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1468-L1530) match their cached source bytes, are enabled in stdlib_layer.mbt and have no native override. The [SC1–SC13 fixture](../../spec_sets_contract_test.mbt) supplies independent literal source/handmade-AST witnesses for these **accepted_constructor_transfer** scopes; every record has `remaining_in_scope=[]`:

| Function | Accepted finite constructor/parameter/demand responsibility |
| --- | --- |
| uniq(arr,keyF=id) | Successive key deduplication with first representatives; empty/singleton key skipping, demanded calls and lazy retained Values. |
| set(arr,keyF=id) | sort+uniq composition, stable first representatives, identity/custom keys and lazy retained Values. |
| setUnion(a,b,keyF=id) | Ordered merge, left representative on equal keys, both comparison directions and exhausted suffix transfer. |
| setInter(a,b,keyF=id) | Ordered intersection with left representatives, all merge branches and initial tailstrict input-head demand. |
| setDiff(a,b,keyF=id) | Ordered left difference, all merge branches, retained suffixes and initial tailstrict input-head demand. |
| setMember(x,arr,keyF=id) | Boolean intersection-length result, key identity, empty-arr target/key skipping and match/target-exhaustion tail demand. |

All six include required names, the optional identity default, positional/named/mixed/aliased forms, safe binding/arity errors, isolated failures, unused calls and unchanged originals. uniq/set retain the established [source-defined String/Object/Function admission](SPEC-SORT-DEMAND-2026-10-25.md#sort-admission-and-non-promises-frozen-adjudication), including deferred invalid indices; no blanket Array guard is added. Binary/member value cases satisfy the [public sorted-unique Array precondition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#sets) under the same keyF. Outside it no meaningful set-result promise is asserted; error-valued probes separately test exact source-branch demand.

Sort/foldl, equality/order/>0, Boolean branches, Array concat/slice/index and ordinary call/evaluation are explicit child premises in the existing [language matrix](SPEC-LANGUAGE-MATRIX.md) and [combinator review](SPEC-ARRAY-COMBINATORS-REVIEW.md), not six duplicated unresolved items or a circular comparison proof. Runtime/marker checks are embedding evidence; general callback counts and resource thresholds are not added. No new function-specific textual conflict or implementation defect was found; shared unresolved judgments retain their own scope.

At unchanged production source 6346da6ea3aa47013475d253c84c49d727b118de, one native debug run passed **17/17** (13 new + 4 existing), exit 0, 11.208 seconds; check/outline passed and all 727 input hashes stayed stable. Existing receiver/profile controls retain their previous scope. Commands:

```sh
moon check . --target native --frozen --deny-warn -j 1
moon test spec_sets_contract_test.mbt sets_test.mbt arguments_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize
```

Fixture SHA-256: `e36139e7176c15c3ed42648f380c487522d08f4395f7807218bbdf46860d14d9`; retained `directed/receipt.json` SHA-256: `0bf098510d60abf9f88683d027cdda2af309faf38384f86b2185dffa1fba064e`. Info/format preserved interfaces and operation/literal tokens, apart from the pre-freeze SC8 title clarification. Six records preserve all 83 prior objects; historical inventory snapshots are unchanged. No product fix, new full-suite/release/Linux/consumer/Go/C++ run or overall compliance claim is made.
