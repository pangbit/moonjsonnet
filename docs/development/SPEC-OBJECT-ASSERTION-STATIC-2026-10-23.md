# Object assertion static scope: frozen criteria

Execution status: the unchanged implementation passed the frozen seven-group
native debug baseline on 2026-10-23. This adds bounded static-scope evidence,
without an implementation fix or whole-constructor acceptance. The original
pre-execution criteria below remain separate from the execution record appended
at the end.

Base: `0bf99116b5a087829f9e1ee0f4153739c287241e`. This preparation follows
the language matrix's partial chk-object row, specifically static checking of
assertion children and object-local initializers. It adds no acceptance result
and does not change the implementation or existing matrix.

## Priority and independent authority

Configuration validation can miss an invalid identifier if checking only
executes successful assertions, visits the first pair, or waits for object
field demand. A miss in a never-selected failure message is particularly easy
to hide in ordinary successful application tests. The selected contract is
therefore eager **static scope validation**, while runtime demand remains a
separate judgment. This supports the project's language/scope/assertion delivery
requirements without adding external proposal material to the repository.

The fixed official Jsonnet source is
`bbb38f1020be1f5aed560928fb839b2c448cefb4` (v0.21.0). Only the retained local
files and project code/evidence were read. The reference is the
[fixed specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html):

- Lines 1536-1547 place static checking after parsing/desugaring, initially
  under Gamma = {std}, and do not introduce static types.
- chk-object at 1586-1595 checks every key in Gamma and all values/assertions
  in Gamma plus self/super. An object field label is not a lexical binding.
- Object desugaring at 1134-1164 collects the object's local bindings; assertion
  desugaring at 1351-1363 wraps the conditional in those bindings. Locals thus
  enclose both condition and message, including names declared after the
  assertion in source. chk-local at 1654-1662 supplies the entire recursive
  binding set to every initializer and its body.
- The assertion conditional checks its condition and both branches via chk-if;
  chk-error checks its message child. Runtime selection of a true condition
  does not excuse an undefined name in the other branch.
- chk-self/chk-super at 1568-1581 and unchanged-Gamma expression assertion
  transfer mean an expression assertion in a computed key acquires no new
  object permission. It also cannot see that object's own local bindings.

The cached spec.html SHA-256 is
`bbac3701ef0316fc29de6c543049ae8f0f78c876bdd94fbf6ab845b2023a720a`.
The cached language.md SHA-256 is
`c55666af13894c8100c84fb053e647cd0ca516f3bb554d0ced29dfa83c3772be`.
No Go/C++ result, implementation output or unstated exception supplies an
expected outcome. Public Static is the project's phase/category check; exact
human diagnostics or independent-error priority are not normative oracles.

## Normative questions kept separate

The existing [assertion adjudication](SPEC-OBJECT-ASSERTION-ADJUDICATION-2026-10-22.md)
leaves N0 (inherited assertion-super transformation) and R0 (state-free
self-index checking reentry) unresolved. Neither is repaired or tested here.
The probes perform Program creation and, for positives, evaluation of a wrapper
whose object-valued local is wholly unused. They never execute assertions,
perform object field lookup, execute the unused inheritance expression or
manifest an object. Static permission for super.n is not a theorem about
runtime parent availability or the right assertion prefix.

DF0's printed ordinary field-value desugaring discrepancy remains unchanged;
no expected runtime field value is used here. The field-label negative only
uses the unambiguous absence of a lexical binding in chk-object. Standalone
super, $ lowering and full object grammar/visibility/additive behavior are
outside this batch.

Top-level manifestation and std.manifestJson are not interchangeable. Their
existing distinction, including the source-defined empty-object traversal,
is preserved. No serialization function appears in the new probes; no earlier
empty-object assertion misclassification is reinstated.

## New independent probes, not measured defects

spec_object_assertion_static_test.mbt constructs source and typed AST nodes
independently from literal fixture data, without parser/export round trips.
It reuses only neutral builders and the source/from_ast entry helper. Its
source builder deliberately writes assertions before object-local declarations.

