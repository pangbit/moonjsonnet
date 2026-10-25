# Array sorting: cardinality branches and demand

## Frozen criteria before baseline

Base: `60269d8a1e4d3d1b624e29892528434aebca7c3f`. The fixed official source is
Google Jsonnet `bbb38f1020be1f5aed560928fb839b2c448cefb4` (v0.21.0).
The local std.jsonnet SHA-256 is
`e76dd6b8e51a2ca041b292dadea9c5521aeea5781b0ffe7c2c683865e7e45351`;
stdlib.html is `0eb80c0ccaf781c4c2c1bc06a22d2d6e57f9866f41c0b62431b5ca4f510e6853`.

[Public sort](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#std-sort)
uses arr and optional keyF=id. Its
[fixed source definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1433-L1466)
selects quickSort through length 30, otherwise merge sort. The quickSort branch
returns the original Array when length is zero or one. It does not read keyF,
call it, compare keys or evaluate an element. A later selected element or JSON
manifestation still demands that element normally. At length two and above,
required key calls/comparisons must succeed before a sorted Array is obtained.
The lower/upper partition and left-biased merge preserve equal-key input order.

This reviews the complete zero/singleton Array identity branch relative to an
already evaluated Array head, plus bounded nondegenerate sorting controls.
Arbitrary producers, non-Array source extensions, every comparison/key domain,
exact native callback counts for general sorting and competing independent-error
order remain outside it. It is not whole-function acceptance. A0/B0/N0/R0/PE0,
DF0/HP0, the greater-than print conflict and all existing unknowns are unchanged.
No upstream result supplies the oracle, and no private proposal is read or copied.

The maintained dispatcher currently forces an explicit keyF before sort_values;
that helper validates it and constructs every key before checking its count.
Static inspection therefore identifies a mismatch for the source's degenerate
branch. The existing four sort test groups are reference-oriented candidates,
not manually mapped normative coverage; sort currently has no public map record.
The original implementation and legacy test bytes must be retained before repair.

| Group | Independent required result and boundary |
| --- | --- |
| SD1 / SD2 | Separate source / handmade-AST entries: empty and singleton Arrays return literal results, shape/type and unused-call results without evaluating an explicit error-valued keyF; positional and reordered named arguments agree. |
| SD3 / SD4 | Separate entries: singleton length/type keep an isolated element error, nested Array/Object payload and Function body unread, both with omitted keyF and with a failed callback body. |
| SD5 | Literal numeric/Unicode ordering, duplicate stability and input preservation; finite lengths2/30/31 span the specified source branch seam. Expected ascending integers are constructed arithmetically, never with a product or host sort. |
| SD6 | Required Array/key head/key body/multi-element payload errors propagate their sole marker. Selecting a returned singleton demands its element while its unused key stays unread. Required invalid callable/comparison heads reject. |
| SD7 | Finite native gates observe only Array shape at zero/one, then the selected result element when requested. At two with a constant key, key evaluation/application are observed and input payloads remain unread. No universal callback count/order is inferred. |
| SD8 | Missing/unknown/overlapping/extra bindings reject before provided native gates; unused whole calls remain lazy. Undefined key/default-body names remain Static even for empty Arrays; explicit Boolean shortcuts skip calls. |

All eight groups construct source and typed public AST separately with neutral
existing helpers. Expectations are literal JSON, mathematical monotonic sequences
or isolated markers. Type/Runtime/Static categories are embedding phase controls,
not standardized diagnostic text. A test loop stops at its first failure;
remaining subcases are NOTRUN until a later complete passing run.

## Minimal correction and validation plan

First run unchanged product code with the new frozen tests. Preserve raw
stdout/stderr, actual exits/durations, source/test hashes and first-failure
cutoffs. A syntax/type-check failure is not a semantic failure. Only after the
mismatch is measured, keep optional keyF as a thunk ID and return the original
zero/singleton Array before key or element evaluation. Keep all multi-element
comparison, stable sorting and global numeric conversion paths unchanged.

Run the old sort_test.mbt unchanged after the fix to record any legacy conflict.
Four existing expectations demand an unused empty/singleton key or element:
empty/null-key, singleton element-error under length, singleton failed key body
under length, and singleton wrong-arity key. If those conflict with the fixed
branch, retain their old bytes/output and move only the old error inputs to
length-two contexts where comparison requires the same check. Do not alter the
new eight-group criteria or frozen Go/C++ comparison fixtures.

Directed native check and debug only, one worker, --frozen --deny-warn and
--no-parallelize; each command has a 300-second limit and closed stdin. Then run
the same eight groups and the minimally affected sort/arguments/sets neighbors.
Use required info/format checks and the existing public-inventory tooling; add
only sort's reviewed dimensions after actual results. No new metadata framework,
full suite, reference interpreter, remote window, installation or push is part
of this batch. Existing whole-suite Linux evidence remains bound to 228cb25.

## Executed correction and preserved baseline

The unchanged product type-checked, then ran all eight groups: **two passed and
six failed, exit 2**. SD5's normal/stable/threshold controls and SD8's
admission/skip/static controls passed. The raw failures precede any repair:

| Group | First measured failure and original cutoff |
| --- | --- |
| SD1 / SD2 | First empty Array / positional call forced the unused key error. Later named/singleton subcases NOTRUN. |
| SD3 / SD4 | First singleton element error, omitted key, was forced under length. Later payload kinds/key forms NOTRUN. |
| SD6 | Selected singleton raised sort-unused-key-head rather than the required sort-selected-singleton marker. Later handmade/invalid-type tails NOTRUN. |
| SD7 | First source empty-Array gate observed array=1,key=1 rather than array=1. Later singleton/handmade/two-element subcases NOTRUN. |

Only two private implementation paths changed. The dispatcher passes keyF's
optional thunk ID; sort_values returns its already admitted zero/singleton Array
before forcing the key, validating its callable type, constructing keys or
reading elements. This directly covers both cardinalities for any deferred key
or payload. Other inputs retain the former key forcing/type-validation order;
the multi-element stable comparison/cache loop, extrema and global comparisons
are unchanged. Selecting/manifesting a returned element still demands it.

The **same frozen eight groups passed in full**, including all formerly skipped
finite subcases. Their SHA-256 remained
`6d67ed4889384f26e9f230e44ed8bea47c35ccbe2b2832f1971fd9814ec02979`
from pre-baseline formatting through final info/format checks. This establishes
the admitted zero/singleton Array branch by inspection and executed controls,
with bounded nondegenerate checks; it does not accept the complete function.

## Exact legacy migrations

The old sort_test.mbt was first run unchanged after the correction: **three
passed, one failed, exit 2**. Its error loop stopped at std.sort([],null), which
the fixed source returns without reading keyF. The following three conflicts
were identified from that source branch but were NOTRUN in the original failing
loop. They are not four separately measured failures. The original file and raw
stdout remain preserved. Its SHA-256 is
`a21d14f8cd67f0c5045930d3030d6f64d8b9d1fa5f3ebcd0cbd62390c2c8a844`.

Only these four input expressions moved to two-element contexts where sorting
requires the same check. Their existing error assertions, the new frozen test
and all reference-comparison snapshots are unchanged.

| Original input | Original project expectation | Fixed source result and why that unconditional expectation is unsupported | Required-demand replacement | Replacement expectation |
| --- | --- | --- | --- | --- |
| std.sort([],null) | Type error | []: the [length<=1 return](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1433-L1437) never reads or calls keyF. An unconditional callable check adds demand absent from this definition. See the documented-domain qualification below. | std.sort([2,1],null) | Type error when comparison requires a callable key |
| std.length(std.sort([error 'forced'])) | Runtime element error | 1: the [same identity return](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1433-L1437) preserves the element thunk; Array length needs only cardinality. The old expectation forced an unneeded element. | std.length(std.sort([1,error 'forced'])) | Runtime element error when a required key demands it |
| std.length(std.sort([1],function(x)error 'forced key')) | Runtime key-body error | 1: the [identity guard](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1433-L1443) selects no pivot/partition, so a valid single-argument key is applied zero times. The old expectation called an unused callback. | std.length(std.sort([1,2],function(x)error 'forced key')) | Runtime key-body error on required application |
| std.sort([1],function(x,y)x) | Runtime missing-argument error | [1]: the [same guard](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1433-L1443) makes no application that could bind x/y. The old expectation required an unused call. See the documented-domain qualification below. | std.sort([1,2],function(x,y)x) | Runtime argument mismatch on required application |

The fixed [public description](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#std-sort)
specifies a single-argument keyF and describes sorting using <=; it does not
require eager validation or callback execution for zero/singleton Arrays.
The null-key and two-parameter-key rows are literal reductions of the fixed
source, outside that documented callable domain. Their migration removes an
unconditional validation assumption and retains checks where the source needs
a call; it does not adjudicate every invalid unused key's public admission/error
policy. The decisive new failures also use valid key functions with poisoned
bodies or omitted identity with an unread element, independently of those two
invalid-key legacy inputs. No documentation/source conflict requires eager
key/element demand within the reviewed Array branch. General invalid-key domain
policy and the source's < / >= partition versus the description's <= remain
separate from this no-comparison branch. Go/C++ were NOTRUN, so neither agreement
nor a new compatibility conflict is claimed.

For an already evaluated Array head of length zero/one, the defined branch has
zero keyF-expression demand, zero keyF applications, zero comparisons and zero
element-head demand. The supplied Array head itself is required when the call is
used; a selected result element is required later, and an entirely unused call
stays unread. The finite native gates verify those boundaries in both entries.
For lengths two and above only positive required-call observations are asserted;
the native key cache is unchanged and exact source/native callback multiplicity
or independent error order is not accepted by this batch.

The migrated legacy sort groups (four), arguments group (one), and source-layer
set groups (three) passed together: **8/8**. No conflicting legacy assertion is
silently excluded, and no complete set-function claim is inferred.

## Local execution and source binding

All runtime checks used macOS native debug, closed stdin, one worker,
--frozen --deny-warn --no-parallelize and 300-second command limits. Installed
versions: moon/moonrun 0.1.20260920 (914d7da, 2026-09-20), moonc
v0.10.14+7d59c7ec9 (2026-09-18). The base is
`60269d8a1e4d3d1b624e29892528434aebca7c3f`: all 682 existing tracked entry hashes
were unchanged before baseline. Original product/tests, frozen criteria, plan,
raw stdout/stderr and per-command argv/PID/exit/duration/group-exit receipts
remain at `/tmp/moonjsonnet-sort-demand.jsu7u82a`. No remote operation was made.

```sh
moon check . --target native --frozen --deny-warn -j 1
moon test spec_sort_demand_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize
moon test sort_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize
moon test sort_test.mbt arguments_test.mbt sets_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize
moon info --target native --frozen
moon fmt
```

The original sort-only command was run before migration and remains a separate
failing record. Existing inventory generators also ran with --frozen -j 1.

| Stage | Exit | Actual result | Seconds |
| --- | --- | --- | --- |
| baseline-check | 0 | Native check passed | 0.534 |
| baseline-test | 2 | 2 passed / 6 failed | 6.760 |
| postrepair-check | 0 | Native check passed | 0.558 |
| postrepair-frozen-test | 0 | 8/8; frozen bytes unchanged | 9.262 |
| postrepair-legacy-original | 2 | 3 passed / 1 failed; original file | 0.194 |
| neighbors | 0 | 8/8 (sort 4 + arguments 1 + sets 3) | 7.461 |
| final-info | 0 | No .mbti change | 0.310 |
| final-format | 0 | No formatting changes | 0.023 |
| public-inventory-cache-access | 0 | 153 candidates; 65 mapped subsets | 1.770 |
| language-matrix-cache-access | 0 | Existing language completion counts unchanged | 4.705 |

| public-inventory-final | 0 | New frozen test hash included by the unchanged scanner | 1.620 |

The initial inventory invocation failed to acquire the dependency-cache lock
inside the sandbox (exit 255, before generation). Formal cache-access approval
allowed the existing frozen generator to run; no dependency was installed.
A preparation-only assertion also stopped before writing the language map:
six previously reviewed rules contain sixteen inspected anchors, not six.
The exact private-dispatch-only diff and all unchanged anchors were checked;
only those sixteen whole-file hashes were rebound. All other rule mappings and
the 216 evidence IDs remain identical. Positive regeneration retained 70 named
rules plus 24 prose/grammar rows, 28 completed named-rule reviews (9 static,
19 evaluation), one constructor-transfer review, 63 partial and two unreviewed
rows. This is metadata freshness, not new language execution or acceptance.

All 64 previous public manual records remain equal as parsed JSON; only sort
was added, giving 65 reviewed subsets and zero whole-function acceptances.
The new test is explicitly staged before final inventory generation so the
existing tracked-file scanner records its hash. Neither generator changed.

| Validated input | SHA-256 |
| --- | --- |
| stdlib.mbt | 31d25cd1347257609205d66e1de21a15dd208388b761dfcc5114b79c1239d487 |
| sort.mbt | 76f5c242863341ad84ddeb9fdb399ef4d1ec4e926a009926af8362030a5e10f5 |
| spec_sort_demand_test.mbt | 6d67ed4889384f26e9f230e44ed8bea47c35ccbe2b2832f1971fd9814ec02979 |
| sort_test.mbt | 2cb9794bd670abc9040085c3a31ac4cb6a399092ecdec57d31581845f49c9471 |
| arguments_test.mbt | 86def26826d5387d11a8f80219d1ccb5811006176372d7f055bae953805e1336 |
| sets_test.mbt | d0b7871aa99c4f457a595585cdcdf8cc174e8450d53c9016f7eaafa925c0598d |
| pkg.generated.mbti | dd585b072ff5a5136c68c2b66f92b9faf31721d392fcb44ab3e687b4c72fb3a3 |

| Raw stdout | SHA-256 |
| --- | --- |
| baseline-test | 46334a9f1b9fa7a0fbe772d15bf2b3f0d616bd5115797788cbea4e7dbd051f00 |
| postrepair-frozen-test | 764157e72b2dd2e8e0a0545e7f821c609e694e542766a3c5c6666f28561c5f05 |
| postrepair-legacy-original | e9488d840233b57041ce420ef7b5539fa44e394ee8ee2a85e95fd9d438f1580e |
| neighbors | 764157e72b2dd2e8e0a0545e7f821c609e694e542766a3c5c6666f28561c5f05 |

These test stderr streams are empty; check/info/format receipts retain their
separate stderr hashes. Every command group was confirmed absent on completion.

Full package regression, release, CLI, Linux and Go/C++ comparison were NOTRUN
on the corrected product bytes. The [native regression record](SPEC-NATIVE-REGRESSION-2026-10-23.md#linux-native-evidence-at-228cb25)
keeps Linux debug 734/734, later release 734/734 and CLI 11/11 tied to 228cb25
and their separate windows. No earlier full-suite result is promoted to this
source. Whole-function and whole-language conformance remain incomplete; all
listed disputes and uncovered domains remain open.
