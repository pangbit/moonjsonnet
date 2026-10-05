# Compatibility: Jsonnet v0.21.0 language and standard-library subset

The language target is Jsonnet v0.21.0, without intentionally excluded language
constructs. The standard library is a documented subset. Passing
the committed corpus does not prove compatibility with all Jsonnet programs.
The official C++ v0.21.0 interpreter is a development-only oracle. Input, imports,
parameters and expected categories are committed under `tests/` and `examples/`.
Success comparisons parse JSON and ignore object order and insignificant whitespace;
non-finite aggregate scalar outputs use exact spelling checks instead. The Go
CLI output corpus also pins complete stdout bytes for JSON layout, plain strings
and YAML document streams. Multi-file fixtures separately compare complete file
contents and filename lists in isolated reference/local output directories.

## Implementation reference

[google/go-jsonnet](https://github.com/google/go-jsonnet) is the functional
implementation reference for future language semantics, standard-library coverage,
embedding capabilities and CLI behavior. MoonBit APIs follow this project's host
contract; differences from the reference must be documented and tested.

The Go baseline is v0.21.0, commit `67968688d9952f50662e979fab1bef889d0d3e57`.
The expanded overall parity objective, complete standard-library inventory and
CLI/embedding gaps are tracked in [GO-PARITY](GO-PARITY.md). Overall parity is not complete.
The differential runner compares identical inputs, imports and parameters and
records Go and C++ results separately, including failed and unsupported cases.
The existing C++ v0.21.0 results remain evidence for that baseline only. Selecting
go-jsonnet as a reference does not establish compatibility with it. See
[validation](VALIDATION.md) for reproduction and report locations.

## Language

Supported: JSON scalar literals; double/single/verbatim strings and indented text
blocks (`|||`, `|||-`); `#`, `//`, `/* */`
comments; recursive `local`; conditionals; lexical functions and closures;
positional/named/default arguments and `tailstrict`; lazy arrays and fields;
array/object/string indexing and array/string slices;
array comprehensions with nested `for`/`if`; object comprehensions with local bindings;
object methods and locals; computed string/null keys; object `+` and juxtaposition;
`self`, `$`, field access through `super`; `:`, `::`, `:::` visibility;
`+:`, `+::`, `+:::`; expression and object assertions; `error`; `import`, `importstr`,
`importbin`. Binary imports preserve arbitrary bytes as arrays of numbers.

Arithmetic `+ - * / %`, string `%` formatting, boolean `! && ||`, bitwise
`~ & | ^ << >>`, equality `== !=`, and `in` are supported.
Ordering supports numbers, Unicode strings and lexicographic arrays. Equality compares arrays and
visible object fields recursively; same-type function equality is an error,
while unlike types compare false. Object equality short-circuits on field names
before accessing values or triggering assertions. Object assertions
are checked on field access/manifestation, including inherited assertions bound to
the final object. An unused error or failed assertion is not evaluated.

Numbers use IEEE-754 binary64. Division by zero and non-finite ordinary arithmetic
results are errors. Numeric tokens retain their original spelling and convert
when evaluated: overflow is a runtime error, unused overflow literals stay lazy,
and underflow can produce zero, matching the pinned Go reference.
As in the pinned Go reference, `sum`/`avg` retain overflow
Infinity/NaN, which unary signs, comparisons and string conversion can consume;
integer precision is not guaranteed above 2^53. Strings/indexing/length/substrings
use Unicode code points, not bytes, UTF-16 units or grapheme clusters. Paired Unicode
escapes are decoded; lone surrogate escapes are syntax errors, as in v0.21.0.
Complete but invalid surrogate combinations (for example `\uD800\u0041`)
decode to U+FFFD. Normal quoted strings are validated when the parser consumes
their tokens, after full-source lexing; verbatim strings keep backslashes literal.
Source locations use one-based UTF-8 byte columns. AST source ranges have exclusive ends.

Array/string indices truncate toward zero before checking bounds, matching Go;
this includes negative fractions between -1 and 0 selecting the first element.
Slices support omitted/null bounds, negative bounds and positive steps. Fractional
bounds and steps retain their fractional progression; each selected index is
then truncated. Zero or negative steps are errors in the reference language too. Formatting supports
mapping keys, flags, dynamic width/precision, length modifiers and every v0.21.0
conversion (`diuoxXeEfFgGcs%`). `tailstrict` forces supplied/default parameters
and uses a trampoline for tail calls; a 10,000-iteration regression verifies this.
Bitwise operators truncate operands to signed 64-bit integers, with shift counts
reduced modulo 64. Left shifts wrap at 64 bits and right shifts preserve the sign,
matching Go. Negative shift counts are rejected before truncation. Operands must
be within `[-2^63, 2^63]` before conversion; the upper endpoint explicitly maps
to MaxInt64. NaN explicitly maps to zero. Complement saturates out-of-range values
before inversion, matching the pinned arm64 Go binary; no out-of-range native
cast is performed. Results are converted back to binary64.

Dynamic fractional format precision uses Go's exponent decomposition and ordered
scaling for powers of ten. Integral precision and scientific mantissa scaling
retain MoonBit core's power function. Arithmetic overflow/underflow and output
limits are still checked. This resolves the retained fractional-format fixture;
it does not claim bit-for-bit agreement for every transcendental calculation on
every platform. The shared C++ fixture asserts both exact outputs as a declared
difference. Attribution and the Go BSD license are included in `NOTICE` and
`licenses/GO-BSD-3-Clause.txt`.

The pinned Go implementation admits the positive `2^63` boundary because its
floating-point range check rounds `MaxInt64` upward. Conversion of that value to
`int64` is outside the representable range and is
[implementation-dependent in Go](https://go.dev/ref/spec#Conversions_between_numeric_types).
MoonJsonnet now reproduces the pinned arm64 result with an explicit branch;
`bitwise-int64-upper-boundary` is retained and passes. This is not evidence for
Go's conversion behavior on other architectures, which remains to be validated.
C++ also rejects
fractional indices, operands beyond its safe-integer bound and positive left-shift
overflow. Those previously shared cases now record explicit C++/MoonJsonnet outcomes.

`std` is an ordinary object with hidden function fields and `thisFile`. It can be
inherited, indexed, reflected and manifested. Hidden-field reflection lists this
implementation's available standard functions; it does not invent missing ones.
Standard functions not listed below report `Unsupported` when accessed on `std`.
There is no fallback to another interpreter.

## Standard library

Go v0.21.0 crashes internally when `objectRemoveKey` receives an inherited object
(`extendedObject` to `simpleObject` assertion). The retained
`object-operations-inheritance` fixture records this Go difference. Removing a key
from an object whose retained fields use object-local bindings also causes a Go
internal error (`object-remove-local-bindings`); MoonJsonnet preserves those bindings.
MoonJsonnet copies the remaining layers and reports a normal missing-field error
if a retained field accesses the removed key through `self`; it does not reproduce
the reference crash. This is not counted as a compatible pass.

Only the following functions are supported. Arity/named-argument violations are
`Runtime`; invalid types are `Type` unless an explicit assertion is involved.

| Function and parameter names | Behavior and restrictions |
| --- | --- |
| `extVar(x)` | Memoized JSON value or lazy Jsonnet code in a clean scope; missing/cyclic names are `Runtime` |
| `type(x)` | Jsonnet type string |
| `isArray(v)`, `isBoolean(v)`, `isFunction(v)`, `isNumber(v)`, `isObject(v)`, `isString(v)` | Type predicates; do not manifest values |
| `length(x)` | Unicode string, array, visible object fields, or required function parameter count (excluding defaults, as in Go) |
| `objectFields(o)`, `objectFieldsAll(o)` | Sorted Unicode keys, excluding/including hidden fields |
| `objectHas(o,f)`, `objectHasAll(o,f)` | Membership excluding/including hidden fields |
| `map(func,arr)` | Lazy mapped array; accepts array or string |
| `mapWithIndex(func,arr)` | Lazy mapped array; callback receives zero-based index and element; strings use Unicode code points |
| `makeArray(sz,func)` | Lazy generated array; callback receives index; signed 32-bit integer size, with negative sizes producing an empty array; callback arity checked when an element is used |
| `reverse(arr)` | New array in reverse order; elements remain lazy and the input is unchanged |
| `sort(arr,keyF=function(x)x)` | Stable array sort; optional key function evaluated once per element; numeric, string or lexicographic array keys; preserves original element thunks and input order for equal keys |
| `uniq`, `set`, `setUnion`, `setInter`, `setDiff`, `setMember` | Pinned upstream Jsonnet definitions, evaluated by the MoonBit runtime; optional key functions, lazy elements and left-hand representatives preserved |
| `mergePatch(target,patch)` | Recursive JSON merge patch with null deletion, visible fields, lazy retained values and scalar replacement |
| `all`, `any`, `filterMap`, `flattenArrays`, `flattenDeepArray`, `count`, `repeat`, `find`, `deepJoin` | Pinned source definitions; boolean short circuit, lazy retained values, nested flattening and Unicode strings |
| `min`, `max`, `clamp` | Source numeric min/max and lazy clamp branches |
| `sum(arr)`, `avg(arr)` | Numeric left-to-right aggregation; avg rejects an empty array; overflow retains Infinity/NaN as in Go |
| `member(arr,x)`, `contains(arr,elem)` | Native short-circuit membership; member also accepts a string substring (including empty substring), contains requires an array |
| `minArray(arr,keyF=function(x)x,onEmpty=error ...)`, `maxArray(...)` | Native stable extrema; force elements, compute each key once, preserve lazy fields, force explicitly supplied onEmpty even when nonempty |
| `$flatMapArray(func,arr)` | Reflected Go helper; flatMap behavior restricted to array input |
| `__compare`, `__compare_array`, `__array_less`, `__array_greater`, `__array_less_or_equal`, `__array_greater_or_equal` | Reflected upstream comparison helpers, including lexicographic nested arrays |
| `get`, `objectValues`, `objectValuesAll`, `objectKeysValues`, `objectKeysValuesAll`, `mapWithKey`, `prune` | Pinned Jsonnet definitions; hidden-field policy, lazy defaults/values and inherited self preserved |
| `objectRemoveKey(obj,key)` | Copies remaining fields including hidden fields, rebinds self and omits object assertions, matching Go's native implementation for simple objects; input is unchanged |
| `objectFieldsEx(obj,hidden)`, `objectHasEx(obj,fname,hidden)` | Native reflection with explicit hidden-field selection and reference parameter names |
| `primitiveEquals(x,y)`, `equals(x,y)` | Primitive comparison or recursive equality; unlike types compare false, same-type functions cannot be compared; parameter names follow Go's native override |
| `filter(func,arr)` | Array filtering; predicate must return boolean |
| `flatMap(func,arr)` | Concatenates callback arrays or strings; string input uses Unicode code points; callback results are forced but returned array elements stay lazy; null results are errors |
| `foldl(func,arr,init)` | Iterative left fold over array/string; forces function, sequence, initial value and each callback result; elements and nested fields remain lazy |
| `foldr(func,arr,init)` | Iterative right fold over array/string; callback receives element then accumulator; same forcing contract as `foldl` |
| `range(from,to)` | Inclusive integer range; arguments restricted to signed 32-bit integers |
| `join(sep,arr)` | String/array separator with like-typed entries; skips null entries |
| `split(str,c)` | Nonempty string delimiter; empty delimiter is `Runtime` |
| `splitLimit(str,c,maxsplits)`, `splitLimitR(str,c,maxsplits)` | Split from left/right with nonempty delimiter; -1 means unlimited, otherwise nonnegative signed 32-bit integer limit |
| `lstripChars(str,chars)`, `rstripChars(str,chars)`, `stripChars(str,chars)` | Eager arguments, Unicode character membership in a string or array; array membership short-circuits; empty input does not inspect the character set |
| `trim(str)` | Unicode 15 White_Space trimming; zero-width space and BOM are retained |
| `isEmpty(str)` | String-only emptiness predicate |
| `equalsIgnoreCase(str1,str2)` | Unicode 15 simple case folding from pinned Go data, including Kelvin sign, sigma variants and supplementary letters; does not expand ß to ss or apply locale rules |
| `asciiLower(str)`, `asciiUpper(str)`, `stringChars(str)` | Pinned source definitions; ASCII-only case conversion and Unicode code-point array |
| `findSubstr(pat,str)` | All overlapping code-point offsets; empty pattern or string gives an empty array |
| `parseInt(str)` | Optional +/-, ASCII decimal digits, signed Int64 range before conversion to double; rejects whitespace, prefixes and underscores |
| `parseHex(str)`, `parseOctal(str)` | Pinned source digit accumulation; no sign or radix prefix; differs from parseInt's Int64 bound |
| `escapeStringJson(str_)`, `escapeStringPython(str)`, `escapeStringBash(str_)`, `escapeStringDollars(str_)`, `escapeStringXML(str_)` | String coercion and context-specific escaping, including C0/C1 JSON controls |
| `resolvePath(f,r)` | Pinned lexical directory joining; does not normalize .. or treat r as an absolute replacement |
| `id(x)` | Eager identity; nested array/object values remain lazy |
| `remove(arr,elem)`, `removeAt(arr,i)` | Remove the first equal value or an integer index; preserve Go's mutation of input slots, then return an independent shorter array; remove searches only through the first match, removeAt does not force elements |
| `$objectFlatMerge(x)` | Internal helper: merge simple objects with disjoint keys, preserving field visibility and bindings, rebinding self, dropping assertions; explicit object locals and inherited objects are rejected |
| `encodeUTF8(str)` | UTF-8 bytes, with BOM and zero characters preserved |
| `decodeUTF8(arr)` | Integer bytes in 0..255; each malformed UTF-8 byte becomes U+FFFD, including incomplete multibyte sequences |
| `base64(input)` | Standard padded alphabet; accepts a byte array or a string with code points <=255, then encodes the string's UTF-8 bytes |
| `base64DecodeBytes(str)`, `base64Decode(str)` | Original UTF-8 byte length must be divisible by 4; ignore CR/LF only; require complete padding, accept nonzero unused pad bits; text output follows decodeUTF8 replacement rules |
| `substr(str,from,len)` | Code-point substring; nonnegative signed 32-bit indices; out-of-range start gives empty string |
| `strReplace(str,from,to)` | Nonoverlapping literal replacement; empty pattern rejected |
| `startsWith(a,b)`, `endsWith(a,b)` | String prefix/suffix checks |
| `parseJson(str)` | Core JSON parser with bounded nesting; malformed JSON is `Runtime` |
| `manifestJson(value)` | Sorted keys, four-space indentation, shortest round-trip decimal numbers without exponents; preserves negative zero |
| `manifestJsonEx(value,indent,newline='\n',key_val_sep=': ')`, `manifestJsonMinified(value)` | Custom layout or compact JSON; empty containers retain both surrounding newlines; JSON escapes C0 and U+2028/U+2029 but preserves HTML characters and C1 |
| `manifestPython(v)`, `manifestPythonVars(conf)` | Pinned source layout: Python True/False/None, sorted visible object fields, 17-digit numeric coercion; vars adds one assignment and newline per field |
| `manifestIni(ini)` | Optional main object and required sections object; sorted fields, array values emit repeated key lines, no escaping |
| `manifestXmlJsonml(value)` | Pinned source JsonML conversion; sorted visible attributes and paired tags; text and attribute values are emitted without automatic XML escaping |
| `manifestToml(value)`, `manifestTomlEx(value,indent)` | Native Go table/array-of-tables layout; default indent is two spaces; empty key is `''`; null and functions rejected; numeric coercion uses 17 significant digits |
| `manifestYamlDoc(value,indent_array_in_object=false,quote_keys=true)` | Native layout, shortest fixed-decimal numbers, newline-terminated block strings, conservative bare-key recognition; function values render as empty text |
| `manifestYamlStream(value,indent_array_in_object=false,c_document_end=true,quote_keys=true)` | Pinned source document separators and optional final marker; empty stream preserves separators and leaves unused document options lazy |
| `toString(a)` | Strings unchanged; other manifestable values become compact JSON with Jsonnet spacing |
| `floor(x)`, `ceil(x)` | Reject non-finite results |
| `abs(n)` | Go source rule: retain n if positive, otherwise negate; preserves non-finite values and flips signed zero |
| `sqrt(x)`, `sin(x)`, `cos(x)`, `tan(x)`, `asin(x)`, `acos(x)`, `atan(x)`, `log(x)`, `exp(x)` | Numeric functions; non-finite results are Runtime errors; finite outputs from non-finite inputs are accepted |
| `hypot(x,y)`, `atan2(y,x)`, `pow(x,n)`, `modulo(x,y)` | Native numeric argument names, signed-zero and non-finite special cases; modulo rejects zero divisor |
| `round(x)` | Nearest integer, half away from zero, preserving negative zero |
| `mantissa(x)`, `exponent(x)` | Binary fraction and exponent, including subnormal normalization; exponent returns 0 for zero/Infinity/NaN |
| `isEven(x)`, `isOdd(x)` | Parity of truncated numeric value; Infinity/NaN yield false/true respectively |
| `isInteger(x)`, `isDecimal(x)` | Zero/nonzero fractional part; Infinity/NaN yield false/true respectively |
| `pi`, `deg2rad(x)`, `rad2deg(x)`, `log2(x)`, `log10(x)`, `sign(n)`, `mod(a,b)` | Pinned source definitions; mod dispatches numeric modulo or string formatting |
| `xor(x,y)`, `xnor(x,y)` | Eager boolean-only operands |
| `format(str,vals)` | Same formatting semantics as string `%` |
| `slice(indexable,index,end,step)` | Same semantics as array/string slice syntax |
| `char(n)`, `codepoint(str)` | Unicode scalar conversion / one-code-point string |
| `assertEqual(a,b)` | Returns true or reports `Assertion` |
| `lines(arr)` | Join non-null strings with a newline after each |
| `sha256(s)` | SHA-256 of UTF-8 string bytes, lowercase hexadecimal; rounds consume the evaluation step budget |
| `md5(s)`, `sha1(s)`, `sha512(s)`, `sha3(s)` | MD5, SHA-1, SHA-512 and SHA3-512 of UTF-8 string bytes; lowercase hexadecimal; require strings and consume a work step per compression/permutation round |

Non-finite aggregate values manifest as `+Inf`, `-Inf`, or `NaN`, including in
arrays/objects, matching Go. These tokens are outside strict JSON. The returned
MoonBit `Json::Number` retains the numeric value and its spelling for `stringify`.
Numeric formatting rejects non-finite operands; `%s` uses their string spelling.
NaN comparison follows Go's comparator (`<`/`>` false, `<=`/`>=` true), while NaN
equality remains false. NaN index/character/bitwise conversion explicitly uses
zero to match the pinned arm64 reference without a non-finite native cast.

Trigonometric, inverse trigonometric, exponential and power algorithms preserve
the fixed Go 1.24.0 ARM64 reference's operation order, including explicit fused
multiply-add and Payne–Hanek reduction for huge angles. The reference ARM64
exponential's lowest subnormal boundary is preserved (`std.exp(-745)` is 0).
These exact results do not establish equivalence to every Go architecture or
toolchain. The algorithms are implemented in MoonBit; a scalar C `fma` wrapper
provides one-rounding multiply-add without linking a reference interpreter.

Integer-only standard function bounds and resource limits may reject inputs that
the reference accepts. Restricted argument domains return an error and are not
silently truncated. String coercion (`toString`, string concatenation and `%s`)
uses the C locale, fixed integer formatting or 17 significant digits.
`manifestJson` follows Go's shortest round-trip digits in fixed decimal notation,
including subnormal numbers and signed zero. It uses MoonBit core's shortest
conversion and expands exponents; expanded output remains subject to the output
byte limit. C++ uses the older numeric text rule for both operations, so the
shared numeric-string fixture records both exact outputs as a declared difference. CLI JSON
uses MoonBit core's JSON serialization; comparisons operate on parsed values.

JSON and Python output read only visible fields; empty or hidden-only objects do
not force assertions. Visible fields still trigger object assertions. JSON
output traverses lazy values directly, enforcing depth and byte budgets. For
`std.manifestJsonMinified({x:self})`, the pinned Go binary fatally overflows its
stack (exit 2); this implementation returns `Limit`. This input remains an
explicit differential failure, not an expected-error pass or a final accepted
compatibility exception.

Deletion follows the pinned Go implementation's observable mutation: deleting
index 1 from `[1,2,3,4]` returns `[1,3,4]` while leaving the original array as
`[1,3,4,4]`. The returned array is independent; removing from it does not mutate
the original again. `map`, `mapWithIndex` and array slices defer reading the slot
until their element is demanded, and `filter` reads the selected slot after its
predicate, so they observe these changes. Ordinary concatenation copies slots.
Out-of-bounds `removeAt` inputs cause an internal Go crash but return `Runtime`
here; those cases remain differential failures.

Go's `$objectFlatMerge` is designed for desugared comprehensions. Top-level
object literals gain an implicit `$` local in Go and crash when passed directly
to this helper, as do explicit object locals and inherited objects. Nested
objects without locals and desugared comprehensions work and are covered by
passing cases. This implementation safely merges simple top-level literals;
all observed reference crashes remain failed inputs, including duplicate-field
and eager-error examples that crash before reaching those checks in Go.

TOML/YAML native string quoting escapes C0/C1 controls but preserves HTML and
U+2028/U+2029, unlike native JSON output. TOML renders fields in sorted key order
before grouping scalar output ahead of sections, preserving evaluation order.
YAML bare keys follow Go's case-sensitive binary and unanchored hexadecimal
checks, decimal underscores, overflow/underflow and reserved-word rules.

The Go YAML object renderer ignores recursive rendering errors. This can return
partial text, such as `"a":\n- 1\n` for `{a:[1,error 'nested']}`. These successful
partial results are preserved. If later fields need evaluation, the reference
can internally crash with `Saving empty traceElement on stack`; that input is
retained as a differential failure. MoonJsonnet keeps valid VM state. Depth,
step and output limits always propagate, including inside YAML object fields.

`parseYaml(str)` parses block/flow collections, quoted/plain/block scalars,
anchors, aliases, merge keys, tags and Go-style document streams. YAML 1.1
`yes/no/on/off/y/n` spellings resolve to booleans; octal and prefixed integers,
floating-point values and explicit scalar tags follow the pinned reference.
Timestamps remain strings. Mapping keys are converted to strings, with Go's
binary32 shortest format for floating keys; null, collection and unsigned
64-bit integer keys are rejected. Non-finite values cannot become JSON, while
non-finite keys use `.inf`, `-.inf`, `.nan`.

Only unindented `---` followed by whitespace activates the reference's stream
splitting; each chunk decodes its first document, and duplicate mapping keys
overwrite earlier keys. Aliases and merge expansion are bounded by step, depth
and intermediate output budgets. An empty input returns Runtime where the pinned
Go implementation crashes. Collisions between differently typed keys that
convert to the same JSON name may depend on Go map iteration; general YAML
behavioral equivalence is not proven by the current corpus.

The bundled MoonBit syntax parser and its local fixes are documented in
`internal/yaml/README.md`, with its MIT license preserved. No external YAML
library or executable is needed at runtime. Explicit tags, scalar resolution and
stream handling are implemented locally; the upstream JSON loader is not used.

New sequence functions follow the pinned Go implementation. In particular,
`makeArray` uses the parameter name `sz`, rejects fractional sizes, returns an
empty array for negative sizes, and defers callback arity errors until an
element is used. C++ v0.21.0 uses `size`, truncates fractional sizes, rejects
negative sizes and requires exactly one declared callback parameter up front.
`reverse` accepts only arrays, as in Go; C++ also accepts strings (returning an
array of characters) and an empty object (returning an empty array).
The new sequence corpus is checked against Go; the original C++ corpus is
retained unchanged. Sequence allocation consumes the evaluation step budget
even when generated elements are never forced.

`length` on a function excludes defaulted parameters, as in Go; C++ counts all
declared parameters. `foldl` follows Go's strict argument and intermediate-result
evaluation. It does not deeply manifest the accumulator or force unused array
elements. This changes the earlier C++-based behavior for unused erroneous
functions/initial values. The shared corpus preserves these inputs and verifies
the exact differing outcomes separately from compatibility passes.

## Known boundaries

External code and named top-level parameters are available in the embedding API
and CLI. Top-level functions are applied exactly once; other top-level values
ignore TLAs. Code parameters have separate scopes, cached values/errors and
synthetic filenames, but imports originate at the host root. The CLI supports
string/code/file/environment forms and last-assignment wins. File reads retain
the project's restricted-root policy. Reusable VM/reset/AST capabilities remain pending.
CLI inline (`-e`), stdin (`-`), `--` and bytewise short-option expansion are now
available. Anonymous entry `std.thisFile` and import origin are empty, with
synthetic diagnostic filenames. Argument/evaluation/output failures exit 1.
Stdin retains the bounded-read and strict UTF-8 host policy. `-S` plain strings,
`-y` JSON documents with YAML stream framing and their embedding APIs are now
available. Default JSON formatting follows the fixed Go CLI serializer.
String mode rejects other types before traversing them; stream mode first deeply
manifests the result, requires an array and ignores `-S`. Multi-file output and
automatic output-directory creation are also available through `-m`/`-c` and
`evaluate_multi`. Multi mode takes precedence over stream mode; raw multi strings
have no added newline. Like Go, `-c` applies to ordinary output and multi data
parents, while stream/list parents must already exist. Identical output content
preserves modification time; I/O failure can leave partial files and lists.
Import search paths, stack/trace options and other CLI capabilities remain pending.

The POSIX host accepts regular files within one canonical root. Text imports
require valid UTF-8; binary imports do not decode their contents. Custom
importers have a separate trust contract. No JS/Wasm/Windows host, formatter, LSP,
package manager or full standard library are provided.

Host native functions and trace sinks are available through `evaluate` and
`fs.evaluate_file`; see the [embedding contract](API.md). Native calls bind
arguments by parameter name/order, fully manifest visible JSON and assertions,
then eagerly copy the returned JSON. Unknown native names return null. Trace
defaults to stderr with Go's `TRACE: filename:line message` format; the filesystem
host reports canonical filenames. Relative/alias diagnostic filename parity and
Go panic recovery are not claimed. Native callbacks and trace sinks execute
trusted host code outside the interpreter's preemptive control.
Duplicate JSON keys passed to `parseJson` follow the core parser behavior.
Error categories and locations are stable concepts, not exact upstream wording.

See the acceptance report linked from [validation](VALIDATION.md) for passed,
failed, skipped and unsupported counts. Unsupported cases are retained in the
corpus, and previously discovered defects remain as regression tests.
