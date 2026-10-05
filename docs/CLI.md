# Command line

Build with `moon build --target native --release`. The executable is
`_build/native/release/build/cmd/main/main.exe` (including on POSIX).
For development use `moon run cmd/main -- OPTIONS INPUT`.

| Option | Purpose |
| --- | --- |
| `--root DIR` | Allowed filesystem root, default current directory |
| `-J DIR`, `--jpath DIR` | Add a library search directory; the rightmost path wins |
| `-t N`, `--max-trace N` | Crop error context to N locations; default 20, zero is unlimited |
| `-s N`, `--max-stack N` | Runtime frame budget; default 500, strictly positive |
| `-e`, `--exec` | Interpret the one input argument as Jsonnet source |
| `-S`, `--string` | Require a string result and emit its contents followed by one newline |
| `-y`, `--yaml-stream` | Require an array and emit its elements as JSON documents with YAML stream delimiters |
| `-m DIR`, `--multi DIR` | Write a top-level object's values to files and list their names |
| `-c`, `--create-output-dirs` | Create parent directories for ordinary output files and multi data files |
| `--` | End option processing; subsequent arguments are inputs |
| `-V NAME[=VALUE]`, `--ext-str NAME[=VALUE]` | Inject a literal string; omitted value comes from the named environment variable |
| `--ext-code NAME[=CODE]` | Inject a lazy Jsonnet expression; omitted code comes from the named environment variable |
| `-A NAME[=VALUE]`, `--tla-str NAME[=VALUE]` | Supply a literal string to a top-level function |
| `--tla-code NAME[=CODE]` | Supply a lazy Jsonnet expression to a top-level function |
| `--ext-str-file NAME=FILE`, `--tla-str-file NAME=FILE` | Supply a lazy `importstr` expression |
| `--ext-code-file NAME=FILE`, `--tla-code-file NAME=FILE` | Supply a lazy `import` expression |
| `-o FILE`, `--output-file FILE`, `--output FILE` | Write the selected output, or the multi filename list; default stdout |
| `--max-steps N` | Evaluation step budget |
| `--max-depth N` | Depth budget, 1–512 |
| `--max-source-bytes N` | Entry/import per-file UTF-8 bytes |
| `--max-import-bytes N` | Cumulative import bytes |
| `--max-imports N` | Import request count |
| `--max-output-bytes N` | Serialized output byte budget; see the mode-specific accounting below |
| `--help`, `-h` | Usage |
| `--version`, `-v` | Package and compatibility version |

Exactly one input is required: a file, `-` for stdin, or source code with `-e`.
Entry paths are relative to `--root`. Options may
precede or follow the input. Unknown options, missing values and multiple inputs
are errors. Parameter values split at the first `=`; subsequent `=` characters
are preserved. Empty names and values are accepted. Repeated names use the last
assignment, including across string/code/file forms. Missing environment
variables and malformed file-option assignments are argument errors (exit 1).

Inline/stdin input has the diagnostic filename `<cmdline>`/`<stdin>` and an empty
`std.thisFile`. Imports resolve from `--root`; imported files keep their own
filename and relative imports. Inline code is not read from stdin, even if the
code argument is `-`. Stdin reads at most `source_bytes + 1` bytes, rejects
oversized input and requires valid UTF-8. Go's default stdin reader is unbounded;
the project retains its explicit resource and UTF-8 policy.

Before parsing, combined short options expand byte by byte up to the first `--`:
`-eV x=value CODE` becomes `-e -V x=value CODE`. This also applies to option
values, matching Go; `-Ve` makes `-V` consume `-e` as a variable name. Attached
values such as `-Vx=value` are not GNU-style assignments. Use `-e -- '-42'` for
source starting with `-`, and `-- '-file.jsonnet'` for filenames starting with `-`.
Help/version can return before input-count validation. Empty output paths are
argument errors; the older `--output` spelling remains an extension.

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
shared budgets.

`-s` counts active top-level/function bodies, unforced lazy values (including
code parameters/imports), object fields/assertions, additive-field wrappers and
JSON manifestation. Cached values and native builtin dispatch do not add frames.
A tail call removes the current function frame only if that frame was entered
with `tailstrict`; arguments are forced after removal. String output skips JSON
manifestation. Exhaustion is a `Limit` error, before output files are opened.
Positive decimal integers use the same syntax/range rules as `-t`; repeated
values use the last assignment. Embedding callers set `Limits.stack`.
The independent depth, step and byte budgets remain in force, so increasing
`-s` does not allow unlimited AST or native recursion. Exact Go frame thresholds
across all standard-library implementations and diagnostics remain unproven.

`-t` accepts a nonnegative decimal integer in the pinned 64-bit Go range. Signs
and leading zeroes are accepted; radix prefixes, underscores, whitespace,
non-ASCII digits and overflow are errors. Repeated values use the last assignment.
A positive limit retains `floor(N/2)` inner context locations and the remaining
outer locations, with one `...` line between them when cropping is needed.
Zero disables cropping. Large values do not narrow or overflow the context count.
The primary error header/location is always printed, and collected context is
not discarded. This option controls error rendering; `std.trace` messages still
use the configured trace sink. The project's context locations differ from Go's
named/synthetic frames, so this does not establish stack-frame or diagnostic-text
equivalence. Embedding callers can use `Diagnostic::format(max_trace?)`.

