# Foundation contracts: expectations locked before execution

This batch selects ten previously unreviewed public functions from the
[official inventory](SPEC-PUBLIC-STDLIB-INVENTORY.md). It does not count previous
length/sum/avg/removal/YAML reviews as new progress. Expectations below were
written before the first execution of the independent regressions.
Subsequent oracle clarifications are recorded explicitly below; retained drafts
and logs identify those changes instead of relabeling original failures.

Normative inputs are Google Jsonnet commit
`bbb38f1020be1f5aed560928fb839b2c448cefb4`:
[specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html),
[public documentation](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html),
and [source definitions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet).
Go/C++ outputs are not used to choose expectations. All inputs are synthetic.

All ten signatures below have required parameters and no public defaults. Named
calls must use the declared names, supplied arguments must bind before their
values are demanded, and missing/extra/unknown arguments fail. Duplicate named
arguments remain a language static error. Predicate inputs are any Jsonnet value;
inventing a type error for a non-number predicate input would violate its contract.

| Function | Fixed basis and normal expectation | Error and boundary expectation | Lazy/immutability expectation |
| --- | --- | --- | --- |
| type(x) | Formal type rules return the seven tags | All value types accepted; arity/name errors and demanded expression errors fail | Inspect outer type only; no array payload, object assertion/field or function body/default execution |
| isNumber(v) | Source is type(v) == number | All other types return false, including functions; finite extremes and negative zero are numbers | Same outer-value forcing boundary as type |
| abs(n) | Source checks numeric type, then n > 0 ? n : -n | Non-numbers fail; finite extremes/subnormal/zero values remain finite | Demand n; unused call/branch stays lazy; no signed-zero string-format assumption |
| sign(n) | Source checks numeric type and returns 1/-1/0 | Non-numbers fail; large/subnormal/negative-zero values have their numerical sign | Demand n; unused call stays lazy |
| min(a,b) | Source validates a then b and chooses a < b ? a : b | Non-numbers fail; equal/extreme finite operands succeed; no integer conversion | Both numeric values needed; invalid a stops before unused b; unused call stays lazy |
| max(a,b) | Source validates a then b and chooses a > b ? a : b | Same numeric boundaries and validation ordering as min | Same forcing boundary as min |
| pow(x,n) | Public mathematical function on binary64 values | Finite real-domain examples succeed, underflow may be zero; overflow/non-real result fails at the producing operation, including under type inspection | Needed numeric operands demanded; unused branch/field/argument must not evaluate invalid pow |
| range(from,to) | Source is makeArray(to-from+1, function(i) i+from) | Inclusive unit steps; zero length at to=from-1; integral-sized fractional intervals and large finite starts are valid; invalid operand types/overflow fail | Results are separate arrays; from expression cached; elements follow lazy source expression |
| map(func,arr) | Source validates function and array/string, then makeArray returns an array of callback results for either input kind | Unicode codepoints, empty inputs, callback/application errors; any callback result value is permitted | Length/selecting another element does not force unused payload/callback, including string input; original input unchanged; each result thunk cached |
| filter(func,arr) | Formal rule requires function and array; retain original elements with true predicate | String/non-array and non-function inputs fail, even empty; demanded callback/application errors propagate | Evaluate true/false predicates, not unused element payloads; preserve retained thunks, original input and memoization |

Review limits are explicit rather than guessed: negative makeArray cardinality
and range intervals yielding negative/nonintegral cardinality are not settled by
the terse formal rule in this batch. Callback declaration-count wording versus
ordinary optional-parameter application, signed-zero output formatting, pow(0,0)
and exhaustive transcendental rounding also remain outside these expectations.
These gaps cannot be counted as complete function acceptance. A bounded host
allocation error does not justify imposing a 32-bit integer range on small-result
range endpoints. removeAt naming remains unchanged.
Nonboolean filter callback results are also left unresolved: the formal set
selects true results but supplies no explicit nonboolean rejection premise.
The initial native-error assertion for that case was not retained as a newly
adjudicated expectation merely because it passed. Original inputs/logs remain.

