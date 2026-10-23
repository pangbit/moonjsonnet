# Additive fields: prefix, capture and demand

## Frozen criteria

Base 3f7dbad5641e4f41dd6e48fce29132e7896b76ca; official Jsonnet remains
bbb38f1020be1f5aed560928fb839b2c448cefb4. The fixed
[field desugaring](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#desugaring)
(1370-1433) covers identifier/String/computed names and the additive branch.
The same version's [language guide](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html#nested-field-inheritance)
(language.md 539-543) explicitly defines this equivalence, including +::/+:::,
and says a missing parent field uses the right value directly:

```text
{k +h rhs} = {k h if "k" in super then super["k"] + rhs else rhs}
```

The name is tested against the field's defining prefix, including hidden
fields; self still denotes the final receiver. The
[visibility law](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#hidden_inheritance)
(1867-1890; language.md 441-473) preserves the parent separator for default :,
otherwise the new separator wins. Field visibility is independent of its value.
The guide's Field Name Expressions (578-591) puts key expressions outside the
object being created. For nested computed names, the additive formula replaces
self/super in its body-side name with captured outer references. Reference
fixtures model that capture with local key aliases, never a public bare-super
binding or an exported parser tree.

## DF0: literal ordinary-field composition is not proved

The printed ordinary computed-field equation (spec.html 1410-1413) has input
`[e] h e'` but emits `desugar_expr(local binds; e, true)` as the value. Literal
application to `["k"] : 3` therefore selects the key expression rather than 3.
The additive equation (1417-1424) constructs its conditional from rhs e', then
passes that conditional as the value into this ordinary-field rule. The guide's
explicit equivalent above retains rhs, so those literal compositions cannot
both establish the same value. No surrounding binder renames e to e'.

This batch uses the explicit guide equivalence, additive intermediate formula,
visibility and scope definitions as independent behavioral criteria. It does
not silently repair the printed rule or claim a complete formal Core derivation.
DF0 remains a concrete clarification: should the ordinary rule's value-side e
be e'? Prior bounded behavior/core-judgment evidence keeps its original scope;
no interpreter is changed to match a guessed paper correction.

| Group | Independent required outcomes |
| --- | --- |
| AD1 | All nine parent/additive separator pairs and identifier/quoted/computed spellings yield k=13 from 10+3, including hidden parents. Visible/all names follow the fixed literal table without reading payloads. Repeated reads return [13,13]; native gates observe each used left/right head once and neither on metadata/unused paths. |
| AD2 | Multilayer additive values use their defining prefix and final self, giving [14,119,999,16,18,16,18,16,18,1] across original/derived/extracted/rehosted reads. With no prefix k, a Boolean rhs remains false even if a later layer supplies k=99; standalone and empty-left forms agree. |
| AD3 | Nested computed names use outer final self.key and outer defining super.key, not the inner object's key. Middle/derived results are [14,23,30,"inner-child"] and [14,20,33,"inner-child"], with exactly key/x/y/z names and an unchanged [10,20,30] original. |
| AD4 | Isolated parent/rhs errors and an invalid demanded plus reject only when read, with no competing-error priority claim. Error key creation is required even by a name query; a null key omits its error rhs. A no-parent Function rhs keeps its body lazy until called. Unknown key/value names still reject statically in unused/skipped contexts. |

Each group tests original source plus independently constructed additive ASTs,
and separately written ordinary If/in/super-index reference forms against
literal outcomes. They are selected behavioral witnesses; public semantic ASTs
are not a formal Core export. Native counts are finite host demand/cache
controls, not a language side-effect model, universal callback ordering or
computed-key evaluation-count theorem. No order between independent failures
is asserted. New array-addition, assertions/reentry and object-local contracts
are excluded; A0/B0/N0/R0/PE0 and existing syntax/Unicode limits are unchanged.

Reuse F6/O2/O6, EX0VIS/EX1, SP1/SP2, OR3, PI2 and CK2 within their original
scopes without rerunning them. DESUGAR-FIELDS stays partial: DF0, full methods,
locals/binders, every field-name/substitution/child domain and complete nested
inheritance lowering remain outside this result. No schema/checker extension.
Four bounded native debug groups, nice 10, frozen -j 1, no parallel testing.
Preserve any first failure before a minimal repair. No full suite, upstream
comparison, remote/browser/install/push, private proposal or new dependency.

<!-- Criteria above are frozen before execution; append results below. -->

## Results

The first native debug invocation passed **4/4**, exit 0, in 9.417 seconds:
`nice -n 10 moon test spec_additive_fields_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize`.
Test SHA-256 remained
`831593d7e2afce69bf9a5dd8518ccb88c0f28648a35368d9316bea2c79284852`
through final checks. There was no product failure, repair, oracle change or
semantic rerun. All original/reference forms used separate source and handmade
entries; the prior plain-object/super/reflection groups were not rerun.

AD1 preserves hidden parent contribution and the declared visibility table
without payload demand for metadata; successful repeated reads observe each
payload once in the bounded host control. AD2 distinguishes prefix selection
from final self and preserves absence even under later same-name overrides.
AD3 distinguishes outer self/super key capture from inner field bindings, with
unchanged originals. AD4 separates key creation, omitted null names, static
admission, metadata and actual value/body demand, with isolated error markers.

Inspection found `eval.mbt` evaluates object keys in the outer environment;
`objects.mbt` stores layer fields, captures final self/defining super and tests
presence below the defining layer before applying + to a prior value. Its
field-value path computes rhs before the prior lookup. That is an implementation
observation, not a normative ordering conclusion; these witnesses intentionally
do not choose priority between independent failures. DF0 still blocks literal
whole-field formal composition, and no implementation output resolves it.

Check, info, fmt, script-format check and schema-v2 matrix generation all exited
0. Product/interface/checker/harness/old-test bytes are unchanged. All 185 old
evidence objects, 68 named review records and 23 other prose records remain
unchanged; only AD1-AD4 and the existing DESUGAR-FIELDS partial row were updated.
The mapping has **189 canonical case IDs**, not 189 newly run tests. The matrix
remains **28 named complete (9 static, 19 evaluation), 1 relative constructor
complete, 62 partial, 3 unreviewed** across 94 rows. No full desugaring or child
domain completion is inferred; all earlier unresolved boundaries remain.

Raw receipts: `/tmp/moonjsonnet-additive-fields.1th5lpcx`. No full suite,
Go/C++ comparison, remote operation or push ran. The historical 539/539 suite
result remains bound only to 5651ae9, not to this enlarged test inventory.
