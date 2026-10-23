# Ordinary object construction: three frozen risk groups

Execution status: all three fixed groups completed through source and handmade
AST entry paths; the native debug baseline passed 3/3. No implementation defect
or product change was needed. The batch is closed at its three-group stopping
point. Original preparation criteria follow, with measured results appended.

Base: `7a775f9cd5c28f63ba6311a7fcf3d231238272f6`. This is static preparation
only. Exactly three groups are proposed for ordinary objects; no build, test,
formatter, implementation edit, matrix change or acceptance claim occurs here.

## Independent basis and preserved limits

The fixed official source is Google Jsonnet
`bbb38f1020be1f5aed560928fb839b2c448cefb4` (v0.21.0). The retained spec.html
SHA-256 is `bbac3701ef0316fc29de6c543049ae8f0f78c876bdd94fbf6ab845b2023a720a`;
language.md is `c55666af13894c8100c84fb053e647cd0ca516f3bb554d0ced29dfa83c3772be`.

The [fixed specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html)
separates stuck execution from static rejection at 1764-1766. Its Values text
at 1786-1796 leaves field values deferred and rules out object values with
duplicate names. The object rule at 2163-2175 retains only String-key fields,
omits Null-key fields and requires distinct retained names. object-inherit at
2293-2333 requires both operands to produce objects before combining layers.
The [fixed language guide](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md)
at 579-591 explicitly evaluates all field-name expressions when creating an
object; at 337-372 it describes combining object layers.

The printed object rule uses e_i in its key premises but e-prime_i in the
conclusion. This batch identifies their key role using the explicit field-name
prose and distinct-name/Null-omission structure; it does not silently repair
that notation or declare literal completion of the entire formal rule. DF0's
ordinary field-value desugaring discrepancy also stays unresolved. Expected
positive results inspect only type, key set and cardinality, never the value
chosen for a field. Canonical field-value preservation/lowering is not accepted
by these observations.

No probe contains an object assertion, self/super reference, additive field,
object comprehension or serialization call. N0/R0 and all existing manifestation
versus std.manifestJson distinctions remain outside this batch.

## Deduplication and exact new boundaries

OH1/EX2 already cover a single ordinary Null key with unread payloads; do not
copy their general reflection grid. R2 and A4 already distinguish literal
duplicate names rejected at creation from dynamic comprehension collisions.
CK1/CK2 cover comprehension collisions and mixed Null/generated fields. AD4
covers Null omission for additive fields. Those existing groups keep their
historical execution identities and are not rerun or counted here.

The new spec_object_construction_test.mbt contains only these three groups:

| ID | Fixed input boundary | Independent expected outcome |
| --- | --- | --- |
| OC1 | Two ordinary keys both refer to the same outer Null binding; a retained kept field and all omitted/stored bodies contain wrong-type arithmetic. Then independently place a free name in an unselected branch of a conditional key. | Metadata is exactly ["object",["kept"],1], with no body demand. The sole invalid key expression rejects Static during creation, directly and in unused/unselected wrappers; selecting Null at runtime does not excuse an unchecked key branch. |
| OC2 | One early field precedes two ordinary keys that both read the outer String binding 'same'. Observe type, complete key set, and early field selection in separate cases. | Each entry creates successfully; a wholly unused observer returns 42. Actual observation fails Runtime during duplicate-key construction, including before the early field can be selected. Its payload would instead fail Type, so that category cannot satisfy the collision oracle. |
| OC3 | Add a valid right object with same/early fields to a left ordinary object that has either the OC2 collision or a Number key with an explicit Runtime-error body. Control: combine two valid same-name layers whose values are both unused wrong-type expressions. | Unused whole additions return 42. Demanded type observation fails Runtime for the collision and Type for the Number key; right-side replacement does not remove left construction. Valid layers yield metadata ["object",["same"],1] without evaluating either field body. No selected field value is asserted. |

