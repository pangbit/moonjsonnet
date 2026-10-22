# Object contract evidence, 2026-10-22

This stage continues the [conformance requirements](SPEC-CONFORMANCE.md) with
six public functions: objectHas, objectHasAll, objectFields, objectFieldsAll,
get and objectValues. The
[independent expectation review](SPEC-OBJECT-CONTRACTS-REVIEW.md) was recorded
before execution, using fixed Google Jsonnet commit
bbb38f1020be1f5aed560928fb839b2c448cefb4. The checked specification, public API
documentation and std.jsonnet hashes match the existing pinned inventory.
No Go/C++ execution or result matching determines these expectations.

## Findings and reviewed dimensions

The independent baseline passed 18/18 groups. No failing implementation case or
necessary product-source change was found within this finite scope. Local test
commit 62f97198233e22ba9c44d131f1c10228eff64091 adds the locked review and four
test files; subsequent coverage/CLI changes do not alter the interpreter.

| Function | Parameters/defaults and normal boundary | Error and forcing evidence |
| --- | --- | --- |
| objectHas | Required o,f; null-valued and empty-name fields present, absent/hidden names false; all nine visibility-inheritance combinations | Nonobject/nonstring kinds fail as Type; computed-name construction errors propagate; field values and assertions stay lazy |
| objectHasAll | Required o,f; hidden/visible fields present, absent fields false, inherited/overridden names | Same type/error criteria; native counters show neither assertion nor field-body execution |
| objectFields | Required o; sorted unique visible names, inherited names, prefixes and supplementary Unicode order | Nonobjects fail; construction still demanded; enumeration does not force payloads or assertions |
| objectFieldsAll | Required o; same name ordering, including hidden inherited fields and overrides | Same type/construction errors and lazy structural reflection, including hidden erroneous payloads |
| get | Required o,f; default=null and inc_hidden=true, positional/named overrides, inherited self/super and original object unchanged | Null differs from missing; defaults run exactly twice for two missing/excluded cases; invalid hidden flag fails, selected field/default errors propagate, present accesses check inherited assertions |
| objectValues | Required o; values align with sorted visible names, inherited self/super, empty/hidden-only objects | Shape/length avoids values and source assertions; selected elements check assertions; nested heads stay lazy; native field visits follow demand order b,a with cached repeated b shared through get |

The [reflection tests](../../spec_object_reflection_test.mbt) contain six groups,
[get tests](../../spec_object_get_test.mbt) six,
[values tests](../../spec_object_values_test.mbt) four, and
[binding tests](../../spec_object_calls_test.mbt) two. Binding tests reject
missing/excess/unknown arguments and leave rejected argument expressions and
unselected calls unevaluated. Native counters distinguish assertion, selected
field and fallback execution. Assertions are not triggered by structural
reflection or missing/excluded get paths; present field indexing does check
them. No blanket assertion policy or std.manifestJson behavior was changed.

All new inputs are synthetic literals and local native counters. They contain no
business data or private proposal text. Existing language/P0 tests remain
regression protection rather than new adjudicated coverage. The eleven older
cardinality/filter observations were neither rerun nor relabeled. The
[public map](SPEC-PUBLIC-STDLIB-INVENTORY.md) now records reviewed subsets for
28 of 153 candidate identifiers, with no whole-function conformance acceptance.

## Execution identity and results

Validation source: aade01ccaa57f5516bdefaec1b5924c49c7354f6, tree
a34a7580df3f0205ab18b29257f39f7bf8c5246b. Product sources are unchanged from
4b6a4a62507f4d7696969a6693ea797608e19ec2. Platform: Darwin arm64. Existing tools:
moon/moonrun 0.1.20260920 (914d7da), moonc v0.10.14+7d59c7ec9. Native suites run
serially with -j 2. No toolchain or dependency upgrade occurred.
Aggregate commands used this commit's product/test inputs; documentation drafts
were separate from executable inputs. The CLI runner verified a clean tracked
tree before and after its execution.

| Check | Outcome |
| --- | --- |
| New independent baseline | 18/18 |
| Native debug aggregate | 425/425 |
| Native release aggregate | 425/425 |
| Release CLI/P0/error/lazy and three application scenarios | 59/59; clean tracked source and retained exact statuses/outputs |
| Warning-denying native check, moon info then moon fmt | Passed; no public .mbti changes |
| Final documentation and format/whitespace checks | 120 files / 892 local links passed; format/whitespace passed |

