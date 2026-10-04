# Embedding API

Import `pangbit/moonjsonnet` for source evaluation and `pangbit/moonjsonnet/fs`
for the POSIX file host. Generated signatures are in `pkg.generated.mbti` and
`fs/pkg.generated.mbti`; regenerate with `moon info`.

`evaluate(source, filename?, anonymous?, ext_vars?, ext_code?, tla_vars?, tla_code?, native_functions?, trace?, resolver?, binary_resolver?, limits?) -> Json raise JsonnetError`
owns a fresh evaluation state on every call. `filename` defaults to `<input>` and
is passed to the importer. `ext_vars` is a `Map[String, Json]` read by
`std.extVar`; strings and JSON values are never implicitly parsed as Jsonnet.
No importer means imports are disabled. A host exception is translated into an
`Import` diagnostic; an existing `JsonnetError` preserves its category.

`evaluate_text(source, string_output?, ...same evaluation options...) -> String raise JsonnetError`
returns Go-style formatted JSON followed by a newline. With `string_output=true`,
it requires a string and returns its unescaped contents plus one newline; other
types fail without deep manifestation. Existing `evaluate` behavior is unchanged.
The JSON serializer uses sorted keys, three-space indentation, `[ ]`/`{ }` for
empty containers, fixed integers and 17 significant digits for other numbers.
Its escaping follows Go's CLI serializer, which preserves HTML/U+2028/U+2029
and escapes C0/C1 characters. It differs from the `std.manifestJson` contract.

`evaluate_stream(source, ...same evaluation options...) -> Array[String] raise JsonnetError`
deeply manifests the whole result, then requires an array. Each returned document
is formatted as above and ends in one newline; an empty array returns `[]`.
Documents share one evaluation, parameter/import caches, callbacks and budgets.
This interface returns documents only; the CLI adds YAML stream delimiters.
Neither API writes files or emits successful output before returning all results.
They accept the same anonymous, parameter, resolver, native and trace options as
`evaluate`; manually configure a `FileHost` to use them with file input.

`anonymous=true` matches Go's anonymous-snippet input mode: `filename` is used
only for diagnostics and trace, `std.thisFile` is empty, and entry imports call
the resolver with empty `from`. Imported files keep their own filenames and
origins. The default `anonymous=false` keeps the existing filename-based behavior.
CLI inline code and stdin use the anonymous mode; code parameters retain their
own synthetic `std.thisFile` names.

`ext_code: Map[String, String]` supplies Jsonnet expressions, including functions,
objects and imports. Code runs in an independent lexical environment containing
`std`; it can read other external variables but cannot read entry-file locals.
Each external value is a memoized thunk shared by imports and the entry program.
Unused code, including syntax errors, remains unforced. Cyclic forcing is a
`Runtime` error. If a name appears in both `ext_vars` and `ext_code`, code wins.
Do not mutate parameter maps or their JSON containers during evaluation.

A top-level function is called once, even when no TLA is supplied. Named
arguments come from `tla_vars: Map[String, Json]` and `tla_code: Map[String, String]`;
code wins for overlapping names. Default parameters use the function's normal
scope. Code arguments have independent scopes and can read `std.extVar`, but
cannot refer directly to other TLAs. Unused argument values stay lazy; missing
required and unknown arguments are errors. A returned function cannot be
manifested. Top-level values other than functions ignore all TLAs.

Code parameters use `<extvar:NAME>` or `<top-level-arg:NAME>` for diagnostics,
trace locations and `std.thisFile`. Their imports pass an empty `from` to the
resolver, so `FileHost` resolves them relative to its root. Origins are preserved
in lexical environments independently of diagnostic names. A file option
imports the supplied file normally, giving it its own identity and relative
imports. Parameter code shares step/depth/output/import budgets and is checked
against `source_bytes` when forced. Each `evaluate` call starts fresh; reusable
VM/AST interfaces and their reset/cache lifecycle are still pending.

Like the pinned Go implementation, `sum`/`avg` can return non-finite numbers.
The returned `Json::Number` keeps Infinity/NaN and a spelling preserved by
`stringify` (`+Inf`, `-Inf`, `NaN`). Those spellings are not valid strict JSON;
this applies inside arrays/objects as well. Ordinary arithmetic still rejects
non-finite results. See [compatibility](COMPATIBILITY.md) for conversion details.

The resolver has signature `(from: String, path: String) -> Source raise`.
`Source { id, text }` must use a stable canonical identity for one immutable
source during an evaluation. Request pairs are cached, and parsed/evaluated
imports are memoized by `(id, import/importstr)`. Imported code has its own lexical
environment and accesses the same external variables. A custom resolver is
trusted host code: it must enforce its own path, network, allocation and timeout
policy. The evaluator checks byte limits after the callback returns.

