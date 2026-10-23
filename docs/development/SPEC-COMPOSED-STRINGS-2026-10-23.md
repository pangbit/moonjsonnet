# Public deepJoin and lines contracts

Base f6fce6dbeb79a7a6bbdfc118ed86906853b35491. The six-group independent
source/handmade AST fixture passed its first native debug execution. No product
defect was exposed and no implementation changed. The fixed obligations below
were prepared and frozen before the reserved execution slot; the recorded
result is a bounded subset, not whole-function conformance acceptance.

## Fixed definitions and independent expectations

The fixed official commit is bbb38f1020be1f5aed560928fb839b2c448cefb4.
The [public declarations](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#std-deepJoin)
(stdlib.html 2426-2477) and
[source definitions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L306-L336)
give both functions one required arr parameter, without a default or name
conflict. Existing array_std_test contains a deepJoin normal example and a
null rejection, but neither function had a manual coverage record at the base revision. These old
examples and historical join/flatten results are not this fixture's execution.

deepJoin returns a String root unchanged, recursively traverses Array roots,
and concatenates String leaves in order without a separator. Empty arrays
contribute no text. Every other root or recursive leaf kind is rejected.
In particular null reaches deepJoin's own rejection before the surrounding
join can skip it. Object fields and Function defaults/bodies are not needed
to reject those heads.

lines is defined as join('\n', arr + ['']). The appended empty string causes
one trailing newline per retained String item, including empty strings.
An empty input returns an empty string. Outer null elements are skipped by
the fixed join definition; all-null input also returns an empty string.
This is a source-defined exception absent from the public Array-of-Strings
prose, not a policy inferred from Go output. Nested arrays are not flattened
or converted into lines. Existing newlines, Unicode scalars and NUL data are
preserved verbatim; no normalization or escaping is introduced.

The fixed [language reference](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md)
requires immutable values (93), strict Strings (128), lazy arguments (154)
and lazy Array elements (203). Both output strings must be fully constructed
even for length or index zero. Unused entire calls remain lazy. Successful
native gates distinguish an unrequired rejected payload from a Runtime
exception raised by that payload; merely matching an error category would
not establish non-demand.

| Group | Frozen assertions (NOTRUN at freeze time) |
| --- | --- |
| CS1 | Ordered nested/string-root deepJoin data; empty roots/nested empties; lines empty/all-null/empty-String/trailing-newline cases; Unicode/NUL and embedded newlines; positional and named arr calls. |
| CS2 | deepJoin rejects all non-String/non-Array root and nested leaf kinds; lines rejects non-Array roots and non-String/non-null members. Native payload gates stay uncalled for rejected Object/Function/Array heads. |
| CS3 | Isolated root and later leaf errors propagate for whole result, length and early selection; unused versions remain lazy. |
| CS4 | Original nested/top-level arrays and aliases retain literal data under input-first/result-first conditions; lines must not append its sentinel to the original; repeated calls agree. |
| CS5 | Original input and String leaves are shared once across length, repeated result reads, original reads and another call; unused calls run zero native gates. |
| CS6 | Missing/extra/unknown/overlapping bindings reject before argument gates; unused invalid calls remain lazy; free names remain Static. |

The fixture is [spec_composed_strings_test.mbt](../../spec_composed_strings_test.mbt).
It uses existing neutral builders for separate source strings and typed ASTs;
all expected JSON results are literal independent data. CS labels are public
report groups, not canonical language IDs. Type/Runtime/Static categories and
native counters describe intended embedding checks, not official diagnostic
wording or a universal callback/error ordering promise.

Whole-function acceptance, Object assertions/inheritance/self, root/std
rebinding, Function equality/PE0, competing failures, full binding combinations,
host encoding/resource limits and conversion edges remain outside this subset.
A0 and the other language print conflict, DF0/HP0, BOM/surrogate and prior shift
exclusions retain their status. No formal transfer rule is promoted here.

## Reserved execution slot and observed result

Preparation used read-only review and formatting while the user's priority
project retained the heavy-resource slot. The preparation receipt and original
NOTRUN report remain outside the repository. No old binary or historical suite
result was relabeled as execution of this fixture. After the parent allocated
a short slot, the frozen test, report and pending-map hashes were verified and
these exact native commands ran sequentially:

```sh
env RUST_LOG=error moon check . --target native --frozen --deny-warn -j 1
env RUST_LOG=error moon test spec_composed_strings_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize
```

The check exited 0 in 0.53 seconds real time. The first and only semantic run
exited 0 in 8.88 seconds real time: 6 passed, 0 failed. Measurements are from
/usr/bin/time -p and include command execution, not an isolated evaluator
benchmark. Both used one build worker; tests ran without parallelization.
The fixture limits remain 20,000 steps, depth 64 and stack 96 per evaluation.
Peak memory was not measured. The slot was explicitly returned immediately
after these commands; no further native test or full build was started.

This is Darwin arm64 native debug, Moon 0.1.20260920 (914d7da), moonc
v0.10.14+7d59c7ec9. The test SHA-256 before/after execution and formatting is
`896627825a13c8760a163a97fe2f49a22155be78e3204c08acde6bdf3fce1ed0`.
Its opening pending-execution comment records the freeze stage; this section
supersedes that status while retaining the exact tested bytes. All source and
handmade paths in the six groups ran. No expectation was revised to match
product output. The zero payload gates in CS2 distinguish domain refusal from
accidental payload errors, including where both would be tagged Runtime.

The two frozen candidate records were reconciled only after this result.
Changes advance pending-status wording to the executed evidence; values,
domains, demand obligations, declarations and exclusions remain unchanged.
Twelve scoped references identify the two function arms within six groups.
The prior 52 manual records are preserved, yielding 54 records and 51 functions
with reviewed dimensions among 153 candidates. Whole-function statuses remain
unaccepted and behavioral_conformance_proven stays false.

No product code, old test, Go fixture or public interface changed. Neighboring
tests were not rerun because no implementation path changed. The language map
and regenerated JSON/Markdown remain byte-identical to the base: 28 completed
named transfers, one constructor relative to its children, 63 partial rows,
two unreviewed rows and 195 canonical IDs. The previous unknowns remain open.

Warm-cache info exited 0 in 0.29 seconds; formatting exited 0 in 0.04 seconds.
Both existing inventory generators and the final documentation validator have
separate command receipts. They are metadata checks, not added semantic runs.
The public generator records the base and pending new test path at generation
time; final staged/committed readback is recorded separately.

Current full suite, Linux, release and Go/C++ comparison remain NOTRUN.
Preparation snapshots, command intents, stdout/stderr, timing and completed
receipts are retained in `/tmp/moonjsonnet-composed-strings.SkAJEG`. Owned
commands are accounted for by their completed results; unavailable system
process enumeration is not bypassed. No push, release, upstream edit or private
proposal material is included.
