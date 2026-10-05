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

`program_test.mbt` checks parsing without execution, reuse with changed parameters,
callbacks and importers, all four output modes, error recovery, fixed source identity,
independent budgets and object/thunk state. The existing string APIs now use the
same parsed-program execution path. These local API tests establish the documented
fresh-state contract; they do not establish reusable Go VM cache-lifecycle parity.
The archive consumer also compiles and calls all four public `Program` methods.

`program_parameters_test.mbt` covers lazy `ext_programs`/`tla_programs`, duplicate
binding precedence, source identity, current execution budgets and recovery after
failure. The public file host is also exercised by the archive consumer. Run the
separate fixed Go API corpus after building the local probe:

```sh
moon build --target native --release --deny-warn
moon run tools/parameter-integration.mbtx _build/native/release/build/examples/parameter-probe/parameter-probe.exe /tmp/go-jsonnet-v0.21.0
```

The runner verifies the clean pinned reference checkout and builds the small
`tests/reference/parameters.go` API adapter with Go 1.24.0, using that module's
source, `GOWORK=off` and `GOPROXY=off`. It tests both adapters against the same
`tests/go-program-parameters.json` expectations: results, complete output-mode
strings, trace text, importer requests, native-call counts and selected diagnostic
fragments. It retains both complete process outputs, binary/adapter hashes and
build metadata in `_build/parameters/report.json`. These API cases are counted
separately from CLI differential cases; error fragments do not prove identical
diagnostic frames. Neither adapter is shipped in the Mooncakes archive. Omitting
the Go checkout runs the local expectations only and writes `local-report.json`;
ASan uses this mode in its isolated source copy, whose Git metadata is unavailable.

`evaluator_test.mbt` and `evaluator_wbtest.mbt` cover reusable interpreter
configuration, cache invalidation, failed-thunk retry, cached assertion errors,
per-execution budgets, reentry guards and stable arena slot counts across repeated
entries. The fixed Go lifecycle sequences use the same API-adapter approach:

```sh
moon run tools/evaluator-integration.mbtx _build/native/release/build/examples/evaluator-probe/evaluator-probe.exe /tmp/go-jsonnet-v0.21.0
```

`evaluator_imports_test.mbt` and its whitebox companion cover query/execution cache
sharing, nonexecution, raw invalid UTF-8 bytes, importer replacement, cached-source
and AST budgets, and reentry. The same sequence runner also exercises resolve,
raw data, imported programs and dependency queries.

`tests/go-evaluator.json` pins every evaluation/query value/error outcome, native-call
count, source-read count and trace messages with sink labels. The Go adapter's
importer caches immutable contents; source-read counts do not measure raw importer
callback invocations. Error fragments and full actual diagnostics are retained.
The report at `_build/evaluators/report.json` records sequence counts separately
from nested evaluation/query/error counts. Query errors use Go's ordinary error
text because these APIs return importer errors directly; runtime evaluation errors
still use its ErrorFormatter. The optional local-only mode is included in
ASan and writes `local-report.json`. These are VM API sequences, not additional
CLI-expression passes, and the arena checks do not establish RSS/leak bounds.
The current Go result is 20/21 sequences: failed-parse retry returns a successful
nil AST in Go v0.21.0, while MoonJsonnet continues to report the static error.
This remains a failing case; local-only expectations pass 21/21. See the
[import-query report](../reports/GO-JSONNET-IMPORT-QUERIES.md).

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

Go aggregate overflow can emit non-JSON scalar tokens. `raw-output` cases pin
exact `+Inf`, `-Inf` or `NaN` spellings for both processes with exit 0; they are
not passed to a JSON parser or omitted. The overlapping `raw_output_cases` count
identifies these inputs separately from ordinary JSON comparisons.

Run the same corpus against the pinned Go implementation separately:

```sh
git clone --depth 1 --branch v0.21.0 https://github.com/google/go-jsonnet.git /tmp/go-jsonnet-v0.21.0
git -C /tmp/go-jsonnet-v0.21.0 rev-parse HEAD
GOTOOLCHAIN=go1.24.0 go -C /tmp/go-jsonnet-v0.21.0 build -o /tmp/go-jsonnet-v0.21.0/jsonnet ./cmd/jsonnet
moon run tools/differential.mbtx /tmp/go-jsonnet-v0.21.0/jsonnet _build/native/release/build/cmd/main/main.exe
```

