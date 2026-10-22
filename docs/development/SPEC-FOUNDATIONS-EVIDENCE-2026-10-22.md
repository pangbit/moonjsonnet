# Ten independent foundation-contract reviews

This batch reviews type, isNumber, abs, sign, min, max, pow, range, map and filter.
It adds no credit for previous length/sum/avg/removal/YAML work. The
[locked expectations and explicit limits](SPEC-FOUNDATIONS-REVIEW.md) use Google
Jsonnet commit bbb38f1020be1f5aed560928fb839b2c448cefb4. New tests use assertions,
not updated Go snapshots. All inputs are synthetic and contain no business data.

## Functions and dimensions actually reviewed

All ten public signatures have required parameters and no defaults. Valid named
calls, missing/extra/unknown arguments, rejected-argument nonexecution and
unselected invalid calls are covered by
[binding/lazy controls](../../spec_foundation_calls_test.mbt). For the two type
functions, every input value kind is accepted; their error cases are demanded
expression/binding failures, not an invented invalid-value type restriction.

| Function | Normal and parameter cases | Error and boundary cases | Lazy/immutable cases |
| --- | --- | --- | --- |
| type(x) | Seven documented tags; named x | Demanded outer error; empty containers, Unicode and function values | No payload/field/assertion/default/body/native callback execution |
| isNumber(v) | Numbers true, all six other kinds false; named v | Outer error; maximum finite, subnormal and negative zero are numbers | Same outer-value boundary, including functions and asserted objects |
| abs(n) | Positive/negative fractions; named n | All six nonnumeric kinds rejected; zero, subnormal, finite extreme | Needed operand demanded, unused calls stay lazy |
| sign(n) | -1/0/1; named n | All nonnumeric kinds rejected; both zeros, subnormal and finite extremes | Needed operand demanded, unused calls stay lazy |
| min(a,b) | Reordered named call, lesser/equal finite operands | Each nonnumeric kind in either position; no integer narrowing; invalid producer propagates | First invalid type stops before second expression; unused call stays lazy |
| max(a,b) | Reordered named call, greater/equal finite operands | Same type/boundary grid as min | Same first-invalid and unused-call boundary |
| pow(x,n) | Named x/n, integer/fractional/negative/zero exponents in the tested real domain | Type errors, underflow-to-zero, finite large result; overflow/non-real result rejected before type/isNumber/min/max/abs/sign consumers | Required operands demanded; unused/short-circuited/hidden/argument overflow remains unforced |
| range(from,to) | Reordered names, inclusive steps, zero/singleton length | Invalid types/size arithmetic overflow; fractional integral-length intervals and starts beyond Int32, including +/-1e308 | Parameter callback cached once across length/elements/slice alias; unused call stays lazy |
| map(func,arr) | Reordered names; array/string input yields an array; Unicode and empty inputs; numeric/string callback values | Function/sequence and demanded callback/application errors | Input array unchanged; unused elements/body stay lazy; repeated result callback runs once |
| filter(func,arr) | Reordered names; true/false selection, empty input | Non-array/non-function and demanded predicate/application errors | Input and retained thunks preserved; unused excluded/retained payloads stay lazy; native predicate count matches elements |

Tests: [types](../../spec_foundation_types_test.mbt),
[numbers](../../spec_foundation_numbers_test.mbt),
[arrays](../../spec_foundation_arrays_test.mbt). This is finite dimension coverage,
not acceptance of all possible contracts for these functions. Signed-zero output
spelling, pow(0,0), exhaustive rounding, callback declaration/default wording,
negative/nonintegral range cardinalities and nonboolean filter results remain
explicitly unadjudicated. Runtime Type versus Runtime diagnostic subcategories
and exact human error wording are not invented as language-standard requirements.

Implementation paths were checked independently: type/abs/filter use the
[native dispatcher](../../stdlib.mbt); isNumber/sign/min/max/map use existing
[source definitions](../../stdlib_source.mbt) selected by the
[source layer](../../stdlib_layer.mbt). pow uses the
[finite-checked math producer](../../std_math.mbt). range now uses the source
definition through that layer, with native makeArray and
[deferred calls](../../sequence.mbt). This prevents a test from passing against
an unused fallback implementation.

## Actual failure, oracle correction and minimal fix

The first executable run at 8c2fcf8 plus new assertions had 26 groups: 22 passed,
four failed. Two were real range failures. Two were an incorrect test oracle:
the draft confused map with flatMap's string concatenation. Fixed source says
map always uses makeArray, including string input, and allows numeric mapped
results. No implementation was changed for those two false failures. The draft,
original log and hashes remain retained.

