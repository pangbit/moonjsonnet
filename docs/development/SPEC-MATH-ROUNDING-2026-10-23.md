# Finite floor and ceil contracts

## Frozen selection and oracle

Base 6905810d7f498462ff6c41aff1f6e882ff3b5f1f. The remaining three unreviewed
language rows are greater-than-true/false and EXEC-BUILTINS. The first two retain
the already recorded printed-comparison conflict; this batch does not probe it.
EXEC-BUILTINS includes an independently clear mathematical subset: floor/ceil.
The existing public inventory has no direct reference or reviewed dimension for
either function. That is a concrete acceptance gap, not a reason to generalize
from native registration or legacy Go math examples.

Official Jsonnet remains bbb38f1020be1f5aed560928fb839b2c448cefb4. The fixed
[standard-function prose](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#execution)
(spec.html 2820-2839) defines standard mathematical behavior on IEEE double
precision. The same [public declarations](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#math)
(stdlib.html 241-242) give floor(x) and ceil(x), one required parameter each.
For admitted finite input x, floor is the greatest integer <= x and ceil the
least integer >= x; the result remains a Number, not a host-width integer.
Nonnumeric values are outside this mathematical domain and must fail.

The independent table contains literal results for positive/negative fractions,
integers, both numerical zeros, nonzero subnormals, neighbors of one, the exact
half immediately below 2^52, values around 2^53 and finite maxima. No expected
answer is computed with MoonBit floor/ceil, an interpreter or Go/C++ output.
Parsed source operands and independently built canonical finite Literal ASTs
are separate entries. This assumes their admitted values; it does not complete
source-number conversion/rounding, and numeric equality does not check zero's
sign bit or rendered spelling.

| Group | Independent required outcomes |
| --- | --- |
| MR1 | The fixed table yields the literal floor/ceil pairs through source and handmade AST calls, both positional and named x. Subnormal results are 0/1 and -1/0; 2^53-scale integers and finite maxima are unchanged without narrowing. |
| MR2 | Six nonnumber value heads reject Type without reading Array/Object payloads or Function defaults/bodies. Required explicit errors propagate their isolated Runtime marker. A reused overflow-producing pow child still fails under floor/ceil instead of becoming a successful nonfinite value. Each unused whole call returns 42. |
| MR3 | Missing/extra/unknown/overlapping bindings reject Runtime before supplied native gates run; unused calls stay lazy. Unselected branches, explicit Boolean shortcuts and hidden fields do not demand an error operand. An undefined operand rejects Static even when unused/skipped, through source and handmade AST admission. |

Runtime/Type/Static tags, binding-before-native counters and entry identities
are host API checks. The specification models stuck errors and does not
standardize presentation; these checks do not become universal mathematical
callback-order/count requirements. Only unambiguous Boolean shortcuts are used,
without a demanded non-Boolean RHS or B0 conclusion. No NaN/Inf success or
malformed host-value admission policy is introduced.

Reuse NT4, PG2, FINITE, AP3/AP5 and F5 plus existing foundation numeric/forcing
reviews within their own scope, without rerunning them. The old std_math tests
explicitly expect Go behavior and are not the new oracle or new passing evidence.
No transcendental/modulo/mantissa/exponent/round/extVar/native semantic contract
is completed. A0/B0/N0/R0/PE0/DF0 and all prior print/syntax/Unicode limits remain.
EXEC-BUILTINS gains scoped evidence only and remains partial. Public floor/ceil
N/E/L/B entries mean reviewed subsets, not whole-function conformance.

Use existing schema v2 and the public inventory generator. Add only two public
manual records; retain every old record. Regenerating the inventory refreshes
reference candidates and input hashes, never historical execution claims. Its
root-test discovery uses git ls-files, so stage only the passed new test before
that read, then freeze the complete explicit file set before committing.
Three bounded native debug groups, nice 10, frozen -j 1, no parallel testing.
Preserve first failures before any minimal repair. No new checker machinery,
full suite, upstream run, remote/browser/install/push, proposal or dependency.

<!-- Criteria above are frozen before execution; append results below. -->

## Results

The first invocation stopped at compilation: three host exponent literals
without a decimal point were not valid MoonBit spellings. No semantic test ran.
The original source/log are retained. Only those host spellings gained .0,
followed by formatter layout and optional trailing commas. A separate diff
audit retains every String literal and other token after those spelling repairs.
Jsonnet strings, mathematical values, result vectors and frozen criteria were
unchanged. This was a fixture syntax repair, not a product defect.

The corrected first semantic invocation passed **3/3**, exit 0, in 8.001 seconds:
`nice -n 10 moon test spec_math_rounding_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize`.
Test SHA-256 remained
`295f1381bc503fbda64c8fd79ee2ba083196c915ad5949ede6aa6b675dbf0ebc`
through final checks. No product repair, expected-result change or later
semantic rerun was needed. MR1 matched its literal finite table; MR2 preserved
outer-type/required-error boundaries; MR3 preserved lazy paths and zero native
argument gates for invalid bindings. No old group or Go math fixture was run.

Inspection connects the selected behavior to stdlib.mbt: floor/ceil require x,
bind arguments before forcing values, apply number_value without coercion and
return finite(Double.floor/ceil). runtime_types.mbt rejects nonnumber heads
and nonfinite successful results. These are implementation checks against the
independent mathematics, not the source of the expected vectors or a proof of
all values in the backend. Source conversion, sign-bit/rendering, arbitrary
resource/diagnostic combinations and every other builtin remain separate.

Check, info, fmt, script-format check, language matrix and public inventory
generation exited 0. Product, interfaces, old tests, checker/harness and both
generators are unchanged. All 189 old language evidence objects, 68 named
records, 23 other prose records and 38 old public manual records were preserved.
MR1-MR3 add **192 canonical case IDs** in total, not 192 new executed tests.
The 94-row language matrix is **28 named complete (9 static, 19 evaluation),
1 relative constructor complete, 63 partial, 2 unreviewed**. EXEC-BUILTINS is
partial. The remaining two unreviewed rows retain their printed > conflict.

The public map now has 37 functions with reviewed dimensions, including two new
floor/ceil subsets; its 153 candidate names and all whole-function unaccepted
statuses are unchanged. Only ceil/floor reviewed subsets changed in the
generated inventory. Nine functions have refreshed reference candidates, which
are discovery metadata, not passing assertions. The snapshot pins base 6905810
plus the staged new test's hash; it is not a full-suite execution receipt.

Raw receipts: `/tmp/moonjsonnet-math-rounding.ut1pg6t8`. No full suite, upstream
comparison, remote operation or push ran. Historical 539/539 remains bound only
to 5651ae9. A useful next partial-domain review is bounded signed-64 shift
counts/modulo-64 and negative-count rejection, excluding legacy out-of-range
conversion/architecture expectations and reusing numeric/static evidence.
