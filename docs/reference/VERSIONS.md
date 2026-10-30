# Version baseline

The development toolchain was updated on 2026-10-30. The Jsonnet references
remain fixed at the versions chosen before implementation on 2026-10-02:

| Component | Version / source |
| --- | --- |
| Moon / moonrun | 0.1.20261028, e1e1f15 |
| MoonBit compiler | v0.10.18+6c83a7f62, 2026-10-28 |
| Installer argument | `0.10.18+6c83a7f62` (compiler build ID, not Moon CLI version) |
| Language and standard-library compatibility baseline | Google Jsonnet v0.21.0 |
| Official reference interpreter | google/jsonnet, tag v0.21.0, commit bbb38f1020be1f5aed560928fb839b2c448cefb4 |
| Functional implementation reference | google/go-jsonnet, tag v0.21.0, commit 67968688d9952f50662e979fab1bef889d0d3e57 |
| Backend | native; POSIX file host (macOS and Linux) |
| Runtime dependencies | MoonBit core bundled with the toolchain; POSIX libc for file host and numeric text formatting |

Semantic sources: <https://jsonnet.org/ref/spec.html>,
<https://jsonnet.org/ref/language.html>, <https://jsonnet.org/ref/stdlib.html>.
These live pages can change; v0.21.0 source and behavior are the pinned
compatibility oracle. Reference source is a test dependency, never linked into
or invoked by the interpreter. The MoonBit implementation includes attributed
adaptations and embedded standard-library source; [NOTICE](../../NOTICE) identifies
their origins and licenses. Development fixtures include attributed upstream
inputs and are excluded from the published archive.

The 0.2.2 release and the historical reports below used Moon/moonrun
0.1.20260920 (914d7da) and MoonBit v0.10.14+7d59c7ec9. Those results do not
establish runtime acceptance on the new toolchain. The migration preserves the
Jsonnet fixtures and dependency versions; it adopts fenced script imports and
the new formatter's integer type names and default-parameter syntax. Generated
interfaces spell the existing 32-bit integer type as `Int32`; optional parameter
names and defaults are retained.

On 2026-10-30, native README/example tests passed 9/9 on both macOS ARM64 and
OrbStack Ubuntu 24.04 Linux AMD64. Each platform built the current release CLI
once and passed its version and configuration-input smoke checks. macOS also
passed the five differential-validator regression tests, the 31-case archive
consumer, and the documentation check (217 files, 1954 links). These are focused
toolchain-migration checks. The full test suite, fresh reference comparisons,
Linux archive consumer and hosted CI have not been rerun with the new compiler.

CI pins the installer argument and reference commit. Toolchain download archives
have an upstream retention policy; if the pinned build becomes unavailable,
refresh the toolchain baseline and rerun acceptance instead of silently falling
back to a newer compiler. Final macOS ARM64 and Linux AMD64 native debug/release
tests pass 330/330 in the recorded baseline. Both platforms completed pinned
Go 1.24.0 comparisons, related ASan checks and an independent archive consumer
(31/31). See the fixed [cross-platform report](https://github.com/pangbit/moonjsonnet/blob/c7f8a8e977e54ab7b0329c3069a7320a0eb81915/reports/GO-JSONNET-CROSS-PLATFORM-ACCEPTANCE.md)
for source, binary and fixture hashes. These historical results are not a claim
of new platform runs for subsequent documentation or packaging changes.

Raw whole-CLI results remain 1132/1150 on ARM64 and 1131/1150 on AMD64; raw
Evaluator and lint results remain 20/21 and 409/410. The recorded acceptance contract
uses 18 CLI plus 1 lint reference-crash exceptions, the optional
import_ast API while import_program remains strict, and same-architecture NaN
behavior. NaN succeeds on ARM64 and returns the same complete error output as Go
on AMD64; its frozen ARM64 success expectation is unchanged. No additional
exceptions were introduced. ASan leak detection was disabled. The historical C++ result
retains 98 compatible cases plus 10 declared differences out of 108; see
[compatibility](COMPATIBILITY.md#recorded-acceptance-boundary).

Design: parse into located expressions; resolve names statically; evaluate
lexical closures with memoized thunks; represent objects as ordered layers whose
fields are rebound to the final self. Manifest only visible fields into JSON.
Global evaluation helpers and `Program` methods create independent state.
An `Evaluator` retains its configured importer and import caches across calls;
its counters and reset rules follow the [API contract](API.md#reusable-evaluator).
