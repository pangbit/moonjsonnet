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

## Frozen continuation: sort public-contract review

Base dbf322dabb8aa250003a9cf00b429946b8243bb5. Fixed Google Jsonnet
bbb38f1020be1f5aed560928fb839b2c448cefb4; the four saved reference hashes are
checked in plan.json. No reference interpreter supplies an expected result.
The prior eight SD groups and their baseline/fix remain unchanged.

Authority: D = explicit fixed public description/signature; F = explicit
language/specification rule; S = result derived from fixed std.jsonnet;
H = this embedding's finite host observation; U = unresolved or not proved.
D says sort(arr,keyF=id) and comparison using <=, with a one-argument key.
S at 1433-1466 defines length<=1 identity, stable quick partitions through30,
then a left-biased merge. F supplies lazy function arguments, unique named
arguments (chk-apply), Number/String/Array comparison and lexicographic prefixes.
Function purity is explicit in language.md 140-174. Spec.html 2854-2857 leaves
custom native function semantics undescribed. Therefore host counter traces
can locate demand but do not select a universal keyF callback algorithm/count.

| Contract area | Authority and existing evidence | Frozen addition / limit |
| --- | --- | --- |
| arr/keyF names, default identity, function arity | D/S plus SD1/2/5/8 and sort default/named group | SC1: source/handmade default/explicit identity, reversed named order, closed key capture, used/unused optional key defaults, Static duplicate named rejection including unused call. |
| Zero/singleton identity and skip boundaries | S/F plus SD1-SD4/SD6-SD8, all passed at dbf322d | Existing tests unchanged; no redundant rerun unless product changes. |
| Number/String/recursive Array key ordering | D/F plus SD5 and old normal group | SC2: exact +/-2^53 and dyadic halves, Unicode BMP/supplementary seam, NUL/prefix/combining sequences and recursive Array length ties. No computed sort oracle. |
| Necessary comparison prefixes | F/S plus old lazy-keys group | SC3: shorter key and nested shorter key skip poisoned tails; [] versus [true] is legal when no Boolean child comparison is required; selecting a returned poison still fails. |
| Incompatible compared keys and primitive input errors | F/S plus SD6 and old Type group | SC3: demanded Null/Boolean/Object/Function/nested invalid keys and mixed key types reject without reading invalid-key payloads; Null/Bool/Number input length fails. Strings/Objects/Functions as input remain U. |
| Array/key/callback/comparison error demand | F/S plus SD6/SD7 | SC4: four isolated errors in separate programs; Array error skips key; key/body/comparison errors precede unrelated payload demand. No competing-error order is chosen. |
| Permutation/stability/equal keys/finite width boundaries | S plus SD5, old constant-key group | SC5: independent grouping/index oracle at n2/3/7/8/9/29/30/31/32/33/63/64/65; negative/positive zero ties. No host/product sorting oracle. |
| Original payload kinds, immutability and sharing | F/S/H plus SD3/4/7 and old immutability group | SC6: constant keys retain every payload head kind without nested/body demand; result and original element sharing verified by finite gates. These gate counts are H, not universal key callback counts. |
| General callback multiplicity/order, independent competing errors | U: source algorithm versus pure/native semantics | No blanket exemption and no count-driven rewrite. Pure demanded failures and zero-callback base branch are tested; general native traces remain unadjudicated. |
| Input/non-callable domain extensions and public std rebinding | U: docs Array/one-argument callable versus source reductions | Retain prior open policy and original non-Array reference tests, no pass credit or guessed implementation change. |
| Arbitrary producers, numeric encoding, limits/diagnostics/manifestation | U beyond finite admitted heads | Existing project resource smoke is separate; no universal resource/diagnostic/Unicode/host acceptance is inferred. |

This fixed continuation has six groups, each through source and independently
constructed typed AST. Stable expected indices are derived by group membership
and original index; expected values and isolated markers are literal. It stops
after check, six-group native debug execution and required metadata/info/format
checks, or after an evidenced minimal correction plus affected neighbors.
A failed loop's remaining branches are NOTRUN until an actual complete pass.
Every check/test command is closed-stdin, single-worker, frozen/deny-warn,
no-parallelize for tests, at most300 seconds. No full suite, SSH, Go/C++, network,
new tooling or installation. Any new implementation finding must be established
by the frozen baseline first. If all pass, product code is left unchanged.
Whole-function/public-language acceptance remains false while U rows remain.

### Admission enrichment frozen before the second run

