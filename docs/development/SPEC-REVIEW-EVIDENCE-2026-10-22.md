# Independent P0 review and local acceptance evidence

This second stage extends [P0 evidence](SPEC-P0-EVIDENCE-2026-10-22.md).
It does not establish complete specification conformance. The
[contract review](SPEC-CONTRACT-REVIEW.md) records the initial P1 mapping, a known
function-length failure, and the unresolved removeAt signature conflict.

## Reviewed source and results

- Full native release and the first CLI/scenario run used
  `0c53f6960798f21ca1001d12410eee619e298bab`.
- The focused diagnostic-classification retry used
  `298f17dd5f6762c1e7e6a844015be859a84ea02a` (tree
  `2bd761016dfc7d87206070c54f0a5f5cc1e1801d`).
- There are no `.mbt`, `.mbti`, `moon.mod` or `moon.pkg` changes between those
  commits. The latter only corrects the verifier and two fixture annotations.
  CLI and embedded binary hashes are identical in both reports.
- Platform: Darwin arm64. Moon `0.1.20260920` (`914d7da`), moonc
  `v0.10.14+7d59c7ec9`. No toolchain or dependency upgrade occurred.
- Product implementations remain identical to the first-stage P0 fixes. This
  stage commits tests, a bounded verification tool and review documentation.

| Executed check | Actual result |
| --- | --- |
| Independent P0 plus embedded API boundary tests | 6/6 passed |
| Full native release, deny-warn, frozen, two jobs | 341/341 passed |
| First complete CLI and application-scenario run | 40/42 passed; two verifier classification failures retained |
| Only the two corrected verifier cases rerun | 2/2 passed |
| Native deny-warn check, moon info and moon fmt | Passed; no public interface changes |
| Documentation validation after the new reports | 110 files and 593 local/current-source links passed |

There are 42 unique CLI/scenario checks and 44 process observations across the
two runs, not a single fresh 42/42 rerun. The first two failures required all
errors to start with `RUNTIME ERROR:`. Actual Import and Limit diagnostics used
their documented host formats, already exited 1, and had empty stdout. The
correction requires their specific class/message while keeping both cases and
their exit/output checks. All 42 unique cases now have passing observations;
the 40 previously passing cases and full release suite were not rerun.

The complete fixtures are [tests/spec-acceptance.json](../../tests/spec-acceptance.json).
The runner [tools/spec-acceptance.mbtx](../../tools/spec-acceptance.mbtx) builds
only cmd/main and examples/embedded with two jobs. Each process has a ten-second
timeout, and the build has a 180-second timeout. It retains full inputs, exits,
stdout/stderr, output-file observations, input hashes, binary hashes and source
identity. Existing private untracked files are not read or copied.

The environment example compared the entire committed development/production
JSON, including shared app/region and distinct replicas/debug/endpoints, and
verified CLI file output. Monitoring compared the entire panel structure and
service lookup against committed JSON. Embedded checks exercised public library
results/imports, parameters, located assertion/runtime errors, root escape and
step limits. A one-step limit can expire while initializing `<std>`, before an
entry-program call context exists; the test records this boundary explicitly.
Overflow/YAML failures also preserved an existing output file byte-for-byte.

## Independent P0 findings

The review followed constructors and consumers beyond the original author tests:
literal overflow, arithmetic, pow/hypot, JSON/YAML parsing and native callbacks
were inspected through std.type, so final-output guards could not hide invalid
intermediate values. No additional finite-value leak was confirmed in these
reviewed paths. This is bounded evidence, not a proof for every mathematical
function/domain. from_json/native_result and math/operator checks remain relevant
parts of the finite-value invariant.

Deletion copies thunk IDs, preserving both payload caching and laziness. A host
callback shared through original/result ran once, while removed/retained error
payloads stayed unforced when only length or other indices were demanded.
Unicode tests cover supplementary characters, combining marks, NUL and empty/end
boundaries. Public slicing uses the embedded std.slice definition via base_env
and syntax dispatch; index errors stay deferred for array elements and strict
for strings. The native slice fallback is aligned, but is not the public path.
YAML nested runtime/type/assertion/function errors propagated, and a reusable
Evaluator remained usable after each failure.

## Source, binary and raw-evidence bindings

Raw evidence remains local under `/tmp/moonjsonnet-spec-review.dyOCji/`.
Temporary evidence is not a durable archival guarantee. The reports include a
per-file input SHA-256 map for the fixtures, runner, P0 tests and all three
application scenarios.

