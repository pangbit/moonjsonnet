# CRLF chomp and official public-contract inventory evidence

This stage extends [P1 evidence](SPEC-P1-EVIDENCE-2026-10-22.md). It resolves the
previously untested CRLF chomp boundary and separates the official public
inventory from Go registration counts. It does not establish complete conformance.
All new inputs are synthetic; no business data or private application content is
included. Existing user material remains untouched and unstaged.

## Fixed lexical decision and actual regression

The [fixed specification's Lexing section](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html)
preserves the file's line-ending style and strips the final newline for |||-.
Together these require stripping one complete final CRLF, preserving every
preceding ending and any additional content CR. This is an interpretation of the
explicit lexical rule, not acceptance inferred from Go/C++ output.

Before the fix, |||- followed by CRLF, an indented x line ending CRLF and the
terminator produced bytes 78 0D rather than 78. The seven-group baseline at
f4b9a14 plus [new tests](../../spec_text_chomp_test.mbt) had four passes and three
failures: ordinary CRLF chomp, preceding empty-line preservation and the public
AST value. LF/mixed-ending controls passed. Complete raw failures remain in
before.log; no snapshots or original upstream fixtures were changed.

`e59151f4613c6c5699c651fd9abc7e8b2663f383` adds three implementation lines:
after removing the terminating LF, remove one preceding CR if present. It does
not normalize any earlier endings. Byte assertions cover leading/consecutive
blank lines, mixed CRLF/LF, an extra content CR, unchomped CRLF, source retention
and Program::from_ast. Affected lexer/parser/string/range/formatter tests passed
32/32, native check passed, and generated interfaces were unchanged.

## Source-bound final validation

Final executable validation used clean tracked inputs at
`0969b3550e83cca9a919d083cfe66bb2b72ba912`, tree
`2f80b222b5424d15582a89096fc904bab1175b16`. This report and subsequent status
prose are documentation-only changes. Platform: Darwin arm64; Moon
0.1.20260920 (914d7da), moonc v0.10.14+7d59c7ec9, matching moonrun.

| Executed check | Actual result |
| --- | --- |
| Initial seven lexical groups | 4 passed, 3 failed |
| Affected native debug tests after minimal fix | 32/32 passed |
| Final complete native debug, deny-warn, frozen, two jobs | 358/358 passed |
| Final complete native release, deny-warn, frozen, two jobs | 358/358 passed |
| Final normative CLI and three application scenarios | 44/44 in one run, including two new byte-preserving chomp cases |
| Official-source inventory generator | Reference hashes matched; 153 candidate identifiers, two properties; no whole-contract passes inferred |
| Documentation validation before this report | 113 files and 820 links passed |
| Final documentation validation | 114 files and 826 links passed |

The full suites ran sequentially once after the batch, not for every item. nice
was requested for each native command, but the environment denied setpriority.
It still executed each command with two build jobs at the permitted priority;
both suites completed normally. This was an OS/environment restriction, not an
automatic approval-review rejection. No priority adjustment is claimed.

The CLI runner's build/case limits remain 180/10 seconds. Complete environment
development/production outputs, monitoring panels, embedded configuration/API,
runtime errors, nonzero exits, root escape, resource limits and P0 lazy/output
preservation cases passed. No repeated upstream comparison was performed.

Evidence directory: `/tmp/moonjsonnet-chomp.e4KiCM/`. The final JSON report binds
source, toolchain, CLI/embedded binaries and complete fixture/input hashes.
Temporary evidence is local, not a durable archival delivery guarantee.

| Artifact | SHA-256 |
| --- | --- |
| before.log | 06ee960ca09fd774d55200526da3f6b70d26c6805b3408b5c434c8a5fd70bd35 |
| after.log (32/32) | 08dc4f2cea9a9a7cd93da9c2067009b8f022eb791620ac1f671cf093cc204337 |
| debug-final.log and release-final.log (same warning/summary bytes) | d116ac8e04fc4b6d21c750ab4b49f7a5f3862a0f810ceb514d51ec6cd7780a5a |
| acceptance/report.json (44/44) | bf78dd8a4e7c54809c2f10804fb12fa6eb52babfbff225a0a808e89002236a20 |
| Native debug root blackbox executable | a746e85a01f1aa413e462372ac890fb855ae4929bee118b1546e2ceb4c53c6af |
| Native release root blackbox executable | 11037ea25f91e6536cf61b33d12079f124e349d354c484d53f5092b2fb2dc1c5 |
| Release CLI | 619f4003b2ecbcc396f5931f32cae35985148aa62876cfe472645fe06af18ed6 |
| Release embedded executable | a2a72b6627d723eb4a2c4fc8b8b20f110b2fe1e8ab72fa406e9166c921a87d62 |

## Public inventory and unresolved decisions

`0969b35` adds the [official inventory and review method](SPEC-PUBLIC-STDLIB-REVIEW.md),
[all candidate names/signatures](SPEC-PUBLIC-STDLIB-INVENTORY.md), a hash-bound
JSON snapshot and reproducible generator. The 153 identifiers include the
unresolved XML spelling pair, not 153 accepted independent functions. Eight
internal helpers, two properties and the extra Go id entry are separated.

Seven functions have explicitly reviewed subsets of N/E/L/B; the remaining
dimensions stay unreviewed. Literal and manually inspected dynamic test
references are candidates, not passes. The report retains source/doc signatures
independently, including removeAt idx versus at. Source at is a proposed stronger
implementation candidate when selecting source-defined signatures, but no rule
uniquely resolves the conflicting documentation. No rename or alias is added.
XML spelling, YAML stream default, fractional isEven/isOdd and Go-only hash scope
also remain explicit review questions, not newly executed failure claims.

## Retained Linux packet and requested scope

No Linux transfer, login or command was attempted. The existing packet remains
byte-identical and binds f4b9a14cd20814650e4937992f491b444ca0877f:

| Retained local file | Size in bytes | SHA-256 |
| --- | ---: | --- |
| /tmp/moonjsonnet-p1.VBkTvA/source-f4b9a14.tar | 6881280 | e30424894f5781a66ffb9359a816ebdb4ff5c7ca3deeced78bdfa8fb20ccb3d0 |
| /tmp/moonjsonnet-p1.VBkTvA/source-update-f4b9a14.bundle | 55838 | ad0d28559615c814df4c516d584e57719e8ec134075bb4f0bf3fda1a71542e58 |

The tar has 527 entries: exact tracked source, native helpers, library/CLI
packages, tests/fixtures, tools, examples, public docs and licenses, plus archive
directory entries. It excludes Git metadata, builds/binaries/caches, credentials
and the untracked application. Its complete listing is retained locally as
f4b9a14-files.txt. The incremental bundle requires the same-project baseline
8e661f9c1a418f87658c68dedc68615483513f86; a source tar alone is not a Git checkout.
This old packet does not contain the chomp fix. A separately named final packet
will bind the completed batch; the old evidence must not be overwritten.

The proposed first Linux job, for the parent to arrange and authorize:

- Linux AMD64, dedicated non-root project checkout containing the exact baseline and target commits. No other project's access is assumed.
- Request two available CPUs, 4 GiB RAM and 8 GiB free workspace/tool-cache space, serial commands and two build jobs, with host-approved lower priority. These are requested operating bounds, not measured minimum or peak requirements. Cap each full native test command at ten minutes and the complete job at thirty minutes.
- Exact Moon 0.1.20260920/914d7da, moonc v0.10.14+7d59c7ec9 and matching moonrun; existing compatible C compiler/linker and POSIX libc. Record compiler/OS versions rather than upgrading them. Git, uname and shasum must be available.
- The product module declares no external module dependency. The .mbtx verification runner additionally needs matching Moon script/runtime support for moonbitlang/async fs/shell. Confirm that frozen support/cache is ready first; missing support is a setup blocker to report, not permission to download or upgrade dependencies.
- Run native deny-warn/frozen check, full native debug and release tests, then tools/spec-acceptance.mbtx without case selection. The runner builds only CLI/embedded and performs the 44 current checks. Retain full commands, exits, outputs, source status, toolchain, binaries and input hashes; failures remain failures.
- No service/daemon, port, database, unrelated filesystem, Go/C++ rebuild, broad differential, ASan, dependency upgrade, remote push, publication or tag is included. Transfer and execution require explicit parent-arranged scope before starting.

No approval-review rejection or uncertain mutation remains in this batch. No
further priority change was attempted after the restriction was observed.
Complete cross-platform and all-public-contract acceptance remain pending.
