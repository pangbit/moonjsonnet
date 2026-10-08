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

`ast_test.mbt` and `ast_cache_test.mbt` exercise all semantic node forms, scope
and shape rejection, cycle/depth/node budgets, edits and copy isolation from
Program and imported caches. The separate AST corpus compares parsed/cloned and
edited trees using the public Go AST/VM APIs:

```sh
moon run tools/ast-integration.mbtx _build/native/release/build/examples/ast-probe/ast-probe.exe /tmp/go-jsonnet-v0.21.0
```

It uses the same pinned checkout/build checks, writes `_build/ast/report.json`,
and supports local-only ASan validation via `local-report.json`. Current AST
results are 173/173, including 37 Go-derived coordinate cases for UTF-8 byte columns,
exclusive ends, parentheses, synthetic nodes and nested tailstrict, and 18 string
escape/surrogate value cases, 23 numeric spelling/range/deferred conversion cases,
16 local-binding range cases, 16 parameter-range cases and 15 repeated-parameter
evaluation cases, plus 28 raw-parsing/source-retention cases. The latter use
Go formatter.SnippetToRawAST for acceptance/errors and check exact local source
reconstruction; they do not compare formatter output or Go Fodder layout. Public range
validation and round trips are also covered by `source_range_test.mbt` and the
archive consumer. These are independently counted from parameters, Evaluator
sequences and CLI cases. ParsedSource retains lexical comments and spelling, but
formatting and complete raw AST metadata remain outside this evidence. See the
[source-retention report](../reports/GO-JSONNET-SOURCE-FIDELITY.md),
[source-range report](../reports/GO-JSONNET-SOURCE-RANGES.md)
and historical [AST report](../reports/GO-JSONNET-AST.md).

`lint_test.mbt` checks lexical scopes, unused bindings, eager cycles, nonexecution,
import traversal, limits and a 2,000-binding cycle. The full pinned upstream lint
corpus is frozen in `tests/go-lint.json`, including shared imported source files:

```sh
moon run tools/lint-integration.mbtx _build/native/release/build/examples/lint-probe/lint-probe.exe /tmp/go-jsonnet-v0.21.0
moon run tools/lint-cli.mbtx _build/native/release/build/cmd/lint/lint.exe /tmp/go-jsonnet-v0.21.0
```

The API runner compares complete ordered diagnostic messages and found flags,
retains full diagnostics, pins Go checkout/build metadata, and writes
`_build/lint/report.json`. Current results are 409/410 (62 upstream, 19 original
focused, 33 type/boundary, 50 lowering/multiple-entry, 56 parser, 62 lexical,
59 string, 21 numeric, 20 binding-location, 20 repeated-parameter and 8 duplicate-declaration inputs). The
previous 35 missing type diagnoses and known parser-wording difference now pass.
One failure remains: a reference panic on entry/import identity collision.
The unused binding location (`number-literal-8`) now matches the reference.
The runner counts reference panics separately while retaining them as failures
and exits 1. Earlier failure evidence remains documented. The 190 cases with frozen locations
also compare diagnostic start line/column against the frozen Go results; the
report counts these separately as `location_total` and `location_passed` (190/190). This
does not establish location/range parity for all diagnostics. CLI checks cover file/option/search/exit behavior
and four type-diagnostic categories, 23 checks per binary;
omitting the Go checkout checks the local CLI only, as used by ASan. ASan also
executes all local lint tests; the full Go API differential is a separate release
binary run. `lint_type_test.mbt` covers recursive graphs, arity, standard-library
declarations, budgets and Go string escaping. See the historical
[lint baseline](../reports/GO-JSONNET-LINT.md),
[lint type report](../reports/GO-JSONNET-LINT-TYPES.md),
[lowering report](../reports/GO-JSONNET-LINT-LOWERING.md),
[parser diagnostic report](../reports/GO-JSONNET-PARSER-DIAGNOSTICS.md),
[lexer diagnostic report](../reports/GO-JSONNET-LEXER-DIAGNOSTICS.md),
[string-literal report](../reports/GO-JSONNET-STRING-LITERALS.md),
[number-literal report](../reports/GO-JSONNET-NUMBER-LITERALS.md),
[binding-range report](../reports/GO-JSONNET-BINDING-RANGES.md),
[parameter-range report](../reports/GO-JSONNET-PARAMETER-RANGES.md), and current
[source-retention report](../reports/GO-JSONNET-SOURCE-FIDELITY.md).
The source-retention batch reran both CLI corpora and the language suite: Go
1132/1150 with the same 18 failed input names; C++ 98 passes plus 10 declared
differences and no failures; upstream language 303/303. These runs bind to
0e4892e with clean source state. Native debug/release each pass 224 tests;
the archive consumer passes 22 tests. See the batch report for isolated ASan evidence.

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
tests, both CLI integration suites and the parameter/evaluator/AST API probes so a sanitizer
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