`binary_resolver(from, path) -> BinarySource raise` serves `importbin`.
`BinarySource { id, bytes }` follows the same immutable canonical identity contract;
its raw bytes become an array of integers 0–255 without UTF-8 decoding. Text and
binary requests have separate caches and share the import count/byte budgets.
Omitting a resolver disables only its corresponding import modes.

`native_functions: Map[String, NativeFunction]` registers host functions for this
evaluation. `NativeFunction { params: Array[String], callback: (Array[Json]) -> Json raise }`
declares required parameter names and a callback; keep names unique and do not
mutate registrations during evaluation. `std.native(name)` returns the function,
or `null` if absent. Positional/named arguments are bound normally and fully
manifested in parameter order before the callback runs, including object
assertions and visible fields. Hidden fields are omitted. Function arguments
cannot be converted to JSON. A lazy call runs once when forced.

Return containers are copied eagerly, rejecting non-finite numbers even in
unread fields. Callback errors become `Runtime` diagnostics at the call site;
MoonBit process aborts are not recoverable Go panics. Native callbacks are trusted
host code: evaluation limits bound argument/result traversal, but cannot interrupt
the callback or prevent its own allocation and I/O. Argument manifestation shares
one output budget per call and preserves an outer manifestation's byte counter.

`trace: (Location, String) -> Unit` receives the call location and unmodified
message. The default prints `TRACE: filename:line message` plus a newline to
stderr. `std.trace(str, rest)` forces both arguments to values before emitting,
requires a string message and returns `rest`; nested arrays/objects remain lazy.
The sink is non-raising. A sink that ignores both arguments silences tracing.
Imports use the same native registry and sink, with their own source locations.

`@fs.evaluate_file(path, root?, ext_vars?, ext_code?, tla_vars?, tla_code?, native_functions?, trace?, limits?)` creates a new `FileHost` and
evaluates an entry file. `path` is relative to `root` (default `.`), or absolute
within that root. `FileHost::new(root, max_bytes?)` and `FileHost::resolve(from,
path)` also allow manually supplying the host to `evaluate`. An empty `from`
resolves relative to the root; otherwise imports resolve beside the source file.
Canonical source contents are cached for the lifetime of a host; create a new
host to observe disk changes. Do not share a mutable host concurrently.
`FileHost::resolve_binary(from,path)` uses the same canonical root checks and
byte cache; `evaluate_file` installs both resolver modes automatically.
`std.thisFile` is the current source's filename/canonical import identity.

Catch `JsonnetError::Error(diagnostic)`. The public `Diagnostic` contains:

| Field | Meaning |
| --- | --- |
| `kind` | `Syntax`, `Static`, `Type`, `Runtime`, `Assertion`, `Import`, `Limit`, `Unsupported` |
| `message` | Human-readable explanation; not a stable machine protocol |
| `location` | Source file, one-based line and Unicode code-point column |
| `context` | Function-call and import locations from inner to outer |

`Diagnostic::to_string()` renders a CLI-friendly diagnostic. Filesystem failures
use the requested/canonical filename and position 1:1. Manifestation errors use
the entry location if no expression is active. Diagnostics may contain source
paths and user-generated messages; the embedding application controls disclosure.

## Limits

Use `Limits::default()` and a record update to change selected fields.

| Field | Default | Accounting |
| --- | ---: | --- |
| `steps` | 1,000,000 | Expression evaluation, forcing, loops, comparisons and manifestation |
| `depth` | 200 | Parser/AST, evaluation, comparison, JSON and manifestation depth; allowed 1–512 |
| `source_bytes` | 1,048,576 | UTF-8 bytes per entry/import/forced parameter code source; raw bytes per binary import |
| `import_bytes` | 4,194,304 | Cumulative resolved request bytes per evaluation |
| `imports` | 128 | Distinct `(from,path)` requests per text/binary mode, including aliases |
| `output_bytes` | 4,194,304 | Compact JSON for `evaluate`; actual serialized payload for text/stream, with conservative JSON manifestation checks retained |

All limits must be positive. Internal string and array construction also uses
the output/step budgets to reject exponential intermediates. Standard-library
string manifestation consumes the output budget during evaluation, then final
manifestation starts a fresh output counter. This is intentionally conservative;
limits are execution budgets, not reference Jsonnet language semantics.
Text output's final newline is outside the payload byte count. Stream document
payloads share one budget, excluding their final newlines; the CLI additionally
counts all YAML delimiters and document newlines. The POSIX host checks
regular-file size and bounds reads before decoding UTF-8.

Lazy values, function arguments/defaults, object fields and imports are memoized.
Object composition creates a fresh field cache bound to the new `self`.
Arena indices connect environments, thunks and objects so recursive language
values do not create native reference-count cycles.
Strict tail calls reuse the evaluator loop after forcing all parameters. Other
recursion and nested expressions remain subject to the configured depth limit.
