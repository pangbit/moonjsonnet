# Native package regression records

The latest complete local run is [84eb1f7](#later-complete-regression-at-84eb1f7).
The earlier strip/split entry remains bound to its original source and counts.

## Source and result boundary

On 2026-10-23, the complete local native package suite passed in both debug and
release mode at commit `21ee8005fbca4779adb2e01d53000c65f325eb33`, tree
`84501f5b20cb962e1377ca9145bef6b1b0cef208`. Both runs started and ended with a
clean worktree and the same hashes for all 666 tracked files in the frozen input
manifest. The subsequent documentation commit changes no tested product,
fixture, interface, manifest or executable README bytes.

| Mode | Actual result | Exit | Elapsed seconds | UTC start / finish |
| --- | --- | --- | --- | --- |
| Native debug | 672 total, 672 passed, 0 failed | 0 | 105.038 | 13:16:33.342621 / 13:18:18.385447 |
| Native release | 672 total, 672 passed, 0 failed | 0 | 145.160 | 13:20:16.125123 / 13:22:41.285313 |

Elapsed times use a monotonic clock around each command, including compilation
and linking. Neither run reached its 600-second limit. Each raw stdout is exactly
42 bytes, including the final newline:

```text
Total tests: 672, passed: 672, failed: 0.
```

Both stderr files are empty. Each test process group and its Python wrapper
exited before the testing slot was returned. The debug run was not repeated
when release was authorized. No failed case was removed, filtered or relabeled;
no snapshot was updated.

These are current package regression results, not complete Jsonnet conformance,
CLI process integration, cross-platform acceptance or reference comparisons.
The normative target remains Google Jsonnet
`bbb38f1020be1f5aed560928fb839b2c448cefb4` (v0.21.0). The
[character stripping record](SPEC-STRIP-CHARS-2026-10-23.md) retains its original
five-pass/seven-failure baseline; the
[split record](SPEC-SPLIT-LIMITS-2026-10-23.md) retains five passes and six failures.
Their independent expectations and corrected focused results are unchanged.
SPL-R0, parameter-name conflicts, Array concatenation and raw-text encoding
questions remain unresolved where previously recorded. No public function gains
whole-contract acceptance from this regression run; overall conformance remains
incomplete.

## Reproduction and local scope

Run from the repository root with the locally installed toolchain:

```sh
RUST_LOG=error moon test --target native --debug --frozen --deny-warn -j 1 --no-parallelize </dev/null
RUST_LOG=error moon test --target native --release --frozen --deny-warn -j 1 --no-parallelize </dev/null
```

The recorded invocations passed the same argv without a shell; stdin was
`subprocess.DEVNULL`. Local `moon test --help` confirmed `--release`, the job
limit, sequential test execution and frozen dependency behavior before use.
Each invocation had its own 600-second wall limit and owned process group.
No priority adjustment, dependency synchronization, installation or network
request was performed. A timeout would have been retained as a nonpassing run,
with process termination confirmed before returning the slot.

The source inventory contains 649 explicit `.mbt` tests, 16 source-documentation
test blocks and seven README tests. Their per-file counts agreed with generated
test metadata before execution. That forecast was not treated as a passing
result; the table above uses each command's actual summary.

| Package | Explicit tests | Documentation tests | Total |
| --- | --- | --- | --- |
| Root library | 615 | 22 | 637 |
| cmd/jsonnetfmt | 4 | 0 | 4 |
| cmd/main | 11 | 0 | 11 |
| examples | 2 | 0 | 2 |
| fs | 4 | 1 | 5 |
| internal/number | 4 | 0 | 4 |
| internal/posix | 4 | 0 | 4 |
| internal/yaml | 5 | 0 | 5 |
| Total | 649 | 23 | 672 |

All project packages were eligible; no package, file, name or index selector was
used. The twenty package manifests contain no custom build hooks. Static review
found no test-initiated network or subprocess calls; native compilation, linking
and generated test drivers use local child processes. File-host tests read
repository examples and write random `_build/host-search-*` fixtures. POSIX tests
exercise canonical paths and intentionally missing or invalid paths. The stdin
test uses invalid limits whose C guard returns before reading. These tests were
included without exclusions, and existing generated artifacts were preserved.

Package-wide testing excludes standalone `.mbtx` scripts, as the installed help
explicitly states. The five tests in `tools/differential.mbtx` remain NOTRUN for
this source, as do standalone CLI/API integration scripts, reference Go/C++ and
upstream-language runners, archive consumers, Linux/remote/container checks and
ASan. CLI helper unit tests and direct library/example calls above do not replace
those process-level checks. No standalone release build or release publication
was performed.

## Toolchain and input identity

Host: macOS 27.0.1, Darwin ARM64. Installed versions:

- moon `0.1.20260920 (914d7da 2026-09-20)`.
- moonc `v0.10.14+7d59c7ec9 (2026-09-18)`.
- moonrun `0.1.20260920 (914d7da 2026-09-20)`.

SHA-256 values below identify the tested implementations, the two frozen
regression fixtures and the installed MoonBit binaries:

| Input | SHA-256 |
| --- | --- |
| stdlib.mbt | `0cafea376164f882e1d27e29a47ac1c6328189001344895a0305a3476a0933fe` |
| std_string.mbt | `11251f9f1142f364c56865cd5398e4523fd7714ec720582c7dbc67bca2c71026` |
| spec_strip_chars_test.mbt | `8b0571d5cfac33281dd2053b081f64ff4a76af9c4bb2aa14514be14c2884807b` |
| spec_split_limits_test.mbt | `c4df06a99535f812bff99a9a4c4ab44147e733543a60d7d7f9cc3c318a59d7a7` |
| moon | `a0cd1c0014f2ca17089542939ac4ad3c983452c5952ca6140af0fcef258e1967` |
| moonc | `8a49fb209d896b8ce72322883aa53a2395a1bdd88d35423ebfd841fc66b8f127` |
| moonrun | `5e67ecba6138384ffca6548005d73580751ea6bc57f02113859010b09f1730e1` |

## Raw evidence locations

The local evidence root is
`/tmp/moonjsonnet-native-debug-plan.s9t1n4qe`. Relative paths below resolve under
that directory. Every run receipt records exact argv, environment override,
source identity, timestamps, elapsed time, exit, timeout status, process-group
exit, output hashes and the post-run clean/hash checks.

| Evidence | Relative path | SHA-256 |
| --- | --- | --- |
| Frozen 666-file input manifest | tracked-inputs.sha256 | `97a3cd1533b8273b902a8eccf771baf403bf99775d9eb8e0269410d6e6764a57` |
| Static test inventory | test-inventory.json | `121945f4726cf224ab06fff26e6e3c3232623cfbe53e2f73e8c23deb94a266a4` |
| Original debug preparation | plan.json | `a7dfed12e14cc0a707e42f32b09658bd9c7c60a749332981916ab3f0c088bc74` |
| Debug receipt | run-20261023T131633.341714Z/run.json | `0ceee48b2de0e3d04242f6dbcdaba9290d8728a3b9a0dd063c5228d447d6d9c2` |
| Release receipt | run-release-20261023T132016.124738Z/run.json | `c4182d77939a8d426d7f9ab2c9f49c95290613c8e0930f473121d26b51a4a4c5` |
| Debug test-binary manifest | delivery/debug-test-binaries.sha256 | `4bcff65288e03ca1960370d7c2d5295ccfe484614ba79a29175a1a33b262fb16` |
| Release test-binary manifest | delivery/release-test-binaries.sha256 | `bd4e25a2cb97753622b8e8216141d0e48a0b9d20d0106ed279d170ebbc067abb` |

The raw files are `stdout.log` and `stderr.log` beside each run receipt. Each
stdout SHA-256 is
`aff9f238d14ee2b1cf3149dcad6c1c7ac7f3caa84af2ab30a4f0c13a7142b58c`;
each empty stderr SHA-256 is
`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`.
Both output pairs remain separate even though their contents match.

The post-run binary manifests identify twelve generated test executables per
mode, selected from nonempty test-info records totaling 672 cases. They exclude
empty drivers and unrelated cached executables. These fingerprints supplement
the process receipts; the receipts' actual summaries establish the run results.

Temporary evidence is local and is not an archival availability guarantee.
The committed source identity, commands, results and hashes remain in this
report. Historical results such as the 539-test debug run at 5651ae9 retain
their original source boundaries. No private proposal, upstream modification,
dependency change, push or release is included.

For the documentation delivery, `moon info --target native --frozen` and
`moon fmt` both exited 0, in 0.048 and 0.024 seconds respectively. These are
metadata/format checks, not additional semantic runs. Their command receipts,
the documentation validation receipt and the final commit/input verification
are stored under `delivery/` in the evidence root. Product, fixture, interface
and executable README bytes remain those tested above.


## Later complete regression at 84eb1f7

The membership and two extrema corrections are now covered by a new complete
local package run on 2026-10-23. Both modes bind source commit
`84eb1f71d1f408b1aa0bd11526a83b31f51b58d0`, tree
`a381e8a7d7b42e0c6b605c746fa7f497469af649`. Each command started and ended with
a clean worktree and the same SHA-256 hashes for all 674 tracked files. This
entry preserves the older 21ee800 results above; it does not reuse their 672
count or relabel their binaries as current.

| Mode | Actual result | Exit | Elapsed seconds | UTC start / finish |
| --- | --- | --- | --- | --- |
| Native debug | 713 total, 713 passed, 0 failed | 0 | 114.195 | 15:32:59.351986 / 15:34:53.546992 |
| Native release | 713 total, 713 passed, 0 failed | 0 | 160.993 | 15:35:01.378953 / 15:37:42.372292 |

Both raw stdout files contain exactly the following 42-byte summary, including
the final newline; both stderr files are empty:

```text
Total tests: 713, passed: 713, failed: 0.
```

No failure, timeout, retry, expectation migration, snapshot update or test
exclusion occurred. Debug and release ran sequentially in separate owned
process groups. Each entire command, including compilation/linking/execution,
had a 600-second limit, closed stdin, RUST_LOG=error, one worker and sequential
tests. All command groups and wrappers exited before returning the test slot.
The exact commands are the two unchanged reproduction commands above, with
explicit `--debug` and `--release`; installed help was checked again locally.

### Current enumeration and offline scope

The fresh source inventory contains 690 explicit MoonBit tests, 16 executable
source-documentation blocks and seven README tests. Before execution, current
debug metadata agreed per file; the old release metadata still totaled 672 and
was explicitly classified as stale. After each run, that mode's metadata
independently totals 713 and identifies twelve nonempty test executables. The
actual passing results come from the raw command summaries, not this inventory.

| Package | Explicit tests | Documentation tests | Total |
| --- | --- | --- | --- |
| Root library | 656 | 22 | 678 |
| cmd/jsonnetfmt | 4 | 0 | 4 |
| cmd/main | 11 | 0 | 11 |
| examples | 2 | 0 | 2 |
| fs | 4 | 1 | 5 |
| internal/number | 4 | 0 | 4 |
| internal/posix | 4 | 0 | 4 |
| internal/yaml | 5 | 0 | 5 |
| Total | 690 | 23 | 713 |

The 41 added declarations since the earlier whole-suite source are fourteen
membership groups, fourteen extrema demand groups and thirteen extrema comparison
groups. Existing declaration counts are retained. Their independent requirements,
original failures and scoped migrations remain in the
[membership report](SPEC-MEMBERSHIP-2026-10-23.md),
[extrema demand report](SPEC-EXTREMA-DEMAND-2026-10-23.md) and
[comparison continuation](SPEC-EXTREMA-COMPARISON-2026-10-23.md).

All twenty package manifests remain eligible; no file/package/index/name filter
was used. The 34 module/package configuration, executable README, C and fs/POSIX
files relevant to the earlier offline audit are byte-identical to that audited
source. Inspection of subsequent implementation/tests found no new network or
external-process calls. Frozen dependencies use the existing local toolchain;
there was no dependency synchronization, toolchain installation or network action.
File-host fixtures remain randomized under _build and existing artifacts are
preserved. The invalid-limit stdin tests return in their C guard before reading;
stdin is also closed for both full commands. No test exclusion was necessary.

### Current identity and raw evidence

Host remains macOS 27.0.1 (26A434), Darwin ARM64. Installed versions are moon and
moonrun 0.1.20260920 (914d7da), moonc v0.10.14+7d59c7ec9, with rr_moon_mod and
rr_moon_pkg enabled. The checked current implementation/fixture and installed
binary hashes are:

| Input | SHA-256 |
| --- | --- |
| stdlib.mbt | `4c83dbc6cae5344ac264d08cd8df7601137b2d04f4c4d97f8977dd9c67ad6511` |
| std_membership.mbt | `680ffdeaf633166f7af73d21d8a8d5ed0c38ab9b36ec83b8757eae721b18d9b9` |
| extrema.mbt | `65d1f63c91bf5336761df94f5f3359c3a26667b7dce9f6955f921043cbad1459` |
| extrema_test.mbt | `39699c2d91e740208035c14f3436bb5cb56a18ce261963e823fe773e0d1fc98b` |
| spec_membership_test.mbt | `ff98fa18f761be4560885c2d02c55bf926ab5532c14f56b049d825ec692ae39e` |
| spec_extrema_demand_test.mbt | `f3cc7628a5726e919328565b11436712e03eee749bf8568cc2d9a9726e61817e` |
| spec_extrema_comparison_test.mbt | `437eee0449cee8057af030fbddd791ba4b952a5e853c9f82102c728a9a619e16` |
| moon binary | `a0cd1c0014f2ca17089542939ac4ad3c983452c5952ca6140af0fcef258e1967` |
| moonc binary | `8a49fb209d896b8ce72322883aa53a2395a1bdd88d35423ebfd841fc66b8f127` |
| moonrun binary | `5e67ecba6138384ffca6548005d73580751ea6bc57f02113859010b09f1730e1` |

The local evidence root is `/tmp/moonjsonnet-native-84eb1f7.ql24n51t`.
Paths in the next table are relative to it:

| Evidence | SHA-256 |
| --- | --- |
| tracked-inputs.sha256 | `c91f74a6fc10a45c4c39fdd66a3411e0662d44e03a7a0c7e4646c597ae8ff603` |
| test-inventory.json | `d29ffda0cc612669bf705815caef7ad635cc932c473b5c21e3f7904a0036590d` |
| plan.json | `9659a0bdee9760faf655d38d612c7777aa8aad3cd860c7206bac57c5a3677bd3` |
| toolchain.txt | `10d48f2767e8de05ca6a6e7a022458bcd450ad4f40dc8473106b54444098ae44` |
| moon-test-help.txt | `9d1220361b9b2e7082d9995d1123725f6c33dd0974c475c99c3f05b532ad129f` |
| debug/run.json | `b172cc3600c567e99a76f39fd961450fc088fb040b9b51d7970eedf9c6b4da02` |
| release/run.json | `122c1cc062273291863993a5e1d526d8cf43f7892200290250ec1af7969aa6d5` |
| debug/test-binaries.sha256 | `25832d6feef1c2cdc084afa3b4f9c7ff4a65a1bad74f32ff282ae76c362bcf4d` |
| release/test-binaries.sha256 | `78f66f342ad7b5efce1fb36b0fa59ce756dc97399c688125ce860dd2b07232b4` |
| debug/test-metadata.json | `618487397fb728bdb989162e82e592caee78b2d16ad1f96dfdcf10b65f0cf7c4` |
| release/test-metadata.json | `199cdaeca9fa96af5c7e9c8fdce30ad44ee1b8a5aff8f645edf8b78e0a89508c` |

The raw outputs remain separate as debug/stdout.log, debug/stderr.log,
release/stdout.log and release/stderr.log. Each stdout SHA-256 is
`c5a08bbaeddeb78f1d9ba782c56fd1b9ec35290e7a0a328c79311b894351f6e8`;
each empty stderr SHA-256 is
`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`.
The receipts bind argv, environment, source/tree, UTC and monotonic timing,
exit/timeout, process groups, raw hashes and clean pre/post input checks.
The per-mode binary manifests select only the twelve executables backed by
nonempty current test metadata, excluding empty drivers and unrelated caches.

### Scope still not established by these passes

Standalone .mbtx scripts remain outside package-wide execution, including five
differential-validator tests. Separate CLI/API process integrations, archive
consumer, fixed Go/C++ or upstream-language comparisons, Linux, remote, container,
ASan and standalone release build/publication remain NOTRUN for this source.
Direct library/example and CLI-helper unit tests do not establish those scopes.

This whole-suite regression adds no public-function acceptance or language-rule
completion. Public coverage remains 64 reviewed subsets, zero whole-function
acceptances; overall conformance is incomplete. Non-Array extrema admission,
exact callback counts, independent error order, the greater-than formal-rule
conflict and all other recorded normative disputes retain their prior status.
Temporary logs are local evidence, not an archival availability guarantee.
No proposal content, upstream modification, push or release is included.

The documentation-only delivery changes no tested product, fixture, interface,
manifest or executable README bytes. Its metadata checks and final exact input/
commit verification are retained under delivery/ in this evidence directory.
