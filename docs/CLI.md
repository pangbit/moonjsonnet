# Command line

Build with `moon build --target native --release`. The executable is
`_build/native/release/build/cmd/main/main.exe` (including on POSIX).
For development use `moon run cmd/main -- OPTIONS INPUT`.

| Option | Purpose |
| --- | --- |
| `--root DIR` | Allowed filesystem root, default current directory |
| `--ext-str NAME=VALUE` | Inject a string; repeat for multiple names |
| `--ext-code NAME=JSON` | Inject a JSON value; arbitrary Jsonnet code is unsupported |
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
precede or follow the input. Unknown options, missing values, malformed JSON
external values and multiple inputs are errors. Repeated external names use the
last value. There is no implicit environment-variable lookup, stdin input,
top-level function application, import search path or multi-file output mode.

Exit 0 means manifested output was emitted (or help/version was requested).
Go-compatible aggregate overflow may emit `+Inf`, `-Inf`, or `NaN` instead of
strict JSON, including within arrays/objects. Interpreter
errors exit 1; CLI argument/output errors exit 2. Diagnostics go to stderr.
Evaluation failure does not open or truncate the output file. On successful
evaluation `-o` overwrites its destination; output I/O is not transactional.
The import root controls reads, not the explicitly selected output path.
