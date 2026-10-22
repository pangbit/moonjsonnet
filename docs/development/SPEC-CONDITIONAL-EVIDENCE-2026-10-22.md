# Conditional constructor-transfer evidence

**Decision: chk-if, if-true and if-false are reviewed complete as conditional
constructor-transfer judgments, relative to their child judgments.** This is an
engineering review of delegation, selection and environment transfer; it does
not complete the child rules or whole-language conformance. The
[pre-execution criteria](SPEC-CONDITIONAL-REVIEW.md) fix this boundary and the
independent expectations before the probes.

The fixed official Jsonnet specification is
[`bbb38f1020be1f5aed560928fb839b2c448cefb4`](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html).
Its chk-if at lines 1666-1670 requires all three children in the same Gamma.
Its if-true/if-false at lines 2273-2287 require a Boolean condition and only the
selected child's value. A non-Boolean condition satisfies neither execution
rule. Expected values, callback sequences and rejection phases were specified
directly, independently of parser round trips and reference implementations.

## Reviewed rule and boundary evidence

| Obligation | Observed evidence and scope |
| --- | --- |
| chk-if checks every child | IF1 isolates an undefined condition, then-child or else-child through source and handmade AST, including entirely unused conditional wrappers; each rejects Static at Program creation |
| Same Gamma and object context | IF1 accepts an outer binding in all three positions. IF2 rejects sibling-local leaks and out-of-object self/super in each position; inherited true/false choices return the explicit 7/9 values, and a condition-local shadow retains outer x=7 in the chosen branch |
| Source grammar | IF1's three malformed source forms reject Syntax before a Program exists; malformed source text has no typed-AST counterpart |
| No static Boolean requirement | IF3's six non-Boolean condition kinds create Programs through both entry paths, then reject Type on evaluation without branch or nested payload callbacks |
| Required evaluation order | IF4 records exactly condition,selected-child for both Boolean choices and both entry paths; a failing condition records only condition, and a selected-child failure preserves the required event sequence and Runtime marker |
| Unused demand | IF4's entirely unused conditional invokes no callback. IF5 never invokes the unselected branch; reused IU3 separately protects an unselected import request |
| Value transfer | IF5 preserves independently specified null, Boolean, number, Unicode string, array and object results for both choices and both entry paths. A selected closure is applied afterward and invokes its body exactly once |
| Reused static controls | Existing A1/AP6 reject invalid dead branches; they remain reused assertions rather than additional new groups |
| N/A within a named judgment | chk-if has no runtime premise. if-true/if-false assume a statically checked expression, so their static-error dimensions are N/A. Boundary failures do not become successful derivations of these rules |

The [static probes](../../spec_conditional_static_test.mbt) and
[runtime probes](../../spec_conditional_runtime_test.mbt) use independently
handmade trees, not exported source ASTs. Public Syntax/Static/Type/Runtime tags,
entry identity and marker messages are embedding phase controls; the fixed
rules do not prescribe those exact diagnostics. Self-made strings, trees and
virtual callbacks perform no actual imported-file or network I/O.

Constructor inspection supplies the general argument beyond these finite
examples. validate.mbt checks all three children unconditionally with identical
names/in_object inputs. ast_convert.mbt preserves the three ordered children;
ast_validate.mbt adds no conditional-specific Boolean restriction. eval.mbt
evaluates the condition once, requires Bool via runtime_types.mbt, and continues
with only the selected expression. diagnostic_trace.mbt spreads the existing Env
while replacing diagnostic context, preserving semantic bindings/object context.
These inspections assume each child's own judgment and bounded host resources;
they are not a machine-checked proof of the interpreter or toolchain.

## Execution identity and retained results

Committed test source: `2ea2a22ca1350d041e8886e8f7eb02e791a1024f`, tree
`5956a9652e6964b0f9baaf69bc601ca857f0e565`. The criteria and static tests entered
at `b4bcb7867094beb9311b1c3fa271de26b6cde1e6`. Closeout verified the retained
pre-run criteria and both probe files byte-for-byte against those committed
files. No interpreter implementation, dependency or public interface changed.
Existing Darwin arm64 tools: moon/moonrun 0.1.20260920 (914d7da), moonc
v0.10.14+7d59c7ec9.

