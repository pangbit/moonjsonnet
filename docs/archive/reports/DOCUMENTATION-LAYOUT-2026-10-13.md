# Documentation layout and language validation — 2026-10-13

The approved documentation cleanup is complete locally. Publication remains
paused. No push, publish, publish dry-run, login, credential change, version
change or history rewrite was performed in this task.

## Source and intended readers

- Starting source: `d6b9493ac55e37f70f3c49f68e85ce222278e22c`.
- Validated documentation commit: `58f9324340d14eca9b4e51e3a4bbde6093880ff1`.
- This report, its actual package manifest and archive-index entries are a
  subsequent documentation-only commit, excluded from the library archive.
- Module remains `pangbit/moonjsonnet` version `0.1.0`, Unreleased.
- The initial worktree was clean. Product packages and test-fixture locations
  were preserved; only two formatter documentation comments changed in `.mbt`.

Library adopters now have a separate [English overview](../../../README.mbt.md)
and [Chinese overview](../../../README.zh-CN.md). Both contain the same twelve
code blocks, feature scope and explicit compatibility counts. Detailed API and
CLI references remain canonical English documents; the Chinese overview does
not claim to translate every reference page. Historical Chinese reports retain
Chinese prose, including their translated privacy notices.

## Layout and migration

```text
README.md -> README.mbt.md
README.mbt.md                 English checked README and module readme target
README.zh-CN.md               Separate Chinese overview
LICENSE, NOTICE, licenses/    Original licensing and attribution
CHANGELOG.md, CONTRIBUTING.md, SECURITY.md, AGENTS.md
docs/
  README.md, README.zh-CN.md  Consumer indexes
  reference/                 Five English consumer reference documents
  development/               English maintenance and validation documentation
    zh-CN/                   Original requirements, parity plan, completion history
  archive/
    README.md, README.zh-CN.md
    reports/                 Historical Markdown, JSON and package manifests
```

The [documentation policy](../../development/DOCUMENTATION.md) defines the root
Markdown allowlist and file-language rules. The exact
[92-path migration map](../../development/documentation-migration-2026-10-13.tsv)
records these moves:

| Previous location | Current location |
| --- | --- |
| Root requirements document | `docs/development/zh-CN/REQUIREMENTS.md` |
| Five consumer documents directly under `docs/` | `docs/reference/` |
| VALIDATION, RELEASING and CI-VALIDATION | `docs/development/` |
| GO-PARITY and COMPLETION-CHECKLIST | `docs/development/zh-CN/` |
| 81 report/evidence files under `reports/` | `docs/archive/reports/` |

All current relative navigation and script references were updated. Historical
GitHub links pinned to old commits and original recorded package-manifest paths
remain unchanged because they describe those old snapshots. Twenty-eight broken
links to redacted local evidence in four reports became explicitly labeled,
non-clickable local-evidence references; no private evidence was uploaded or
invented. Public labels and redacted identifiers remain available.

## Official requirements and toolchain

