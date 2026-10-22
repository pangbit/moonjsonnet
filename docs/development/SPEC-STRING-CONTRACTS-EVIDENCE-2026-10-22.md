# String and Unicode contract evidence, 2026-10-22

This stage continues the [conformance requirements](SPEC-CONFORMANCE.md), using
fixed Google Jsonnet commit bbb38f1020be1f5aed560928fb839b2c448cefb4.
The [independent expectation review](SPEC-STRING-CONTRACTS-REVIEW.md) precedes
execution. Scope is char, codepoint, substr, findSubstr, stringChars,
startsWith and endsWith. All new inputs are synthetic; private application
content is neither copied nor modified.

## Actual failures and fixes

Baseline af188daba70b19b8b7b1b283fa856d372d62c132 ran 19 new groups: 14 passed,
five failed. The original release CLI hash was
3ab8b5f0d896821697a4ba705b38aa903a50c519b80bc497fbe0ab92a5f391a4.

| Established failure | Before | Fixed criterion/result |
| --- | --- | --- |
| Fractional char identifier | char(0.5) returned NUL and char(65.5) returned A, exit 0 | Runtime error at conversion, including before type/codepoint consumers |
| Large requested substring length | substr('abc',1,1e308) failed an Int32 length check | Source size calculation clips to 2; result is bc |
| Unused character index | substr('abc',0.5,0) failed an early integer check | Zero generated size performs no character lookup; result is empty |
| First substring type guard | Later native arguments executed twice after invalid str | Source assertion stops before either later argument; counter 0 |
| Second substring type guard | Native length expression executed after invalid from | Source assertion stops before length; counter 0 |

Implementation commit 57aad77ee50ff82d6d5b6dd7e6c8e9da0425cede makes two minimal
changes: [char conversion](../../stdlib.mbt) checks integrality before the rune
conversion; [source selection](../../stdlib_layer.mbt) enables the already
embedded fixed substr definition. The latter preserves its explicit guard order,
clipping formula and deferred character indexing. No global integer conversion,
array/slice rules, dependency or public Mbt interface was changed.

After the implementation change, all 19 new groups passed. Including four
legacy groups yielded 21/23: two old assertions still demanded truncating
char(65.5) and an early substring integer diagnostic. Their original sources
and complete failure log remain local. Those assertions were updated to the
fixed criterion and the resulting existing index-error wording; the original
Go JSON/tool fixtures and historical results were not rewritten or rerun.
Legacy surrogate replacement tests remain, explicitly outside this batch's
normative scalar-domain acceptance. The affected caller suite then passed 46/46.

## Per-function reviewed subset

Every signature has required arguments and no public defaults. Common
[binding/lazy tests](../../spec_string_calls_test.mbt) cover reordered names,
missing/extra/unknown parameters, rejected argument values and unused calls.

| Function | Normal/boundary | Errors/laziness |
| --- | --- | --- |
| char | Scalar IDs round-trip through codepoint: NUL, CJK, non-BMP, replacement/maximal scalar | Fractional/subnormal IDs reject at conversion; nonnumber heads do not demand payloads; invalid unused conversions stay lazy |
| codepoint | One-codepoint strings return their zero-based identifiers | Empty and multiple-codepoint graphemes/ZWJ strings fail; nonstring/container/function heads fail without executing payloads |
| substr | Unicode offsets, clipped suffixes, requested lengths 2^31/2^53/1e308, huge starts | Ordered source guards, empty generated count skips index validation, needed negative/fractional indices and negative length fail |
| findSubstr | Overlapping and supplementary offsets, empty/long pattern, composed/decomposed distinction | Both explicit string guards; invalid pattern does not execute native haystack |
| stringChars | Codepoint array includes NUL, combining mark and supplementary character; empty gives empty | Primitive length-invalid kinds fail; one native outer input shared through length/reordered/repeated selections |
| startsWith | Exact codepoint prefix, empty prefix true, longer prefix false, no case/normalization folding | Primitive length-invalid inputs and required outer errors fail; unused calls remain lazy |
| endsWith | Exact suffix, empty suffix true, supplementary and combining examples | Same bounded error/lazy scope; undocumented nonstring extensions remain unresolved |

