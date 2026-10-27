# Compatibility: Jsonnet v0.21.0

The language target is Jsonnet v0.21.0, without intentionally excluded language
constructs. The final conformance target covers every language rule and public
standard-library contract at Google Jsonnet commit
`bbb38f1020be1f5aed560928fb839b2c448cefb4`; unresolved or untested contracts are
not accepted as conforming. Go/C++ behavior is comparison evidence and cannot
override explicit normative requirements. All 163 members in the fixed Go standard-library reflection inventory
are registered; [surface coverage](GO-STDLIB-SURFACE.md) is distinct from behavioral equivalence. Passing
the committed corpus does not prove compatibility with all Jsonnet programs.
The official C++ v0.21.0 interpreter is a development-only oracle. Input, imports,
parameters and expected categories are committed under `tests/` and `examples/`.
Success comparisons parse JSON and ignore object order and insignificant whitespace;
historical non-finite aggregate scalar outputs use exact spelling checks instead. The Go
CLI output corpus also pins complete stdout bytes for JSON layout, plain strings
and YAML document streams. Multi-file fixtures separately compare complete file
contents and filename lists in isolated reference/local output directories.

## Implementation reference

[google/go-jsonnet](https://github.com/google/go-jsonnet) is the functional
implementation reference for language semantics, standard-library coverage,
embedding capabilities and CLI behavior. MoonBit APIs follow this project's host
contract; differences from the reference must be documented and tested.

The Go baseline is v0.21.0, commit `67968688d9952f50662e979fab1bef889d0d3e57`.
The differential runner compares identical inputs, imports and parameters and
records Go and C++ results separately, including failed and unsupported cases.
The existing C++ v0.21.0 results remain evidence for that baseline only. Selecting
go-jsonnet as a reference does not establish compatibility with it.

## Recorded acceptance boundary

The [fixed cross-platform evidence](https://github.com/pangbit/moonjsonnet/blob/c7f8a8e977e54ab7b0329c3069a7320a0eb81915/reports/GO-JSONNET-CROSS-PLATFORM-ACCEPTANCE.md)
records macOS ARM64 and Linux AMD64 with Go 1.24.0. These are recorded results,
not a claim that every release-preparation edit reruns the full reference suite.

| Corpus | Raw result / boundary |
| --- | --- |
| C++ v0.21.0 | 108 cases: 98 compatible, 10 declared differences, 0 skipped |
| Go whole CLI | ARM64 1132/1150; AMD64 1131/1150 |
| Go reusable evaluator | 20/21; strict `import_program` retry remains different |
| Go lint | 409/410; one reference internal crash remains a raw failure |
| Opt-in nullable `import_ast` | 13/13 cases, 37 observations; does not reclassify the original evaluator fixture |
| Formatting | 736/736 frozen checks, 178/178 upstream fixtures, 255/255 CLI checks; 4 identity/help checks separately |

The recorded acceptance contract permits 18 CLI and 1 lint reference-crash
exceptions, the separately tested opt-in `import_ast` API, and same-architecture
NaN behavior. Raw failures remain in the reports. AMD64 NaN behavior matches Go's
complete error output but still fails the frozen ARM64 success expectation.
These historical bounds do not establish current conformance or universal Go parity.
The subsequent immutability, finite-number, integer-index and YAML-error fixes
intentionally diverge from some frozen Go expectations. Those inputs and original
reports remain unchanged; the whole Go corpus has not been rerun for
these fixes. The current C++ recheck and declaration migrations are recorded in
[CI validation](https://github.com/pangbit/moonjsonnet/blob/main/docs/development/CI-VALIDATION.md);
the table above remains historical. Repository
[validation instructions](https://github.com/pangbit/moonjsonnet/blob/main/docs/development/VALIDATION.md)
describe reproduction; development fixtures and reports are excluded from the archive.

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

Numbers use IEEE-754 binary64. Division by zero and non-finite arithmetic
results are errors. Numeric tokens retain their original spelling and convert
when evaluated: overflow is a runtime error, unused overflow literals stay lazy,
and underflow can produce zero, matching the pinned Go reference.
`sum`/`avg` reject overflow at the first invalid addition, before later operands
or consumers are evaluated. Unused aggregates remain lazy;
integer precision is not guaranteed above 2^53. Strings/indexing/length/substrings
use Unicode code points, not bytes, UTF-16 units or grapheme clusters. Paired Unicode
escapes are decoded; lone surrogate escapes are syntax errors, as in v0.21.0.
Complete but invalid surrogate combinations (for example `\uD800\u0041`)
decode to U+FFFD. Normal quoted strings are validated when the parser consumes
their tokens, after full-source lexing; verbatim strings keep backslashes literal.
Source locations use one-based UTF-8 byte columns. AST source ranges have exclusive ends.
Repeated formal parameter names are Static errors, including in unused branches,
methods and manually supplied Program ASTs; nested scopes may still shadow names.
Empty text-block lines preserve their LF or CRLF bytes. The focused CRLF
regressions also verify that `|||-` removes one complete final LF or CRLF while
preserving preceding endings and content CR bytes. Retained source keeps its
original bytes independently of the canonical string value.

Array/string indices must be finite integers within bounds before conversion.
Slices support omitted/null bounds, negative bounds and positive steps. Fractional
bounds and steps retain their fractional progression. Array slices defer index
validation until an element is accessed; strings are strict. A fractional end
bound need not generate fractional indices. Zero or negative steps are errors in the reference language too. Formatting supports
mapping keys, flags, dynamic width/precision, length modifiers and every v0.21.0
conversion (`diuoxXeEfFgGcs%`). `tailstrict` forces supplied/default parameters
and uses a trampoline for tail calls; a 10,000-iteration regression verifies this.
Bitwise operators truncate operands to signed 64-bit integers, with shift counts
reduced modulo 64. Left shifts wrap at 64 bits and right shifts preserve the sign,
matching Go. Negative shift counts are rejected before truncation. Operands must
be within `[-2^63, 2^63]` before conversion. ARM64 maps the upper endpoint to
MaxInt64 and NaN to zero, and saturates complement operands before inversion.
AMD64 maps NaN and out-of-range conversions to MinInt64. These explicit paths
follow the pinned architecture's Go binary without an out-of-range native cast.
Results are converted back to binary64.

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
MoonJsonnet reproduces the pinned ARM64 and AMD64 results with explicit branches;
the boundary fixture is retained. Other architectures remain unverified.
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
| `length(x)` | Unicode string, array, visible object fields, or all declared function parameters including defaults; reflection does not force defaults or the body |
| `objectFields(o)`, `objectFieldsAll(o)` | Sorted Unicode keys, excluding/including hidden fields |
| `objectHas(o,f)`, `objectHasAll(o,f)` | Membership excluding/including hidden fields |
| `map(func,arr)` | Lazy mapped array; accepts array or string |
| `mapWithIndex(func,arr)` | Lazy mapped array; callback receives zero-based index and element; strings use Unicode code points |
| `makeArray(sz,func)` | Lazy generated array; callback receives index; signed 32-bit integer size, with negative sizes producing an empty array; callback arity checked when an element is used |
| `reverse(arr)` | New array in reverse order; elements remain lazy and the input is unchanged |
| `sort(arr,keyF=function(x)x)` | Stable array sort; optional key function evaluated once per element; numeric, string or lexicographic array keys; preserves original element thunks and input order for equal keys |
| `uniq`, `set`, `setUnion`, `setInter`, `setDiff`, `setMember` | Pinned upstream Jsonnet definitions, evaluated by the MoonBit runtime; optional key functions, lazy elements and left-hand representatives preserved |
| `mergePatch(target,patch)` | Recursive JSON merge patch with null deletion, visible fields, lazy retained values and scalar replacement |
| `all`, `any`, `filterMap`, `count`, `repeat`, `find` | Pinned source definitions; boolean short circuit and lazy retained values |
| `deepJoin(arr)` | Returns a String root unchanged or recursively concatenates String/Array leaves without separators; null and other leaf kinds reject. See the [scoped String composition review](#development-evidence-index) |
| `lines(arr)` | Appends a newline after every retained String, including empty strings; the fixed source skips null items and returns an empty String for empty/all-null inputs. Original arrays stay unchanged. See the [scoped String composition review](#development-evidence-index) |
| `flattenArrays(arrs)` | Concatenates one level of an array of arrays; requires outer member heads and keeps inner payloads lazy. Documentation names the parameter arr; named conformance remains unresolved. See the [scoped flatten review](#development-evidence-index) |
| `flattenDeepArray(value)` | Recursively flattens arrays, retaining null and all other non-array leaves; the fixed source also wraps scalar roots. Structure requires recursive leaf heads, while object fields and function bodies remain lazy. See the [scoped flatten review](#development-evidence-index) |
| `min`, `max`, `clamp` | Source numeric min/max and lazy clamp branches |
| `sum(arr)`, `avg(arr)` | Numeric left-to-right aggregation; avg rejects an empty array; each addition rejects non-finite results |
| `member(arr,x)`, `contains(arr,elem)` | Both validate the collection before the target and leave the target lazy for empty Arrays. Array member examines every equality predicate, including errors after a match; contains stops at its first match. String member follows findSubstr and returns false for an empty pattern. See the [scoped membership review](#development-evidence-index) |
| `minArray(arr,keyF=function(x)x,onEmpty=error ...)`, `maxArray(...)` | Stable Array extrema select onEmpty only when empty and leave keyF lazy on that branch. Nonempty Arrays skip onEmpty; explicit keys can leave discarded elements lazy. The initial key is compared even for a singleton; a failing key condition skips selection, while selected results remain required. See the [demand review](#development-evidence-index) and [comparison continuation](#development-evidence-index). Non-Array admission, exact callback counts and full comparator scope remain open |
| `$flatMapArray(func,arr)` | Reflected Go helper; flatMap behavior restricted to array input |
| `__compare`, `__compare_array`, `__array_less`, `__array_greater`, `__array_less_or_equal`, `__array_greater_or_equal` | Reflected upstream comparison helpers, including lexicographic nested arrays |
| `get`, `objectValues`, `objectValuesAll`, `objectKeysValues`, `objectKeysValuesAll`, `mapWithKey`, `prune` | Pinned Jsonnet definitions; hidden-field policy, lazy defaults/values and inherited self preserved |
| `objectRemoveKey(obj,key)` | Copies remaining fields including hidden fields, rebinds self and omits object assertions, matching Go's native implementation for simple objects; input is unchanged |
| `objectFieldsEx(obj,hidden)`, `objectHasEx(obj,fname,hidden)` | Native reflection with explicit hidden-field selection and reference parameter names |
| `primitiveEquals(x,y)`, `equals(x,y)` | Primitive comparison or recursive equality; unlike types compare false, same-type functions cannot be compared; parameter names follow Go's native override |
| `filter(func,arr)` | Array filtering; predicate must return boolean |
| `flatMap(func,arr)` | Validates the function before demanding the input; concatenates callback arrays or strings using Unicode code points; callback result heads are forced but returned array elements stay lazy; out-of-documented-kind return policies remain under review |
| `foldl(func,arr,init)` | Iterative left fold over array/string; empty input returns init without using func, the first callback may ignore init, and each intermediate result head is forced; elements and nested fields remain lazy |
| `foldr(func,arr,init)` | Iterative right fold over array/string; callback receives element then accumulator, with the same empty/initial/intermediate forcing rules as `foldl` |
| `range(from,to)` | Source-defined inclusive unit steps; finite endpoints are not narrowed, including fractional bounds with integral length; generated size remains subject to host limits |
| `join(sep,arr)` | String/array separator with like-typed non-null entries; null is skipped but empty items count toward delimiters. Validates the outer array before demanding the separator; nested array payloads stay lazy. See the [scoped contract review](#development-evidence-index) |
| `split(str,c)` | Source assertions validate str, then nonempty c; unlimited left-to-right splitting retains empty pieces. See the [scoped split review](#development-evidence-index) |
| `splitLimit(str,c,maxsplits)`, `splitLimitR(str,c,maxsplits)` | Validates str/c before demanding maxsplits; finite nonnegative integral bounds are not narrowed to Int32. -1 means unlimited; native R still scans from the right, with overlapping -1 cases unresolved against fixed source (SPL-R0). Fractional/other-negative limits remain rejected but unadjudicated. See the [scoped review](#development-evidence-index) |
| `lstripChars(str,chars)`, `rstripChars(str,chars)`, `stripChars(str,chars)` | Validates String input before demanding chars; empty input leaves chars lazy. Uses Unicode String-set membership or source-defined Array membership, inspecting every Array member even after a match while sharing element values. Supersedes the historical eager/short-circuit behavior; see the [scoped review](#development-evidence-index) |
| `trim(str)` | Unicode 15 White_Space trimming; zero-width space and BOM are retained |
| `isEmpty(str)` | String-only emptiness predicate |
| `equalsIgnoreCase(str1,str2)` | Unicode 15 simple case folding from pinned Go data, including Kelvin sign, sigma variants and supplementary letters; does not expand ß to ss or apply locale rules |
| `asciiLower(str)`, `asciiUpper(str)`, `stringChars(str)` | Pinned source definitions; ASCII-only case conversion and Unicode code-point array |
| `findSubstr(pat,str)` | All overlapping code-point offsets; empty pattern or string gives an empty array |
| `parseInt(str)` | Fixed official optional minus and ASCII decimal digits; separate finite Number multiply/add accumulation without an Int64 bound; plus, whitespace, prefixes and underscores reject. This supersedes the historical Go-oriented native range/sign behavior; see the [scoped review](#development-evidence-index) |
| `parseHex(str)`, `parseOctal(str)` | Pinned source Number digit accumulation without a host Int64 bound; no sign or radix prefix. The review leaves the hex helper's punctuation-alias discrepancy (HP0) unresolved |
| `escapeStringJson(str_)`, `escapeStringPython(str)`, `escapeStringBash(str_)`, `escapeStringDollars(str_)`, `escapeStringXML(str_)` | String coercion and context-specific escaping, including C0/C1 JSON controls |
| `resolvePath(f,r)` | Pinned lexical directory joining; does not normalize .. or treat r as an absolute replacement |
| `id(x)` | Eager identity; nested array/object values remain lazy |
| `remove(arr,elem)`, `removeAt(arr,i)` | Return a new array while preserving the original and its aliases; remove searches only through the first match, removeAt does not force elements; the public named-index contract remains under review |
| `$objectFlatMerge(x)` | Internal helper: merge simple objects with disjoint keys, preserving field visibility and bindings, rebinding self, dropping assertions; explicit object locals and inherited objects are rejected |
| `encodeUTF8(str)` | UTF-8 bytes, with BOM and zero characters preserved |
| `decodeUTF8(arr)` | Integer bytes in 0..255; each malformed UTF-8 byte becomes U+FFFD, including incomplete multibyte sequences |
| `base64(input)` | Standard padded alphabet with no line breaks; String codepoints 0..255 map directly to bytes, matching the corresponding byte Array. Codepoints above 255 error. For UTF-8 text, use `base64(encodeUTF8(str))`. Negative/fractional Array admission remains unresolved in the normative review |
| `base64DecodeBytes(str)`, `base64Decode(str)` | Return byte numbers / a String mapping each byte to the same-numbered Unicode codepoint. The deprecated String decoder does not decode UTF-8; use `decodeUTF8(base64DecodeBytes(str))` for UTF-8 text. Current parser observations: original UTF-8 byte length divisible by 4, only CR/LF ignored, complete padding required, nonzero unused pad bits accepted. These malformed-input observations and non-String admission are not normative acceptance |
| `substr(str,from,len)` | Source-defined code-point substring; validates types/length in source order and clips length to the available suffix before allocation; an empty result performs no character lookup |
| `strReplace(str,from,to)` | Nonoverlapping literal replacement; empty pattern rejected |
| `startsWith(a,b)`, `endsWith(a,b)` | String prefix/suffix checks |
| `parseJson(str)` | Core JSON parser with bounded nesting; malformed JSON is `Runtime` |
| `manifestJson(value)` | Sorted keys, four-space indentation, shortest round-trip decimal numbers without exponents; preserves negative zero |
| `manifestJsonEx(value,indent,newline='\n',key_val_sep=': ')`, `manifestJsonMinified(value)` | Custom layout or compact JSON; empty containers retain both surrounding newlines; JSON escapes C0 and U+2028/U+2029 but preserves HTML characters and C1 |
| `manifestPython(v)`, `manifestPythonVars(conf)` | Pinned source layout: Python True/False/None, sorted visible object fields, 17-digit numeric coercion; vars adds one assignment and newline per field |
| `manifestIni(ini)` | Optional main object and required sections object; sorted fields, array values emit repeated key lines, no escaping |
| `manifestXmlJsonml(value)` | Pinned source JsonML conversion; sorted visible attributes and paired tags; text and attribute values are emitted without automatic XML escaping |
| `manifestToml(value)`, `manifestTomlEx(value,indent)` | Native Go table/array-of-tables layout; default indent is two spaces; empty key is `''`; null and functions rejected; numeric coercion uses 17 significant digits |
| `manifestYamlDoc(value,indent_array_in_object=false,quote_keys=true)` | Native layout, shortest fixed-decimal numbers, newline-terminated block strings, conservative bare-key recognition; functions and nested errors fail the call |
| `manifestYamlStream(value,indent_array_in_object=false,c_document_end=true,quote_keys=true)` | Pinned source document separators and optional final marker; empty stream preserves separators and leaves unused document options lazy |
| `toString(a)` | Strings unchanged; other manifestable values become compact JSON with Jsonnet spacing |
| `floor(x)`, `ceil(x)` | Reject non-finite results |
| `abs(n)` | Go source rule: retain n if positive, otherwise negate; flips signed zero |
| `sqrt(x)`, `sin(x)`, `cos(x)`, `tan(x)`, `asin(x)`, `acos(x)`, `atan(x)`, `log(x)`, `exp(x)` | Numeric functions; non-finite results are Runtime errors |
| `hypot(x,y)`, `atan2(y,x)`, `pow(x,n)`, `modulo(x,y)` | Native numeric argument names and signed-zero handling; modulo rejects zero divisor |
| `round(x)` | Nearest integer, half away from zero, preserving negative zero |
| `mantissa(x)`, `exponent(x)` | Binary fraction and exponent, including subnormal normalization; exponent returns 0 for zero |
| `isEven(x)`, `isOdd(x)` | Parity of truncated numeric value |
| `isInteger(x)`, `isDecimal(x)` | Zero/nonzero fractional part |
| `pi`, `deg2rad(x)`, `rad2deg(x)`, `log2(x)`, `log10(x)`, `sign(n)`, `mod(a,b)` | Pinned source definitions; mod dispatches numeric modulo or string formatting |
| `xor(x,y)`, `xnor(x,y)` | Eager boolean-only operands |
| `format(str,vals)` | Same formatting semantics as string `%` |
| `slice(indexable,index,end,step)` | Same semantics as array/string slice syntax |
| `char(n)`, `codepoint(str)` | Integral identifier conversion / one-code-point string; scalar round trips and fractional-ID rejection reviewed; surrogate-ID policy remains unadjudicated |
| `assertEqual(a,b)` | Returns true or reports `Assertion` |
| `lines(arr)` | Join non-null strings with a newline after each |
| `sha256(s)` | SHA-256 of UTF-8 string bytes, lowercase hexadecimal; rounds consume the evaluation step budget |
| `md5(s)`, `sha1(s)`, `sha512(s)`, `sha3(s)` | MD5, SHA-1, SHA-512 and SHA3-512 of UTF-8 string bytes; lowercase hexadecimal; require strings and consume a work step per compression/permutation round |

Non-finite numbers are invalid Jsonnet values. Aggregate evaluation fails before
they can reach comparison, string conversion or indexing. JSON and YAML
manifestation also reject internal non-finite values defensively. Frozen Go
Infinity/NaN outputs remain historical compatibility evidence, not normative passes.

The [string contract review](#development-evidence-index)
records the fixed substring definition's clipping and forcing order, and char's
integer-identifier criterion. Original Go truncation and early substring-error
fixtures remain preserved as comparison evidence; they do not establish these
normative contracts and have not been rerun for the changes.

Trigonometric, inverse trigonometric, exponential and power algorithms preserve
the fixed Go 1.24.0 ARM64/AMD64 reference's operation order, including explicit fused
multiply-add and Payne–Hanek reduction for huge angles. The reference ARM64
exponential's lowest subnormal boundary is preserved (`std.exp(-745)` is 0).
These exact results do not establish equivalence to every Go architecture or
toolchain. MoonBit implementations and the native numeric C stub preserve the
architecture-specific paths and one-rounding multiply-add without linking a
reference interpreter.

Integer-only standard function bounds and resource limits may reject inputs that
the reference accepts. Restricted argument domains return an error and are not
silently truncated. String coercion (`toString`, string concatenation and `%s`)
uses the C locale, fixed integer formatting or 17 significant digits.
`manifestJson` follows Go's shortest round-trip digits in fixed decimal notation,
including subnormal numbers and signed zero. It uses MoonBit core's shortest
conversion and expands exponents; expanded output remains subject to the output
byte limit. C++ uses the older numeric text rule for both operations, so the
shared numeric-string fixture records both exact outputs as a declared difference.
CLI JSON follows the pinned Go layout described in [CLI](CLI.md), with complete
stdout-byte comparisons in its dedicated corpus.

JSON and Python output read only visible fields; empty or hidden-only objects do
not force assertions. Visible fields still trigger object assertions. JSON
output traverses lazy values directly, enforcing depth and byte budgets. For
`std.manifestJsonMinified({x:self})`, the pinned Go binary fatally overflows its
stack (exit 2); this implementation returns `Limit`. This input remains an
explicit differential failure and is covered by the recorded reference-crash
exception contract; it is not relabeled as a compatible expected-error pass.

Deletion preserves Jsonnet immutability: deleting
index 1 from `[1,2,3,4]` returns `[1,3,4]` while leaving the original array as
`[1,2,3,4]`. The returned array, original, aliases, and previously created lazy
maps or slices remain independent of subsequent deletions. Payload thunks remain
lazy; querying the result length does not force its elements.
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

YAML rendering propagates nested errors and rejects functions at every level.
`{a:[1,error 'nested']}` therefore fails instead of returning partial text.
Frozen Go truncation and reference-crash cases remain in the differential
fixtures. Depth, step and output limits propagate inside YAML object fields.

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

`length` on a function counts all declared parameters, including defaults, under
the fixed public contract; C++ counting corroborates the documentation. This
intentionally differs from Go's required-only count. Duplicate formal parameters
are rejected statically under the specification's unique-name rule, even where
frozen Go fixtures accept them. Original comparison inputs/results remain
unchanged and have not been rerun for these fixes.
`foldl` and `foldr` follow the fixed source definitions: an empty sequence does
not use the callback, and the first callback can ignore the original initial
value. The tailstrict recursion requires every new accumulator head, while
nested payloads and unused elements remain lazy. The implementation remains
iterative. This intentionally supersedes the old strict-Go argument assertions;
original frozen comparison inputs and results are retained without being rerun.
See the [array contract review](#development-evidence-index)
for independently established expectations and unresolved boundaries.

## Development evidence index

The scoped reviews referenced above are summarized here so this guide remains
usable in the distribution archive. The full review files are retained under
`docs/development/` in the source repository, together with their original
failures, independent expectations and bounded regression results. The filenames
below identify those repository records; they are not files shipped in the
archive. A scoped result does not establish whole-function conformance, and the
unresolved boundaries remain unaccepted.

| Repository review file | Scope and retained limits |
| --- | --- |
| `SPEC-COMPOSED-STRINGS-2026-10-23.md` | `deepJoin` and `lines`: ordered String composition, required leaf errors, unused calls and immutable inputs. `lines` null skipping is a fixed-source obligation beyond the Array-of-Strings prose. |
| `SPEC-FLATTEN-2026-10-23.md` | One-level and recursive flattening, structure demand and retained lazy payloads. `flattenArrays` has conflicting public/source parameter names (`arr`/`arrs`); broader source-only input admission and the printed Array-concatenation rule remain unresolved. |
| `SPEC-MEMBERSHIP-2026-10-23.md` | `member` demands all Array equality predicates; `contains` stops at its first match. Empty Array targets stay lazy, and String membership follows `findSubstr`, including its empty-pattern result. |
| `SPEC-EXTREMA-DEMAND-2026-10-23.md` | Array extrema: empty/nonempty branch demand, singleton key comparison, lazy discarded payloads and stable selection. Non-Array admission and exact callback counts remain outside this acceptance. |
| `SPEC-EXTREMA-COMPARISON-2026-10-23.md` | Extrema comparison demands required key heads, recursive Array prefixes and selected values. The printed comparison-rule conflict is retained; these cases do not accept the full comparator domain. |
| `SPEC-JOIN-2026-10-23.md` | Ordered String/Array joining, null skipping, delimiter placement, outer-array validation before separator demand, and lazy inner Array payloads. The printed Array-concatenation conflict remains open. |
| `SPEC-SPLIT-LIMITS-2026-10-23.md` | Ordered String/delimiter/limit validation, retained empty pieces, Unicode preservation and large integral limits. Right-split overlapping unlimited cases (SPL-R0), fractional limits and other negative limits remain unadjudicated. |
| `SPEC-STRIP-CHARS-2026-10-23.md` | Character-set stripping, empty-input laziness, String validation before membership, strict Array membership and preserved input/aliases. No extra normalization or whitespace policy is introduced. |
| `SPEC-INTEGER-PARSERS-2026-10-23.md` | Decimal/octal/hexadecimal String grammars and finite Number accumulation without a host Int64 bound. The hex punctuation-alias discrepancy (HP0) remains unresolved. |
| `SPEC-STRING-CONTRACTS-REVIEW.md` | Scalar `char`/`codepoint`, substring clipping and forcing order, overlapping search, character arrays and prefix/suffix matching. Surrogate identifiers, non-String source extensions and fractional generated cardinality remain unadjudicated. |
| `SPEC-ARRAY-COMBINATORS-REVIEW.md` | Array construction, folds, flatMap and slicing with lazy payloads and immutable inputs. Negative/fractional cardinality, nonboolean filter results and source-only input extensions remain open; observations are not normative passes. |

## Known boundaries

External code and named top-level parameters are available in the embedding API
and CLI. Top-level functions are applied exactly once; other top-level values
ignore TLAs. Code parameters have separate scopes, cached values/errors and
synthetic filenames, but imports originate at the host root. The CLI supports
string/code/file/environment forms and last-assignment wins. File reads retain
the project's restricted-root policy. Reusable evaluator/reset/import caches and
semantic/raw AST APIs are available; see [API](API.md).
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
Import search paths and stack/trace controls are available; see [CLI](CLI.md).

The POSIX host accepts regular files within one canonical root. Text imports
require valid UTF-8; binary imports do not decode their contents. Custom
importers have a separate trust contract. No JS/Wasm/Windows host, LSP or package
manager is provided. Standard-library registration and formatter availability
do not remove the behavioral boundaries recorded above.

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

See the recorded acceptance boundary above for passed, failed and difference
counts. Unsupported cases are retained in the
corpus, and previously discovered defects remain as regression tests.
