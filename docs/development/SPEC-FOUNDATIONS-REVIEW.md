# Foundation contracts: expectations locked before execution

This batch selects ten previously unreviewed public functions from the
[official inventory](SPEC-PUBLIC-STDLIB-INVENTORY.md). It does not count previous
length/sum/avg/removal/YAML reviews as new progress. Expectations below were
written before the first execution of the independent regressions.

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
| filter(func,arr) | Formal rule requires function and array; retain original elements with true predicate | String/non-array and non-function inputs fail, even empty; predicate must yield boolean | Evaluate predicates, not unused element payloads; preserve retained thunks, original input and memoization |

Review limits are explicit rather than guessed: negative makeArray cardinality
and range intervals yielding negative/nonintegral cardinality are not settled by
the terse formal rule in this batch. Callback declaration-count wording versus
ordinary optional-parameter application, signed-zero output formatting, pow(0,0)
and exhaustive transcendental rounding also remain outside these expectations.
These gaps cannot be counted as complete function acceptance. A bounded host
allocation error does not justify imposing a 32-bit integer range on small-result
range endpoints. removeAt naming remains unchanged.

The initial draft incorrectly used flatMap's string-concatenation behavior for
map. Source reconciliation after the first run corrected those two expectations:
map always returns an array and may map string characters to numbers. The initial
draft and all four first-run failures remain retained locally; the two map
failures were test-oracle errors, not implementation failures. No map change is
proposed to satisfy the incorrect draft.
