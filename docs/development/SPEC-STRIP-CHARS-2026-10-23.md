# Public character stripping contracts: frozen preparation

The preparation criteria below are retained. The appended first-execution
record supersedes their NOTRUN status: unchanged product passed five groups
and failed seven. The subsequent scoped correction passed all twelve groups
and three neighboring checks. The independent fixture remains byte-identical;
the chronological preparation, failures and correction records are retained.

Base 8f91f79c66524b124812efe498235b574d3089e3; the initial worktree was clean.
This is a lightweight preparation record. All twelve groups in
[spec_strip_chars_test.mbt](../../spec_strip_chars_test.mbt) are **NOTRUN**.
The implementation, legacy tests, comparison fixtures and accepted coverage
maps are unchanged. No compiler, native test, full suite, Linux, container,
remote comparison or release command has run in this preparation stage.

## Fixed basis and independent expectations

The fixed official commit remains bbb38f1020be1f5aed560928fb839b2c448cefb4.
The [public declarations and examples](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#std-stripChars)
(stdlib.html 566-661) and
[source definitions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L59-L73)
agree on two required parameters, str and chars, for lstripChars, rstripChars
and stripChars. There is no default or conflicting parameter name in this
group. None of these three names has a reviewed manual coverage record at
the base. Their existing examples are comparison-oriented evidence.

The String domain removes successive leading, trailing or both-side members
of a character set. The set is not a substring pattern; its ordering and
duplicate characters do not matter. Interior characters remain unchanged.
The fixed [language reference](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md)
requires immutable values, Unicode codepoint Strings, strict String values,
lazy function arguments and lazy Array elements. The literal expected data
therefore distinguishes supplementary characters, NUL, combining marks and
composed characters, with no normalization or extra whitespace policy.

Both one-sided source definitions test String length before membership. An
empty String returns unchanged without evaluating chars, including when chars
is an error expression or a value outside the membership domain. stripChars
first applies rstripChars, then lstripChars, so the empty case also avoids
chars. An invalid primitive str (null, Boolean or Number) fails its length
operation before chars is demanded. A nonempty String needs chars even when
no character will be removed. Required errors must prevent a String result,
including when its type, length or early character is inspected.

Array-valued chars is a source-defined domain beyond the String-set examples,
not an inference from Go. The fixed
[member and count definitions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L247-L254)
use count(filter(...)) for Array membership. Determining that count requires
the equality predicate for every member, even after an earlier match. Thus
str = 'a' and chars = ['a', error 'required'] must fail. A later successful
String-producing callback must also run. The fixture checks String members
only in this branch, avoiding unresolved Function equality questions. Empty
input still avoids the entire character array, and needed element thunks
remain shared across repeated membership scans.

These obligations are derived from fixed definitions before any execution.
Neither equality with Go/C++ output nor a matching error category constitutes
the independent oracle. Runtime/Static tags and callback counts in the tests
also check this embedding's interface; exact official diagnostic text is not
an acceptance criterion.

## Frozen executable groups

All groups use separately assembled source and typed AST expressions, neutral
existing builders, literal expected JSON and the existing per-evaluation
20,000-step / depth-64 / stack-96 limits. A failed first loop iteration will
not prove execution of its remaining paths; retain raw results and rerun the
unchanged fixture after a correction before claiming the complete subset.

| Group | Independent obligation; status NOTRUN |
| --- | --- |
| SC1 | Directional String sets, unordered/duplicate members, interior preservation, empty/all/no-match inputs, Unicode/NUL/combining/whitespace boundaries; positional and reordered named calls. |
| SC2 | lstripChars with empty String ignores an error chars expression and unused wrong-kind/payload values, for value/type/length. |
| SC3 | The same empty-String requirement for rstripChars. |
| SC4 | The same empty-String requirement for stripChars. |
| SC5 | A successful chars callback remains uncalled for empty input; input is shared once across result length and repeated reads; unused whole calls run no callbacks. |
| SC6 | Isolated str/needed-chars/strict-String construction errors propagate through whole result, type, length and early selection; unused calls remain lazy. |
| SC7 | Invalid needed chars heads fail without reading Object fields or Function defaults/bodies. |
| SC8 | Invalid primitive str heads fail before a successful chars callback, rather than merely matching an error category. |
| SC9 | Original Strings, aliases and sets remain unchanged under input-first/result-first observations; required input and chars expressions execute once across repeated result reads and another call. |
| SC10 | Missing/extra/unknown/overlapping bindings fail before gates; unused invalid calls remain lazy; unused free operands are still Static errors. |
| SC11 | Source-defined Array sets yield literal results; all String members, including those following a match, execute once and remain shared across scans. |
| SC12 | A later character-array error propagates despite an earlier match, including type and length observations. |

## Static implementation findings and correction boundary

Three concrete witnesses differ from the fixed obligations by inspection:

- std.lstripChars('', error 'unused') must return ''.
- std.rstripChars(null, successful_chars_callback()) must fail with zero
  chars-callback executions.
- std.stripChars('a', ['a', error 'required']) must fail.

In [stdlib.mbt](../../stdlib.mbt), bind_arguments validates the call, then the
generic params.map forces both argument heads before the stripping dispatch.
In [std_string.mbt](../../std_string.mbt), strip_characters receives an already
forced chars Value, and Array membership returns true at the first match.
These paths explain the missing non-demand and required-demand behavior.
They are static findings, not observed test failures yet.

The candidate correction is narrowly scoped: route these three functions
before generic eager forcing, retain the chars thunk until the first actual
membership check, and inspect every Array member needed by count semantics
while remembering whether a match occurred. Keep String scanning iterative,
retain argument binding, memoization, rejection and resource accounting, and
do not change embedded upstream source. The existing left-before-right native
scan and non-String str domains need separate review; this subset does not
declare them equivalent to the source's right-before-left composition.

The old [string test](../../std_string_test.mbt) explicitly expects an error
from stripChars('', error 'eager'). If first execution confirms the finding,
move that one legacy refusal to a nonempty input, retain its original bytes,
and rely on the independent empty regression for the corrected behavior.
The frozen Go fixture entries string-strip-eager-characters and
string-strip-array-characters, plus the
[historical string report](../archive/reports/GO-JSONNET-STRINGS.md), must remain
unchanged. They describe earlier Go-oriented behavior, including Array
membership short-circuiting. Update the current compatibility row only after
a verified correction. No old failure is reclassified as a normative pass.

## Reserved next execution and remaining acceptance

The parent coordinates the heavy-resource slot. After it allocates a slot,
verify the frozen file hashes and run these two commands sequentially on the
unchanged product, retaining exit codes, timing, stdout and stderr:

```sh
env RUST_LOG=error nice -n 10 moon check . --target native --frozen --deny-warn -j 1
env RUST_LOG=error nice -n 10 moon test spec_strip_chars_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize
```

Return the slot and report actual results. No semantic result, diagnostic
wording adjustment or implementation correction is presumed here. A subsequent
authorized fix requires rerunning the exact frozen obligations plus affected
string/binding/native-diagnostic regressions; final info, formatting, inventory
and documentation checks are also still pending. No full suite is implied.

This group supports configuration-string cleanup and the final public-stdlib
normal/error/lazy/boundary requirements in the
[acceptance contract](SPEC-CONFORMANCE.md). It does not complete the embedded
application, CLI failure, platform, archive or release obligations. Source/API
compatibility, String input length behavior for non-String structural values,
mixed Array equality, competing errors, direction-specific callback order,
Object assertions/inheritance, std/root rebinding, explicit tailstrict calls,
exhaustive binding/resource/encoding cases and whole-function acceptance remain
unproved. Existing parameter-name disputes, array-concatenation rules, text
encoding questions, HP0/DF0/PE0, print conflicts and shift limits retain their
earlier status.

The 54 manual records, 51 functions with reviewed dimensions, zero fully
accepted public functions and incomplete overall acceptance are unchanged.
Both generated inventories and both manual maps remain at their base bytes;
pending candidates are stored separately outside the repository. Historical
full-suite totals are not a result for these new files.

Original product/legacy/comparison snapshots, reference hashes, formatting
receipts, pending case mappings and the final preparation freeze are in
`/tmp/moonjsonnet-strip-chars.ebcypwrh`. Temporary evidence is local, not an
archival delivery guarantee. The private proposal was consulted for requirements
only; no proposal content or personal information is copied into these files.

## First unchanged-product execution

The parent allocated one short native-debug slot after preparation. Frozen
product, fixture, report and pending-map hashes matched before execution.
The two planned commands ran sequentially on Darwin arm64, Moon
0.1.20260920 (914d7da), moonc v0.10.14+7d59c7ec9. Both used one build worker;
the test command disabled parallel execution. The first check exited 0 in
0.603 seconds; the first semantic run exited 2 in 9.791 seconds, with
12 groups total, 5 passed and 7 failed. Timing uses a monotonic wall clock
around each subprocess, including compilation and test startup where applicable.

The sandbox rejected the check command's attempt to lower priority:
`nice: setpriority: Operation not permitted`. The command nevertheless ran
and exited 0; its effective nice value was not measured. The subsequent test
used an approved sandbox escalation for the same planned nice-10 command;
it completed without that warning. This is a recorded execution limitation,
not a hidden successful priority-setting claim. No command was rerun for it.

| Group | First observed result |
| --- | --- |
| SC1, SC6, SC7, SC9, SC10 | Passed, including all source/handmade AST paths in these groups. |
| SC2, SC3, SC4 | Failed on the first source expression for each function: empty String incorrectly demanded the error chars argument. |
| SC5 | Failed: observed input = 1 and chars = 1; independently expected only input = 1 for empty String. |
| SC8 | Failed: observed input = 1 and chars = 1; independently expected only input = 1 when primitive str cannot have a length. |
| SC11 | Failed: chars = 1 and first = 1, but the required later member callback was absent. |
| SC12 | Failed: an earlier matching member suppressed the required later error. |

SC5, SC8, SC11 and SC12 stopped on their first lstripChars/source failure.
Their remaining function/AST arms, and the subsequent arms of SC2-SC4, are
not claimed to have executed. Static review implicates the shared helper in
all three functions, but broader runtime proof requires the next directed run.
The successful callbacks in SC5/SC8/SC11 distinguish demand errors from merely
returning a matching error category. No fixture syntax/type correction was
needed, and no semantic expectation was changed to match product output.

The unchanged tested fixture SHA-256 is
`8b0571d5cfac33281dd2053b081f64ff4a76af9c4bb2aa14514be14c2884807b`.
All protected baseline hashes and the pending map still matched after the run.
The original preparation snapshot remains intact under frozen/ in the evidence
directory; baseline-check and baseline-test files retain intents, completed
receipts, exit codes, timing and raw stdout/stderr. baseline-summary.json
records group results, hashes, toolchain and the priority-setting limitation.

Both owned heavy subprocesses have exited. The slot was returned immediately
after results; no further build, test, full suite, Linux or comparison command
started. Product correction, legacy expectation migration and a subsequent
directed run await parent coordination. No new commit, coverage promotion or
whole-function acceptance is recorded by this failed baseline.

## Static correction prepared after the failed baseline

After the parent returned the slot to the priority project, it authorized a
scoped static correction. An executor transport interruption prevented one
read-only command from starting; no write or new heavy command had started
then. Once the same project environment and writable root were restored, a
minimal pwd/HEAD check confirmed 8f91f79, and hashes verified the original
product, frozen fixture and all first-run logs before editing.

The correction changes only the three strip entry points and their shared
private helper:

- builtin dispatch passes str's forced value and the still-lazy chars thunk
  before the generic eager argument path. Binding validation remains before
  this dispatch.
- strip_characters retains its existing String guard, returns an empty String
  immediately, and forces chars once only for nonempty input. Invalid primitive
  str therefore rejects without running a chars callback.
- Array membership records matches while visiting every element. Existing
  force/equal calls retain thunk sharing, depth checks and step accounting;
  a prior match no longer suppresses a later value or error.

The legacy std_string_test error case changes only its str input from empty
to 'a', as planned before baseline execution. The original empty-input bytes
are preserved under baseline/ and covered by the unchanged independent
SC2-SC5 assertions. No frozen value, domain, binding or demand expectation
changes. Original Go fixtures, source definitions, manual coverage maps,
generated inventories and shared force/equality implementations are unchanged.

Only lstripChars, rstripChars and stripChars call this helper. Adjacent parseInt,
trim, equalsIgnoreCase and splitLimit helpers remain unchanged, as do the
general member/contains/count implementations. The native scan direction is
also unchanged; competing-error and direction-specific callback cases remain
outside this subset. No whole-function conformance is inferred from the patch.

The static diff/byte audits exited 0. No post-correction compilation,
formatting, interface generation or semantic test has run. Existing .mbti files
are unchanged; regenerated-interface confirmation is still pending. The
already failed groups retain their observed status, including all first-failure
loop cutoffs. A successful result is not presumed for previously unexecuted
source/handmade arms.

When the parent releases another slot, the minimum directed set is the frozen
spec_strip_chars_test, legacy std_string_test and arguments_test. These exercise
all strip obligations, the migrated error case and neighboring String behavior,
plus shared binding behavior. Run one check followed by those files sequentially:

```sh
env RUST_LOG=error moon check . --target native --frozen --deny-warn -j 1
env RUST_LOG=error moon test spec_strip_chars_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize
env RUST_LOG=error moon test std_string_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize
env RUST_LOG=error moon test arguments_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize
```

Future commands intentionally omit priority changes, following the parent's
instruction after the sandbox nice refusal. They are planned commands, not
additional execution evidence. info/fmt, metadata validation, current
compatibility documentation and the local English commit remain pending after
semantic verification. There is no new heavy command, slot claim or commit in
this static correction stage. Repair hashes and the pre-repair report snapshot
are retained beside the unchanged original failure evidence.

## Successful directed verification of the correction

The parent subsequently released a new slot. All repair-ready hashes matched,
including the exact frozen twelve-group fixture, before the four planned
commands ran sequentially. No command changed process priority, and no sandbox
escalation was needed. Each command used one worker; each test command disabled
parallel execution. All four completed with exit code 0:

| Command | Monotonic wall time | Observed result |
| --- | ---: | --- |
| Native check | 0.671 seconds | No warnings/errors |
| spec_strip_chars_test | 13.629 seconds | 12 passed, 0 failed |
| std_string_test | 0.279 seconds | 2 passed, 0 failed |
| arguments_test | 0.123 seconds | 1 passed, 0 failed |

This is a total of fifteen directed test groups on Darwin arm64 native debug,
using the previously recorded toolchain. The times include command startup and
any compilation, not isolated evaluator performance. No full suite, release,
Linux or Go/C++ comparison ran. All four child processes exited, and the heavy
slot was returned immediately; only metadata/documentation work followed.

The successful full fixture execution reaches every previously cut-off loop
arm, including all three functions and independent handmade AST paths. No
fixture syntax, category, value or demand expectation changed between the
seven-failure baseline and the twelve-group pass. Native counts now confirm
zero chars demand for empty or rejected primitive input, and required later
Array-member demand despite an earlier match. Original failure logs and hashes
remain unchanged alongside repair-success.json and per-command raw receipts.

The three pending manual records were reconciled only after execution. Their
frozen N/E/L/B expectations and reference locations are unchanged; status text
now identifies executed evidence. All 54 prior records are preserved, yielding
57 records and 54 functions with reviewed dimensions among 153 candidates.
Zero whole public functions are accepted, and behavioral_conformance_proven
remains false. SC identifiers remain report-local labels, not language IDs.
The current compatibility row describes the corrected behavior; frozen Go
fixtures and the historical report retain their original observations.

## Final metadata scope

Interface generation and formatting exited 0 in 0.240 and 0.064 seconds.
Generated public interfaces are unchanged, and all four tested implementation
and test files remain byte-identical to repair-ready.json. The initial info
attempt used unsupported check/test flags and exited 2 during CLI parsing;
the corrected command used the documented info options. This was not a failed
semantic test or a reason to alter expectations.

The public generator exited 0 with the same 153 candidates. Only the three
strip rows change their reviewed subsets/reference candidates; all existing
whole-contract statuses remain unaccepted. Its first sandboxed attempt exited
255 because locking the existing dependency cache was forbidden. Formal tool
approval allowed the existing --frozen metadata generators to use that cache;
no dependency upgrade, network installation or priority change was attempted.

The language generator first exited 1 because stdlib.mbt's whole-file hash
changed. Six existing rules inspect that file: type-object, length-string,
length-array, length-object, object-has-ex and object-fields-ex. A byte-level
audit proved that the entire stdlib diff is exactly the strip-only early
dispatch plus removal of the old strip arm; every other byte and all inspected
anchors are unchanged. None of those six intrinsics matches the new guard.
Six generic-dispatch arguments now explicitly exclude strip names, and sixteen
inspection fingerprints were updated after this review. All other manual
language mapping content is unchanged. The original mapping and a detailed
reinspection receipt remain in the evidence directory.

The regenerated language matrix exited 0, retaining 28 completed named rules,
one constructor transfer relative to children, 63 partial rows, two unreviewed
rows and 195 canonical evidence IDs. Its Markdown is unchanged; JSON changes
only the mapping/fingerprint metadata and the six inspection arguments. No
language rule was promoted and no historical language evidence was relabeled
as a new semantic run. Complete conformance remains false.

The current documentation validation, staged-scope audit and local commit
receipt are retained separately with the other command records. The report
does not embed its own future commit hash. Source, licenses, archive consumers,
CLI/application scenarios and platform-wide final acceptance still require
their separately scoped evidence. This correction neither resolves the
previously listed exclusions nor establishes a current full-suite result.
