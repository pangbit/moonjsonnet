# Object-comprehension dynamic keys: bounded execution evidence

**Decision: the predefined dynamic-collision, mixed-null and delayed-value
capture group is reviewed complete.** Source and independently handmade ASTs
reject a collision during construction, filter repeated null names and retain
the correct iteration environment for values forced later. This is the
[pre-execution contract](SPEC-OBJECT-COMP-KEYS-REVIEW.md), not completion of
object-comp or every comprehension/desugaring/substitution obligation.

## Fixed normative basis and reused controls

The [official specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html)
at bbb38f1020be1f5aed560928fb839b2c448cefb4 evaluates object-comprehension
names, requires distinct non-null names and stores only non-null body
expressions without evaluating their values (2183-2200). Its comprehension
desugaring introduces fresh iterator tuples and binds generator names in both
key and body expressions (1168-1189). The explicit outputs and error sites
follow those clauses relative to the existing generator/local/array children.
No Go/C++ behavior supplies an oracle.

The [earlier comprehension review](SPEC-LANGUAGE-FORMS-EVIDENCE-2026-10-22.md)
already records C1 sequential/nested scope; C2/A3 empty/all-null suppression;
C3 structural key demand and selected-body caching; C4/A4 simple duplicate
failure; C7 key/body error phases. Those exact meanings are reused, not
rerun or added to this batch. Existing A3 is now explicitly reused in the
lazy dimensions for object-comp and DESUGAR-COMPREHENSIONS. Source/exported-AST
controls are not relabeled independent handmade inputs.

The new difference is a collision across distinct dependent-generator tuples,
and mixed omitted/retained names whose field bodies retain their own tuple
after construction. Ordinary constant duplicates and all-null objects are
not repeated as new groups.

## Actual source and handmade-AST outcomes

The [new test file](../../spec_object_comp_keys_test.mbt) constructs separate
source strings and typed trees. It reuses only the neutral forms_ast builder
and its stable virtual forms-ast identity; it never exports a parser tree.
The source computes names; the native key observer returns that supplied name.
The body observer returns literal true. Expected pairs, names and markers
were fixed before execution.

Outer x=99/y=88 are shadowed by x in [1,2], then y in [0,x]. The four tuples
are (1,0), (1,1), (2,0), (2,2), so the second generator must see the earlier
generator's x rather than the enclosing x.

| Required clause | Actual result through both entry paths |
| --- | --- |
| CK1: duplicate construction remains lazy while unused | An unused o.first binding returns 42 with zero key/body observations; Program creation succeeds |
| CK1: computed conflicts are detected before structural demand succeeds | Distinct (1,1)/(2,2) tuples both compute first. std.type(o) rejects Runtime, with zero body entries |
| CK1: reading an existing early field cannot bypass a later conflict | Direct o.first also rejects during construction with both colliding tuple/name observations and no value evaluation |
| CK2: null names can repeat and disappear | (1,0)/(2,0) both return null; the successful object has type object and length 2, with first/second as its retained names |
| CK2: shape inspection does not force retained or omitted bodies | Metadata gives [object,2] and zero body entries, although both null bodies and the second retained body contain explicit errors |
| CK2: per-iteration environment is retained | o.first yields [1,1] and only its (1,1) body tuple is observed; it cannot borrow the later tuple or enclosing 99/88 |
| CK2: retained errors wait for actual selection | o.second records only (2,2), then rejects Runtime with retained-body-marker |
| CK2: all successful names precede selected value work | A sticky observer confirms that all four tuple/name entries were present whenever a body entered |

Membership/name maps collapse repetitions and impose no key-callback order or
universal call-count policy. In the failing construction, only the colliding
tuples are required; unrelated keys after the conflict need not be observed.
There is one collision class and no failing key expression. Zero body entries
distinguish the duplicate failure from the deliberately erroneous values.

The Runtime category, virtual entry identity and literal retained-body marker
are embedding phase controls, not standardized diagnostic wording. Both source
and AST are statically valid before evaluation; no malformed-source Syntax
counterpart or full static judgment is claimed. All evaluations use steps=5000,
depth=48 and stack=64 over finite domains.

## Dataflow supporting this bounded decision

eval.mbt traverses the clauses before returning an object. Each emitted key
is evaluated in its iteration scope: Nil stores no field, Str checks the
accumulated name map before insertion, and other kinds take the existing Type
branch. No value is evaluated to insert a name. Duplicate rejection therefore
occurs before an object can be handed to std.type or field lookup.

Each For iteration creates a child environment and recursively processes
later clauses there. A later domain sees the earlier iterator binding, and
each stored LayerField retains that iteration scope. The field value wraps
object locals/body in a Local expression without forcing it. On eventual
lookup, objects.mbt evaluates that stored field using its captured environment;
the final loop variables or outer same-name locals do not replace it.

