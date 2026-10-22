# Object visibility and lookup contract review

Normative inputs are the checked, fixed Google Jsonnet sources at commit
bbb38f1020be1f5aed560928fb839b2c448cefb4:
[public documentation](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html),
[source definitions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1555),
and [specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html).
Their cached SHA-256 values match the earlier inventory's pinned inputs. This
review records expectations before the new tests are executed. Existing tests
are reference candidates, not automatically adjudicated contract coverage.

## Six-function scope and expectations

| Function | Signature/defaults | Normal and error criterion | Forcing and visibility criterion |
| --- | --- | --- | --- |
| objectHas | (o,f), both required | Object and string required; missing name is false, an existing null value is present | Excludes hidden fields; inherited fields count; no field value or assertion is evaluated |
| objectHasAll | (o,f), both required | Same object/string and missing/present distinction | Includes hidden inherited fields; still structural rather than a field access |
| objectFields | (o), required | Returns names in sorted Unicode codepoint order; nonobject fails | Excludes hidden fields; inherited/overridden names appear once; values and assertions stay lazy |
| objectFieldsAll | (o), required | Same ordering/type contract | Includes hidden fields after visibility inheritance, without evaluating their values or assertions |
| get | (o,f,default=null,inc_hidden=true) | Object/string/Boolean membership inputs required; optional default accepts any Jsonnet value | Uses objectHasEx, then indexes only a present included field; default is used only for missing/excluded fields; present null does not select default |
| objectValues | (o), required | Values align with the sorted visible names; nonobject fails | Source array comprehension defers field indexing; construction/length does not check object assertions; selected elements index the original object and share its cached field values |

The formal object-has-ex/object-fields-ex rules inspect names/visibility, with
no premise evaluating field bodies or assertions. The latter rule explicitly
orders names. The language's string order is lexicographic by Unicode codepoint.
Under hidden-status inheritance, a right-hand ':' preserves the inherited
visibility, '::' hides and ':::' forces visibility. Tests use all nine visibility
combinations with independent explicit expected results.

The object-index rule checks the object's assertions before yielding a selected
field. Inherited self/super retain their existing language meaning. Thus get on
a present included field, or a demanded objectValues element, checks inherited
assertions; get on a missing/excluded field does not index the object. An empty
objectValues result has no element access that could check its source assertions.
This is separate from manifesting an object as top-level JSON. The existing
std.manifestJson({assert false}) path is not treated as a defect or changed.

Invalid public argument binding must reject demanded calls without evaluating
rejected argument expressions. Optional get arguments are tested by omission,
position and name. Native counters distinguish structural reflection from
assertion, field and default execution, and verify selected-thunk caching and
demand order. Synthetic null/omitted keys, empty/hidden-only objects, prefix keys,
supplementary Unicode and inherited overrides supply finite boundary coverage.

## Limits of this adjudication

Exact diagnostic text and relative error order when multiple necessary inputs
fail are not specified by these contracts. Runtime failure is normative; the
tests additionally check the library's existing Type/Runtime/Assertion categories
where the failing operation is unambiguous. No arbitrary first-error ordering
is inferred from the layout of formal premises or from Go/C++ execution.

This is a reviewed subset, not acceptance of every object, equality,
inheritance, assertion, resource or public-function contract. The eleven older
cardinality/filter observations and earlier signature/default conflicts remain
unresolved; they are neither rerun nor relabeled by this batch. Every new input
is synthetic and contains no business data or private application content.

The [execution evidence](SPEC-OBJECT-CONTRACTS-EVIDENCE-2026-10-22.md) records
actual baseline, aggregate and CLI results independently of the expectations.