Case-by-case review after the first 6/6 pass found missing key-call class
boundaries. SC1 gained one insertion only: six non-Function heads when a key
application is required, plus zero-formal and two-required-formal functions.
No old line or expectation changed; the six test declarations are identical.
The initial file, plan and raw 6/6 receipt remain preserved alongside the
separately frozen enriched file/plan. This is additional coverage, not a changed
oracle selected from a failure. Both versions ran on unchanged dbf322d product
bytes. No implementation defect was established by either passing run.

### Existing legacy assertions, individually classified

N, L and E refer respectively to the normal, lazy-key and error-case arrays in
[sort_test.mbt](../../sort_test.mbt), in their committed order; P refers to its
three scaling/resource assertions. R below means the particular contract is
reviewed against the fixed clauses and independent SD/SC controls; it is not
whole-function acceptance. U gives no normative pass credit. The existing
four groups were last executed in the preceding correction batch; they were
not rerun here because their test and product bytes are unchanged.

| Case | Existing assertion | Review and independent cross-check |
| --- | --- | --- |
| N1 | sort([3,-1,2,2]) -> [-1,2,2,3] | R: Number order, SD5/SC2 |
| N2 | `named arr=['😀','你','a'] -> ['a','你','😀']` | R: names/Unicode, SD1/2/5 and SC1/2 |
| N3 | [[1,2],[],[1],[0]] -> [[],[0],[1],[1,2]] | R: lexicographic prefixes, SC2/3 |
| N4 | keyed objects with ids a,b,c -> b,a,c | R: source-derived stable ties, SD5/SC5 |
| N5 | keyF=function(x)-x -> descending Numbers | R: explicit key behavior, SC1 |
| N6 | [sort(a),a] retains original [3,1,2] | R: immutability, SD5/SC6 and private-copy inspection |
| N7 | [sort([]),length(sort),objectHas(std,'sort'),objectHasAll(std,'sort')] -> [[],2,false,true] | Empty/arity R via SD1/2 and SC1; std's hidden-field reflection is a separate cross-feature control, not full namespace acceptance |
| N8 | length(sort([{}])) -> 1 | R: singleton payload head unread, SD3/4 |
| L1 | length(sort([error,error],constant0)) -> 2 | R: irrelevant payloads remain lazy, SD7/SC6 |
| L2 | keyed objects select good .v without unrelated error field | R: key/payload separation, SD5/SC4/6 |
| L3 | key [-x,error] selects value 2 | R: unequal prefix skips suffix, SC3 |
| L4 | sort([],function(x,y)error) -> [] | S reduction retained; unused incompatible key's public admission remains U |
| L5 | key function(x,y=0)x+y sorts [2,1] | R: one supplied argument plus lazy default, SC1 |
| E1 | sort('abc') -> Type | U: docs Array domain versus source String expansion. Existing error is not a normative oracle |
| E2 | sort([2,1],null) -> Type | R: needed key head must be callable, SD6/SC1 |
| E3 | sort([true,false]) -> Type | R: demanded Boolean keys unsupported, SC3 |
| E4 | sort([1,'a']) -> Type | R: mismatching key types, SC3 |
| E5 | sort([{},{}]) -> Type | R: demanded Object key unsupported, SC3 |
| E6 | key returns null -> Type | R: demanded Null key unsupported, SC3 |
| E7 | length(sort([1,error])) -> Runtime | R: required identity payload, SD6 |
| E8 | length(sort([1,2],function(x)error)) -> Runtime | R: required key body, SD6/SC4 |
| E9 | sort([1,2],function(x,y)x) -> Runtime | R: missing required key argument, enriched SC1 |
| E10 | sort() -> Runtime | R: missing arr, SD8 |
| E11 | sort(keyF=function(x)x) -> Runtime | R: missing arr, SD8 |
| E12 | sort(xs=[]) -> Runtime | R: unknown name, SD8 |
| E13 | sort([],arr=[]) -> Runtime | R: positional/named overlap, SD8 |
| E14 | sort([],function(x)x,0) -> Runtime | R: excess positional argument, SD8 |
| P1 | sort(reverse(range(1,2000))) == range(1,2000) | Secondary project regression using product range/reverse/equality; SC2/5 supply independent order/permutation oracles |
| P2 | constant-key range(1,100) retains original order | Secondary source-property regression; SC5 supplies independent grouping/index expectations |
| P3 | steps=1000 gives Limit for 100 items | H: local resource protection, not a standardized Jsonnet step count |

### Algorithm audit and remaining decisions

The fixed source's <=1 guard and stable partitions/left-biased merge define the
reviewed Array result. Successful Boolean comparison predicates avoid the
separate nonboolean filter-result dispute. Its formal filter relation selects
original input indices; the reviewed source derivation preserves their order.
The native loop caches one key head per input item and stable-merges runs.
Inspection shows each output slot receives an original thunk once, the input
Array is never mutated, and the left run wins equal keys. Inductively, merging
ordered runs preserves their multiset and stable key order, assuming the child
comparison relation is defined and coherent. Recursive key comparison stops at
the first unequal common-prefix member or the shorter length. SC2/3/5 exercise
those assumptions and boundaries; they do not complete every child producer,
raw numeric/string encoding or the existing greater-than formula dispute.