The retained affected native debug run reports **27 tests, 27 passed, 0 failed**;
the continuation record reports process exit 0. The two new test files contain
five groups, not 27 new groups. The raw summary log does not retain the full
command line or a Git HEAD field, so an exact original file selection is not
asserted here. The retained probe bytes and continuation identity bind this
bounded result. It was not rerun during this documentation/matrix closeout and
is not presented as a fresh run of the closeout commit.

The retained root check, info and formatting logs report successful completion.
Closeout ran root `moon info --frozen --target native .` then `moon fmt .`, and
`moon fmt --check tools/spec-language-matrix.mbtx`. Matrix/documentation commands
use `moon run --frozen -j 1` at reduced process priority. Installed moon info has
no worker-count option. The initial sandbox attempt denied priority adjustment
and the existing dependency-cache lock: info/formatting still exited 0, while
the matrix invocation stopped before validation. The permitted local matrix
retry exited 0 using the existing frozen cache and pinned local references.

| Final closeout check | Result |
| --- | --- |
| Matrix validation and regeneration | Exit 0; the four resumed inputs remain byte-identical after regeneration |
| Git-tracked/staged documentation checker | Exit 0; 139 files and 1058 local/current-source links passed, including this staged report |
| Root info then formatting; matrix script formatting | All exited 0 |
| Public interfaces and whitespace | No .mbti changed; working and staged diffs pass git diff --check |

## Matrix provenance and rejected records

The [matrix](SPEC-LANGUAGE-MATRIX.md) records **6 completed named rules
(4 static, 2 evaluation), 42 partial rows and 46 unreviewed rows**, comprising
70 named rules and 24 initial prose/grammar rows. The three new completions add
no inventory row. Public stdlib coverage remains 35/153 partially reviewed
functions, and whole-language acceptance remains false.

The generator validates the pinned source hashes, exact conditional statements
and premise roles, inspected implementation/test hashes, nonempty evidence and
explicit assumptions/exclusions. It records a manual decision; matching source
or assertion text does not infer execution or prove correctness. Existing
premise-free import completions retain their separate validation path.

Four retained negative controls each exit 1 at their expected guard, before any
matrix output: changed conditional statement; wrong selected-child premise role;
conditional-record transplantation to an unsupported rule; and legacy
premise-free completion transplanted to nonempty-premise chk-self. Closeout
checked those logs, the shadow tools against the current generator and the
absence of their output directories; these were not rerun semantic tests.

| Retained artifact | SHA-256 |
| --- | --- |
| Pre-execution criteria | 0076b47bf5ba40f51228dcd1c0a05342d8e5f6fa3d525483b3cbf836a1072a03 |
| Static probe file | 6f596f443401defc8c4865a5ac19084973c1bc27aeba11dd487e131462b4ea8e |
| Runtime probe file | ed86e469169c41f8a7c4badc881152175525dd18c29282d48a23d5be31542ccf |
| Affected 27/27 log | ec680fcb3ddfafd80cc820b3bb83056e1cf81b6d88970423a789dd2ea6df1f58 |
| Four negative-control records | 3d9f2a047eaa5fa8ed3b3c98ce00c82ebab728d449ad39443be70af4522122ff |
| Closeout matrix log | 9c5bfcea43bade3975f21c3be1c436f3ee4a0d1164fe2aa830dc0b7b18647c6f |

Raw local evidence: `/tmp/moonjsonnet-conditional.PKeL9r`. Temporary logs are
not an archival delivery guarantee. Committed criteria/tests and the
[machine-readable matrix](spec-language-matrix.json) preserve assertions,
inspected hashes, assumptions, N/A reasons and exclusions. Documentation
validation reads Git-tracked/staged Markdown only; untracked documents are
outside its input set.

## Remaining scope

All child judgments, complete surface/desugaring grammar, malformed host AST
metadata, complete binder/object algebra, manifestation, diagnostic priorities
and traces, resource/stack limits and CLI exits remain separate obligations.
No error or unary rule is completed by this batch.

The [Go/C++ comparison](SPEC-LANGUAGE-COMPARISON-2026-10-22.md) remains separate
and unknown for these new cases. Earlier macOS debug 491/491 and CLI 67/67 remain
attached to cd5ea7b, and the [Linux evidence](SPEC-LINUX-AF188DA-EVIDENCE-2026-10-22.md)
remains attached only to frozen af188da; neither is promoted to this source.
No new semantic, CLI, release/full-suite, additional-platform or remote campaign,
installation, push, tag or release was performed during closeout.
