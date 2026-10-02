# Compatibility: Jsonnet v0.21.0 language and standard-library subset

The language target is Jsonnet v0.21.0, without intentionally excluded language
constructs. The standard library is a documented subset. Passing
the committed corpus does not prove compatibility with all Jsonnet programs.
The official C++ v0.21.0 interpreter is a development-only oracle. Input, imports,
parameters and expected categories are committed under `tests/` and `examples/`.
Success comparisons parse JSON and ignore object order and insignificant whitespace.

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
visible object fields recursively; function equality is an error. Object assertions
are checked on field access/manifestation, including inherited assertions bound to
the final object. An unused error or failed assertion is not evaluated.

Numbers use IEEE-754 binary64. Division by zero and non-finite results are errors;
integer precision is not guaranteed above 2^53. Strings/indexing/length/substrings
use Unicode code points, not bytes, UTF-16 units or grapheme clusters. Paired Unicode
escapes are decoded; lone surrogate escapes are syntax errors, as in v0.21.0.
Source locations count code points.

Slices support omitted/null bounds, negative bounds and positive steps. Zero or
negative steps are errors in the reference language too. Formatting supports
mapping keys, flags, dynamic width/precision, length modifiers and every v0.21.0
conversion (`diuoxXeEfFgGcs%`). `tailstrict` forces supplied/default parameters
and uses a trampoline for tail calls; a 10,000-iteration regression verifies this.
Binary operators apply the reference's safe-integer checks and modulo-64 shifts;
bitwise complement accepts signed 64-bit operands.

`std` is an ordinary object with hidden function fields and `thisFile`. It can be
inherited, indexed, reflected and manifested. Hidden-field reflection lists this
implementation's available standard functions; it does not invent missing ones.
Standard functions not listed below report `Unsupported` when accessed on `std`.
There is no fallback to another interpreter.

## Standard library

Only the following functions are supported. Arity/named-argument violations are
`Runtime`; invalid types are `Type` unless an explicit assertion is involved.

| Function and parameter names | Behavior and restrictions |
| --- | --- |
| `extVar(x)` | Injected JSON value; missing name is `Runtime` |
| `type(x)` | Jsonnet type string |
| `isArray(v)`, `isBoolean(v)`, `isFunction(v)`, `isNumber(v)`, `isObject(v)`, `isString(v)` | Type predicates; do not manifest values |
| `length(x)` | Unicode string, array, visible object fields, or function parameter count |
| `objectFields(o)`, `objectFieldsAll(o)` | Sorted Unicode keys, excluding/including hidden fields |
| `objectHas(o,f)`, `objectHasAll(o,f)` | Membership excluding/including hidden fields |
| `map(func,arr)` | Lazy mapped array; accepts array or string |
| `filter(func,arr)` | Array filtering; predicate must return boolean |
| `foldl(func,arr,init)` | Left fold, preserving lazy accumulator semantics; array/string |
| `range(from,to)` | Inclusive integer range; arguments restricted to signed 32-bit integers |
| `join(sep,arr)` | String/array separator with like-typed entries; skips null entries |
| `split(str,c)` | Nonempty string delimiter; empty delimiter is `Runtime` |
| `substr(str,from,len)` | Code-point substring; nonnegative signed 32-bit indices; out-of-range start gives empty string |
| `strReplace(str,from,to)` | Nonoverlapping literal replacement; empty pattern rejected |
| `startsWith(a,b)`, `endsWith(a,b)` | String prefix/suffix checks |
| `parseJson(str)` | Core JSON parser with bounded nesting; malformed JSON is `Runtime` |
| `manifestJson(value)` | Sorted keys, four-space indentation |
| `toString(a)` | Strings unchanged; other manifestable values become compact JSON with Jsonnet spacing |
| `floor(x)`, `ceil(x)`, `abs(n)` | Finite binary64 arithmetic |
| `format(str,vals)` | Same formatting semantics as string `%` |
| `slice(indexable,index,end,step)` | Same semantics as array/string slice syntax |
| `char(n)`, `codepoint(str)` | Unicode scalar conversion / one-code-point string |
| `assertEqual(a,b)` | Returns true or reports `Assertion` |
| `lines(arr)` | Join non-null strings with a newline after each |

Integer-only standard function bounds and resource limits may reject inputs that
the reference accepts. Restricted argument domains return an error and are not
silently truncated. Standard-library numeric text uses the C locale, fixed integer
formatting or 17 significant digits, matching the pinned reference. CLI JSON
uses MoonBit core's JSON serialization; comparisons operate on parsed values.

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
