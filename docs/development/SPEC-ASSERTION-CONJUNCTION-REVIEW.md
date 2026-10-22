# Assertion conjunction and finite reentry: pre-execution criteria

Base source: 0719f40d160f46208153e9d234a2a45dfe3749d0. Fixed official Jsonnet:
bbb38f1020be1f5aed560928fb839b2c448cefb4. Cached spec.html SHA-256:
bbac3701ef0316fc29de6c543049ae8f0f78c876bdd94fbf6ab845b2023a720a;
language.md SHA-256:
c55666af13894c8100c84fb053e647cd0ca516f3bb554d0ced29dfa83c3772be.
Inputs and expected outcomes below precede new execution. Neither actual
interpreter output nor Go/C++ behavior supplies the oracle.

## Normatively decidable U2 scope

The [fixed specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html)
object-inherit rule (2293-2333) retains both operands' assertion lists;
object-index (2215-2228) requires every assertion before yielding a field.
Its values discussion (1793-1796) treats reordering object assertions as
immaterial. These clauses require conjunction and retention, not a particular
iteration order, first failing assertion, callback order or successful-check
count. A field override must not erase assertions in either operand.

The first fixture has two assertions per operand and no self/super reference
in any predicate. It independently decides the retention clause without
depending on reentry. Each position is made uniquely false in turn. A final
case has two false positions and accepts either failure, without requiring
callbacks for assertions that an earlier failure can prevent from executing.

The second fixture adds the requested finite self-field dependency, relative
to the already reviewed self/rebinding contract. The dependency graph has
three numeric fields and no field/function recursion. The printed object-index
rule does not explicitly model an in-progress checking state. Therefore this
part is bounded operational acceptance under that existing child contract,
not a claimed new finite derivation from the state-free equation or an invented
normative guard/cache policy. Record this formal scope limit separately.
N0's assertion-super rewrite stays unresolved; no new fixture uses super.

## Independent source and handmade-AST expectations

Observers only record assertion IDs (and a numeric receiver context) in maps,
so repeated observations collapse and order is never compared. A message
observer returns the given ID string; a payload observer returns its numeric
input. The actual predicates remain Jsonnet expressions. New trees are
handmade using unchanged neutral AST/program helpers, not parser-exported.

| Probe | Required outcome |
| --- | --- |
| AC1: all four retained predicates are true | Left assertions L0/L1 and right assertions R0/R1 all appear in the observed ID set; selected value is 42. Right value overrides an error-valued left value; no message runs |
| AC1: unique false positions | Separate L0, L1, R0 and R1 cases each raise Assertion bearing their sole false ID. No selected payload runs, regardless of which true checks happened first |
| AC1: two independent false predicates | With L0 and R1 false, accept either ID as the Assertion message. Do not require a particular first error or that every condition callback ran |
| AC1: construction/unused access is lazy | In that two-failure case an explicit type guard constructs the merged object. Metadata/unused-field modes yield object/42 and no condition, message or payload observer runs |
| AC2: finite field graph | Left has seed=1, goal=3, next=self.seed+1, done=self.next+1. L0 checks done==goal and L1 checks next+1==goal. Right overrides seed=10/goal=12, with R0 checking seed+2==goal and R1 checking done-seed==2 |
| AC2: checked original does not authorize a merged object | Actually demand left.value==3 before merged.value. Final result is 12; ID/context set includes L0/L1 at goal=3 and all four IDs at goal=12. No check order is asserted |
| AC2: reentry must not lose remaining predicates | Each self read occurs while the merged object's assertions are in progress. Every retained ID must still be observed in the successful run. All messages are explicit errors and stay unforced |

Source and AST must separately satisfy these literal expectations. Use
Limits with steps=5000, depth=48 and stack=64 on every evaluation. An incorrect
recursive checker then fails promptly instead of consuming unbounded work;
the expected successful inputs themselves contain only a length-three acyclic
field graph. Limit failures are not accepted as successful reentry behavior.

## Review, reuse and stopping point

Reuse AS receiver/check-state evidence, U1 binding/capture evidence and the
existing SP/AX distinctions without rerunning them. Inspect full layer/pair
retention, fresh receiver state, the in-progress return path, traversal after
reentrant field reads and the completed-state assignment after all pairs.
Scope acceptance to U2 conjunction plus the bounded operational reentry path.
Do not turn successful callbacks into a proof of the paper's missing state
premise or N0's missing super transformation.

The report must close or reject U2 explicitly, leave U1's prior decision
separate, and identify the remaining normative adjudication and exact matrix
positions that can close relative to children. Finish the existing constructor
review using reusable AR0/IF4 and inspected expression/object paths; do not
invent another unbounded list of behavioral microgroups. Whole object-index,
inheritance, equality, stdlib and host contracts remain separately scoped.

One local worker with reduced priority and existing frozen dependencies only.
No full suite, remote/platform run, installation, push, tag, imported-file,
private-document or network I/O is included.
