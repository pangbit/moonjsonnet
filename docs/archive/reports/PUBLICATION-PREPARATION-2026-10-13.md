# Publication preparation — 2026-10-13

The three approved preparation fixes are complete. Local package readiness is
**GO within the documented native compatibility boundary**. Actual publication
remains conditional on separate authorization, current registry checks and CI
for the final pushed source. No publish command (including publish dry-run),
login, credential change, push, version change or history rewrite was performed.

## Source and scope

- Starting source: `c7f8a8e977e54ab7b0329c3069a7320a0eb81915` on `main`.
- Validated preparation commit: `25022af83ebf355fa959b93a25011bc9097c095a`.
- Module: `pangbit/moonjsonnet`, version `0.1.0`, still Unreleased.
- Toolchain: Moon `0.1.20260920` (`914d7da`), MoonBit
  `v0.10.14+7d59c7ec9`; native macOS ARM64 for this local validation.
- The report and manifest are a subsequent report-only commit and are excluded
  from the package. The starting worktree was clean; no user edits were removed.

The implementation diff contains only comments and blank lines: 324 added or
removed lines across 37 `.mbt` files. Module/package metadata, native C stubs,
generated interfaces and existing test fixtures are unchanged. The only executable
tool change strengthens the development-only archive consumer checks.

## Completed fixes

1. Added source and local modification notices to applicable parser, evaluator,
   diagnostics, lint, formatter and YAML adaptation files. The 35 go-jsonnet
   mappings were checked against actual source at fixed revision
   `67968688d9952f50662e979fab1bef889d0d3e57`, retaining file copyright lines where
   present and the existing NOTICE attribution where absent. The downloaded
   codeload archive SHA-256 is
   `784d1e9756129c7e85aa34a7a1f0e6c9ebd6b0494636e290d9a515b5db62d9ce`.
   Two YAML paths identify their local modifications and distinct MIT/Apache
   origins. Rune quoting retains its Go BSD attribution. NOTICE now names the
   current quote files and the additional numeric adaptation files. Independently
   implemented raw-tree files were not assigned an upstream copyright.
2. Corrected stale descriptions of standard-library registration, Jsonnet external
   code, reusable evaluators, AST/formatter APIs, binding locations, diagnostics,
   CLI serialization and ARM64/AMD64 numeric conversion. Added a minimal executable
   example. Repository-only documentation links now use GitHub URLs; bounded
   historical compatibility evidence is linked at the starting source revision.
3. Restricted package `docs/` to API, CLI, COMPATIBILITY, VERSIONS and
   GO-STDLIB-SURFACE. CONTRIBUTING and development process documents now join
   tests, tools, reports and examples outside the archive. Historical records
   remain in the repository. All licenses, three C stubs and consumer interfaces
   remain present. The consumer script checks required files, excluded paths,
   the documentation allowlist and local Markdown link destinations.

## Final local archive

| Item | Actual value |
| --- | --- |
| Filename | `pangbit-moonjsonnet-0.1.0.zip` |
| SHA-256 | `cc8caf2c0ac63cfaa86d606ca9c3a47b7c8845c087f98c4404360cdebbad596b` |
| ZIP bytes | 313598 |
| Entries | 167 files |
| Uncompressed bytes | 956031 |
| Manifest | [Actual archive entry order](publication-package-2026-10-13.txt) |
| Manifest SHA-256 | `a0075deb7c8864a45ad402767815655c8a15e306dfb1510a032fa9563cddc784` |

All 167 extracted files were compared byte for byte with the preparation commit.
The saved ZIP's extracted contents also match the independent 31-test consumer's
package. This binds the tests to the saved payload; it does not claim that two ZIP
creations necessarily produce the same ZIP bytes.

The previous audit archive contained 173 files. The six removed entries are
CONTRIBUTING.md and docs/CI-VALIDATION.md, docs/COMPLETION-CHECKLIST.md,
docs/GO-PARITY.md, docs/RELEASING.md and docs/VALIDATION.md.