The initial draft incorrectly used flatMap's string-concatenation behavior for
map. Source reconciliation after the first run corrected those two expectations:
map always returns an array and may map string characters to numbers. The initial
draft and all four first-run failures remain retained locally; the two map
failures were test-oracle errors, not implementation failures. No map change is
proposed to satisfy the incorrect draft.

## Five type-predicate classification transfers at b9f0e3d

The scratch candidate adds isArray, isBoolean, isFunction, isObject and isString
from fixed std.jsonnet 30,32-35 and stdlib.html 143-145: each requires v, has no
default, and returns std.type(v) == its declared tag. Their embedded bodies match
the fixed definitions; stdlib_layer.mbt enables them and imports.mbt skips native
overrides. [TP1-TP6](../../spec_type_predicates_contract_test.mbt) use independent
literal source/handmade-AST oracles for all seven heads, deferred payloads,
required/named/alias calls, invalid binding, outer errors/unused calls and unchanged
aliases including inherited Object heads. Runtime/Static diagnostic tags and exact
error markers are extra embedding checks, not language error-priority requirements.
The accepted classification-transfer scopes assume the established type,
String-tag equality, ordinary-call and child-Value judgments; they introduce no
Object-assertion or host-callback rule and do not resolve shared open judgments.
All six groups passed once in native debug (14.527 s), with no implementation gap
found or product change. The command was `moon test spec_type_predicates_contract_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize`.
The preserved first check failed on five uses of a reserved MoonBit local name;
renaming that binder and its four references changed no Jsonnet/AST/oracle value,
and the corrected format/check/outline all passed before the sole test run.
Five records preserve all 89 prior objects: the unapplied patch would give 94
mappings/59 unmapped candidates; the main tree still has 89/64. No full-suite,
release, Linux or whole-language acceptance is inferred. The verified fixture SHA-256 is
`ca8521d43a02221597aea472466e7412c8ec430003c5f545d5400f26cf3dbb5b`.

## Four math expression transfers at b9f0e3d

A second scratch batch adds deg2rad, rad2deg, log2 and log10 from fixed
std.jsonnet 267-271 and stdlib.html 237-238,251-252, each with required x/no default.
The embedded bodies match the fixed multiply/divide or log-ratio expressions,
are source-enabled and have no native override. [MX1-MX6](../../spec_math_transforms_contract_test.mbt)
freeze literal unit/base identities, binding/aliases, all nonnumber heads,
nonpositive-log domains, intermediate multiplication overflow, finite underflow
and required versus unused demand. Type/Static/Runtime diagnostics are extra
embedding checks, not mandated diagnostic kinds or error priority. The accepted
expression-transfer scopes assume IEEE basic arithmetic, fixed pi, native std.log
and ordinary-call/child-Value judgments; wrapper validation does not certify general
logarithm accuracy or all mathematics. All six groups passed once in native debug
(10.586 s); info, format-check, check and the six-test outline also passed. Production
and all 94 prior mapping objects remain unchanged. Applying both unapplied batches
would yield 98 mappings/55 unmapped candidates; the main tree stays 89/64. No new
full-suite, release or Linux run is claimed. The verified fixture SHA-256 is
`49f4f52c841bf6e1c04fb0bec0aa6e6029ae72169561d6248f46d01de3238946`.

## Native math profile and amd64 log baseline at b9f0e3d

