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

## UTF-8 valid-scalar contract frozen at 7fadc7b

Base `7fadc7b00b1212fab8fd591d2ead6c5869823b99`; no implementation defect is claimed.
The fixed [UTF-8 declarations](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#L1329-L1376)
require `encodeUTF8(str)` and `decodeUTF8(arr)`, without defaults or source bodies.
[RFC 3629 sections 3/4](https://www.rfc-editor.org/rfc/rfc3629.html#section-3) define the canonical scalar encodings;
[section 6](https://www.rfc-editor.org/rfc/rfc3629.html#section-6) treats interior FEFF as data. Leading-signature handling is not adjudicated.
`spec_utf8_contract_test.mbt` uses independent literal text/bytes through source and handmade ASTs, not round trips as oracles.

| Groups | Frozen required outcome |
| --- | --- |
| C01-C04 | Literal pairs at U+0000/007F/0080/07FF/0800/D7FF/E000/FFFF/10000/10FFFF cover all widths and scalar-gap edges. |
| C05 | Explicit mixed-width 26-byte vector converts to ten scalar characters, with independent values and lengths. |
| C06 | Documented required names str/arr work directly and through function aliases. |
| C07-C08 | A sole demanded outer or byte-expression error fails; other byte elements are ASCII, without competing-error priority. |
| C09-C10 | Unselected calls stay lazy; repeated byte Array/String aliases and an identity map retain literal values. |
| C11 | Interior `A\ufeff\u0000B` maps to `[65,239,187,191,0,66]` and back; four codepoints and six bytes. |

Required failure/laziness follows the existing language rules; `Runtime` and exact user-marker checks are additional embedding assertions, not UTF-8 byte-value requirements.
Existing `std_encoding_test.mbt` and Base64 decoder C10 retain ordinary/empty Unicode controls; malformed replacement and leading-BOM profiles remain ungraded.
Invalid scalar Strings, out-of-domain byte coercion, resource equivalence, exact diagnostic order and callback counts remain outside this subset; no whole-function acceptance follows.
The protected ten-group candidate is retained externally; its literals are preserved, with only C11 added. At fixture freeze, product, old tests and coverage map were unchanged.
Info, fmt and fmt-check pass without interface changes; formatting preserves literal/operation tokens.
At that freeze, native execution of 11 new plus 15 existing groups was pending. No full/platform run or publication is part of this batch.

The directed native run passes 26/26 (11 new, 15 existing; exit 0, 9.113 seconds) on unchanged production.
Raw `moonjsonnet-utf8-contract.2_psxce0/directed/receipt.json` binds the base above and fixture SHA-256
`b0e3f4ec366262fc49c1078ce4217a1b1679d6fb85bdc7f51ef72f6826bfffed`.
Inputs stayed stable and all three owned groups exited; no product fix or legacy expectation change was needed.
Two new manual records add encodeUTF8/decodeUTF8 only; the previous 67 objects remain byte-identical.
Full/release/Linux/CLI/C++ runs are NOTRUN for this batch; the earlier 890-test source cohort excludes these 11 new groups.

Leading-BOM and malformed recovery remain **UNRESOLVED / NOTPASS**. The fixed
UTF-8 declarations have no source/formal builtin body specifying rejection versus
replacement or its granularity. RFC 3629 sections 3/4 identify invalid bytes but
do not choose that Jsonnet API policy; section 6 permits leading signature
interpretation. No precedence or mandatory handling resolves these omissions,
and no new compatibility experiment or decoder change is used to claim acceptance.

## strReplace contract frozen at 5ecbf9f

Base `5ecbf9f391d87422eb1692ef6d361baadf9b5418`; no implementation defect is claimed.
The fixed [public declaration/example](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#L772-L794)
and [source definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L148-L178)
require String str/from/to, no defaults and nonempty from. Source matching advances
by the matched pattern length; inserted text is not recursively replaced.
`spec_str_replace_contract_test.mbt` supplies literal expectations through source
and independently handmade ASTs; it does not reproduce the replacement algorithm.

| Group | Frozen required outcome |
| --- | --- |
| SR1 | Official example; empty/no-match/identity/deletion, adjacent and nonoverlapping matches, literal punctuation and nonrecursive replacement. |
| SR2 | Exact NUL, supplementary and combining codepoints with both single- and multi-codepoint patterns; no normalization folding. |
| SR3 | Positional/reordered named/alias calls agree; three required parameters, missing/unknown/extra binding rejection with otherwise valid values. |
| SR4 | Every nonstring head kind in each argument and empty from reject, including empty input; no required error tag or diagnostic winner. |
| SR5 | Each isolated argument error propagates; to remains required on empty and unmatched input, with no competing invalid arguments. |
| SR6 | Unused whole calls, false branches and Boolean shortcuts leave errors and invalid empty patterns dormant. |
| SR7 | Input/pattern/replacement String aliases and repeated results retain independent literal values. |
| SR8 (revised) | Final compact JSON budgets of 4/5/10/6 UTF-8 bytes include both quotes; exact budgets pass and one byte less is Limit. Separate std.length values remain 1/3/2/2. |

SR4 asserts rejection only, not skipped container/function payload demand. SR5's
Runtime/marker checks and SR8's Limit/byte budgets are embedding checks alongside
language value/failure criteria; no exact diagnostic order, callback count or
general resource equivalence is asserted. SR8 intermediates are no larger than
the literal final result. Invalid host Strings, N0/R0 and UTF-8 recovery/BOM
questions remain outside this subset. Existing string/argument/JSON String groups
are reused as neighbors; native execution was pending at the initial freeze, with product and old tests unchanged.
Info, fmt and fmt-check pass without interface changes; formatting preserves
literal/operation tokens. The planned directed subset is eight new plus ten existing groups.

The original directed run passed 17/18 (exit 2, 9.528 seconds): SR1-SR7 and all
ten neighbors passed; SR8 failed at the first source-entry one-byte-short assertion.
Its handmade budget arm and remaining three vectors were NOTRUN. Frozen fixture/doc hashes were respectively
`00031792f973ca5b76486823005cb2b71a0bef7cc0b497cb7633f1371527d382` /
`7b261ce5656e34a8733c99e5f6bbf0981ecd54efff92da70839fa79718cca15e`.
Original inputs and `directed/receipt.json`/raw output remain preserved externally.
The extra inference that std.length must enforce exact UTF-8 intermediate
String bytes is withdrawn: [API Limits](../reference/API.md#limits) promises
final compact JSON accounting and only conservative internal construction guards.
SR8 now checks final JSON bytes including quotes, retaining its literal values
and separate codepoint counts. SR1-SR7 and product bytes are unchanged; this is
an embedding-test correction, not a strReplace semantic defect or product fix.
The corrected directed run passes 18/18 (eight new, ten existing; exit 0,
9.490 seconds), with check/outline also exiting 0 and all inputs stable.
`directed-final/receipt.json` binds unchanged source `5ecbf9f` and fixture SHA-256
`a9b8077a667d8233683238c20a1f1739b0607bb663476507fd69f008ea728b04`.
It runs `moon test spec_str_replace_contract_test.mbt std_string_test.mbt arguments_test.mbt spec_json_string_contract_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize`.
Original 17/18 evidence and the resource correction remain intact; no product or
legacy expectation change was made. Only strReplace gains a manual record, with
the previous 69 objects unchanged. No new full/release/Linux/CLI/C++ run or
whole-function acceptance is claimed; the earlier full cohort excludes these groups.

## ASCII case family at 59eb3e8

From base `59eb3e803e135b0d89a258c2a71dac5c60ff91a7`, the fixed
[conversion definitions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L179-L194) and
[equalsIgnoreCase definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1766)
support these independent literal source/handmade-AST subsets:

| Function | Fixed rule and bounded witnesses |
| --- | --- |
| asciiUpper(str) | Change only ASCII a-z to A-Z; AC1/AC3/AC7-AC11 cover letters, boundaries, unchanged Unicode, required names/errors, laziness and aliases. |
| asciiLower(str) | Change only ASCII A-Z to a-z; AC2/AC3/AC6-AC11 cover the corresponding literal values and demand controls. |
| equalsIgnoreCase(str1,str2) | Compare the two asciiLower results; AC4-AC11 distinguish ASCII equivalence from distinct non-ASCII variants without Unicode normalization/folding. |

The baseline passes 12/14 (new 9/11, old 3/3); AC5's first Kelvin source comparison
and AC6's source comparison fail. Their then-blocked reverse/handmade/later arms
remain recorded as NOTRUN at baseline. Selecting the existing equalsIgnoreCase
body in source_standard_function yields 14/14 (11 new, three old; 10.019 seconds),
including those later arms. Check/outline exit 0; 722 inputs remain stable.
Native fallback, Unicode table and conversion bodies stay unchanged. Fixture
`492562b599b86a3e7a08d3a8cb847d393d0d72827d4922a6cbd700c25fdc8f0e`
differs from the initial freeze only by layout/trailing commas; interfaces are unchanged.

`std_string_test.mbt` keeps its six inputs and changes `[true,true,false,false,false,true]`
to `[false,false,false,false,false,false]`. `tools/consumer.mbtx` changes only the same AC6 input
`equalsIgnoreCase('KΣẞ𐐀','kςß𐐨')` from true to false; each non-ASCII character is
unchanged by asciiLower. Original files/logs and the complete per-pair literal
derivations remain in the retained scratch evidence; no Go output supplies the oracle.
Three new manual records preserve the prior 70 objects. Container/function
stringChars admission, N0/R0, BOM/recovery and Stream-default questions remain
unresolved. No whole-function, full-suite, consumer-package, release/Linux or
fresh Go/C++ comparison pass is claimed by this directed result.
