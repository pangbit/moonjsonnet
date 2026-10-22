# Application entry-path evidence

The [pre-probe oracle](SPEC-LANGUAGE-CALL-REVIEW.md) selected remaining
application dimensions after checking the existing F1-F6, arguments, static and
AST tests. Previously reviewed ordinary source permutations/binding failures
are controls, not new rule coverage. No product defect was found; interpreter
implementation and public APIs remain unchanged.

Validation source is `9f6fce65e2a44da24900b31c10d4f70b7ecbf688`, tree
`6774398f9567b19762fdf56a0df40c2a83b8bf69`, on Darwin arm64 with the existing
moon/moonrun 0.1.20260920 (914d7da), moonc v0.10.14+7d59c7ec9. Later changes
only map evidence and add reports; the validated test/corpus/runner bytes remain
unchanged.

| New group in [spec_language_call_test.mbt](../../spec_language_call_test.mbt) | What the actual assertions establish |
| --- | --- |
| Default closure environments | Independently written source and handmade local/function/call trees give `[10,20,99]`, distinguishing definition/formal/caller scope |
| Finite recursive function defaults | Handmade and source mutually recursive f/g defaults share the call's formal x, giving `[42,7]` rather than outer x=100 |
| Handmade runtime binding rejection | Four validly constructed Programs reject missing/unknown/overlapping/extra arguments as Runtime with zero argument/default/body callbacks |
| Callee demand | Source and handmade heads distinguish numeric/object Type from an exact callee Runtime marker; native head executes once when required, argument callbacks never execute |
| Unselected invalid calls | Source/handmade unused calls return 42 with zero head/argument callbacks |
| Static invalid calls | Source and handmade unselected duplicate-name/undefined-expression calls reject Static during Program creation |
| Source syntax | Three malformed default/argument/delimiter texts reject Syntax; no malformed-text AST equivalence is claimed |

The first six groups include handmade ASTs which do not originate in a parser.
The last group is intentionally source-only. Static failures happen before a
Program exists; Runtime/Type assertions occur only after creation succeeds.
Callback counters prevent unrelated error categories from masking early demand.

| Bounded check | Observed result |
| --- | --- |
| First new-group native baseline | 7/7 |
| One affected native debug run, seven files | 29/29 including all seven new groups |
| Warning-denying native check | Passed |
| Source CLI corpus | 15/15: 3 exact JSON results and 12 exit-1/empty-stdout diagnostics |
| Existing ordinary binding controls within CLI corpus | Four; not counted as newly reviewed source behavior |
| Matrix assertion validation | 46 exact test blocks; 43 rows with partial evidence, 51 entirely unreviewed |
| Documentation | 131 files / 1005 local/current-source links passed |
| Final info then fmt, script format and whitespace | Passed; no .mbti changes |

Native commands used `--frozen --deny-warn -j 1`; there was no full aggregate,
release or remote run. The affected files were spec_language_call,
spec_language_function, spec_static, arguments, ast, syntax_diagnostic and
language. The [CLI corpus](../../tests/spec-language-call-cli.json) uses
`moon run --frozen tools/spec-language-forms.mbtx EVIDENCE_DIR calls`; the forms
corpus remains the runner's default. Its native debug build is single-worker.
The [retained CLI report](spec-language-call-cli-evidence-2026-10-22.json) includes
exact commands, outputs, source/input/binary hashes and statuses. CLI rendering
exposes source/runtime classes, not the finer library kind. The corpus's
library_kind fields are expectations verified by separate library assertions,
not actual kinds inferred from a CLI message.

| Retained artifact | SHA-256 |
| --- | --- |
| Pre-probe oracle | f31d912d2fd33739097fa91b3695d16736febf7e632d9460d7feeef9edf1696e |
| Baseline log | 29250d71d26eddc15e31c1bdd9bba84e69f30e65ab60f24e083ca22ffdaddc4a |
| Affected 29-group log | 6568c837a5b748e78707f97ae7c803b3ff0f4511e3a122395c8d0b5405600f2a |
| Test source | a9a8489f31f3fce9d3266602fbad788e3ba63a50daa1b66f99cfb9f1ea13724a |
| CLI corpus | 19308b060c80ddc3cb1def5b73f05ecbf7d57f16be32d2961301c647f87d1682 |
| Shared CLI runner | a42786f6e077c27162ba640710a391835a294d9048aaad57756e2a20a60fd56c |
| CLI report | 2b1fe2144c5e09c33a8c74c6f36d3c724ae7d929d8f6aa11d01c5d16f4ecd3fd |
| Raw CLI cases.json | 298276d8f9221cbf84f6c8a9bf91c880bd99be119fbd6af029a8da52d9ce3f70 |
| Native debug CLI | c41f07805590ddf79326634ece3030355d3776edec3fc6de28463207c14be6cc |

Raw local evidence remains under `/tmp/moonjsonnet-language-calls.TLRaLc`;
temporary files are not an archival delivery guarantee. The committed CLI report
preserves the source execution results.

Only already partial application/syntax/substitution rows gain dimensions.
The [matrix](SPEC-LANGUAGE-MATRIX.md) still has 43 partially reviewed rows and
51 entirely unreviewed rows; no rule or public stdlib function is newly accepted
as complete. Full named/positional permutations, other non-function head kinds,
tailstrict forcing/order and positional-after-named fine diagnostic classification
remain outside this batch. The standard-library 35/153 partial reviews and all
unresolved naming/cardinality/Unicode contracts are unchanged.
[Go/C++ comparison](SPEC-LANGUAGE-COMPARISON-2026-10-22.md) remains unknown for
these new paths. The older af188da Linux evidence is not reused for this source.
No push, release or tag occurred.
