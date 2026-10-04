# Command line

Build with `moon build --target native --release`. The executable is
`_build/native/release/build/cmd/main/main.exe` (including on POSIX).
For development use `moon run cmd/main -- OPTIONS INPUT`.

| Option | Purpose |
| --- | --- |
| `--root DIR` | Allowed filesystem root, default current directory |
| `-V NAME[=VALUE]`, `--ext-str NAME[=VALUE]` | Inject a literal string; omitted value comes from the named environment variable |
| `--ext-code NAME[=CODE]` | Inject a lazy Jsonnet expression; omitted code comes from the named environment variable |
| `-A NAME[=VALUE]`, `--tla-str NAME[=VALUE]` | Supply a literal string to a top-level function |
| `--tla-code NAME[=CODE]` | Supply a lazy Jsonnet expression to a top-level function |
| `--ext-str-file NAME=FILE`, `--tla-str-file NAME=FILE` | Supply a lazy `importstr` expression |
| `--ext-code-file NAME=FILE`, `--tla-code-file NAME=FILE` | Supply a lazy `import` expression |
| `-o FILE`, `--output FILE` | Write JSON after successful evaluation; default stdout |
| `--max-steps N` | Evaluation step budget |
| `--max-depth N` | Depth budget, 1–512 |
| `--max-source-bytes N` | Entry/import per-file UTF-8 bytes |
| `--max-import-bytes N` | Cumulative import bytes |
| `--max-imports N` | Import request count |
| `--max-output-bytes N` | JSON output byte budget |
| `--help`, `-h` | Usage |
| `--version` | Package and compatibility version |

Exactly one input is required. Entry paths are relative to `--root`. Options may
precede or follow the input. Unknown options, missing values and multiple inputs
are errors. Parameter values split at the first `=`; subsequent `=` characters
are preserved. Empty names and values are accepted. Repeated names use the last
assignment, including across string/code/file forms. Missing environment
variables and malformed file-option assignments are argument errors (exit 2).

Code runs in an independent environment with `std`, and its value/errors are
memoized when used. `--ext-code` now accepts arbitrary Jsonnet, including JSON.
Invalid code is an interpreter error (exit 1) only when forced. Unused file
parameters do not read their files. Parameter files and code imports are relative
to `--root` and obey its canonical path/symlink/UTF-8/byte restrictions. Imported
parameter files resolve their nested imports beside the file. This root policy
is stricter than Go's default unrestricted filesystem importer.

Top-level functions are called once using named TLAs, with ordinary lazy/default
parameter behavior. Missing and unknown argument names are errors. Non-function
top-level values ignore TLAs. See [API](API.md) for code parameter filenames and
shared budgets. Stdin input, import search paths, combined option abbreviations
and multi-file output are still pending.

Exit 0 means manifested output was emitted (or help/version was requested).
Go-compatible aggregate overflow may emit `+Inf`, `-Inf`, or `NaN` instead of
strict JSON, including within arrays/objects. Interpreter
errors exit 1; CLI argument/output errors exit 2. Diagnostics go to stderr.
Evaluation failure does not open or truncate the output file. On successful
evaluation `-o` overwrites its destination; output I/O is not transactional.
The import root controls reads, not the explicitly selected output path.
