# Relational sign transfers: less, less-equal and greater-equal

## Frozen criteria

Base: 41df71f8d853faa1dd40de7008c7d194ab43f584. Fixed official Jsonnet:
bbb38f1020be1f5aed560928fb839b2c448cefb4. Six adjacent, unambiguous sign
transfers share one comparison child: less-than true/false, less-or-equal
true/false and greater-or-equal true/false. Four have bounded array evidence;
the last two are unreviewed. This batch supplies the missing direct scalar
and greater-equal consumer controls and reviews the complete sign dispatch.

The [fixed execution rules](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#execution)
(2360-2378, 2404-2443) define these literal outcomes:

| Admitted cmp(left,right) sign | left < right | left <= right | left >= right |
| --- | --- | --- | --- |
| -1 | true | true | false |
| 0 | false | true | true |
| 1 | false | false | true |

The same-version numeric prose (2796-2804) uses finite IEEE double numbers
and lexicographic Strings/Arrays, with Strings ordered by codepoint. The
cmp-number/string and five cmp-array rules (2448-2538) determine the new
fixture signs. Unsupported value domains cannot satisfy a comparison rule;
errors are modeled as stuck execution. Error kinds/messages below are
embedding controls, not standardized diagnostic wording.

The greater-than rules at 2382-2397 print `<` in their conclusions. Those
conclusions conflict with the less-than sign cases. Their raw text is not
repaired or accepted here; both greater-than rows stay unreviewed. No Go/C++
behavior is used to select an interpretation. The malformed `|||` boundary
and every other standing unknown are outside this batch.

As in the [array comparison review](SPEC-ARRAY-ORDERING-EVIDENCE-2026-10-22.md),
std.cmp denotes the comparison child relation in these rules, not an assertion
that a public std.cmp function must be registered. Six named transfers may
be completed **relative to that admitted child sign in {-1,0,1}**, with
left/right roles preserved. Whole operand/cmp judgments, arbitrary producers,
complete recursive array/scalar proofs, public-library registration and std
rebinding remain separate. This decision does not complete the comparator
rows or all comparison operators.

Reuse AO1/AO2/AO3 for the existing < and <= array branches, necessary nested
prefix and unused/demanded/static boundaries. Their source/hash and already
executed outcomes are retained; do not repeat those groups. New observations
are limited to the missing combinations below.

| New group | Independent oracle |
| --- | --- |
| RS1 | Literal (<,<=,>=) vectors for finite negative/equal/positive Number pairs, signed-zero equality, empty/prefix/codepoint Strings, astral versus U+E000, composed versus decomposed text and NUL prefixes. Expected booleans come from the fixed table and input values, never another comparator result. |
| RS2 | Greater-equal consumes all three admitted array signs: an empty side skips unmatched errors, a nested first difference skips inner/outer tails, equal nested arrays yield true. Required left/right heads and one reached element propagate their isolated Runtime marker; ignoring the whole comparison yields 42. |
| RS3 | Direct Boolean/null/Object/Function and number/string mismatches reject all three operators Type. Object fields/function bodies remain unread. New greater-equal array/non-array and reached noncomparable-element controls complement the existing AO3 cases; unused whole failures remain lazy. |

Every new expression is constructed independently as source and public AST
using neutral existing builders. A reused AO3 static rejection is an
adjacent child obligation, not proof of full chk-binary/array checking.
No ordering among independent errors or native callback timeline is imposed.
No NaN/Infinity successful value is admitted and existing finite guards stay
unchanged. Complete number decoding/rounding and encoding/resource behavior
remain unproved.

A restricted comparison-sign metadata form must pin the six exact formulas,
operator/sign partition, result Boolean, operand roles, child assumptions,
source/test hashes and explicit exclusions; it must reject the misprinted
greater-than rules and malformed records. This records complete transfer
constructors under their children, not whole-language conformance or a
completion percentage.

Three native debug groups, nice 10, -j 1, no parallel testing, using existing
steps=20000/depth=64/stack=96 limits. Preserve first real failures before any
minimal product fix; if none, leave product sources unchanged. No full suite,
remote/browser, installation, new dependency, release/Linux, push or private
external document.

<!-- Criteria above are frozen before execution; evidence is appended below. -->

## Results and completion boundary

The first directed native debug invocation passed **3/3, exit 0** in
8.037 s. No product defect was found, and no passed semantic group was
rerun. Executed test SHA-256:
`9e802e562d4d855e518bf298678b0004b5690a579e1790eb26d35c0b96d8278b`.
Product sources, old tests and public `.mbti` remain unchanged. Historical
full native debug 539/539 still refers only to 5651ae9.

[eval](../../eval.mbt) evaluates the comparison operands and preserves
their left/right roles before dispatch. [binary](../../operators.mbt)
obtains its comparison child once in those roles, then applies c<0, c<=0
or c>=0. On admitted signs {-1,0,1}, these predicates exhaust exactly the
six fixed-rule partitions. The >= default arm is uniquely selected by its
four-operator entry guard and the three other explicit arms. [AST conversion](../../ast_convert.mbt)
preserves the operator/ordered children. This case analysis closes the
result constructors relative to their child judgments, without using a
public std.cmp call or proving its complete child semantics.

The new normal/error/lazy controls agree with that result table, including
codepoint Strings, signed-zero equality, unsupported heads, skipped array
tails and required failures. Existing AO1/AO2/AO3 retain their bounded
array/static scope and are mapped without another execution. All cmp
child rows and the two greater-than rows are unchanged; their correctness
does not follow from the new completed result constructors.

The restricted metadata form pins formulas, operator/sign/result domains,
operand roles, child assumptions and source/test snapshots. **10/10 new
sign-form controls** reject at their intended guards before output; positive
readback exits 0 with **161** canonical file/case IDs. The harness's new
`--case-prefix sign-` selection runs just these controls and a positive
readback using tracked/staged inputs. Reproduce with
`python3 tools/spec-language-matrix-test.py REFERENCE_DIR NEW_EVIDENCE_DIR --case-prefix sign-`.
The prior global-identity negative controls are retained, not claimed as
fresh runs.

Check/info/fmt and standalone format checking passed. The new validator's
first compilation failed because a Json-literal edit accidentally rewrote
parts[1]; the failed source/log are retained and only that index was repaired.
Only matrix validation was retried afterward. Unrelated mapping formatting
was restored to the baseline layout; its ordered normalized serialization
is byte-identical to the tested base, so the selected dictionary-mutant
serializations are unchanged. Final matrix validation passes with the
restored bytes. Neither correction changed test expectations or product code.

The 94-row matrix is **22 completed named judgments** (6 static, 16
evaluation), **1 relative constructor transfer, 59 partial, 12 unreviewed**.
Four old partial result judgments and two unreviewed result judgments gain
these scoped completions. All other rule/prose decisions and A0/B0/N0/R0/PE0,
filter non-Boolean, malformed-block and surrogate boundaries are preserved.
Whole comparator children/producers, the conflicting greater-than formulas
and complete language conformance remain unproved; no implementation is
changed to resolve a speculative reading.

Raw criteria, first execution, exact metadata patch/equivalence proof,
compiler failure, targeted controls and final documentation/commit readback:
`/tmp/moonjsonnet-relational-sign.5cnpo4o_`.
