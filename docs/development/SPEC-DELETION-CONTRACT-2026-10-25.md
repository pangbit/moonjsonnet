# Complete deletion responsibility review

## Frozen scope and independent expectations

Base `ccf50ef16b1c24656f05d0cce8c78acea83d8814` has 692 clean tracked entries.
References remain Google Jsonnet `bbb38f1020be1f5aed560928fb839b2c448cefb4`.
This continues the [preserved remove search repair](SPEC-REMOVE-SEARCH-2026-10-25.md),
without reopening B0, N0/R0, A0 or general comparison disputes.

The [public descriptions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#L2838-L2896)
state first-occurrence removal and removal at a position. Both functions require
two parameters, without defaults. `remove` agrees on arr/elem. `removeAt` remains
an explicit idx (documentation) / at (source) conflict; current i is compatibility
state and has no normative endorsement. No alias or spelling choice follows.

The [fixed bodies](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1773-L1785)
are operational definitions, not Go/C++ snapshots. `remove` first completes find;
[find](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1655-L1659)
explicitly rejects nonarrays before looking at its target. `removeAt` instead
comprehends arr[i] across range(0,length(arr)-1), filtering i != at. It has no
integer conversion, bounds guard, array type guard or eager index evaluation.
Its array element body remains lazy. The [desugaring definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#L1105-L1134)
binds the parsed std.jsonnet; the [array-comprehension clauses](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#L1468-L1522)
separate range/predicate demand from retained element demand.

Thus an empty range skips the index altogether; no matched numeric position,
including a negative, out-of-range, fractional or large finite index, leaves all
elements. Disjoint index kinds do not match a numeric loop index. This follows
[equals](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1586-L1621)
checking the two type names first; no same-type function equality is asserted.
The documentation adds no competing validation or declared Array-only premise.
String inputs therefore expose Unicode-indexed characters as an Array; simple
Object/Function inputs follow length but defer invalid numeric indexing until
a retained element is selected. Their bodies, defaults and field payloads are
not used for length. Null/Bool/Number fail length with Type. These are concrete
source-admission consequences, not a new generalized container API promise.

## Existing evidence reused without duplicate new declarations

- [RSD1-RSD3](../../spec_remove_search_test.mbt): empty target skipping, complete
  search including later errors, first-only deletion, no match, named arr/elem,
  nested payload laziness, required target/input errors and control-flow gates.
- [Immutable deletion](../../spec_remove_test.mbt),
  [legacy regression](../../remove_test.mbt),
  [cached/removed/retained payload controls](../../spec_review_test.mbt), and
  [sequence aliases](../../spec_sequence_structure_test.mbt): original and derived
  arrays, earlier map/slice, chained deletion, deferred or warmed values.
  The native callback count in the old review remains a host compatibility check;
  no exact callback trace or allocation identity is made normative here.
- [Argument validation](../../arguments_test.mbt) supplies generic binding controls;
  only deletion-specific missing/extra/unknown/duplicate-arr and mixed calls need
  independent new coverage. Invalid binding must fail without forcing supplied
  error markers; no exact diagnostic wording or winner between invalid bindings
  is required.

## New frozen group map

Every new case has source and independent handmade AST entry paths in
[spec_deletion_contract_test.mbt](../../spec_deletion_contract_test.mbt).

| Group | Missing obligation and independent expectation |
| --- | --- |
| DEL1 | Both function lengths are 2 and require both arguments; missing/extra/unknown/duplicate-arr binding rejects before supplied values; mixed remove(arr,elem=...) works. No removeAt index spelling is chosen. |
| DEL2 | Singleton deletion across Null/Bool/Number/String/Array/Object targets; mixed primitive targets and Unicode non-normalization. No same-type function/cyclic/assertion oracle. |
| DEL3 | remove's explicit find guard rejects each nonarray kind with its guard error before an unused target. |
| DEL4 | removeAt removes each actual numeric position including -0 and integral 1.0, rather than deleting every duplicate value. |
| DEL5 | Empty removeAt returns [] with error-valued or arbitrary-kind indices, including shape observations. |
| DEL6 | Unmatched finite positions preserve all values, including fractions, negative, end, beyond Int32 and very large finite indices; length does not inspect retained error heads. |
| DEL7 | Numeric/disjoint index comparisons skip nested Array/Object payloads and Function bodies; a required nonempty index error or overflow still fails. |
| DEL8 | Source-defined String/zero-length Object/Function admission, shape-only nonempty Object/Function retention, selected invalid indexing Type, and Null/Bool/Number length Type. |
| DEL9 | remove/removeAt/map/original alias composition, returned closures/hidden payloads, required retained payload errors. Host pointer identity is not an observable language obligation. |

Before any repair, run native check and these nine declarations, preserving raw
stdout/stderr/exit, first failures and loop cutoffs. Do not infer each later
branch ran when its declaration already failed. A confirmed repair must preserve
current unresolved index spelling and must not widen aliases; the fixed body is
the authority for positional behavior. Preserve original Go/C++ data and old
runtime-error assumptions, with an exact-input/source migration for any old test
that conflicts. No snapshot-update command is allowed.

One final directed batch will combine all nine new groups with RSD/legacy,
immutability, alias/caching and argument neighbors. Use native debug, frozen,
deny-warn, one worker/no-parallelize, DEVNULL stdin and bounded 300-second commands.
Then info, fmt and metadata checks; stop after documenting actual results and a
precise English local commit. No full suite, release, CLI/API delivery, network,
SSH/Linux, reference execution, proposal import, installation or push. Public
parameter conflict and shared child judgments remain explicit, not function passes.

<!-- All criteria above precede execution; results append below. -->

## Compatibility-only binding guard prepared after the first repair

The original native binder in the frozen base names the index i; the same file
and lint metadata remain unchanged. Before executing the preservation guard,
freeze [a separate profile](../../spec_deletion_binding_profile_test.mbt) that
accepts the original reordered arr/i call and rejects idx/at without using their
argument values. This profile protects an explicitly retained compatibility
choice; its normative acceptance is null. It is not a tenth normative group and
does not adjudicate the fixed documentation/source conflict.

## Actual baseline, repair and one final batch

The first check exited255 for five uses of the read-only Json Null constructor.
No semantic test ran then. Replacing those constructors with public Json::null()
changed no expected value; the original syntax-only file/check remain preserved.
The corrected check passed, and its executable test SHA was frozen before the
unchanged product baseline. The nine semantic criteria never changed.

Baseline: **9 total, 5 passed, 4 failed, exit2, 7.478s**. DEL1-DEL4 and DEL9
passed. The raw failures are opaque JsonnetError output, not captured exact
messages: the first source queries in DEL5/6/7/8 are respectively an empty Array
with an erroneous index, negative unmatched numeric index, Null index, and
String input. Native eager forcing, integer/bounds conversion and Array-only
admission explain these failures by static inspection. Later loop entries and
the handmade path in each failing declaration were NOTRUN in that baseline;
no count of independently observed failures is invented for them.

The sole product file changed is [stdlib_layer.mbt](../../stdlib_layer.mbt).
The primary source layer now selects removeAt. A two-required-parameter arr/i
adapter lazily forwards positionally to the **unchanged embedded fixed Func**.
The inner at binder and whole fixed body remain intact; no eager/index/bounds
logic is duplicated. This is source-body repair while explicitly preserving
unadjudicated current spelling, not a signature decision. No idx/at alias is
added. The native approximation, copy helper, global equality/index/number
operators and embedded source bytes are unchanged.

With the frozen nine groups plus all planned neighbors and original legacy file,
**27 total, 26 passed, 1 failed, exit2, 11.624s**. All nine new groups passed.
The only failing old group stopped at the first bounds-error assumption below.
The raw output and original file are preserved before these exact migrations:

| ID | Same original input | Old expectation | New expectation and fixed-source reason |
| --- | --- | --- | --- |
| DA-M1 | `std.removeAt([1],-1)` | Error | `[1]`; No loop index equals -1; retain index0. |
| DA-M2 | `std.removeAt([1],1)` | Error | `[1]`; The only loop index0 is not1; retain it. |
| DA-M3 | `std.removeAt([],0)` | Error | `[]`; Empty range makes no comparisons or index calls. |
| DA-M4 | `std.removeAt([1],0.5)` | Error | `[1]`; Numeric0 differs from0.5; no integer conversion is present. |
| DA-M5 | `std.removeAt([1],'0')` | Error | `[1]`; Number0 and String0 have different type names; equals returnsfalse before primitive comparison. |

Only DA-M1 was reached in that failing old loop. DA-M2 through DA-M5 were NOTRUN
there, then explicitly executed in the final batch. They moved to literal
successful assertions; no failed case was dropped or ignored. The remaining
remove errors and all other legacy values stay unchanged. Historical Go/C++
fixtures, including their incompatible bounds/name assumptions, remain intact.

After those migrations, **28/28 unit groups passed, exit0, 10.642s** in one
combined final batch. This comprises nine new semantic groups, eighteen existing
regression groups, and one separate compatibility-only binding profile. The
profile is a unit pass with normative acceptance null. It is not a specification
signature pass. All source and independently handmade subcases now executed.
Native info/fmt passed; no .mbti or tested product/oracle bytes changed afterward.

## Responsibility coverage and remaining boundary

| Responsibility | Current evidence / exact boundary |
| --- | --- |
| Required params and defaults | DEL1: both lengths2, no defaults, missing/extra/unknown/duplicate-arr rejection without marker demand; mixed remove call. RSD1/3 provide reordered arr/elem names. removeAt idx/at remains conflicted, current i is only a guarded compatibility profile. |
| Empty/single/duplicate/no-match and first occurrence | RSD1/3, DEL2/4/6; deletion is by first equal value versus one matching numeric position. |
| Required search and unused target | RSD1/2/3 retain the original ccf50ef red evidence; DEL3 proves the explicit find type guard. No new remove implementation change. |
| Index domain / error timing | DEL4-DEL8 follow predicate equality and source length/index children. Unmatched finite or disjoint-kind indices are successful no-ops; empty ranges skip error indices. Selected invalid indexing and required producer errors still fail. |
| Lazy payload / callable value preservation | DEL7-DEL9, existing aggregate/review: removed heads, unobserved retained heads/nested values and closures remain lazy; selecting a retained error propagates it. Hidden fields and simple objects here have no assertions. |
| Immutability / aliases / map composition | DEL9 plus immutable/sequence/review controls exercise originals and derived arrays in both demand orders. Original value/closure references are retained by arr[i]; physical Array allocation or exact native callback count is not promised. |
| Nonarray admission | DEL8 records actual fixed source consequences for String, simple Object and Function length; selected numeric Object/Function indexing fails Type. Null/Bool/Number fail the length child. No additional Array-only guard is invented from the documentation's Arrays heading. |
| Shared child obligations | B0/N0/R0/A0/general comparison and same-type Function PE0 are not adjudicated by this batch. No cyclic-input/host-resource proof, diagnostic winner, generic closure/static completion or global std receiver hook is claimed. |

The local positional/source-body responsibility now has a reviewable map across
all listed categories, with no remaining implementation defect in these scoped
cases. `removeAt` still cannot receive whole-function acceptance because its
public name is conflicted; `remove` does not acquire unconditional acceptance
from unresolved shared producers/equality/assertion children. The public inventory
remains66 reviewed subsets and zero whole-function accepts. Only these two
records change; the other64 and all225 language evidence/completion records stay
unchanged. This is a stopping boundary, not a reason to add endless small probes.

## Evidence bindings and scope

Raw commands, first failures, original/migrated files, frozen expectations,
DEVNULL stdin, RUST_LOG=error, one-worker debug/frozen/deny-warn/no-parallelize,
300-second bounds and owned-process receipts are under
`/tmp/moonjsonnet-deletion-contract.b5dnqyrr`. Temp storage is not an archival
availability promise. Key SHA-256 bindings are:

| Artifact | SHA-256 |
| --- | --- |
| Frozen executable nine-group test | `70fdcbca0382c4255941a509c0d02ee94a3e9f9329ce35c943565434aac99c6d` |
| Separate compatibility profile | `8264b6b5e796acb315618e9883e5ea8782e8011c7d56d3cd0c309027015bd4b7` |
| Frozen criteria | `56b892b0284e0d7b1d50ef108103ee64ca5a0e74ca2e284e4f76cce4b5a6adb9` |
| Original product baseline stdout | `b1266983824f9da01a0d3c65c850c2ae1eb823f957a8b24d586cd8b2f5393466` |
| Postrepair original legacy stdout | `51d81c84018dc2aa05fe14483dd57f9851d03b81c118add14c426423523eccae` |
| Final28 stdout | `7d4e84d5b03c950f02bc098a7f054e6212d3245e8c3298b9a5d60a3a0bec6058` |
| Selected source layer | `20c370370daea09d0206ca6b988e4eaeba311b03cb1e7bf008752814713a1a19` |
| Unchanged embedded stdlib | `39212e15a7fce36cda8c620b08116328df801d791ffff775734cd02497bf6e98` |

No full native suite, release, standalone CLI/API application campaign, Linux/SSH,
Go/C++, toolchain installation, upstream/proposal change or push ran. Earlier
full-package and Linux results bind their earlier commits and do not validate
this repair. Overall conformance remains incomplete.