| Artifact | SHA-256 |
| --- | --- |
| `full-release.log` | `5263d3e02a6bd1569f201e268ef80e90361069eb45f2b98361feef664700e4e8` |
| `independent-after.log` | `98566e3b0f8ddd392230312d4a93343c59922153eac8fd89fe88ef3a5e9815cd` |
| `acceptance/report.json` (original 40/42) | `404f6bebe95b892c59e4e5cf230365ecae98fd04580fa4a9e693ff8f49feab5c` |
| `acceptance-retry/report.json` (selected 2/2) | `e453cc15b644b7c7f8d8f2898a230d161c951658f017804fbc6b85832f8e3188` |
| release CLI | `45121b829e61788aa3a5f52e6e865c0c1e272d256533d3bc65d4f71a6ebeb0fb` |
| release embedded executable | `3b06a985486b13656c132bc094adc4bd1268a9b198845c38a9cc7eac28b4299b` |
| release root blackbox test executable | `36b91442de5d2fa90462b8f4d12b2acfb78c84471471ae185a64102e4e64f865` |
| release root whitebox test executable | `3e7c6d7e9273087e5ef0800fd675870a6c1f6254829e81674420f529fb976a22` |
| release examples blackbox test executable | `1eea6b9a25827e1d339d968acd407f7845bd710bcb39587dfa14e723583c177b` |
| committed CLI fixture JSON | `3611733218fd3acbcfbfcabe7eb174216d567e5eceb157ae68823d77e6a5141e` |
| committed CLI runner | `5c590f1d27a09db4c58328efa87467c2395898973c071bf1c4871f8d75899c00` |

## Linux packet and requested execution scope

Only local preparation occurred. No upload, SSH, Linux command, database access,
push, publication or tag was attempted. Do not reuse credentials or permissions
from another project. The parent task must arrange the host and authorization.

The reviewed packet is bound to `298f17dd5f6762c1e7e6a844015be859a84ea02a`:

| Local packet | SHA-256 / contents |
| --- | --- |
| `/tmp/moonjsonnet-spec-review.dyOCji/source-298f17d.tar` | `4265132ffa0de18480c1955242ee04f057dc4e5167b7082a33f956f8e8543670`; about 6.5 MiB; exact tracked source/tests/tools/docs and no Git history, untracked application, caches, binaries or credentials |
| `/tmp/moonjsonnet-spec-review.dyOCji/source-update-298f17d.bundle` | `cf7c2fcb96d0bfaecf1eb24b680a39babd1874a26fa26a689f47ba6a8da39719`; incremental committed updates, verified by git bundle verify |

The tar's Git commit header was checked. The bundle requires the exact project
baseline `8e661f9c1a418f87658c68dedc68615483513f86` already present in an isolated
project checkout; it is not a standalone full-history bundle. The source tar can
be reviewed/extracted independently, but the runner requires a real Git checkout.
The parent must explicitly arrange that baseline and import the incremental
bundle, then check out the exact target commit before running the verifier.

Proposed Linux scope after authorization: Linux AMD64, a dedicated non-root
identity/workspace, the same pinned Moon toolchain, serial commands with at most
two build jobs and lower scheduling priority. Run native deny-warn check, complete
debug and release tests, then tools/spec-acceptance.mbtx without case selection.
The latter builds the two executables and executes all P0/scenario checks. Capture
source status/commit, tool version, commands/exits, binaries, fixture/input hashes
and complete logs. Retain any failure; do not relax expectations for platform
differences. No fresh Go/C++ build, broad differential suite, ASan, dependency
upgrade, service restart or unrelated filesystem/database access is requested in
this first Linux scope. Those are separate later acceptance stages.

## Approval blocker and remaining work

The known function-length mismatch remains unchanged. Automatic approval review
rejected the attempted local commit containing that behavior change because it
did not recognize sufficient user approval. The command did not execute. The
candidate and its failing/passing tests are preserved as described in the
contract review, and all subsequent release/CLI validation used the original
required-only behavior. No workaround committed the rejected implementation.

The parent needs approval for the concrete change from required-only counting to
all declared parameters, including defaults for source/builtin functions. The
candidate patch SHA-256 is
`24ea8101f4e1ed65fb16358c2e8cd332d0faa3d07d6acbf2275a945e3d981708`;
the retained candidate test file SHA-256 is
`f2dc8893e68fc04376e85495f3451ffc1040321ff378448e384e94a1fd01977e`.
No action is currently running or has an uncertain outcome. The signature
conflict, complete P1 enumeration, Linux run and fresh upstream comparisons
remain pending; complete conformance is not accepted.