There are four [scalar groups](../../spec_string_scalar_test.mbt), six
[substring groups](../../spec_string_substr_test.mbt), six
[sequence/search groups](../../spec_string_sequence_test.mbt) and three common
groups. This maps reviewed subsets for 35 of 153 public candidate identifiers;
neither group counts nor R/R/R/R imply complete function conformance.

## Validation identity

Validation source: 821d3d1133769a03fd2ce3c68371f75253639b34, tree
1768633f5fc810d5b5948296c3d1bcc23844c5f2. Platform: Darwin arm64. Existing tools:
moon/moonrun 0.1.20260920 (914d7da), moonc v0.10.14+7d59c7ec9.
Native commands are serial with -j 2. No toolchain/dependency upgrade occurred.

| Check | Result |
| --- | --- |
| Independent baseline | 14/19; five real failures |
| After fix, before legacy assertion updates | 21/23; only two documented old assertion conflicts |
| Affected string/format/manifest/argument callers | 46/46 |
| Native debug aggregate | 444/444 |
| Native release aggregate | 444/444 |
| Release CLI/P0/lazy and three application scenarios | 67/67; clean tracked validation source |
| Warning-denying native check, info then fmt | Passed; no .mbti changes |
| Final documentation and format/whitespace checks | 122 files / 914 links passed; format/whitespace passed |

Local raw evidence is retained at /tmp/moonjsonnet-string-contracts.PNvOUc.
Initial sources are under initial/; baseline-cli.json identifies exact original
commands, outputs/statuses and the native counter failures. No original failure
was overwritten. Temporary evidence is not an archival delivery guarantee.

| Artifact | SHA-256 |
| --- | --- |
| baseline.log | c7cbdecaa0eef1c2fa27e12b0f364e86b27dc3ae37be9a35cf4d5694e2f54d0c |
| after-before-legacy.log | 23154b63983abaaabb58e6136be6bb946c308a69311233e702dda4c022d55e7d |
| affected.log | ec5eab89b6b65dd7921561733b9a186114c44ea8e454aa4d54fc233b63e99abd |
| CLI fixture | bc8618dcdac3e2f7ef05b68addbdae2861183ff77ce4e6c7ca561a594b1d8257 |
| Acceptance tool | 6ebe381d404ef8ffb5e1065c4b3f51a16dca85bb12ebf788570f1146d4741162 |
| Manual coverage mapping | f443546c461e838441ab3b66031684edc4f0070e3d5e952a4a1204dfd18e1c56 |
| baseline-cli.json | c58ed3bfa83f20ead0b6e3d0b52f5822887e6f2f7c115bc934baae813c027b59 |
| Native debug/release logs, identical count summaries | 03ed4d4adc2e88ab108e66745d282e379df9903df5a4a9ff33644e4327161269 |
| acceptance/report.json | 8422da4a2ee6bf2ad315bd14b333015766bedfade3183f3f497313847e8c3e7b |
| acceptance/cases.json | 74862cf1ecb102b07977d468de405d7e04fd56020eb591f2ebb2257db63f3185 |
| Release CLI executable | 76c861903c9c1c70456b31b62e974d47e6e612beee50d11e9934885700eca6f1 |
| Release embedded executable | bf1896666915347f0df0663afb9e790f6ef15a0beb7545a05d2aec9e9dbb7a8f |

## Unresolved domains and frozen Linux work

Surrogate identifiers, mechanical nonstring stringChars/prefix/suffix source
extensions and nonintegral computed substring makeArray sizes are explicitly
unadjudicated. All eleven earlier cardinality/filter observations and the
removeAt/Xml/YAML-default conflicts remain unchanged. This stage does not
establish every language rule or complete public contract.

Separately approved Linux verification remains frozen at af188da: its tar is
7,290,880 bytes, SHA-256
b7c8d68558bcf3390c295729f26635b8ac8a8e5c6838da09c742d83ca2d6cc31.
The separately approved archive controller is 12,592 bytes, SHA-256
84248bf131b1afe20d8b44517a3997bd22f3574992352533d62ebe733839ba24.
Both remain unchanged; new source/tests are not substituted into them. That
snapshot has 425 native tests and 59 CLI/scenario checks, distinct from this
stage. Its archive-only controller already passed a local no-Git smoke run;
Linux execution must wait for the parent to confirm the previous remote job has
finished and cleaned up. No SSH, upload or remote execution occurred here.
The proposal is unchanged; no push, publication or tag occurred.