## Validation performed

| Command or check | Result |
| --- | --- |
| `moon check --target native --deny-warn` | Exit 0 |
| `moon test --target native --deny-warn` | 330/330 |
| `moon test tools/differential.mbtx --deny-warn` | 5/5 validator tests; does not run the differential suite |
| `moon run tools/consumer.mbtx` | 31/31, plus required-file, exclusion, docs allowlist and relative-link checks |
| `moon package --list --frozen` | Exit 0; local ZIP and actual manifest inspected |
| README executable extracted verbatim from the archive and run with `moon run --target native .` | `{"answer":42}` plus newline |
| `moon info`, then `moon fmt` | Exit 0; final repeat had no work |
| `git diff --check` and generated-interface diff | Clean; no `.mbti` changes |
| Product diff and protected metadata/C/fixture comparison to starting source | Comment-only product changes; protected files unchanged |
| Saved payload versus consumer extraction and committed source | Identical file contents |

The first attempt at the strengthened consumer script stopped during compilation
on four StringView-to-String conversions in the new checks. Those conversions
were corrected; the subsequent full consumer run passed. Initial and successful
attempt logs are retained locally, rather than treating the first attempt as a pass.

The installed `moon package --help` and the
[official command documentation](https://docs.moonbitlang.com/en/stable/toolchain/moon/commands.html)
were checked before packaging. Local packaging is distinct from publication:
`moon publish --dry-run` may submit the package for server validation and was
not used. The
[module documentation](https://docs.moonbitlang.com/zh-cn/latest/toolchain/moon/module.html)
describes `.moonignore`; the actual ZIP is the evidence for the applied filters.

## Privacy and link scope

The extracted package was searched for local user/home paths, the local account
name, private IPv4 patterns, retained redaction markers, private-key headers,
common GitHub/AWS credential prefixes and credential-assignment fields. Both
searches returned no matching files (ripgrep exit 1), and the complete manifest
was reviewed. This is a bounded scan, not a proof that arbitrary secrets cannot
exist. Raw local logs and paths are not included in this report or the package.

Relative Markdown file destinations were checked against the extraction. Named
anchors added in this change were checked against the current headings. External
link availability and all possible Markdown syntax were not exhaustively tested.

## Preserved compatibility evidence and remaining release work

No reference fixtures, failure classifications or accepted exceptions changed.
The fixed [cross-platform acceptance report](GO-JSONNET-CROSS-PLATFORM-ACCEPTANCE.md)
and [starting-source CI](https://github.com/pangbit/moonjsonnet/actions/runs/38244224273)
remain historical evidence, not new runs of the preparation commit.

- C++: 108 = 98 compatible + 10 declared differences, zero skipped.
- Go whole CLI: raw ARM64 1132/1150; AMD64 1131/1150.
- Go reusable evaluator: raw 20/21. Strict `import_program` remains strict;
  optional `import_ast` has separate 13/13 cases and 37 observations.
- Go lint: raw 409/410. The recorded acceptance contract retains 18 CLI plus
  one lint reference-crash exception; raw failures are not relabeled as passes.
- Same-architecture NaN behavior remains intentional. The AMD64 error matches
  Go but continues to fail the frozen ARM64 success expectation.
- Both-platform debug/release 330, upstream 303 and integration 97 are prior
  evidence. Release-mode, Linux, full Go, C++, upstream, integration and ASan
  suites were not rerun for this comments/documentation/packaging-only change.
  Prior ASan evidence had leak detection disabled.

Before a real release, obtain separate publication/push authorization, push the
reviewed commits and verify CI on that exact source. Recheck namespace access and
version availability at the registry. The earlier read-only audit reported the
`pangbit` account and a 404 module manifest; neither reserves `0.1.0` nor proves
that server-side publication validation will succeed. No registry-installed
consumer has been tested because no publication occurred. After an authorized
release, verify a fresh registry consumer and only then record publication and
tag/release results. These are outstanding release actions, not hidden product
fixes or a request to change the version now.
