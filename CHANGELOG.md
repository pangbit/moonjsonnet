# Changelog

## 0.2.1

Prepared from incremental corrections and finite contract reviews made on
2026-10-27 through 2026-10-29, building on the existing 0.2.0 project. These are
the release candidate's changes, previously listed as Unreleased. Publication
status and its timestamp belong to the
[registry record](https://mooncakes.io/docs/pangbit/moonjsonnet@0.2.1); these notes
do not assert publication or a source tag. Public MoonBit API signatures are
unchanged. Complete Jsonnet v0.21.0 conformance remains unestablished.

- Keep `manifestTomlEx` indentation lazy until output needs an indented prefix;
  flat fields and empty output no longer evaluate an unused indentation argument.
- Make `reverse` use the fixed length and lazy indexing definition. String input
  produces an Array of one-character Strings in reverse Unicode code-point order;
  Array payloads remain lazy and original values stay unchanged.
- Correct `hypot`'s required named parameters to `a,b`; positional calls are
  unchanged and legacy `x,y` named calls are rejected.
- Normalize positive subnormal inputs in the AMD64 logarithm implementation
  and preserve `atan2` quadrants when the intermediate ratio underflows to zero.

- Make `trim(str)` use the fixed seven-character endpoint set and make
  `isEmpty(str)` follow `length(str) == 0` for supported String, Array, Object
  and Function values, preserving unused payloads and original aliases.

- Make `round(x)` follow fixed `floor(x + 0.5)` and make `isInteger`/`isDecimal`
  compare that rounded value with x. Negative halves round upward; IEEE addition
  also changes some large odd integers before the comparison.

- Make Number output in `manifestJsonEx`, `manifestJson` and
  `manifestJsonMinified` follow the fixed Jsonnet definition's ordinary String
  coercion. For example, `0.1` now produces `0.10000000000000001`; signed zero,
  finite-value checks, lazy options and exact output-byte limits are preserved.
- Make JSON String values and object keys follow `escapeStringJson`: escape
  C0/C1 controls and leave U+2028/U+2029 raw. Ordinary Unicode, hidden fields,
  lazy options and UTF-8 output-byte limits retain their existing behavior.
- Make YAML Number output in `manifestYamlDoc` and `manifestYamlStream` follow
  ordinary String coercion, including scientific notation for small values;
  signed zero, finite checks, lazy options and output-byte limits are preserved.
- Make YAML keys with `quote_keys=false` follow the fixed Jsonnet character,
  reserved-word and numeric-shape predicates: `nan`, `1e3` and `x0xffz` are bare,
  while `_`, `0b29` and `1.0e309` are quoted. Forced quoting is unchanged.
- Make `equalsIgnoreCase` follow the fixed ASCII-lowering definition. Distinct
  non-ASCII variants such as K/k, Σ/σ and ß/ẞ now compare false; `asciiUpper` and
  `asciiLower` retain their existing behavior.
- Make `equals` accept the fixed definition's required `a,b` parameter names
  and reject legacy `x,y` names. Positional equality and `primitiveEquals`
  retain their existing behavior.

## 0.2.0

Release notes for version 0.2.0. Publication status and its timestamp are recorded
by [Mooncakes](https://mooncakes.io/docs/pangbit/moonjsonnet@0.2.0); these notes do
not assert a publication date or a source tag. Public MoonBit API signatures are
unchanged from the previous public repository revision; corrected Jsonnet
behavior can change results or reject inputs previously accepted.

- Correct `base64` String encoding to map codepoints 0..255 directly to bytes:
  `base64('é')` now returns `"6Q=="`, matching `base64([233])`.
  For the former UTF-8 encoding intent,
  use `base64(encodeUTF8(str))`.
- Correct the deprecated `base64Decode` String result to map each decoded byte
  to its Unicode codepoint: `base64Decode('6Q==')` returns `"é"`,
  while `base64Decode('w6k=')` returns `"Ã©"`.
  Decode UTF-8 text explicitly with `decodeUTF8(base64DecodeBytes(str))`;
  the byte decoder and UTF-8 decoder are unchanged.
- Preserve immutable arrays during removal; reject aggregate overflow when
  evaluated and fractional array/string indices; propagate nested YAML errors
  and reject YAML function values. Array slices retain lazy index validation.
- Preserve source-defined demand, defaults and input admission in array
  combinators, sorting, extrema, membership, deletion and numeric reductions.
  Unused values and formatting options remain lazy where the fixed definition
  requires it; errors from demanded computations propagate.
- Correct string stripping, split limits, substring demand, decimal parsing and
  CRLF text-block handling; reject duplicate formal parameters statically.
- Reject scalar YAML document roots and non-finite values nested in parsed JSON;
  preserve ordinary JSON keys such as `self`, `super` and `$` when returning
  parsed data or native callback results.
- Pin validation scripts to the async version used by the previous successful
  CI, retaining the fixed MoonBit toolchain and explicit native CI profiles.
- Make packaged compatibility references self-contained and document explicit
  UTF-8 migration. Historical reference mismatches and unresolved specification
  questions remain recorded in [compatibility](docs/reference/COMPATIBILITY.md);
  this release does not claim complete specification conformance.

## 0.1.0 — 2026-10-13

Initial publication, confirmed by the public
[Mooncakes version record](https://mooncakes.io/docs/pangbit/moonjsonnet@0.1.0).
The original capability notes below retain the historical scope; they do not
establish full specification conformance or describe the later fixes above.

- All 163 reflected go-jsonnet v0.21.0 standard-library members, with bounded
  differential evidence and explicit compatibility differences.
- Native MoonBit `sha256` over UTF-8 strings with bounded work and known-answer tests.

- Independent located parser, static name validation and lazy native evaluator.
- Closures/defaults, comprehensions, layered inheritance, visibility and assertions.
- Complete language surface: text blocks, slices, bitwise and array ordering,
  percent formatting, strict tail-call trampoline, comprehension locals and binary imports.
- Ordinary hidden-field std object with reflection, inheritance and thisFile.
- Upstream language/formatting corpus and byte-preserving binary host tests.
- JSON/Jsonnet external variables and top-level arguments, custom imports,
  bounded POSIX file host and CLI.
- Reusable evaluator and import caches, semantic and lossless editable ASTs,
  formatter/linter/dependency CLIs, hooks, debugger and configurable diagnostics.
- Configurable limits and documented host/compatibility boundaries.
- Lazy `makeArray`, Unicode-aware `mapWithIndex` and nonmutating `reverse`.
- Go-compatible `flatMap` over arrays/Unicode strings and iterative `foldr`, with
  lazy array elements and bounded intermediate allocation.
- Stable `sort` with an optional key function, cached keys, lazy payloads and
  iterative merging bounded by the evaluation step limit.
- Go-compatible required function arity and iterative `foldl` argument/result evaluation.
- Fractional indexing/slicing and signed 64-bit wrapping bitwise operators;
  explicit ARM64/AMD64 conversion paths preserve the pinned Go behavior for
  positive `2^63` and NaN without an out-of-range C cast.
- Go-compatible shortest fixed decimal numbers in `manifestJson`, preserving signed
  zero and output limits while retaining the separate string-coercion contract.
- Go-style fractional powers for dynamic format precision, with upstream attribution
  and regression coverage for fixed, scientific and general conversions.
- Pinned go-jsonnet differential reports retain mismatches separately from C++ acceptance.
- Three runnable examples, fixed-reference differential and host integration tests.
- Apache-2.0 metadata, per-file adaptation notices, generated API interfaces
  and archive consumer checks. See [compatibility](docs/reference/COMPATIBILITY.md) for
  retained Go failures and the 10 declared C++ differences.
