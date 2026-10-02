# Embedding API

Import `pangbit/moonjsonnet` for source evaluation and `pangbit/moonjsonnet/fs`
for the POSIX file host. Generated signatures are in `pkg.generated.mbti` and
`fs/pkg.generated.mbti`; regenerate with `moon info`.

`evaluate(source, filename?, ext_vars?, resolver?, limits?) -> Json raise JsonnetError`
owns a fresh evaluation state on every call. `filename` defaults to `<input>` and
is passed to the importer. `ext_vars` is a `Map[String, Json]` read by
`std.extVar`; strings and JSON values are never implicitly parsed as Jsonnet.
No importer means imports are disabled. A host exception is translated into an
`Import` diagnostic; an existing `JsonnetError` preserves its category.

The resolver has signature `(from: String, path: String) -> Source raise`.
`Source { id, text }` must use a stable canonical identity for one immutable
source during an evaluation. Request pairs are cached, and parsed/evaluated
imports are memoized by `(id, import/importstr)`. Imported code has its own lexical
environment and accesses the same external variables. A custom resolver is
trusted host code: it must enforce its own path, network, allocation and timeout
policy. The evaluator checks byte limits after the callback returns.

`@fs.evaluate_file(path, root?, ext_vars?, limits?)` creates a new `FileHost` and
evaluates an entry file. `path` is relative to `root` (default `.`), or absolute
within that root. `FileHost::new(root, max_bytes?)` and `FileHost::resolve(from,
path)` also allow manually supplying the host to `evaluate`. An empty `from`
resolves relative to the root; otherwise imports resolve beside the source file.
Canonical source contents are cached for the lifetime of a host; create a new
host to observe disk changes. Do not share a mutable host concurrently.

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
| `source_bytes` | 1,048,576 | UTF-8 bytes per source, including entry and imported text |
| `import_bytes` | 4,194,304 | Cumulative resolved request bytes per evaluation |
| `imports` | 128 | Distinct `(from,path)` requests, including aliases |
| `output_bytes` | 4,194,304 | Compact UTF-8 JSON, including punctuation and escaping |

All limits must be positive. Internal string and array construction also uses
the output/step budgets to reject exponential intermediates. Standard-library
string manifestation consumes the output budget during evaluation, then final
manifestation starts a fresh output counter. This is intentionally conservative;
limits are execution budgets, not reference Jsonnet language semantics.
The CLI's final newline is outside the JSON byte count. The POSIX host checks
regular-file size and bounds reads before decoding UTF-8.

Lazy values, function arguments/defaults, object fields and imports are memoized.
Object composition creates a fresh field cache bound to the new `self`.
Arena indices connect environments, thunks and objects so recursive language
values do not create native reference-count cycles.
