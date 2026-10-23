# Public mergePatch data and demand contract

## Frozen scope and independent criteria

Base 5d95a8539bb43637356edb3cee87bde64fa0e0ca. This batch reviews mergePatch
for configuration overlays, using the existing public inventory and manual
N/E/L/B mapping. It is a bounded public-function subset, not a completion of
all object rules or all standard-library behavior.

Fixed official Jsonnet bbb38f1020be1f5aed560928fb839b2c448cefb4 declares
[mergePatch(target, patch)](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#std-mergePatch)
(stdlib.html 3710-3730), explicitly referring to
[RFC 7396 section 2](https://www.rfc-editor.org/rfc/rfc7396.html#section-2).
The RFC operates on JSON data: null-valued patch members remove names, absent
removal names stay absent, object patches recursively update an object target
or an empty substitute, and a nonobject patch replaces the entire target.
Arrays are replaced as a unit. Unaffected members retain their data. It does
not promise JSON text layout/member ordering, duplicate-key handling, or a
Jsonnet error-expression execution order. Its pseudocode's target assignment
describes the result; it does not authorize mutation of Jsonnet values.

The fixed [public definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1531-L1554)
supplies the language-specific demand criteria, separately from the RFC:

- A nonobject patch branch returns patch without reading target. An object
  patch needs the target's outer kind, not unrelated target payloads.
- objectFields supplies visible keys. Computing null_fields reads every visible
  patch value's head to distinguish null; Array/Object payloads are not thereby
  traversed. An isolated failed patch head must propagate even when another
  result field alone would otherwise suffice.
- A deleted target value is not read; retained values remain field thunks.
  Recursive calls occur only when their result field is demanded.
- The two recursive calls explicitly use tailstrict. For a present target
  member, demanding a recursive scalar replacement therefore also demands the
  old target value's head. This differs from top-level nonobject replacement;
  a pure JSON RFC example cannot decide this error-expression boundary.

Existing evidence is reused in its original scope, without another run merely
to change a report: [sets_test.mbt](../../sets_test.mbt) has recursive deletion,
array replacement, nonobject-target normalization, visible/hidden projection,
unused target, deleted/retained payload and required-patch-error examples.
Those source assertions receive explicit manual mappings here; their old
Go/C++ comparison report does not supply normative expectations or current
execution results. The new tests supply independent typed AST counterparts
and the missing demand/alias boundaries.

| Group | Independent assertion obligations |
| --- | --- |
| MP1 | Literal JSON outcomes for removal/addition, retained null, nested normalization, whole-array and scalar replacement; named and positional interface calls. |
| MP2 | Shared target and patch data survive merge-first and warm-input-first reads; explicit conditional gates require each read, without assuming a callback traversal order. |
| MP3 | Replacement skips an unused target, object normalization skips nonobject payloads, deletion/retention and visible projection do not force unrelated values; patch container heads and result key inspection do not traverse their payloads. |
| MP4 | Isolated required patch/target/selected payload failures propagate, including the explicit recursive tailstrict boundary; undefined unused operands remain Static. Missing/unknown argument bindings reject before native argument gates. |

All new source expressions and typed AST trees are built separately, without
exporting a parser AST. Expected results are literal JSON values, not product
mergePatch output or another implementation's output. Runtime/Static tags and
binding counters are this embedding's checks, not an RFC diagnostic format.
No failure race with multiple error operands receives a required order.

This batch does not accept Function values as an RFC JSON domain, infer an
unused invalid value-type policy, or prove every self/super/assertion/hidden
inheritance combination. It does not decide JSON duplicate-key, malformed
Unicode, floating-point conversion, resource or error-format policies. The
language matrix, its two unreviewed print conflicts, shift exclusions and all
previous unresolved boundaries stay unchanged.

Freeze these criteria and the test bytes before the first directed run. A real
product mismatch must remain in a failed receipt before a minimal correction;
otherwise no product change is authorized just to improve the matrix. Use one
low-priority native-debug worker, existing generators/checkers, no full suite,
new dependency, remote execution, push or private application materials.

<!-- Criteria above are frozen before execution; append results below. -->

## Results and reused evidence

The first directed native debug run passed all four groups, exit 0. There was
no compiler/fixture failure or product mismatch; no interpreter, existing test,
generated public interface, harness or generator changed. The frozen test
SHA-256 is
`52953d3c31c78e8451c8fbce03c8be345bccecb770b24a7d7e9340ae948ccb90`.
The new test bytes and criteria prefix remain identical after the run.

MP1 checks literal object data and legal scalar/array roots through source and
independent typed AST entry points. MP2 requires reads using explicit language
conditionals in both merge-first and warmed-input-first cases, then observes
the original target, patch, alias and a second merge. This is consistent with
the fixed [language reference's immutable-value rule](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md)
(language.md line 93),
and does not treat the RFC's algorithmic assignment as an embedding mutation.
MP3 checks deleted/unselected target values, discarded nonobject payloads,
patch container payloads, key-only inspection and visible-key projection.
MP4 checks each isolated required failure, static admission and binding refusal.
In particular, both source and AST skip an error target for a top-level null
replacement, but reading a recursively replaced existing member propagates its
old head error under the explicit source tailstrict call. Merely inspecting
that result's keys does not force the recursive field call.

The three preexisting sets_test test blocks remain unchanged. Their reviewed
mergePatch assertions are mapped as source evidence for recursive deletion and
replacement, nonobject targets, hidden projection, unused/deleted/retained
values and required patch errors. They were not rerun or counted as new passes.
The current embedded mergePatch definition was extracted by removing only its
MoonBit multiline-String prefix and compared byte-for-byte with the fixed
official definition. It matches; its body SHA-256 and all original source/test
hashes are retained in the raw scope audit. This confirms the inspected source
identity, rather than inferring a contract from Go execution.

The run used nice 10 and
`moon test spec_merge_patch_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize`.
Root check, info, formatting and the two existing inventory generators exited
0. No semantic test was rerun merely to regenerate metadata. Documentation
checks and final staged/committed byte receipts are retained with the run.
This 4/4 directed result does not extend the historical full 539/539 run beyond
its original 5651ae9 source identity.

## Inventory outcome and remaining scope

The new public manual record equals the contract map frozen before the first
semantic run. All 44 previous records are preserved; there are now 45 records
and 42 functions with at least one reviewed dimension among 153 candidates.
Only mergePatch's reviewed subset/reference-candidate snapshot changed. Every
whole-function status remains unaccepted, and behavioral_conformance_proven
remains false. MP1-MP4 name this report's groups and add no canonical language
test IDs. Source snapshot metadata records the base and pending test path at
generation time, not a claim that the final worktree is dirty.

Both generated language matrix files and their manual mapping are byte-for-byte
unchanged: 94 rows, 28 completed named transfers, one constructor transfer
complete relative to children, 63 partial, two unreviewed and 195 canonical
evidence IDs. The two greater-than print conflicts, bounded-shift exclusions
and other previously unresolved matters are preserved. Existing schema v2 and
inventory/checker behavior were sufficient; no new evidence framework was
introduced.

This is a coherent JSON transformation and explicit demand subset, not a
proof over every JSON size or Jsonnet extension. Function inputs, exhaustive
signature combinations, duplicate-key/encoding/number policies, exact errors,
resource limits and all inheritance/assertion interactions remain unproved.
The error tests choose one required failure at a time and impose no member
iteration or competing-error order. No Go/C++ comparison, remote test,
installation, full suite or push ran. The only additional public source read
was the official RFC explicitly cited by the fixed documentation.

Raw baseline/oracle provenance, pre-run manual map, frozen criteria/test, first
run, scope audit, generated snapshots, checks and final commit receipts are in
`/tmp/moonjsonnet-merge-patch.4h_exj8k`.
