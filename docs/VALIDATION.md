# Reproduce validation locally

Use the toolchain in [VERSIONS](VERSIONS.md). Run from the repository root:

```sh
moon check --target native --deny-warn
moon test --target native --deny-warn
moon test --target native --release --deny-warn
moon info
moon fmt
moon fmt --check
moon doc
moon build --target native --release --deny-warn
```

Reference interpreter (development only; not a runtime dependency):

```sh
git clone --depth 1 --branch v0.21.0 https://github.com/google/jsonnet.git /tmp/jsonnet-v0.21.0
git -C /tmp/jsonnet-v0.21.0 rev-parse HEAD
make -C /tmp/jsonnet-v0.21.0 -j4 jsonnet
moon run tools/differential.mbtx /tmp/jsonnet-v0.21.0/jsonnet _build/native/release/build/cmd/main/main.exe
moon run tools/upstream-language.mbtx /tmp/jsonnet-v0.21.0 _build/native/release/build/cmd/main/main.exe
moon run tools/integration.mbtx _build/native/release/build/cmd/main/main.exe
moon run tools/consumer.mbtx
```

Verify reference SHA `bbb38f1020be1f5aed560928fb839b2c448cefb4`.
The differential runner checks reference version and keeps every fixture,
comparing parsed JSON for success cases and failures for error cases. It records
per-case outcomes, counts, reference version and source commit in
`_build/differential/report.json`. `unsupported-reference-error` distinguishes a
function the pinned C++ reference itself rejects. Structured local error-category
checks are covered by the library and host integration suites.

Run the same corpus against the pinned Go implementation separately:

```sh
git clone --depth 1 --branch v0.21.0 https://github.com/google/go-jsonnet.git /tmp/go-jsonnet-v0.21.0
git -C /tmp/go-jsonnet-v0.21.0 rev-parse HEAD
go -C /tmp/go-jsonnet-v0.21.0 build -o /tmp/go-jsonnet-v0.21.0/jsonnet ./cmd/jsonnet
moon run tools/differential.mbtx /tmp/go-jsonnet-v0.21.0/jsonnet _build/native/release/build/cmd/main/main.exe
```

The Go run includes the shared `tests/differential.json` corpus plus Go-specific
cases in `tests/go-differential.json`. C++ continues to run the original shared
corpus: its pass count does not cover the Go-specific cases. The
`makeArray` contract differences are listed in [compatibility](COMPATIBILITY.md).

The runner checks Go binary build metadata for commit
`67968688d9952f50662e979fab1bef889d0d3e57` and an unmodified checkout. Build the
binary before writing other files into that checkout. Go results are written to
`_build/go-differential/report.json`, preserving the C++ report. Both reports
include binary SHA-256 hashes, source commit/dirty state and per-case outputs.
Passed, failed, unsupported and `reference_differences` counts are disjoint; `error_cases` overlaps the
tested cases. Unsupported checks with an unexpected outcome count as failures.
The `go_expect` fixture field only records reference-specific expectations.
Undeclared behavioral differences remain
failures and the runner exits nonzero; an upstream internal error is never an
expected-error pass. Go compatibility is not yet a passing CI gate.

Ten shared cases deliberately follow the Go contracts for function arity,
`foldl`, indexing, bitwise operators, manifest numbers and fractional format
precision and SHA-256 support, which differ from C++. Their
`cpp_difference` entries assert reference JSON or the C++ error class and
MoonJsonnet JSON or structured error category. They are
reported as `reference-difference`, with `passed=false`, and are not skipped or
counted as compatible. Any changed outcome, missing error or unexpected
convergence fails the check. This lets the C++ regression gate retain all inputs
while checking the documented Go migration; undeclared mismatches still fail.
See the [object standard-library report](../reports/GO-JSONNET-OBJECTS.md) for current
commit-bound results and the retained differences. The earlier
[sets and merge patch report](../reports/GO-JSONNET-SETS.md),
[overall parity baseline](../reports/GO-JSONNET-PARITY-BASELINE.md),
[stable sort report](../reports/GO-JSONNET-SORT.md),
[sequence combinator report](../reports/GO-JSONNET-COMBINATORS.md),
[fractional format report](../reports/GO-JSONNET-FORMAT.md),
[manifest number report](../reports/GO-JSONNET-MANIFEST.md),
[numeric alignment report](../reports/GO-JSONNET-NUMERIC.md),
[function-contract report](../reports/GO-JSONNET-CONTRACTS.md) and
[sequence-function report](../reports/GO-JSONNET-PROGRESS.md) remain historical baselines.

The upstream language runner verifies the exact reference commit, runs 32
language fixture files, separately evaluates the upstream formatting assertions,
and checks parser/static/function error fixtures. It preserves upstream inputs;
the isolated formatting expressions retain their original source line numbers
in report names. The `setInter` and `mergePatch` dependencies are now implemented;
all 303 selected cases pass. Any unsupported dependency now fails the check. The report
is written to `_build/upstream-language/report.json`.

Run ASan **after committing source**, because its isolated checkout copies only
tracked files. It copies the installed runtime to a temporary directory, disables
mimalloc in that copy, instruments native code/stubs, and runs tests plus the host
integration suite. It does not modify the installed MoonBit toolchain.

```sh
moon run tools/asan.mbtx
```

Leak detection is disabled for portability with Apple Clang; this check covers
address errors, not a LeakSanitizer proof. Test scripts use MoonBit script mode
and `moonbitlang/async`; commands may need access to Moon's dependency cache.
`tools/consumer.mbtx` extracts the actual Mooncakes archive into a temporary
workspace and compiles/tests a separate module using only public APIs.
It also verifies that the archive includes `NOTICE` and the Go BSD attribution
required by the adapted fractional format power implementation, plus the bundled
Jsonnet standard-library source. Its independent consumer executes `std.set`.

See the repository's `reports/` directory for commit-bound acceptance evidence.
Generated raw artifacts remain in `_build` and are not published to Mooncakes.

The [overall parity plan](GO-PARITY.md) tracks capabilities outside the existing
behavioral corpus. `tools/parity.mbtx` compares all 163 reflected Go standard-library
members against a frozen reference snapshot and the local CLI, writing
`_build/parity/report.json`. It records registration gaps, not behavioral passes;
zero unsupported cases in the smaller differential corpus does not imply full parity.
