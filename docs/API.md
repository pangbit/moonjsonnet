# Embedding API

Import `pangbit/moonjsonnet` for source evaluation and `pangbit/moonjsonnet/fs`
for the POSIX file host. Generated signatures are in `pkg.generated.mbti` and
`fs/pkg.generated.mbti`; regenerate with `moon info`.

`evaluate(source, filename?, anonymous?, ext_vars?, ext_code?, ext_programs?, tla_vars?, tla_code?, tla_programs?, native_functions?, trace?, resolver?, binary_resolver?, limits?) -> Json raise JsonnetError`
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

`evaluate_multi(source, string_output?, ...same evaluation options...) -> Map[String, String] raise JsonnetError`
deeply manifests the whole result, then requires an object. Visible keys are
returned unchanged as filenames; JSON values become Go-style documents ending
in a newline. With `string_output=true`, each value must be a string and its raw
contents are returned without an added newline. Hidden fields remain unforced;
assertions and visible values are checked before shape/string validation.
The returned map has no iteration-order guarantee. The CLI sorts filenames by
UTF-8 lexical order, but this API neither writes files nor validates filename
paths. The embedding host chooses its own output policy. All files share one
evaluation and payload budget; options and import/native/trace state match the
other evaluation APIs. The compact JSON manifestation budget is retained.

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
`Runtime` error. If a name appears in both `ext_vars` and `ext_code`, code wins;
`ext_programs` takes precedence over both (see [Parsed programs](#parsed-programs)).
Do not mutate parameter maps or their JSON containers during evaluation.

A top-level function is called once, even when no TLA is supplied. Named
arguments come from `tla_vars: Map[String, Json]` and `tla_code: Map[String, String]`;
code wins for overlapping names, and `tla_programs` overrides both. Default parameters use the function's normal
scope. Code arguments have independent scopes and can read `std.extVar`, but
cannot refer directly to other TLAs. Unused argument values stay lazy; missing
required and unknown arguments are errors. A returned function cannot be
manifested. Top-level values other than functions ignore all TLAs.

Code parameters use `<extvar:NAME>` or `<top-level-arg:NAME>` for diagnostics,
trace locations and `std.thisFile`. Their imports pass an empty `from` to the
resolver, so `FileHost` resolves them relative to its root. Origins are preserved
in lexical environments independently of diagnostic names. A file option
imports the supplied file normally, giving it its own identity and relative
imports. Parameter code shares step/depth/stack/output/import budgets and is checked
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

`@fs.evaluate_file(path, root?, jpaths?, ext_vars?, ext_code?, tla_vars?, tla_code?, native_functions?, trace?, limits?)` creates a new `FileHost` and
evaluates an entry file. `path` is relative to `root` (default `.`), or absolute
within that root. `FileHost::new(root, jpaths?, max_bytes?)` and `FileHost::resolve(from,
path)` also allow manually supplying the host to `evaluate`. An empty `from`
resolves relative to the root; otherwise imports resolve beside the source file.
If absent locally, imports search `jpaths` from right to left. Relative library
directories are relative to root; the constructor copies the array and never
reads `JSONNET_PATH`. Absolute imports bypass library search. `FileHost::load(path)`
loads an entry file without search, as used by `evaluate_file` and the CLI.
Successful and missing path attempts and canonical source contents are cached
for the lifetime of a host; create a new host to observe disk changes. Other
I/O errors are not cached and never fall through. Root, UTF-8 and byte policies
apply to every winning library candidate. Do not share a mutable host concurrently.
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

`Diagnostic::format(max_trace? = 0)` returns a header followed by rendered context.
A positive limit keeps half the context at each end, assigning the odd location
to the outer end and inserting `...` for the omitted middle. Zero or a negative
value leaves context unlimited, as with Go's embedding formatter. The primary
location in the header is always retained. Rendering never mutates the stored
`Diagnostic`; `to_string`/`Show` remain unlimited for compatibility. The CLI uses
a default context limit of 20 and rejects negative option values. These are
limits on this API's context list, not a claim that its locations equal Go's
complete named/synthetic frame set. See [CLI](CLI.md).

## Parsed programs

Parser diagnostics preserve token spelling, including number notation, quote
kind and raw escapes, and use the pinned Go token names and delimiter messages.
Operator runs follow Go boundaries, including unary suffixes and adjacent
comments. Import operands must parse as direct string literals; computed and
parenthesized operands are rejected. Token spelling is retained during parsing
only; this does not add source-preserving AST metadata or complete error ranges.
Normal quoted strings keep raw escapes during lexing and decode as their tokens
are parsed. Full-source lexical errors therefore precede escape errors, while
later syntax errors may not. Escape-error messages retain Go's embedded source
range prefix; the complete Diagnostic/CLI formatting is still not identical.

`Program::parse(source, filename?, anonymous?, limits?) -> Program raise JsonnetError`
lexes, parses and statically validates an entry program without executing code,
reading imports or invoking callbacks. The public `Program` has private fields;
callers cannot construct or mutate its AST. It retains the entry AST, source
identity and byte count, rather than the original source text.

`Program::evaluate`, `evaluate_text`, `evaluate_stream` and `evaluate_multi` accept
the same parameters, resolvers, native functions, trace sink and execution limits
as their string counterparts. Text/multi methods also accept `string_output`.
They do not take `filename` or `anonymous`: these are fixed when parsing and govern
locations, `std.thisFile` and relative import origins for every execution.
The existing string APIs delegate through this path.

```mbt
let program = @moonjsonnet.Program::parse("function(n=2) std.extVar('x') * n")
let first = program.evaluate(ext_vars=Map([("x", 21)])) // 42
let second = program.evaluate(ext_vars=Map([("x", 3)])) // 6
```

Entry and explicitly supplied parameter ASTs are reused. Every execution creates new thunks, objects,
import/source caches and resource counters, including after failure. Changing
parameters, callbacks or a custom resolver's results affects the next execution.
An explicitly reused `FileHost` still retains its own byte cache; this API does
not invalidate host state. Imported code and code parameters remain lazy and are
parsed within that execution; the standard library follows its existing setup.

Creation checks source bytes and parser/AST depth. Execution validates its own
limits, rechecks the saved byte count and AST depth, and applies the ordinary
runtime budgets. It does not replay lexer/parser nesting checks on source syntax
that is no longer present, such as redundant parentheses.

All string and `Program` output methods, plus `fs.evaluate_file`, accept optional
`ext_programs` and `tla_programs` maps of names to `Program`. These provide Go's
ExtNode/TLANode role without exposing mutable AST internals. For duplicate names,
programs override code, which overrides JSON. A supplied program is evaluated
lazily once per binding per execution in a clean scope. It can reference other
external variables and the current native callbacks. An unused binding has no
runtime effects; parsing/static validation has already happened when it was built.

```mbt
let argument = @moonjsonnet.Program::parse("21*2", filename="args/answer.jsonnet")
let result = @moonjsonnet.evaluate("function(x) x", tla_programs=Map([("x", argument)]))
```

For these parameter programs, `std.thisFile` is `<extvar:NAME>` or
`<top-level-arg:NAME>`, while diagnostics and trace retain the original AST
locations. Imports use the program's filename, or an empty origin when it was
parsed with `anonymous=true`. Source-byte and AST-depth limits are checked when
the parameter is forced against that execution's limits; unused parameters do
not consume these runtime budgets.

This provides the parse-then-evaluate role of Go's `SnippetToAST` and AST-based
`Evaluate`/`EvaluateStream`/`EvaluateMulti`. Reusable VM settings and import value
caches are provided by `Evaluator` below.

## Editable semantic AST

`Program::ast() -> Ast` returns a deep, editable copy. `Ast` contains `kind`,
`loc` and optional exclusive `end`; public `AstKind`, `AstField` and `AstClause` represent every supported
expression form. Replace records with `{ ..node, kind: ... }` and edit child
arrays to construct transformations. `Ast::clone(limits?)` makes another isolated
copy, including subtrees with free variables. No runtime objects are exposed.

`Program::from_ast(tree, filename?, anonymous?, limits?)` copies the tree,
validates node shapes and lexical scopes, and creates a reusable Program.
Edits to either the input or a later exported tree cannot change that Program,
another copy, or an Evaluator's imported AST/value cache. The resulting Program
works with every output mode and ext/TLA Program bindings.

```mbt
let node = @moonjsonnet.Program::parse("21").ast()
let edited = { ..node, kind: @moonjsonnet.AstKind::Binary("+", node, node), }
let result = @moonjsonnet.Program::from_ast(edited).evaluate() // 42
```

Literal nodes contain only scalar Json; use Arr/Obj for collections.
Numbers parsed from source use `NumberLiteral(String)` to retain the original
unsigned decimal token (for example `1.20E+003`). Conversion and overflow happen
only when that node is evaluated. `Literal(Json::number(...))` remains available
for manually constructed numeric values. In this pre-1.0 API, consumers matching
parsed numbers must handle `NumberLiteral`; clone and `from_ast` retain its spelling.
Manual numeric tokens must match Jsonnet's unsigned number grammar, with no
whitespace, leading sign or extra token. `from_ast` validates this syntax without
forcing conversion; represent a leading minus with `Unary`.

Field visibility is 1 (inherit), 2 (hidden), or 3 (visible); ImportFile's Bool selects
string versus code import, and Call's Bool is tailstrict. Function/default/local
bindings and comprehension clauses retain their lexical scope rules.

Local, Obj and ObjectComp now hold `Array[AstBinding]` instead of name/value
tuples. Each binding has `name`, `value` and `range: SourceRange?`. Parsed ranges
begin at the declaration name and end after its initializer, independently of
the initializer node's own range. Following Go's semantic AST, sugared local
functions (`local f(x)=x`) have no binding range after lowering; object-local
functions retain it. Clone and Program conversion preserve these distinctions;
manual/synthetic bindings may use `range: None`. This pre-1.0 change requires
updating tuple construction and access to named record fields. Invalid binding
ranges are rejected by the same shape checks as node ranges.

`Func` holds `Array[AstParameter]` rather than name/default tuples. Each parameter
has `name`, `default_value: Ast?` and `range: SourceRange?`; a parsed range covers
the name through its default expression, or only the name when required. Clone
and Program conversion preserve it; synthetic parameters can use None. Consumers
must migrate tuple access to named fields. Repeated formal names are accepted as
in Go: positional arguments sharing a name use the last argument, absent optional
names use the first default, and every required occurrence still needs an explicit
argument. Named arguments may not rebind an already supplied name. Unselected
arguments/defaults remain lazy, including overwritten positional arguments under
tailstrict.

Conversion checks `depth` and uses `steps` as a node-copy budget; cyclic child
arrays and excessive width/depth return Limit. Manually constructed programs
have no source text and a saved source-byte count of zero; this does not exempt
later imports, steps, stack, depth or output from execution limits. Filename
defaults to the root location file, while explicit `filename`/`anonymous` control
the entry/import identity. Individual diagnostic locations remain unchanged.
Trees contain semantic syntax and numeric token spelling, not comments, whitespace,
or Go's desugared/free-variable metadata. Source-preserving tooling
and complete Go AST metadata compatibility remain pending.

`Ast::source_range() -> SourceRange?` returns retained coordinates. `Location`
lines and UTF-8 byte columns start at one; `SourceRange.end` is exclusive.
`SourceRange::format()` renders `file:line:begin-end` or
`file:(beginLine:beginColumn)-(endLine:endColumn)`. Clone and Program conversion
preserve these coordinates, including when the entry filename is overridden.
Ranges describe the parsed source, so editing a node does not recompute them.
`from_ast` rejects reversed, nonpositive or cross-file ranges.

The pre-1.0 `Ast` record now requires `end` in manual record literals: use
`end: None` for synthetic nodes. Record updates preserve it automatically.
Parentheses are omitted from the inner node's range; calls exclude `tailstrict`.
Implicit null, identifier/dot field keys, method wrappers and assertion wrappers
have no range, matching Go's semantic AST. Coordinates do not retain source
text, comments, or complete diagnostic end ranges.

## Parsed source for source tooling

`ParsedSource::parse(source, filename?, limits?)` parses without evaluation or
lexical-scope validation, following the raw parsing role used by Go's formatter.
Unknown variables and out-of-scope self/super can be retained; syntax errors,
duplicate local names, repeated literal field spellings and source/depth limits
still fail. Convert its
`ast()` view through `Program::from_ast` to validate scopes before execution.

`text()` reconstructs the exact input. `parts()` returns independent `SourcePart`
records in source order, including leading and trailing material. Kinds distinguish
token text, whitespace, line comments and block comments; each carries original
text and a one-based UTF-8 byte range. Quotes, verbatim doubling, escapes, text-block
indentation, numeric spelling, CRLF, shebangs and comments are retained.

The `ast()` result is an independent semantic view. Editing that view or a returned
parts array does not rewrite the retained document. This is source retention and
raw parsing; it does not expose Go's Fodder normalization or editable raw AST.
Ordinary Program parsing does not retain trivia.

`format_source(source, filename?, options?, limits?)` and
`ParsedSource::format(options?, limits?)` provide partial native source formatting.
They never evaluate expressions, resolve imports or mutate the retained document.
The result ends with LF. Source/depth limits apply before formatting; emission
also enforces UTF-8 output-byte and token/trivia step limits.

`FormatOptions::default()` selects two-space indentation, at most two blank lines,
single quotes, slash comments, pretty field names, unpadded arrays, padded objects
and implicit object addition. String styles are `DoubleQuotes`, `SingleQuotes`
and `PreserveQuotes`; comments use `HashComments`, `SlashComments` and
`PreserveComments`. Strings containing one quote kind use the other to avoid
escaping; strings containing both kinds, verbatim strings and text blocks retain
their spelling. Nonpositive indentation/blank-line options preserve the original
indentation or disable blank-line limiting, following Go.

The strip flags follow Go precedence: `strip_comments`, then
`strip_all_but_comments`, then `strip_everything`. Keeping only comments replaces
the expression with `null` and drops inline line comments. Stripping everything
removes comments/newlines but still inserts normal token spacing; text-block
content remains intact. Since trailing-comma and string-style passes run before
stripping or pretty-name rewriting, some Go outputs are themselves non-idempotent.

`sort_imports` arranges consecutive groups of top-level code imports by their raw
UTF-8 path spelling, before string normalization. Blank lines and paragraph
comments separate groups; adjacent comments travel with their import. A group
containing duplicate variable names retains its order. A multi-binding import
local becomes separate local declarations. Ordinary bindings, parenthesized
imports, `importstr`/`importbin`, and imports inside functions are not sorted.
Setting the option to false disables this pass. Escaped paths can therefore
produce another Go non-idempotence case: string normalization changes the sort
key used by a subsequent format call.

Equal paths follow the fixed Go 1.24.0 `sort.Slice` permutation, including its
unstable ordering. Comment stripping distinguishes line endings, paragraphs and
interstitial comments before removing text; distinct retained line endings can
leave indented empty lines, just as in Go. Tabs count as eight spaces when
retaining indentation for stripped comments.

**Incomplete:** complete comment placement and broader layout rules remain
under differential validation. `FormatNode` and a
jsonnetfmt CLI are not provided yet. See [the overall parity status](GO-PARITY.md);
the available options do not imply complete formatter compatibility.

## Reusable evaluator

`Evaluator::new()` creates a configurable interpreter with persistent imported
sources, parsed imports and evaluated code imports. Its `evaluate(program)`,
`evaluate_text(program)`, `evaluate_stream(program)` and `evaluate_multi(program)`
accept an already parsed `Program`; entry programs execute each time. Existing
global and `Program` methods still create independent execution state.

```mbt
let evaluator = @moonjsonnet.Evaluator::new()
evaluator.ext_var("answer", 42)
let program = @moonjsonnet.Program::parse("std.extVar('answer')")
let first = evaluator.evaluate(program)
evaluator.ext_code("answer", "6*7")
let second = evaluator.evaluate(program)
```

`ext_var` / `ext_code` / `ext_program` and their `tla_` counterparts bind one name.
Each setter replaces the name's previous representation; `ext_reset` and
`tla_reset` clear their respective bindings. The `var` methods accept JSON,
including strings. `native_function(name, function)` registers or replaces a
callback. Do not mutate supplied JSON containers or callback parameter arrays
after registration; use setters to notify the interpreter of changes.

| Configuration change | Retained cache |
| --- | --- |
| ext setter/reset or native registration, even with the same value | Sources and parsed imports; evaluated imports and their reachable runtime values are cleared |
| TLA setter/reset, trace sink, string-output mode or limits | Sources, ASTs and evaluated imports |
| `set_importer(resolver?, binary_resolver?)` | None; replaces callbacks and clears all import state |

`set_trace` changes the sink used by subsequent trace calls, including previously
unforced cached fields. A field already evaluated does not emit its trace again.
`set_string_output(true)` selects raw strings for text/multi output; JSON and
stream methods retain their types. `set_limits` validates the supplied Limits
without clearing caches. Each execution has fresh step/frame/output/import
counters, and source bytes for directly requested cached imports are checked
again. Cached successful values need not reexecute their original computation.

Imports are disabled initially. A binary resolver supplies bytes for all three
import forms; when it is absent, a text resolver supplies UTF-8 bytes. If both
are supplied, the binary resolver is authoritative. Source bytes are cached by
`(from,path)` and shared by queries and execution; text is decoded from those
same bytes. Code and string imports retain strict UTF-8 validation. Resolved
identities must refer to stable contents. Replacing the importer clears these caches, but cannot clear caches
owned by a reused external `FileHost` or custom callback. Use a new host when its
files should be reread. These policies do not imply Go's unrestricted filesystem
or callback invocation-count parity.

Successful imported fields and closures remain lazy/cached across calls, even
when a different field or output operation fails. Failed computations retry on
the next execution. Object assertion failures are the exception: Go retains
their errors, and this interpreter retains an isolated diagnostic snapshot until
the object/value cache is invalidated. Reusing the error does not mutate earlier
diagnostic results.
Temporary entry values are released after execution; reachable imports keep
stable internal IDs and freed slots are reused. The cache can still grow with
new import identities or newly demanded retained values. This is not an RSS or
leak guarantee.

Evaluation and configuration changes reject reentry on the same Evaluator from
a callback. Separate instances can be used independently. An EvalHook/debugger
API remains pending.

The following queries share source/AST caches and never execute Jsonnet, apply
parameters or invoke native/trace callbacks:

- `resolve_import(imported_from, imported_path) -> String` returns the resolved
  identity and caches the underlying bytes immediately, without parsing them.
- `import_data(imported_from, imported_path) -> BinarySource` returns the same
  identity and raw bytes. It preserves invalid UTF-8 and NUL, corresponding to
  the byte contents of Go's string-returning ImportData.
- `import_program(imported_from, imported_path) -> (Program, String)` parses and
  validates source, returning the program and resolved identity. Evaluation of
  the returned Program is a separate operation, so it executes its entry anew;
  importing that identity within an expression still uses the import value cache.
- `find_dependencies(imported_from, imported_paths) -> Array[String]` uses the
  static scanner below with the Evaluator's shared source/AST cache. Traversal
  state and scan budgets are fresh each time, and cached runtime values are not
  forced or cleared by the scan.

Queries apply current source/import-byte limits; parsed programs and scans also
recheck cached AST depth. Scans account cumulative bytes and request counts as
usual. Querying does not initialize the runtime or consume evaluation steps.
All four methods raise `JsonnetError` and use the same non-reentry guard as
execution. Failed parses retain source bytes but do not install an invalid AST;
repeated requests continue to report the parse/static error. Go v0.21.0 can
instead return a successful nil AST on a repeated ImportAST after such a failure;
the differential input remains a failure, not an accepted parity exception.

## Lint analysis (partial)

`lint(snippets: Array[Source], resolver?, limits?) -> Array[Diagnostic] raise JsonnetError`
checks entry snippets without executing Jsonnet. It reports syntax/static errors,
import errors, unused local/object-local bindings, and eager local-definition
cycles. All lexical references count, including dead branches and references
from other unused bindings. Function parameters and comprehension variables do
not produce unused-binding warnings. Imported code is parsed and its imports
checked recursively, but only explicitly supplied entries receive lint warnings.
Raw imports need not be UTF-8; code imports do. Runtime/native/trace effects are
never invoked.

Conservative type inference follows the pinned Go type graph, including recursive
values, function results, imported code, union types and standard-library
declarations. It checks non-function calls, argument names/counts, indexing,
missing known fields and unary operands. Function parameters, self/super and
dynamic object fields remain abstract as in Go. The lint declarations deliberately
preserve Go's approximations even where runtime return types differ. An empty
result does not prove runtime safety or complete diagnostic compatibility.

Analysis lowers `%`, `in`, slices and comprehensions to the pinned hidden
standard-library calls, preserving nested diagnostic order even when `std` is
shadowed. Synthesized expression depth also consumes the depth budget.
For duplicate entry filenames, only the last successfully parsed entry provides
inferred types; earlier entries are checked on their own syntax with `void`
types, following Go. If an explicit entry is also imported under the same identity,
the local graph uses the entry root; the observed Go panic remains a differential
failure, not an accepted compatibility exception.

Limits abort analysis with JsonnetError; parse/import findings otherwise collect
across entries. Source, depth, import bytes/count and analysis steps are bounded.
The local-cycle and type-component graph walks are iterative; recursive index
expansion has a depth limit and graph traversal consumes analysis steps.
Location points use the current AST;
unused bindings point to their initializer because declaration ranges are not
yet represented. Diagnostic location/text formatting parity remains incomplete.

`cmd/lint` supports multiple files, `-J`/`--jpath`, `JSONNET_PATH`, `--`, short
option expansion, help/version, and the local `--root` confinement option. Exit 0
means no findings, 2 means findings, and 1 means input/resource failure.
As in the pinned Go CLI implementation, `-` is opened as a file; this does not
implement the stdin behavior claimed by Go's help text. Entry files do not fall
back to library search. Example:

```sh
moon run --target native cmd/lint -- -J lib config.jsonnet
```

## Static dependencies

Static dependency scanning and the lint API never evaluate code. Like the pinned
Go implementation, import scanning and lint type/cycle checks skip object
assertions; lint's lexical-use analysis still visits them.

`find_dependencies(imported_from, imported_paths, resolver~, limits?) -> Array[String] raise JsonnetError`
statically scans all entry files and transitive imports without evaluating Jsonnet.
The required resolver returns `BinarySource` for every import form. Only code is
UTF-8 decoded and parsed; `importstr` and `importbin` dependencies can contain
arbitrary bytes. Results contain sorted unique resolved `id` values, excluding
all entry identities. Entries are parsed before traversal; cycles and aliases
terminate through identity deduplication. Stable immutable identities are required.

The walk follows pinned Go v0.21.0 `FindDependencies`, including two limitations:
object assertions are omitted, and a path seen first as raw data suppresses later
recursive code traversal (the later code is still parsed for syntax/static errors).
Unexecuted branches, local bindings and function defaults are scanned. It does
not execute external/native functions or inspect externally supplied parameter code.
It is not a complete dependency list for every possible runtime execution.

`FileHost::find_dependencies(paths, imported_from?, limits?)` installs the host's
binary resolver, library search, canonical root and byte cache. API entries may
use library search, matching Go's VM method; the separate dependency CLI checks
that entry paths exist directly. Every scan has fresh request/AST caches, while
an existing `FileHost` retains its own immutable byte cache across scans.
This standalone scan is independent of evaluation. Use `Evaluator::find_dependencies`
to share source/AST caches with that interpreter; the two methods use the same
traversal rules and resource accounting.

Scanning applies `source_bytes`, `import_bytes` and `imports` to all distinct
requests, including entries and aliases; repeated identical `(from,path)` requests
are cached. `depth` bounds parsing/ASTs, `steps` bounds visited AST nodes, and
`output_bytes` bounds dependency identities including one UTF-8 newline per result.
Graph traversal is iterative; runtime `stack` is not consumed. All limit values
are validated. Go has no equivalent scan resource budgets. Failure returns no list;
diagnostic text/context is not claimed identical to Go.

## Limits

Use `Limits::default()` and a record update to change selected fields.

| Field | Default | Accounting |
| --- | ---: | --- |
| `steps` | 1,000,000 | Expression evaluation, forcing, loops, comparisons and manifestation |
| `depth` | 200 | Parser/AST, evaluation, comparison, JSON and manifestation depth; allowed 1–512 |
| `stack` | 500 | Active clean evaluation frames, object assertion/additive frames and JSON manifestation |
| `source_bytes` | 1,048,576 | UTF-8 bytes per entry/import/forced parameter code source; raw bytes per binary import |
| `import_bytes` | 4,194,304 | Cumulative resolved request bytes per evaluation |
| `imports` | 128 | Distinct `(from,path)` requests per text/binary mode, including aliases |
| `output_bytes` | 4,194,304 | Compact JSON for `evaluate`; actual serialized payload for text/stream/multi, with conservative JSON manifestation checks retained |

All limits must be positive. Internal string and array construction also uses
the output/step budgets to reject exponential intermediates. Standard-library
string manifestation consumes the output budget during evaluation, then final
manifestation starts a fresh output counter. This is intentionally conservative;
limits are execution budgets, not reference Jsonnet language semantics.
`stack` is independent of `depth`: ordinary AST traversal does not add a runtime
frame, but forcing an uncomputed thunk does. Ready strings supplied through
`ext_vars`/`tla_vars`, cached values and injected standard-library fields add no
frame. Other JSON parameter values retain lazy conversion as an embedding
extension. A tail call may discard a frame entered with `tailstrict`, before
forcing its arguments. Stack exhaustion has kind `Limit`; `max_trace` only
controls diagnostic rendering. Existing full `Limits` record literals must add
`stack`; prefer record updates from `Limits::default()`.
Text output's final newline is outside the payload byte count. Stream document
payloads share one budget, excluding their final newlines; the CLI additionally
counts all YAML delimiters and document newlines.
Multi JSON final newlines are excluded, with payloads shared across all files;
the CLI checks the full filename list separately before output I/O. The POSIX
import host checks regular-file size and bounds reads before decoding UTF-8.

Lazy values, function arguments/defaults, object fields and imports are memoized.
Object composition creates a fresh field cache bound to the new `self`.
Arena indices connect environments, thunks and objects so recursive language
values do not create native reference-count cycles.
Strict tail calls reuse the evaluator loop after forcing all parameters. Other
recursion and nested expressions remain subject to the configured depth limit.