Source formatting has a separate pinned Go corpus:

```sh
moon run tools/formatter-integration.mbtx _build/native/release/build/examples/formatter-probe/formatter-probe.exe ${LOCAL_PATH_012}
```

The runner validates exact frozen output, parse-error fragments, reparse success
and Go's idempotence behavior. It records both outputs and all failures in
`_build/formatter/report.json`; a nonzero exit is expected while differences remain.
The 2026-10-05 implementation `3cfaa54` passed 359/359 fixtures, including the six
previously retained differences. That historical native debug/release validation
passed 235/235, and the archive consumer passed 23/23. Its ASan run included the
formatter black-box tests, not the complete Go formatter differential corpus.
The historical upstream input survey passed 126/178, with 52 retained failures
(zero Go errors and three local probe errors):

```sh
moon run tools/upstream-formatter.mbtx _build/native/release/build/examples/formatter-probe/formatter-probe.exe ${LOCAL_PATH_012} ${LOCAL_PATH_006}
```

This tool pins both checkouts, uses C++ only as an input source, and compares
exact output and idempotence against Go. It retains every input and both outcomes
in `_build/upstream-formatter/report.json`, returning nonzero on differences.
See the [sort/strip report](../reports/GO-JSONNET-FORMATTER-SORT-STRIP.md)
for exact hashes, accepted checks and remaining work.

On 2026-10-08, clean implementation `30548ae8953ed85ef027d3bd1dfd23eaca67a6c0`
passes **402/402** frozen fixtures and **148/178** upstream inputs. Both tools
rebuilt and reran the pinned Go reference; their final reports record
`source_dirty=false`. Native debug/release tests each pass **240/240**. Checks,
release build, interface generation, formatting and documentation generation pass,
with no public interface changes. Every previously passing upstream input remains
passing across the four stages. The upstream runner still returns nonzero for
the **30 retained failures**, including two unchanged AST depth-limit errors.
The prior ASan, consumer and unrelated CLI/API/lint results were not rerun in
this batch. See the [continuation report](../reports/GO-JSONNET-FORMATTER-CONTINUATION.md)
for commits, hashes, the full failure list and depth analysis.

The next local continuation was validated before commit, based on `1c75ed8` with
uncommitted changes, passing
**504/504** frozen fixtures and **151/178** upstream inputs after rebuilding and
running pinned Go. Reports record `source_dirty=true`. All original 402 fixtures
are unchanged and pass; all previously passing 148 upstream inputs still pass.
Native debug/release tests each pass **243/243**, and checks, release build,
interface generation, formatting and documentation generation pass with no public
interface changes. The **27 retained failures** include the same two AST depth
errors. CLI/API/lint, ASan, consumer and cross-platform acceptance were not rerun.
See the [binary continuation and paragraph margin report](../reports/GO-JSONNET-FORMATTER-CONTINUATION2.md).

Clean implementation `ec27c1c23cc2a8537b9ca4c335c914b5cf419cc2` now passes
**608/608** frozen fixtures and **157/178** upstream inputs. Native debug/release
tests each pass **246/246**, with no public interface changes. The **21 retained
failures** include the same two AST depth errors. These reports bind the clean
implementation, while unrelated CLI/API/lint, ASan, consumer and platform results
retain their prior identities. See the [assertion and text-block report](../reports/GO-JSONNET-FORMATTER-CONTINUATION3.md).

Clean implementation `6f63a09692c4724dea86cac68f69930cf06d8779` passes
**736/736** frozen formatter fixtures and **176/178** upstream inputs, retaining
only two AST depth refusals. Native debug/release tests each pass **249/249**.
The full Go CLI differential remains **1132/1150**, retaining all 18 known
reference-crash differences. The archive consumer passes **23/23** and the isolated
ASan test/host integration suite passes. No public interfaces changed; full parity
and cross-platform acceptance remain incomplete. See the [expression indentation
and whole-suite report](../reports/GO-JSONNET-FORMATTER-CONTINUATION4.md).

