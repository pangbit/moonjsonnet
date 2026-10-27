# Differential validation infrastructure

## Historical validator repair

The following records the original validator repair and its historical corpus,
not the current candidate's result. The 0.2.0 reconciliation below supersedes
the five stale declarations without rewriting those earlier results.

The C++ shared suite retains all 108 cases and the same 10 declared differences. This change corrects verification of existing declarations; it changes no product behavior, test input, reference outcome, threshold or exception policy.

The two fold cases declare MoonJsonnet Runtime errors from the literal `error 'unused'`. The validator now requires exit 1, empty stdout, an exact `RUNTIME ERROR: unused` first line and supported stack continuations. Other classes/messages, internal failures and arbitrary exceptions are rejected. The old location-style substring `: Runtime:` could neither recognize the current CLI nor validate its necessary message.

The fractional-format case keeps the existing exact C++ v0.21.0 output. MoonJsonnet's complete output is selected only for two proven native profiles: Linux/x86_64 and Darwin/arm64. Both reference and CLI binaries must match that host platform, and C++ must identify itself as v0.21.0 in a clean checkout of bbb38f1020be1f5aed560928fb839b2c448cefb4. Unsupported profiles and references fail closed.

`tests/reference/fractional-format-evidence.json` contains the exact complete Go/Moon outputs from the original 2026-10-09 archives. Go was 1.24.0, go-jsonnet v0.21.0 at 67968688d9952f50662e979fab1bef889d0d3e57. Linux source bc1d3c3 ends in 2039; macOS source a021c19 ends in 2003. The archived complete strings, source commits and archive SHA256 are also pinned in the validator; no current CI output, rounding tolerance or epsilon supplies a golden. Unredacted archives remain local; this compact synthetic-case evidence contains no environment identifiers.

Regression tests prove valid/invalid error classification, exact strings, unknown platform/reference rejection, native binary identity and altered-byte/provenance rejection. Run them with `moon test tools/differential.mbtx --deny-warn`; standalone tests do not execute the script main. CI runs these before the shared comparison and retains every existing later check.

Classification changes are explicit: Linux's seven recognized declarations become ten by recognizing fold-lazy, fold-empty and the existing architecture-bound fractional declaration. macOS's eight become ten by recognizing the two folds. Ordinary passed count remains 98, total remains 108, and skipped remains 0. None belongs to the separate 19 approved Go internal-reference-crash exceptions.

## Script dependency and platform constraints