The Go run includes the shared `tests/differential.json` corpus plus Go-specific
cases in `tests/go-differential.json`, `tests/go-parameters.json`,
`tests/go-cli-input.json`, `tests/go-cli-output.json`, `tests/go-cli-multi.json`,
`tests/go-cli-imports.json`, `tests/go-cli-diagnostics.json` and
`tests/go-cli-stack.json`.
Fixtures can supply `args`, `files`, `env`, an
`input` mode (`file`, `exec` or `stdin`), literal `input_arg`, explicit `stdin`,
`cwd` and pinned JSON `result` or error diagnostic checks. The `<work>` marker
in fixture paths and environment values resolves to the runner's working directory;
fixture files can include nested directories. Reports
retain all inputs and outputs. C++ continues to run the original shared
corpus: its pass count does not cover the Go-specific cases. The
`makeArray` contract differences are listed in [compatibility](COMPATIBILITY.md).

`text-output` fixtures pin complete `stdout` bytes, including whitespace, Unicode,
NUL and newlines; they do not parse or trim output. They cover Go CLI JSON layout,
plain strings and YAML document streams. `text_output_cases` is an overlapping
count of these successful-output fixtures. Error cases also require empty stdout
on both processes, retaining the stream's evaluate-before-output contract.

File-output fixtures use independent `<out>` directories for the reference and
local program. `output_setup`, `output_directories` and `output_links` prepare
initial state; `output_files` pins each final file's complete contents or `null`
for absence. `file-output` also pins stdout, replacing only the generated root
with `<out>`. `io-error` pins exit 1, diagnostic fragments, partial stdout and
final files. Reports retain the fixture, both concrete argument lists and both
observed file maps. ENOTDIR below a regular file counts as absence; other host
observation errors still abort. The overlapping `file_output_cases` count
includes successful, evaluation-error and I/O-error file fixtures;
`io_error_cases` also overlaps `error_cases`. Output directories are reset before
each side, so reference-created files cannot mask local mkdir/write defects.
ENOTDIR-as-absence applies only to output observation; import lookup treats it
as a fatal I/O error, matching the pinned Go importer.

The host integration entrypoint also runs `tools/multi-integration.mbtx`. It
checks raw bytes, directory creation, partial failures and budgets, then compares
mtime/inode after pinning a past timestamp to prove identical content is not
rewritten. No timing sleep is used. The existing-file comparison is exercised
at zero length and around 4096-byte boundaries, including unchanged and changed files.

It also runs `tools/import-integration.mbtx`, covering library priority, root
policy, absolute paths, symlinks, permissions, UTF-8/binary data and import limits.
Library fixtures retain successful and failing candidates; API regressions
mutate files between calls to verify positive/negative host-cache stability and
fresh-host behavior. The archive consumer calls `jpaths` and entry `load` from
the actual packaged module, including its executable documentation.

`tools/diagnostic-integration.mbtx` checks context cropping through file/anonymous
inputs, nested imports and output modes, preserving prior output files, trace
messages and evaluation budgets. Diagnostic fixtures can separately pin complete
`reference_stderr` and `moonjsonnet_stderr`; the runner stores `stderr_fixture`
alongside both actual outputs. Matching each program's own fixed expectation
does not establish equal diagnostic text or frame sets. Those gaps remain in the
overall parity inventory; ordinary error-outcome pass counts are not byte-parity counts.

`tests/go-cli-stack.json` pins runtime-frame thresholds from the fixed Go
reference, including normal/strict calls, lazy values, object assertions/addition,
manifestation, ready string versus code TLAs and CLI integer boundaries.
`tools/stack-integration.mbtx` checks imports, preserved output files and absent
multi directories on exhaustion, independent step/depth limits and trace cropping.
It is included in the main integration and isolated ASan runs. Passing these
cases does not prove every standard-library implementation uses identical frames.

Static dependency scanning has a separate corpus and reference executable:

```sh
GOTOOLCHAIN=go1.24.0 go -C /tmp/go-jsonnet-v0.21.0 build -o /tmp/jsonnet-deps-v0.21.0 ./cmd/jsonnet-deps
moon build --target native --release cmd/deps
moon run tools/dependency-integration.mbtx _build/native/release/build/cmd/deps/deps.exe /tmp/jsonnet-deps-v0.21.0
```

