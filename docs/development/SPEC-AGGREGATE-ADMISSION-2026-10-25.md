# Sum/avg source admission and necessary foldl behavior

## Frozen independent boundary

Basebf1609a3537687ed4c98e96e613770be0de0719d has697 clean tracked entries.
Keep its original1/6 baseline,25/25 Array regression, exact legacy migration and
16-inspection proof intact. This continuation closes its named nonarray gap.
References stay at google/jsonnet bbb38f1020be1f5aed560928fb839b2c448cefb4.

[Public sum](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#L2693-L2718)
and [avg](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#L2809-L2836)
state sum/average of arr without an explicit Array-only/Number-only type premise.
The Arrays section title is not an executable type guard. The fixed
[sum/avg definitions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1724-L1730)
are unambiguous about a fold seeded with0 and the empty-length avg guard before
sum/division. There is no affirmative conflicting type requirement to preserve.
Names agree on one required arr and no defaults.

The [foldl definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L823-L830)
uses length and lazy indexed arguments, not a sequence-kind guard. Its public
description explains array traversal without adding a must-be-Array rejection.
Empty Strings, zero-visible-field Objects and zero-parameter Functions therefore
return the original initial value without using the callback or indexing.
Nonempty Object/Function inputs can be traversed when a callback ignores indexed
elements; sum's a+b requires those numeric indices and fails Type. Avg with
zero-length inputs raises its own supplied error first; nonempty String sum is
String and the final quotient fails Type. These are source consequences, not
reference-interpreter answers or diagnostic priority invented for unrelated errors.

Strings use Unicode codepoints for index/length. Thus sum('123') is String0123,
sum('') is Number0, and digit-looking/astral/combining/NUL contents are not parsed
as numeric producers. Numeric Array additions and avg division still use the
unchanged finite-checked operators; String concatenation is not falsely treated
as an overflowing numerical addition. Reuse the prior frozen six-group arithmetic
file and P0/JSON/YAML guards in the final regression after any routing change.

## Frozen executable groups

[spec_aggregate_admission_test.mbt](../../spec_aggregate_admission_test.mbt)
provides source and independently handmade AST entries with literal expectations.

| ID | Decisive expectation |
| --- | --- |
| ASA1 | One required arr, no defaults; positional/named/aliased calls; missing/extra/unknown/duplicate binding rejects without supplied marker demand. |
| ASA2 | Literal empty/digit-looking/Unicode/NUL String sums retain numeric0 or concatenate from0; a foldl codepoint sum is129382. |
| ASA3 | Empty String avg raises its fixed empty error; nonempty Strings finish summation then fail quotient Type, including before type() can observe a result. |
| ASA4 | Empty/hidden-only Object and zero-parameter Function sums return0; avg raises its empty error without hidden fields/body evaluation. |
| ASA5 | Nonempty Object/Function shape is counted; demanded numeric indexing fails Type rather than reading fields/defaults/bodies. |
| ASA6 | Null/Bool/Number length admission fails Type; isolated required input errors propagate; unused/hidden/explicit Boolean shortcuts skip the entire call. |
| ASA7 | Necessary foldl: empty-length Objects/Functions skip the callback but demand the returned init; callbacks ignoring indexed payloads count nonempty Object/Function length without using their erroneous fields/default/body. |

No assertions/cyclic values, function equality, ordering erratum, independent
error winner, native callback count, allocation identity or exact resource cost
is added as a requirement. Keep B0/N0/R0/A0/PE0 outside this batch.

## Minimal implementation and shared-consumer plan

First run check and only these seven groups on the unmodified product; preserve
stdout/stderr/exit and first-failure loop cutoffs. Prefer selecting the exact
already embedded source functions sum, avg and necessary foldl. Pure sum/avg
routing alone cannot fix empty Object/Function sums because the old native foldl
rejects them. No native helper body or global finite/index/arithmetic operator
needs an edit if source routing meets the frozen criteria. Foldr is not a sum
prerequisite and remains a separate unchanged function.

All six fixed direct foldl calls are audited: parse_nat (used by source parseHex/
parseOctal), flattenArrays, uniq (and dependent set), sum, minArray, maxArray.
The latter two remain native, so their source fold calls are not selected.
Existing integer-parser, flatten, set and fold tests provide the real selected
consumer regressions; do not invent a new general math suite. Final directed
files combine the seven groups with aggregate_addition, aggregate, spec_aggregate,
spec_review, spec_array_fold, JSON/YAML defensive whitebox, spec_integer_parsers,
spec_flatten, sets and standard native diagnostics. Preserve any original legacy
failure; exact-input migrations need source evidence, never a bulk snapshot update.

Commands are bounded300s, native debug/frozen/deny-warn/j1/no-parallelize, closed
stdin and RUST_LOG=error. Then info/fmt and exact metadata checks, an English
local commit and owned-process exit receipt. No full suite, release, SSH/Linux,
standalone CLI/API, Go/C++ run, installation, proposal import, upstream change
or push. No old25 or789 count validates newly routed product bytes.

<!-- All criteria above precede execution; append actual results below. -->

## Observed baseline, exact source routing and migrations

The first deny-warn check exited 255 for the local identifier alias being reserved;
no semantic tests ran. Only that local binding/reference was renamed aliased_call.
The original file/check are preserved; all independent semantic criteria stayed
unchanged, and the corrected executable was frozen before its baseline check.

The unmodified product baseline was **7 total, 3 passed, 4 failed, exit 2, 7.853s**.
ASA1/5/6 passed. ASA2/4/7 have opaque raw JsonnetError output; ASA3 explicitly
reports Type versus required Runtime. Their first source observations are an
empty String sum, empty String avg, empty Object sum and empty Object foldl.
Later variants and handmade branches in each failing declaration were NOTRUN at
those first failures; they are not claimed as separately observed baseline errors.

Product change is exactly **three added names** in
[stdlib_layer.mbt](../../stdlib_layer.mbt): foldl, sum and avg now select the
already embedded fixed definitions. Neither the source bodies, native fallbacks,
sequence helpers, generic arithmetic/indexing, finite checks nor output helpers
changed. The earlier bf1609a Array fallback improvement remains intact; it is
not substituted for the new actual source path. Standard numerical + and /
continue rejecting a nonfinite result at each actual operation. Codepoint String
concatenation is a separate operation and does not parse 1e309 as a Number.

With the seven new groups and planned consumer/finite/diagnostic neighbors but
all legacy assertions still unchanged, the first postrepair batch reported
**52 total, 50 passed, 2 failed, exit 2, 16.083s**. Every new group and the earlier six
arithmetic groups passed. The only failing old groups are preserved below:

| ID | Exact original input | Old expectation | Required new expectation and fixed basis |
| --- | --- | --- | --- |
| ASA-M1 | std.sum('123') | Error | String 0123: fixed sum/foldl traverses the three String codepoints and concatenates each to the numeric 0 seed. |
| ASA-M2 | std.manifestYamlDoc({a:[std.sum('not-array')],z:error 'later'}) | Type, message not later | Runtime marker later on this same input. The a value now completes as legal String 0not-array; z is its only remaining error. |

The raw old YAML failure observes only Runtime versus Type because its old kind
assertion stops before inspecting a message. The final explicit same-input
assertion independently verifies marker later; it is not retroactively attributed
to that stopped run. Subsequent old loop cases likewise execute only after the
precise migrations. The original YAML input remains in an explicit failure and
evaluator-recovery assertion. An isolated sum(null),z:0 fixture retains Type
propagation coverage without introducing a competing error. Existing Runtime,
Assertion and hidden-function controls are unchanged. No Go/C++ fixture or
snapshot changed, and no case was dropped.

After those migrations, the final batch passed **52/52, exit 0, 14.432s**. It includes
all seven admission groups, the prior six actual-operation groups and 39 existing
finite/fold/output/parser/flatten/set/diagnostic groups. All source/handmade
branches of the frozen new cases now ran. Native info/fmt passed; no interface
or tested product/oracle byte changed afterward. No additional product repair
was necessary.

## Complete responsibility map and shared consumers

| Responsibility | Current reviewed outcome |
| --- | --- |
| Binding/defaults | ASA1: exact arr name, one required parameter, no defaults, positional/named/local-alias use and invalid binding before values. |
| Array reduction and finite arithmetic | Previous AGF1-6 plus P0 controls: actual left-associated +, numeric 0 seed, safe/overflowing prefixes, finite subnormal underflow, strict required elements, avg quotient after completed sum and String-coercion errors. |
| String admission / Unicode | ASA2/3: empty sum 0, literal digit/overflow-looking/astral/combining/NUL content, exact codepoint count/traversal; nonempty avg has a String sum and Type quotient. |
| Object/Function admission | ASA4/5: zero visible-field/parameter length returns sum 0 and avg empty error without payload/body use; nonempty shapes require invalid numeric indexing and fail Type. Optional defaults/body remain unused for counting. |
| Primitive / required error input | ASA6: Null/Bool/Number fail length; supplied input error propagates. Whole-call unused, hidden and explicit Boolean shortcut paths remain lazy. |
| Initial value / helper strictness | ASA7 and existing fold groups: empty length skips func but returns/demands init; a callback can ignore indexed Object/Function data. Existing per-step result-head and nested-payload laziness, left order and cached host profiles survive source selection. |
| Immutable values and aliases | ASA1 local function aliases and existing fold/AGF original-Array/map controls retain their inputs; no callback-count or allocation identity is made a new normative obligation. |
| Output | Required String coercion still uses existing core JSON guards; numeric errors are not delayed until final manifestation. Existing JSON/YAML defensive tests remain intact. |

The six fixed direct foldl calls were all inspected. Selected source parse_nat
(via parseHex/parseOctal), flattenArrays, uniq (including set consumers) and sum
have current integer-parser, flatten, set and aggregate regressions. The minArray/
maxArray source definitions are not selected: their existing native paths remain
unchanged, including the standard diagnostic control. Foldr remains native and
its separate admission gap is not silently resolved by selecting foldl.

No listed sum/avg-specific signature, admission, initial/reduction/quotient or
finite-error boundary remains open after this source-body review. The earlier
sum('123') and avg guard-order differences are now **closed**, not compatibility
exclusions. This conclusion is relative to the ordinary length/index/apply/+/
manifest children. Shared assertion/cyclic/producer judgments and existing global
text conflicts retain their own rows; these finite probes do not waive them or
claim a whole-language judgment. There is no demand for unobservable callback
traces, independent-error winners or implementation-specific resource costs.
Unqualified whole-function acceptance stays 0; this scoped responsibility stops
here rather than reopening arbitrary new function details.

## Evidence and metadata binding

Raw bounded argv/environment/closed-stdin logs, unchanged frozen expectations,
original/migrated files, current input hashes and owned-process receipts are at
`/tmp/moonjsonnet-aggregate-admission.77_ru__f`. Temp paths are not archival
availability promises. One unrelated full-file evidence binding changes because
the old YAML fixture shared spec_review_test.mbt with SQ0UNI. The entire prefix
through that unchanged Unicode test is byte-identical; evidence-rebinding.json
preserves its exact prefix hash and old/new file SHA. Only length-string's
spec_review_test file hash changes. Normalizing it yields exact equality to the
old language mapping, with all 225 evidence objects and completion conditions
unchanged. The prior sixteen stdlib inspection bindings do not change again.

Only sum/avg/foldl public behavioral records update; foldr's remaining text is
clarified as unchanged/separate. The other 62 public records stay equal, 66 reviewed
subsets and zero unqualified whole-function accepts. Relevant SHA-256 bindings:

| Artifact | SHA-256 |
| --- | --- |
| Frozen seven-group executable | `b412a349acf33ea69164cc1c03d3d77badfa28980d5ec906172d9ab93e3a02e5` |
| Frozen criteria | `af0c358b9385cdc6f6f3e4255353bfef030fb82e3f59476ed2b9ac2033084cfe` |
| Original semantic baseline stdout | `67db2200270972aed99ab0613b72e7a00842255408c0f92dcf91f8067b76558b` |
| Original postrepair legacy failures stdout | `b443e01a962c44964d9ffedb2349323d03c8f9a2ce3843f316d8946f71c17406` |
| Final 52 stdout | `32ab04c43f211252e4e0dfa6e3b4d9754c77403f7b4de2db0081c07e20f82201` |
| Three-line source route | `da18a50484b6996df7db1d59a22ef0b3ef780e78c8ae3aee56bb0191b11da2bb` |
| Unchanged embedded standard library | `39212e15a7fce36cda8c620b08116328df801d791ffff775734cd02497bf6e98` |
| Unchanged native aggregation/operator dispatch | `49840cc3dc3ea46a55acbdf42ad55892244920d14e067166faf4b6a177f54eee` |
| Unchanged sequence helpers | `f8178d5eb75f6dc5bdbe155a76a76aa95f0e1b3dae2f2c227ef649088d47fb20` |
| Unicode full-file rebinding proof | `dd6e3ef25d70e21f1dc7becf8c95c606b6ece4a4aae31412abc7951decdd9d24` |

No full suite, release, standalone CLI/API, SSH/Linux, reference interpreter,
installation, upstream/proposal change or push ran. Prior 25/25 and 789/789 results
retain their original commits; neither is substituted for this 52-group result.
Overall conformance remains incomplete.