A third scratch batch freezes sqrt/exp/log/sin/cos against fixed spec.html
2820-2836 and the required-x public signatures in stdlib.html 235-246.
[NM1-NM6](../../spec_native_math_contract_test.mbt) cover exact elementary/binary
values, rational log and Taylor trigonometric intervals, finite/range behavior,
producer errors, binding, payload demand and lazy contexts. General rounding and
large-angle phase accuracy remain unaccepted; these are native profiles, not
source-constructor certificates. Diagnostic kinds and markers remain embedding
assertions. [NL1](../../spec_native_log_kernel_wbtest.mbt) directly exercises the
real amd64 log body, initially moved byte-for-byte into a private helper with
unchanged dispatch. The preserved baseline passed six public groups and failed
NL1: 2^-1074 returned -709.0895657128241 outside (-745,-744), and 2^-1023 returned
-708.6841006047159 outside (-710,-709); the 2^-1022 normal control passed. All three
observations executed. The bounds follow 0.6931 < ln(2) < 0.6932 and
ln(2^-n) = -n ln(2), not ULP tolerances or Go outputs. Normalizing positive
subnormals by exact 2^54 and compensating the exponent fixed that kernel path;
the same frozen six public groups plus NL1 then passed 7/7 (13.733 s), with
info/format/check/outline also passing. General rounding and large-angle phase
accuracy remain unaccepted, and Linux/x86 public std.log end-to-end is NOTRUN;
host kernel coverage is not platform execution. The prior 98 mapping objects
remain unchanged; the unapplied candidate has 103 mappings/50 unmapped versus
main 89/64. No full-suite, release or Linux rerun is claimed.

The three scratch-stage accounts above preserve their historical, then-unapplied
status. The cumulative 732-input candidate subsequently passed the full macOS
ARM64 native package suite with one worker and frozen dependencies: debug
990/990 in 180.041 s and release 990/990 in 201.889 s (384.349 s total execution).
The integrated production and test bytes match that verified candidate; current
manual coverage is 103 mappings/50 unmapped candidates. Linux/x86 end-to-end
validation remains NOTRUN, and the older b9f0e3d Linux packets do not represent
the new subnormal-log correction. This paragraph records integration status,
not another full-suite run or broader numerical-accuracy acceptance.
## Inverse trigonometric profiles at da5b4c14

Fixed spec.html 2820-2832 supplies standard IEEE mathematical behavior and
stdlib.html 247-250 supplies asin/acos/atan(x) and atan2(y,x), without defaults.
[IT1-IT7](../../spec_inverse_trig_contract_test.mbt) freeze independent elementary
values and rational-pi intervals, endpoints/quadrants/extremes, binding/aliases,
nonnumber admission, producer errors and required versus unused demand. The
original semantic baseline passed 6/7: IT3 executed all eight cases through both
source and handmade AST, with four negative-y/negative-x observations returning
+3.141592653589793 instead of (-3.142,-3.141); the other twelve passed. The two
coordinate families have exact positive ratios below half the minimum subnormal.
Selecting the negative-x adjustment from original y, instead of the underflowed
quotient, fixed the quadrant while preserving early exits and other algorithms.
The same seven frozen groups then passed within 18/18 directed tests (19.877 s),
including eleven neighbors; the earlier compiler-only pattern correction is
retained separately and changed no oracle. Type/Static/Runtime kinds and markers
are additional embedding checks, not mandated diagnostics or error priority.
Four native numerical/domain/demand profiles preserve all 103 prior mapping
objects, giving current counts of 107/46. No arbitrary ULP or exact-call-count
requirement is introduced; general numerical accuracy remains unproven, not
exempted. atan2(0,0) and signed-zero strings receive no new decision. The earlier
990/990 debug/release evidence belongs to the predecessor source; this change
has no new full-suite, release, Linux/x86 or CLI run, and the old b9f0e3d Linux
packets do not cover it.

## Rounding expression transfers at 901181d2

