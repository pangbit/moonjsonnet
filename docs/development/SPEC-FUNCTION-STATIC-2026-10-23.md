# Function static scope: frozen preparation

Execution status: the unchanged implementation passed the frozen seven-group
native debug baseline on 2026-10-23. No implementation defect or constructor
completion is declared. The preparation text below is retained as the original
pre-execution plan; actual results and byte identities follow it.

Base: `80e10a90073e15c6154b5817fac92b0fa7bd9085`. This is a language
constructor review, independent of the completed stdlib corrections. Preparation
only: no build, check, formatter, test, implementation change or new acceptance
claim. The existing language matrix still records chk-function as partial.

## Authority and independent expected behavior

The fixed official Jsonnet specification is
`bbb38f1020be1f5aed560928fb839b2c448cefb4` (v0.21.0). Its retained local spec.html
has SHA-256
`bbac3701ef0316fc29de6c543049ae8f0f78c876bdd94fbf6ab845b2023a720a`.
Only this local material was consulted; no reference interpreter was executed.

[Static checking](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#static_checking),
lines 1536-1547, describes checking after parsing/desugaring, initially under
Gamma = {std}, without static types. chk-function at lines 1693-1703 has three
premises: every optional default is checked under Gamma plus **all** formals;
the body is checked under that same set; formal names are pairwise distinct.
There is no invocation, default-demand or runtime-type premise. The empty
formal list satisfies the uniqueness and optional-default premises vacuously.

Consequently a free name in any default or body must prevent Program creation,
even in an unused local or unselected branch. Forward, mutually recursive and
self-referencing defaults are statically admissible when all names are bound;
this says nothing about their termination when called. A local or nested
function inside one default introduces names only in that child, not in other
defaults or the enclosing function body. Existing Gamma names remain visible,
and distinct formals may shadow outer names.

The adjacent chk-object / chk-self / chk-super rules, lines 1568-1596, give
object values their object context but not an object's computed keys. Function
checking preserves that inherited context and does not introduce it. Probes use
only self.n and super.n, not the disputed standalone-super case. Runtime
inheritance and object assertions are not judged by these probes.

Static is a project phase/category assertion for rejection during parse or
from_ast, rather than an official diagnostic spelling. Each negative fixture
contains one invalid name/context site. No ordering among simultaneous errors,
exact diagnostic text, location or callback count is required.

## Missing evidence, not an established implementation failure

The matrix's chk-function row already cites F1/F6/AP1/AP2 for positive lexical,
default and method behavior, and F5/S1 for negative source/default/uniqueness
behavior. It leaves default/body constructor review open. In particular F5
constructs source programs; it does not independently build invalid default or
body ASTs. AP1/AP2 establish positive handmade invocation/default environments,
not those rejection paths. An exported parser AST would not independently
test them either.

The new file spec_function_static_test.mbt supplies seven named groups. It
constructs source text and AST nodes separately from literal fixture data,
using existing neutral builders only. No expected value is computed from the
implementation or Go/C++ output.

| ID | New group and independently specified outcome |
| --- | --- |
| FS1 | Put the sole free name in the first, middle and last of three optional defaults after one required formal. Each rejects Static during creation. |
| FS2 | A free name in the body rejects with zero formals and with required/optional formals whose defaults are valid. |
| FS3 | A local binding or nested function parameter private to the first default cannot bind the second default or the outer body; each rejects Static. |
| FS4 | Zero formals, required-to-default references, forward/mutual defaults, self-referential defaults, outer names and legal shadowing all create successfully. Their unused wrappers return the explicit 42. |
| FS5 | self.n/super.n in a default or body reject outside an object and in a top-level object's computed key. Function syntax grants no permission. |
| FS6 | The corresponding default/body sites accept within object values, using an inherited object for super.n. Unused wrappers return 42 without demanding fields or running inheritance assertions. |
| FS7 | Explicit error and wrong-runtime-type child expressions are admissible in both default and body; unused wrappers return 42. No runtime success is asserted for calling them. |

Every rejection is checked directly, inside an unused local, and in an
unselected branch, through both source and handmade-AST entry paths. Every
positive performs creation plus evaluation of an unused wrapper through both
paths. Loops stop at their first failure; later subcases are then NOTRUN, not
covered. Seven is a planned group count, not a passing result.

Reuse spec_static_test.mbt's existing source and independently handmade duplicate
formal controls rather than adding copies. Its exact source-diagnostic assertion
remains a host check. Existing F1/F6/AP1/AP2 remain their original evidence;
their historical results are not executions of these new bytes.

## Static implementation audit and limits

validate.mbt's Func branch first copies names, collects every parameter, and
rejects duplicates using a fresh seen map. Only afterward does it iterate all
present defaults, then the body, each with the same completed scope and
unchanged in_object flag. Child Local/Func branches copy their enclosing name
sets; the reviewed path does not leak their private additions into siblings.
The Obj branch checks keys under the outer names/context and values under the
object context. These branches agree with the proposed independent criteria.

ast_convert.mbt preserves each formal name, optional default and body while
recursively converting them. ast_validate.mbt checks host parameter identifiers
and ranges. parser.mbt's parameter reader preserves names/defaults; both its
parse entry and Program::from_ast in program.mbt call validate with {std} and
no object context. No definite implementation discrepancy was found by this
static audit. The baseline may therefore pass entirely; an uncovered contract
is not a measured defect.

Any future constructor-completion decision must be relative to the child
judgments, supported by this structural review and actual probe results. This
preparation does not complete arbitrary child constructors, source grammar or
desugaring, invocation/default execution, parameter metadata, $ lowering,
standalone super, object algebra/assertions, exact diagnostic/error priority,
resource exhaustion or CLI behavior. Object-assertion N0/R0 disputes and all
extrema disputes stay unchanged. No conformance matrix or count is updated.
This work supports the project's language-conformance delivery requirement;
it does not establish overall acceptance or import external proposal content.

## Minimal deferred baseline

The parent owns heavy-test scheduling. After allocation, first verify the base
HEAD, all 674 existing tracked paths, both frozen new files and the fixed spec
hash. Then run only these commands sequentially with closed stdin, RUST_LOG=error,
one worker and a 600-second wall limit per command:

```sh
RUST_LOG=error moon check . --target native --frozen --deny-warn -j 1 </dev/null
RUST_LOG=error moon test spec_function_static_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize </dev/null
```

Preserve raw stdout/stderr, actual exits, durations, counts, first-failure cutoffs
and process-group exit status. Compiler errors are not semantic failures;
preserve original bytes before any necessary syntax/type-only correction.
Do not modify the product or frozen meaning to make the baseline pass.

If a subsequent constructor acceptance needs refreshed uniqueness evidence,
the smallest adjacent run is the existing spec_static_test.mbt (three named
groups) with the same native debug options. That is a separate scheduling
request, not permission to run it during this preparation. Formatting/interface
checks required for final delivery are likewise deferred until permitted.
There is no reason currently identified to modify any implementation file.

No full suite, snapshot update, priority adjustment, network, upstream edit,
dependency installation, Go/C++, Linux, remote/container test, commit, push or
release is part of this static preparation. Temporary freeze receipts preserve
the original bytes but are not archival storage.

## Executed baseline and delivery scope

The parent subsequently allocated the single heavy-verification slot. Preflight
verified HEAD `80e10a90073e15c6154b5817fac92b0fa7bd9085`, all 674 tracked
file-content hashes and symlink targets, both new frozen files and spec.html.
The working tree initially contained only the two prepared, untracked files.
No syntax/type repair, changed oracle, snapshot update or implementation edit
was needed.

| Command from the frozen plan | Actual result | Duration | Owned PID/group |
| --- | --- | --- | --- |
| native check, frozen, deny-warn, -j 1 | exit 0 | 0.444 seconds | 20684, exited |
| native debug spec_function_static_test.mbt, same options plus no-parallelize | exit 0; 7 total, 7 passed, 0 failed | 5.480 seconds | 20708, exited |

Check ran at 16:14:25.946-16:14:26.405 UTC and the test at
16:14:29.640-16:14:35.139 UTC. Each command used closed stdin, RUST_LOG=error,
one worker and a 600-second cap. Neither timed out. All frozen input hashes
were still identical after both commands, and both owned process groups were
absent. Every bounded loop in FS1-FS7 completed; there is no first-failure cutoff
or unexecuted branch within those listed groups.

The actual stdout summary was `Total tests: 7, passed: 7, failed: 0.` followed
by a newline. Check stdout and test stderr were empty. Check stderr contained
only `Finished. moon: ran 6 tasks, now up to date` and its newline.

Evidence directory: `/tmp/moonjsonnet-function-static.jbjt3hbe`.

| Retained artifact | SHA-256 |
| --- | --- |
| freeze.json, original 674-file manifest and prepared-file identities | `2c2dc77c84328441c0d4742d1c54b2b22ef3f0e3b5593470bacdfc7fd72a46c2` |
| plan.json, the two frozen command arrays | `c86e86daa74e72a2b94731d3cc49fcf7ef76f5d03f4058538731c09b57441df0` |
| original/spec_function_static_test.mbt, executed bytes | `c5f3cf4d6fe829d7c74ca06ee666bdffb8c12a7bf7437665b22ea645242522b4` |
| original/docs/development/SPEC-FUNCTION-STATIC-2026-10-23.md, original criteria | `d9a1f163d1c7ea72cf15668e6c0a187004bbac10c77ed94e0b761b12d1ceb5ed` |
| baseline/check.stderr | `08dfb28aa47cadb52adbbe0e17f43b3527323993cdb1c310eea3ddaafceb5d46` |
| baseline/test.stdout | `29250d71d26eddc15e31c1bdd9bba84e69f30e65ab60f24e083ca22ffdaddc4a` |
| formatted delivered spec_function_static_test.mbt | `4d7e433ff2b5b0851f33ab823abbafea31cc3c33c0e2499a1bee769bbcb4ccc3` |

baseline/check.run.json and baseline/test.run.json retain actual command arrays,
timestamps, elapsed times, exit/timeout state, output hashes, input-hash checks
and process-group absence. baseline/preflight.json and toolchain.json retain
the input and toolchain receipts. The host was Darwin mini.local 27.0.0 arm64;
moon/moonrun were 0.1.20260920 (914d7da), moonc was v0.10.14+7d59c7ec9,
with rr_moon_mod and rr_moon_pkg flags.

After the baseline, the required moon info --target native --frozen and moon fmt
invocation completed with exit 0 and no .mbti changes. Info has no jobs option;
this auxiliary invocation used its tool default, separately from the two
single-worker baseline commands. Only the new test file was reformatted.
baseline/format-equivalence.json records a token comparison: all string
literals, comments and other tokens were identical, with only whitespace and
three optional trailing commas before closing brackets/parentheses removed.
The formatted copy is retained as baseline/formatted-test.mbt. The 7/7 result
is bound to the original bytes above; no second execution or new test result
is claimed for the formatting-only copy.

Only the chk-function row receives new FS1-FS7 mappings. All prior evidence
records, other rule mappings and prose-clause records are preserved. The
existing matrix generator checked the updated mappings and regenerated both
matrix outputs with exit 0 in 4.192 seconds, using --frozen and -j 1. Its first
sandboxed attempt exited 255 before generation because MoonBit could not lock
the local dependency cache; that raw failure remains under metadata/generator.*.
The subsequent metadata/generator-approved.* attempt used formally approved
cache access, performed no dependency update/network operation, and exited
with its process group absent.

The evidence inventory changes from 195 to 202 unique IDs. Acceptance status
does not change: 70 named rules plus 24 prose/grammar rows; 28 completed named
reviews, 1 relative constructor review, 63 partial rows and 2 unreviewed rows.
chk-function is still partial. The generator infers neither execution nor
whole-language acceptance; this report supplies the separate bounded execution
record. The 64 public stdlib subsets and zero whole-function acceptances are
unaffected; overall conformance remains incomplete.

The existing spec_static_test.mbt uniqueness controls were not rerun. No full
native suite, release, standalone integration campaign, CLI/API process test,
Go/C++, Linux, ASan, network or remote/container verification ran for this
delivery. Historical 713/713 debug/release results stay bound to 84eb1f7 and
are not relabeled as executions of the new probe or delivery commit. The local
delivery commit contains the test, this report and the three mapping/matrix
files; its exact commit and file identities are retained in the final delivery
receipt under the evidence directory, without a self-referential report hash.
