# Language clauses: independent reviewed subsets

This stage starts at `84e7e20`. The
[oracle written before probes](SPEC-LANGUAGE-REVIEW.md) fixes expectations from
Google Jsonnet `bbb38f1020be1f5aed560928fb839b2c448cefb4`, independently of Go/C++
execution. Tests and oracle are committed as `2dd6dd4`. No interpreter defect was
found in the two selected gaps, and no product implementation or public API was
changed. The only first-run failure was a test-input syntax mistake, retained
with its original sources and log rather than reported as a product fix.

## What is actually covered

[Function tests](../../spec_language_function_test.mbt) add six assertion groups:

- Exact definition/caller/formal scope, forward defaults, reordered names and
  interleaved optional/required parameters.
- Explicit argument override and unused error/recursive defaults.
- Native counters proving shared default thunks once per call and no unused
  callback execution.
- Runtime binding rejection before argument/default/body callback execution.
- Parse-time rejection of unused invalid defaults/bodies/named arguments and
  unavailable caller variables.
- Inherited method defaults distinguishing final self from lexical super.

[Object tests](../../spec_language_object_test.mbt) add seven assertion groups:

- Computed key scope excludes the new object's self/locals; a nested key can
  refer to the enclosing object's self.
- Original/derived fields distinguish self, super, root `$` and nested self.
- Inherited assertions use final derived self, including hidden field access.
- Recursive JSON conversion checks assertion-only objects even without visible
  fields; shape inspection and excluded hidden values remain lazy.
- Native counters verify assertion reuse, lazy success messages and selected
  payload nonexecution after an assertion failure.
- All nine visibility separator pairs compare manifested objects and direct
  field access, including hidden overridden functions.
- Demanded nested functions and errors reject with explicit Type/Runtime
  categories; hidden functions are omitted without execution.

Counters observe host callbacks as an additional forcing/cache check; exact
Jsonnet results and parse/evaluation categories remain the normative assertions.
No assertion chooses an order between unrelated simultaneous failures.

## Clause inventory and limits

[The matrix](SPEC-LANGUAGE-MATRIX.md) enumerates all 70 named inference rules in
the pinned specification and adds 24 initial prose/grammar obligations. It maps
24 manually reviewed test blocks, including existing lexical/index/import
regressions. There are 41 rows with reviewed subsets and 53 entirely unreviewed
rows. A row or populated dimension is never a complete-conformance verdict.
Shared test blocks are not counted again for each referencing rule.

The [mapping input](../../tests/spec-language-coverage.json) records exact test
declarations, assertion excerpts and the reviewed semantic meaning.
[The generator](../../tools/spec-language-matrix.mbtx) validates those locations,
source hashes, fixed rule enumeration and implementation paths. It emits both
Markdown and [machine-readable data](spec-language-matrix.json); it neither
infers execution from names nor converts unknown coverage into passing results.

Every unmapped named rule remains open. The 24 prose/grammar rows are an initial
inventory: full lexical/grammar/desugaring decomposition and additional
normal/error/lazy/boundary cases are still required. This work changes no public
stdlib coverage count: the earlier 35/153 figures describe partial dimensions,
not complete functions. The eleven array observations, removeAt parameter-name
conflict, Unicode surrogate ambiguity and other unresolved contracts remain.
[Reference compatibility](SPEC-LANGUAGE-COMPARISON-2026-10-22.md) is explicitly
unknown for this stage because no fresh Go/C++ run was performed.

## Local execution identity

Platform: Darwin arm64. Existing tools: moon/moonrun 0.1.20260920 (914d7da),
moonc v0.10.14+7d59c7ec9. Native commands use `--frozen --deny-warn -j 2`.
Raw evidence is under `/tmp/moonjsonnet-language-contracts.sSg2Ad`;
temporary files are not an archival delivery guarantee.
The test source identity is `2dd6dd43f444a5e96f87399a49f9fe932ca3a54e`, tree
`1927d17e517427829c5b3b55b0e0dc22f4dd073f`. Subsequent changes in this stage
only add matrix tooling/data and documentation; the interpreter and test sources
used for these native runs remain unchanged.

| Check | Observed result |
| --- | --- |
| First independent run | 12/13; method-input separator typo, no product defect |
| Corrected independent checkpoint | 13/13 |
| Full native debug aggregate | 457/457 |
| Native release, the nine matrix-linked test files | 33/33 |
| Warning-denying native check | Passed |
| `moon info` then `moon fmt` at checkpoint | Passed; public .mbti unchanged |
| Matrix source/locations/assertion anchors | 70 named rules + 24 prose rows validated |
| Matrix negative controls | Changed assertion and changed reference bytes both rejected before output |
| Documentation at matrix checkpoint | 126 files / 957 links passed |

Exact execution commands were `moon test --target native --frozen --deny-warn
-j 2` and `moon test spec_language_function_test.mbt
spec_language_object_test.mbt spec_static_test.mbt spec_import_scope_test.mbt
spec_index_test.mbt spec_foundation_types_test.mbt spec_text_block_test.mbt
spec_text_chomp_test.mbt spec_manifest_wbtest.mbt --target native --release
--frozen --deny-warn -j 2`, with `RUST_LOG=error`.

| Artifact | SHA-256 |
| --- | --- |
| Original pre-probe oracle | 3465ebf6d982043f12270709f9da2bab2c3bea87ff8d0bb036a98f81944438aa |
| Original first-run log | f3517f8456be0dc3631c44be38c0fd52ef3fc35e069110eb0bfd1a808de07d0f |
| Corrected checkpoint log | 8a4e7a01c3f5026ef0c27a47b536bea8872fe1fab2d6d673da8ccd9aea407092 |
| Native debug aggregate log | e1d152de0ced1c2803d2012b2df9475c39f1122abcc1997c8ff572b87447d80b |
| Mapped native release log | 68c4c6881ce4c27d1a508e590f60bdf047fd85f8b316c64187e9ae7305d7b527 |
| Function test file | ddf1840ccfcd89545ddb6e51fcead6404999484697dbd3ad8649ae7b29b0f39a |
| Object test file | a25702df3c41f0dacd4447cd4b5c344608c24ba2938a555e8d401f80064c7b0d |
| Manual language mapping | 28941e7afcd66b605a564180e880b925e9f9506bb4b72bc5e354d106973313db |
| Matrix generator | d9315e91e295727795ea73196358168196d88bba24432ae11837c1ad9c62d9a5 |
| Machine-readable matrix | 3a52dae150826fa2f3111a96cdda748665019216c9d62a5a9971e9b137aae2d9 |
| Debug root blackbox executable | 0c6f901669b425dbd2919d2bb36368435342113d0f7776197005597ac7d89c7b |
| Release root blackbox executable | 2f9c42c753967fea15023f68c0b9d8fb9c50a2690521b615b9469693383d7d40 |

The full debug and focused release scopes overlap; their counts are not added.
No broader release or CLI/application rerun is claimed for the language stage;
the previous 444/444 release and 67/67 scenario results retain their own source
identity. The newer language source stays separate from the approved
`af188da` archive/controller: no current file is substituted into that Linux job.
The private proposal and pre-existing untracked repository proposal are
unchanged. No push, release or tag is part of this stage.
