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
against `source_bytes` when forced. Global `evaluate` calls start fresh;
[reusable evaluators](#reusable-evaluator) retain import caches with explicit reset
rules, and [parsed programs](#parsed-programs) can be reused.

Numbers must be finite. `sum`/`avg` reject overflow at the addition that causes
it, before returning a result; unused expressions remain lazy. Manifestation also
rejects internal non-finite numbers. See [compatibility](COMPATIBILITY.md).

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

For `std.sort`, this sharing rule does not promise a particular number or order
of `keyF` applications. Use pure, repeatable keys for defined sorting results.
Independent failing key applications have no promised diagnostic winner;
required errors and branch laziness still apply. These algorithm details do not
change the argument/manifestation or shared-call contracts above.

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
| `location` | Source file, one-based line and UTF-8 byte column |
| `context` | Function-call and import locations from inner to outer |
| `trace` | Independent source/synthetic frames, outermost first; a static error retains its source site |

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

`TraceFrame { location: TraceLocation, name: String }` preserves named contexts:
`$`, named local thunks, functions and objects, plus synthetic evaluation, top-level
function-call, manifestation, array-element, field, object-assertion and additive
field sites. `TraceLocation` is `Source(SourceRange)` or `Synthetic(String)`;
`format()` renders that location. Frames are captured before unwinding and copied
for retained errors and hook outcomes. The pre-1.0 Diagnostic record now requires
`trace: []` for manually constructed errors; record updates preserve it.

`DiagnosticFormatter::new()` supplies Go-style rendering with a default trace
limit of 20. `set_max_trace(size)` keeps both ends of the reversed display order;
zero/negative means unlimited. `format(d)` returns text and `format_bytes(d)`
preserves malformed Unicode bytes that Go can truncate inside a character. Text
rendering replaces invalid UTF-8. The stored message/trace are unchanged.
`set_source(Source {id,text})` supplies code for static error snippets;
`clear_sources()` removes code while retaining a saved diagnostic range.
`set_color(color?)` transforms only the selected static source fragment, and
omission disables it. Runtime traces do not invoke color, following fixed Go's
default formatter. Snippet lookup is bounded to 1 MiB and invalid caller ranges
omit code. Formatting is host-side presentation, separate from execution budgets.

`Evaluator::set_diagnostic_formatter(formatter?)` configures explicit
`format_error(d)` / `format_error_bytes(d)`, preserving caches and rejecting
configuration reentry. Omission restores the default. Supply entry/import/parameter
source identities to the formatter when code snippets are needed. Legacy
`Diagnostic::format` retains its prior header/context format. The CLI uses this
Go-style renderer for language errors and frame exhaustion; other import/limit
failures retain the explicit host-policy diagnostic format. These
interfaces do not claim every runtime message or CLI diagnostic is byte-identical
to Go outside the checked diagnostic corpus.

`error value` and a failed assertion's optional message use Jsonnet string
conversion: strings remain unchanged, while other values are manifested as
compact JSON with Go's spaces and control-character quoting. Conversion retains
the existing depth, work and output budgets. Successful assertions do not force
their messages. Source definitions of `map`, `mapWithIndex`, `assertEqual`,
object field/has helpers, `manifestJson` and `slice` preserve standard-library
source frames and argument laziness. An explicit `error` in those definitions
has kind `Runtime`; a native type guard has kind `Type`.
Import compile failures retain their public `Syntax`/`Static` category, while
Go-style rendering preserves the runtime import call frames and includes the
original compile-error range in its message. Direct parsing still uses static
source snippets. String/stream/multi output type errors include the rejected
type; string mode continues to reject a container without forcing its contents.

Malformed JSON diagnostics follow the pinned Go 1.24 scanner's first-error and
EOF rules, including byte-to-character quoting. YAML diagnostics distinguish
scanner/parser origins and preserve the pinned decoder's line numbering,
anchor names and directive errors. `parseYaml` retains Go's document splitting;
a `%YAML` directive separated from its `---` by that split can fail even when
the unsplit document is legal YAML. These checks cover a finite corpus and do
not establish every JSON/YAML decoding error as equal to Go.

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
Trees contain semantic syntax and numeric token spelling. Use the separate
`RawAst` API below for comments, whitespace and source-preserving edits. Go's
desugared/free-variable metadata is not part of this semantic view.

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

Object-assert declaration spans are retained privately without adding semantic
nodes or changing AST depth. `Program::assertion_ranges()` returns an independent
map keyed by the condition's source-range identity. Pass it as
`Program::from_ast(tree, assertion_ranges=...)` to preserve those spans after
edits that keep condition identities. Used ranges are validated like AST ranges;
unused map entries are ignored. Without that map, a manually supplied object
assertion uses its condition/message span for diagnostics. This does not change
evaluation, scope validation or the public object-assert tuple representation.

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
parts array does not rewrite the retained document. For an editable structural
view, export `SyntaxDocument::raw_ast()` or use `RawAst::parse()` below.
Ordinary Program parsing does not retain trivia.

`format_source(source, filename?, options?, limits?)` and
`ParsedSource::format(options?, limits?)` provide native source formatting.
They never evaluate expressions, resolve imports or mutate the retained document.
The result ends with LF. Source/depth limits apply before formatting; emission
also enforces UTF-8 output-byte and token/trivia step limits.

For tooling on deeper trees, `SyntaxDocument::parse(source, filename?, limits?)`
and `format_syntax_source(source, filename?, options?, limits?)` use independent
`SyntaxLimits`. Defaults are recursive parser depth 200, complete tree depth
4096, 1,000,000 nodes and formatting steps, 1 MiB source and 4 MiB output.
All limits must be positive; parser depth is capped at 512 and tree depth at
16384. A flat binary chain can therefore exceed evaluator tree depth without
expanding recursive parser admission. Every tree child counts, including defaults,
object assertions and comprehension clauses. `format` rechecks source, tree and
node admission, even when a previously parsed document is given narrower limits.

`SyntaxDocument::text`, `parts` and iterative `ast` have the same retention and
independent-copy behavior as `ParsedSource`. Parsing/formatting never evaluates
or resolves imports. Exporting a semantic AST does not admit it for execution:
`Program::from_ast` still applies evaluator scope and resource checks. Existing
`Program`, `ParsedSource`, `format_source` and `Limits` retain their depth defaults
and hard cap; use the explicit syntax entry point for deeper source tooling.

`SyntaxDocument::raw_ast(limits?)` exports fresh, editable `RawNode` containers;
`RawAst::parse(source, filename?, limits?)` provides the same view directly. Its
root contains ordered `RawPart::Text(SourcePart)` and `Child(RawNode)` entries.
Tokens own their leading trivia; EOF trivia is in `RawAst.final_fodder`. Every
token, whitespace and comment fragment occurs exactly once, retaining original
UTF-8 byte ranges and spelling. Parentheses, fields, bindings, parameters,
arguments, object locals/assertions and comprehension clauses are structural
nodes alongside the expression categories in `RawNodeKind`.

The ordered parts are authoritative. `kind` and optional `range` describe the
original parse; editing an array does not refresh either. Reparse `text()` to
refresh metadata after edits. `RawAst::text` includes final fodder and
`RawNode::text` serializes the selected node exactly, without grammar validation.
`clone()` copies every child occurrence and mutable parts/final-fodder array,
including repeated shared children, leaving the document and other exports
independent. Build, serialization and cloning use iterative stacks, check the
complete raw tree/node/work budgets, and bound cyclic edits. Structural wrapper
nodes also count toward raw tree depth and node limits. Serialization checks
`SyntaxLimits.source_bytes`; formatting additionally checks output bytes.

`format_node(node, final_fodder?, options?, limits?)` formats edited expression
syntax. `RawAst::format` supplies its root and EOF fodder. Both serialize the
parts, reparse with independent `SyntaxLimits`, and apply the same passes as
`format_syntax_source`. They preserve the caller's arrays, never evaluate or
resolve imports, and reject malformed edited syntax. A binding/parameter fragment
can be serialized separately but needs an enclosing expression to be formatted.
Synthetic nodes may use `range: None`; their default filename is `<node>`.
This functional API preserves raw source material rather than exposing Go's
normalized Fodder types.

`FormatOptions::default()` selects two-space indentation, at most two blank lines,
single quotes, slash comments, pretty field names, unpadded arrays, padded objects
and implicit object addition. String styles are `DoubleQuotes`, `SingleQuotes`
and `PreserveQuotes`; comments use `HashComments`, `SlashComments` and
`PreserveComments`. Strings containing one quote kind use the other to avoid
escaping; strings containing both kinds and verbatim strings retain their spelling.
Text blocks use the formatter's current indentation and preserve the decoded
content, subject to fixed Go's removal of carriage returns. Nonpositive
indentation/blank-line options preserve the original
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

`Diagnostic::format_syntax(source)` renders raw-parser errors with token end
ranges, or point locations for EOF/lexer failures, without a final LF. Source
lookup is bounded to 1 MiB. `format_syntax_bytes(source)` additionally preserves
fixed Go's raw four-byte malformed-Unicode context, which may split UTF-8;
the String helper retains the normalized stored message. Neither method changes
the stored diagnostic or provides evaluator stack frames.
Computed-import ranges use a bounded operand reparse under default syntax budgets,
falling back to the opening token if that lookup fails.

`RawAst`, `format_node` and `cmd/jsonnetfmt` provide editable syntax and source
formatting. See the [recorded formatter checks](COMPATIBILITY.md#recorded-acceptance-boundary)
for the tested scope; these finite corpora do not prove equivalence for every input.

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
| TLA setter/reset, trace sink, evaluation hook, string-output mode or limits | Sources, ASTs and evaluated imports |
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
a callback. Separate instances can be used independently.

### Evaluation hooks and debugging

`Evaluator::set_eval_hook(hook?)` installs `EvalHook { before, after }` for all
four output methods; omit `hook` to disable it. Callbacks run around admitted
semantic expressions, including lazy children when demanded. `after` receives
`Success(DebugValue)` or an isolated `Failure(Diagnostic)`. Transparent local,
conditional and assertion bodies still receive paired callbacks. Callback errors
abort execution and leave the evaluator available for a later call. Replacing a
hook preserves import caches, so previously cached computations need not emit
new events.

Implementation-only standard-library wrappers and native nodes are omitted from
hook frames; their exportable source children remain observable. Every admitted
`node()`/`stack()` entry has a public semantic AST. A user filename such as
`<std>` does not by itself suppress events.

`EvalContext::location`, `source_range` and `evaluation_id` are immutable metadata.
The ID is unique within one execution and pairs its before/after events.
`node()` and `stack()` return independent semantic AST copies; stack order is
outermost first and includes direct expressions. Copying consumes execution work.
`variables()` lists sorted captured and active lexical bindings without forcing
them. Shadowed names can occur more than once; the innermost binding is used by
lookup. The internal `$std` alias can appear. `self`/`super` are omitted from the
list but may be looked up in an object context. These views do not change actual
interpreter lookup or parameter binding.

`peek(name)` returns a handle only for an already cached value. `lookup(name)`
explicitly forces the root thunk. `DebugValue::kind()` returns its category;
`display()` previews cached content without forcing children or assertions,
using `<unevaluated>`, `<evaluating>` and `<failed>` placeholders. Only cached
visible object fields appear. `json()` explicitly manifests children and can
invoke imports/assertions. Inspection suppresses recursive hook events and shares
execution step, depth, stack and output limits. Live context/value operations
expire when the callback returns; retain metadata, copied nodes or returned text/
JSON instead. Preview text is a MoonBit API contract, not Go's internal value
string representation.

`Debugger::new(evaluator?)` uses a configured evaluator or a new instance.
`breakpoint_locations(program)` returns semantic node ranges in traversal order;
it omits synthetic nodes and erased parentheses, so it is not a list of every Go
raw AST location. `set_breakpoint(program,line,column?)` chooses the first matching
range and returns its identity. Omit the column or use a negative column to match
the line. `active_breakpoints()` returns a fresh sorted array;
`clear_breakpoints(filename)` removes that file's entries.

`run(program,on_stop~,start_with_step?)` synchronously evaluates text and calls
the host at `Step`, `Breakpoint` or `Exception` stops. Return `Continue`, `Step`,
`Finish` or `Terminate`. A callback can wait for terminal/UI input. `Finish`
continues until that expression returns, then steps at the next nonliteral node.
Literals and internal standard-library nodes do not cause normal step stops.
Termination raises a runtime diagnostic; a later run starts normally. The
previous evaluation hook is restored after success or failure. Stop contexts have
the same lifetime and inspection rules as hooks. Exception views retain the
deepest failed lexical environment while callbacks unwind; errors still propagate.
Failure outcomes include the independently captured named/synthetic trace above.

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
- `import_ast(imported_from, imported_path) -> (Program?, String)` is an opt-in
  nullable query corresponding to Go ImportAST. A valid parse returns Some(program).
  Its first Syntax/Static failure raises and records nil under the resolved identity;
  later calls to this method return None and that identity. None is not a parsed
  Jsonnet `null` expression. Valid ASTs and bytes share the ordinary caches.
- `find_dependencies(imported_from, imported_paths) -> Array[String]` uses the
  static scanner below with the Evaluator's shared source/AST cache. Traversal
  state and scan budgets are fresh each time, and cached runtime values are not
  forced or cleared by the scan.

Queries apply current source/import-byte limits; parsed programs and scans also
recheck cached AST depth. Scans account cumulative bytes and request counts as
usual. Querying does not initialize the runtime or consume evaluation steps.
All queries raise `JsonnetError` and use the same non-reentry guard as execution.
`import_program`, ordinary evaluation and dependency scans remain strict: failed
parses retain bytes but do not install an invalid AST, and retries still fail.
Their failures do not seed the opt-in `import_ast` nil history. That history survives
ext/native/TLA/trace setters and resets, and `set_importer` clears it together with
all import caches. Importer/UTF-8 and resource errors never become successful nil;
cached nil results still obey current byte limits. A cached valid AST rechecks depth.
The original differential fixture calls the strict `import_program` operation;
that unchanged call still differs from Go's retry. The optional nullable entry
has a separate passing corpus under the [recorded acceptance contract](COMPATIBILITY.md#recorded-acceptance-boundary);
the original 20/21 result is retained.

## Lint analysis

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
failure covered by the recorded reference-crash exception contract. It is not
counted as a compatible output.

Limits abort analysis with JsonnetError; parse/import findings otherwise collect
across entries. Source, depth, import bytes/count and analysis steps are bounded.
The local-cycle and type-component graph walks are iterative; recursive index
expansion has a depth limit and graph traversal consumes analysis steps.
Unused-binding locations use the retained declaration-range start, with an empty
location when a manual or synthetic binding has no range. The recorded location
corpus covers 190/190 cases; this does not establish equivalence for every AST.

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
