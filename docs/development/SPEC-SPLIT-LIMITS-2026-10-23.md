# Public split contracts: frozen preparation

The preparation below is retained. The first unchanged-product execution
subsequently passed five groups and failed six. The scoped correction then
passed all eleven frozen groups and three neighboring checks. The frozen
fixture and the SPL-R0 exclusion are unchanged; the chronological preparation,
failure and correction records remain below.

Base 0e7cb7890f972c0e1f9a1ff628e87eee4a7f6dd1; the initial worktree was clean.
This lightweight stage prepares split, splitLimit and splitLimitR, none of
which has a reviewed manual record at the base. All eleven groups in
[spec_split_limits_test.mbt](../../spec_split_limits_test.mbt) are **NOTRUN**.
Product sources, old tests, Go fixtures and accepted coverage maps are
unchanged. The prior strip correction and its fifteen executed groups remain
bound to their own commit and evidence, not this new fixture.

## Fixed basis and independent expectations

Normative sources remain Google Jsonnet
bbb38f1020be1f5aed560928fb839b2c448cefb4. The
[public declarations](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#std-split)
(stdlib.html 671-769) give split the required str and c parameters, and add
required maxsplits for splitLimit and splitLimitR. No defaults or parameter-name
conflict occurs in this group. A delimiter may contain multiple characters.

The [fixed definitions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L114-L146)
provide the following independent criteria:

- All three validate str as a String, then c as a nonempty String. Limited
  variants next validate maxsplits as a Number. A failing earlier guard does
  not evaluate later argument expressions. Rejected Array/Object/Function heads
  do not require their payloads.
- Ordinary splitting finds nonoverlapping delimiter occurrences in order and
  retains leading, trailing and adjacent empty pieces. Empty input yields one
  empty String, not an empty array. Missing delimiters yield the original
  String. Zero maximum yields the original String after argument validation.
- split and splitLimit scan from the left. Positive integral splitLimitR
  maxima use the reverse-String/reverse-result definition and split from the
  right, returning pieces in their original order. Data outside matched
  delimiters, including supplementary Unicode characters, combining marks and
  NUL, is preserved without normalization.
- A finite nonnegative integral maxsplits is a comparison bound on the count
  of pieces already emitted. There is no conversion to a signed 32-bit integer
  or allocation of maxsplits elements in the definition. The selected limits
  2^31, 2^53 and the finite Number represented by 1e308 therefore work on short
  inputs with at most two matches. The last Number is integral at its binary64
  magnitude; the expected result does not depend on its exact decimal spelling.
- The -1 sentinel is unlimited. Nonoverlapping-delimiter examples are included
  for both limited functions; the right/overlap discrepancy below is excluded
  from passing assertions explicitly.

The [language reference](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md)
supplies immutable values, strict String contents, lazy arguments and lazy
Array elements. Needed input/argument errors prevent even a result Array head
or length from being returned, while an unused entire call remains lazy.
Native success counters check skipped or shared arguments independently of
error categories. Runtime/Type/Assertion tags in the fixture check the current
embedding's native/source entry conventions, not official diagnostic wording.

## Explicit unresolved cases

SPL-R0 is a documentation/source conflict for unlimited right splitting with
overlapping delimiters. The documentation says splitLimitR splits right to
left, while its fixed -1 branch calls the left-scanning splitLimit directly.
For str = 'aaa', c = 'aa', maxsplits = -1, those give ['a', ''] and ['', 'a']
respectively. Current native code and the old example select the right result.
This stage preserves that old evidence and marks the conflict unresolved;
neither result is introduced as a normative success. Positive integral maxima
have no corresponding branch conflict and test both directional outcomes.

Fractional maxima and negative maxima other than -1 remain unadjudicated.
The source comparisons mechanically accept them, whereas the documentation
describes a split count and an output-length bound without defining such
domains explicitly. Existing native rejections are not converted into passing
normative claims or silently overwritten. The new large-positive-integer
cases require no decision about these domains. Raw host encoding, resource
exhaustion and malformed Unicode remain separate obligations.

## Frozen groups and static findings

Source expressions and typed ASTs are built independently using existing
neutral helpers. Expected results are literal JSON data; no Go/C++ or product
output has been used to derive them. Each evaluation retains the existing
20,000-step / depth-64 / stack-96 limits and short input Strings. Large limits
are not large allocations or stress-test inputs.

| Group | Independent obligation; all NOTRUN |
| --- | --- |
| SP1 | Ordered ordinary/multicharacter splitting, positive bounded direction, unambiguous -1 examples, zero and Int32-maximum controls, empty/no-match/adjacent pieces, Unicode/NUL/combining data, positional and reordered named parameters. |
| SP2/SP3 | Source and handmade AST splitLimit accept finite integral limits 2^31, 2^53 and 1e308, including empty/no-match inputs and positive-limit overlap cases. |
| SP4/SP5 | The same separate source/handmade checks for splitLimitR, preserving right-to-left selection for positive maxima. |
| SP6 | str kind failures precede successful c/maxsplits callbacks and do not demand rejected Array/Object/Function payloads. |
| SP7 | Wrong/empty c fails before the maxsplits callback, even for empty input and a zero-producing callback. |
| SP8 | Nonnumber maxsplits fails without demanding Array/Object/Function payloads. |
| SP9 | Required str/c/maxsplits and strict String-construction errors propagate through whole result, type, length and first selection; unused calls remain lazy. |
| SP10 | Required input, delimiter and maximum thunks execute once across result length, repeated reads, another call and original input reads; unused calls run no callbacks. |
| SP11 | Missing/extra/unknown/overlapping bindings fail before gates; unused calls retain laziness and free names remain Static. |

Static inspection identifies two implementation discrepancies:

1. Both limited native entries call the shared integer conversion before
   split_limit. That converter rejects Numbers outside signed Int32, so even
   splitLimit('', ',', 2147483648) cannot reach its short valid result.
2. Generic native argument forcing happens before text_value checks and before
   split_limit checks the empty separator. Invalid str or c therefore still
   executes later c/maxsplits callbacks. The public split entry is already
   source-defined and supplies a useful neighboring guard-control case.

These are source-level findings only. The first reserved run must execute the
unchanged implementation and preserve any failures. Loop-based groups may stop
at the first failure; do not infer execution of later arms. Separate SP2-SP5
tests provide independent source/AST wide-limit failure opportunities.

The narrow candidate correction affects native splitLimit/splitLimitR dispatch
and their private split_limit helper in stdlib.mbt/std_string.mbt. Preserve
binding validation, check str and c before demanding maximum, and compare
bounded actual piece counts to a Number maximum without Int32 narrowing.
Keep the global integer converter, public signatures, source layer, upstream
definitions, strip functions and unrelated string helpers unchanged. A scoped
fix must not change SPL-R0, infer a fractional/negative policy, or modify any
old expected value to hide a failure. The old Go out-of-range error fixture
remains separate comparison evidence even if the correction later disagrees.

## Reserved execution and remaining acceptance

The priority project retains the heavy-resource slot. Only read-only review,
fixture/document preparation and formatting ran in this stage. After parent
allocation, verify the freeze hashes and execute sequentially:

```sh
env RUST_LOG=error moon check . --target native --frozen --deny-warn -j 1
env RUST_LOG=error moon test spec_split_limits_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize
```

Do not adjust nice. Retain raw output, exit codes and timing, then return the
slot. Product corrections and any subsequent directed verification require
the next coordination step. A later correction's minimum neighbors are the
legacy std_string_test and arguments_test, with additional tests only if an
actual changed dependency warrants them. Source callers of splitLimit include
split; the shared helper is otherwise used only by the two limited entries.

This group supports delimiter-based configuration input parsing and the
[final acceptance contract](SPEC-CONFORMANCE.md). It does not establish full
String/function contracts, return-element/resource laziness, all Unicode or
binding combinations, competing errors, std rebinding, CLI/application or
platform/archive acceptance. SPL-R0 and fractional/other-negative maxima,
earlier name disputes, concatenation and raw-text encoding questions, HP0/DF0/
PE0, print conflicts and shift exclusions remain open. No comparison agreement
or old passing count reduces those obligations.

The 57 manual records, 54 functions with reviewed dimensions, zero fully
accepted functions and incomplete overall status remain unchanged. Neither
official coverage map nor generated inventory has been advanced for these
pending cases. Snapshots, pending mappings, reference hashes and the final
preparation freeze are in `/tmp/moonjsonnet-split-limits.ruoza0b2`. These are
local evidence, not an archival guarantee. No private proposal material,
upstream edit, new dependency, push or release is included.

## First unchanged-product execution and static correction

After the parent allocated a short slot, every frozen fixture/report/map hash
and original product hash matched the base. The planned check exited 0 in
0.523 seconds, and the first semantic run exited 2 in 10.521 seconds: eleven
groups, five passed, six failed. Both used one worker; the test disabled
parallel execution. No priority change was attempted. Timings use a monotonic
clock around each subprocess, including startup and any compilation.

SP1, SP8, SP9, SP10 and SP11 passed through their complete loops. SP2-SP5 each
failed at their first empty-input / 2^31 case, separately demonstrating the
narrowing failure for both functions through source and handmade AST. Their
later inputs and wider limits were not reached. SP6/SP7 completed the split
source-wrapper controls and then failed at the first splitLimit/source invalid
head: a successful later-argument callback had executed. The remaining native
AST/function/empty-separator arms were not reached and are not credited.
No syntax/type repair or frozen expectation change was needed.

Both heavy subprocesses exited and the slot was returned before any correction.
The original stdout/stderr, exact commands, timing, exits, hashes and loop
cutoffs are preserved under baseline-* in the evidence directory. SPL-R0 was
not tested as an accepted outcome; no comparison interpreter ran.

The parent-authorized static correction changes only stdlib.mbt and
std_string.mbt. Limited split dispatch now validates str, then c, and passes
the still-lazy maxsplits thunk to the private helper. That helper rejects an
empty separator before demanding maximum. It retains the maximum as a Double
and compares actual piece counts as Doubles, removing the erroneous positive
Int32 upper bound without allocating in proportion to that bound.

Existing fractional/negative rejection policies and diagnostics are retained,
including the legacy lower-bound check for negative values. This preservation
is not a normative endorsement of those unresolved domains. The -1 handling
and reverse scan are unchanged, so SPL-R0 remains open. Global integer(),
source split, upstream definitions, strip functions, public signatures,
ordinary String scanning and legacy tests are unchanged. Existing force/tick
calls continue to enforce thunk sharing and evaluation budgets.

No post-correction check, semantic test, interface generation or inventory
regeneration has run. The minimum next slot is one check and the frozen
spec_split_limits_test, followed by std_string_test and arguments_test to cover
the old bounded/fractional/negative/unlimited examples and binding dispatch.
Use the same single-worker flags and no priority changes. The complete frozen
fixture must pass before any skipped branch or new reviewed dimension is
claimed. Source and report snapshots plus a repair-ready receipt preserve the
untested patch for parent coordination; no new commit is made at this stage.

## Successful directed verification

The parent allocated the next short slot after the static correction. All
repair-ready hashes, the frozen eleven-group fixture and original failure logs
matched before execution. Global integer() remained byte-identical to the base.
The following four commands ran sequentially without priority changes or
sandbox escalation; all exited 0:

```sh
env RUST_LOG=error moon check . --target native --frozen --deny-warn -j 1
env RUST_LOG=error moon test spec_split_limits_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize
env RUST_LOG=error moon test std_string_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize
env RUST_LOG=error moon test arguments_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize
```

| Command | Monotonic wall time | Observed result |
| --- | ---: | --- |
| Native check | 0.571 seconds | No warnings/errors |
| Frozen split fixture | 14.420 seconds | 11 passed, 0 failed |
| Legacy String tests | 0.284 seconds | 2 passed, 0 failed |
| Argument binding test | 0.126 seconds | 1 passed, 0 failed |

This is Darwin arm64 native debug with Moon 0.1.20260920 (914d7da) and moonc
v0.10.14+7d59c7ec9. Timing includes command startup and any compilation, not
isolated evaluator performance. All four child processes exited; the slot was
returned and reported before metadata/documentation work. No complete suite,
Linux, release or Go/C++ comparison ran. No old full-suite count is a result
for this correction.

The tested fixture SHA-256 remains
`c4df06a99535f812bff99a9a4c4ab44147e733543a60d7d7f9cc3c318a59d7a7`.
All previously cut-off inputs and source/handmade paths in this fixture now
executed. No expectation, diagnostic-category assertion or generated tree was
changed between the six-failure baseline and the eleven-group pass. Successful
native counters independently establish that failed guards skip later
arguments, rather than merely returning the same error category.

The two legacy String groups still include fractional/negative refusals and
the historical unlimited-right overlap result. Their passing compatibility
assertions do not adjudicate those domains or earn normative coverage. SPL-R0
and the other exclusions remain open; the independent fixture omits disputed
outcomes. No legacy expected value or frozen Go fixture was changed.

Only after execution were the three pending public records reconciled. Their
N/E/L/B expectations and test anchors are unchanged; status now identifies
executed evidence. All 57 prior manual records are preserved, yielding 60
records and 57 functions with reviewed dimensions among 153 candidates. Zero
whole functions are accepted and behavioral_conformance_proven stays false.
SP labels are local report groups, not new canonical language IDs. The current
compatibility rows describe the corrected wide-limit and guard behavior while
retaining the explicit unresolved domains.

## Metadata review and delivery boundary

The sixteen existing stdlib.mbt inspections in six language rules were
re-reviewed: type-object, length-string, length-array, length-object,
object-has-ex and object-fields-ex. A byte-level audit proves the complete
stdlib diff is exactly the two-name early split dispatch plus deletion of its
old eager arm. Every other implementation byte and inspected anchor is
unchanged; none of those six intrinsics can enter the new branch. The sixteen
whole-file fingerprints and six dispatch explanations were updated accordingly,
without changing any language rule's scope, status or execution evidence.
The original mapping and explicit reinspection receipt remain preserved.

Interface, formatting, inventory, documentation and final staged/commit checks
have separate command receipts in the same evidence directory. These metadata
checks are not extra semantic runs. The tested source hashes in
repair-success.json and the final committed-byte receipt identify what was
verified; this report does not embed its own future commit hash. Final full
language/library, cross-platform, CLI/application and archive acceptance still
require their remaining independent evidence. No private proposal, upstream
edit, dependency upgrade, push or release is part of this delivery.

Interface generation and formatting exited 0 in 0.273 and 0.018 seconds.
Generated .mbti files are unchanged, and formatting left the verified product
and fixture bytes identical to repair-ready.json. Both existing inventory
generators exited 0. The public inventory changes only the three split rows;
all 153 whole-contract statuses remain unaccepted. The language matrix retains
28 completed named rules, one constructor transfer relative to children,
63 partial rows, two unreviewed rows and 195 canonical evidence IDs. Its
Markdown and all previous execution evidence/statuses remain unchanged;
JSON changes reflect only the inspected-file metadata and explanations above.
Documentation and final index/worktree/commit receipts are recorded separately
after the final report text is staged, without rerunning passed semantic tests.
