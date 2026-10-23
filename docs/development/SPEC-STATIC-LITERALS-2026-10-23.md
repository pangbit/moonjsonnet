# Static scalar literal acceptance

## Frozen criteria

Base d215ad8edab2611bf8bf89e664b1d02e6566a7dd; official Jsonnet fixed at
bbb38f1020be1f5aed560928fb839b2c448cefb4. The [chk-lit rule](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#static_checking)
(1560-1564) has no premises and concludes:

```text
_ |- null, true, false, string, number
```

For a well-formed scalar literal, static checking accepts every payload and
environment without name lookup, runtime type tests or evaluation. Lexing,
host shape admission and runtime finite-number production are separate stages.
The [number token definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#lexing)
excludes a leading minus. The public AstKind documentation likewise defines
NumberLiteral as an unsigned decimal spelling and Literal as a scalar value.
Signed source expressions contain Unary; canonical finite negative AST
numbers are a separate value representation, not negative numeric tokens.

Reuse PG1/PG2 for admitted scalar kinds and finite numerical/String edges,
NT3/NT4 for malformed numeric shape versus valid-token admission and demanded
overflow, and QS2/QS3/QS4 for quoted versus canonical String data and invalid
source spelling. Their old results are not new executions. No NaN/Inf,
surrogate policy, source encoding or rounding behavior is accepted here.

| Group | Independent required outcome |
| --- | --- |
| LP1 | Null, both Booleans, finite canonical numbers, an unsigned raw numeric token and empty/name-like Strings create source/independent-AST Programs in root, local, function/default and object-field contexts. Ignoring each whole context returns 42. Literal text does not become variable/self/super/root syntax. |
| LP2 | Canonical finite signed-number AST leaves and correctly parsed signed source expressions admit; hand-built signed NumberLiteral payloads reject host Static before demand. Literal(Array/Object) also rejects host shape checking directly and unused, whereas proper Arr/Obj constructors admit. There is no lexical AST counterpart to malformed source strings. |

The structural review must inspect the unconditional Literal/NumberLiteral
validator arm, payload-preserving conversion and independent host shape
checks. It closes only chk-lit on the admitted core domain. There is no
in-rule static/runtime error case; LP2/NT3/NT4/QS4 are boundary evidence.
Nonfinite host Json numbers are outside the admitted successful value domain;
this batch neither probes nor assigns their host admission timing. Source
negative values involve the separately reviewed unary constructor. Function,
Array/Object, binder and enclosing child judgments are not completed by these
contexts. The adjacent value rule additionally contains Function/Array and
remains unreviewed. No other static rule remains among the eight unreviewed
rows at this base; none is invented or upgraded by association.

Use the existing premise-free record and schema-v2 checker without modifying
checker/harness code. Two bounded native debug groups, sequential nice 10,
frozen -j 1 and no parallel tests. Preserve first real failures before any
minimal repair. No full suite, remote/browser, install, push or private
proposal source. All previous child-relative decisions and A0/B0/N0/R0/PE0,
greater-than and encoding/surrogate unknowns retain their scope.

<!-- Criteria above are frozen before execution; append results below. -->

## Decision and result

The first native debug run passed **2/2, exit 0**, with test SHA-256
`280662a08529ece56b43d47692065f7bf289b878a77dc2f8b87953d793f2677e`.
The formatted [LP1/LP2 fixtures](../../spec_static_literals_test.mbt) were not
rerun. No product defect, interpreter change or public-interface change was
found. Prior PG/NT/QS controls were reused without new execution claims.

The [validator](../../validate.mbt) returns Unit for wildcard Literal and
NumberLiteral payloads; neither names nor object permission is read. This
covers every admitted payload/environment, beyond the finite probes.
[Typed conversion](../../ast_convert.mbt) preserves both representations.
[Host shape checking](../../ast_validate.mbt) separately rejects container
Literal carriers and malformed/signed numeric tokens. LP2 distinguishes that
stage from canonical finite negative numbers and source Unary signs. Raw
valid numeric spelling may still overflow only when evaluated, as NT4 already
shows. No new nonfinite or surrogate-domain expectation was manufactured.

This closes **chk-lit alone**, using the existing premise-free review form.
Its static-error and runtime-error cells are N/A for the core judgment, with
explicit shape/lexing/runtime boundary evidence retained separately. Source
String success does not prove all quoting/encoding, and unused enclosing
contexts do not prove their child/binder/object/function rules. The existing
paired-static and other child-relative decisions remain unchanged.

The unchanged schema-v2 checker passed **174** unique canonical file::case
identities, case-local anchors and inspected/test hashes. No metadata framework,
whitelist or new negative-control layer was added; old metadata controls were
not repeated. All 172 previous evidence records, 66 previous mapped rule
records and 24 prose records retain their bytes and meanings outside the two
new insertions. Only LP1/LP2 and the chk-lit review are added.

The 94 rows now record **27 named completions (9 static, 18 evaluation),
1 relative constructor, 59 partial and 7 unreviewed**. Remaining unreviewed
rows are value, greater-than-true/false, LEX-ENCODING, SYN-EXPR,
DESUGAR-OPERATORS and EXEC-BUILTINS. Other static rows can still be partial;
no unreviewed static row remains, which is not whole-static conformance.
The greater-than printing conflict is retained without further probing.

Native check, supported info, root/tool formatting and matrix generation
exited 0. All product, checker/harness, old-test and .mbti bytes are unchanged.
Tracked/staged document validation and final exact commit/blob/clean/process
receipts are retained in `/tmp/moonjsonnet-static-literals.3zzuijb3`.
Full-suite 539/539 remains bound only to 5651ae9, with no new full or upstream
run. A next independent review is value-head preservation for its exact
Primitive/Function/Array domain, separating raw numeric conversion and object
construction/manifestation rather than extrapolating from these static leaves.