| ID | Required outcome before any new execution |
| --- | --- |
| OAS1 | One free identifier is placed in each of three assertion-condition positions, with no fields needed. Every creation rejects Static. |
| OAS2 | All three predicates are literal true; one failure message in turn contains the sole free identifier. Every creation still rejects Static. |
| OAS3 | An unused object-local initializer with a free identifier rejects Static. A field label does not bind the same unqualified identifier in either an assertion predicate or a never-selected message. |
| OAS4 | A name bound inside a condition does not leak into its message or another assertion. A name bound inside one message does not leak into a later message. Each isolated violation rejects Static. |
| OAS5 | self.n/super.n in an expression assertion's condition/message inside a top-level computed key reject Static. A message in that key cannot borrow the object's newly declared local. |
| OAS6 | Object assertions see all recursively declared locals and retain their self/super context, including aliases declared after the assertions. Creation of both the layer and a source/AST inheritance expression succeeds; wholly unused wrappers return the literal 42. No object or assertion execution is required. |
| OAS7 | Non-Boolean, explicit-error and false assertion conditions with explicit-error messages are statically admissible. Creation succeeds and wholly unused wrappers return 42; no success is asserted for demanding such an object. |

Each negative is checked directly, inside an unused local and inside an
unselected branch through source and independently handmade AST entry paths.
Each fixture has one invalid identifier/context site. Every positive separately
checks creation and an unused wrapper through both entry paths. The explicit
42 comes from the wrapper, not any object's field or serialization output.
Limits for wrapper evaluation are the existing sequence_limits() controls.
Loops stop on the first failure; later subcases are then NOTRUN, not covered.
Seven is a frozen group count, not a passing count.

Existing O1 checks outer key scope; AS/AX/AL/AC primarily cover valid-program
runtime demand, receiver/prefix capture, conjunction and reentry. The
DESUGAR-ASSERT transfer explicitly assumes child static judgments. Its existing
review does not execute the new illegal assertion/message/local children.
No previous result is counted as execution of these bytes.

## Static implementation audit

validate.mbt's Obj arm builds the complete object-local scope first, checks
every initializer, checks keys with the outer names/context, and checks every
field value, assertion condition and present message under the object scope.
Local and function child checkers copy their inherited names, so their private
bindings do not leak. The Assert arm visits condition/message/continuation
without granting a new context. The Index(super, key) path requires an object
context and still checks its key. These paths agree with the independent
expectations; **no definite implementation defect is established**.

parser.mbt's object reader preserves assertion pairs and locals regardless of
source member order. ast_convert.mbt preserves fields, locals, every condition
and every optional message. Source parse and Program::from_ast both enter the
same static checker with {std} and no object context. All these statements are
source inspections, not measured probe results or a whole-constructor proof.

This is presently an evidence gap with a determinate static contract. N0/R0
remain distinct normative gaps. No full chk-object, inheritance, substitution,
manifestation, or whole-language completion is proposed.

## Deferred minimum baseline

The parent owns the heavy slot; this turn performs no build/check/format/test.
After allocation, verify the base HEAD, all 676 existing tracked file hashes
and symlink targets, both frozen new files and the two fixed reference hashes.
Run sequentially, stdin closed, RUST_LOG=error, one worker and a 600-second
wall cap per command:

```sh
RUST_LOG=error moon check . --target native --frozen --deny-warn -j 1 </dev/null
RUST_LOG=error moon test spec_object_assertion_static_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize </dev/null
```

Retain original stdout/stderr, actual exits, duration/counts, first-failure
cutoffs, input hashes and owned-process exit proof. A compiler error is not a
semantic failure; preserve original bytes before a neutral syntax/type repair.
Do not alter the criteria or product to turn an unchanged-product baseline
green. Formatting/interface checks for final delivery require their later
allowed checkpoint; any formatted execution bytes must be identified separately.

If a real assertion validation defect is proved, the smallest proposed later
regression set is this file plus the existing assertion-local and language
object files. Add inherited-super/self regressions only if their runtime paths
actually change. No implementation correction or adjacent run is authorized
by this preparation alone. An all-pass baseline adds only bounded evidence.

No matrix/count change, full suite, release, Go/C++, network, remote/Linux or
container execution, dependency update, upstream edit, commit, push or release
occurs during preparation. All original proposal content stays outside the repo.

## Executed baseline

After the parent allocated the single verification slot, preflight confirmed
HEAD `0bf99116b5a087829f9e1ee0f4153739c287241e`, all 676 existing tracked
content hashes and symlink targets, both new frozen files and both fixed
reference hashes. The index was empty and the only working-tree additions
were the prepared test and report. No compiler repair, changed expectation or
implementation edit was required.

| Frozen command | Actual result | Duration | Owned PID/group |
| --- | --- | --- | --- |
| native check, frozen, deny-warn, -j 1 | exit 0 | 0.441 seconds | 31486, exited |
| native debug spec_object_assertion_static_test.mbt, same options plus no-parallelize | exit 0; 7 total, 7 passed, 0 failed | 5.601 seconds | 31520, exited |

