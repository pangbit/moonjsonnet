# Array extrema comparison and remaining scope

## Static decision and preparation status

Base: `37facf2939fb11aa96bb22264eba9694d9e6c167`. This continuation reviews the
open domains in the [previous demand report](SPEC-EXTREMA-DEMAND-2026-10-23.md).
It does not alter that report, its frozen fourteen groups, product code, legacy
fixtures, interfaces, coverage maps or historical results. Thirteen new groups
in [spec_extrema_comparison_test.mbt](../../spec_extrema_comparison_test.mbt)
are prepared but uncompiled and unexecuted. No new pass, baseline failure or
whole-function acceptance is claimed.

Only existing local materials were read. No network, interpreter comparison,
native build, check, test, generator, formatter, installation or push was run
for this preparation. The public map remains 64 reviewed subsets among 153
candidates, with zero whole-function acceptances; overall conformance remains
incomplete.

## Fixed authority and derivation

All references remain Google Jsonnet v0.21.0 at
`bbb38f1020be1f5aed560928fb839b2c448cefb4`. The local immutable inputs under
`/tmp/moonjsonnet-spec-audit.1KasPx` were independently hash-checked:

| Input | SHA-256 |
| --- | --- |
| stdlib.html | `0eb80c0ccaf781c4c2c1bc06a22d2d6e57f9866f41c0b62431b5ca4f510e6853` |
| upstream-std.jsonnet | `e76dd6b8e51a2ca041b292dadea9c5521aeea5781b0ffe7c2c683865e7e45351` |
| spec.html | `bbac3701ef0316fc29de6c543049ae8f0f78c876bdd94fbf6ab845b2023a720a` |
| language.md | `c55666af13894c8100c84fb053e647cd0ca516f3bb554d0ced29dfa83c3772be` |

