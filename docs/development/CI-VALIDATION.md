# Differential validation infrastructure

The C++ shared suite retains all 108 cases and the same 10 declared differences. This change corrects verification of existing declarations; it changes no product behavior, test input, reference outcome, threshold or exception policy.

The two fold cases declare MoonJsonnet Runtime errors from the literal `error 'unused'`. The validator now requires exit 1, empty stdout, an exact `RUNTIME ERROR: unused` first line and supported stack continuations. Other classes/messages, internal failures and arbitrary exceptions are rejected. The old location-style substring `: Runtime:` could neither recognize the current CLI nor validate its necessary message.

The fractional-format case keeps the existing exact C++ v0.21.0 output. MoonJsonnet's complete output is selected only for two proven native profiles: Linux/x86_64 and Darwin/arm64. Both reference and CLI binaries must match that host platform, and C++ must identify itself as v0.21.0 in a clean checkout of bbb38f1020be1f5aed560928fb839b2c448cefb4. Unsupported profiles and references fail closed.

`tests/reference/fractional-format-evidence.json` contains the exact complete Go/Moon outputs from the original 2026-10-09 archives. Go was 1.24.0, go-jsonnet v0.21.0 at 67968688d9952f50662e979fab1bef889d0d3e57. Linux source bc1d3c3 ends in 2039; macOS source a021c19 ends in 2003. The archived complete strings, source commits and archive SHA256 are also pinned in the validator; no current CI output, rounding tolerance or epsilon supplies a golden. Unredacted archives remain local; this compact synthetic-case evidence contains no environment identifiers.

Regression tests prove valid/invalid error classification, exact strings, unknown platform/reference rejection, native binary identity and altered-byte/provenance rejection. Run them with `moon test tools/differential.mbtx --deny-warn`; standalone tests do not execute the script main. CI runs these before the shared comparison and retains every existing later check.

Classification changes are explicit: Linux's seven recognized declarations become ten by recognizing fold-lazy, fold-empty and the existing architecture-bound fractional declaration. macOS's eight become ten by recognizing the two folds. Ordinary passed count remains 98, total remains 108, and skipped remains 0. None belongs to the separate 19 approved Go internal-reference-crash exceptions.