AST conversion preserves the key, body and ordered clauses. Validation visits
domains sequentially and puts earlier loop variables in the key/body scope.
These source paths, the four explicit name observations and the selected
body tuples support the result beyond merely counting tests. No product
defect was observed and no implementation fix was required.

## Completion boundary and still-unreviewed scope

The selected contract is closed; the full core object-comp constructor has
not received a general relative-to-children completion decision. Other
invalid-key producers are credited only where prior C4 controls apply.
General filter/nesting lowering and mechanical non-array domain extensions
retain their previous unadjudicated scopes. This group does not add self,
super, root, object-local, host resource or arbitrary grammar acceptance.

The rule does not standardize which of several independently erroneous keys
fails first. Such an arbitrary ordering is removed from the old blanket
remaining-obligations text; no new ordering test is requested as an acceptance
endpoint. Existing empty, filter, type and cached-value controls remain
available for a later constructor review without being claimed as fresh runs.

The [assertion adjudication](SPEC-OBJECT-ASSERTION-ADJUDICATION-2026-10-22.md)
is unchanged: N0/R0 remain unknown and its relative DESUGAR-ASSERT record is
preserved. These new paths have no assertions or self/super references, so
they neither depend on nor resolve those questions.

## Execution identity and final checks

Base source: 7f2d5bf242be394a897787d2196db0d769d8ab0b, tree
0197b946be9b7d0ff1a2985913a03e7d57ad02cb, plus the new test identified below.
The pre-run record pins criteria, new test, implementation and reused
C-series/helper bytes. Their hashes remained unchanged after execution and
matrix/format work. Existing local Darwin arm64 tools: moon/moonrun
0.1.20260920 (914d7da), moonc v0.10.14+7d59c7ec9.

One directed native debug invocation passed **2/2, exit 0**, on its first run:

    nice -n 10 env RUST_LOG=error moon test spec_object_comp_keys_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize

Only the two new groups executed; their internal source/AST variants do not
turn test count into conformance. No old C/A groups or aggregate/platform
outcomes are added, and no semantic rerun followed mapping/documentation edits.
Subsequent frozen checks were sequential and used reduced priority and one
worker where supported. Installed info/fmt expose no worker-count option.

| Final check | Result |
| --- | --- |
| Native root check | Exit 0 with --frozen --deny-warn -j 1 |
| Info then fmt; script fmt --check | All exited 0; no .mbti changes |
| Matrix validation/regeneration | Exit 0 on first invocation; anchors, source hashes and existing constructor record validated |
| Tracked/staged-only documentation checker | Exit 0: 160 files and 1173 local/current-source links; root layout, language candidates, README parity and migration targets passed |
| Whitespace and exact scope | Both staged/worktree diff checks passed; exactly the seven intended test, criteria, evidence and matrix files |

Only object-comp, DESUGAR-COMPREHENSIONS and SUBSTITUTION receive bounded
mappings. Every completion state in the [matrix](SPEC-LANGUAGE-MATRIX.md)
remains unchanged: **8 completed named rules, 1 constructor transfer relative
to children, 41 partial rows and 44 unreviewed rows**, across 94 inventory rows
(70 named rules and 24 initial prose/grammar obligations). Whole-language
acceptance and inferred execution remain false. Product code, dependencies
and public interfaces are unchanged; no public-library completion is added.
[Go/C++ comparison](SPEC-LANGUAGE-COMPARISON-2026-10-22.md) stays separate and
unknown for these new probes.

| Artifact / source | SHA-256 |
| --- | --- |
| Pre-execution criteria | 589d3fc8522885a76363f8d1d66068d59c42684d8027c7f2a2795c1e1b22d09a |
| Executed new test | cce9e374299a7688c84fd62133d52d5047a59985d92e4f8260c2a8648dfe27de |
| Passing 2/2 summary log | ddd0722f90fd133207ca9e423fc1faa05c3608f3be5c5eb4fdbea4259682b120 |
| eval.mbt | f75c9e3fd45506a140711eaf21c09625dfa9879798ccc1ac40adc1f2983f55c3 |
| objects.mbt | 06fe3700af7171f9b67a9641a35c92d541849409bcd009e34428ee0456079436 |

Raw records: /tmp/moonjsonnet-object-comp-keys.tc299du0, including before-run.json,
criteria-before.md, test-before.mbt, focused-result.json, checks.json,
toolchain.json and individual logs. Temporary records are not an archival
guarantee; committed tests/criteria and the
[machine-readable matrix](spec-language-matrix.json) retain actual scope and
oracles. Summary counts/hashes alone do not identify executed source.

Standard/default and one worker were retained. All fixtures are synthetic
virtual callbacks with no imported-file, private-document or network I/O.
No full suite, remote/platform/CLI run, installation, push or tag occurred.