The [CI workflow](../../.github/workflows/ci.yml) uses MoonBit
`0.10.14+7d59c7ec9` with `moonbitlang/async@0.22.4`. All `tools/*.mbtx`
imports from that module name the same version, including `fs` and `shell`.
The versioned script import syntax is documented in the
[Moon script guide](https://docs.moonbitlang.com/en/latest/toolchain/moon/script-mode.html).
Unversioned imports resolve the newest version in the local registry index;
`moon update` refreshes that index, not the explicit script version.

Both jobs in the [previous successful CI run](https://github.com/pangbit/moonjsonnet/actions/runs/38343391121)
used async 0.22.4 with this compiler. The
[first 0.2.0 candidate CI](https://github.com/pangbit/moonjsonnet/actions/runs/40456212952)
resolved async 0.22.5 and stopped before running tests: its `moon.pkg` field
`max_concurrent_tests` is unsupported by the pinned toolchain. The original
failure remains visible. No compiler upgrade, dependency-source edit or
skipped assertion is used to resolve it.

The cached 0.22.4 module manifest declares no external module dependencies;
its core imports use the installed SDK. Its registry archive checksum is
`2ffdb85cb229cfe9219161a7f2b959215a79a0d75b7e642cb346713f168a1457`.
The product module itself has no external runtime module dependency. This pin
therefore constrains the standalone validation dependency, not product behavior.

CI selects `ubuntu-24.04` for Linux/x86_64 and `macos-15` for Darwin/arm64 and
checks `uname` before validation. These match the two profiles admitted by the
fixed fractional-format evidence. Runner labels follow the
[GitHub hosted-runner reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners).
Runner-image revisions, system C toolchains, action major-version tags and the
MoonBit installer endpoint remain external inputs. This is a bounded dependency
and architecture constraint, not a claim of fully hermetic third-party inputs.
The C++ reference remains bound to its existing commit.

For an offline local check, first provision the exact dependency in the normal
cache, then use `moon check tools/differential.mbtx --frozen --deny-warn -j 1`.
A missing cache is a setup failure; do not substitute a newer dependency.
After a source change, CI must pass at the exact new commit before publication.

## 0.2.0 declarations after independent semantic fixes

[CI run 40457347281](https://github.com/pangbit/moonjsonnet/actions/runs/40457347281)
tested `d3c429a49186f2503772b359c2f6e49a7ff04863` on both supported profiles.
Each job passed 864 native debug and 864 native release tests, then recorded
**97 passed, 6 failed, 5 declared reference differences, 0 skipped** from 108
C++ comparison cases. The later language, integration and consumer steps were
skipped. The run remains failed; changing declarations does not turn that
historical execution into a successful run.

The five obsolete declarations still described behavior predating independent
normative fixes. All original input strings and their case names remain in
[the corpus](../../tests/differential.json). The migrations are:

| Case / unchanged source | Old MoonJsonnet declaration | Current independent requirement and fixture |
| --- | --- | --- |
| `fold-lazy`: `std.foldl(function(a,b)b, [1,2], error 'unused')` | Runtime `unused`; C++ result `2` | Literal `2` required on both sides. The initial accumulator is a lazy argument ignored by the first callback; later recursive accumulator heads remain strict. |
| `fold-empty`: `std.foldl(error 'unused', [], 1)` | Runtime `unused`; C++ result `1` | Literal `1` required on both sides. The source base case returns `running` without calling `func`. |
| `length`: `[std.length({a:1,b::2}),std.length([1,2]),std.length(function(a,b=2)a)]` | `[1,2,1]`; C++ `[1,2,2]` | Literal `[1,2,2]` required on both sides: the public function counts all parameters, including defaults. |
| `noninteger-index`: `[1][0.5]` | Result `1`; C++ Runtime error | Both must exit 1 with empty stdout and runtime diagnostics. The selected index must be an integer in the array's bounds. |
| `slice-fraction`: `[1,2][0.5:]` | Result `[1,2]`; C++ Runtime error | Both must exit 1 with empty stdout and runtime diagnostics when manifestation demands the first fractional index. Lazy slice length is a different case. |

These expectations come from the fixed
[foldl and slice definitions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet),
[function length documentation](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#std-length),
and [array-index rule](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#execution).
Existing independent regressions are [fold demand](../../spec_array_fold_test.mbt),
[parameter count](../../spec_length_test.mbt), and [index/slice demand](../../spec_index_test.mbt).
The earlier [fold failures/fixes](SPEC-ARRAY-COMBINATORS-EVIDENCE-2026-10-22.md)
and [index failures/fixes](SPEC-P0-EVIDENCE-2026-10-22.md) remain recorded. Agreement
between the two interpreters is a comparison result, not its normative basis.
The exact CLI message in the index fixture is an implementation diagnostic check;
the specification requires failure but does not prescribe its wording.

### Fractional character conversion

The fixed [char documentation](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#std-char)
requires the returned character's integer identifier to be the supplied `n`.
[codepoint](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#std-codepoint)
is its inverse. The fixed `%c` numeric branch calls `std.char(val)` without a
rounding operation (`stdlib/std.jsonnet`, lines 699–701). There is no character
with integer identifier 65.5; returning `A` silently changes the argument to 65.
MoonJsonnet therefore retains its existing rejection. C++ v0.21.0 truncation is a
reference difference, not an instruction to undo the independently established
[char criterion](SPEC-STRING-CONTRACTS-REVIEW.md) or its
[original failures and fix](SPEC-STRING-CONTRACTS-EVIDENCE-2026-10-22.md).

The original `format-char-fraction` source
`['%c' % 65.5, std.char(65.5)]` remains unchanged. C++'s exact result is `["A","A"]`;
MoonJsonnet must exit 1 with empty stdout and the exact first line
`RUNTIME ERROR: Codepoints must be integers, got 65.5`, followed only by supported
stack continuations. This uses the existing strict error validator, which rejects
unrelated exceptions, wrong messages and internal errors. No error wildcard or
successful-output tolerance is added.

That first formatting error prevents the array's second element from executing.
A separate `char-fraction-direct` input, `std.char(65.5)`, requires the same
MoonJsonnet error and C++ result `"A"`. The existing
[scalar tests](../../spec_string_scalar_test.mbt) independently exercise direct
conversion, type consumers and codepoint consumers; the
[call tests](../../spec_string_calls_test.mbt) retain unused-call laziness.
Surrogate handling and other fractional formatting policies are not adjudicated
by this change.

The retained fixed documents match the inventory's hashes: `stdlib.html`
`0eb80c0ccaf781c4c2c1bc06a22d2d6e57f9866f41c0b62431b5ca4f510e6853`,
`spec.html` `bbac3701ef0316fc29de6c543049ae8f0f78c876bdd94fbf6ab845b2023a720a`,
and `stdlib/std.jsonnet`
`e76dd6b8e51a2ca041b292dadea9c5521aeea5781b0ffe7c2c683865e7e45351`.
The failed run's Linux report SHA-256 is
`dbfbcabc107363fd72730a6235f3bec459360c427ef07279760d3ab81ec8e046`;
both original platform reports and logs remain attached to that run and retained
locally. Neither is edited by this migration.

The revised corpus has 109 inputs (the original 108 plus one direct-char probe)
and seven exact C++ declarations. These are fixture counts, not a new passing
result. New CI must execute this corpus and the previously skipped later stages.
Existing Go-specific expectations, separate Go fixtures and archived reports are
unchanged; no new Go result or full conformance claim follows. The product
implementation and public interfaces are unchanged by this repair.
