# Public integer String parser contracts

## Frozen definitions and scope

Base fd4aa2c3966076b357cc8e75cd3be223595b9137. This batch reviews parseInt,
parseOctal and parseHex as a single String-to-Number contract group, reusing
the existing public inventory and manual N/E/L/B schema. It does not merge
String numeric data with source-number tokenization or host integer casts.

Official Jsonnet remains bbb38f1020be1f5aed560928fb839b2c448cefb4. The
[public declarations](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#std-parseInt)
(stdlib.html 1177-1257) describe signed decimal, unsigned octal with leading
zeroes and case-insensitive unsigned hexadecimal. Their fixed
[definitions and parse_nat helper](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L75-L113)
give the following additional explicit criteria:

- Each public parser requires a nonempty String. parseInt permits a leading
  minus, with at least one remaining digit. The helper rejects a plus sign;
  the documentation's word signed does not explicitly require accepting plus.
  parseOctal/parseHex do not remove any sign or radix prefix.
- For decimal and octal the helper's codepoint calculation admits exactly
  ASCII digits of that radix. Hex decimal digits and A-F/a-f have their usual
  independent values. Whitespace, separators, radix prefixes, out-of-radix
  letters/digits and selected non-ASCII characters fail in the clear domain.
- parse_nat folds Number arithmetic from zero with a separate base multiply
  followed by digit addition. It neither creates an Int64 intermediate nor
  specifies an Int64 range. Selected exactly representable values beyond that
  range therefore remain valid. The fixed finite-Number execution contract
  rejects actual arithmetic overflow before type inspection; an unused call
  does not perform that arithmetic.

There is a specific excluded domain question, HP0: the helper's fallback
`code - zero_code` also gives U+003A through U+003F the values 10 through 15
for base 16, whereas the documentation calls the input hexadecimal. These
punctuation aliases are not ordinary hexadecimal notation. This batch does
not decide a documentation/source precedence for that discrepancy, test those
aliases as normative successes, or change the source definition to guess a
resolution. Malformed host Strings/surrogates are also excluded. Ordinary
digits/letters and unambiguous rejected characters do not depend on HP0.

## Manual evidence plan before execution

| Group | Independent obligations |
| --- | --- |
| IP1 | Exact small values, leading zeroes, negative decimal/numeric zero, octal digits, hex upper/lower/mixed case, named/positional str, and selected exact radix powers beyond Int64 for octal/hex. |
| IP2/IP3 | Source and independently built AST parseInt reject +12 as required by the fixed helper. |
| IP4/IP5 | Source and independent AST parseInt accept positive/negative 10^20. Each decimal prefix is exact in binary64, so no general rounding oracle or host Int64 conversion is involved. |
| IP6 | Empty/sign-only/clear invalid String data fail; wrong outer kinds and needed input errors fail without reading unrelated Array/Object/Function payloads. Error categories are embedding checks, not a public diagnostic-format promise. |
| IP7 | Overflowing digit Strings fail before std.type can return number; unused whole calls stay lazy. Missing/unknown bindings reject before argument native gates, and unused free operands remain Static. |

All typed trees are assembled separately from source; expected JSON Numbers
are literal independently derived values. IP7 uses at most 343 input digits
and a bounded 100000-step limit for source-fold execution, not an unbounded
stress test. Other groups reuse the existing bounded test helpers.

Existing [std_string_test.mbt](../../std_string_test.mbt) has source examples
for hex case, octal leading zeroes and clear invalid data. Its Go-oriented
parseInt plus acceptance and Int64 range expectations are not the oracle.
The suspected native discrepancy must fail on unchanged product first. If
confirmed, restrict the correction to parse_decimal; retain all original
bytes, keep the new regression expectations fixed, and replace the legacy
combined plus/Int64 example with -12 and exact +/-10^20. Move its two former
Int64-overflow refusals to genuine positive/negative decimal arithmetic
overflow. Keep the frozen Go differential fixture and historical report
unchanged, and explain the resulting compatibility differences.

No whole function, all decimal rounding, zero-sign rendering, resource/error
format combinations, HP0 or source-number grammar is accepted by this group.
The language matrix and all prior unresolved/shift boundaries remain intact.
Use one low-priority native-debug worker and the existing generators/checkers;
run only necessary regression neighbors after a confirmed fix. No full suite,
new dependency, remote comparison, push or private application materials.

<!-- Criteria above are frozen before execution; append results below. -->

## Failed regression, correction and bounded verification

The original unchanged-product run exited 2: seven groups, two passed and five
failed. Four failures independently demonstrated the source/AST plus-acceptance
and Int64-bound discrepancies. IP6's fifth failure was a fixture error: source
assertions use this embedding's Assertion category, whereas the test had used
Runtime. Native parseInt malformed Strings still use Runtime and its wrong
outer types use Type. This tag distinction is not a public diagnostic promise.

The original test and failure log remain retained. Only the two IP6 category
expressions were corrected; no digit/sign/value/finite/lazy/binding assertion
changed. A directed rerun on still-unchanged product then exited 2 with three
passed and exactly the four product regressions failed. That corrected failed
fixture has SHA-256
`69bbab1aa131e4d3a4b43c8cdde5d8ece0c74bf05637743ee9b26a6d490c34f1`.
The first pre-correction fixture remains separately identified as
`ef787f4e8ca7148e493949b6615ca734ee27b990755c5149ad612d010d671a5e`.

The product correction changes only parse_decimal in std_string.mbt. A leading
minus is removed; every remaining character must be an ASCII decimal digit.
Accumulation uses separate finite Number multiply and add steps, followed by
the optional negation, without an Int64 intermediate. Every later helper in
that file is byte-identical to the base. Dispatch, public interfaces,
parseOctal/parseHex definitions and finite admission itself are unchanged.
The corrected product SHA-256 is
`452c93c47828f66e9f2b683338651c96b26cc65ca162bb3f821d91fbc63ffbf0`.

After this correction the exact corrected failed test bytes passed 7/7.
The decimal 10^20 witness is exact independently: its odd significand 5^20 is
below 2^53, as are those of its prefixes. The chosen octal/hex large witnesses
are powers of two. These cases establish the missing non-Int64 contract
without claiming a general decimal-rounding result.

| Directed file | Passed |
| --- | ---: |
| spec_integer_parsers_test.mbt | 7/7 |
| std_string_test.mbt | 2/2 |
| arguments_test.mbt | 1/1 |
| standard_native_diagnostics_test.mbt | 2/2 |
| spec_review_test.mbt | 4/4 |

All five commands exited 0, totaling 16/16, using nice 10, native debug and
`--frozen --deny-warn -j 1 --no-parallelize`. The original legacy combined
plus/Int64 example and two former range failures were migrated exactly as
planned above; a token audit excludes any other legacy assertion change.
All original bytes remain in the raw evidence. The old broad test's Go wording
is historical; this parser subset now follows the fixed official definition.

## Compatibility and inventory outcome

Accepting plus and imposing a signed Int64 bound were documented historical
Go-oriented native behaviors. They are superseded here. The current
[compatibility rows](../reference/COMPATIBILITY.md) now describe the corrected
contract and HP0. The frozen Go fixture and historical report are unchanged.
In particular, the fixture entries string-parse-int-limits,
string-parse-int-overflow-error and string-parse-int-underflow-error encode the
old sign/range choices. They cannot be used as normative acceptance criteria
for this correction. No new Go/C++ execution or compatibility pass count is
claimed, and general rounding-related comparison outcomes remain unmeasured.

The manual maps were frozen before the first run. After the IP6 fixture
correction only IP7's declaration line was reanchored in the three records;
their fixed expectations and scope are unchanged. The three new public
subsets preserve all 45 previous records, yielding 48 records and 45 functions
with reviewed dimensions among 153 candidates. Only the three parser
reviewed-subset/reference snapshots change. All whole-function statuses remain
unaccepted and behavioral_conformance_proven remains false. IP labels are
report groups, not new canonical language IDs.

Root check, info, formatting and both existing generators exited 0. Public
interfaces are unchanged. The language manual mapping and both generated
matrix files remain byte-identical: 94 rows, 28 completed named transfers,
one constructor transfer completed relative to children, 63 partial, two
unreviewed and 195 canonical evidence IDs. No old review requires a new
inspection hash: std_string.mbt is not one of its pinned inspection files.
Schema v2 and all existing checkers/generators remain unchanged.

HP0 is still unresolved; punctuation aliases were not probed or counted as
normative passes. Malformed host Strings, exhaustive accumulation rounding,
zero sign/rendering, all argument/error/resource combinations and whole
function conformance remain unproved. Earlier language print conflicts,
assertion/equality/desugaring unknowns and shift exclusions are preserved.
No full suite, remote test/comparison, dependency installation or push ran;
the historical full 539/539 remains bound only to 5651ae9.

Frozen inputs, both pre-fix failure logs, the category-only fixture correction,
after-fix results, scope/token/reanchor audits, generated snapshots and final
documentation/staged/commit receipts are retained in
`/tmp/moonjsonnet-integer-parsers.wke8_l7x`.
