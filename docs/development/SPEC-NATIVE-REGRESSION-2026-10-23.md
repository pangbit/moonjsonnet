# Native package regression records

The latest complete macOS run is [84eb1f7](#later-complete-regression-at-84eb1f7).
[Linux evidence at 228cb25](#linux-native-evidence-at-228cb25) separately binds
debug 734/734, release 734/734 and eleven release delivery cases across two
source-identical windows. Earlier results and failures keep their original boundaries.

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

## Local application delivery subset at f23210c

On 2026-10-23, the existing application examples passed two API test groups and
eleven independent CLI/embedded process cases at clean source commit
`f23210c4774c157ea7f70a7ba9c4ed865c819134`, tree
`05c5d7547539c00526fe3c6819df164222c6f1d9`. A Git archive and per-entry SHA-256
manifest bound all 682 tracked regular files and literal symlinks. The working
repository and temporary snapshot matched these inputs before and after execution.
There was no product-source, fixture, expectation or controller correction.

The external Python standard-library controller selected ten rows verbatim from
[spec-acceptance.json](../../tests/spec-acceptance.json), plus the existing
standalone embedded case from
[spec-acceptance.mbtx](../../tools/spec-acceptance.mbtx). It did not execute the
broad two-worker runner. The two API groups were the complete existing file
[examples_test.mbt](../../examples/examples_test.mbt): `complete examples match
fixed expected JSON` and `embedded config rejects invalid parameters and limits
with source diagnostics`. These use the project API and local controlled imports;
they do not install or consume a separate published package.

Commands ran serially in the temporary source directory, with closed stdin and
the existing Moon SDK. The release build and debug API test each had a 600-second
limit; every application process had a 10-second limit. The controller's overall
child-execution limit was 1500 seconds. Every spawned command received its own
process group. Timeouts would kill only that invocation's group and preserve its
raw outputs; no timeout occurred. Child environment values were frozen explicitly:
the existing PATH, HOME and SDKROOT, `RUST_LOG=error`, `LANG=C`, `LC_ALL=C`, and
TMPDIR/TMP/TEMP pointing inside this evidence directory.

```sh
moon build cmd/main examples/embedded --target native --release --frozen --deny-warn -j 1
moon test examples/examples_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize
```

The build exited 0 in 13.196 seconds; the API command exited 0 in 3.424 seconds
and reported exactly `Total tests: 2, passed: 2, failed: 0.` The controller exited
0 in 20.154 seconds including toolchain readback, hashing and process cases.
All eleven process verdicts passed; six correctly returned a nonzero exit:

| Existing case ID | Actual exit | Verified result |
| --- | --- | --- |
| environment-configurations | 0 | Entire committed development/production JSON |
| environment-file-output | 0 | Entire expected JSON in the output file; empty stdout |
| monitoring-panels | 0 | Entire committed monitoring panel JSON |
| embedded-configuration | 0 | Expected checkout configuration with replicas=3 |
| embedded-missing-parameter | 1 | Runtime diagnostic containing replicas and main.jsonnet |
| embedded-invalid-type | 1 | Numeric-parameter assertion and main.jsonnet location |
| embedded-invalid-value | 1 | Range assertion and main.jsonnet location |
| embedded-import-escape | 1 | Import diagnostic rejecting escape from the configured root |
| embedded-step-limit | 1 | Limit diagnostic; no stronger entry-location assumption |
| preserve-output-on-overflow | 1 | Overflow diagnostic; existing output bytes unchanged |
| embedded-library-executable | 0 | Expected first-line JSON and all three existing rejection diagnostics |

Success cases required empty stderr; error cases required empty stdout and the
existing diagnostic checks. JSON comparisons preserved types and full structure.
Each output-file case had its own temporary directory, with the sentinel saved
before execution and both actual and copied after-execution bytes retained.
The overflow case preserved the exact sentinel bytes. No existing user output
path was reused.

Toolchain readback recorded Moon 0.1.20260920 (914d7da), moonc
v0.10.14+7d59c7ec9, moonrun 0.1.20260920 and Apple clang
21.0.0 (clang-2100.1.1.101), on macOS ARM64. The local evidence directory is
`/tmp/moonjsonnet-local-c.t7e074qn`. The following hashes bind its retained inputs
and outputs; temporary-file availability is not an archival guarantee.

| Artifact | SHA-256 |
| --- | --- |
| source-f23210c.tar | `485eedd9ac230194bd0346dc962b84d220d06e3b431fa709a1110fa50f5a4698` |
| source-manifest.json | `7b531fa2ff58a5a2e7caa83a0804d76f396fad19c27c7b9bc8d32392765e5949` |
| freeze.json | `ff0c710289ea06bd6f41b5951a7fde3362fef10eeb2be29d02586a0e530a7b02` |
| selection.json | `95251c3061f27b88915f879dc1123b3c4b114a992e20248f24e7437db3eb69e1` |
| controller.py | `dc0b223d43cac8406372744c488d6163a462ddedbc133abc1c68bcb4c5885f1b` |
| tests/spec-acceptance.json | `bc8618dcdac3e2f7ef05b68addbdae2861183ff77ce4e6c7ca561a594b1d8257` |
| examples/examples_test.mbt | `b2ee12422858882c7e661ba3e32ce333fd8724496fda344ae11ef3edd161a5ff` |
| release cmd/main executable | `decadfb6ef3fe6c4279266170f077c1d5dae94739fd546b875fc33e914f7de99` |
| release embedded executable | `3381baa7435b6c14505b914d8fdb80c8b37766be125256a51ea5e81b92deab8e` |
| debug examples blackbox executable | `8119a4da3569aea0958bdb33203ce93da7d28ef88bbb63e8341704654892cd36` |
| results/report.json | `4e4e5258a63fafd3f56e60ae868a8cf17a0ccb35244d11a04350cd3eb569fa35` |
| results/artifacts.json | `93dc195a3a576ee9add7674355eb57e4bf7bce7f788206af042375f7623e56ef` |
| results/receipt.json | `d0af94b71e417104d7a4d3d095fdb58a1059b50b9d23a5e8286b895fc72a978a` |
| independent-verification.json | `e88a714b5c597a1767643ba8d0da83f763e67190e711ede1b7644b5ef7746302` |

The freeze binds exact argv, environment, controller and existing tool-binary
hashes. Every command has separate raw stdout/stderr and exit/timing metadata;
the artifact manifest covers reports, output-file observations and binary copies.
Independent readback rehashed the evidence, original 682 inputs and saved
executables, and confirmed the controller plus fifteen direct child PIDs and all
recorded process groups had exited. Receipt-pinned cleanup then verified the
generated-file inventory and removed only this run's `source/_build` and `tmp`.
All source inputs, raw logs, before/after output files, binary copies and receipts
remain retained. No source checkout, user output or global cache was cleaned.

This finite subset is not the complete 67-case application suite, independently
installed package-consumer acceptance, a full package regression at f23210c,
debug-and-release application acceptance in both modes, or Linux acceptance.
The old full-suite 713/713 results remain bound to 84eb1f7. No Go/C++ execution,
SSH, transfer, network tool, installation, container, ASan, push or release was
performed. The run adds no normative-rule or public-function completion: all
recorded disputes remain unresolved where previously unresolved, and overall
specification conformance remains incomplete.


## Linux native evidence at 228cb25

On 2026-10-25, two separate Linux AMD64 validation windows established complete
native debug and release package results for the same source commit
`228cb252e76ebba07b447b11b16eaf99850bf954`, tree
`130ccfc2115c6b59244226bbfeb7fb4a65a84b41`. Both used the same 682-entry Git
archive, including literal `README.md -> README.mbt.md`, and checked source
hashes before and after execution. The later documentation commit changes no
tested product, fixture, interface, module/package manifest or executable README
bytes; it is not another test run of a newly committed 682-entry archive.

### Separate results and preserved failure

The first window passed debug and then timed out during the combined release
build/test command. Its release stdout and stderr are empty. The preserved
inventory has 45 generated C test drivers but only 40 corresponding executables;
the final executable was produced 593.685 seconds after release started. There
is no final release test count for that attempt. Application build and all eleven
process cases were NOTRUN. This is an incomplete build under its original budget,
not an adjudicated language failure or an earlier release pass.

The independently approved new window split release driver construction from the
ordinary complete test invocation. It did not repeat debug, filter any test,
change a fixture/snapshot or reinterpret the first timeout as passing.

| Window / stage | Actual result | Exit | Elapsed seconds | UTC start / finish |
| --- | --- | --- | --- | --- |
| First window: native debug | 734 total, 734 passed, 0 failed | 0 | 349.361 | 02:12:13.789790 / 02:18:03.150409 |
| First window: combined release | Timeout; no final test summary | -9 | 600.066 | 02:18:03.265763 / 02:28:03.331818 |
| New window: release driver build | 45 native drivers; metadata totals 734 | 0 | 711.240 | 03:37:25.131979 / 03:49:16.372225 |
| New window: complete release test | 734 total, 734 passed, 0 failed | 0 | 119.692 | 03:49:17.465765 / 03:51:17.158259 |
| New window: application build | CLI and embedded executables | 0 | 80.096 | 03:51:18.031535 / 03:52:38.127376 |

The successful debug and release stdout files each contain exactly the following
42-byte summary (SHA-256
`97f9b62ec2158c3a6b9ae92837e4e8f3ccbe13f3b646003e63a2a0ddbb4f1fc8`),
with separate raw files and empty stderr:

```text
Total tests: 734, passed: 734, failed: 0.
```

Each mode's generated metadata independently totals 734: root library 699,
cmd/jsonnetfmt 4, cmd/main 11, examples 2, fs 5, internal/number 4,
internal/posix 4 and internal/yaml 5. The source inventory contains 711 explicit
MoonBit tests and 23 documentation tests. Forecast inventory counts alone were
not treated as execution. The release build produced 45 test drivers, including
empty drivers; executable presence does not add assertion counts. Their C and
binary hashes and timestamps stayed unchanged across the complete test command.

The new application campaign reused exactly the eleven existing case IDs and
expectations in the [local application subset](#local-application-delivery-subset-at-f23210c).
All eleven verdicts passed: five successful exit-0 processes and six required
exit-1 error processes. Full typed JSON, diagnostic fragments, source locations
where required, import confinement, budgets and before/after output sentinels
were checked. The six expected nonzero exits are not test failures. API example
tests are included in the package suite, not counted again as extra executions.

### Commands, budgets and toolchain binding

All native commands used one worker, sequential tests, frozen dependencies,
RUST_LOG=error and closed stdin. The first debug/release commands each had a
600-second limit. The new window had one 1800-second total limit, including
transfer, evidence recovery and cleanup. Its explicit revised allocation was
setup120/check30/driver-build1050/complete-test120/application-build180/
eleven-processes110/evidence-and-cleanup180/stop-reserve10 seconds. The actual
complete test took 119.692 seconds within its 120-second cap; no budget was
silently extended. The full new window completed in 941.587 seconds.

```sh
moon check . --target native --frozen --deny-warn -j 1
moon test --build-only --target native --release --frozen --deny-warn -j 1 --no-parallelize
moon test --target native --release --frozen --deny-warn -j 1 --no-parallelize
moon build cmd/main examples/embedded --target native --release --frozen --deny-warn -j 1
```

The preceding debug window used the full reproduction command with `--debug`.
`--build-only` was confirmed by installed same-version help; the following
ordinary test command retained its normal build checks and full execution.
No unsupported run-only option or test selector was introduced.

Host: Linux 6.17.0-14-generic, x86_64; Python 3.12.3; GCC 13.3.0.
Moon/moonrun were 0.1.20260920 (914d7da), moonc v0.10.14+7d59c7ec9.
The new window pinned all 1866 resources in the earlier private SDK manifest,
209271649 bytes, including contents and modes; every resource matched the
successful debug environment. Native children used UID/GID 65534 with private
read-only SDK files and private empty caches. The installed SDK binary hashes
and three watched cache-marker hashes/sizes/mtimes were unchanged. These limited
checks are not a whole-host filesystem audit. No toolchain installation or
system configuration change occurred.

| Tool / application binary | SHA-256 |
| --- | --- |
| Linux moon | `6da4919f45f4abf7c6d7f3cf8d9a457de77dca430d6fb811d21b27ae1ac8e11d` |
| Linux moonc | `d163b2c4c878ca584870764b75e633d73e8b9c178dcc6b00c692f6b2a6b1b2dc` |
| Linux moonrun | `1b22f489621059b8c22ee4acdaddc5f5d1781f62529d3000a24c03d45032d0e2` |
| Linux GCC binary | `1b99826121ae6682a634e5efe09bd3e3df58ce58e0b28f849114ab5b89139c26` |
| Linux Python binary | `c2c20b4745d447551221ec3d4e70f92c270c4609fe3df34fc52ea6dd46e92273` |
| _build/native/release/build/cmd/main/main.exe | `b539b537103dae425a0194abe8270f769f5aab2ecaf585b93ea36cc7d9a57cb9` |
| _build/native/release/build/examples/embedded/embedded.exe | `9d1c31430f61cdcc01f636ea83498d9d2fcf5c2ce26091c60d07ae5b56de3563` |

### Evidence recovery, cleanup and scope

The first-window evidence root is `/tmp/moonjsonnet-linux-window.kx1teq2a`.
Its archive and all 153 members were verified locally before any cleanup.
The immutable original receipt records a transient residual process group;
the original cleanup helper refused with `Owned-process cleanup unconfirmed`.
Fresh subsequent checks found the recorded PIDs/groups absent, but the receipt
was not rewritten. The directory was retained with mode 0700 until a separately
approved 300-second cleanup-only window on the same date. That cleanup completed
in 6.927 seconds with a new current identity/process receipt and independent
absence confirmation. Its local evidence root is
`/tmp/moonjsonnet-next-frozen.vh6m0r85/runs/cleanup-20261025T032623Z`.

The new release/delivery evidence root is
`/tmp/moonjsonnet-next-frozen.vh6m0r85/runs/validation-20261025T033716Z`.
All 255 archive members were hash-verified locally. The current receipt separately
verified directory identity, original evidence, complete generated-file inventory,
source bytes and current PID/birth/group absence. Only the owned validation
directory and controls were removed, followed by an independent directory and
process absence check. All native groups, controllers and local transport
processes exited. Historical reports/receipts remain byte-identical locally.

The following hashes bind source, the separate windows and cleanup results.
Reports contain exact argv/environment, per-command raw stdout/stderr, actual
counts, toolchain and executable hashes, own-process samples and before/after
output files. `verified-evidence/results/` is the extracted archive under each
window's local evidence root; current cleanup receipts are separate local files.

| Artifact | SHA-256 |
| --- | --- |
| Source archive | `9464643fb1d99f11b85aec2d44cf249ab112b3cd3d14601e88f02b98b4154174` |
| 682-entry source manifest | `2e609ef87ebdd4935e71259f80c6c3a14429e2a1339c671fed5ce1bddbbb43b8` |
| First-window freeze | `7be1e085ba0e0c64fa87208ddc1154c37a9d9672b9f257522cc429b298921314` |
| First-window evidence archive | `78798f0ceec783222ec4121c6db062144e84219d228b7aef26d63aeaa43d07f5` |
| First-window report | `4b685aa06281e332ce615731a620723542a58b675565dd69233e57cb5dac43df` |
| First-window historical receipt | `54602c3c18fdd1887c149bce66fbf107744edc24dc46014a32e5295e9b94a5a3` |
| New release/delivery freeze | `77dade9a534506dded57a23865748baf1821db0d057b031142eb929918b9f56a` |
| New release/delivery archive | `fc35551b95930fab2c9b845b424683fc517c0facfdbea60a182343111c6e4c82` |
| New release/delivery report | `a6a69b3de08a592da0d9bca8f90573278bf0e540fac1a8f343adfc9c1364abf8` |
| New release/delivery historical receipt | `dce8298a63dda31775f99c899878860e5e680238eb1ffed424884ea237ae1cbc` |
| New current cleanup receipt | `350308bdf27e951cbe2b39ca19424a3b80485331081d03e8a16fd12ded52862e` |
| New independent absence receipt | `bd692add798055b01eead0a28e4a95d800d4930099c2fe89ce00e15062cca200` |
| Final validation result | `ab09dd847904576cb8aa0f556eb4c1bef9dc24a2cbc2137b92dd41d6d01d3df4` |
| Old-directory cleanup result | `bad0f02acba18b12e86845cbe5a3577693d83b59d8f5660db6f94b17bb976410` |

Two older SDK-copy guard failures before any native command also remain preserved:
`/tmp/moonjsonnet-linux-window.p17wtuao` (archive
`d852d2b9eb85b0d0b2e84a51882d435107e14441e64c484ae8dd30fe72d703e9`)
and `/tmp/moonjsonnet-linux-window.dn4u715s` (archive
`6a2ed8573c196730bf3b70ec4c81f701eadd17acb17fc6cffd59489a41dc2e7c`).
Their native stages remain NOTRUN. Their fixture failures and the later
600-second release timeout were not hidden by this passing window.

These results add Linux package and eleven-case release application evidence.
They do not establish all 67 application cases, an independently installed
consumer, debug CLI process acceptance, fresh Go/C++ or upstream-language
comparisons, ASan, current-source full macOS 734 testing, public whole-function
acceptance or complete language-rule coverage. Historical macOS713 evidence
remains bound to 84eb1f7. All A0/B0/N0/R0/PE0/DF0/HP0 and other recorded unknowns
retain their separate status. Overall specification conformance remains
incomplete. Temporary evidence locations are not an archival availability
guarantee. No private proposal, upstream modification, push or release is included.

## macOS native debug regression at 4b1be8a

The accumulated sort admission, demand and inherited-source receiver changes
were exercised together at source commit
`4b1be8ae6001c00cbb5a3dc58265cb02f1dbe333`. All 686 tracked input entries
matched the frozen manifest before execution and after the test command. The
worktree was clean throughout execution; no product source, expected value,
snapshot, test selection or package configuration was changed.

The unfiltered native debug command was:

```sh
RUST_LOG=error LANG=C LC_ALL=C moon test --target native --debug --frozen --deny-warn -j 1 --no-parallelize </dev/null
```

The exact raw stdout, with a final newline, is:

```text
Total tests: 758, passed: 758, failed: 0.
```

Exit was 0 and stderr was empty. The current metadata independently enumerates
758 tests over 12 nonempty test drivers: 735 explicit tests, 16 source documentation
blocks and seven README tests. No file, package, index or name was filtered, and
there are no skip/ignore attributes in the tracked tests or current metadata.
The actual total equals the full inventory; no skip or exclusion was introduced.
Standalone tools/*.mbtx integration scripts are a separate unexecuted scope.

| Package | Current debug metadata total |
| --- | --- |
| Root library | 723 |
| cmd/jsonnetfmt | 4 |
| cmd/main | 11 |
| examples | 2 |
| fs | 5 |
| internal/number | 4 |
| internal/posix | 4 |
| internal/yaml | 5 |
| Total | 758 |

### Bounded window and actual phases

The original 600-second window began 2026-10-25 at 06:58:50.076935 UTC, with an
unchanged 07:08:50.076935 UTC deadline. Its initial controller encountered a
sandbox PermissionError in auxiliary process observation, exited 124 after
0.005 seconds and confirmed its owned command group absent. Its empty output
contains no test summary and is not a product failure or passing-test claim.
That original receipt remains intact. Formal approval then allowed the same
frozen local command and read-only owned-process observation within the same
absolute deadline; the budget was not reset.

The approved command started 07:00:01.234407 UTC and finished 07:01:56.901543 UTC:
**115.667 seconds** observed wall time. The complete original window used
**186.824 seconds**, including controller recovery and exit checks. The raw
controller elapsed fields use the original-window clock; the command duration
above is derived from its separate UTC start and finish.

Two-second owned-process sampling first observed moonc at 07:00:03.269935 UTC,
then the examples test driver at 07:00:23.562935 UTC and the root library driver
at 07:00:25.619935 UTC. These show compilation followed by actual test execution;
they are sampled boundaries, not exact exclusive compiler/test durations. Both
the initial and approved command groups were independently absent after exit.
The slot was released before documentation work; no product command was retried
after the 758/758 result.

### Input and raw evidence binding

Raw outputs, unmodified first-controller failure, approval-continuation receipt,
current test metadata/binary hashes, phase observations and verified counts are
under `/tmp/moonjsonnet-native-debug-4b1be8a.aui96a_c`. Temporary evidence paths
are not an archival availability guarantee. Host/toolchain remain macOS ARM64,
moon and moonrun `0.1.20260920` (`914d7da`), moonc `v0.10.14+7d59c7ec9`.

| Artifact | SHA-256 |
| --- | --- |
| inputs-before.json (686 tracked entries) | `9a0b96c8d2c48f0a1424f4a8f20e8a98ff041c25a963cc2e94634f3e5bb8c6f2` |
| plan.json | `abc5618173649c8c85189613047760ac4e764ee2a0adeced6f1b6a59a26c0f55` |
| First controller run.json | `6d488d3c235cb0245759e103e28bec5c624f4257ad40495113c8f1040f8e1782` |
| Approved formal-continuation/run.json | `d48a93924b14d0d00358d94f7708fe6f230708ea60bfbe869e888931a05eb721` |
| Approved raw stdout | `35896ab519fe3ca38bfff7c1b8f9e42a4a01647df048b7b257fd4bf1f4ef7958` |
| Approved raw stderr (empty) | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |

This is a current-source macOS native debug package regression. Release,
standalone API/CLI delivery scenarios, Linux and Go/C++ were NOTRUN in this
round. The separate 228cb25 Linux results are not evidence for these new product
bytes. No new specification domain or feature, comparison erratum, snapshot
migration, SSH, push or release was introduced. Existing red-case evidence,
N0/R0/DF0 and other language disputes remain intact. Overall conformance stays
incomplete; 65 public subsets and zero whole-function acceptances are unchanged.


## macOS native debug regression at 9150705

The accumulated objectRemoveKey, remove and removeAt source-routing changes
were exercised together at source commit
`915070528e59e8f899ecc60033923d1bd8b2ab62`. All **695 tracked input entries**
matched the preceding committed manifest before execution and afterward. The
worktree was clean during the run. No product, test, expected value, snapshot,
selection or package configuration changed. All earlier independent red runs
and exact legacy migrations remain in their original evidence records.

The unfiltered package command was:

```sh
RUST_LOG=error LANG=C LC_ALL=C moon test --target native --debug --frozen --deny-warn -j 1 --no-parallelize </dev/null
```

Raw stdout, including its final newline, is exactly:

```text
Total tests: 789, passed: 789, failed: 0.
```

Exit was 0, stderr empty, timeout false and skipped 0. The current metadata
independently enumerates 789 tests across 12 nonempty drivers: 766 explicit tests
plus the unchanged 16 source documentation and 7 README tests. No file/package/
index/name filter or skip/ignore attribute exists in the executed selection.
The metadata total equals the raw actual total; these are regression unit counts,
not 789 normative judgments. In particular, conditional compatibility profiles
remain unit checks with their existing normative acceptance null. tools/*.mbtx
standalone integration scripts were not dispatched by this package command.

| Package | Current debug metadata total |
| --- | --- |
| Root library | 754 |
| cmd/jsonnetfmt | 4 |
| cmd/main | 11 |
| examples | 2 |
| fs | 5 |
| internal/number | 4 |
| internal/posix | 4 |
| internal/yaml | 5 |
| Total | 789 |

### Cross-impact boundary and actual phases

The full run includes the two `spec_index_test.mbt` groups requiring integer
Array/Unicode String indices and the six `numeric_test.mbt` groups, as well as
immutable deletion, alias/map/caching, all independent remove/search and current
objectRemoveKey/deletion groups. Ordinary Array/String indexing therefore keeps
its existing fractional/type/bounds rejection; source-defined removeAt index
filtering/admission is not generalized into a relaxed ordinary-index rule.
The index/number operators and their expected values were not edited.

One 600-second window began **2026-10-25 at 09:21:24.780285 UTC**, with the fixed
09:31:24.780285 UTC deadline. A 590-second command soft limit reserved 10 seconds
for owned-group termination if needed. The run ended at 09:23:34.664808 UTC,
using **129.885 seconds**, including input verification and exit bookkeeping.
It did not need a retry, budget reset, product repair or oracle migration.

Read-only own-process sampling first observed moonc at 2.069 seconds and an actual
package test driver at 22.346 seconds; the root library drivers were also seen.
These are sampled compiler/test boundaries, not exact exclusive phase timings.
All observed descendants belonged to the owned process group 19698. The controller
and a later independent signal-zero check both confirmed that group absent.
The test command was fully joined, and the heavy slot was released before the
following documentation-only work. No product test was rerun after 789/789.

### Same-source evidence binding and unexecuted scope

Raw stdout/stderr, unchanged source manifests, toolchain/binary fingerprints,
current metadata, phase observations and exit/cleanup receipts are at
`/tmp/moonjsonnet-native-debug-9150705.9d1pcey9`. Temp storage is not an archival
availability guarantee. This host is macOS ARM64, with freshly checked moon and
moonrun 0.1.20260920 (914d7da), moonc v0.10.14+7d59c7ec9. Only the 12 current nonempty
metadata-driver executables are selected as binary evidence; other cached files
are not counted as executed tests.

| Artifact | SHA-256 |
| --- | --- |
| inputs-before.json (695 entries) | `99e8bdd202f6e0beec6ea35dbc4839096cc7a35df6048b2b95778b97ab16f1ef` |
| inputs-after.json (same 695 entries) | `99e8bdd202f6e0beec6ea35dbc4839096cc7a35df6048b2b95778b97ab16f1ef` |
| plan.json | `64bb5fc5914b8785135846970106152ccb576330d3b86ba23457345fcf8c3a1d` |
| run.py | `d19acf984eb3acc5b37b0098c7895983fb2021fa2369f76336d91cb45892a487` |
| run.json | `d06dd921d3e7df6c7e9e771072fd8debb2a330d627b7dd430aacd75b4fb25b34` |
| Raw stdout | `05872ffddbfe5a9237cd914285554e17dc0d8f43cde1354d88be539a8c916e90` |
| Raw empty stderr | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| Current toolchain and binary hashes | `92e6af90e375881e1b361a444c6a0e071364df89b466929e42235babfef47e98` |
| Current metadata/12 drivers and independent exit verification | `89b522cd4ec9b001729ceba737c7b722d3e6eb7695b6d65267a4ad5b8c22ed3f` |

This establishes current-source macOS native debug package regression only.
Release, standalone API/CLI delivery scenarios, Linux/SSH and Go/C++ were NOTRUN.
Earlier Linux results remain bound to 228cb25; the former 758 result remains at
4b1be8a. No remote window, new feature/domain, upstream/proposal change, toolchain
installation, snapshot update or push occurred. The removeAt idx/at signature
conflict, current-i compatibility status and shared language disputes remain
unchanged. Overall conformance stays incomplete; 66 public subsets and zero
whole-function acceptances are not promoted by this regression.


## macOS native debug regression for 3397975 and one foldl oracle migration

The shared foldl/sum/avg source routing at product commit
`3397975c966e4c3a48748a5136776dd2b950d8d0` was exercised with the full unfiltered
local native debug suite. All 699 tracked entries initially matched the frozen
committed input manifest. Installed moon/moonc/moonrun/clang binary hashes equal
the preceding audited 9150705 run; versions remain moon/moonrun 0.1.20260920
(914d7da) and moonc v0.10.14+7d59c7ec9 on macOS ARM64. No product, configuration,
interface or snapshot was changed during this validation.

Both invocations use the same unfiltered command, closed stdin and one worker:

```sh
RUST_LOG=error LANG=C LC_ALL=C moon test --target native --debug --frozen --deny-warn -j 1 --no-parallelize </dev/null
```

### Preserved first failure and exact adjudication

At pristine 3397975, raw output ends with:

```text
Total tests: 802, passed: 801, failed: 1.
```

Exit was 2, stderr empty, wall time 129.962 seconds. The only failing declaration
was stdlib_contract_test's foldl-demand group, whose obsolete input expected a
Type error from `std.foldl(function(a,b)b,{},0)`. Its actual raw failure reports
unexpected success and does not print the returned value. The old assertion
stops that loop; its later callback-arity entry was NOTRUN there.

The fixed [foldl definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L823-L830)
checks index 0 against length({}) 0 and returns the original running/init 0, without
calling func or indexing. This is also independently frozen by ASA7 in the
[admission review](SPEC-AGGREGATE-ADMISSION-2026-10-25.md). The same exact input
moved from the error loop to the existing literal success list with expectation 0.
No input, test declaration or case was deleted; the only semantic test-file
change is this individually evidenced oracle migration. It is not a snapshot
update or product fix. All first-run outputs and the original file are retained.
No language evidence snapshot binds this file, so no rule completion or evidence
hash adjustment is needed for this migration.

### Continuation within the original fixed window

The sole window began **2026-10-25 at 10:28:18.543503 UTC** with the unchanged
**10:38:18.543503 UTC** deadline. Its first command ended at 10:30:28.505474 UTC.
The continuation began at 10:33:36.439563 UTC after the exact oracle patch was
formatted and its new 699-entry input manifest frozen. The controller measures
elapsed time from the original start, not a new 600-second clock, and reserves
the final 10 seconds for process-group termination if needed.

The continuation's exact stdout is:

```text
Total tests: 802, passed: 802, failed: 0.
```

Exit was 0, stderr empty, timeout false. Command duration was **107.656 seconds**;
completion at 10:35:24.098454 UTC used **425.555 seconds of the original window**,
including the first run and intervening diagnosis/migration. No budget was reset.
The migrated positive assertion and the previously unexecuted error-loop suffix
ran successfully. No additional product/test repair or further test run followed.

All 699 entries were stable within each invocation. Between invocations only
stdlib_contract_test.mbt changed, with SHA-256
`cd46518ed733d44120ea83265ea7eecbfca23c250295f17a9ce22eb06f902330`.
The passing evidence is therefore product 3397975 plus this explicit test migration,
not a claim that the untouched original commit had zero failures.

### Actual scope, phases and exit receipts

Current metadata enumerates 802 tests over 12 nonempty drivers: 779 explicit tests,
16 source documentation blocks and 7 README tests. There are no skip/ignore
attributes or file/package/index/name filters. Skipped 0 follows from the complete
metadata total equalling raw actual output. Unit regression includes conditional
compatibility checks; it does not make 802 specification judgments.

| Package | Metadata total |
| --- | --- |
| Root library | 767 |
| cmd/jsonnetfmt | 4 |
| cmd/main | 11 |
| examples | 2 |
| fs | 5 |
| internal/number | 4 |
| internal/posix | 4 |
| internal/yaml | 5 |
| Total | 802 |

This covers actual foldl consumers, all sum/avg overflow/additive/admission and
lazy cases, unchanged Array/Unicode String integer-index checks, parser/flatten/
uniq/set and existing immutable/diagnostic neighbors. The source routing did not
relax ordinary indexing. The independent CLI/application process campaign and
tools/*.mbtx integration scripts remain outside this package-test invocation.

Own-process samples in the first run observed moonc at original-window 2.070s
and an actual test driver at 22.349s. Continuation samples observed moonc at
window 320.048s and a test driver at 324.107s. These are sampled phase boundaries,
not exclusive compiler/test durations. Each command was fully joined; both
process groups 50567 and 50932 were independently confirmed absent afterward.
The heavy slot was released before documentation-only metadata/commit work.

### Evidence and remaining scope

Raw original and continuation output, both stable 699-entry snapshots, old/new
oracle files, unchanged toolchain hashes, current 12-driver binary/metadata hashes,
phase samples and independent exit checks are under
`/tmp/moonjsonnet-native-debug-3397975.iz96e67p`. Temp paths are not an archival
availability guarantee. Relevant bindings are:

| Artifact | SHA-256 |
| --- | --- |
| Initial committed inputs | `2c17f1d798c0ff964cb64c63c2fc96bb8a738da0a60bea826ab3b819fa52d31c` |
| Initial plan | `16e54bf10121ac956e4352010028398a334528642f10b6957446d5ffa819fedd` |
| Preserved failing run | `dd2146260b53e3d0a0e308af2c9a0ca711d4ffb7a307ba5176ced8d89d3bce3a` |
| Preserved failing stdout | `d15ad5f0a344e9b2845fe3ce4523a7fbc1526ab80c7182cee00c90b8439e8791` |
| Frozen continuation inputs | `504cce162ab935489e75af47cc1ebb3cc86400f2177f486d96c42b56f1cd38de` |
| Stable continuation inputs after run | `504cce162ab935489e75af47cc1ebb3cc86400f2177f486d96c42b56f1cd38de` |
| Continuation same-deadline plan | `23fa82e8d820122d9cdf8c647e00d912ac3b16604adf06226ef5d5b417a82066` |
| Continuation result | `635361e0b5f71257bcc84586d978bb2a9c67494a7ee56ecba6ffd3f5e177a411` |
| Passing stdout | `d8686d7728eb7793d4a07ed4efb93b723fb0990fe486eadfbeb57559e7091a46` |
| Passing empty stderr | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| Toolchain versions/binary hashes | `b3c8893b7a9a22ebb549d3c18ee2836c42ca29ecc125b895c47cae8b4cff936b` |
| Independent metadata/binaries/exit verification | `81ebf549b4342d9431222b3c52e9bdc29f641fdbefbeffa00a60b15ab8e9a5db` |

This is local native debug package regression with a documented legacy oracle
migration. Release, Linux/SSH, standalone API/CLI delivery and Go/C++ were NOTRUN.
The prior Linux evidence remains tied to 228cb25 and is not migrated. No feature,
new semantic domain, product repair, reference snapshot update, environment
installation, upstream/proposal change or push occurred. Shared normative disputes
and incomplete overall conformance remain; no public whole-function completion
is promoted by 802 unit passes.


## macOS native debug regression at 0d06ded

The clean703-entry source snapshot
`0d06dedeb40ade30b6501ef961ce86cc3c5f4916` completes the cumulative YAML demand
and shared-call follow-up. All inputs match the committed manifest before and
after this run. No product, oracle, snapshot, configuration or interface changed.
Installed moon/moonc/moonrun/clang SHA256 values match the earlier3397975 audit:
moon/moonrun0.1.20260920 (914d7da), moonc0.10.14+7d59c7ec9 on macOS ARM64.

The same closed-stdin, one-worker, frozen unfiltered command was used:

```sh
RUST_LOG=error LANG=C LC_ALL=C moon test --target native --debug --frozen --deny-warn -j 1 --no-parallelize </dev/null
```

Fresh --outline enumeration lists816 entries. Current metadata agrees:12
nonempty drivers, no skip attributes; the duplicate no_args_tests index is not
counted a second time. Root contributes781, cmd/jsonnetfmt4, cmd/main11, examples2,
fs5, internal/number4, internal/posix4 and internal/yaml5. Raw final stdout is:

```text
Total tests: 816, passed: 816, failed: 0.
```

Exit0, skipped0, empty stderr, timeout=false; the completed native command took
130.751987333 seconds including any build work. The package command includes
conditional compatibility tests, so816 passes are not816 normative judgments.

The original600-second window began at11:47:51.618172 UTC on2026-10-25, with
fixed deadline11:57:51.618172 UTC. Outline succeeded in0.090479 seconds. The first
just-started test was safely stopped when optional local /bin/ps own-process
sampling raised sandbox PermissionError. Its controller exited124, with empty
outputs and no semantic test statistics; this is a preserved harness failure,
not an implementation failure or a passing test run.

The prohibited sampler was not retried. A continuation retained the Popen child
handle, dedicated process group, input checks and termination reserve, while
disabling only that optional observation. It began11:49:33.906980 and completed
11:51:44.661438 UTC, using233.043301 seconds of the original window. The absolute
deadline never changed. Detailed compiler-versus-test phase timings were not
observed and are not inferred. Outline/aborted/finished groups89847/89848/89879
were independently confirmed absent. The heavy slot was released before
documentation-only closeout.

This complete local regression covers the initial P0 tests, current source
foldl/sum/avg and deletion routes, integer indexing/lazy slices, sort, YAML
required/unused options and late errors, and ordinary/strict call controls.
The original failures, exact legacy migrations and conditional normative limits
remain in their stage records. This run changes none of their expectations.

Local raw evidence: `/tmp/moonjsonnet-native-debug-0d06ded.r03ooman`.
verification.json contains12 driver/binary SHA256 pairs, exact package counts,
no-skip basis, input stability and independent process-exit receipts.

| Artifact | SHA256 |
| --- | --- |
| inputs-before.json | `68a098ef00afca1f07f6d2762562d2a5ab5a554f70a2d9e6ae18966e9145b671` |
| outline.stdout | `5105d308027eb2dfd3aa0d4b990bd4707638c38fd823100ebdea4a89faf0bbfb` |
| run.json | `84904179302d0cc23e971bc9a39d1a09b3e313d389c7c1a71a63d7d678abd1dc` |
| continuation/stdout | `f7fb8057dfa60b3f956bcb26d014b899892f26f544f7a2b28e0f38442b1874e1` |
| continuation/run.json | `2acb0f842e93ee8d6e2c3ea1eb8a5d1803a0e3e9b768576f88d2d38482743e51` |
| verification.json | `487997483444f719dd64103c2dc0b230ba189f4da0778c8b6bcd3773df845d20` |
| toolchain.json | `8148c8fa0357325355b154a48edd82efac2a1a75693406d0ff72f74839bbd4cb` |

Subsequent changes in this closeout are documentation only. The
[phase inventory](SPEC-CONFORMANCE.md#stage-inventory-after-0d06ded) distinguishes
current P0 regressions, existing subsets, evidence-mapping gaps and shared
normative questions. No release, Linux/SSH, independent CLI/API, standalone
tools/*.mbtx integration or reference interpreter was executed. The older
228cb25 Linux evidence remains bound to that source, and whole conformance
remains incomplete. No further test or new semantic domain starts in this turn.


## macOS native debug regression at1a46122

Clean source `1a461221627e54d983611f7a5e773fab7577869b` is the708-entry
freeze point for the completed input-parsing/shared-returned-data batch. It
includes the bounded parseYaml root guard, parseJson eager finite-tree visitor
and native/YAML String-key isolation. This validation changes no product, test,
oracle, snapshot, package/module, executable README or interface bytes. Earlier
red results and any individually justified legacy migrations remain in the
[JSON/input record](SPEC-JSON-CONTRACTS-2026-10-23.md) and
[YAML root record](SPEC-PARSE-YAML-2026-10-25.md); a green full suite does not
replace them or settle their explicit conditional profiles.

The unfiltered command closes stdin and uses frozen dependencies, one worker
and serial test execution:

```sh
RUST_LOG=error LANG=C LC_ALL=C moon test --target native --debug --frozen --deny-warn -j 1 --no-parallelize </dev/null
```

Fresh installed --outline succeeds and lists835 entries. Current generated
metadata independently agrees across12 nonempty drivers and8 packages: root800,
cmd/jsonnetfmt4, cmd/main11, examples2, fs5, internal/number4, internal/posix4 and
internal/yaml5. This is812 explicit tests,16 source documentation tests and7
README tests. The nineteen added groups since0d06ded are six public YAML, two
normative-null YAML profiles, five JSON input and six returned-data-key groups.
No test attributes or selectors skip anything; no_args_tests aliases are not
counted a second time. Raw final stdout is:

```text
Total tests: 835, passed: 835, failed: 0.
```

Exit0, skipped0, empty stderr, timeout=false. The complete suite command takes
134.280120166 seconds, including any build work. The whole600-second window
starts2026-10-25 at14:31:29.029634 UTC, with fixed deadline14:41:29.029634 UTC;
it ends14:33:45.748986 UTC after136.718975208 seconds. Toolchain metadata and
outline precede the suite in the same clock. No command is retried and the
budget is not reset. No process-table sampler is invoked; exact exclusive
compile-versus-test durations are unavailable and not inferred from silence.

All708 input hashes match before and after execution. Popen groups32511
(toolchain),32514 (outline) and32515 (suite) exit normally and are independently
absent. The heavy slot is returned before this documentation-only closeout.
The twelve executed driver binaries and their metadata have recorded SHA256
values in verification.json. macOS ARM64 moon/moonrun0.1.20260920 (914d7da),
moonc0.10.14+7d59c7ec9 and the Apple clang binary have exactly the preceding
0d06ded audit's hashes; no toolchain is installed or changed.

Local evidence: `/tmp/moonjsonnet-native-debug-1a46122.8g0ycb6t`.

| Artifact | SHA256 |
| --- | --- |
| plan.json | `c14a420b78ebca60bddcc1e04bbc51ae06095e583d52e9da78f33517dfc552f5` |
| inputs-before.json | `c847bd942fb05f4dd728382882a48f1a666ac83680b3d005edcfba9ea0b87897` |
| static-enumeration.json | `cdef7aa3674bb1925e107430e84dbdf579c52ef4e5c6ec9c2bfba336618a997a` |
| outline.stdout | `207a5cc8aa7886581e0f9f90492525f29be136e234ea64832355e78185180f59` |
| suite.stdout | `0b82ad14a02aad27dabfd9ee96e56a387522472b8dfbfc60860bd70f79a75aab` |
| suite.stderr | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| run.json | `ae1aad06555b5507171257e6d50afe54a803dc09b1ce9af156bf8351b5cfeaa3` |
| verification.json | `65c7e281c33a43b2b5f662fc146b3e9ae2001e6e32d801781130be94afe33ef3` |
| toolchain.json | `3f72b0e9477ef4ff426a9b70ca28a48e398b9c9b0c5ace36f4d589441242b419` |
| run.py | `ca394d3a69facec807aca279d1b2f596040bbf5d11bcae9067267befcbd121c8` |

This is current local regression evidence, not835 normative acceptances. Public
coverage stays67 mapped subsets/zero whole-function acceptances; all225 language
evidence records and their conditional child assumptions are unchanged. Overall
specification conformance remains incomplete. Current release, Linux/SSH,
standalone tools/*.mbtx, independent CLI/API/package-consumer and Go/C++ checks
are NOTRUN. Historical228cb25 Linux734/734 and earlier full-suite counts are not
inherited by this source. Only this record and the concise cohort checkpoint
are edited after testing; tested implementation/fixture bytes remain identical.

### Same-source platform follow-up boundary

The complete708-entry allowlist and README.md -> README.mbt.md link are frozen
at1a46122. A later documentation-only commit must prove identical product/test/
package/executable-README bytes. No new archive, upload or remote operation is
prepared or launched here. The existing Linux flow can be reused at a separately
scheduled boundary: strict host/toolchain identity, audited private read-only SDK
layout and two internal links, private caches/UID65534, check, release build-only,
unfiltered complete release tests, existing application build and unchanged
eleven-process delivery subset, evidence readback/verification and owner-only
current-identity/process cleanup. No new environment loop or installation is
needed. The old734-case test used119.692 of120 seconds, so that cap must not be
silently reused for835; a new explicit phase allocation must retain the total
1800-second transfer/execution/recovery/cleanup bound. Current debug134.280
seconds informs sizing but does not predict release/Linux duration. Full67-case
application and independent package-consumer acceptance stay separate from the
eleven-process subset. No further semantic domain or test starts in this turn.