The current official [module documentation](https://docs.moonbitlang.com/en/stable/toolchain/moon/module.html)
was checked for the readme path, SPDX license metadata, namespace/version rules
and `.moonignore` filtering. The official
[package guide](https://docs.moonbitlang.com/en/stable/toolchain/moon/package-manage-tour.html)
shows `README.mbt.md` with a `README.md` symlink and describes registry metadata
display. The [command documentation](https://docs.moonbitlang.com/en/stable/toolchain/moon/commands.html)
and installed `moon package --help` distinguish local packaging from publishing.

Actual toolchain: Moon `0.1.20260920` (`914d7da`), MoonBit
`v0.10.14+7d59c7ec9`, moonrun `0.1.20260920`; rr_moon_mod and rr_moon_pkg enabled.
The existing modern `moon.mod` was retained byte for byte, including
`readme = "README.mbt.md"`. Both README paths and the separate translation exist
inside the tested archive. This validates the local readme target and package
contents; no registry rendering or registry-installed consumer is claimed.

## Local checks

| Check | Result |
| --- | --- |
| Documentation checker before this report | 105 Markdown files, 499 local/current-source link targets, root allowlist and 92 migration targets passed |
| Final documentation check including this report and its index entries | 106 Markdown files and 508 local/current-source link targets passed |
| README translations | All 12 fenced code blocks identical; raw compatibility boundaries present in both |
| Existing documentation fences | All fenced content in 97 original documents unchanged |
| Historical numerical evidence | Every numeric and 40/64-character hexadecimal token sequence in 80 historical documents unchanged |
| Historical report data | Two JSON reports and the previous package manifest moved byte for byte |
| Native tests with warnings denied | 330/330 |
| Strict differential-validator tests | 5/5 |
| Independent archive consumer | 31/31 plus required-file, exclusion, documentation allowlist and relative-file-link checks |
| Verbatim README executable against the saved archive | Printed `{"answer":42}` followed by a newline |
| `moon info`, then `moon fmt`; `moon doc` | Exit 0; generated `.mbti` unchanged |
| Protected metadata, versions, C stubs, test fixtures, LICENSE, NOTICE and third-party licenses | Unchanged from starting source |
| Saved archive versus tested consumer extraction and committed source | Identical payload; all 170 entries checked |
| Bounded extracted-package privacy scan | No matching local user/home paths, private IPv4 patterns, redaction markers, private-key headers or common credential prefixes |

The new `tools/documentation.mbtx` is also wired into CI. It checks local file
destinations and current-main GitHub paths against the source checkout, plus
language-mixing candidates outside code, README parity and migration targets.
The final report and updated indexes are checked again before their commit.
The heuristic does not prove translation quality or all possible Markdown
anchor syntax; the changed prose and navigation were reviewed separately.

Initial temporary migration helpers needed StringView/argument-label corrections
before they could run. The first documentation check also exposed the existing
redacted links and an English document's mistakenly translated footer; those
issues were corrected, then the check passed. Attempt logs remain local.

## Final local package

| Item | Value |
| --- | --- |
| Filename | `pangbit-moonjsonnet-0.1.0.zip` |
| ZIP SHA-256 | `d092cef2f3946be3dca8d55d9903785b0e59a1b3f8a077022f1c2394e0c24856` |
| Size | 319787 bytes; 969236 bytes uncompressed |
| Entries | 170 files |
| Actual manifest | [ZIP entry order](documentation-package-2026-10-13.txt) |
| Manifest SHA-256 | `0ff695efcbdd74ff28cca97edd4ec390c5032499cc1f31334c21f6f27b5644d0` |

The archive contains both README languages, two consumer indexes, five reference
documents, licenses, interfaces and all three required native C stubs.
Requirements, plans, development procedures, historical reports, tools, tests
and examples are excluded. Separate ZIP builds may differ as containers; the
recorded SHA identifies this saved archive only.

## Preserved boundaries and remaining work

The C++ boundary remains 108 = 98 compatible + 10 declared differences. Raw Go
results remain CLI ARM64 1132/1150 and AMD64 1131/1150, reusable evaluator 20/21
and lint 409/410. The existing 18 CLI plus one lint reference-crash exceptions,
separately tested optional import_ast API and same-architecture NaN contract
remain unchanged. No failure was removed or converted to a pass by translation.

The preceding [dual-platform CI](https://github.com/pangbit/moonjsonnet/actions/runs/38340214206)
belongs to the starting d6b9493 source. This documentation commit has not been
pushed, so its new CI step has not run remotely. Linux, release-mode, complete
Go/C++ differential, upstream/integration and ASan suites were not rerun for
this documentation-only task. Their earlier evidence is not reassigned to this
commit. Newly reorganized current-main URLs become available remotely after a
separately authorized push; their local target files were verified here.

No local product or packaging blocker remains from the documentation cleanup.
Any push, remote CI verification and Mooncakes publication still require the
separate authorization appropriate to those actions. Registry access, version
availability and post-publication consumer checks were not performed in this task.
