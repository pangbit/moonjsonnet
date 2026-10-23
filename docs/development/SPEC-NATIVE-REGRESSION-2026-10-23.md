# Native package regression after the strip and split fixes

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
