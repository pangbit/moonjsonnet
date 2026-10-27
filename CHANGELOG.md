# Changelog

## 0.1.0 — Unreleased

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
- Fractional slice progression and signed 64-bit wrapping bitwise operators;
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