All source entries and typed trees are built separately from literal fixture
data with neutral builders, without parser/export round trips. The interfaces
are Program::parse(expression.source, filename="ordering-entry") and
Program::from_ast(expression.tree), followed by bounded Program::evaluate.
The reused sequence_failure helper checks creation and an unused wrapper before
actual demand; sequence_value supplies literal positive JSON expectations.
pair_reject checks the static negative before any evaluation. All three helpers
exercise both interfaces. Limits are the existing sequence_limits() controls.

Null/duplicate/control payloads use 1 minus a String, a deferred Type error if
evaluated. The Number-key body instead has an explicit Runtime error, so a wrong
body demand cannot satisfy the expected Type category. This makes no claim about
priority between independent demanded errors: the stored body is not an
evaluation premise of construction. Runtime/Type/Static tags are
project API phase/category controls, not standardized human diagnostics. No
precise error text, competing-key order, native callback count or cache policy
is part of the oracle. A loop stops at its first failure; later subcases are
NOTRUN. Three is a planned group count, not a passing count.

The static negative is deliberately in the key, rather than the omitted value,
so it does not adjudicate DF0's field-value substitution problem.

## Static audit and deferred minimum run

eval.mbt's ordinary Obj arm evaluates each key, skips Nil, admits unique String
keys, rejects duplicate names Runtime and other key types Type, then stores
field expressions without evaluating them. validate.mbt checks keys in the
outer context. The Binary path evaluates both operand heads; operators.mbt
combines layers only after receiving two ObjectValue operands. These paths
agree with the proposed criteria; no definite implementation defect is found
by static inspection. Missing combination evidence is not a measured failure.

The parent owns the heavy slot. After allocation, verify the base HEAD, all
680 existing tracked hashes and symlink targets, the new test/criteria and fixed
reference hashes. Preserve original bytes before any later permitted formatting
and identify the actual execution copy separately. Then the minimum baseline is:

```sh
RUST_LOG=error moon check . --target native --frozen --deny-warn -j 1 </dev/null
RUST_LOG=error moon test spec_object_construction_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize </dev/null
```

Run serially with closed stdin, owned process groups and 600 seconds per command.
Retain stdout/stderr, actual exits/counts/durations, input hashes, first-failure
cutoffs and process-group exit proof. A compiler error is not a semantic failure.
All three groups with both entry paths and their fixed subcases are the stopping
point; no automatic extension or whole object/inheritance acceptance follows.
If a definite bug is measured, preserve the baseline and criteria before any
minimal own-source repair and propose only directly affected adjacent controls.

This preparation changes no implementation, mapping/count or old evidence.
No native execution, full suite, release, Go/C++, filesystem fixture, private
file/proposal read, network, remote/Linux/container, dependency update, snapshot
update, commit, push or release is included. Wait for the parent's next slot.

## Executed baseline and byte binding

After the parent allocated the heavy slot, the original freeze was verified
against HEAD `7a775f9cd5c28f63ba6311a7fcf3d231238272f6`, all 680 existing
tracked contents/symlink targets, both new files, both fixed references and
OC1-OC3's individual literal-input manifests. The index was empty and only the
prepared test/report were untracked.

Required interface/format preparation preceded the test baseline: native frozen
moon info exited 0 in 0.271 seconds and moon fmt exited 0 in 0.529 seconds.
No existing tracked file, public .mbti or new test byte changed. The token
comparison found no changes at all; a separate execution freeze preserves the
verified identity without replacing the original preparation freeze. Info has
no jobs option and used its auxiliary tool default. Both baseline commands
below explicitly used one worker.

| Frozen command | Actual result | Duration | Owned PID/group |
| --- | --- | --- | --- |
| native check, frozen, deny-warn, -j 1 | exit 0 | 0.451 seconds | 56168, exited |
| native debug spec_object_construction_test.mbt, same options plus no-parallelize | exit 0; 3 total, 3 passed, 0 failed | 5.492 seconds | 56188, exited |

Check ran at 17:24:12.762-17:24:13.230 UTC; the test ran at
17:24:17.395-17:24:22.907 UTC on 2026-10-23. Each used closed stdin,
RUST_LOG=error, a separate process group and a 600-second cap. Neither timed
out. Every frozen execution input hash remained unchanged after each command;
both owned process groups were absent. All three groups and every fixed loop
completed through both entry paths. No first-failure tail, compiler repair,
expectation migration, snapshot update, extra group or adjacent semantic run
was required.

