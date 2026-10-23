# Public prune removal and demand contract

## Frozen definitions and manual obligations

Base 8c1a3c2fb3c7758b12dcc5bcbbb85a2d668beeed. This batch reviews prune
using the existing public inventory/manual map. It is a coherent bounded
transformation and demand subset, not acceptance of all object semantics.

Official Jsonnet remains bbb38f1020be1f5aed560928fb839b2c448cefb4. The
[public declaration](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#std-prune)
(stdlib.html 186-206) defines empty members as null, zero-length arrays or
zero-length objects, and admits any argument type. Its fixed
[definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1623-L1641)
recursively prunes each candidate before isContent decides membership. The
array comprehension retains surviving input order; the object comprehension
uses objectFields and constructs ordinary visible result fields. The
[language values contract](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md)
(language.md line 93) requires original values to remain immutable.

Independent required outcomes:

- Nested containers that become empty after recursive pruning are removed from
  their parents. False, numeric zero and empty Strings remain content.
- Root null/Array/Object keep their root kind; there is no absent-root value.
  Scalar roots return unchanged. A root Function also returns its uncalled
  closure: the noncontainer branch does not invoke its body or defaults.
- Only final visible object fields are candidates. Hidden errors and hidden
  members of nested objects do not become content; the inherited visibility
  decision is reused from the existing object evidence.
- Deciding all surviving keys or array length requires their recursive
  membership checks. An isolated error inside a visible candidate cannot be
  suppressed merely by reflecting the pruned result. This differs from
  reflecting an already constructed unpruned container.
- An unused whole call remains lazy. Required errors propagate; one required
  failure is used per error probe so no member/callback/error race order is
  prescribed. Static free operands remain invalid despite unused calls.

| Group | Independent assertions |
| --- | --- |
| PR1 | Cascading nested null/empty removals, false/zero/empty-String preservation, scalar/root-empty behavior, named/positional a and surviving array order. |
| PR2 | Original object/array values and aliases remain unchanged before/after explicitly gated cold/warm result reads. A repeated prune observes the same data. |
| PR3 | Final inherited hidden/forced-visible selection, hidden error exclusion and nested hidden-only emptiness. Visible output values are not hidden again. |
| PR4 | Isolated required root/nested/array/overflow errors versus unused whole calls, uncalled root Function bodies/defaults, missing/unknown binding refusal before native gates and Static unused free operands. |

All source and independent typed AST expressions are assembled separately;
literal JSON outcomes are written independently, without product or Go/C++
output supplying expected values. Error tags/counters are embedding checks.
The old [object_std_test.mbt](../../object_std_test.mbt) source assertions for
nested cleanup and scalar roots are reused in their stated scope; historical
comparison evidence is not a current run or a normative oracle.

The ordinary non-Function JSON data domain and a root Function head are
decidable here. Nested Function content comparisons, all assertion/inheritance
interactions and local std/root rebinding are excluded. In particular this
batch does not settle PE0, N0/R0 or force an object assertion policy from the
prune implementation. It also excludes exhaustive numeric/encoding/resource
and exact error-format behavior. HP0, the two language print conflicts and
shift exclusions remain unchanged.

Freeze this manual plan and test bytes before the first native-debug directed
run. A real product discrepancy must be retained as a failed regression before
a minimal fix; otherwise keep product and old tests unchanged. Use existing
schema v2/generators/checkers, one nice-10 worker, frozen -j 1 and no parallel
tests, full suite, remote comparison, installation, push or private proposals.

<!-- Criteria above are frozen before execution; append results below. -->

## Results and reused evidence

The first directed native debug run passed all four groups, exit 0. There was
no fixture/compiler failure or observed product discrepancy. Product files,
old tests, public interfaces, harness and generators remain unchanged. The
frozen test SHA-256 is
`fd53ba8c1e516ffd1964d935c5dffd7fd3b738e350bed5d49011cdcdb544473f`;
the test and criteria prefix retain their first-run bytes.

PR1's literal results retain false/zero/empty Strings in their original array
positions while removing recursively empty structures, including parents that
only become empty after pruning their children. Root null and empty containers
remain roots. PR2's explicit conditional gates require input/result reads in
both directions, then compare original, alias, result and repeated prune data.
This observes immutability without inventing a callback traversal order.

PR3 checks a visible field overridden as hidden and a hidden field overridden
as forced-visible, plus hidden-only roots and nested hidden-only objects. Hidden
errors stay unforced; the surviving false/zero values remain visible. PR4's
source and handmade AST cases preserve the one isolated required error through
root demand, array membership, nested visible membership and numeric production
before type inspection. Shared unused-call controls return 42. A root Function
head stays Function without calling its erroneous default/body. This is a head
observation, not proof of every Function application or nested Function case.

The existing object_std_test source cleanup/scalar-root assertions are mapped
without treating the rest of that mixed test as prune evidence. Their bytes
remain unchanged; they were not rerun or added to the 4/4 result. The embedded
prune definition was compared with the fixed official body after removing only
the MoonBit multiline-String prefix. It matches byte-for-byte; the raw audit
pins that body and all original source hashes. No Go output supplies an oracle.

The directed command used nice 10 and
`moon test spec_prune_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize`.
Root check, info, formatting and both existing generators exited 0. No semantic
test was repeated just to refresh metadata. Documentation and final staged/
committed byte receipts accompany the raw run. The historical 539/539 full
result remains bound only to 5651ae9, not these new tests.

## Inventory and remaining limits

The public manual record equals the pre-execution frozen map. All 48 earlier
records remain unchanged: there are now 49 manual records and 46 functions
with reviewed dimensions among 153 candidates. Only prune's reviewed subset
and candidate-reference snapshot changed. Every whole-function status remains
unaccepted, and behavioral_conformance_proven stays false. PR1-PR4 are report
groups, not new canonical language IDs. Source snapshot metadata describes
the base/pending test path at generation time, not the final Git clean state.

The language manual mapping and both generated matrix files remain
byte-identical: 94 rows, 28 completed named transfers, one constructor transfer
complete relative to its children, 63 partial, two unreviewed and 195 canonical
evidence IDs. Existing schema v2, checkers and generators were sufficient;
there is no new metadata framework or upgrade of child judgments.

Nested Functions and PE0, object assertions/N0/R0, exhaustive inheritance/local
std/root rebinding, numeric/encoding/resource policies, exact diagnostics and
every signature combination remain outside this subset. The probes prescribe
neither recursive callback counts nor competing-error order. HP0, all prior
language print/desugaring unknowns and shift exclusions are unchanged. No
Go/C++ comparison, remote execution, new dependency, full suite or push ran.

Baseline/oracle identity, frozen test/criteria/manual map, first-run receipt,
scope audit, generated snapshots and final documentation/stage/commit receipts
are retained in `/tmp/moonjsonnet-prune.uxr_2q9r`.
