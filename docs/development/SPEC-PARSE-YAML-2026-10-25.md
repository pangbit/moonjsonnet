# parseYaml public collection domain and bounded parser behavior

## Independent scope frozen at bbe0bc3

Base bbe0bc37864b8eee327329e2ced308f3a1f2f275 has703 clean tracked inputs.
Its product/test bytes equal the preceding0d06ded816/816 debug snapshot; that
historical count is not applied to any later product repair.

The fixed
[public paragraph and signature](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#L1296-L1320)
declares parseYaml(str), describes a best-effort mechanism, excludes full YAML
standards compliance, limits successful conversion to JSON-compatible YAML and
explicitly excludes scalar document roots. Roots must be sequences or maps.
Its literal foo: bar example yields an Object. No parseYaml source definition or
separate formal function rule supplies a contrary root contract in the pinned
material. A reference interpreter is not an alternative normative source.

The installed parser is an event-only local yaml.mbt port with a separate wrapper:
[parser provenance](../../internal/yaml/README.md),
[document/node conversion](../../parse_yaml.mbt) and
[scalar conversion](../../parse_yaml_scalar.mbt). Existing tests demonstrate
YAML1.1 scalar resolution, nested collections, anchors/merge/duplicate keys,
String key conversion, custom tags, Go-compatible chunking, diagnostics and
resource limits. These are supported project behaviors, not all public promises.
No new parser dependency, full YAML1.2 conformance or upstream edit is required.

The concrete current difference is already visible in the current-byte legacy
json_yaml_diagnostic_test: parseYaml('a') returns String a. The wrapper converts
a Scalar root without a collection guard. Freeze a new independent rejection
expectation before changing it. This is distinct from nested scalar values,
which must remain usable inside the admitted common collections.

## Finite responsibility map

The [six public groups](../../spec_parse_yaml_contract_test.mbt) use separately
handmade source/AST entries and literal outcomes, reusing neutral builders only.

| ID | Independent requirement |
| --- | --- |
| PYC1 | The documented map and bounded ordinary JSON-compatible map/sequence/empty/nested collections return literal JSON values through positional/named calls. This is not every YAML production. |
| PYC2 | One required str, no default; aliases, named binding and missing/unknown/extra/overlap errors preserve call binding before supplied expression demand. Error-kind tags are project phase controls, not mandated diagnostic prose. |
| PYC3 | String input is required; non-String heads fail without Array/Object/Function payload demand, argument errors propagate before type observation and whole unused calls remain lazy. |
| PYC4 | Plain/quoted/block Scalar document roots fail even under type(), independently of later JSON manifestation. Nested scalars are not prohibited. |
| PYC5 | Actually parsed admitted collection syntax/nonfinite failures propagate before type(), never return a successful partial value. Quoted .inf remains String data. Root .inf/.nan legacy tests alone no longer distinguish scalar admission from the finite converter; legal collection controls supply that evidence. |
| PYC6 | Bounded Unicode/escaped NUL keys/String data decode as literals; Jsonnet-looking String contents are not executed as code/import/native calls. No malformed raw-encoding or general Unicode theorem is inferred. |

The [two separate extension groups](../../spec_parse_yaml_profile_test.mbt) have
normative acceptance null: empty/no-document outcomes, multi-document packaging,
single-marker wrapper behavior and ignored trailing data after an end marker
are not fixed by the public paragraph. Preserve those current project choices.
If that extension actually decodes a later document, parser/conversion/root
failures propagate; no whole-input streaming guarantee is invented. Empty
explicit documents yielding Scalar nodes follow the same collection guard;
no-root input policy is separate. These controls must not count as two normative
public contract passes.

Reuse original parse_yaml, JSON/YAML diagnostic, native diagnostic and finite
review tests. Anchors/duplicate keys/merge precedence, dialect/directive, custom
tag and exact error-message expectations remain compatibility tests unless a
fixed public clause independently specifies them. Do not upgrade their green
results or mutate the parser to satisfy a broader YAML standard.

## Execution plan and stop boundary

First check and run only the six frozen public groups plus the two separately
classified profiles on unchanged product. Preserve actual raw errors/exits and
first-failure loop cutoffs. A compile error is not a semantic baseline failure.
If the scalar-root gap is confirmed, change only the wrapper's root admission
before conversion, preserving nested scalars, no-root policy, extension chunking,
limits and parser errors. Then run the original legacy files unchanged; record
any old scalar-success assertions before individually migrating exact inputs
with this paragraph's root restriction. No bulk snapshot update or Go fixture
change is allowed. Existing later-loop cases after a failure are NOTRUN until
the corrected regression completes.

Use native/debug/frozen/deny-warn/j1/no-parallelize with DEVNULL stdin and300-second
command limits. Final directed regression includes the eight new groups and the
four existing public parser/diagnostic/finite files. info then fmt, fixed-source
inventory/documentation consistency and a precise English local commit follow.
Only parseYaml gains a public subset record if its evidence passes; prior66
records and language evidence remain separate. No full suite, release, SSH,
standalone CLI/API, Go/C++, dependency installation, private document or push.
Stop after this responsibility; empty/stream and other unsupported clauses stay
explicit, without an unbounded YAML ecosystem review.

<!-- Criteria above precede the independent baseline; append actual results. -->


## Applicability correction before implementation

The original public baseline passed4/6, failed2/6 (exit2,7.703902458 seconds).
PYC4 first accepted scalar root a unexpectedly; later root variants were NOTRUN.
PYC5's first four malformed/actual Inf/NaN collection inputs correctly raised,
then untagged `{ok: [1],bad: [1e309]}` unexpectedly succeeded. A temporary
one-group diagnostic deliberately reported all five actual outcomes: four
errors and `{bad:["1e309"],ok:[1]}`. That diagnostic exit2 is not another
semantic baseline or regression pass/failure count; its source/raw log remain
external and its exact owned temporary file was removed.

The scalar resolver explicitly falls back to String when its numeric scan is
not admitted as a finite Number. The public best-effort paragraph defines no
scalar schema/overflow-token classification that forces this spelling to be
a Number. An unconditional Runtime oracle for this untagged spelling therefore
exceeds this bounded contract. Preserve the exact old input/expectation/failure
and move only this case to the separate, normative-null project profile, with
the current String interpretation. Do not change scalar resolution to force a
Go result or manufacture a numeric requirement. The original PYC5 finite-value
criterion remains: actual decoded nonfinite values and malformed collections
must fail; its original first four inputs stay unchanged.

The separate profile baseline passed1/2, failed1/2 (exit2,0.250525167 seconds).
Its first later scalar-document input was accepted; later profile error cases
were NOTRUN at that first failure. This reinforces where to apply the root guard
inside the retained extension, without making its packaging a public promise.
Original frozen files and criteria remain immutable in the evidence directory;
revised applicability snapshots are separately frozen before product editing.


## Root repair and exact legacy migrations

Only parse_yaml.mbt changes: after a decoded document has a root, require
Sequence or Mapping before yaml_to_json. No-root input policy stays separate.
Nested Scalars continue through the original resolver; no parser/scanner,
chunking, alias/key conversion, generic dispatch, limit or scalar implementation
is edited. The new public example/type/lazy/Scalar-root/collection finite/data
criteria pass. Required errors retain normal Jsonnet diagnostics.

The first repaired run keeps both legacy files unchanged:21 total,18 passed,
3 failed (exit2,11.863064583 seconds). All six public and two profile groups
pass. The failing declarations are the original tagged-root success group,
document-splitting success group and final scalar-a diagnostic assertion.
The first tagged root and first explicit empty Scalar document stop their
respective groups; later variants in those groups are NOTRUN there. These are
three observed declaration failures, not eleven independently observed failures.

The following exact old inputs move to Runtime rejection under the fixed
collection-root restriction. Original bytes/output remain external; no input
is deleted or changed to hide a failure. Three new bracketed tag counterparts
preserve the old nested scalar decoder compatibility checks separately.

| Exact old YAML input (JSON-escaped String) | Old success | New outcome | Observed in first legacy run |
| --- | --- | --- | --- |
| `"!<tag:example.com,%C0%80> value"` | String value | Runtime root rejection | Reached |
| `"!<tag:yaml.org,2002:int> '012'"` | Number10 | Runtime root rejection | NOTRUN after earlier failure; migrated from the same root rule |
| `"!<tag:example.com,%E4%B8%AD> value"` | String value | Runtime root rejection | NOTRUN after earlier failure; migrated from the same root rule |
| `"---"` | Array[Null] | Runtime decoded-root rejection | Reached |
| `"---\n---\n"` | Array[Null] | Runtime decoded-root rejection | NOTRUN after earlier failure; migrated from the same root rule |
| `"1\n---\nfalse\n---\n"` | Array[Number1,Boolfalse] | Runtime decoded-root rejection | NOTRUN after earlier failure; migrated from the same root rule |
| `"# comment\n---\n1"` | Array[Null,Number1] | Runtime decoded-root rejection | NOTRUN after earlier failure; migrated from the same root rule |
| `"--- # comment\n1"` | Number1 | Runtime decoded-root rejection | NOTRUN after earlier failure; migrated from the same root rule |
| `"1\n...\nignored"` | Number1 | Runtime decoded-root rejection | NOTRUN after earlier failure; migrated from the same root rule |
| `"1\n--- ignored"` | Number1 | Runtime decoded-root rejection | NOTRUN after earlier failure; migrated from the same root rule |
| `"a"` | String a | Runtime root rejection | Reached |

The two explicit empty-document cases are Scalar-null roots in the retained
project stream extension; no-root whitespace/comment results remain unchanged.
Neither profile is promoted to an independently specified stream contract.
Existing alias/merge/duplicate-key/directive/tag and exact diagnostic controls
remain project compatibility evidence; their passing values do not add official
YAML dialect promises. No frozen Go/C++ snapshot is modified.

## Final directed result and evidence binding

After only those evidenced legacy migrations, the same six-file directed run
passes21/21, failed0, exit0,9.968312583 seconds. It includes six public groups,
two normative-null extension groups and13 existing decoder/diagnostic/finite
groups. Previously unexecuted legacy loop suffixes now run. No product correction
beyond the root guard was needed; revised pre-repair public/profile criteria
retain identical bytes. info then fmt pass with no public mbti change, and all12
validated source/test SHA256 values remain identical to the tested bytes.

Evidence directory: `/tmp/moonjsonnet-parse-yaml.z56okx94`. Original frozen and
revised applicability snapshots, baseline raw outputs, the deliberate one-group
diagnostic, legacy originals/migrations, validated-inputs.json and per-command
exit/time/absent-PGID receipts remain separate. DEVNULL stdin,300-second bounds,
C locale and RUST_LOG=error apply to every native command.

| Artifact | SHA256 |
| --- | --- |
| frozen/spec_parse_yaml_contract_test.mbt | `49747d94bf26e7c2e8959533b761a0123b8676e6edbc7da7234f72f4bbdecaf8` |
| frozen/spec_parse_yaml_profile_test.mbt | `75d57c4ed747d40bbd1e6fe844e90a5f1937ed2483d5b65989efaada1aa2747c` |
| revised/spec_parse_yaml_contract_test.mbt | `ed1bfcd735a4f2599d0242af78715710bc9ece628d1e725df1896bf7d67eaeb2` |
| revised/spec_parse_yaml_profile_test.mbt | `39137883964d32308c402e2898127e8020ef3a7beb3edade0f3fdcf6f3edb3f9` |
| public-baseline/stdout | `bdfa43ec03d62f726db655b12c4520586316a975ae964beb1f43654d34c22b2e` |
| profile-baseline/stdout | `6f41512181f9bff90ae300f6a2fcfdcd15fca1bfac9a32116f4b147032dd1e5d` |
| collection-diagnostic/stdout | `660fbfa2f7becad01876c8bfb653896a8b3d8784284840426226140441343be9` |
| repaired-original-legacy/stdout | `e94867e388642fbf9bdced064f93cee99416d13622056eefa4b4e2e0bd20722e` |
| final-directed/stdout | `29736c09aabe626657aabd7c61b828f86a957e1ca35ff1974f9d07745a7b7217` |
| validated-inputs.json | `5dc0ba12b8d74cdcfbdb1c096c4265cad583de029f2f4b19f562c409c4cbb44a` |

Only one public record is added: parseYaml; the prior66 are equal and the
67-subset count grants zero whole-function acceptances. There are no old
inspection/evidence hash bindings to the three edited parser/test paths, so
all225 language evidence and completion fields stay byte-identical. This is a
closed bounded public responsibility plus explicitly separate implementation
profiles, not complete YAML compliance or proof about every unbounded parser
feature. No repeated scalar-schema experiment or parser dependency change follows.

No full suite/release/SSH/Linux/independent CLI/API or reference interpreter ran
on the new product bytes. The prior816/816 and228cb25 Linux results remain
historical; broader same-source regression/platform work requires its own
coordinator allocation. Overall specification conformance remains incomplete.
