# Bounded integer shifts and demanded counts

## Frozen criteria

Base 983a7d1e328d4c01ea59f46c51bc40b8652e8bc7. Official Jsonnet remains
bbb38f1020be1f5aed560928fb839b2c448cefb4. The fixed
[numeric execution prose](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#execution)
(spec.html 2806-2817) first converts bitwise operands to signed 64-bit integers,
performs the operations, then converts back to binary64. For << and >>, the
right value modulo 64 is the count; a negative count raises an error.

This batch chooses finite integral operands exactly representable in binary64
and strictly inside the signed-64 positive upper boundary; -2^63 is used only
as a demanded negative count. Their integer conversion is identity. Nonnegative
left-shift values/results fit the signed range without losing bits; right-shift
left values are nonnegative. For k = count mod 64, left results are x * 2^k
and right results floor(x / 2^k). All selected outputs are exact binary64
integers, so no host-width narrowing or conversion-back rounding is needed.
The normal table contains literal results, never host shift/modulo calls or
current/Go output. At residue 63 the left input is zero; moving a nonzero bit
into the sign bit is outside this chosen contract.

Normal counts cover numerical -0/0, 1, 31/32, 61/62/63, 64/65, 126/127/128/129,
2^32+1, 2^53-1, 2^53+2 and 2^63-1024. Negative integer counts include negative
multiples of 64 and the exact lower signed bound: they must fail, even with a
zero left value. This does not settle fractional conversion or pre/post-conversion
negative-fraction checking. Inputs at +2^63 or outside signed-64, negative-left
sign filling, discarded/sign bits, general integer-to-binary64 rounding and
architecture-specific legacy conversion expectations remain outside this review.
These are scope limits, not implementation exemptions or new paper conflicts.

| Group | Independent required outcomes |
| --- | --- |
| SH1 | Source and independent canonical finite Literal ASTs match the declared << / >> table. Large exact counts use their low six count bits without a host-32-bit narrowing. Numerical -0 is count zero; no rendered/sign-bit zero claim. |
| SH2 | Both operators reject every declared negative integer count, including -64/-128 and -2^63, with zero or three on the left. Unused whole operations return 42; zero left cannot bypass count validation. |
| SH3 | Every nonnumber outer kind rejects Type in either role without reading Array/Object payloads or Function defaults/body. Isolated required left/count errors propagate Runtime, including count error with zero left. Unselected branches, explicit Boolean shortcuts and hidden fields stay lazy. Missing source operands reject Syntax; no malformed Binary AST counterpart is claimed. |

Source parsing and handmade AST execution are separate entry paths, not a
complete syntax proof. Error tags are local API checks; the fixed specification
does not standardize error presentation. No order is asserted between two
independent failures. Only the explicit Boolean shortcuts are used, without
adjudicating B0's demanded non-Boolean RHS. No nonfinite successful value is
introduced. Existing PI1/PI2 pair-static, PREC1/OT3 grouping/token, BS1/BS2 lazy
and NT4 producer evidence retain their original scopes and are not rerun.

numeric_test.mbt is byte-identical to its historical 5651ae9 version. Its mixed
source vectors include useful count examples, but also fractions, sign-bit
wrap and explicit architecture branches. This batch does not promote those
combined assertions to an independent normative result or rerun that file.
The new values, independent ASTs and demand/type controls fill a concrete gap.

EXEC-OPERATORS stays partial. The two unreviewed > formulas and all previous
A0/B0/N0/R0/PE0/DF0, conversion, syntax and Unicode limits remain unchanged.
No whole bitwise/child-rule or language completion follows. The public inventory
is regenerated only to pin the tracked new test and base; no public function
reviewed dimension or signature is added. Candidate discovery is not execution.
Use existing schema v2/generators, three bounded native debug groups, nice 10,
frozen -j 1, no parallel testing. Retain any first failure before a minimal fix.
No full suite, Go/C++ run, remote/browser/install/push, proposal or dependency.

<!-- Criteria above are frozen before execution; append results below. -->

## Results

The first native debug invocation passed **3/3**, exit 0, in 8.992 seconds:
`nice -n 10 moon test spec_bounded_shift_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize`.
Test SHA-256 remained
`dff823b5287e3a7a6a502f04bbdc7a3afbd589fa5db019396f5df8e801df3d81`
through final checks. No product failure, fix, fixture/oracle change or later
semantic rerun was needed. The mixed legacy numeric group was not executed.

SH1 matched the exact result table through both independent entries, including
large admitted counts and all declared boundary residues. SH2 rejected negative
integer counts even with zero left and a zero modulo residue. SH3 kept the
outer-type/required-error/unused boundaries distinct and rejected the four
missing-operand source spellings without a fabricated malformed AST analog.
The existing static/precedence/Boolean evidence was reused in its original scope.

Inspection found operators.mbt converts both heads with bitwise_integer,
rejects a negative numeric right operand, uses y modulo 64 for both shifts,
then converts the Int64 result back to Double. The conversion delegates to
reference_int64. This observation supports the selected identity-conversion
domain, not general FFI conversion/rounding or an out-of-range/architecture
policy. The independent result table was fixed before this execution.

Check, info, fmt, script-format check and both inventory generators exited 0.
Product, interfaces, old tests, checker/harness and generators are unchanged.
All 192 old language evidence objects, 68 named review records and 23 other
prose records remain unchanged. SH1-SH3 bring the mapping to **195 canonical
case IDs**, not 195 newly executed tests. The 94-row matrix remains **28 named
complete (9 static, 19 evaluation), 1 relative constructor complete, 63 partial,
2 unreviewed**. EXEC-OPERATORS is partial and the two > print conflicts remain.

The public snapshot pins base 983a7d1 and this staged test's hash. Its Markdown,
all 40 manual records, all 153 function entries/whole-function statuses and all
reference candidates are unchanged; only snapshot input provenance changed.
The 37 functions with reviewed dimensions gain no new operator-derived claim.

Raw receipts: `/tmp/moonjsonnet-bounded-shift.7i2_rune`. No full suite, Go/C++
comparison, remote operation or push ran. Historical 539/539 stays bound only
to 5651ae9. Fractional/out-of-range conversion, negative-left sign filling and
sign/discarded bits remain outside this bounded result with all prior limits.
