# Independent Array extrema demand contracts

## Preparation scope

Base: `946f62853b417cb3e3583b6e920fdab5907f7159`. The product, existing tests,
interfaces, reference corpora and coverage maps remain unchanged. This batch
prepares [fourteen independent groups](../../spec_extrema_demand_test.mbt) for
the previously unreviewed minArray/maxArray demand contracts. No native check,
compilation, semantic test or reference comparison has run for these new groups.
Formatting and static review are preparation only, not passing coverage.

The adjacent count/find definitions were inspected first. They are enabled
source functions, composed from filter/range/equality. No distinct implementation
gap was established by that inspection; their normal/error/lazy/boundary coverage
is still unreviewed. The native minArray/maxArray paths expose more direct
unnecessary-demand defects, so this preparation prioritizes those two functions.
It does not add count/find coverage by implication.

## Fixed authority and admitted domain

Normative sources remain Google Jsonnet v0.21.0 at
`bbb38f1020be1f5aed560928fb839b2c448cefb4`:

- [minArray public contract](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#L2722) and [maxArray public contract](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#L2753) describe optional key extraction and an onEmpty result selected for an empty Array.
- [Fixed definitions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1732) branch on length first. The empty branch returns onEmpty; the nonempty branch uses keyF to compare candidates and retains the earlier candidate when keys tie. The source supplies identity keyF and an error onEmpty default.
- The same definitions select a candidate through lazy function arguments. A constant key does not demand its item argument. With two equal constant keys, an unselected later error element is unnecessary; the selected result is still required. Fold's strict accumulator result does not force the discarded argument.

The checked local copies are outside the repository:

| Reference under /tmp/moonjsonnet-spec-audit.1KasPx | SHA-256 |
| --- | --- |
| stdlib.html | `0eb80c0ccaf781c4c2c1bc06a22d2d6e57f9866f41c0b62431b5ca4f510e6853` |
| upstream-std.jsonnet | `e76dd6b8e51a2ca041b292dadea9c5521aeea5781b0ffe7c2c683865e7e45351` |

This batch admits Array inputs and ordinary comparable Number/String/Array keys.
Its required outcomes are literal and were derived before product execution.
Parsed source and separately constructed public Program ASTs exercise the same
criteria without deriving one tree from the other. Observation gates report
which argument/value heads were demanded; no Go/C++ result or copied reference
implementation is used as an oracle.

## Static implementation differences

The current [dispatch](../../stdlib.mbt) shares the sort/minArray/maxArray entry.
After forcing arr, it immediately forces an explicit keyF and then an explicit
onEmpty for both extrema functions. The [native helper](../../extrema.mbt)
validates key before examining emptiness, forces the first element, and forces
each later element before calling its key function. The fixed branch and
selection definitions instead imply:

1. Nonempty Arrays must leave onEmpty unforced, including a supplied error or
   successfully observable callback gate.
2. Empty Arrays must select onEmpty without demanding keyF, its type, body or
   nested payloads. Invalid-looking but unused key expressions are not eagerly
   rejected in that branch.
3. A constant key and a retained earlier candidate must not force a discarded
   error element merely to visit its slot. Demanding the selected result still
   exposes its own error; the fix must not suppress required output failures.

These are static findings, not measured failures yet. The baseline must retain
the unchanged product and old extrema expectations. A future correction should
remain in the extrema-specific dispatch/helper; sort, membership, strip/split,
global equality/comparison and earlier frozen probes are outside its scope.

## Frozen groups

The table follows the fixture's fourteen top-level declarations. Every group
uses both source and independent AST paths unless a particular path is named.

| ID | Independent expectation | Controls and boundaries |
| --- | --- | --- |
| EX1 | Literal minimum/maximum and first equal-key candidate are selected | Positional/named arr, omitted identity key, reordered keyF, numeric and singleton/tie cases, Unicode/NUL/combining Strings, comparable nested Arrays and projected object IDs |
| EX2 | Source minArray ignores onEmpty for a nonempty Array | Explicit error, all value heads and deferred payloads; direct/type observations and unused-call control |
| EX3 | Handmade minArray retains EX2 | Separate declaration prevents source failure from concealing the AST path |
| EX4 | Source maxArray ignores onEmpty for a nonempty Array | Same independent controls |
| EX5 | Handmade maxArray retains EX4 | Separate declaration |
| EX6 | Source minArray ignores keyF on an empty Array | Error/nonfunction/wrong-arity heads, lazy Array/Object/Function fallback payloads and direct/type/length observers |
| EX7 | Handmade minArray retains EX6 | Separate declaration |
| EX8 | Source maxArray ignores keyF on an empty Array | Same independent controls |
| EX9 | Handmade maxArray retains EX8 | Separate declaration |
| EX10 | minArray with constant numeric keys leaves the unselected tail error lazy | Earlier literal 7 remains selected; direct and type observers |
| EX11 | maxArray retains the corresponding discarded-tail behavior | Separate function declaration; direct and type observers |
| EX12 | Successful gates distinguish both branch demands and shared heads | Empty: input/fallback once, no key. Nonempty: input/key-expression/selected-value once, no fallback/discarded-value. Repeated result reads share values; unused call has no gates |
| EX13 | Required branch/selected-result errors propagate | Isolated input, chosen fallback, needed key expression/body and selected payload markers; empty omitted fallback and needed wrong-arity key reject |
| EX14 | Invalid bindings precede gates; unused optional free names remain Static | Missing arr, extra/unknown/duplicate arguments; independently missing arr/keyF/onEmpty symbols with otherwise valid lexical scope |

EX12 counts forcing of the shared key expression, not the number of calls to
the returned key function. No total order between independent valid callback
effects is invented. Explicit error probes require their Runtime marker;
binding failures use the existing runtime-domain/zero-gate assertion helper.
Shared helpers build inputs or inspect outcomes; they do not supply an extrema
result oracle. Limits remain steps 20000, depth 64 and stack 96.

If a loop fails, only assertions reached before that failure are observed.
In particular, EX10/EX11 start with source, then handmade AST; a first source
failure does not establish the later AST result. No unexecuted branch earns
coverage. Typechecking errors, if any, must be separated from semantic failures.

## Open domains and preserved legacy evidence

The following remain unadjudicated, not waived or counted as passes:

- EXT-A0: non-Array behavior, including mechanical length/fold extensions to
  Strings and empty Objects, versus the documented Array contract.
- EXT-C0: singleton noncomparable values, the source's initial self-comparison,
  complete key-type admission and precise key callback invocation/reuse counts.
- EXT-E0: competing errors and exact diagnostic category/text outside explicit
  markers, malformed raw text, complete Unicode/comparator/resource behavior,
  public std rebinding and all earlier specification disputes.

The existing [extrema fixture](../../extrema_test.mbt) contains older
Go-oriented assertions, including rejection of an empty Array with keyF=1 and
onEmpty=2, rejection of a nonempty Array with an error onEmpty, and success for
a singleton Object without a key. The first two conflict with this batch's
fixed branch criteria; the singleton case stays in EXT-C0 and is not silently
reclassified here. These assertions and the already-correct membership tests
in the same file remain byte-identical, SHA-256
`c630608264e95be353b127644dcc11e0cc52a6ceea2f355bc1afe39b3458d2ae`.
An unchanged copy is saved with this preparation. Any future migration must
retain original inputs, source identity and observed failures; no Go corpus,
global comparison or frozen membership expectation may be edited to hide one.

## Reproducible coverage count

The current count comes from distinct name keys in the committed manual map,
not prose or registered members:

| Commit | tests/spec-public-coverage.json records / distinct names |
| --- | --- |
| 0e7cb7890f972c0e1f9a1ff628e87eee4a7f6dd1 | 57 / 57 |
| 21ee8005fbca4779adb2e01d53000c65f325eb33 | 60 / 60 |
| 06a260ccf2c6d24190f394f9629490678d3c05c7 | 60 / 60 |
| 946f62853b417cb3e3583b6e920fdab5907f7159 | 62 / 62 |

Each historical input is retrievable with `git show COMMIT:tests/spec-public-coverage.json`.
The 946f628 map adds exactly member and contains, and its remaining sixty
records are identical to the parent map. The generated public inventory agrees:
62 reviewed subsets among 153 candidates, zero whole-function acceptances.
`coverage-count-proof.json` in the evidence directory records the four input
blob SHA-256 hashes and this exact preserved-row comparison. This preparation
does not modify the count or claim any new coverage; overall conformance remains
incomplete.

## Planned minimum baseline and freeze

After the parent assigns a testing slot, verify the base/fixture hashes and run
only the following commands sequentially, with stdin closed and a 600-second
wall cap per command:

```sh
RUST_LOG=error moon check . --target native --frozen --deny-warn -j 1 </dev/null
RUST_LOG=error moon test spec_extrema_demand_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize </dev/null
```

Preserve original stdout/stderr, exit, monotonic duration, actual counts and
first-failure cutoffs. Do not change product, frozen criteria or old assertions
before the baseline. Any necessary syntax/type repair must retain the original
bytes and the independent meaning. No snapshot update, priority change,
installation, network, full suite, integration script, Go/C++, Linux, container
or remote execution is included. Return the slot after confirming owned
processes exited; a later correction and verification must have their own scope.

Local preparation evidence is under `/tmp/moonjsonnet-extrema-demand.dre85p0q`:
the 670-file base manifest, original extrema fixture, formatted new fixture,
coverage-count proof and freeze receipt. Frozen new test SHA-256:
`f3cc7628a5726e919328565b11436712e03eee749bf8568cc2d9a9726e61817e`.
Temporary evidence is not an archival guarantee. No private proposal material,
upstream change, new dependency, commit, push or release is part of preparation.

<!-- Independent criteria above are frozen before any baseline execution. -->


## Executed unchanged-product baseline

The authorized slot began with HEAD 946f628 and all 670 tracked base hashes
matching. Both prepared files matched the freeze receipt. No pre-baseline
syntax repair, implementation change or expectation change was needed.

| Command | Actual result | Exit | Seconds |
| --- | --- | --- | --- |
| Native frozen deny-warn check, one worker | Passed | 0 | 0.499 |
| Frozen spec_extrema_demand_test.mbt, native debug | 3 passed, 11 failed | 2 | 7.203 |

EX1, EX13 and EX14 completed. EX2-EX5 failed on the first direct observation
of an explicit error onEmpty; the preceding unused-call control passed, but
later type/head/payload branches were not reached. EX6-EX9 failed on the first
explicit error keyF; later key heads and fallback payload observers were not
reached. EX10/EX11 failed on their first source observation of the discarded
tail error; handmade and type observations were not reached. EX12 completed
its first minArray/nonempty/source value observation, then failed its gate map:
input/key/fallback/selected/discarded were all 1, instead of only
input/key/selected. Later empty, handmade and maxArray branches were not reached.
The generic JsonnetError output is retained as emitted; the independent fixture
and static path analysis identify each probe without inventing diagnostic text.

Raw stdout, stderr, per-command receipts and root MoonBit hashes are under
`/tmp/moonjsonnet-extrema-demand.dre85p0q/baseline`. Baseline test stdout SHA-256
is `c71509e32434ea61f53d5f41e5b9aba0598b474a9e2dbcf5585d67369640be50`;
stderr is empty. Every command process group exited; no timeout occurred.

## Minimal implementation correction and verification

The extrema dispatch now passes optional thunk IDs to the private helper.
After requiring the Array head, the helper selects the empty branch before
forcing or validating keyF, and forces onEmpty only on that branch. For a
nonempty Array, it retains required key validation and initial selected-result
demand. A later explicit key receives the item thunk directly; its item is
forced only if selected. Identity keys still require each compared item.
Initial selection, stable tie selection, key caching, loop tick and global
comparison logic are unchanged; this does not decide EXT-C0.

The shared sort entry still forces input then key before its unchanged helper.
That neighboring dispatch motivates sort's directed regression. Binding behavior
is checked by the arguments fixture. Membership implementation and its earlier
frozen tests, strip/split source and frozen criteria, and global comparison are
byte-identical to the base. No upstream or Go comparison corpus was changed.

| Command after the correction | Actual result | Exit | Seconds |
| --- | --- | --- | --- |
| Native frozen deny-warn check, one worker | Passed | 0 | 0.454 |
| Same frozen spec_extrema_demand_test.mbt | 14/14 | 0 | 11.116 |
| sort_test.mbt | 4/4 | 0 | 0.288 |
| arguments_test.mbt | 1/1 | 0 | 0.131 |
| Original extrema_test.mbt | 1/2 | 2 | 0.242 |
| Migrated extrema_test.mbt | 2/2 | 0 | 5.843 |

All semantic tests used `--target native --debug --frozen --deny-warn -j 1
--no-parallelize`, closed stdin, RUST_LOG=error and a 600-second per-command cap.
No commands overlapped, timed out or left an owned process group. All fourteen
frozen groups now completed their source/handmade, observer and loop branches.
The frozen fixture hash is unchanged. Receipts under `postrepair` and
`migration` retain actual commands, monotonic durations, raw output hashes and
process-exit checks. The slot was returned before documentation/metadata work.

## Precise legacy assertion migration

The original file ran unchanged after the correction. Its first extrema group
failed at `std.minArray([],keyF=1,onEmpty=2)`, where the old error assertion
conflicts with the fixed length-zero branch returning onEmpty. The membership
group passed. Later error-loop assertions were not reached in that run.
Original stdout SHA-256:
`d536b5327ff4f4200ce6c05972d936d1327b1764dc23db7c319617935e36a4e6`.
The full original fixture remains retrievable from base 946f628 and in
`legacy-extrema_test.mbt` under the local evidence root.

| Original input | Old assertion | Revised literal result | Fixed independent basis |
| --- | --- | --- | --- |
| std.minArray([],keyF=1,onEmpty=2) | Error | 2 | Fixed minArray lines 1732-1734 branch on empty Array and return onEmpty without keyF |
| std.minArray([1],onEmpty=error 'forced') | Error | 1 | Fixed minArray lines 1735-1742 nonempty fold never references onEmpty; already independently required by EX2/EX3 |

Only these two outcomes moved from the error list to literal success assertions.
The first group's title now describes branch defaults without presenting Go as
its normative authority. All other inputs/outcomes remain, including singleton
Object success under the still-open EXT-C0 scope, required selected-payload
errors and invalid needed key arity. The complete second membership block is
byte-identical. No snapshot update was used. The migrated two groups passed;
stdout SHA-256 is
`ddd0722f90fd133207ca9e423fc1faa05c3608f3be5c5eb4fdbea4259682b120`.

## Delivery binding and remaining scope

Verified source/test bytes:

| File | SHA-256 |
| --- | --- |
| stdlib.mbt | `4c83dbc6cae5344ac264d08cd8df7601137b2d04f4c4d97f8977dd9c67ad6511` |
| extrema.mbt | `79a4af908659caca0e299c8ad427e864036f08b80aff9ad42affa96c6cba18c4` |
| extrema_test.mbt | `7913d371e8fa8ba7a460cf0f8f16c7aaed804ae6c2f14864237630b9b5a7551b` |
| spec_extrema_demand_test.mbt | `f3cc7628a5726e919328565b11436712e03eee749bf8568cc2d9a9726e61817e` |

Interface generation exited 0 in 0.241 seconds; formatting exited 0 in 0.075
seconds. Neither changed any generated interface or already verified product/
frozen fixture byte. The migrated legacy fixture was verified after formatting.
The public map adds exactly minArray and maxArray; its previous 62 records are
identical, so the new total is 64 reviewed subsets among 153 candidates, with
zero whole-function acceptances. This is a bounded contract result, not an
acceptance inferred from function counts.

Six existing language rules contain sixteen whole-file stdlib.mbt fingerprints.
Their anchors and unaffected implementation were reinspected against the exact
single dispatch hunk. The length/type/object-reflection intrinsics cannot enter
the extrema branch. Only those fingerprints and six dispatch explanations are
refreshed; rule statuses and assertion evidence are unchanged. The original map
and reinspection receipt are retained under the evidence root.

No current full native debug/release suite, standalone integration, archive
consumer, Go/C++, Linux, container, remote or ASan run was performed. Earlier
672/672 debug/release evidence remains bound to 21ee800 only. The baseline eleven
failures and old-fixture conflict remain historical raw failures; the corrected
directed set has no remaining failure. EXT-A0/EXT-C0/EXT-E0 and every earlier
specification dispute remain unresolved. Overall conformance is incomplete.
The private application stays external; no proposal content is in this change.


Both existing offline metadata generators exited 0: public inventory in 1.723
seconds and language matrix in 4.502 seconds. The public inventory changes only
the two reviewed-subset records; the language matrix retains 70 named rules,
24 prose/grammar rows, 28 completed named-rule reviews, one constructor transfer,
63 partial rows, two unreviewed rows and 195 canonical assertion IDs. Its
Markdown remains byte-identical. Generator passes validate mapping structure
and pinned hashes; they are not semantic test passes.

Toolchain: moon 0.1.20260920 (914d7da), moonc v0.10.14+7d59c7ec9,
moonrun 0.1.20260920 (914d7da); feature flags rr_moon_mod and rr_moon_pkg.
The raw `moon version --all` result is retained in the evidence directory.
Final documentation validation and exact commit/input verification have their
own receipts in `documentation` and `delivery/commit-verification.json` beneath
that directory. The latter binds the local delivery commit to these verified
source/test hashes and the original base. Temporary files are local evidence,
not an archival guarantee. No push or release is included.
