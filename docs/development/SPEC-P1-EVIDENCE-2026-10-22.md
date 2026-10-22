# Focused P1 regressions and local acceptance evidence

This stage extends the [contract matrix](SPEC-CONTRACT-REVIEW.md) and preserves
the [earlier P0/scenario report](SPEC-REVIEW-EVIDENCE-2026-10-22.md). It does not
establish complete conformance. The engineering [acceptance contract](SPEC-CONFORMANCE.md)
still requires every fixed v0.21.0 language/public-library rule and source-bound
native debug/release library, CLI and three-scenario evidence on both target
platforms. No private application content is copied into this report or tests;
all new inputs are synthetic and contain no business data.

## Source and normative decisions

Final executable validation used clean tracked inputs at
`ce4ee514fffd91152df4b4a2f33867dae01bbb86`, tree
`8213a56c93ba3a81acc615d735203a7af5e445e6`. This report and accompanying prose
updates are subsequent documentation-only changes. Platform: Darwin arm64;
Moon `0.1.20260920` (`914d7da`), moonc `v0.10.14+7d59c7ec9`.
No dependency, toolchain, version or public-interface change occurred.

| Local commit | Reviewed change |
| --- | --- |
| `2cee5de679c78c1ffbadc1e70e905d2228143938` | Previously approved function-length fix: all declared parameters, including defaults; call binding/default/lazy behavior preserved |
| `0887fced205750d656b625b9c8d841e8ba7c216f` | Reject duplicate formal parameter names with Static before invocation, including Program::from_ast; adjust local legacy assertions and archive consumer |
| `b98206572ce11b2c922312a0841582d37396ec6f` | Preserve CRLF empty lines in text blocks without normalizing their bytes |
| `ce4ee514fffd91152df4b4a2f33867dae01bbb86` | Add import-isolation/lazy regressions; update acceptance input hashes and resolved-gap metadata |

All normative sources remain fixed at Google Jsonnet
`bbb38f1020be1f5aed560928fb839b2c448cefb4`:

- [Static Checking, chk-function](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html): formal names must be unique. A per-function name set in validate checks declarations before defaults/body; outer lexical names can still be shadowed. Syntax-only raw parsing remains separate from Program static validation.
- [Lexing](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html): empty text-block lines remain empty and original line endings are preserved. Both leading/interior blank-line scans now recognize CRLF and retain both bytes. CRLF chomp and the complete malformed/whitespace-only-line matrix are not adjudicated or tested in this stage.
- [Core Syntax](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html): imports load lazily and each imported file is statically checked in isolation. New tests show current import implementation already satisfies these selected boundaries; there is no import implementation fix.

The fixed specification file retained locally has SHA-256
`bbac3701ef0316fc29de6c543049ae8f0f78c876bdd94fbf6ab845b2023a720a`.
Go/C++ behavior does not override these explicit rules. Original comparison
fixtures/results remain unchanged; accepting duplicate names in a frozen Go
fixture is now a comparison difference. No fresh upstream corpus was run.

## Actual failure and correction evidence

The first run at `2cee5de` with three new test files had nine groups: five passed,
four failed. Both duplicate-parameter groups failed (source and public AST); both
CRLF-empty-line groups failed (leading and interior). Shadowing/lazy-default and
LF/nonempty-CRLF controls passed. All three import groups passed initially.

| Executed check | Actual result / boundary |
| --- | --- |
| Duplicate-parameter, AST, Program, length, parameter and lint affected tests | 33/33 passed after fix |
| Archive consumer after static fix, before CRLF fix | 31/31 passed; not counted as a fresh final-source archive run |
| Text-block, lexer/parser/string/range/formatter affected tests | 28/28 passed after fix |
| Import, evaluator-query, Program-parameter and scope affected tests | 22/22 passed; coverage addition only |
| Final complete native debug, deny-warn, frozen, two jobs | 354/354 passed |
| Final complete native release, deny-warn, frozen, two jobs | 354/354 passed |
| Final existing P0 CLI and three application scenarios | 42/42 in one fresh run |
| Extra P1 CLI probes after correcting their test host root | 5/5; duplicate unused branch/method exit 1 with empty stdout and located errors; CRLF result, function length/lazy default and unused import succeed |
| Native check, moon info, moon fmt and diff whitespace checks | Passed; generated interfaces unchanged |
| Documentation policy/link validation | 111 files and 610 local/current-source links passed |