Clean implementation `1681c77da4e95102ccfe9c77f1d2d844c91a59e2` exports ASTs
iteratively, passing native debug/release **251/251**, pinned Go AST **173/173**
and the isolated ASan test/host integration suite. Public admission budgets and
interfaces remain unchanged. See the [iterative export report](../reports/GO-JSONNET-AST-ITERATIVE-EXPORT.md).

See the repository's `reports/` directory for commit-bound acceptance evidence.
Clean implementation `824fd43f418b32340a4540b173eddacda5301c4c` adds explicit
independent syntax admission. The formatter probe now uses `format_syntax_source`
with default `SyntaxLimits`, passing **736/736** frozen and **178/178** upstream
inputs with zero Go/local errors. Native debug/release tests each pass **256/256**,
Go AST passes **173/173**, CLI retains **1132/1150** and the same 18 failures,
archive consumer passes **24/24**, and isolated ASan native/host checks pass.
Old evaluator/ParsedSource/format_source admission remains unchanged. See the
[independent syntax limits report](../reports/GO-JSONNET-SYNTAX-LIMITS.md).

Generated raw artifacts remain in `_build` and are not published to Mooncakes.
Clean implementation `63c6f00a6adfc6668827f37d2a5273ca4c2f6806` adds
`cmd/jsonnetfmt`, passing **255/255** exact Go CLI comparisons, including raw
stderr bytes and file effects, plus separate help/branding and host-policy checks.
Native debug/release tests each pass **262/262**, archive consumer **24/24**,
frozen/upstream formatting **736/736** and **178/178**; isolated ASan includes the
new formatter host suite and passes. See the [jsonnetfmt report](../reports/GO-JSONNET-JSONNETFMT.md).

The raw syntax batch exports independently editable `RawAst`/`RawNode` containers,
retaining ordered token/trivia fragments and EOF fodder. `raw_ast_test.mbt` checks
expression/declaration/field/argument/clause coverage, cloning and document isolation,
cyclic edits, complete budgets and iterative processing of a depth-4000 binary tree.
The formatter probe now also checks exact raw-tree reconstruction and compares
`format_node` against `SyntaxDocument::format` for every frozen/upstream input;
the Go adapter cross-checks `SnippetToRawAST`/`FormatNode` against `Format`.

```sh
moon run tools/formatter-node.mbtx _build/native/release/build/examples/formatter-node-probe/formatter-node-probe.exe ${LOCAL_PATH_012}
```

This separate corpus edits the actual Go raw AST and local concrete syntax tree:
numbers, strings, array insertion/removal, local/use renaming and leading/final
comments, under eight option sets. It compares complete outputs, reparse and
idempotence flags in 56 cases against the frozen `tests/go-formatter-node.json`
and fresh pinned Go runs. The report records source/build/adapter/fixture hashes
and retains failures without skips. Local-only mode omits the checkout, writes
`local-report.json`, and is also run on the isolated ASan binary. This is separate
from Go comparison evidence. The archive consumer calls every new public method.

Evaluation observation and synchronous debugging use `eval_hook_test.mbt`,
`debug_scope_wbtest.mbt` and `debugger_test.mbt` for ordering, laziness, leased
contexts, captured/shadowed scopes, preview/forcing, complete inspection budgets,
reentry, restoration, failure and recovery. Executable README examples and the
independent archive consumer call the new public interfaces.

```sh
moon run tools/debugger-integration.mbtx _build/native/release/build/examples/debugger-probe/debugger-probe.exe ${LOCAL_PATH_012}
```

This adapter uses the pinned public Go debugger, checks its clean checkout and
compares ordered stop reasons/ranges/variables/scalar lookups, output/error flags
and breakpoint state against both frozen fixtures and a fresh Go run. Full
diagnostic text is retained independently and is not claimed equal. Go raw AST
breakpoint enumeration and synthetic desugaring are not covered by this corpus.
Omitting the checkout runs local frozen verification and writes a separate
`local-report.json`; isolated ASan runs this mode on its instrumented binary.
No input is skipped or declared an accepted exception.

The [overall parity plan](GO-PARITY.md) tracks capabilities outside the existing
behavioral corpus. `tools/parity.mbtx` compares all 163 reflected Go standard-library
members against a frozen reference snapshot and the local CLI, writing
`_build/parity/report.json`. It records registration gaps, not behavioral passes;
zero unsupported cases in the smaller differential corpus does not imply full parity.

> Privacy redaction: This public copy replaces environment-specific host and filesystem identifiers with placeholders. Unredacted evidence and original recorded hashes are retained locally. Counts and outcomes describe the original execution; exact diagnostic and path bytes may be redacted. No tests were rerun on the privacy-rewritten commit.