The [standard-library introduction](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#L21)
points to std.jsonnet for functions expressible in Jsonnet. The
[minArray/maxArray public descriptions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#L2737)
require comparator values from keyF, and describe selection from an Array.
They supply no singleton exemption from comparison and no requirement to execute
a key callback exactly once. Their
[fixed definitions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1732)
use arr[0] as the initial candidate and fold over the entire Array.

The [foldl definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L823)
starts at index zero; its first callback receives the initial candidate and
arr[0]. The [foldl prose](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#L2243)
also includes the first element rather than starting at index one. Therefore
both extrema compare the first key with itself before selecting a result or
visiting the next candidate. Eliminating that comparison is safe only if its
demand and possible failure are preserved.

The [fixed comparison helper](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1691)
explicitly rejects Boolean, Object and Function heads. Its Array branch compares
a common prefix recursively; equal prefixes continue. Null reaches a relational
operator for which there is no admitted Null comparison. This agrees with the
[Number/String/Array comparison rules](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#L2448)
and [numeric/overloaded-operator prose](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#L2796).
These establish the bounded rejection and necessary-prefix cases below; they
do not complete every comparator judgment or all finite/Unicode producer rules.

Finally, [lazy function arguments](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#L154)
and [conditional evaluation](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#L2273)
make the key comparison a dependency of candidate selection. When a key function
ignores its item and its body or returned key's required prefix fails, the item
is not needed to evaluate that condition. A later selected-branch payload must
not be demanded first. This is a condition-versus-branch dependency, not a new
left-to-right rule between two independent operands.

## Decisions by previously open area

| Area | Official-source relationship | Decision and current implementation |
| --- | --- | --- |
| EXT-C1: singleton noncomparable identity or explicit keys | The public comparator requirement, foldl's first callback and source comparison helper agree; no contrary singleton rule was found | Determinate bounded rejection for Boolean/Null/Object/Function and reached nested noncomparable Array keys. Current native extrema computes a singleton key but skips comparison, so it can return a value where comparison must fail. This is a static implementation gap, not an observed test result. |
| EXT-C2: initial self-comparison of Array keys | Fixed fold starts at zero; equal-key comparison must traverse its necessary equal prefix | Determinate demand for an error within that prefix, even with only one candidate or a later candidate differing at an earlier position. Current traversal starts at one and omits that first comparison. Same-reference identity is not a substitute for recursively comparing a partial key. |
| EXT-E1: failing key condition versus selected item | Lazy application and if-condition dependency agree with the source body | Determinate non-demand of an item ignored by a failing key condition. Current helper forces the first selected item before calling its key, exposing an unnecessary gate/error. A successful key condition must still demand the selected result. |
| EXT-A0: non-Array inputs | Source mechanically accepts more domains than the Array-oriented description explicitly admits; there is no explicit contrary String/error rule in this material | Keep public admission of String and empty Object/zero-parameter Function unresolved. Source-derived outcomes are explanatory candidates, not passing assertions or compatibility exemptions. |
| EXT-C3: exact keyF invocation count/cache policy | Source has two key call expressions per fold step; prose says keyF is called on each element, not exactly once | Keep exact callback counts unresolved as a normative requirement. Pure calls may be optimized while preserving values, failures and demand. Host native effects cannot turn source syntax into a universal required timeline. Current key caching is not itself a proved defect. |
| EXT-E2: independent competing errors | Formal errors are stuck execution; diagnostics and host native semantics are not fully prescribed | Keep independent operand/error precedence, category/text outside isolated markers, and native callback ordering unresolved. Existing order must not be promoted merely because a reference interpreter agrees. |

The old `std.minArray([{}])` success assertion in extrema_test.mbt now has a
specific static conflict under EXT-C1. It remains unchanged for the next
baseline. This is a project legacy expectation, not an official-source conflict.
If execution confirms the gap, preserve the original input, assertion and raw
failure before any separately justified migration. No Go corpus may be edited
to hide the conflict.

## Non-Array analysis without an invented oracle

The source's length test and fold allow several mechanical candidates:

- Nonempty Strings can be indexed into one-codepoint Strings, then compared by
  codepoint; an empty String selects onEmpty. Current native extrema's Array
  guard rejects both. The public Array wording does not explicitly settle
  whether this source extension is part of the supported contract.
- An empty visible Object and a zero-parameter Function have length zero under
  the library's length behavior, so the source can return onEmpty without
  indexing. This mirrors the existing unresolved fold scope. It does not by
  itself authorize adding these as public accepted inputs.
- Nonempty Objects/positive-parameter Functions reach incompatible indexed
  selection under ordinary keys. Boolean/Null/Number inputs cannot satisfy the
  required length operation. Current rejection of these inputs is not evidence
  that every error priority or all out-of-domain cases have been settled.

There is no explicit official pair of contradictory required results identified
for these examples; the unresolved issue is domain admission. The distinction
matters: silence is not an exemption, but broadening the native API solely from
a mechanical source path would also require an unrecorded domain decision.
No non-Array expectation appears in the new fixture.

## Callback and error boundaries

For a terminating Array of n comparable keys, the fixed source presents two
key applications at each of n fold steps, including the first element paired
with itself. The current helper computes each candidate's key once and retains
the winner's key. This structural difference alone does not justify an exact
2n native-callback assertion: the language describes functions as
[referentially transparent](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#L165),
while [std.native semantics and diagnostic presentation](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#L2845)
are outside a fully prescribed pure-language contract. A pure key expression's
required failure cannot be optimized away merely by caching a successful head.

The new gates measure only absence of selected-payload demand before a failing
condition. They do not count calls to keyF. Independent pure-marker probes
record the same condition/branch dependency; exact Runtime marker checks are
local API controls for explicit errors, not a standardized implicit diagnostic.
Noncomparable-key assertions accept the project's Runtime or Type category and
reject parse/static/limit/unsupported failures. Program construction is outside
the runtime catch, avoiding a compilation/static failure being counted as a
semantic success.

The known greater-than formal rules print `<` in their conclusions. That
[existing conflict](SPEC-RELATIONAL-SIGN-2026-10-23.md) remains unreviewed. The
new negative cases fail while producing the comparison child, before the
minArray greater-than predicate could have a value; they do not resolve the
misprint. Positive controls use the already admitted ordinary comparator domain
and do not claim completion of the disputed greater-than rows.

## Frozen executable groups

Each function/path gets a separate declaration so a source failure cannot hide
the corresponding handmade-AST result. Every input is synthetic. Shared helpers
construct trees or inspect results; no comparator or reference executable
calculates expected outcomes.

| ID | Group | Independent expectation |
| --- | --- | --- |
| EC1 | Source minArray singleton domain | Runtime rejection before a result-type observer for singleton Object/Boolean/Null/Function or reached nested noncomparable Array, both identity and explicit constant keys |
| EC2 | Handmade minArray singleton domain | Same criteria through independently constructed AST |
| EC3 | Source maxArray singleton domain | Corresponding maximum criteria |
| EC4 | Handmade maxArray singleton domain | Corresponding maximum criteria |
| EC5 | Source minArray initial key prefix | The initial self-comparison propagates its sole explicit key-tail error for singleton keys, nested keys and a multi-element Array whose later key differs earlier |
| EC6 | Handmade minArray initial key prefix | Same prefix cases through independent AST |
| EC7 | Source maxArray initial key prefix | Corresponding maximum cases |
| EC8 | Handmade maxArray initial key prefix | Corresponding maximum cases |
| EC9 | Source minArray condition before payload | A failing key body or required Array-key prefix leaves the selected-item gate absent; pure key-error versus branch-error controls preserve the same dependency |
| EC10 | Handmade minArray condition before payload | Same dependency through independent AST |
| EC11 | Source maxArray condition before payload | Corresponding maximum dependency |
| EC12 | Handmade maxArray condition before payload | Corresponding maximum dependency |
| EC13 | Supported singleton controls | Number/String/empty/nested comparable Array keys preserve literal 7; constant numeric keys select lazy Object/Array/Function/Boolean/Null heads; required selected-result errors still propagate |

Every negative case retains an unused-call control. Key-prefix failures use a
type observer to avoid confusing necessary comparison with later JSON
manifestation. EC9-EC12 include direct and type observers and skip no category
by catch-all success. EC13 checks source and handmade AST. Limits remain
steps 20000, depth 64 and stack 96. If a loop fails, later cases are unexecuted;
only a completed group can establish its full bounded list.

## Minimal execution plan and scope

No slot is owned during preparation. After explicit parent allocation, verify
HEAD, all 672 existing tracked hashes, both new frozen files and the four fixed
reference hashes. Run these two commands sequentially, closed stdin,
RUST_LOG=error, one worker and 600 seconds per command:

```sh
RUST_LOG=error moon check . --target native --frozen --deny-warn -j 1 </dev/null
RUST_LOG=error moon test spec_extrema_comparison_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize </dev/null
```

Retain raw stdout/stderr, actual exit/counts/duration, process-exit verification
and frozen hashes. A type/syntax problem is not a measured semantic failure;
retain the original bytes and any necessary neutral correction separately.
Do not change the product, old singleton expectation or new criteria before
that unchanged-product baseline.

If the baseline confirms the static gaps, the proposed implementation scope is
only the private extrema helper's initial comparison/selection demand. Preserve
sort, membership, strip/split, global comparison and all old frozen criteria.
The minimum subsequent regression proposal is the same 13 groups, the prior
14 demand groups, and extrema_test.mbt with its singleton conflict preserved
first. Add binding/sort regression only if their dispatch is changed. Any
legacy expectation migration needs the individual authority and raw failure
record. Exact callback caching and non-Array admission must not be widened by
a convenience repair. No implementation is changed or correction authorized
by this preparation itself.

Full native debug/release, integration scripts, upstream Go/C++, Linux,
containers, remote and ASan remain NOTRUN for these new probes. No matrix status
or function count is promoted by static reasoning alone. The local evidence
root below stores the complete base manifest, original legacy fixture, new
fixture/report bytes and frozen minimum argv. Temporary evidence is not an
archival guarantee. The private proposal remains outside the repository.

<!-- Criteria above are frozen before any execution. -->

Local preparation evidence: `/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-extrema-comparison.ziwcw8he`.


## Executed baseline and preserved failures

The parent allocated one local test slot. Preflight confirmed base 37facf2,
all 672 tracked hashes, both frozen new files and the four fixed normative
reference hashes. Check succeeded without any syntax/type correction. Product
code, old singleton expectation and frozen criteria were unchanged at baseline.

| Baseline command | Actual result | Exit | Seconds |
| --- | --- | --- | --- |
| Native frozen deny-warn check, one worker | Passed | 0 | 0.567 |
| spec_extrema_comparison_test.mbt, native debug | 1 passed, 12 failed | 2 | 6.963 |

EC13 completed. EC1-EC4 passed their unused control, then failed because the
first singleton Object/identity call produced a result type instead of rejecting;
explicit key and later type cases were not reached. EC5-EC8 likewise failed on
the first constant Array key containing an error, before later nested/multiple
candidate cases. EC9-EC12 observed the required key-body error, but their first
direct observation found a selected-payload gate instead of zero demand. Later
type observers, Array-key failures and pure condition/branch markers were not
reached in those failed groups. No unexecuted branch is counted as passing.

The evidence root named above retains `baseline/receipt.json`, raw stdout and
stderr, per-command exits/durations/process groups and root MoonBit hashes.
Baseline test stdout SHA-256:
`7164e437921c649f9e29aecde6013eb19f85762707f2d2ef817a52ad6ab0258f`.
Stderr was empty. Both command groups exited, with no timeout or retry.

## Minimal correction and formatting identity

Only the private [extrema helper](../../extrema.mbt) changes product behavior.
It computes the initial key before requiring the selected item, compares that
key with itself using the unchanged comparator, then requires the selected
item. The existing subsequent candidate loop, cache policy, Array-only guard,
optional branch behavior, comparison operators and all other implementation
files are unchanged. The initial comparison is not inferred from the misprinted
greater-than sign rules; it produces the comparison child first. No non-Array
extension or exact native/key callback timeline is introduced.

Before the corrected directed run, interface generation exited 0 in 0.341 s
and formatting exited 0 in 0.041 s. Interfaces remained unchanged. The new
fixture acquired formatter-only layout and optional trailing commas. Its
original frozen bytes remain in `prepared-test.mbt`, SHA-256
`d3cffdb28eebfc86ddde2042b8bd55e703ad7dee5e7aab18831173f07288b390`.
The formatted tested fixture SHA-256 is
`437eee0449cee8057af030fbddd791ba4b952a5e853c9f82102c728a9a619e16`.
`formatting.patch` preserves the complete difference; exact string literals,
comments and all other tokens match after ignoring whitespace and optional
commas immediately before closing delimiters. No expected result, input, test
body logic or declaration changed. The initial stricter punctuation-only
preflight rejected those formatter commas before starting a semantic command;
its correction is recorded in `formatting-verification.json` and is not a test
failure or pass. The fourteen earlier demand groups remain byte-identical.

## Corrected directed verification and legacy migration

| Command | Actual result | Exit | Seconds |
| --- | --- | --- | --- |
| Native frozen deny-warn check, one worker | Passed | 0 | 0.725 |
| Same 13 extrema comparison groups | 13/13 | 0 | 9.758 |
| Previous extrema demand fixture | 14/14 | 0 | 3.183 |
| Original extrema_test.mbt | 1/2 | 2 | 0.234 |
| Migrated extrema_test.mbt | 2/2 | 0 | 6.747 |

All tests used native debug, frozen dependencies, deny-warn, one worker,
no-parallelize, closed stdin, RUST_LOG=error and a 600-second per-command cap.
All thirteen new groups completed their full bounded loops and observer paths.
The previous fourteen groups also completed. Raw `postrepair` and `migration`
receipts bind actual stdout/stderr, exits, duration and source/test hashes.
No test command timed out or ran concurrently with another heavy command.

The unchanged legacy run reports a JsonnetError in its first extrema group;
its second membership group passes. The raw output identifies the group, not a
per-iteration input, so no per-iteration diagnostic is invented here. The
statically identified old `std.minArray([{}])` success conflicts with the same
Object-key rejection directly tested by EC1/EC2. The fixed minArray definition
at lines 1732-1742 invokes foldl from index zero (823-829), whose first comparison
uses the Object key; __compare at 1693-1702 explicitly rejects that type.
No official source supplies a singleton exemption.

Exactly that existing input moves from expected `{}` to the legacy runtime
rejection list. All other expectations remain, including non-Array rejection
as a preserved legacy behavior rather than new normative acceptance. The
complete second membership block is byte-identical. The subsequent same-product
2/2 run supports this precise migration; the old group's unreached later
assertions receive coverage only from this completed migrated run.
No Go snapshot or other frozen regression was edited.

The original fixture remains in base 37facf2 and
`original-extrema_test.mbt` under the evidence root. Original legacy stdout
SHA-256 is `32fcdcaaad46aa7028384f62e6a0a0b503152b7a48e3acc66531a9547b29b154`;
migrated stdout SHA-256 is
`ddd0722f90fd133207ca9e423fc1faa05c3608f3be5c5eb4fdbea4259682b120`.
Both stderr files are empty. `legacy-migration.json` and its patch retain the
individual authority, input, old/new expectation and unchanged block check.

After the legacy edit, interface generation exited 0 in 0.239 s and formatting
exited 0 in 0.041 s. Neither changed verified product or either normative fixture;
the migrated legacy file was tested after formatting. No interface changed.
Every owned command group and wrapper exited before the parent testing slot was
returned. The corrected directed set has no remaining failure; original failures
remain preserved historical evidence.

## Delivery binding and remaining obligations

Verified bytes:

| File | SHA-256 |
| --- | --- |
| extrema.mbt | `65d1f63c91bf5336761df94f5f3359c3a26667b7dce9f6955f921043cbad1459` |
| extrema_test.mbt | `39699c2d91e740208035c14f3436bb5cb56a18ce261963e823fe773e0d1fc98b` |
| spec_extrema_comparison_test.mbt | `437eee0449cee8057af030fbddd791ba4b952a5e853c9f82102c728a9a619e16` |
| spec_extrema_demand_test.mbt | `f3cc7628a5726e919328565b11436712e03eee749bf8568cc2d9a9726e61817e` |

The public mapping extends only the existing minArray/maxArray records with
bounded EC evidence and retains all previous EX criteria. The other 62 manual
records remain identical, and the count stays 64 reviewed subsets, zero whole
function acceptances. No language-rule claim or completed-rule status changes:
stdlib dispatch, global comparator, language mapping and generated language
matrix are unchanged. Sort/binding dispatch is unchanged, so its previously
passed tests are not rerun or relabeled as current evidence in this batch.

Toolchain: moon 0.1.20260920 (914d7da), moonc v0.10.14+7d59c7ec9,
moonrun 0.1.20260920 (914d7da), with rr_moon_mod and rr_moon_pkg enabled.
The raw version output is retained under the evidence root. Offline public
inventory/documentation validation and final commit verification have separate
receipts; these add no semantic test passes. `delivery/commit-verification.json`
binds the local delivery commit to these verified bytes and base 37facf2.

No new full native debug/release suite, standalone integration, archive consumer,
Go/C++, Linux, container, remote or ASan verification ran. Earlier complete
672/672 runs remain evidence only for 21ee800, not this source. EXT-A0 admission,
EXT-C3 precise callback counts/cache policy, EXT-E2 independent errors/native
order, full comparator/Unicode/raw-encoding/resource domains and the greater-than
formal-rule conflict remain unresolved. Overall conformance is incomplete.
No upstream code, private proposal content, push or release is included.

The existing public inventory generator exited 0 in 1.801 seconds.
Its generated review changes are exactly minArray and maxArray; all 153
whole-contract statuses remain unaccepted. The language matrix did not need
regeneration because its inspected files and evidence are unchanged.
