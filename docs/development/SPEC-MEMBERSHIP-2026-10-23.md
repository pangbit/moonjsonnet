# Independent member and contains contracts

## Frozen scope before execution

Base: `06a260ccf2c6d24190f394f9629490678d3c05c7`, with unchanged product bytes
from `21ee8005fbca4779adb2e01d53000c65f325eb33`. This preparation selects
`member(arr, x)` and `contains(arr, elem)`: both currently have no reviewed
subset in the public inventory. It adds the independent
[membership fixture](../../spec_membership_test.mbt), not a new acceptance claim.
No implementation, earlier fixture, comparison snapshot or coverage map changes.

The [previous full native regression](SPEC-NATIVE-REGRESSION-2026-10-23.md)
establishes 672/672 debug and release only for its recorded inputs. These new
fourteen groups have not been typechecked or executed. Formatting passed; no
native compilation, semantic test, reference interpreter or remote command has
run during this preparation. No general technical approval is needed; the next
execution waits for the parent-coordinated testing slot.

## Fixed independent basis

The authority remains Google Jsonnet v0.21.0 commit
`bbb38f1020be1f5aed560928fb839b2c448cefb4`:

- [Public member signature and Array/String domain](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#L1989): arr and x are required.
- [Public contains signature](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#L2784): arr and elem are required.
- [member and count definitions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L247): the Array branch counts all matching entries; the String branch tests whether findSubstr produces any index; other collection types fail before needing the target.
- [findSubstr definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1642): its String checks precede the empty-pattern/empty-input/oversized-pattern empty result. An empty String pattern therefore makes member false, including for an empty input String.
- [contains definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1764) and [any definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1676): an Array comprehension supplies lazy equality elements; any stops after its first true element. An empty collection produces false without demanding the target.

The existing fixed local copies were verified before deriving expectations:

| Reference | SHA-256 |
| --- | --- |
| stdlib.html | `0eb80c0ccaf781c4c2c1bc06a22d2d6e57f9866f41c0b62431b5ca4f510e6853` |
| upstream-std.jsonnet | `e76dd6b8e51a2ca041b292dadea9c5521aeea5781b0ffe7c2c683865e7e45351` |

Reference files stay under `/tmp/moonjsonnet-spec-audit.1KasPx`, outside the
repository. The fixture uses literal outcomes and successful observation gates,
with independently constructed source and AST inputs. It does not evaluate a
copied reference implementation to manufacture expectations. Go/C++ agreement,
including agreement on an invalid result, cannot establish a normative pass.

## Four static implementation gaps

In [stdlib.mbt](../../stdlib.mbt), the generic `params.map` forces both argument
heads before the shared member/contains arm validates the collection. The arm
then uses the same early-exit Array loop for both functions, while String member
uses the host String contains operation. That differs from the fixed definitions:

1. Both empty Array calls must return false without demanding their target.
   Current eager argument collection instead demands it, including an error.
2. An invalid collection must fail without running a successful target gate or
   nested payload. Current argument collection runs the target gate first.
3. Array member must inspect every equality predicate, including errors after
   an earlier match. Current code breaks at the first match. Contains must retain
   its distinct short circuit; changing both to a full traversal would be wrong.
4. String member with an empty pattern must return false through the fixed
   findSubstr rule. Host String containment currently treats that pattern as
   present. Nonempty Unicode patterns still need positive controls.

These are source-level findings, not observed test failures yet. The target
String's malformed raw encoding and unresolved cross-source disputes are not
adjudicated here. The documented parameter names agree with these two source
definitions; no alias, renamed parameter or signature exception is introduced.

## Frozen regression groups

Each group maps to one top-level test declaration in the new fixture, in order.
Except where a path is explicitly named, each assertion exercises both parsed
source and an independently built public Program AST.

| ID | Independent expectation | Boundary / discriminator |
| --- | --- | --- |
| MC1 | Array presence is Boolean equality membership; positional and reordered named calls agree | Empty, repeated, absent, mixed-type, nested Array and visible-object cases; hidden fields and unused function bodies stay lazy |
| MC2 | Nonempty String patterns match literal code-point sequences | Supplementary Unicode, NUL, composed/decomposed distinctions, overlap and suffix/length boundaries |
| MC3 | Empty String patterns return false | Empty, ASCII, supplementary, NUL and combining inputs |
| MC4 | Source member of an empty Array does not demand x | Error, every head kind, deferred payloads; successful target gate remains uncalled |
| MC5 | Handmade member retains MC4 | Separate declaration so a source failure cannot conceal the AST path |
| MC6 | Source contains of an empty Array does not demand elem | Same literal/error/gate controls, independent of member |
| MC7 | Handmade contains retains MC6 | Separate declaration |
| MC8 | Member visits all three entries after an initial match | First/middle/last gates each run once; collection/target and repeated result reads share values |
| MC9 | Source member propagates an error after an earlier match | Direct result and type observation fail with the exact explicit error marker; unused call succeeds |
| MC10 | Handmade member retains MC9 | Separate declaration |
| MC11 | Contains stops after its first match | The tail has both a successful gate and an error; neither may run; required inputs/results remain shared |
| MC12 | Invalid collections reject before target/payload gates | Null/Boolean/Number/Object/Function for both functions, plus String for contains |
| MC13 | Isolated required collection, target and pre-match entry errors propagate | Direct and type observers; String member still validates a required target on empty input |
| MC14 | Binding errors precede argument demand; unused free names remain Static | Missing/extra/unknown/duplicate bindings; source and handmade AST; required names without defaults |

The gates record demand counts, not an invented total order among otherwise
valid operands. Explicit Jsonnet errors require their exact Runtime marker.
Other invalid-head/binding tests require a runtime-domain error, distinguishing
it from Syntax, Static, Limit and Unsupported, without inventing a normative
host diagnostic spelling or subcategory. A failed group's later loop arms are
unexecuted until a later successful run; they must not be credited individually.
All executions use the existing bounded fixture limits: steps 20000, depth 64,
stack 96. No resource-equivalence or complete Unicode-domain proof is claimed.

## Preserved old expectations and affected scope

[extrema_test.mbt](../../extrema_test.mbt) contains older expectations that
conflict with the independently fixed criteria: empty String member succeeds,
Array member short circuits after a hit, and both empty Array calls demand an
error target. Those bytes remain unchanged, SHA-256
`1096e365b4990978b897f833cd3193d7b12410bf4415309e9a71b5dd8cd9a9d0`.
An additional unchanged copy is preserved with this preparation. These are
historical comparison expectations, not a reason to alter the new oracle.
Any later reconciliation must explicitly retain the original inputs/results;
a successful old corpus is not substituted for the independent baseline.

A future correction can be confined to the member/contains dispatch and its
private traversal/demand logic. Shared equality, global argument forcing,
standard-library source definitions, public names and existing strip/split
implementations need not change. The neighboring affected checks are the new
fixture, `extrema_test.mbt` (including its recorded conflicts),
`arguments_test.mbt`, and the unchanged `spec_strip_chars_test.mbt` guard against
accidentally altering the already-correct adjacent demand behavior. Those are
candidate follow-up checks, not authorization to start another run now.

## Minimum unchanged-product baseline

After a slot is allocated, first verify base and frozen bytes, then run these
two commands sequentially with stdin closed and a 600-second cap per command:

```sh
RUST_LOG=error moon check . --target native --frozen --deny-warn -j 1 </dev/null
RUST_LOG=error moon test spec_membership_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize </dev/null
```

Keep stdout/stderr, exit codes, monotonic elapsed times, actual group results
and first-failure cutoffs. Syntax/type failures are not semantic failures; any
necessary test-only correction must preserve the frozen meaning and old bytes.
Do not update snapshots, edit implementation first, omit failed groups, change
priority, install dependencies or run full suites, Go/C++, Linux or integration
scripts. Confirm owned processes exited before returning the slot. There is no
currently executed membership result to add to the public inventory.

Preparation evidence is under `/tmp/moonjsonnet-membership.7r_owseb`, containing
the 667-file base manifest, unchanged legacy fixture, formatted new test and
freeze receipt. New test SHA-256:
`ff98fa18f761be4560885c2d02c55bf926ab5532c14f56b049d825ec692ae39e`.
Temporary evidence is not an archival guarantee. No private proposal material,
upstream modification, remote action, push or release is included.

<!-- Independent expectations above are frozen before baseline execution. -->

## Unchanged-product baseline

After the parent allocated a slot, the base commit, all 667 existing tracked
files, new fixture, frozen report and unchanged legacy fixture matched their
recorded hashes. The exact two planned commands ran sequentially with stdin
closed, one worker and no priority adjustment. Check exited 0 in 0.570 seconds;
the semantic command exited 2 in 7.630 seconds: **14 groups, 5 passed, 9 failed**.
Neither timed out. No test syntax/type correction or oracle change was needed.
All owned process groups and the wrapper exited before the slot was returned.

| Groups | Actual baseline and first-failure cutoff |
| --- | --- |
| MC1, MC2, MC11, MC13, MC14 | Passed their complete loops, including source and handmade AST paths |
| MC3 | Source member with empty input and empty pattern returned true instead of false. Its handmade path and later input Strings were not reached |
| MC4, MC5, MC6, MC7 | Each separately raised on its first empty-Array/error-target direct observation. Later target kinds, type observation and successful gate controls were not reached |
| MC8 | Source value observations succeeded, but the count map contained only array, needle and first. Middle and last were absent; the handmade path was not reached |
| MC9, MC10 | Each separately returned success for the first direct observation despite the required tail error. The later type observation was not reached |
| MC12 | Source member rejected null but failed the zero-gate assertion. Its other collection kinds, handmade path and contains arms were not reached |

The failed MC12 prefix directly establishes member's guard-demand defect;
contains' corresponding invalid-collection branches remain unexecuted in this
baseline, although the common eager implementation was inspected. The four
independently declared empty-Array failures establish eager target demand for
both public functions and both entry paths. A group's later assertions do not
earn passing coverage merely because the harness continued with other groups.

Raw evidence is under
`/tmp/moonjsonnet-membership.7r_owseb/baseline-20261023T133922.127697Z`:
`check.stdout.log`, `check.stderr.log`, `test.stdout.log`, `test.stderr.log`,
their separate command receipts and `baseline.json`. The semantic stdout
SHA-256 is
`200981a00c4bf23f3fd67b875430f4f3b2bdf70d45eeec4b08d12465b592873c`;
its stderr is empty. The original freeze receipt, report prefix, test and
667-file input manifest remain separate and unchanged.

## Static correction awaiting another execution slot

Only after the failed baseline exited, the parent-authorized correction added
a private [membership helper](../../std_membership.mbt) and an early two-name
dispatch in [stdlib.mbt](../../stdlib.mbt), replacing its old shared eager arm.
The collection head is validated before the target; an empty Array returns
false without forcing that target. Nonempty Arrays retain the existing single
target force, shared equality and per-entry budget tick. Member visits every
entry after a match, while contains keeps its early exit. String member still
validates its String target, then treats an empty pattern as absent.

The entire remaining stdlib.mbt byte sequence, including strip/split dispatch,
global argument handling and equality dispatch, is unchanged. std_string.mbt,
the frozen fourteen groups, extrema_test.mbt, both earlier strip/split fixtures,
source library definitions, interfaces and public signatures are unchanged.
Formatting and static diff/hash checks completed; **no post-correction check or
semantic test has run**. No corrected result, new coverage or commit is claimed.

The next minimum slot starts with the same check and complete frozen membership
fixture. Candidate neighboring tests are arguments_test.mbt and the unchanged
spec_strip_chars_test.mbt. extrema_test.mbt should retain and expose its known
legacy conflicts rather than be silently edited to pass; any reconciliation
needs explicit evidence preserving the original fixture and raw outcome.
No full suite or reference/remote run is requested. The testing slot remains
returned while the source patch waits for directed verification.

## Directed verification and legacy assertion migration

The parent allocated a subsequent short slot. Repair-ready hashes and all
frozen criteria matched before execution. Five commands ran sequentially with
the original extrema fixture intact:

| Command scope | Actual result | Exit | Elapsed seconds |
| --- | --- | --- | --- |
| Native frozen check, one worker | No warnings/errors | 0 | 0.540 |
| spec_membership_test.mbt | 14/14 | 0 | 10.837 |
| arguments_test.mbt | 1/1 | 0 | 0.134 |
| spec_strip_chars_test.mbt | 12/12 | 0 | 5.160 |
| Unchanged extrema_test.mbt | 1/2 | 2 | 0.203 |

Tests used `--target native --debug --frozen --deny-warn -j 1 --no-parallelize`,
with `RUST_LOG=error`, closed stdin and a 600-second cap per command. No command
timed out. All fourteen membership groups completed their full source/handmade
paths, including the branches not reached during the first baseline. The
extrema failure was the first array-result assertion: the empty String pattern
returned false, while the old assertion required true. Its later loop cases
were not reached and are not presented as separately observed failures.

The unchanged five-command record is
`/tmp/moonjsonnet-membership.7r_owseb/postrepair-20261023T134526.587011Z/postrepair.json`.
Each command has separate stdout/stderr and receipt files beside it. Original
extrema stdout SHA-256:
`ad2a369cdadd6625d9f36c712acff94813c98fe8785ff9daf59b1305367ef836`.
All semantic-command stderr files are empty. The product and frozen fixture
hashes remained unchanged throughout those commands.

The parent's conditional authorization permitted precise migration of project
tests when their old assertions conflicted with fixed normative definitions.
The following four decisions were derived before editing that fixture:

| ID | Original input / expectation | Fixed basis and corrected assertion |
| --- | --- | --- |
| ME1 | The first result array includes member('', '') and expected true in its last position | member's String branch uses findSubstr; its empty-pattern branch returns no indices. Only that result-array position becomes false; MC3 independently passes |
| ME2 | The original mixed array calls member([1, error 'unused'], 1) and contains on the same shape, expecting [true, true] | member/count must visit the error tail, while contains/any short circuits. The original mixed source is retained verbatim and must raise Runtime with message unused; a separate contains success control retains its shortcut. MC8-MC11 independently pass |
| ME3 | member([], error 'forced') was listed among required errors | count over an empty Array calls no equality predicate and leaves x lazy, so the unchanged input now expects false. MC4/MC5 independently pass |
| ME4 | contains([], error 'forced') was listed among required errors | The empty comprehension gives any no equality element and leaves elem lazy, so the unchanged input now expects false. MC6/MC7 independently pass |

The exact fixed source locations are the member/count, findSubstr, any and
contains definitions linked above. No Go comparison result, automatic snapshot
update or newly invented exception supports these changes. The unrelated
extrema test, all other membership values/errors, original combined input,
global comparison implementation and frozen fourteen-group fixture remain
unchanged. The old test name was corrected to distinguish the two traversals.

The original fixture remains recoverable from base commit
`06a260ccf2c6d24190f394f9629490678d3c05c7` and the local unchanged copy already
identified above. The structured per-assertion record is
`/tmp/moonjsonnet-membership.7r_owseb/legacy-migration.json`. The migrated fixture
SHA-256 is `c630608264e95be353b127644dcc11e0cc52a6ceea2f355bc1afe39b3458d2ae`.

Only the edited extrema file was rerun, with the same test flags: **2/2, exit 0,
6.684 seconds**. Its raw stdout/stderr and receipt are under
`/tmp/moonjsonnet-membership.7r_owseb/migrated-extrema-20261023T134803.666898Z`.
The stdout SHA-256 is
`ddd0722f90fd133207ca9e423fc1faa05c3608f3be5c5eb4fdbea4259682b120`;
stderr is empty. This final verification did not change the product or frozen
membership criteria. All command process groups and wrappers exited, and the
slot was returned before documentation and metadata work.

## Delivery scope and remaining evidence

The corrected private helper SHA-256 is
`680ffdeaf633166f7af73d21d8a8d5ed0c38ab9b36ec83b8757eae721b18d9b9`;
stdlib.mbt is
`2f3e781683aaa059c995f1439250d9a6c3ce010b6492b600a067fb2572fa2676`.
The original fourteen-group fixture retains its frozen hash. Public coverage
adds only member and contains, with bounded N/E/L/B and signature evidence.
All sixty existing manual records are preserved. The earlier prose count of
57 was stale after the split batch: its committed map already contained 60
distinct functions; this batch brings the map to 62, not five newly reviewed
functions. All 153 whole-contract candidates remain unaccepted.

Six existing language rules reference sixteen whole-file fingerprints of
stdlib.mbt. Exact byte comparison proves that the only edits are the two-name
membership early dispatch and removal of its old arm; all other implementation
bytes and inspected anchors are unchanged. The length/type/object-reflection
intrinsics cannot enter the new branch. Their fingerprints and six dispatch
explanations are refreshed without changing rule statuses, assertion evidence
or earlier execution results. The original mapping and reinspection receipt
are retained separately under the local evidence root.

Interface, formatting, inventory, documentation and final commit/input checks
have separate metadata receipts. These do not add semantic passes. No new
complete native debug/release, standalone integration, archive-consumer,
Go/C++, Linux, container, remote or ASan run was performed. The earlier 672/672
debug/release runs bind only the old source at 21ee800; they are not results
for this membership change. The initial nine failures and unchanged-extrema
failure remain historical raw failures; the executed corrected directed set
has no remaining failure. Overall specification conformance is still incomplete.

Interface generation exited 0 in 0.320 seconds and formatting exited 0 in
0.047 seconds, preserving the verified product/fixture bytes and all generated
interfaces. Both existing inventory tools exited 0 against the pinned local
references. The public map changes only the two newly reviewed rows; the
language matrix retains 28 completed named rules, one constructor transfer
relative to children, 63 partial rows, two unreviewed rows and 195 canonical
evidence IDs. Its Markdown is unchanged. The mapping retains its original
layout, with only the reviewed fingerprints and explanations updated.