The native and fixed-source algorithms are deliberately recorded separately.
For two successful items, ordinary direct expansion has one shared pivot call
and a separate rest-item call in each partition; the native map computes one
key per item. This is a static application-structure difference, not a newly
executed Go/C++ trace or proof that effectful key callbacks are equivalent.
The fixed language requires pure functions; the specification explicitly leaves
custom native semantics undescribed. Exact effectful-native multiplicity/order
cannot be uniquely accepted from these clauses. It remains unadjudicated rather
than being silently waived or used to rewrite the cache. Isolated required key
and comparison errors still must propagate, as SD6/SC3/4 verify. Competing-error
message priority is not selected by matching interpreter outputs; the formal
error model is stuck execution and does not standardize error presentation.

Non-Array input remains a concrete scope decision. The literal source returns
length0/1 Strings/Objects/Functions unchanged when length is defined, while the
native helper requires Array; longer Strings can mechanically reach character
sorting. Public documentation only promises an Array argument. Those source
reductions and the old String rejection cannot both be promoted to a uniquely
settled total public contract. Null/Boolean/Number failures are independently
covered because source length cannot admit them. Unused invalid key types/arity
have the analogous documented-domain versus source-guard issue. Neither policy
is changed by this batch. Generic public-std rebinding, arbitrary producer and
host/resource/manifestation compositions also retain their separate gaps.

### Actual continuation results and binding

The first six groups passed, then the enriched six groups passed in full.
All 684 base entries matched dbf322d before, between and immediately after
the two check/test pairs, before the planned documentation/map updates.
Both frozen versions, plans and raw receipts remain at
`/tmp/moonjsonnet-sort-contract.psw4ohdu`. Each command used closed stdin,
--target native --frozen --deny-warn -j 1, debug and --no-parallelize for tests,
with a 300-second hard limit. Every owned process group exited.

| Stage | Exit | Actual result | Seconds |
| --- | --- | --- | --- |
| baseline-check | 0 | Native check passed | 0.510 |
| baseline-test | 0 | 6/6 passed | 6.451 |
| enriched-check | 0 | Native check passed | 0.270 |
| enriched-test | 0 | 6/6 passed | 6.587 |

| Frozen artifact | SHA-256 |
| --- | --- |
| Initial six-group test | 6d16551900c126a1819acb43fe1a0fcf2b8f969ab38b711df282e8283d10a71d |
| Enriched six-group test | b43ad430cbcf40fe8fb2fb97bca29821832e97f5a099c1ad47ad5ac658795ade |
| Initial plan | 2c85ded74a650fab3572514d75fe0d02dabee447809905c9ba7bd106f13ec572 |
| Enriched plan | 1b907cafcc37e3752a991c310b60ec0cb8a14f3dd267cf177c09a5bb8c0a077a |

Both test stdout streams report Total tests:6, passed:6, failed:0 and have SHA-256
`98566e3b0f8ddd392230312d4a93343c59922153eac8fd89fe88ef3a5e9815cd`;
the separate test-input hashes above identify the added assertions. Test stderr
is empty. This is six distinct groups with a preserved earlier version, not
twelve newly distinct groups. The preceding eight SD groups and eight neighbors
remain source-bound historical runs, not re-executed counts here. Product,
public interfaces, old tests and all Go/C++ snapshots are unchanged.

The sort map alone is extended; all 64 other manual records stay equal. There
are still 65 reviewed public subsets, zero whole-function acceptances and no
new language-rule completion. Full package/release/CLI/Linux/reference campaigns
were NOTRUN. The earlier 228cb25 platform results cannot validate new source
merely because these finite sort checks pass. No new SSH or push was performed.

### Final metadata checks

The existing public-inventory generator was reused unchanged after staging the
new test so its scanner includes the enriched test hash. Only sort's existing
manual record changed. No implementation inspection hashes or language matrix
needed rebinding: product and existing test bytes are unchanged. Required
interface/format checks also passed with no .mbti change. The installed info
subcommand rejected -j before doing any work (exit2); the supported original
info command was then used successfully. This tooling correction is preserved
separately and is not a semantic test failure.

| Stage | Exit | Seconds |
| --- | --- | --- |
| final-info | 2 | 0.025 |
| final-info-supported | 0 | 0.331 |
| final-format | 0 | 0.024 |
| public-inventory | 0 | 1.643 |