Fixed std.jsonnet 1760/1770-1771 defines round(x) as floor(x + 0.5), with isInteger/isDecimal comparing that result to x; stdlib.html 254/257-258 supplies required x/no defaults.
[RP1-RP7](../../spec_rounding_predicates_contract_test.mbt) use independent source/handmade-AST literals for IEEE boundaries, finite extremes, binding, head rejection, sole errors and lazy demand; exact midpoint/significand reasoning replaces no expression with a Go oracle.
The preserved baseline passed 7/10 (new 4/7), with all RP1-RP3 observations executed; enabling the three unchanged source bodies then passed all seven new groups within 9/10, leaving only the old round-vector assertion failing.
The unchanged-input legacy vector migrates [-3,-2,-1,0,1,2,4503599627370497] to [-2,-1,0,1,1,2,4503599627370498]; the later, then-NOTRUN round(-0.1) String expectation changes -0 to 0 because floor receives a positive value. The mantissa(-0) String expectation remains -0.
[Durable evidence](../archive/reports/spec-rounding-predicates-2026-10-28.json) preserves the original failures and fixed fixture; final migrated validation is recorded separately from that pre-migration result.
The three accepted constructor-transfer scopes assume IEEE addition/finite checks, reviewed floor, numeric equality and ordinary-call/child-Value judgments; diagnostic tags/markers are extra embedding checks. All 107 prior mapping objects remain byte-identical, giving 110 mappings/43 unmapped candidates.
isEven/isOdd fractional parity remains a separate unresolved prose/source disagreement. No new ULP, diagnostic-winner or callback-count promise is added; prior full/release evidence is historical, with no full-suite, release, Linux or CLI rerun here.

## String utility transfers at c44f7d4a

Fixed std.jsonnet 1799 defines trim(str) through stripChars with exactly seven
characters: U+0020, U+0009, U+000A, U+000C, U+000D, U+0085 and U+00A0.
Line 1762 defines isEmpty(str) as length(str) == 0; both require str without a
default. [SU1-SU6](../../spec_string_utilities_contract_test.mbt) use independent
source/handmade-AST literals, binding/error/demand checks and immutable aliases.
The baseline passed 6/9 groups (new 3/6): trim removed 18 extra native whitespace
characters, while isEmpty rejected supported Array/Object/Function heads.
SU1/SU2 collected every 68/28 observation; SU6 stopped at its first Array error,
so its later aliases were then NOTRUN. Enabling only the two unchanged source
bodies passed all six frozen groups within 7/9, before any legacy migration.

Two old assertions contradicted these definitions: trim's U+2003/U+3000/U+2029
input now retains those characters instead of x alone; isEmpty([]) now explicitly
asserts true rather than an error, with null retained as a negative control.
The same nine groups then passed 9/9; the six-group fixture stayed byte-identical.
[Durable evidence](../archive/reports/spec-string-utilities-2026-10-28.json)
preserves the original outputs, frozen plan/fixture and both migration reasons.
The accepted scopes transfer the fixed definitions under reviewed stripChars,
length, ordinary-call and child-Value premises. Assertion/inheritance N0/R0,
resolvePath's shared array-concatenation A0, exact diagnostic priority and callback
counts receive no new decision. All 110 prior mapping objects are preserved,
giving 112 mappings/41 unmapped candidates. Overall conformance remains incomplete;
full-suite, release, Linux, CLI/API and reference comparisons were not rerun.

## Configuration check transfers at 7c291cdd

[CC1-CC10](../../spec_config_checks_contract_test.mbt) review all/any, assertEqual
and toString against fixed std.jsonnet 1661-1689, 842-850 and 37-38. The first
three already use source definitions; native toString and String concatenation
share coerce_string. No product repair or legacy-test migration was needed.
The first check exposed only an invalid MoonBit host-literal spelling; after
syntax/format correction the baseline passed 16/17, with six empty-container
String observations differing from an overconstrained []/{} literal oracle.
The fixed [tostring rule](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html)
requires single-line JSON, without specifying that unique whitespace. CC7 now
uses independent literal empty JSON values plus String/single-line checks; the
three original inputs remain, and nonempty spacing literals stay a separate
compatibility profile. The then-NOTRUN CC7 error section subsequently passed.
[Durable evidence](../archive/reports/spec-config-checks-2026-10-28.json) retains
the original fixture, plan, parse/format failures and 16/17 output separately
from the final 17/17 (ten new groups and seven unchanged regressions).
The transfers assume existing ordinary-call, Boolean/Array/equality, visibility
and String-coercion children. A0/N0/R0/cmp/PE0, exact diagnostic presentation and
callback counts are unchanged; old Array regression results do not settle A0.
All 112 prior mapping objects are preserved, giving 116 mappings/37 unmapped
candidates. Overall conformance remains incomplete; full-suite, release, Linux,
standalone CLI/API and reference comparisons were not rerun.