Six added CLI cases cover inherited structural reflection with a false source
assertion, get defaults/null/hidden selection, get's inherited assertion error,
objectValues shape laziness and selected assertion error, and inherited
self/super values with unchanged original. Original P0 and three application
scenario fixtures remain included. Errors must return exit 1 with empty stdout;
normal cases must match parsed expected JSON. Exact outputs and every source,
tool and fixture hash are retained by the acceptance runner.

Raw local evidence: /tmp/moonjsonnet-object-contracts.HX1Fx3. Initial pre-format
test inputs are preserved under initial/. These are local temporary artifacts,
not an archival delivery guarantee.

| Artifact | SHA-256 |
| --- | --- |
| baseline.log | 8c71a392f6b0e5e5e495f4cb5785083e4c503ff3319676cc1f1844ba6f5a1835 |
| New CLI fixture | 136ed776079346298a693808366c5989bd9e67d21ccf3b7f6aa44ae3802c56b7 |
| Acceptance tool | 5aedbd36de89916f46ab4bb70a524b9be59aa21abfbbdccbec7e4e877ad9d240 |
| Manual coverage mapping | 610982b0467b27a91878abf90fdc65d09a83b78e0ce38cf9f691279e5f3330d3 |
| Previously prepared 4b6a4a6 packet audit | 76d6db92bf79b000ed3f971c649239fe9c80a1394f3db8e441fc28d2da466cdb |
| Native debug/release logs, identical count summaries | 7a896dee13dae8fb1c5a8f8fa41e03d621321fd1f7739dcc3f7683c06d9ec176 |
| acceptance/report.json | d670c256892020d587b2c1cb6759f21c6a3204f7a8a8a0435dc7364ff3b5bf43 |
| acceptance/cases.json | eea5f3495253d67cc8eeb61f836f925a9b6b0872c2ce14fd04178595cb420701 |
| Release CLI executable | 3ab8b5f0d896821697a4ba705b38aa903a50c519b80bc497fbe0ab92a5f391a4 |
| Release embedded executable | 06e70e7f51b7ad2f23ef9d71b516c21bccce66d1fe4b57db1cc68a7aefa36515 |

## Local packet and remaining scope

The earlier 4b6a4a6 tar/bundle are unchanged and remain bound to that commit.
The tar's 547 entries comprise 510 file/symlink entries and 37 directories:
244 .mbt, 43 .mbtx, 20 .pkg, 20 .mbti, one .mod, 32 .json, four .jsonnet,
two .libsonnet, three .c, eight .go, 119 .md, six .txt, one .tsv, two .yml,
two dotfiles and three extensionless files: LICENSE, NOTICE and the repository's
.githooks/pre-commit script. Go files are reference
adapter sources; they are not executed by the proposed native acceptance scope.
The bundle contains incremental Git commit/tree/blob objects and commit
metadata, requiring the same-project 8e661f9 baseline, rather than a checkout.

Read-only member-name and all 26 incremental-tree checks found no private
proposal/sensitive paths, private-key headers or common AWS/GitHub/Slack token
markers.
Neither package contains the private untracked proposal, build output or
executable binaries. A local packet may be rebound once this batch is stable;
any resulting identity/hashes are retained in the local completion receipt.

The requested Linux planning bounds remain 2 CPUs, 4 GiB RAM and 8 GiB disk,
with an existing matching Moon toolchain, C compiler/linker, POSIX libc, Git,
uname, shasum and frozen async fs/shell script dependencies. Run serial -j 2,
with a 10-minute cap per native suite and 30-minute cap for the entire job.
These are proposed hard limits, not remotely measured completion estimates.
Missing tools/cache or a timeout must be reported before any installation or
upgrade. No upload, remote execution, service/port, database, push, tag or
publication is authorized by this preparation.

Exact presentation and precedence among multiple failing necessary arguments
remain outside the reviewed contract. Full inheritance/assertion/resource and
every public-function combination remain pending. Earlier signature/default
conflicts and the eleven boundary observations are unchanged. No local approval
or environment blocker exists; Linux execution still awaits the parent task's
specific arrangement. Complete conformance is not established by this stage.