Check ran at 16:32:58.526-16:32:58.982 UTC; the test ran at
16:33:03.410-16:33:09.034 UTC. Both were serial, used closed stdin and
RUST_LOG=error, and stayed within their 600-second caps. All frozen inputs
remained byte-identical after each command, with each owned process group
absent. Every bounded loop and both source/handmade entry paths completed.
There was no semantic failure, unexecuted first-failure tail, timeout, retry or
snapshot change. The result confirms the listed expected static categories and
unused-wrapper values; it establishes no new runtime assertion/inheritance or
serialization result.

Raw evidence is retained under
`/tmp/moonjsonnet-object-assertion-static.un6fjznh`. The original manifest,
criteria and command plan are preserved independently of delivery metadata.

| Artifact | SHA-256 |
| --- | --- |
| freeze.json, all 676 existing paths plus frozen inputs | `ea1523af4d86e799d9a938b936cbaeaa592da2411ef5136ce2f4d6e63c0d3af3` |
| plan.json, frozen command arrays | `0f021121f4877b6bb102da6901d43b3547d1271f9be684165569d63a78e85887` |
| original/spec_object_assertion_static_test.mbt, executed bytes | `3dcbca0acab3d7be6ab34dc0e723bde241ef14a7e1f08a8a97f177b7f1c3c027` |
| original/docs/development/SPEC-OBJECT-ASSERTION-STATIC-2026-10-23.md | `26ee8a34a2e37cf8e15e239487d990a1f17dad0a01e08d8a5f21c6ae84106480` |
| baseline/check.stderr | `08dfb28aa47cadb52adbbe0e17f43b3527323993cdb1c310eea3ddaafceb5d46` |
| baseline/test.stdout | `29250d71d26eddc15e31c1bdd9bba84e69f30e65ab60f24e083ca22ffdaddc4a` |
| formatted delivered spec_object_assertion_static_test.mbt | `fc52475ec9825b9a8ae40a667e2d8201821fdce246685a374ad33a8666da0d83` |

Check stdout and test stderr were empty; check stderr was only the
44-byte up-to-date summary. Test stdout was the 38-byte line
`Total tests: 7, passed: 7, failed: 0.` with a newline. Each baseline/*.run.json
stores command arrays, timestamps, actual elapsed time/exit/counts, raw-output
hashes, process-group absence and unchanged-input checks. The preflight and
toolchain receipts are retained in the same directory.

The local host was Darwin mini.local 27.0.0 arm64. moon/moonrun were
0.1.20260920 (914d7da), moonc was v0.10.14+7d59c7ec9, with rr_moon_mod
and rr_moon_pkg flags. No toolchain or dependency was installed or updated.

## Evidence delivery and limits

The required native frozen moon info exited 0 in 0.201 seconds and moon fmt
exited 0 in 0.532 seconds, after the baseline. No existing tracked file or
.mbti changed at that point. Info has no jobs option and used its tool default;
the two baseline commands above explicitly used one worker.

Only the new test was formatted. metadata/format-equivalence.json records a
token comparison: all other tokens, comments and string literals were identical,
with only whitespace and six optional trailing-comma adjustments (two inserts,
four removals). The formatted file is separately retained as
metadata/formatted-test.mbt. The 7/7 execution remains bound to the original
bytes; a second execution of the formatting-only copy is not claimed.

Only chk-object receives OAS1-OAS7 mappings. All 202 previous evidence records,
every other rule mapping and all prose-clause records remain unchanged. The
existing frozen matrix generator, with -j 1 and formally approved local cache
access, exited 0 in 4.242 seconds and regenerated both matrix outputs. Its raw
stdout/stderr and command/process receipt are retained as metadata/matrix.*.
No generator or acceptance-policy code changed.

Evidence IDs increase from 202 to 209; acceptance counts remain 28 completed
named reviews, 1 relative constructor review, 63 partial rows and 2 unreviewed
rows across 70 named rules plus 24 prose/grammar rows. chk-object stays partial;
the 64 public stdlib subsets and zero whole-function acceptances are unaffected.
N0/R0, DF0, manifestation/manifestJson distinctions and all other unresolved
contracts retain their previous status. Overall conformance remains incomplete.

No adjacent runtime test was needed or rerun because no implementation changed.
No full debug/release suite, Go/C++, CLI/API process integration, ASan,
Linux/remote/container or network verification ran for this delivery. Earlier
713/713 results remain bound to their original 84eb1f7 source. The final local
commit contains only this report, the new test and the three mapping/matrix
files; its exact commit and file hashes are retained in the delivery receipt
under the evidence directory. Nothing is pushed or released.
