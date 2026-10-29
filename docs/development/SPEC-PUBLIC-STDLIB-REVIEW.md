# Official public standard-library contract review

The [complete candidate-name inventory](SPEC-PUBLIC-STDLIB-INVENTORY.md) is
derived from fixed Google Jsonnet commit
`bbb38f1020be1f5aed560928fb839b2c448cefb4`, not from Go's registration list:

- [Official public documentation](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html): individual headings and the inline type/math declarations.
- [Official source definitions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet): top-level function exports, excluding the six __ helpers.
- [Fixed specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html): native, modulo, primitiveEquals, objectHasEx and objectFieldsEx also have explicit rules/descriptions. Formal metavariables do not define public parameter names.

The union has **153 candidate identifiers**, including the unresolved
escapeStringXml/escapeStringXML spelling pair. This is not a count of accepted
functions or resolved independent contracts. The properties pi and thisFile are
listed separately. The specification's cmp comparison relation is retained in
the JSON appendix; its explicit TODO to introduce it does not establish an
ordinary public callable. Its classification must not become a passing claim.

The six source helpers are __compare, __compare_array, __array_less,
__array_greater, __array_less_or_equal and __array_greater_or_equal. Go reflection
also includes $flatMapArray and $objectFlatMerge. These eight internal helpers
are separate from public contracts. The additional Go id member is not declared
as a public export in these fixed sources; it remains a reference-only extension
entry. Its presence does not establish a normative requirement or exemption.
The original 163-member Go reflection fixture is unchanged and was not rerun.

## Coverage meaning and reproduction

The [JSON inventory](spec-public-inventory.json) preserves each source's spelling,
signature and location independently. It also maps existing test-reference
candidates. A reference can merely reflect a function, be an unused value, or
assert a Go-specific result. It therefore never earns coverage by itself.
Literal scanning excludes the frozen comparison JSON and can miss dynamic
calls; manually inspected digest_test references are included separately.
No direct reference found means exactly that limited search result, not proof
that no test exists anywhere.

N/E/L/B in the table are normal/error/lazy/boundary dimensions. R means only the
specific assertions reviewed against the fixed contract in
[manual case mappings](../../tests/spec-public-coverage.json). U means that
dimension remains unreviewed/unmapped. One hundred thirty-eight identifiers currently have manual
records, leaving 15 candidates without current mappings; this does not mean they
are untested. Records include reviewed subsets and the accepted constructor-transfer
and call-binding scopes below, including the ten independent [foundation reviews](SPEC-FOUNDATIONS-REVIEW.md)
and five [array combinators](SPEC-ARRAY-COMBINATORS-REVIEW.md), plus six
[object visibility/lookup functions](SPEC-OBJECT-CONTRACTS-REVIEW.md) and seven
[string/Unicode functions](SPEC-STRING-CONTRACTS-REVIEW.md), plus
[two finite rounding subsets](SPEC-MATH-ROUNDING-2026-10-23.md) and
[four JSON input/output subsets](SPEC-JSON-CONTRACTS-2026-10-23.md) and
[a mergePatch data/demand subset](SPEC-MERGE-PATCH-2026-10-23.md) and
[three integer String parser subsets](SPEC-INTEGER-PARSERS-2026-10-23.md) and
[a prune removal/demand subset](SPEC-PRUNE-2026-10-23.md) and
[a join concatenation/demand subset](SPEC-JOIN-2026-10-23.md) and
[two shallow/deep flattening subsets](SPEC-FLATTEN-2026-10-23.md) and
[deepJoin/lines String composition subsets](SPEC-COMPOSED-STRINGS-2026-10-23.md) and
[three character stripping subsets](SPEC-STRIP-CHARS-2026-10-23.md) and
[three split-family subsets](SPEC-SPLIT-LIMITS-2026-10-23.md) and
[two membership subsets](SPEC-MEMBERSHIP-2026-10-23.md) and
[two Array extrema demand subsets](SPEC-EXTREMA-DEMAND-2026-10-23.md) and
[a sort Array cardinality/demand subset](SPEC-SORT-DEMAND-2026-10-25.md);
the earlier subset records retain their stated limits. The explicitly delimited
constructor-transfer and call-binding scopes below are accepted under generic child premises;
source-text conflicts retain their stated domain limits. This
inventory does not certify whole-language conformance. Earlier executed
test counts remain tied to their respective stage sources, not to a new claim
about every signature, type, default or forcing order.

