# Version baseline

Fixed before implementation on 2026-10-02:

| Component | Version / source |
| --- | --- |
| Moon | 0.1.20260920, 914d7da |
| MoonBit compiler | v0.10.14+7d59c7ec9, 2026-09-18 |
| Installer argument | `0.10.14+7d59c7ec9` (compiler build ID, not Moon CLI version) |
| Language and standard-library compatibility baseline | Google Jsonnet v0.21.0 |
| Official reference interpreter | google/jsonnet, tag v0.21.0, commit bbb38f1020be1f5aed560928fb839b2c448cefb4 |
| Functional implementation reference | google/go-jsonnet, tag v0.21.0, commit 67968688d9952f50662e979fab1bef889d0d3e57 |
| Backend | native; POSIX file host (macOS and Linux) |
| Runtime dependencies | MoonBit core bundled with the toolchain; POSIX libc for file host and numeric text formatting |

Semantic sources: <https://jsonnet.org/ref/spec.html>,
<https://jsonnet.org/ref/language.html>, <https://jsonnet.org/ref/stdlib.html>.
These live pages can change; v0.21.0 source and behavior are the pinned
compatibility oracle. Reference source is a test dependency, never linked into
or invoked by the interpreter. The implementation and committed differential
inputs are original; `tools/upstream-language.mbtx` additionally executes the
Apache-2.0 upstream test fixtures from the external reference checkout.

CI pins the installer argument and reference commit. Toolchain download archives
have an upstream retention policy; if the pinned build becomes unavailable,
refresh the toolchain baseline and rerun acceptance instead of silently falling
back to a newer compiler. macOS arm64 and Linux x86_64 native debug/release
tests pass 315/315. Fresh pinned Go 1.24.0 Linux comparisons have been executed
before and after the architecture-specific numeric repair. The unchanged whole
CLI corpus still reports 1131/1150: the original 18 failures and one NaN index
fixture with an ARM64 success expectation and AMD64 error/path differences.
Targeted absolute-path comparisons do not replace that failure. See the
[SSH acceptance report](../reports/SSH-LINUX-ACCEPTANCE.md).
Related ASan acceptance at clean `daece32` also passed 315 native tests, host 97,
character 72, native errors 384, CLI 4095, API 1323 and 20 numeric inputs, with 417
copied source files verified. Leak detection remains disabled per the original
runner; the installed runtime hash is unchanged. The original 18+1+1 differences
and the additional frozen NaN fixture remain unaccepted.

Design: parse into located expressions; resolve names statically; evaluate
lexical closures with memoized thunks; represent objects as ordered layers whose
fields are rebound to the final self. Manifest only visible fields into JSON.
Each evaluation owns its caches, counters and importer; there is no global VM.
