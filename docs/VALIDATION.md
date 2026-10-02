# Reproduce validation locally

Use the toolchain in [VERSIONS](VERSIONS.md). Run from the repository root:

```sh
moon check --target native --deny-warn
moon test --target native --deny-warn
moon test --target native --release --deny-warn
moon info
moon fmt
moon fmt --check
moon doc
moon build --target native --release --deny-warn
```

Reference interpreter (development only; not a runtime dependency):

```sh
git clone --depth 1 --branch v0.21.0 https://github.com/google/jsonnet.git /tmp/jsonnet-v0.21.0
git -C /tmp/jsonnet-v0.21.0 rev-parse HEAD
make -C /tmp/jsonnet-v0.21.0 -j4 jsonnet
moon run tools/differential.mbtx /tmp/jsonnet-v0.21.0/jsonnet _build/native/release/build/cmd/main/main.exe
moon run tools/upstream-language.mbtx /tmp/jsonnet-v0.21.0 _build/native/release/build/cmd/main/main.exe
moon run tools/integration.mbtx _build/native/release/build/cmd/main/main.exe
moon run tools/consumer.mbtx
```

Verify reference SHA `bbb38f1020be1f5aed560928fb839b2c448cefb4`.
The differential runner checks reference version and keeps every fixture,
comparing parsed JSON for success cases and failures for error cases. It records
per-case outcomes, counts, reference version and source commit in
`_build/differential/report.json`. `unsupported-reference-error` distinguishes a
function the pinned C++ reference itself rejects. Structured local error-category
checks are covered by the library and host integration suites.

The upstream language runner verifies the exact reference commit, runs 32
language fixture files, separately evaluates the upstream formatting assertions,
and checks parser/static/function error fixtures. It preserves upstream inputs;
the isolated formatting expressions retain their original source line numbers
in report names. Two fixtures also require the out-of-scope `setInter` or
`mergePatch` standard functions; those are retained and reported separately as
unsupported standard-library dependencies, never as language passes. The report
is written to `_build/upstream-language/report.json`.

Run ASan **after committing source**, because its isolated checkout copies only
tracked files. It copies the installed runtime to a temporary directory, disables
mimalloc in that copy, instruments native code/stubs, and runs tests plus the host
integration suite. It does not modify the installed MoonBit toolchain.

```sh
moon run tools/asan.mbtx
```

Leak detection is disabled for portability with Apple Clang; this check covers
address errors, not a LeakSanitizer proof. Test scripts use MoonBit script mode
and `moonbitlang/async`; commands may need access to Moon's dependency cache.
`tools/consumer.mbtx` extracts the actual Mooncakes archive into a temporary
workspace and compiles/tests a separate module using only public APIs.

See the repository's `reports/` directory for commit-bound acceptance evidence.
Generated raw artifacts remain in `_build` and are not published to Mooncakes.
