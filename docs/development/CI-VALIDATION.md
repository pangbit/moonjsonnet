# Differential validation infrastructure

The C++ shared suite retains all 108 cases and the same 10 declared differences. This change corrects verification of existing declarations; it changes no product behavior, test input, reference outcome, threshold or exception policy.

The two fold cases declare MoonJsonnet Runtime errors from the literal `error 'unused'`. The validator now requires exit 1, empty stdout, an exact `RUNTIME ERROR: unused` first line and supported stack continuations. Other classes/messages, internal failures and arbitrary exceptions are rejected. The old location-style substring `: Runtime:` could neither recognize the current CLI nor validate its necessary message.

The fractional-format case keeps the existing exact C++ v0.21.0 output. MoonJsonnet's complete output is selected only for two proven native profiles: Linux/x86_64 and Darwin/arm64. Both reference and CLI binaries must match that host platform, and C++ must identify itself as v0.21.0 in a clean checkout of bbb38f1020be1f5aed560928fb839b2c448cefb4. Unsupported profiles and references fail closed.

`tests/reference/fractional-format-evidence.json` contains the exact complete Go/Moon outputs from the original 2026-10-09 archives. Go was 1.24.0, go-jsonnet v0.21.0 at 67968688d9952f50662e979fab1bef889d0d3e57. Linux source bc1d3c3 ends in 2039; macOS source a021c19 ends in 2003. The archived complete strings, source commits and archive SHA256 are also pinned in the validator; no current CI output, rounding tolerance or epsilon supplies a golden. Unredacted archives remain local; this compact synthetic-case evidence contains no environment identifiers.

Regression tests prove valid/invalid error classification, exact strings, unknown platform/reference rejection, native binary identity and altered-byte/provenance rejection. Run them with `moon test tools/differential.mbtx --deny-warn`; standalone tests do not execute the script main. CI runs these before the shared comparison and retains every existing later check.

Classification changes are explicit: Linux's seven recognized declarations become ten by recognizing fold-lazy, fold-empty and the existing architecture-bound fractional declaration. macOS's eight become ten by recognizing the two folds. Ordinary passed count remains 98, total remains 108, and skipped remains 0. None belongs to the separate 19 approved Go internal-reference-crash exceptions.

## Script dependency and platform constraints

The [CI workflow](../../.github/workflows/ci.yml) uses MoonBit
`0.10.14+7d59c7ec9` with `moonbitlang/async@0.22.4`. All `tools/*.mbtx`
imports from that module name the same version, including `fs` and `shell`.
The versioned script import syntax is documented in the
[Moon script guide](https://docs.moonbitlang.com/en/latest/toolchain/moon/script-mode.html).
Unversioned imports resolve the newest version in the local registry index;
`moon update` refreshes that index, not the explicit script version.

Both jobs in the [previous successful CI run](https://github.com/pangbit/moonjsonnet/actions/runs/38343391121)
used async 0.22.4 with this compiler. The
[first 0.2.0 candidate CI](https://github.com/pangbit/moonjsonnet/actions/runs/40456212952)
resolved async 0.22.5 and stopped before running tests: its `moon.pkg` field
`max_concurrent_tests` is unsupported by the pinned toolchain. The original
failure remains visible. No compiler upgrade, dependency-source edit or
skipped assertion is used to resolve it.

The cached 0.22.4 module manifest declares no external module dependencies;
its core imports use the installed SDK. Its registry archive checksum is
`2ffdb85cb229cfe9219161a7f2b959215a79a0d75b7e642cb346713f168a1457`.
The product module itself has no external runtime module dependency. This pin
therefore constrains the standalone validation dependency, not product behavior.

CI selects `ubuntu-24.04` for Linux/x86_64 and `macos-15` for Darwin/arm64 and
checks `uname` before validation. These match the two profiles admitted by the
fixed fractional-format evidence. Runner labels follow the
[GitHub hosted-runner reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners).
Runner-image revisions, system C toolchains, action major-version tags and the
MoonBit installer endpoint remain external inputs. This is a bounded dependency
and architecture constraint, not a claim of fully hermetic third-party inputs.
The C++ reference remains bound to its existing commit.

For an offline local check, first provision the exact dependency in the normal
cache, then use `moon check tools/differential.mbtx --frozen --deny-warn -j 1`.
A missing cache is a setup failure; do not substitute a newer dependency.
After a source change, CI must pass at the exact new commit before publication.