The runner checks version/build metadata and freezes expected results in
`tests/go-dependencies.json`. Each fixture compares complete stdout and checks
an independent `-o` output file on both programs, including preservation after
scan failure and truncation on successful empty results. It retains full inputs,
outputs, file contents, source identity and binary hashes in
`_build/dependencies/report.json`. These tool cases are separate from interpreter
expression parity. Omitting the reference argument runs the local integration
checks, also invoked by the isolated ASan script after building `cmd/deps`.

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
Trace fixtures additionally compare exact stderr on success and the exact trace
prefix before an error diagnostic. Both programs receive the same absolute
input path for these cases; relative/alias diagnostic-path parity is not implied.

See the [reusable-evaluator report](../reports/GO-JSONNET-EVALUATOR.md) for current
commit-bound results and the retained differences. The earlier
[AST-parameter report](../reports/GO-JSONNET-PROGRAM-PARAMETERS.md),
[parsed-program report](../reports/GO-JSONNET-PROGRAM.md),
[dependency-scan report](../reports/GO-JSONNET-DEPENDENCIES.md),
[runtime-frame report](../reports/GO-JSONNET-STACK.md),
[diagnostic report](../reports/GO-JSONNET-DIAGNOSTICS.md),
[import-search report](../reports/GO-JSONNET-IMPORT-SEARCH.md),
[multi-output report](../reports/GO-JSONNET-MULTI-OUTPUT.md),
[CLI output report](../reports/GO-JSONNET-CLI-OUTPUT.md),
[CLI input report](../reports/GO-JSONNET-CLI-INPUT.md),
[parameter report](../reports/GO-JSONNET-PARAMETERS.md),
[YAML parsing report](../reports/GO-JSONNET-PARSE-YAML.md),
[native and trace report](../reports/GO-JSONNET-NATIVE-TRACE.md),
[digest report](../reports/GO-JSONNET-DIGESTS.md),
[TOML and YAML output report](../reports/GO-JSONNET-TOML-YAML.md),
[deletion and internal object merge report](../reports/GO-JSONNET-REMOVE.md),
[JSON, Python, INI and XML output report](../reports/GO-JSONNET-OUTPUT.md),
[UTF-8 and Base64 report](../reports/GO-JSONNET-ENCODING.md),
[string and Unicode report](../reports/GO-JSONNET-STRINGS.md),
[math and boolean report](../reports/GO-JSONNET-MATH.md),
[aggregation and non-finite values report](../reports/GO-JSONNET-AGGREGATES.md),
[array combinator and extrema report](../reports/GO-JSONNET-ARRAYS.md),
[object standard-library report](../reports/GO-JSONNET-OBJECTS.md),
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
address errors, not a LeakSanitizer proof. The script sets ASan `exitcode=99` for
tests, both CLI integration suites and the parameter/evaluator API probes so a sanitizer
failure cannot satisfy an expected application-error exit code. Test scripts use MoonBit script mode
and `moonbitlang/async`; commands may need access to Moon's dependency cache.
`tools/consumer.mbtx` extracts the actual Mooncakes archive into a temporary
workspace and compiles/tests a separate module using only public APIs.
It also verifies that the archive includes `NOTICE`, Go BSD attribution and
the inherited Cephes/Sun math notices, plus the bundled Jsonnet standard-library
source and the generated Unicode fold table. Its independent consumer executes
`std.set`, Unicode `std.equalsIgnoreCase`, Base64 encoding and malformed UTF-8
replacement.

Unicode simple folding is generated from Go 1.24.0's Unicode 15.0.0 tables.
`tools/embed-unicode.mbtx` verifies the pinned source SHA-256 before writing the
runtime map and 2,880 test pairs. To reproduce, download the exact source from
`https://raw.githubusercontent.com/golang/go/go1.24.0/src/unicode/tables.go`, run
`moon run tools/embed-unicode.mbtx PATH_TO_TABLES_GO`, then `moon fmt`.
The Go differential suite evaluates every generated pair on both interpreters;
separate fixtures cover non-equivalent characters and multi-character folding.

See the repository's `reports/` directory for commit-bound acceptance evidence.
Generated raw artifacts remain in `_build` and are not published to Mooncakes.

The [overall parity plan](GO-PARITY.md) tracks capabilities outside the existing
behavioral corpus. `tools/parity.mbtx` compares all 163 reflected Go standard-library
members against a frozen reference snapshot and the local CLI, writing
`_build/parity/report.json`. It records registration gaps, not behavioral passes;
zero unsupported cases in the smaller differential corpus does not imply full parity.
