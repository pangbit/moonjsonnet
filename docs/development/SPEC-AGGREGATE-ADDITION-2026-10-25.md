# Array aggregation: actual addition and finite results

## Frozen review boundary

Base79adcb4b933cc9f99e50eeb8b25b535f38a91111 has695 clean tracked entries.
The complete789/789 debug result at9150705 covers all unchanged numeric P0,
producer and JSON/YAML defensive tests. The existing sum/avg branch checks each
numeric addition with finite and checks the final division; empty avg rejects
before dividing. No new nonfinite leak is established by static inspection.
Do not rerun those unchanged groups as another baseline.

References stay fixed at google/jsonnet
bbb38f1020be1f5aed560928fb839b2c448cefb4. The [Number definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#L132-L136)
excludes nan/inf and makes operations producing them errors; finite subnormal
rounding to zero is not such an error. [sum/avg source](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1724-L1730)
defines sum as foldl(function(a,b)a+b,arr,0), and avg as an empty check followed
by sum(arr)/length(arr). [The public descriptions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#L2693-L2718)
do not add an every-element-Number guard. This batch uses Array inputs only:
the ordinary left-fold definition and overloaded String addition give decisive
expectations without choosing String/nonarray sequence admission or fold-child
Object/Function disputes. Those remain outside this finite responsibility.

The native per-element number conversion is narrower than actual a+b. In
particular sum([1,'2',3]) should be '123'; avg must complete the sum before its
quotient, so avg([1,'2',error 'required-after-string']) must expose that marker
rather than rejecting the String early. A String accumulator changes subsequent
operations to concatenation; it does not retroactively allow an overflowing
numeric prefix. No independent competing-error winner is invented here: the
required predecessor fold and later quotient are explicit source stages.

## Frozen independent groups

[spec_aggregate_addition_test.mbt](../../spec_aggregate_addition_test.mbt)
uses literal expected values/markers and independently handmade ASTs:

| ID | Decisive expectation |
| --- | --- |
| AGF1 | Literal mixed/String Array folds produce123,0ab,1😀2 and0truenull, with String heads. |
| AGF2 | A positive/negative numeric overflow before a String fails even through type(); a String prefix changes later large-number additions into safe concatenation, and avg then fails quotient Type. |
| AGF3 | Required elements after a String are still read before avg division; isolated supplied errors propagate through type(). A completed String sum gives avg quotient Type. |
| AGF4 | Largest finite singleton values and minimum subnormals stay finite; two minimum subnormals sum to1e-323, half one rounds to0. |
| AGF5 | Unused, hidden and explicit Boolean shortcut paths skip the whole new String reduction; demanding it exposes its supplied later marker. B0 remains untouched. |
| AGF6 | Numeric seed plus container fails Type without nested demand. After a String transition, coercion must traverse an Array/simple Object payload and expose its marker even under type(). Functions remain unmanifestable without invoking their bodies. |

No assertion-bearing objects, same-type function equality, general diagnostics,
host callback counts or Go/C++ result supplies an oracle. Existing numeric,
fold-order and JSON/YAML guard files are reused after a product change rather
than duplicated. The final directed set includes these six groups, aggregate,
spec_aggregate, spec_review, spec_array_fold, spec_manifest_wbtest and
spec_yaml_wbtest; no full suite or wider math campaign is authorized.

Preserve the original six-group run, first source/handmade cutoffs and any
postrepair old-oracle failure. Only a proven difference permits the smallest
sum/avg-case change; ordinary arithmetic finite guards and all input-domain
choices outside Array stay unchanged. Any legacy migration must keep its exact
input and supply its fixed-source reason. No snapshot or upstream fixture update.

If stdlib.mbt changes, its16 existing language inspection hashes must be rebound
only after proving all inspected anchors/control branches are outside the exact
edited aggregate span. Preserve their old records and compare every other field;
no225 evidence ID, rule completion, premise or count may be promoted by a hash
change. The two existing public subset records may add actual evidence only.

Run bounded300s native/debug/frozen/deny-warn/j1/no-parallelize commands with
closed stdin, then required info/fmt and metadata validation. No new SSH, full
suite, release, standalone CLI/API, reference interpreter, installation, proposal
import, upstream change or push. Stop after the grouped result and exact commit.

<!-- All criteria above precede execution; append actual results below. -->

## Actual result and minimal repair

The check passed without fixture or type corrections. The unmodified product
baseline then reported **6 total, 1 passed, 5 failed, exit 2, 7.214s**. AGF4's finite
extreme/underflow cases passed. AGF1/AGF2 failed with opaque JsonnetError output;
AGF3/5/6 explicitly reported actual Type versus required Runtime. Each failing
declaration stopped at its first source observation. Later source variants and
handmade entries were NOTRUN at those cutoffs, not counted as observed failures.
In AGF2, the preceding positive/negative numeric overflow controls had already
succeeded before its String-prefix result failed.

The only product edit is the sum/avg match arm in [stdlib.mbt](../../stdlib.mbt).
The accumulator is now a strict Value seeded with Number 0. Each actual step calls
the existing Vm::binary(+,acc,next), retaining finite validation for numeric +
and using existing String coercion after a String transition. Avg then calls
the existing / operator after completing the same reduction. The Array entry
guard, empty-average guard, signature, budget ticks and public routing stay
unchanged. No global arithmetic, fold, parsing, native-result or output guard
was edited. Empty sum 0 is trivially finite; for nonempty numeric reductions each
new accumulator is checked by binary+, and numeric avg is checked by binary/.
There is no path that relies solely on final output to reject a produced Infinity.

String coercion uses the unchanged core manifest/JSON rendering path and its
finite check. Existing final JSON/JSON String/YAML defensive tests were reused
in the postrepair neighbor batch, without repeating them against unchanged code
before the repair. This is not a claim about all mathematical functions or every
serialization/output/resource domain.

The first postrepair selected run was **25 total, 24 passed, 1 failed, exit 2, 11.722s**.
All six frozen groups passed; the only failure was the original legacy oracle:

| File | Exact unchanged input | Old expectation | Required replacement |
| --- | --- | --- | --- |
| aggregate_test.mbt | std.sum([1,'2']) | Error | String 12: fixed sum 1724 is (0+1)+String2. |

The old file and failure output remain preserved. Only that input moved from
the error loop to a literal successful assertion; it was not deleted. Subsequent
old error-loop entries were NOTRUN in that failed execution and were executed
after the migration. No reference fixture or snapshot changed.

The final same-scope batch passed **25/25, exit 0, 8.148s**: six independent groups
and 19 existing aggregation/fold/producer/defensive-output groups. Source and
independently handmade branches all ran after the repair. Info and fmt passed;
no interface or tested product/oracle byte changed afterward. The pre-existing
nonfinite P0 behavior remains correct through the reused actual-operation
operators; the new observable repairs are legal Array String addition and the
mandatory reduction/quotient/coercion demand boundaries, not a claimed new
nonfinite-producer leak.

## Exact metadata migration and stopping boundary

Changing the full stdlib file requires a current file-hash binding for 16 existing
inspections across length-array, length-object, length-string, object-fields-ex,
object-has-ex and type-object. The frozen original file proves the entire prefix
and suffix outside the exact sum/avg match span are byte-identical. Every bound
anchor lies outside that span and stays byte-identical; selected dispatch/forcing
conditions are unchanged. The old 16 records are preserved with old/new offsets
in inspection-rebinding.json. Only their file SHA changes. Normalizing those 16
hashes back gives exact structural equality to the old mapping: all 225 evidence
objects, completion premises/reasoning and counts remain unchanged. This is
maintenance of an existing inspection binding, not 16 new rule acceptances.

Only sum/avg public records add evidence; the other 64 remain equal, leaving 66
reviewed subsets and zero whole-function acceptances. This scoped Array review
has no remaining observed failure in the enumerated actual-operation branches.
It does **not** finish the complete sum/avg public contracts. In particular the
unchanged Array-only entry guard still rejects std.sum('123'), while the fixed
sum body delegates to foldl's String traversal and would produce String 0123.
That exact old negative assertion still runs as legacy compatibility evidence;
it is a known separate admission difference, not a normative pass or exception.
Nonarray avg source length/empty-guard order also remains outside this repair.
Public binding, other producers, assertion/cyclic children and resource limits
retain their own obligations. No B0/N0/R0/A0/PE0 branch is reopened or waived.

## Source and raw evidence

Raw closed-stdin argv/environment, first failures, unchanged frozen tests,
original/migrated legacy file, exact code-span/16-inspection proof and process
receipts are at `/tmp/moonjsonnet-aggregate-addition.flfpwbzp`. Every command uses
at most 300s, with one worker/native debug/frozen/deny-warn/no-parallelize for tests.
Temporary paths are not an archival availability promise. Key SHA-256 bindings:

| Artifact | SHA-256 |
| --- | --- |
| Frozen six-group test | `276af27941d7c9ad584ba367d6dac7ad0cfcf2e876a7c6224479a762d67a2af8` |
| Frozen criteria | `1b4140fca2b84d7be71905347a41683ec8e9c98e6e9731d011908078f99263c8` |
| Original baseline stdout | `e61630f0713158a6e0f0d38f2d3dbd0910b8382c6ab5c7d25ec039d557b266f0` |
| Original postrepair legacy failure stdout | `1a70b1cfce7bade587ef5248efbe61cb9c4cab6013afb0509455f634d1feea26` |
| Final 25 stdout | `1f90a005b7e282503a5e26d8069407a20038c45b53de5ee0d719047365a3a561` |
| Final stdlib.mbt | `49840cc3dc3ea46a55acbdf42ad55892244920d14e067166faf4b6a177f54eee` |
| Unchanged operators | `a93a2d005dd74b7a07ac9fa6d1a585a4fda46d7a8ce6c97dda8e3c83a30b3209` |
| Unchanged embedded stdlib | `39212e15a7fce36cda8c620b08116328df801d791ffff775734cd02497bf6e98` |
| Exact inspection rebinding proof | `e89656e50d1be88b25fbb0515c1df99c8cd79c6c7aa302d64fe612adcaae47bf` |

No full suite, release, standalone CLI/API, Linux/SSH, Go/C++ run, installation,
upstream/proposal modification or push occurred. The prior 789/789 debug result
binds 9150705 and is not current-source evidence for this repair. Overall
conformance remains incomplete.
