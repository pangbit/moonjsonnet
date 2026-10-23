# Static target/index and binary child transfer

## Frozen criteria

Base fcd140db0eb1680358c20b86d7813cb2fe285448; official Jsonnet fixed at
bbb38f1020be1f5aed560928fb839b2c448cefb4. The [static specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#static_checking)
(1622-1629, 1675-1679) gives these independent premises:

```text
chk-array-index: Γ ⊢ e ; Γ ⊢ e'  =>  Γ ⊢ e[e']
chk-binary:      Γ ⊢ e_L, e_R   =>  Γ ⊢ binary(e_L, sym, e_R)
```

The preceding static prose (1534-1548) explicitly supplies no static types.
These constructors introduce no binding, change no object permission and
must check both children even when the whole expression will be unused.
The binary grammar (746-767) supplies 19 symbols. Runtime short-circuiting,
integer/range checks and target/key types are different judgments. A
well-scoped fractional index or mixed-type operation must not fail Static.

Reuse IDX for prior source integer/range failures and successful Unicode/
integral indexing; reuse PREC1 for all 19 admitted binary symbols and existing
AO3/BS3/SQ4 static controls. Do not rerun those groups or treat their successful
runtime outcomes as a proof of a static constructor. New trees are independent
Index/Binary/Local/Obj constructions, never parsed AST exports.

| Group | Required independent outcomes |
| --- | --- |
| PI1 | Both child positions reject one free name directly, under unused locals and in unselected branches. A binding private to either child cannot leak into its sibling. Bound sibling names in the enclosing Gamma accept and unused execution yields 42, without evaluating their error-valued bindings. |
| PI2 | self/super/root accesses in either child reject outside an object, including dynamic field keys that have only the outer context. The same child expressions accept in appropriate own/inherited object field contexts, while the enclosing object stays unused. |
| PI3 | The direct super-index and in-super special branches require object permission and still validate their key child in the same Gamma. Missing keys fail Static even in unused inherited fields; bound keys admit without executing an inherited lookup. |
| PI4 | Source and handmade Index Programs admit nonintegral and out-of-range numeric keys, return 42 unused, then fail Runtime when demanded without reading an error-valued element. A valid zero key instead demands that element's isolated error marker. All binary symbols also admit unused heterogeneous operands; no dynamic operator result is inferred. |

The structural review must inspect the shared Index/Binary validator arm,
its super special branch, both child-preserving AST conversion paths and host
shape checking. Completion is only of these two constructor transfers relative
to the children's own static judgments. No child checker, binder/object rule,
index execution rule or full comparison/Boolean/numeric domain is completed.
There is no defined order requirement among competing failures; each negative
has one invalid child. Syntax/Static/Runtime/Type labels are embedding controls.

Schema v2 remains unchanged. Reuse the existing fixed-statement/premise-role
validation branch, adding only a bounded static-pair whitelist for these two
judgments and its static N/A treatment. Four targeted refusal fixtures use
the existing metadata harness; no new framework or broad control rerun.
Inspected sources/tests remain hashed. Full-suite 539/539 belongs only to
5651ae9; A0/B0/N0/R0/PE0, greater-than printing and encoding/surrogate questions
retain their existing status.

Four new bounded native debug groups, sequential nice 10, frozen -j 1,
no parallel tests/full suite/remote/install/push/private proposals. Preserve
first actual failures before any minimal product fix.

<!-- Criteria above are frozen before execution; append results below. -->

## Decision and evidence

The first native debug execution passed **4/4, exit 0**. Tested source
SHA-256: `21825d976ea91ebf6cb79dde93aa864116bbceab96d2f46d3690095fd8660325`.
The exact test bytes were retained through final checks; no semantic group
was rerun. There was no product failure or interpreter/public-interface change.
[PI1-PI4](../../spec_static_pairs_test.mbt) use independent source and typed
AST entry paths. Reused groups remain historical evidence, not new executions.

Inspection of [validate](../../validate.mbt) covers every normal Index/Binary
constructor through its common arm: two child checks with identical names
and object permission, no added bindings, type test or evaluation. The
special super-target/in-super arm checks permission and then the key in that
same context. [Typed conversion](../../ast_convert.mbt) preserves both child
roles and the Binary symbol. [Shape admission](../../ast_validate.mbt) is a
separate host precondition. The 19-symbol source grammar and existing PREC1
cover admitted Binary syntax without evaluating mixed-type operations.

Thus **chk-array-index and chk-binary are complete constructor transfers
relative to their own child judgments**. PI4's successful construction is
separate from its demanded integer/range failure; neither proves complete
array-index execution. The static rows mark runtime errors N/A and retain
PI4/IDX as boundary evidence. Child name/binder/object/root/super judgments,
including bare-super availability, full source grammar and operator runtime
semantics remain outside this decision. No greater-than print ambiguity,
Boolean B0 or object assertion N0/R0 obligation is accepted by this review.

Schema v2 and the existing checker/harness remain in use. The checker reuses
its fixed-equation/premise-role path with a two-ID static-pair whitelist and
the normal static runtime-N/A convention. Four fixtures rejected foreign-rule
reuse, formula changes, role reversal and missing child assumptions before
matrix output. Positive readback passed with **172** unique canonical test
identities and unchanged real inputs. Prior negative controls were not rerun.

All 168 previous evidence records and 24 prose records retain their original
bytes/meaning. Only the prior chk-binary record is upgraded, with its old
controls preserved, and chk-array-index plus PI1-PI4 are added. The 94 rows now
record **26 named completions (8 static, 18 evaluation), 1 relative constructor,
59 partial and 8 unreviewed**. This does not establish a conformance rate or
close any other child/evaluation rule.

Native check, supported info, root/tool formatting and matrix generation
exited 0; .mbti and every product/old-test byte remained unchanged. The final
tracked/staged documentation and exact commit/blob/clean/process receipts are
retained under `/tmp/moonjsonnet-static-pairs.hqn392e4`. No compatibility/full
suite, remote, install or push ran. A next bounded static leaf is chk-lit,
using existing scalar/number/String evidence and preserving all runtime and
source-encoding assumptions.