Evidence directory: `/tmp/moonjsonnet-object-construction._xn4hj3w`.

| Retained artifact | SHA-256 |
| --- | --- |
| freeze.json, original preparation | `6dfc62c530a8cfd301377749966fc0da35efe8c95a9f6e24c3decf59fd72840e` |
| plan.json, original two-command plan | `6d7a40acead4ec97d301b93519e731073c5efff20625ba598c7e71e52d9e5335` |
| execution-freeze.json | `a0885aa8297002f8c9c793cd53233064bed3d20e0d477f732bd7a210ccd94f2a` |
| execution-plan.json | `5a06fdd9e7e9b3c19a21fa29f4e3526c1ee28db8b3e15c654a2dc699f59f54cb` |
| spec_object_construction_test.mbt, preparation/execution/delivery bytes | `acfb04859691b752e3cca576ccd72d6a11519b12d3be648dd829cbd8100e7807` |
| original/docs/development/SPEC-OBJECT-CONSTRUCTION-2026-10-23.md | `faf48385bf2d8bdb90dd8c7ba1e37603fb61f6d3533046f6fcaf7d4b7076cbf6` |
| inputs/OC1.json | `b9e8beeecb6a62ec13a3af722373cc2f392dc463773c38da08cda5ed6f269e8c` |
| inputs/OC2.json | `98eae1a54b60c3c2d67b938d3caf7e8e541e2aeaef1f8c0ce46fceca1519489c` |
| inputs/OC3.json | `4fc7b8dab207b05c526f4cac3dd818e18674e4184369e7c192d20e1bea20e797` |
| baseline/test.stdout | `97372d6d024ba8fb9a214e3a9a3495ca88a0631086280e8b2271682e11ea6fb0` |

The input JSON records are static manifests of literal bindings, keys, payloads
and expected observations, not runtime-loaded files. Exact executable inputs
are the test bytes plus all frozen helper/source hashes. baseline/*.run.json
retains argv, timestamps, elapsed time, exit/counts, input checks, raw hashes
and process-group absence. Check stdout and test stderr were empty. Check
stderr contained only its 44-byte up-to-date message; test stdout was exactly
the 38-byte `Total tests: 3, passed: 3, failed: 0.` line with a newline.

The toolchain receipt records Darwin mini.local 27.0.0 arm64, moon/moonrun
0.1.20260920 (914d7da), moonc v0.10.14+7d59c7ec9, with rr_moon_mod and
rr_moon_pkg enabled. No toolchain or dependency changed.

## Scope closeout

OC1-OC3 add bounded object-construction evidence. Only the object, chk-object
and object-inherit rows receive directly relevant mappings: OC1's key Static
control belongs to the adjacent checker; OC3's failures are operand-construction
preconditions, not intrinsic addition or later-field errors. All other rule
mappings, prose rows and the 213 prior evidence records are preserved. The
existing frozen matrix generator exited 0 in 4.355 seconds with -j 1 and
formally approved local cache access; metadata/matrix.* preserves its output.

The evidence inventory increases to 216 IDs. Acceptance counts remain 28
completed named reviews, 1 relative constructor review, 63 partial rows and
2 unreviewed rows across 70 named rules and 24 prose/grammar rows. These three
rows remain partial. No literal whole-formula, field-value selection, N0/R0/DF0,
assertion, serialization, host/platform or whole-language acceptance is added;
overall conformance remains incomplete.

No product repair, adjacent runtime run, additional group, full suite, release,
CLI/API process integration, Go/C++, Linux, ASan, network, remote or container
campaign was performed. Old full-suite/platform counts retain their original
source bindings. The delivery receipt records the exact local commit, executed
test hash, input/output hashes, clean worktree and final process checks. The
commit contains only this test/report and three mapping/matrix files; no push,
release or automatic follow-on group is part of the closeout.