The [character stripping review](SPEC-STRIP-CHARS-2026-10-23.md) preserves the
first unchanged-product result of five passed and seven failed groups. The
scoped argument/Array-member demand correction then passed all twelve frozen
groups and three neighboring checks. Only those independently reviewed subsets
advance the dimension map; no whole-function acceptance is inferred.

The [split-family review](SPEC-SPLIT-LIMITS-2026-10-23.md) preserves the first
five-pass/six-failure baseline. The scoped wide-limit and guard-demand correction
passed all eleven frozen groups plus three neighboring checks. Only the
independent fixture's bounded obligations advance the public map; the
unlimited-right/overlap documentation/source conflict remains unresolved.

The [membership review](SPEC-MEMBERSHIP-2026-10-23.md) preserves its first
five-pass/nine-failure baseline. The corrected member/contains demand and
traversal passed all fourteen frozen groups, with separate neighboring checks.
The old extrema assertions were run unchanged, retained as a raw failure, then
migrated individually against the fixed definitions and passed separately.
The earlier prose count of 57 was stale: the committed split-stage map already
contained 60 distinct records. This batch adds only member and contains, giving
62 reviewed subsets; correcting that count does not grant any other coverage.

The [Array extrema demand review](SPEC-EXTREMA-DEMAND-2026-10-23.md) retains
its three-pass/eleven-failure baseline. The scoped optional-argument and
unselected-payload correction passed all fourteen unchanged groups, sort's four
groups and arguments' one group. Two conflicting legacy extrema assertions
were migrated individually after preserving the raw failure, and the two
legacy groups then passed. This adds only minArray and maxArray: all 62 prior
manual records are unchanged, yielding 64 reviewed subsets and zero whole
function acceptances. Non-Array scope and singleton/comparator disputes remain
unresolved.

The [extrema comparison continuation](SPEC-EXTREMA-COMPARISON-2026-10-23.md)
retains its one-pass/twelve-failure baseline. It resolves bounded singleton-key
rejection, initial self-comparison demand and condition-before-selection cases
from the earlier open comparator area. The corrected helper passed all thirteen
new groups and the fourteen previous demand groups; one legacy singleton Object
success assertion was migrated after preserving the old group's raw failure,
and both legacy groups then passed. Only the two existing extrema map records
are extended. The total remains 64 reviewed subsets and zero whole-function
acceptances; non-Array admission, exact callback counts, independent error order
and the greater-than formal-rule conflict remain unresolved.

The [sort cardinality/demand review](SPEC-SORT-DEMAND-2026-10-25.md) retains
its two-pass/six-failure baseline. Passing the key thunk through the dispatcher
and returning zero/singleton Arrays before key/element demand passed all eight
unchanged groups and eight neighboring checks. The old sort tests were run
unchanged first; their raw failure is retained, and four conflicting inputs
were individually moved to required two-element contexts. The 64 prior manual
records remain unchanged, yielding 65 reviewed subsets and zero whole-function
acceptances. Non-Array scope, arbitrary key/comparison domains and independent
error priority remain outside this review.

