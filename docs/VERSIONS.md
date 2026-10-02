# Version baseline

Fixed before implementation on 2026-10-02:

| Component | Version / source |
| --- | --- |
| Moon | 0.1.20260920, 914d7da |
| MoonBit compiler | v0.10.14+7d59c7ec9, 2026-09-18 |
| Installer argument | `0.10.14+7d59c7ec9` (compiler build ID, not Moon CLI version) |
| Language and standard-library compatibility baseline | Google Jsonnet v0.21.0 |
| Official reference interpreter | google/jsonnet, tag v0.21.0, commit bbb38f1020be1f5aed560928fb839b2c448cefb4 |
| Backend | native; POSIX file host (macOS and Linux) |
| Runtime dependencies | MoonBit core bundled with the toolchain; POSIX libc for file host and numeric text formatting |

Semantic sources: <https://jsonnet.org/ref/spec.html>,
<https://jsonnet.org/ref/language.html>, <https://jsonnet.org/ref/stdlib.html>.
These live pages can change; v0.21.0 source and behavior are the pinned
compatibility oracle. Reference source is a test dependency, never linked into
or invoked by the interpreter. The implementation and test inputs are original.

CI pins the installer argument and reference commit. Toolchain download archives
have an upstream retention policy; if the pinned build becomes unavailable,
refresh the toolchain baseline and rerun acceptance instead of silently falling
back to a newer compiler. Only local macOS acceptance has been executed so far.

Design: parse into located expressions; resolve names statically; evaluate
lexical closures with memoized thunks; represent objects as ordered layers whose
fields are rebound to the final self. Manifest only visible fields into JSON.
Each evaluation owns its caches, counters and importer; there is no global VM.
