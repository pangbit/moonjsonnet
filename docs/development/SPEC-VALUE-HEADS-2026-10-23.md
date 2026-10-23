# Core value head preservation

## Frozen criteria

Base d5ea411e077e906585b8e7b14f323ccd7401a73a; official Jsonnet fixed at
bbb38f1020be1f5aed560928fb839b2c448cefb4. The [value equation](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#execution)
(2153-2157) states:

```text
v in {null,true,false} union String union Number union Function union Array
-----------------------------------------------------------------------
v evaluates to v
```

The [value definitions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#jsonnet_values)
(1786-1859) explicitly retain unevaluated Array elements and Function
default/body expressions. Object is absent from this rule and has a separate
construction judgment. Evaluation and JSON manifestation are distinct:
functions have no JSON representation, and manifesting an array demands its
elements. The [language Number domain](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#number)
excludes NaN/Inf. Raw decimal spelling and its conversion are not an already
admitted finite Number value; those boundaries remain in NT3/NT4/LP2.

Reuse PG1/PG2 for all primitive classes, finite edges and exact String values;
TYPELAZY/PG3 for nonforcing type/disjointness; AP1/AP2 for closure/default
capture; SQ1/MA3/IF5 for existing Array/Function demand distinctions. Do not
rerun these groups or use same-type primitiveEquals (PE0) as an oracle.

| New group | Independent required outcome |
| --- | --- |
| VH1 | An Array containing an observed outer variable, an error element and an error-bodied Function yields type Array, length 3 and selected Function type with no observations. Reading only position zero later returns the defining x=7 despite caller x=99 and observes only that element. Selecting the error element or manifesting an isolated error Array propagates its marker; ignoring those whole operations yields 42. |
| VH2 | A Function with observed default/body yields Function type with neither observation. Under caller x=99, an explicit p=3 yields 10 and only the body observation; default p=x yields 14 and both observations, capturing defining x=7. Separate error defaults/bodies are harmless at head demand and fail only on required application; function JSON manifestation rejects without running its error body. |

All new sources and trees are constructed independently. Type/length are
bounded head observers with literal expected outputs, not acceptance of whole
stdlib contracts. Observation sets impose neither callback order nor general
invocation counts. Marker/kind checks distinguish later demand from obtaining
a value head. Unknown child names are still checked statically, as in existing
MA3 and static-child evidence; no invalid child is admitted by this rule.

A complete decision requires case analysis of every admitted constructor:
unchanged primitive payload, unchanged Function parameters/body/defining
environment, and ordered Array expressions suspended with their defining
environment. Inspect capture/store helpers for hidden evaluation. Finite
passing cases alone are insufficient. Future element/application/static child
judgments, host native/builtin function representations, Object construction,
manifestation, source encoding/surrogates and numeric conversion remain
separate. Well-formed core values and finite Number membership are premises;
nonfinite successful values are never admitted to obtain completion.

Reuse the existing fixed-equation/premise-role validator path with a single
bounded value entry if this review closes. The same schema v2 and harness
serve four targeted refusal fixtures; do not build another framework.
No in-rule error is required for an admitted value; static/runtime rejection
boundaries must be explicit N/A or adjacent evidence, not fabricated passes.

Two new native debug groups, sequential nice 10, frozen -j 1, no parallel
testing. Preserve first actual failures before minimal repair. No full suite,
remote/browser/install/push/private proposals. A0/B0/N0/R0/PE0, greater-than
printing, and all prior child-relative/encoding unknowns retain their scope.

<!-- Criteria above are frozen before execution; append results below. -->

## Fixture-boundary correction before the second execution

The first run passed the Array group and failed the Function group's final
root-output assertion (1/2, exit 2). Its original source/log/result are retained.
The frozen no-Function-JSON/no-body-demand oracle remains unchanged. The
fixture incorrectly used Program.evaluate on a root Function to observe only
manifestation: the pre-existing [host API](../reference/API.md) explicitly
calls a top-level function once even without TLAs, and moonjsonnet.mbt applies
that convention before output. Thus the root's body marker was expected under
the host protocol; this was not a demonstrated value-rule implementation bug.

Before rerunning, change only that manifestation fixture to a single-element
Array containing the Function. This bypasses the top-level function protocol,
then manifestation reaches the Function value and must reject it without
calling the body. Keep both assertions. Only the failed Function group will
rerun; the passed Array case and common helper bytes must remain identical.
No product code or normative expected value is changed.

## Decision and receipts

The corrected Function-only run passed **1/1, exit 0**. The Array group keeps
its first pass; its entire case/common-helper prefix is byte-identical and was
not rerun. Original 1/2 failure source/log and the pre-retry API adjudication
remain in raw evidence. Final test SHA-256 is
`c333432caf47be1eb43ef9650c86309361f3dc5e6bcd80befc435cb2802a20fc`.
There is no demonstrated interpreter defect or product/API change.

The inspected scalar from_json/finite arms preserve every admitted payload;
Func returns Closure(ps,body,env); Arr maps each ordered expression to a
Pending thunk with its defining environment. Store only allocates a slot;
visibility/trace capture changes metadata without evaluating children or
changing lexical names. Already Ready(v) also returns v unchanged. This case
analysis closes **the value identity transition for its exact admitted core
domain**, with future child/application/static judgments explicitly separate.
It is not a partial-to-complete inference from test counts. Core Object is not
in this rule, raw numeric conversion is not an already finite value, and host
native/builtin function extensions are outside the formal Function grammar.

Schema v2 is unchanged. Its existing fixed-statement/premise-role path gains
only the bounded value entry, with in-rule static/runtime errors marked N/A
and later demand failures in boundary evidence. Four refusal fixtures reject
foreign-rule reuse, domain widening, forced-payload roles and erased input/
child assumptions before output. Positive readback passed **176** unique IDs;
no old metadata control suite or semantic full suite was repeated.

All 174 previous evidence records, 67 mapped rule records and 24 prose rows
retain their bytes and meaning outside the two insertions. Only value gains a
completion decision. The 94 rows now record **28 named completions (9 static,
19 evaluation), 1 relative constructor, 59 partial and 6 unreviewed**.
A0/B0/N0/R0/PE0, greater-than printing, encoding/surrogates and all existing
child-relative scopes remain unchanged; no compatibility result is inferred.

Native check, supported info, formatting and matrix generation exited 0.
Product, old-test and .mbti bytes are unchanged. Final tracked/staged document
and exact commit/blob/clean/process receipts are retained under
`/tmp/moonjsonnet-value-heads.b0rvg9_6`. Full native 539/539 belongs only to
5651ae9. A next distinct gap is LEX-ENCODING at byte-to-source entry paths,
using synthetic UTF-8 inputs while keeping any BOM-policy question separate.