The [sort contract continuation](SPEC-SORT-DEMAND-2026-10-25.md#frozen-continuation-sort-public-contract-review)
maps all thirty legacy assertions individually, retaining the non-Array String
error and unused incompatible-key admission as unresolved. Six independent
groups passed on unchanged dbf322d product, with a preserved initial pass before
key-call class enrichment. Only the existing sort record advances; the count
remains 65 reviewed subsets and zero whole-function acceptances.

The [sort admission adjudication](SPEC-SORT-DEMAND-2026-10-25.md#sort-admission-and-non-promises-frozen-adjudication)
uses the explicit e_std/source implementation contract to resolve the earlier
non-Array/unused-invalid-key scope question. Its preserved2-pass/4-failure
baseline led to a minimal length/deferred-index correction, then20 unchanged
sort groups and8 neighbors passed. The old String-Type assertion was measured
as a failure, retained as a correct positive input, and its Type negative moved
to a Boolean length failure. General native key counts/order and an independent
diagnostic winner are non-promises, not indefinitely pending requirements.
Other receiver/comparison gaps remain; still65 subsets and zero whole functions.

The [receiver/comparison boundary](SPEC-SORT-DEMAND-2026-10-25.md#standard-receiver-composition-and-comparison-boundary)
links four existing-object-file cases to partial language rules. A preserved
2-pass/2-failure baseline exposed lost final self in an inherited optimized
field; the source-context repair passed4/4 plus44 neighbors while canonical
std stays native. Saved/forwarded functions remain lexical, not receiver hooks.
The malformed comparison conclusions remain a stopped global document conflict,
with a proposed erratum only. No sort-specific framework or function completion
was added;65 reviewed subsets and zero whole functions remain.

The [objectRemoveKey projection review](SPEC-OBJECT-REMOVE-KEY-2026-10-25.md)
adds one distinct public subset. The fixed comprehension retains original obj[k]
values, projects visible keys and defers an unused filter key. Its unchanged
product baseline passed2/8; routing to the exact embedded source passed8/8,
plus three precisely migrated legacy groups and29 neighboring groups. All65
prior manual records remain unchanged, making66 reviewed subsets and zero
whole-function acceptances. This does not alter the general assertion/equality
text disputes or reuse older whole-suite/Linux evidence for new product bytes.

The same function's [explicit boundary matrix](SPEC-OBJECT-REMOVE-KEY-2026-10-25.md#public-contract-boundary-matrix-at4488a71)
now closes the direct gaps with10/10 directed cases and no product change.
Required names/no defaults, complete valid call forms, absent keys, inherited
visibility, ordinary output flags, NUL identity, cold/warm aliases and flat
assertion forwarding have scoped evidence. Only common N0/R0 input-index child
questions remain conditional; unspecified traces/storage/diagnostic winners are
not pending requirements. The count stays66 subsets and zero unconditional
whole-function acceptances; no new public function or general rule is added.

The [remove search-demand correction](SPEC-REMOVE-SEARCH-2026-10-25.md)
changes one existing reviewed subset. The frozen baseline passed1/3 and exposed
both an eagerly forced empty-search target and illegal length1 after a required
tail error. Routing to the exact embedded definition restores full find demand;
17 selected regression groups pass after three individually justified old-input
migrations. The old L inference about an erroneous retained head is superseded,
while removeAt's distinct lazy-copy controls remain. All65 other public records
stay unchanged:66 reviewed subsets and zero whole-function acceptances remain.
B0's strict RHS sample is compatibility-only, not a normative pass or a reason
to change the Boolean evaluator.

[tools/spec-public-inventory.mbtx](../../tools/spec-public-inventory.mbtx) checks
the three reference hashes before extracting the fixed headers/exports. Its
source-header assumptions were reviewed against those exact bytes. It records
the generator/manual-map hashes, hashes of every scanned root test, the Git base
identity and any uncommitted test paths. Candidate references can therefore be
checked against their actual bytes even during a review with pending test edits.
The generator and manual case map are independently identified by their hashes.
This generated document is an audit snapshot, not a clean-source
execution report. Regenerate with the same public reference files:

```sh
env RUST_LOG=error moon run --frozen tools/spec-public-inventory.mbtx REFERENCE_DIR OUTPUT_DIR
```

Reference files stay outside the repository; no private application is read by
this generator. The generated inventory contains interface facts and test
references, not copied reference implementations. The focused
[contract matrix](SPEC-CONTRACT-REVIEW.md) retains detailed language/P0 evidence.

<a id="removeat-named-parameter-candidates"></a>

## removeAt named-parameter reconciliation

The fixed documentation declares removeAt(arr, idx). The same version's source
declares removeAt(arr, at). MoonJsonnet 0.2.1 declares i from Go. The fixed
specification's apply rule matches a named argument to a declared parameter;
named spelling is observable. The
[language parameter guidance](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#function-parameters)
recommends positional arguments when every parameter is required because authors
may not regard those names as stable. That guidance neither selects idx/at/i nor
disables ordinary named-call matching.

| Candidate | Supporting basis | Unresolved consequence |
| --- | --- | --- |
| idx | Explicit public documentation signature and description | Conflicts with the executable source definition's at |
| at | Exact source definition specifies the function and its bound parameter | Conflicts with the documentation signature; no explicit precedence rule resolves it |

The post-0.2.1 compatibility choice retains existing positional and `i` calls
and accepts `at` and `idx` as names for that same index slot. This is an explicit
compatibility extension, not a claim that the conflicting sources uniquely
specify three aliases. Supplying the slot more than once is a duplicate-binding
error, including mixed aliases and positional-plus-alias calls, before any
argument/default is demanded. There is no precedence rule that silently chooses
one supplied value. The function still has two parameters; extracted/inherited
original functions retain the aliases, while replacement/user functions follow
their own declarations. Ordinary index/payload laziness and `tailstrict` head
forcing are preserved.

The earlier rejection-only profile deliberately accepted neither disputed name.
That project-policy test is migrated to the explicit alias contract, keeping the
original `i` success and required-error inputs as demand controls. Frozen Go/C++
oracles and the fixed source definition are unchanged. This resolves the naming
compatibility obligation without renaming an established parameter or declaring
the rest of `removeAt` universally conformant.

## Other source conflicts and useful gaps

- XML retains the existing fixed-source export `escapeStringXML(str_)`. The documentation spells `escapeStringXml(str)` instead. Source authority and compatibility select the former; no second export or parameter alias is invented. Existing XML contract evidence verifies the selected implementation. This does not claim agreement with both signatures.
- YAML stream retains `c_document_end=true`, as in the fixed source and existing API. The documentation's prose also describes a stream ending with `...`, although its printed signature says `false`. Explicit `false` remains supported. Existing empty-stream/default and explicit-option tests cover this choice; it is an explained conflict resolution, not a missing renderer or a promise of both defaults.
- Parity follows the public integral-part description, retaining truncation instead of the source's conflicting `round` formula. The [profile decision](SPEC-CONFORMANCE.md#profile-decisions-and-wrapper-repair) supersedes the earlier unresolved label; it does not claim both formulas agree.
- SHA-1/SHA-256/SHA-512/SHA3 documentation marks them Go-only, while fixed C++ source exports error stubs. Successful local digest vectors remain finite native-profile evidence, not agreement with every conditional implementation profile.

These are explicit implementation choices and bounded evidence, not newly
discovered missing functions. Historical review rows retain their original
scope. Further work should address a concrete unfulfilled contract or missing
distinguishing evidence; repeating probes of these same conflicts or increasing
registration counts cannot establish complete conformance.


## Complete deletion responsibility continuation at ccf50ef

The [combined deletion review](SPEC-DELETION-CONTRACT-2026-10-25.md) maps the
existing search/immutability evidence with nine new independent groups across
binding, target/value types, full-search demand, numeric/disjoint/empty index
behavior, source length admission, retained values and alias/map composition.
The actual baseline passed5/9; source-body removeAt selection with a lazy current-i
adapter repairs four observed groups without choosing between idx/at or adding
aliases. Five exact old error assumptions have preserved source/input migrations.
The final directed unit batch passes28/28, including one compatibility-only name
profile with normative acceptance null. The remove source body from ccf50ef stays
unchanged. Only remove/removeAt public records change: other64 records and all225
language evidence remain equal,66 reviewed subsets and zero whole-function accepts.
Shared producer/equality/assertion children and the name conflict remain scoped;
no fresh full-suite, platform or reference-execution acceptance follows.


## Array sum/avg actual-operation continuation at 79adcb4

The [finite aggregation review](SPEC-AGGREGATE-ADDITION-2026-10-25.md) confirms
existing per-operation finite guards were already correct; it does not invent a
new nonfinite leak. Six independent groups expose a different actual reduction
error: mandatory Number conversion rejects legal String + and can hide required
later errors before avg division or String coercion. Baseline 1/6 and the original
postrepair legacy failure are preserved. Only the sum/avg case now reuses existing
+ and / operations; final 25/25 groups include old finite/empty/lazy/fold and
JSON/YAML defensive controls. One exact old input moved from error to String 12.
Only these two public records change; other 64 are equal, 66 subsets/zero whole
functions remain. The known nonarray sum String rejection and other admission/
public-child obligations stay open. Sixteen disjoint old language inspections
only rebind their full-file hash with a preserved span/anchor proof; all 225
evidence/completion fields otherwise stay equal. No old full-suite or Linux
count is applied to the changed product.


## Sum/avg admission closeout at bf1609a

The [full admission/source review](SPEC-AGGREGATE-ADMISSION-2026-10-25.md)
closes the earlier String rejection and avg guard-order gap. Public descriptions
add no contrary type guard; exact source sum/avg/foldl are selected with three
routing lines and no helper/operator body changes. The actual seven-group
baseline passed 3/7, and the final grouped regression passes 52/52 including prior
finite arithmetic and audited parser/flatten/uniq/set consumers. Two exact old
inputs and failures remain preserved; no reference snapshots changed.

Function-specific signature, all input-head kinds, initial/length/Unicode,
reduction/quotient, finite/error/coercion and lazy boundaries now have one closed
source-body map relative to their ordinary language children. Shared assertion/
cycle/producer disputes remain at global rows; this is not a normative exemption
or a reason to keep reopening arbitrary details. Foldr remains native/separate.
Only sum/avg/foldl behavior records and foldr's scope note change: other 62 records
are equal, 66 reviewed subsets and zero unqualified whole-function accepts.
All 225 language evidence objects and completion conditions stay equal; only the
unchanged SQ0UNI declaration's full-file hash rebinds after its unrelated YAML
fixture migration, with exact-prefix proof. Prior 25/789 are not inherited.


## YAML error and option-demand responsibility at 3da8ab8

The [bounded YAML review](SPEC-YAML-DEMAND-2026-10-25.md) confirms that the old
nested-error P0 was already fixed: raised failures cannot return a successful
partial String. The new gap was eager forcing/type checking of unused Doc
formatting options. Their thunks now follow actual visible Object/nonempty
Array-field demand while explicit tailstrict still forces bound heads. The
unchanged Stream definition inherits that correction. Seven frozen groups first
passed3/7, and a separately frozen strict control failed; the final related
regression passes29/29 after one exact old scalar-option error oracle migration.

Only the two existing YAML public records extend: the other64 remain equal,
66 reviewed subsets and zero whole-function acceptances. Thirty-five disjoint
stdlib/eval inspections rebind current full-file hashes, with unchanged anchors
and all225 language evidence/completion fields otherwise equal. Full YAML
quoting/layout certification is not inferred; explicit stream ends avoid the
unresolved documentation false/source true default. Flat field-demand controls
do not decide inherited/cyclic N0/R0. Prior802/802 and older Linux evidence do
not apply to the new source bytes; no full/release/remote/CLI run was done here.


## parseYaml best-effort collection-root review at bbe0bc3

The [bounded public review](SPEC-PARSE-YAML-2026-10-25.md) separates the fixed
JSON-compatible collection-root requirement from existing YAML1.1/empty/stream/
duplicate/alias project profiles. It repairs scalar document admission with one
wrapper guard, preserving nested scalars and the scalar/parser implementations.
The original public4-pass/2-failure and separate profile1-pass/1-failure outputs
remain preserved. One untagged-overflow numeric assertion exceeded the specified
scalar schema and moves, on the same input, to a normative-null profile; it is
not a second implementation defect. Eleven exact old scalar-success expectations
are individually migrated after retaining the original three legacy failures.
Final related regression passes21/21, including six public and two separate
profile groups. Only parseYaml is newly mapped; all66 previous public records
and225 language evidence fields remain byte-identical, giving67 public subsets
and zero whole-function acceptances. The new source does not inherit816/816,
release or Linux results. Best-effort is not a full YAML standards promise.


## parseJson complete-input and finite-data continuation at 727a59d

The [input-domain continuation](SPEC-JSON-CONTRACTS-2026-10-23.md#parsejson-input-domain-continuation-frozen-at-727a59d)
reuses existing JC1/JC2/JC4 evidence and adds five scoped EOF/escape/finite/key/
resource groups. The baseline passed4/5: an Object's nonfinite Number was deferred
past type(). The final parseJson-only read-only tree validation fixes that gap
while retaining the original data construction, scalar roots and generic field
laziness. A rejected constructor-reuse candidate's25/26 failure remains recorded;
its arbitrary-key collision is not hidden by changing a test. Final26/26 passes
without legacy/oracle migrations. Only this existing public record extends:
other66 stay equal,67 subsets and zero whole-function accepts. Sixteen disjoint
stdlib inspection hashes are maintained, with all225 language evidence/decisions
otherwise equal. BOM/lone-surrogate/duplicate-key and broader resource/numeric
questions remain separate; prior full/Linux counts are not inherited.


## Returned-data String-key isolation at8aba1ec

The [shared converter follow-up](SPEC-JSON-CONTRACTS-2026-10-23.md#shared-returned-data-string-keys-frozen-at8aba1ec)
independently reproduces self/super data capture through native callbacks and
parseYaml. Six frozen source/handmade groups initially pass2/fail4, then pass
with the scoped private-binding repair and required neighbors37/37. parseJson
uses its original constructor and is an unaffected control; $ ordinary data
bindings already worked. String keys resembling internal names, nested data,
captured closures, simple overlays and eager invalid-number versus unused-call
checks stay distinct from general language scope/receiver rules. No old oracle
or reference snapshot changes. Only parseYaml's existing subset and parseJson's
control map extend; other65 public records and all225 language evidence fields
remain equal.67 subsets and zero whole-function acceptances remain. Host native
callback Json-return observations do not create std.native formal acceptance.
YAML schema/stream profiles and existing unresolved language contracts retain
their status. No current full-suite/release/Linux/CLI evidence is claimed.

## Canonical UTF-8 conversion subset at 7fadc7b

The [valid-scalar contract](SPEC-STRING-CONTRACTS-EVIDENCE-2026-10-22.md#utf-8-valid-scalar-contract-frozen-at-7fadc7b)
adds encodeUTF8/decodeUTF8 literal width boundaries, named aliases, sole required
errors, unused calls, alias preservation and interior FEFF/NUL through source
and handmade ASTs. All 11 new groups and 15 existing controls pass on unchanged
implementation (26/26); no product fix or old expectation migration was needed.
Exactly two manual records are added, preserving all 67 prior objects and giving
69 distinct reviewed subsets, with no whole-function acceptance. Generated
inventory files remain historical snapshots, separate from the current manual map.
Malformed recovery, leading-BOM signatures, invalid scalars, out-of-domain byte
coercion and wider resource/diagnostic obligations remain unadjudicated; old
compatibility observations earn no new normative passes. These 11 groups were
not part of the earlier 890-test full native cohort; no new full/platform run occurred.

## strReplace subset at 5ecbf9f

The [replacement contract](SPEC-STRING-CONTRACTS-EVIDENCE-2026-10-22.md#strreplace-contract-frozen-at-5ecbf9f)
adds eight source/handmade-AST groups on unchanged production. The original 17/18
result retains SR8's overstrong internal-byte inference; correcting that embedding
check to the documented final compact JSON budget yields 18/18 (eight new, ten
neighbors), without changing SR1-SR7, product code or old expectations.
One new manual record preserves all 69 prior objects, giving 70 reviewed subsets;
historical inventories remain unchanged. Language value/demand checks and SR8's
embedding checks stay separate. No whole-function/full/platform acceptance is
claimed; UTF-8 leading-BOM and malformed-recovery policy remains UNRESOLVED/NOTPASS.

## ASCII case family at 59eb3e8

The [combined ASCII case review](SPEC-STRING-CONTRACTS-EVIDENCE-2026-10-22.md#ascii-case-family-at-59eb3e8) adds asciiUpper, asciiLower and equalsIgnoreCase; the fixed-source correction passes 14/14 while preserving the 12/14 baseline and exact legacy migrations.
Three new records preserve all 70 prior objects, giving 73 reviewed subsets and 80 candidate identifiers without current manual mappings; those mapping gaps do not mean untested functions, and unconditional whole-function acceptance remains zero.

## Mapping constructor-transfer at e42ef923

The [combined mapWithIndex/filterMap review](SPEC-ARRAY-COMBINATORS-EVIDENCE-2026-10-22.md#mapping-constructor-transfer-at-e42ef923) passes 21/21 on unchanged production and accepts mapWithIndex's public constructor-transfer scope plus filterMap's Boolean-predicate composition scope under explicit generic child judgments. Only filterMap's existing nonboolean predicate child policy remains unresolved outside that accepted scope.
Two new records preserve all 73 prior objects, giving 75 current mappings and 78 unmapped candidates; historical generated inventory counts remain snapshots, and mapping gaps do not imply absent tests.

## Repeat and search-transfer at 2e288eef

The [repeat/count/find review](SPEC-ARRAY-COMBINATORS-EVIDENCE-2026-10-22.md#repeat-and-search-transfer-at-2e288eef) accepts all three finite constructor/search-transfer scopes under explicit generic child judgments, with 16/16 directed groups passing on unchanged production. Three new records preserve all 75 prior objects, giving 78 current mappings and 75 unmapped candidates; this count concerns mappings, not absent tests or whole-language acceptance.

## Object projection-transfer at d2874a40

The [four-function object projection review](SPEC-OBJECT-CONTRACTS-EVIDENCE-2026-10-22.md#object-projection-transfer-at-d2874a40) accepts objectValuesAll/mapWithKey transfer and the Object-valued common-domain scopes of objectKeysValues/objectKeysValuesAll. The pair functions retain their shared return-type annotation conflict; 19/19 directed tests include unchanged legacy source profiles, not unconditional all-Value pair acceptance. Four new records preserve all 78 prior objects, giving 82 current mappings and 71 unmapped candidates.

## equals public call-binding at acb42b3e

The [equals binding review](SPEC-OBJECT-CONTRACTS-EVIDENCE-2026-10-22.md#equals-public-call-binding-at-acb42b3e) preserves the 8/10 baseline and passes 10/10 after correcting only its required a/b parameter names and two legacy call inputs. The new record accepts the call-binding protocol, not the complete equality comparator; all 82 prior objects remain unchanged, giving 83 current mappings and 70 unmapped candidates.

## Six set transfers at 6346da6e

The [uniq/set/union/intersection/difference/membership review](SPEC-ARRAY-COMBINATORS-EVIDENCE-2026-10-22.md#six-set-transfers-at-6346da6e) accepts six finite constructor-transfer scopes with 17/17 directed groups on unchanged production. uniq/set include established source admission; binary/member scopes retain their sorted-unique Array precondition and all six use explicit generic child premises. Six new records preserve all 83 prior objects, giving 89 current mappings and 64 unmapped candidates, not 89 complete-function or overall conformance certificates.

## native host-contract subset at 3d253179

The [fixed specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#execution) requires String lookup of a configured function and explicitly leaves its semantics to the custom execution environment. The repository's [host contract](../reference/API.md#L96) additionally defines absent-name `null`, parameter-order JSON manifestation, shared lazy calls, copied finite returns and callback diagnostics. The four existing [native test groups](../../native_test.mbt#L40) at lines 40, 77, 134 and 181 assert that finite profile; none is a new whole-function or universal host-semantics claim. Both pinned [Go](https://github.com/google/go-jsonnet/blob/67968688d9952f50662e979fab1bef889d0d3e57/builtins.go#L2261) and [C++](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/core/vm.cpp#L1277) return `null` for an absent registration, an implementation convention consistent with the published host policy, not a version discrepancy or a required new error. At source `3d25317903f1d42799c3d05a1e3c07bdf3a75ffc`, the test SHA-256 `abc42f546f6334e3176c150b1384b0b8e45d50bbd0ce729bffb34e2b9b677221` matches the macOS before/after and Linux packet/before/after manifests; all four modes' hash-verified test metadata identify these groups at indices 1-4. Their existing complete native debug/release campaigns each passed 1087/1087; no standalone four-test run occurred. One finite native mapping is added, preserving all 137 prior records. No product/test/oracle changes or new execution are needed; exact arbitrary host semantics and error presentation are not manufactured blockers, and direct lookup-binding combinations and shared language children retain their separate scopes.
