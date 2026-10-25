# Array removal search demand and Boolean boundary closeout

## Frozen independent criteria

Base a03af756d74e97cbf84ca1c5dd8fbf4a2775fb68 has689 clean tracked inputs.
All public references stay at google/jsonnet
bbb38f1020be1f5aed560928fb839b2c448cefb4(v0.21.0), with their existing hashes
rechecked. No implementation result or Go/C++ run supplies a normative oracle.

## B0 closeout and pivot

The [four Boolean rules](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#L2542-L2581)
state false-and/true-or shortcuts explicitly and transfer b in the longcuts.
No explicit execution-domain declaration of b was found in the fixed fragments;
the Boolean parameters of desugaring helpers are local helper inputs, not a
binding for this rule variable. The [guide Boolean paragraph](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#L116-L118)
requires Boolean if conditions. Its [lazy Boolean example](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#L154-L159)
does not settle a demanded non-Boolean RHS. B0 remains a domain/applicability
gap, not a newly proved pair of contradictory promises. No guessed guard or
Go-compatible outcome closes it.

Reexecute the existing BS1-BS3 and IF1-IF5 source/handmade tests at this base:
all truth choices, non-Boolean left/if heads, required/skipped errors, static
dead children and branch/context transfer have independent existing criteria.
A separate [strict-extension profile](../../spec_boolean_rhs_profile_test.mbt)
freezes both longcuts with Null/Number/String/Array/Object/Function RHS heads,
observed through std.type to avoid confusing later manifestation with operator
admission. The strict profile expects Type; a Value-transfer profile instead
yields the six kind names. Nested payloads/bodies are unused in either profile.
Normative acceptance of that separate profile is null, regardless of its unit
result. Exact independent-error winner or human diagnostic text is not required.
The B0 branch stops after these observations; it does not block other domains.

## Decidable alternate: remove must use the complete find result

[Public remove](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#L2838-L2859)
removes the first occurrence; arr,elem are required with no defaults. The fixed
[remove body](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1779-L1785)
is byte-identical in the maintained embedded source:

```jsonnet
remove(arr, elem)::
  local indexes = std.find(elem, arr);
  if std.length(indexes) == 0 then arr
  else std.removeAt(arr, indexes[0]),
```

[find](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1655-L1659)
uses filter over every index. The [public find declaration](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#L2044-L2061)
also specifies all occurrences. Thus an empty index range never compares elem,
whereas observing length(indexes) for a nonempty range requires every match
predicate, even after the first match. This error occurs before removeAt or
array concatenation: neither A0 nor its named-index disagreement is used to
choose the minimal result. Required comparisons do not manifest nested payloads
when primitive/disjoint equality has already decided their heads.

The native approximation separately forces every builtin argument, then breaks
at its first equality match. This is a static risk, not a runtime result yet.
The [new independent search file](../../spec_remove_search_test.mbt) freezes
three groups with separate source and handmade ASTs:

| ID | Independent required outcome |
| --- | --- |
| RSD1 | remove([],error unused-empty-target) returns [] without using the target; result length/type are0/array and original aliases remain empty. Positional/reordered arr,elem names agree. |
| RSD2 | length or type of remove([1,error tail-required],1) must propagate tail-required, as must variants with an earlier nonmatch or duplicate match. A required pre-match head error also propagates. No result-head1/array is legal here. |
| RSD3 | Only the first occurrence is deleted; missing values and original aliases retain literal values. Retained Array/Object heads may be compared without reading their nested erroneous payloads. Needed target/input errors propagate, but unused/if/Boolean-shortcut wrappers stay lazy; a non-Boolean if condition rejects before selecting its remove branch. |

Every expected value/marker is literal. No same-type function equality, object
assertion-super, comparison-print choice or source/AST parser export supplies
the oracle. Existing deletion/aggregate files are first run unchanged as a
legacy baseline, not accepted as normative merely because they pass. Known
legacy assumptions about unused targets and skipped retained heads must be
preserved and individually migrated only after the frozen red run. RemoveAt's
separate lazy-copy behavior and original Go/C++ fixtures are not changed.

Run only native check and directed files with frozen/deny-warn/j1, closed stdin,
debug/no-parallelize for tests and300s bounds. Preserve raw first failures and
loop cutoffs. A repair must be minimal and use the fixed body or equivalent
mechanics; no broad evaluator/Boolean change. No full suite, SSH/Linux/remote,
standalone delivery campaign, tool installation, private proposal or push.

<!-- All criteria above precede execution; results append below. -->

## Current results and frozen red evidence

The first native check passed, exit 0. Existing BS1-BS3 and IF1-IF5 passed 8/8
in 9.208 seconds. They exercise both Boolean choices, skipped/required errors,
non-Boolean left/if inputs, static dead branches and context/value transfer.
The separate strict RHS profile passed 1/1 in 0.381 seconds; that unit pass has
normative acceptance null. Required if types and shortcut transfer remain
explicit; demanded non-Boolean RHS still depends on B0's missing domain choice.
This observation does not change the Boolean evaluator or count a longcut
completion. The branch is stopped rather than repeatedly probing a definition.

The unchanged implementation then reported **3 total, 1 passed, 2 failed, exit 2**
for RSD1-RSD3 in 0.261 seconds. RSD1 demanded unused-empty-target. RSD2 printed
**required search error tail-required, got 1**: the illegal result head is
retained in the raw output, not hidden by top-level manifestation also failing.
RSD3 passed the independent value/alias/nested-laziness/control-flow controls.
The first source arm stops each failing group; later named/handmade and length/
type variants were NOTRUN until repair and are not counted as separate observed
failures. Both frozen files and every literal criterion remained unchanged.

The old deletion/aggregate files first passed 6/6 unchanged. This is a legacy
unit result, not proof that their pre-existing erroneous source claims were
valid. The original files, original public remove record and raw outputs are
preserved under the evidence directory and preceding Git commit.

## Minimal source repair and exact old-input migrations

Only one product line changed in [stdlib_layer.mbt](../../stdlib_layer.mbt):
remove is enabled in source_standard_function. The public field now selects its
already embedded exact fixed definition instead of the eager, first-match
native approximation. The [embedded source](../../stdlib_source.mbt) and native
implementation file stayed unchanged. Its find dependency is already source-
defined; positional removeAt is reached only with the first valid found index.
No global comparison, integer, Boolean or deletion-copy algorithm changed.

With that repair and all old tests still unchanged, the selected search/legacy
run reported 9 total, 6 passed, 3 failed. All three independent groups passed;
the three failures are old oracle groups whose first obsolete assertion is
listed below. This first post-repair old-oracle failure remains intact.

| Migration | Exact original input and old expectation | Required new expectation and fixed basis |
| --- | --- | --- |
| RM1 remove_test | std.length(std.remove([1,error 'unused'],1)) expected 1. | Same input now explicitly asserts Runtime marker unused. remove 1779-1785 requires length(find), and find 1655-1659 compares every index before returning the index array. |
| RM2 remove_test | std.remove([],error 'forced') was in the expected-error loop. | Same input now explicitly equals []. An empty find range invokes no predicate; the no-match branch returns arr without reading elem. |
| RM3 spec_aggregate_test | std.length(std.remove([1,error 'unused'],1)) expected 1. | Same input now explicitly asserts Runtime marker unused, for the same full-search requirement as RM1. Its adjacent removeAt retained-thunk length control stays unchanged. |

Each failing old group stopped at its first obsolete oracle. Later loop entries
were not covered by that failed execution; they run after the precise migration.
The SQ0IMM immutable-array file was not edited. No Go/C++ fixture, snapshot or
removeAt named-index expectation was rewritten. The former public remove.L
claim that a retained error head stayed unforced was wrong for this source body;
it is explicitly superseded, not retroactively called passing normative evidence.
A retained nested payload can still stay lazy when its outer type settles
comparison; the new RSD3 covers that distinct contract.

## Final directed scope and stopping decision

After the three exact migrations, **17 selected groups passed, exit 0, 8.949s**:
three independent search groups, six legacy regression groups and eight existing
Boolean/if groups. These are unit-regression counts, not 17 newly proved language
rules; the legacy internal helper/function-equality controls keep their own
scopes. The strict RHS profile separately passed 1/1, exit 0, 0.384s, with normative
acceptance null. No B0 test becomes a passing language-matrix assertion.

The result now skips an empty-search target and requires later comparisons even
after the first match. Original arrays and unused nested payloads remain intact;
false-and/true-or, unselected if branches and unused calls still skip the now
strict search. A non-Boolean if condition still rejects without selecting it.
No additional implementation failure remains in these scoped cases. No further
control-flow ambiguity experiment or unrelated library function is opened.

Native info then fmt passed, exit 0 in 0.199s and 0.043s; no .mbti or validated
product/oracle byte changed. The language map updates only the two partial B0
remaining texts; all 225 prior evidence objects and all completed review records
remain unchanged. The public map changes only remove: all 65 other records stay
equal, leaving 66 reviewed subsets and zero whole-function acceptances. Full
parameter/producer/equality-child obligations and the separate removeAt name
conflict are not claimed complete. Independent diagnostic winner, exact native
trace and resource complexity are not invented acceptance requirements.

Raw argv/environment, closed stdin, frozen/deny-warn/j1/no-parallelize settings,
300-second command bounds, first failures, original/migrated files and owned
process-group receipts are at
`/tmp/moonjsonnet-control-remove-search.mi_bmkub`. Temp paths are not archival
availability guarantees. Important source/test/output bindings are:

| Artifact | SHA-256 |
| --- | --- |
| Frozen search test | `117993dc2907e848f233510aec0c70f8a38d9953b751ace40f4278543b9f7ae8` |
| Frozen B0 profile | `c499566dac0ba4a7dd9ee6c5623b572022aabf180c20cf92c26b9904effa6378` |
| Frozen criteria | `693c1b476bec739c60fffd79dc3421de369877235c9e8dabe2240156b1960f05` |
| Original search failure stdout | `2cb0b8461a381811b9aebfdbbad0857686e90eeb0820ccd949a817905561cab1` |
| Original legacy baseline stdout | `98566e3b0f8ddd392230312d4a93343c59922153eac8fd89fe88ef3a5e9815cd` |
| Post-repair original-legacy failure stdout | `fcb69c3c43bf26d2571772bef765b229b33af0c5776a984e9b99722a85d34daf` |
| Final 17 regression stdout | `b28f3b8e4d471a65d42128a3bc856cea2eb1a5f113adb1c3f790d6750a89ba8d` |
| Separate final B0 profile stdout | `b136ac6dbfa8a737c1c47b4ab55287d32add1374feaea7f839a55b45a9685782` |
| stdlib_layer.mbt | `3ae99faee7a9d851e7fb3f3af1c7f0e6800398e7138cd183453d90c4bfccc515` |
| stdlib.mbt | `31d25cd1347257609205d66e1de21a15dd208388b761dfcc5114b79c1239d487` |
| stdlib_source.mbt | `39212e15a7fce36cda8c620b08116328df801d791ffff775734cd02497bf6e98` |
| eval.mbt | `f75c9e3fd45506a140711eaf21c09625dfa9879798ccc1ac40adc1f2983f55c3` |
| runtime_types.mbt | `eb8a948f5aa45e57ba9417753d9d97e80e55ab4a35cd8524dc51a6a950f3e8e9` |
| remove_test.mbt | `1a9f970ccda698c569594f5611d62a2076f5fdac1795323f7c2ac20ec8fe7b31` |
| spec_aggregate_test.mbt | `088cf53438c579b18f06469afce3bf3bd52f9fc7da19c3239bba61e60f792adc` |
| spec_remove_test.mbt | `94b514e9ba69c2b5ad55f8c8e020ec7ab44ceac495150b9cd7020cbdea37c75c` |
| spec_remove_search_test.mbt | `117993dc2907e848f233510aec0c70f8a38d9953b751ace40f4278543b9f7ae8` |
| spec_boolean_rhs_profile_test.mbt | `c499566dac0ba4a7dd9ee6c5623b572022aabf180c20cf92c26b9904effa6378` |

Full native suite, release, standalone API/CLI delivery, Linux/SSH/remote and
Go/C++ were NOTRUN on this repair. The 758 full-suite result belongs to 4b1be8a,
and older Linux results to 228cb25; neither validates these new product bytes.
No private proposal import, upstream modification, toolchain installation,
push or release occurred. Overall conformance remains incomplete.