After correcting only that oracle, the 26-group baseline was 24/26: fractional
range and large finite endpoints still failed. The old implementation converted
both endpoints to 32-bit integers before constructing the result. The fixed
source instead computes makeArray(to-from+1,function(i)i+from), so a three-element
fractional interval or one-element range starting at 1e308 is valid.

`4a1401f` enables range in the existing source standard-function dispatch: one
line changes the public execution path to the already embedded definition.
Global integer conversion, indexing and native fallback code are unchanged.
Affected new/dependent suites passed 57/57. An added native callback/slice-alias
check passed in the array suite, 10/10. Follow-up tests for unselected bad binding
and explicit filter ambiguity passed 13/13. These totals overlap.

The nonboolean filter assertion was not kept as a new normative requirement
solely because the implementation rejected it: the terse formal rule selects
true results without an explicit nonboolean-error premise. Original inputs/logs
remain evidence. Existing Go/C++ corpus inputs and original failure reports are
unchanged; no fresh upstream corpus was executed.

## Final source and evidence

Final executable validation uses clean tracked inputs at
2e31bdfb4a4885b9a307eb69ebab50b65ae21a68, tree
9b5c634bd653e835821a2ac46de5fe6e51a869f2. Platform: Darwin arm64; unchanged Moon
0.1.20260920/914d7da, moonc v0.10.14+7d59c7ec9 and matching moonrun.

| Check | Actual result |
| --- | --- |
| Final native debug, deny-warn, frozen, two jobs | 384/384 passed |
| Final native release, deny-warn, frozen, two jobs | 384/384 passed |
| Final CLI/contracts/three application scenarios | 47/47 in one fresh run |
| Native check, info/fmt and interface review | Passed; generated interfaces unchanged |
| Mapping documentation before final report | 115 files and 842 links passed |
| Final documentation validation | 116 files and 855 links passed |

The full suites ran sequentially once for this completed batch. No nice retry
was attempted after the previous environment restriction. There is no approval
review blocker, external-source read failure or uncertain mutation. Raw logs and
source/tool/binary/input receipts are retained at
`/tmp/moonjsonnet-foundations.lBMJHE/`; temporary evidence is not durable archival
delivery. All bounded commands completed; the CLI report records full outputs,
source/toolchain identity, binary hashes and fixture/test-input hashes.

| Retained artifact | SHA-256 |
| --- | --- |
| before-initial.log (two real and two oracle failures) | ec182112ac335f550196a42b55b8a5f6dd5454ed204afe1c69b498871f2b4943 |
| before-corrected.log (two real range failures) | cf1f05ee75375e428a19c0cdd161268183f6a489a2c2e814fcebbe5bdaf5f233 |
| after.log (57/57) | 31898dec55f2a41a508f35eff4669d7cd4dbd0f1883bc9cb00fe3ea90e1d29ff |
| debug-final.log and release-final.log (same summary bytes) | 5554c190d899065fba0d02eefefe089bdd27f9ec4becbc1025fbc1062215ccc7 |
| acceptance/report.json (47/47) | f60899b4cbc080833b505f1e27b484af29aa39b77dad0516a90bbdd0b6672c7a |
| Native debug root blackbox executable | 91280e87a560f7da38c65157d819a0a73225dfb08b53e3e52e305730936051ab |
| Native release root blackbox executable | 3202c62fdb5d750af98a2ab2e3eacdceb9b9232e57bdaf690f258159d25b3a1c |
| Release CLI | c327ed73e340f55b0437652ea80b4564e94e63b5c69917e6765a7e6542ce4558 |
| Release embedded executable | 5197980316fe0aa4d8e76c4ae6cd3b4759e69c9f96ecb55d8bc64c06786dd517 |

The [public inventory](SPEC-PUBLIC-STDLIB-REVIEW.md) now maps seventeen functions
to explicitly reviewed subsets, including these ten, and preserves U dimensions
and remaining questions. The generator records every scanned root-test hash and
pending test paths as well as base Git identity; uncommitted review edits cannot
silently masquerade as the base commit's inputs. No coverage percentage or whole
function conformance is inferred from registrations or string mentions.

Linux packets for earlier commits remain local and unchanged. A final local
packet may be rebound after the batch is stable. No transfer, remote access,
database access, push, tag, publication, proposal edit or tool/dependency upgrade
occurred. removeAt naming and the other recorded public-source conflicts remain
unresolved. Complete all-public and cross-platform acceptance is still pending.
