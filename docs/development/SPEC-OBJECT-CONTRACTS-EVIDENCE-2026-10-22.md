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

## Object projection-transfer at d2874a40

The fixed [projection definitions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1573-L1580) and [mapWithKey definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L289-L295) are already source-enabled in [stdlib_layer.mbt](../../stdlib_layer.mbt). They delegate enumeration to objectFields(All), values to original obj[k], and construction to ordinary calls/comprehensions. The [independent OP1–OP9 fixture](../../spec_object_projection_contract_test.mbt) closes these finite scopes under those generic child judgments:

| Accepted constructor-transfer scope | Decisive obligations |
| --- | --- |
| objectValuesAll: all declared Value projection | All sorted names including hidden fields; required o/Object guard, lazy Array elements, needed original indexing and receiver/alias preservation. |
| objectKeysValues: visible projection in the Object-valued common domain | Exact key/value pair shape and String keys; binding/Object guard, key versus value demand, original receiver and overlays. |
| objectKeysValuesAll: all-field projection in the Object-valued common domain | Same pair obligations, including hidden fields; the shared return-type conflict below limits acceptance. |
| mapWithKey: all declared visible-field mapping transfer | Function-before-Object guards, required func/obj, regular result fields containing func(k,obj[k]), lazy shape/arity/body/value and original receivers. |

Each recorded scope is **accepted_constructor_transfer** with `remaining_in_scope=[]`. Generic enumeration/index/receiver/application judgments are premises, not new function-specific pending work. Flat assertion demand is tested directly; no new inherited assertion-super or recursive-index judgment is made. OP6's successful host-gate non-demand and Runtime/exact-marker checks are embedding evidence, not general mapper counts or independent-error priority.

### Shared pair return-type annotation conflict

The fixed [objectKeysValues prose](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#std-objectKeysValues) labels value as Object, and objectKeysValuesAll inherits that description; both source bodies instead store unrestricted o[k]. For o={a:1}, source pair.value is 1, incompatible with a literal Object-only annotation. No source precedence is established: this is a shared unresolved item in the two functions' own return contracts, not a generic-child exemption. No scalar rejection, wrapping or unconditional all-Value acceptance is inferred. All new normal pair tests use Object values; existing scalar-pair assertions remain source-defined profiles.

On unchanged production source d2874a40e2998ba4c1e1237c97e7fca84e59e88f, one native debug run passed **19/19** (9 new + 10 existing), exit 0, 9.769 seconds; warning-denying check and matching outline passed, with all 725 input hashes stable. The test total includes legacy source profiles and is not a count of cross-source normative successes. Commands:

```sh
moon check . --target native --frozen --deny-warn -j 1
moon test spec_object_projection_contract_test.mbt object_std_test.mbt spec_object_reflection_test.mbt arguments_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize
```

Fixture SHA-256: `dc409fecada3755def02eaa3e68993fe366a8f299c3ff67d74ebbc3d852cb7c7`; retained `directed/receipt.json` SHA-256: `fa7f37b727c5f360d057adabb5e69446df12389b9e2874fd7a3ce16434e0da5a`. Info/format preserved interfaces, literals and operation tokens. Four new manual records preserve all 78 prior objects. No product fix, new full-suite/release/Linux/consumer/Go/C++ run or whole-language certificate is claimed; historical inventory snapshots and source-profile fixtures remain unchanged.

## equals public call-binding at acb42b3e

The fixed [equals(a,b) declaration](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1582) has two required parameters and no defaults. [EN1–EN3/EN5](../../spec_equals_names_contract_test.mbt) accept this bounded protocol as **accepted_call_binding**: positional/named/reordered/mixed and first-class calls, ordinary invalid bindings, unknown legacy x/y, named uniqueness and unused-call laziness. `remaining_in_scope=[]`; equality outcomes are child premises, and EN4/EN6 are behavior-preservation controls rather than proof of the comparison algorithm, == or all equality domains.

On acb42b3e01f48020f2d9955b5d68b65ca1d6da27 the unchanged-product run passed **8/10**, exit 2: EN1 rejected its first a/b source call after positional direct/alias controls had passed through both entries; EN3 accepted its first x/y source call. Remaining arms after each failure were NOTRUN, and all four old groups passed. Splitting only the builtin_params entry into equals[a,b] and primitiveEquals[x,y] leaves the handler, self.equal, operators and source routing unchanged. The same frozen six new groups plus four neighbors then passed **10/10**, exit 0, 9.334 seconds, including every previously blocked arm; warning-denying checks and matching outlines passed, and each run's 726-input manifest stayed stable.

| Legacy input before | Migrated input | Unchanged expectation and basis |
| --- | --- | --- |
| std.equals(x=[1],y=[1]) | std.equals(a=[1],b=[1]) | true; fixed source1582 names are a,b. |
| std.equals(a=1,b=1) | std.equals(x=1,y=1) | error; x,y are unknown under that same declaration. |

Original inputs/logs remain preserved; these are the only two legacy literal changes. The bounded adjacent audit found objectFields(All), objectRemoveKey, member and contains labels already matched their fixed declarations. Formal objectFieldsEx/objectHasEx/primitiveEquals rules do not declare public parameter labels, so no names were inferred from metavariables or changed. The two frozen Go named-argument profiles remain unchanged and were not rerun.

```sh
moon check . --target native --frozen --deny-warn -j 1
moon test spec_equals_names_contract_test.mbt object_std_test.mbt arguments_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize
```

Frozen fixture SHA-256: `0c31a91c16d3420e2b3167a0a9fb28b886980d47a2eb7e267e054de5ef88c48f`; corrected stdlib.mbt: `078d0c869808096e54d1a1bd92196dbc34e19e9ea4fe91e51505e3ea45b96950`. Retained baseline/candidate receipt hashes: `59bbcf5716471f74c1df143857221f762309c432c3dfb423a3bd3889732e1f35` / `d4ceb091c9f4ab9f19b5c4c54e9e451493a7d630e18ab5ae594959cc6e9e6cd3`. Info/format checks changed no interface or frozen oracle. One new manual record preserves all 82 prior objects. No new full-suite/release/Linux/consumer/Go/C++ run, publication or whole-comparison acceptance is claimed.
