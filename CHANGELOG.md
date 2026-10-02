# Changelog

## 0.1.0 — Unreleased

- Independent located parser, static name validation and lazy native evaluator.
- Closures/defaults, comprehensions, layered inheritance, visibility and assertions.
- Complete language surface: text blocks, slices, bitwise and array ordering,
  percent formatting, strict tail-call trampoline, comprehension locals and binary imports.
- Ordinary hidden-field std object with reflection, inheritance and thisFile.
- Upstream language/formatting corpus and byte-preserving binary host tests.
- JSON external variables, custom imports, bounded POSIX file host and CLI.
- Explicit standard-library subset, configurable limits and structured diagnostics.
- Lazy `makeArray`, Unicode-aware `mapWithIndex` and nonmutating `reverse`.
- Go-compatible required function arity and iterative `foldl` argument/result evaluation.
- Go-compatible fractional indexing/slicing and signed 64-bit wrapping bitwise operators,
  with explicit rejection of the unrepresentable positive `2^63` conversion boundary.
- Go-compatible shortest fixed decimal numbers in `manifestJson`, preserving signed
  zero and output limits while retaining the separate string-coercion contract.
- Pinned go-jsonnet differential reports retain mismatches separately from C++ acceptance.
- Three runnable examples, fixed-reference differential and host integration tests.
- Apache-2.0 metadata, generated API interfaces and reproducible release checks.
