# Documentation layout and language policy

## Root entry points

The root Markdown allowlist is `README.mbt.md`, its `README.md` symlink,
`README.zh-CN.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `SECURITY.md` and `AGENTS.md`.
Keep the original `LICENSE`, `NOTICE`, `licenses/`, MoonBit configuration, source,
tests and tool configuration in their appropriate locations. A documentation
cleanup must not relocate product packages or test fixtures.

`README.mbt.md` is the English entry and the `moon.mod` readme target. Its checked
MoonBit examples remain executable. `README.md` is the standard repository entry;
`README.zh-CN.md` is a separate Chinese translation with the same examples,
features and compatibility qualifications. Translation selectors are navigation,
not a second language appended to the same body.

## Directory ownership

| Location | Purpose | Packaged |
| --- | --- | --- |
| `docs/README*.md` | English and Chinese consumer indexes | Yes |
| `docs/reference/` | English API, CLI, compatibility, version and standard-library reference | Explicit five-file allowlist |
| `docs/development/` | English contribution, validation, release and documentation procedures | No |
| `docs/development/zh-CN/` | Chinese original requirements, parity plan and completion history | No |
| `docs/archive/` | Historical reports and original evidence data, indexed by language | No |
| `internal/yaml/README.md`, `licenses/` | Vendored-code provenance and original license texts | Yes |
| `examples/`, `tests/`, `tools/` | Development programs, fixtures and automation | No |

The [migration map](documentation-migration-2026-10-13.tsv) records every moved
path. Old package manifests and report JSON retain their original bytes, even
when their recorded paths refer to an older source layout. Absolute links pinned
to a historical Git commit also retain their original paths. Update current
navigation and script references when moving documentation.

## Language and evidence rules

Use one prose language per file. Code, commands, API identifiers, filenames,
quoted tool output and proper names retain their original spelling. Keep translated
pages separate, link corresponding pages and preserve technical scope. Detailed
references currently have one canonical English edition; do not imply that the
Chinese overview translates every API contract.

Historical Chinese reports keep Chinese prose, including their privacy notices.
Their counts, failure classifications, source identities and licensing facts
must not be weakened or silently replaced. In particular, preserve the ten C++
differences and the raw Go failure boundary. License texts remain unmodified.

Run `moon run tools/documentation.mbtx` to check the root allowlist, local Markdown
destinations, language-mixing candidates, README example parity and migration
targets. This is a bounded syntax/prose check with human review, not an automatic
proof of translation quality or external-link availability. Run the archive
consumer as well: repository-valid links may still point to files excluded from
the package.

## MoonBit packaging contract

The official [module reference](https://docs.moonbitlang.com/en/stable/toolchain/moon/module.html)
defines the readme path, metadata and `.moonignore` filtering. The official
[package guide](https://docs.moonbitlang.com/en/stable/toolchain/moon/package-manage-tour.html)
shows the checked README and symlink layout and explains registry metadata display.
The actual installed toolchain and `moon package --list --frozen` output determine
this project's tested archive. Do not migrate module formats, change versions or
run a publication command as part of documentation validation.
