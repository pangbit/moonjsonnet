# Compatibility: Jsonnet v0.21.0 language and standard-library subset

The language target is Jsonnet v0.21.0, without intentionally excluded language
constructs. The standard library is a documented subset. Passing
the committed corpus does not prove compatibility with all Jsonnet programs.
The official C++ v0.21.0 interpreter is a development-only oracle. Input, imports,
parameters and expected categories are committed under `tests/` and `examples/`.
Success comparisons parse JSON and ignore object order and insignificant whitespace.

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

Numbers use IEEE-754 binary64. Division by zero and non-finite results are errors;
integer precision is not guaranteed above 2^53. Strings/indexing/length/substrings
use Unicode code points, not bytes, UTF-16 units or grapheme clusters. Paired Unicode
escapes are decoded; lone surrogate escapes are syntax errors, as in v0.21.0.
Source locations count code points.

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
be within `[-2^63, 2^63)` before conversion; results are converted back to binary64.
Bitwise complement retains the same operand range.

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
MoonJsonnet rejects it with `Runtime`, preserving a defined conversion boundary;
`bitwise-int64-upper-boundary` remains a Go differential failure. C++ also rejects
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
| `extVar(x)` | Injected JSON value; missing name is `Runtime` |
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
| `substr(str,from,len)` | Code-point substring; nonnegative signed 32-bit indices; out-of-range start gives empty string |
| `strReplace(str,from,to)` | Nonoverlapping literal replacement; empty pattern rejected |
| `startsWith(a,b)`, `endsWith(a,b)` | String prefix/suffix checks |
| `parseJson(str)` | Core JSON parser with bounded nesting; malformed JSON is `Runtime` |
| `manifestJson(value)` | Sorted keys, four-space indentation, shortest round-trip decimal numbers without exponents; preserves negative zero |
| `toString(a)` | Strings unchanged; other manifestable values become compact JSON with Jsonnet spacing |
| `floor(x)`, `ceil(x)`, `abs(n)` | Finite binary64 arithmetic |
| `format(str,vals)` | Same formatting semantics as string `%` |
| `slice(indexable,index,end,step)` | Same semantics as array/string slice syntax |
| `char(n)`, `codepoint(str)` | Unicode scalar conversion / one-code-point string |
| `assertEqual(a,b)` | Returns true or reports `Assertion` |
| `lines(arr)` | Join non-null strings with a newline after each |
| `sha256(s)` | SHA-256 of UTF-8 string bytes, lowercase hexadecimal; rounds consume the evaluation step budget |

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

The POSIX host accepts regular files within one canonical root. Text imports
require valid UTF-8; binary imports do not decode their contents. Custom
importers have a separate trust contract. No JS/Wasm/Windows host, formatter, LSP,
package manager, native callbacks or full standard library are provided.
Duplicate JSON keys passed to `parseJson` follow the core parser behavior.
Error categories and locations are stable concepts, not exact upstream wording.

See the acceptance report linked from [validation](VALIDATION.md) for passed,
failed, skipped and unsupported counts. Unsupported cases are retained in the
corpus, and previously discovered defects remain as regression tests.