Imports first search beside the importing file (or root for anonymous inputs
and code parameters), then `-J` directories from right to left, then the
colon-separated `JSONNET_PATH` directories from left to right. Empty environment
components mean root; an empty environment value adds no paths. Empty `-J`
values are argument errors. Relative library directories are relative to
`--root`, matching the default current-directory root; this remains an extension
when an explicit root differs from the process directory. Absolute imports do
not search libraries. Entry files never use library search.

Code, text and binary imports share the host's canonical byte cache. Successful
and missing path attempts stay fixed for one host lifetime. Only a nonexistent
path falls through; permissions, non-directory parents, directories, symlink
loops, invalid UTF-8, byte limits and root escapes stop resolution. `-J` and
`JSONNET_PATH` do not expand the allowed root. Unlike unrestricted Go imports,
library files and symlink targets must remain inside the configured root.

Default JSON output now follows Go's CLI layout: three-space indentation, sorted
keys, `[ ]`/`{ }` empty containers and one trailing newline. Integral numbers use
fixed decimal text; other numbers use 17 significant digits. C0/C1 characters
are escaped; HTML and U+2028/U+2029 are preserved. This replaces the earlier
compact CLI JSON layout; the embedding `evaluate` still returns `Json`.

`-S` emits raw string contents, including Unicode, NUL and existing newlines,
then adds one newline. Other result types fail without traversing their fields.
`-y` deeply manifests the result and then requires a top-level array. Each element
is rendered as ordinary JSON, preceded by `---` and a newline; a nonempty stream
ends with `...` and a newline. An empty array emits no bytes. `-y` ignores `-S`,
matching Go. All documents are evaluated before any output is written.

`-m` deeply manifests the result and requires a top-level object. Visible keys
are filenames, appended to `DIR/` and listed in UTF-8 lexical order. Each JSON
file ends in one newline; with `-S`, values must be strings and are written raw
with no added newline. `-m` takes precedence over `-y`. Repeated `-m` uses the
last directory; an empty directory argument fails. An empty object writes no
data and does not create the output directory, but `-o` still creates an empty list.

Existing files are compared without UTF-8 decoding; identical bytes preserve
their modification time. The bounded comparison reads up to the new content's
length plus one byte rather than loading an unbounded existing file. Each name
is written to the list before that file is checked/written, as in Go, so an I/O
failure can leave a partial list and earlier files. Evaluation failure creates
neither files nor directories and preserves an existing filename list.

`-c` creates ordinary output and multi data-file parents with mode 0755 subject
to umask. Like the reference, it does not create stream output parents or the
multi filename-list parent. Parent paths are lexically cleaned for directory
creation; the actual output path and printed names retain their original spelling.
Output paths and generated keys follow the host filesystem, including symlinks
and `..`; the import root restricts reads, not these explicitly selected writes.

JSON/string budgets count actual payload UTF-8 bytes, excluding the one trailing
newline. JSON/stream manifestation also retains the conservative compact JSON
budget. Stream document payloads share one serialized budget; the CLI additionally
counts every document newline and YAML delimiter before writing the stream.
These explicit limits are host policy rather than unrestricted Go input equivalence.
Multi payloads share one budget, excluding JSON final newlines; the complete
filename list has another check against `output_bytes` before opening any output.

Exit 0 means manifested output was emitted (or help/version was requested).
Go-compatible aggregate overflow may emit `+Inf`, `-Inf`, or `NaN` instead of
strict JSON, including within arrays/objects. Interpreter
errors and CLI argument/output errors exit 1, matching Go. This changes the
earlier CLI argument/output exit code 2. Diagnostics go to stderr.
Evaluation failure does not open or truncate the output file. On successful
evaluation `-o` overwrites its destination; output I/O is not transactional.
The import root controls reads, not the explicitly selected output path.

## Static dependency tool

Build `cmd/deps` with `moon build --target native --release cmd/deps`, then run
`_build/native/release/build/cmd/deps/deps.exe [-J DIR] [-o FILE] [--root DIR] [--] FILE...`.
It lists canonical absolute transitive dependencies, sorted one per line, excluding
all entries. Empty results emit no bytes. Multiple entries, `--jpath`,
`--output-file`, `JSONNET_PATH`, byte-wise combined short options, help and version
are supported. `-` is a literal filename, not stdin. Entries must exist directly;
library fallback applies to nested imports. The API additionally permits library
entry lookup, as Go's VM method does.

No Jsonnet code runs. The pinned Go scanner omits object assertion imports and
does not recurse into an identity already encountered as raw data; these behaviors
are preserved and tested. See [API](API.md) for scan limits and cache lifetime.
The tool uses the default resource budgets and the existing canonical root policy.
It opens the output only after successful scanning, preserving an existing file
on scan failure; a successful empty list truncates a selected output to zero bytes.
Errors exit 1 and successful scans exit 0. Diagnostic formatting and all possible
desugared traversal/error orders are not yet proven equivalent to Go.