Affected-suite totals overlap and must not be added. The two final full suites
ran once after both implementation fixes; no full suite was run for each item.
Commands were sequential, with at most two build jobs. The existing bounded
[acceptance runner](../../tools/spec-acceptance.mbtx) builds CLI/embedded only and
uses ten-second case timeouts. Full environment development/production outputs,
monitoring panels, embedded structured results/imports, parameters, diagnostic
errors, host-root escape and resource limits were checked. P0 lazy/error/output
preservation cases remain part of those 42 checks.

The extra temporary CLI verifier first used absolute files under its evidence
directory with the CLI's default repository root. All five were rejected by the
existing host boundary before evaluation (0/5). The correction sets --root to
only that synthetic directory; all five were rerun. This was a verifier setup
error, not five language failures. Both reports and verifier versions remain
retained. These five checks are separate from the successful 42-case run.

## Reproduction and hashes

Evidence directory: `/tmp/moonjsonnet-p1.VBkTvA/`. It contains original tests,
before/after logs, complete CLI stdout/stderr, synthetic source bytes, reports,
toolchain, input hashes and test-executable hashes. Temporary files are local
evidence, not a durable archival delivery guarantee.

```sh
env RUST_LOG=error moon test --target native --deny-warn --frozen -j 2
env RUST_LOG=error moon test --target native --release --deny-warn --frozen -j 2
env RUST_LOG=error moon run --frozen tools/spec-acceptance.mbtx EVIDENCE_DIR
```

| Retained artifact | SHA-256 |
| --- | --- |
| `before.log` | `3d1d34496022a2c22075400aefb97d6e260937f38e7fc96b92b975a2c978befa` |
| `debug-final.log` and `release-final.log` (same summary bytes) | `f94302c07d60e1bc740a508eacb994cfb2499956cb9ce212c878af412c0a5b17` |
| `acceptance/report.json` (42/42) | `e3bac1312e5c8765c9b139d368b6d16d8df0d9cb0f4c206d1c73df69029e7fc8` |
| `p1-cli-before-root.json` (0/5 host rejection) | `c59f6316345d3fd6fab49635ee4f2c31ad1800a81fa3da2d34ed4163dfcf930f` |
| `p1-cli-report.json` (5/5) | `976ea5ed6eced6c50eff37d188bd0abde36d5bfee4cf8d0abab4b7cffaf6e5c6` |
| `cli-check.mbtx` (temporary P1 verifier) | `ecde92cbf3c0ea4a283e45580d7b0fe8bf92f6310835f7b7f6e2c2cd4efa14ed` |
| Release CLI | `4152486928102e39e8c3a2df70c23f1ea9e6c986d612f2477133bd905f89ef99` |
| Release embedded executable | `fc9bff1e0848549058d23616301c82df7898231625089ce1bdcadc3c63b805d4` |
| Native debug root blackbox executable | `ebfabf62317123691e4a6a7b1e03e9c2a53d77dcf3fd38afc419498cea5552f5` |
| Native release root blackbox executable | `c64d0125976f9ff9d0f7177465477ae7f493db6dfc31ec6471276a89bb7332f4` |

The final acceptance report hashes the four normative P1 test files as well as
its original fixtures and application inputs. The P1 CLI report additionally
records every source probe, verifier identity and test-executable inventory.
No binary hashes are presented as evidence for Linux.

## Remaining scope and permissions

Function-length approval is resolved by the completed `2cee5de` commit and
`/tmp/moonjsonnet-length.Fli1ZD/COMMITTED.txt`. No action in this stage was denied
by automatic approval review; no mutation has an uncertain outcome. Existing
private untracked application material was not edited or staged.

The removeAt parameter-name conflict is unchanged. The matrix remains partial;
all remaining public signatures and individual language rules still need real
normal/error/lazy/boundary mappings. CRLF chomp, the full inheritance/assertion
matrix and fresh Go/C++ comparisons are not passing claims. Linux AMD64 native
debug/release and CLI/scenario validation remain pending. Old Linux packets bind
older source and cannot be used for this final implementation. A new packet may
be prepared locally after this batch; upload/host execution requires the parent
to arrange the exact project scope and authorization. No upload, SSH, database
access, remote push, publication or tag occurred.
