# P0 stage evidence, 2026-10-22

This is a local macOS ARM64 stage report, not full conformance acceptance.
The [acceptance contract and focused matrix](SPEC-CONFORMANCE.md) identify the
fixed normative sources, tests and remaining work. All regression inputs are
synthetic. No private application content is included.

## Source and environment

- Initial source: `8e661f9c1a418f87658c68dedc68615483513f86`.
- Final source/documentation: `4192f157d2c374eb9ff7b5e42dea2f5f681bf421`.
- Product fixes: `001679a`, `dd3b9d0`, `ece4ff1`, `069b9de`.
- Program/archive regression follow-up: `09d7488`.
- Platform: `Darwin arm64`.
- Moon: `0.1.20260920`, commit `914d7da`.
- Moonc: `v0.10.14+7d59c7ec9`, dated 2026-09-18.
- Dependencies, toolchain, module version and generated public interfaces are unchanged.
- Tests ran before the source/documentation commit. The committed MoonBit source,
  tests and package configuration match those tested inputs; the documentation
  commit does not change `.mbt`, `.mbti`, `moon.mod` or `moon.pkg` from `09d7488`.
  README prose edits were already present during validation.
- The pre-existing untracked application file was preserved and excluded from
  every commit. No push, tag, publication, Linux upload or database access occurred.

## Executed results

| Check | Actual result | Local log |
| --- | --- | --- |
| New six normative groups before product changes | 1 passed, 5 failed | `/tmp/moonjsonnet-spec-p0.YGGswy/before.log` |
| Removal and affected sequences | 18/18 passed | `/tmp/moonjsonnet-spec-p0.YGGswy/remove-after.log` |
| Aggregate, JSON guards and affected consumers | 27/27 passed | `/tmp/moonjsonnet-spec-p0.YGGswy/aggregate-after.log` |
| Index/slice and affected sequences | 24/24 passed | `/tmp/moonjsonnet-spec-p0.YGGswy/index-after.log` |
| YAML and affected output paths | 18/18 passed | `/tmp/moonjsonnet-spec-p0.YGGswy/yaml-after.log` |
| First expanded native debug suite | 334/336 passed; two old mutation expectations failed | `/tmp/moonjsonnet-spec-p0.YGGswy/native-debug.log` |
| Full native debug after those expectations were corrected | 336/336 passed | `/tmp/moonjsonnet-spec-p0.YGGswy/native-debug-final.log` |
| Focused normative native release suite | 8/8 passed | `/tmp/moonjsonnet-spec-p0.YGGswy/spec-release.log` |
| Extracted local archive consumer | 31/31 passed | `/tmp/moonjsonnet-spec-p0.YGGswy/consumer.log` |
| Documentation | 107 files, 530 links passed | `/tmp/moonjsonnet-spec-p0.YGGswy/documentation.log` |
| Native check with deny-warn, moon info, moon fmt and fmt --check | Passed; no public interface diff | Terminal output |

The affected suites overlap. Their counts must not be summed. The release check
selected the six `spec_*test.mbt` / `spec_*wbtest.mbt` files below; it was not a
full release-suite run. Consumer packaging was local only.

The before log demonstrates original-array mutation, successful aggregate
overflow, fractional index truncation, successful partial YAML, and demanded
fractional slice truncation. The lazy-boundary group already passed. Fixes now
preserve those lazy boundaries, check each aggregate addition immediately, reject
fractional indices before conversion, defer array-slice index checks, and
propagate YAML errors. No snapshots were refreshed to hide failures.

## SHA-256 bindings

Paths for test binaries are relative to the repository. They are generated local
artifacts, excluded from Git. These hashes identify the actual artifacts inspected
for this stage, not a guarantee that a fresh build is byte-identical.

| Binary/archive | SHA-256 |
| --- | --- |
| `_build/native/debug/test/moonjsonnet.blackbox_test.exe` | `a967d434441738046843f0763d454473db21d482810f520d00a9857ea4d886dd` |
| `_build/native/debug/test/moonjsonnet.whitebox_test.exe` | `029a6356bdbd799448760b5360b0d15edb5fd26d44f1bf1acedee03fa7f6b573` |
| `_build/native/release/test/moonjsonnet.blackbox_test.exe` | `9a2636735eddbcb1d0da41a365c9a95786ac3c0daf1f2de424e1ccad40196ed3` |
| `_build/native/release/test/moonjsonnet.whitebox_test.exe` | `3e7c6d7e9273087e5ef0800fd675870a6c1f6254829e81674420f529fb976a22` |
| `_build/publish/pangbit-moonjsonnet-0.1.0.zip` | `8afb24fae550e297c77bd540a6a77cb36ab1dec9db2d8abe4533e3c2f71cb178` |

| Normative regression input file | SHA-256 |
| --- | --- |
| `spec_remove_test.mbt` | `94b514e9ba69c2b5ad55f8c8e020ec7ab44ceac495150b9cd7020cbdea37c75c` |
| `spec_aggregate_test.mbt` | `ba202765fb4669f805d00b087666df00be4ff3f128bd2f98bc8451bdd9b8f50c` |
| `spec_index_test.mbt` | `8082f3d1253b242b9e6b4fd6f1397275fe1f5732c8ae62f922fc2c32963b2b67` |
| `spec_yaml_test.mbt` | `f3e780945664c28724177b15d5f8540ff668526218e1b6ab0c55b468c2bb280d` |
| `spec_manifest_wbtest.mbt` | `efca143dad93275761ad4ab60a9dfd45116fdec7c809e4fd35001fc9235c81f7` |
| `spec_yaml_wbtest.mbt` | `a9d65846e43f8cb06e783f6138fde5f1afd3e8da1a8cc2f0b4a74441f1141dba` |

| Log (under the temporary evidence directory above) | SHA-256 |
| --- | --- |
| `before.log` | `007fc185681075461aa34914b7235cff126160dbe507f245ea2e0dd9ec9a57c1` |
| `native-debug-final.log` | `7ba365c64c0585816748796b60c836b6bc670484dfc503ad1b7e6c3ee69223de` |
| `spec-release.log` | `764157e72b2dd2e8e0a0545e7f821c609e694e542766a3c5c6666f28561c5f05` |
| `consumer.log` | `df593bea23338bbd5b02908b70e2a53334a607a622244123c8a320ca101ff952` |
| `documentation.log` | `6f749bccfb5fb27a67c1d4fc16390f89c1281d84bea123daeae0b1e94a80b2c4` |

Temporary logs are available in the current execution environment and should be
archived separately if durable raw evidence is required. Original upstream JSON
fixtures, historical reports and the prior audit results were not modified.

## Remaining work and access status

No operation is currently denied, pending approval or uncertain. Moon cache and
Git metadata writes initially hit sandbox restrictions; the scoped escalations
succeeded. No blocked action was bypassed.

Full release, CLI/application scenario runs, Linux AMD64, complete language/public
stdlib enumeration and fresh fixed Go/C++ comparisons remain unexecuted for this
source. The `removeAt` parameter-name conflict and function-length contract are
unresolved. Top-level assertions and the distinct std.manifestJson path were
preserved. A source-bound final cross-platform acceptance claim is therefore
still pending; Linux host/scope authorization belongs to the parent task.
