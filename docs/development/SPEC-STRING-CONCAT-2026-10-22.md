# String concatenation and conversion boundaries

## Frozen criteria

Base: 15792d604f2906cafcdf503962038bec0e72ab70. Official Jsonnet:
bbb38f1020be1f5aed560928fb839b2c448cefb4. Only the currently unreviewed
string-concat judgment receives new coverage in this batch; other object,
assertion and manifestation rows retain their existing scoped decisions.

The [fixed string-concat rule](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#execution)
(2347-2353) requires both operand values, at least one in String, and joins
tostring(left) followed by tostring(right). Its explanatory text (2786-2790)
leaves a String unchanged; otherwise it manifests a JSON value and unparses
it as one line. The [String definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html#string)
states that Strings are strict. Merely inspecting the resulting String tag
therefore still requires its converted contents; ignoring the whole
expression does not. No relative timing of two competing failures is fixed.

The [manifestation text and rules](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#manifestation)
(2878-2886, 2948-2995) omit hidden fields, check assertions including empty
objects, force visible fields/array elements, and reject functions. The
published [toString contract](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#std-toString)
is made concrete by the same version's [official library definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L37-L38):
return an existing String, otherwise use empty-String concatenation. This is
a public library definition, not an observed Go/C++ result.

[manifestJson](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#std-manifestJson)
instead calls manifestJsonEx with four-space indentation. Its
[official aux definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1048-L1087)
quotes Strings and visits object values through visible field indexing. An
assertion-only object has no such index operation. Preserve this distinction
from implicit tostring/ordinary output; it does not excuse an implicit
conversion from the manifestation assertions required above.

Reuse O3/O4/O6/O7 from the [object review](SPEC-LANGUAGE-REVIEW.md) for
top-level assertion, visibility and nested function/error semantics; FINITE
from [defensive numeric guards](../../spec_manifest_wbtest.mbt); and SQ1/SQ4
from the [sequence record](SPEC-SEQUENCE-STRUCTURE-2026-10-22.md) for lazy
array concatenation and static/required-head boundaries. Existing
[numeric string-format tests](../../render_test.mbt) are compatibility
receipts, not a normative oracle for decimal spelling. No old group is rerun.

| New group | Independent required outcome |
| --- | --- |
| SC1 | Empty/ordinary/astral/combining/NUL/newline/quote/backslash String concatenation preserves contents and left/right order exactly. toString preserves a String; manifestJson of A includes JSON quotes. |
| SC2 | Both conversion directions and public toString yield one-line text whose host-parsed JSON equals literal null/Boolean/finite-number/array/object expectations. Hidden errors/functions stay unread, overridden erroneous values disappear, and forced-visible inherited fields are present. Do not prescribe whitespace, object key order or numeric spelling. |
| SC3 | Required operand heads, nested visible payload errors, root/nested functions and numeric overflow fail even under type(conversion). Ignoring each whole conversion yields 42. Functions are rejected as values without executing their erroring bodies. Error kind/unique markers are embedding controls; no competing-error order is asserted. |
| SC4 | Empty, hidden-only and nested assertion-only objects fail implicit conversion/toString even under type; unused conversions stay lazy. A true assertion leaves its erroring message unread. The same empty assertion object can be traversed by library manifestJson without visible indexing, and its result parses as empty JSON. A hidden free variable still rejects Static in an unused concatenation. |

Source text and handmade public ASTs are independently constructed using
neutral existing helpers; no parser-exported AST or product formatter builds
expected values. The host JSON parser only accepts legal spellings of
already fixed JSON expectations. Each case has one demanded failure; no
callback timeline, field traversal order or error wording is standardized.

This batch will remain a partial string-concat review: complete conversion
of every admitted Number/String, exact encoding/rounding domain, all value
producers and full mutually recursive manifestation/assertion semantics are
not proved by these finite controls. A0/B0/N0/R0/PE0, the non-Boolean filter
question, resource bounds and Go/C++ compatibility stay unchanged. Child
judgments are not promoted by this new consumer evidence.

Four bounded native debug groups, nice 10, -j 1, no parallel test execution,
steps=20000/depth=64/stack=96. No full suite, remote, browser, installation,
release/Linux, push, private external document or dependency. Preserve any
first semantic failure before a minimal product fix. Otherwise only tests,
this combined record and the existing matrix mapping change.

<!-- Criteria above are frozen before execution; evidence is appended below. -->

## Results and scope

The first directed native debug run passed **4/4, exit 0** in 7.182 s.
The executed source/handmade-AST test bytes remain unchanged, SHA-256
`b563491ec478bbc3f11e53a69dc92926b99e49e81201eeddb93f27eab2814eb0`;
first log SHA-256
`68e3eed91ee5d217ff66600d731275bc52d0148ef97ff479d64faef8d2e15499`.
No interpreter change was needed and no semantic group was rerun. The
previous check/info/fmt results remain valid for these same root sources;
no public `.mbti` or old test changed. Historical full native debug 539/539
continues to refer only to 5651ae9.

The [operator dispatch](../../operators.mbt) reaches coerce_string when
either operand is String; the String arm returns its content, while other
values pass through [ordinary manifestation](../../manifest.mbt) and a
single-line renderer. Its Object arm checks assertions before enumerating
visible names; its Array/field arms recurse into needed values, and its
Function arm rejects without calling a body. These facts explain why a
type-only observer of concatenation still exposes the isolated nested
failures, while hidden/overridden values and unused whole conversions do
not. The same path retains the finite-number check. This is separate from
[manifest_json_ex](../../manifest_json.mbt), whose visible-index traversal
explains the public manifestJson empty-assertion-object control. No observed
ordering of two failures, formatting layout or upstream executable became
a normative premise.

Only string-concat gains a new partial row. The 94-row matrix is now
**16 completed named judgments + 1 constructor transfer relative to children
+ 62 partial + 15 unreviewed**. Complete conversion/encoding/rounding and
recursive child judgments remain outside these controls. A0/B0/N0/R0/PE0,
the non-Boolean filter question and all old completion decisions are intact.

## Evidence identity repair

The original matrix check correctly rejected SC2's helper-only anchor.
It is now anchored to the named case's call and literal expectations; the
helper and all executable expectations are unchanged. A separate audit found
preexisting duplicate evidence keys SP1-SP3: precedence records were followed
by super records, and the parsed/generated map retained the super versions.
The old checker success therefore did not validate those precedence bindings.

The bad serialization draft and original failing logs are retained. The
mapping was first restored byte-for-byte from its frozen original, then
changed through recorded text spans rather than a lossy JSON rewrite.
Precedence's five records are now PREC1-PREC5 and bind to their original
file/cases; super retains SP1-SP3. Every old assertion and semantic source
hash is preserved. The historical [precedence record](SPEC-PRECEDENCE-2026-10-22.md)
keeps its original labels/results; its SP1-SP5 labels correspond to the
current matrix's PREC1-PREC5.

| Old affected row | Repair and limit |
| --- | --- |
| SYN-PRECEDENCE | References now select PREC1-PREC5 in spec_precedence_test.mbt. The clause remains partial; restored source bindings are not new semantic executions. |
| object-index, object-inherit | Existing SP references still select spec_super_prefix_test.mbt; generated rows and partial decisions are unchanged. |
| HIDDEN-INHERITANCE, SUBSTITUTION | Same preserved super bindings and row content; no additional object contract is accepted. |

Schema v2 adds a canonical file::case test_id for all **152** mapped cases.
The [matrix checker](../../tools/spec-language-matrix.mbtx) rejects duplicate
decoded keys in every JSON object (including escaped keys and objects inside
arrays), duplicate global test IDs, noncanonical paths and ID/file/case
mismatches. It retains the requirement that every anchor occur in the
selected named case. These checks protect metadata identity; they do not
prove an assertion's semantic meaning or execution.

The persistent [metadata regression harness](../../tools/spec-language-matrix-test.py)
uses only the installed Python standard library, existing Moon tooling,
tracked/staged sources and this batch's explicit new fixtures. Reproduce
from the repository root with
`python3 tools/spec-language-matrix-test.py REFERENCE_DIR NEW_EVIDENCE_DIR`.
**14/14 isolated negative controls** rejected at their intended guards before
output; positive readback exited 0 and verified all canonical IDs plus the
PREC/super bindings. During setup, two checker compile attempts failed, and
the first mirror positive run lacked Git metadata; those logs/source bytes
are retained. The corrected positive runs in the real repository. Its
input-checked resume reused the valid negative results; none were repeated.

Raw criteria, unchanged semantic tests, original mapping, bad draft, text
patch, collision impact audit, all failures and final metadata results:
`/tmp/moonjsonnet-string-concat.2ab_oquy`. Final documentation/link checking
and exact committed-byte readback are recorded there separately.
