# objectRemoveKey source-defined projection review

## Frozen independent criteria

Base:068f063b720c6ebe5d165235f754d01bd9d589a7. Fixed official Jsonnet:
bbb38f1020be1f5aed560928fb839b2c448cefb4(v0.21.0). No interpreter output or
Go/C++ reference run supplies an expected result in this review.

The [public entry](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#L3324-L3345)
names obj,key and returns a new object after removing the supplied key. The
[standard-library introduction](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#L22-L32)
and [fixed source](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1788-L1792)
specify the remaining behavior:

```jsonnet
objectRemoveKey(obj, key):: {
  [k]: obj[k],
  for k in std.objectFields(obj)
  if k != key
},
```

The maintained embedded body byte-matches that definition. objectFields uses
objectFieldsEx(obj,false), so hidden fields are not projected. Each retained
field expression reads the original obj[k]; it does not transplant the input
field expression into a new self/super context. An empty visible field list
never evaluates the filter key. A nonempty list compares String k with key;
the existing disjoint-type equality contract gives false without coercion for
all other outer value kinds. There is no String-only key guard in this fixed
definition, and no public text adds one. This does not adjudicate PE0 same-type
nonprimitive equality or A0/B0/N0/R0/DF0.

The [language object model](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#L348-L372)
and [object indexing](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#L2215-L2225)
supply the existing final-receiver and demanded-field children. Assertion
controls below use only flat constant-false assertions: no inherited assertion
super, recursive self-indexing, competing errors or assertion-order promise.
The source object-comprehension rule is distinct from the disputed ordinary
computed-field DF0 formula. Existing bounded child reviews retain their scope;
this batch does not certify every child or whole-language rule.

Eight groups are frozen in [spec_object_remove_key_test.mbt](../../spec_object_remove_key_test.mbt).
Every group constructs source and independent public AST inputs using neutral
builders; all expected results/markers are literal. No parser export, local
behavior or reference implementation generates an oracle.

| ID | Independent expectation |
| --- | --- |
| ORK1 | Removing a from {a:1,b:self.a} leaves b=1, for positional and reordered obj/key names. |
| ORK2 | An inherited source with final a=2, super.a=1 and a self-reading closure retains [2,2,1,2,2,1,2,2,2] across original, projection and later a=99 overlay reads. Original aliases stay unchanged. |
| ORK3 | Projection omits hidden h and removed drop, exposes retained ordinary/forced-visible fields, and keeps original key metadata. Empty, composed/decomposed and astral String names are removed by exact identity. |
| ORK4 | Object type/visible keys/count leave removed, hidden and retained payload errors dormant; an unused whole call skips both arguments. A selected retained field propagates retained-value. |
| ORK5 | Empty and hidden-only inputs return {} without evaluating an error-valued key. A nonempty visible input demands the isolated key-required error before reading a field payload. |
| ORK6 | Null/Boolean/Number/Array/Object/Function keys do not match String a, so literal {a:1} remains and nested key payloads/bodies stay unread. No same-type nonscalar comparison is used. |
| ORK7 | Projection key metadata skips a flat false input assertion. Reading a retained field requires that original assertion and fails. Removing the only visible field returns {} without reading an original field. |
| ORK8 | Non-Object inputs reject Type; isolated input-head/computed-key errors propagate Runtime. Required/extra argument binding errors reject Runtime; an unused call still rejects statically free operands during admission. |

The existing native branch is separately inspected as an implementation risk:
it copies layers, retains hidden fields, discards assertion lists and eagerly
requires a String key. This inspection is not an executed failing result.
Legacy project tests encode some copied-layer behavior; preserve their original
run before any individually justified migration. Do not change Go/C++ fixtures.

Run only native check and this directed file first: frozen dependencies,
deny-warn, one worker, closed stdin, debug/no-parallelize for tests, each bounded
by300 seconds. Subsequent repair uses the same frozen semantic criteria and
necessary neighboring tests. No snapshot update, whole suite, release, standalone
CLI/API delivery, reference run, SSH, installation, private proposal or push.
No whole-function acceptance follows from these finite groups.

<!-- Frozen criteria above precede execution; results append below. -->

## Executed red and green evidence

The first check exited255 because Moon inferred the four Unicode expected-name
arrays as Array[String] instead of Json. Only an explicit Array[(String,Json)]
annotation and a local cases name were added. All four literal vectors and
every semantic expectation stayed unchanged. The initial file, typed file,
plan, typed plan, exact type-only patch and check output remain preserved.
This was a fixture compilation error, not a semantic failing test.

With all686 original input entries unchanged, the typed check passed. The first
unchanged-product directed run then reported **8 total,2 passed,6 failed,exit2**.
ORK4/ORK8 passed. ORK1/ORK2 raised an error instead of the required original-
context values; ORK3 retained hidden h; ORK5 demanded the first empty-input key
error; ORK6 rejected the first Null key; ORK7 suppressed the required original
flat assertion. The raw output is retained without editing.

The first source arm stopped each failing group. In particular, ORK1's later
handmade/named variants, ORK2's later reads/handmade path, ORK3's Unicode removal
loop, ORK5's hidden-only/required-nonempty branches, ORK6's later key kinds and
ORK7's later handmade/empty-result branches were NOTRUN in that baseline.
They are not counted as observed independent failures. They execute after repair.

Only one product line changed: objectRemoveKey was added to
source_standard_function in [stdlib_layer.mbt](../../stdlib_layer.mbt). The
existing standard-library dispatch therefore uses the already embedded exact
fixed source body rather than exposing the native layer-copy approximation.
No new algorithm, upstream edit, comparator change or global object rule was
introduced. The maintained source bytes and native implementation file stayed
unchanged. The public obj,key names and external interface are unchanged.

The original [legacy file](../../object_std_test.mbt) first passed3/3 against
the original implementation. After the one-line repair, the unchanged new and
legacy files reported11 total,9 passed,2 failed: all eight independent groups
passed, while two old groups stopped at assumptions inconsistent with the fixed
source. That first old-expectation failure run remains intact.

## Exact legacy migrations

Each original input remains exercised. Only the required expectation or its
explicit success/error assertion location changed; no Go/C++ fixture or bulk
snapshot update was made.

| ID | Original input and old expectation | Source-defined new expectation and basis |
| --- | --- | --- |
| M1 | std.objectRemoveKey({a:1,b:self.a},'a').b was in the generic expected-error loop. | Same input now explicitly equals1. The retained obj[k] indexes original self.a=1; source1788-1792. |
| M2 | local o={a:1,h::2}; local r=std.objectRemoveKey(o,'a'); [std.objectFieldsAll(r),r.h,o.a] expected [["h"],2,1]. | The unchanged original input now explicitly rejects Runtime for absent h. A separate metadata input replaces r.h with std.objectHasAll(r,'h') and expects [[],false,1]. objectFields uses visible-only Ex; source1558-1559 and1788-1792. |
| M3 | local o={a:1,b:self.a}; (std.objectRemoveKey(o,'a')+{a:4}).b expected4. | Same input equals1. The output overlay cannot rewrite the original obj captured by obj[k]; source1788-1792 plus existing object/closure semantics. |
| M4 | std.objectRemoveKey({assert false, a:1,b:2},'a') expected {"b":2}. | Same input explicitly rejects Assertion: manifesting retained b reads original obj[b], which requires its flat false assertion; source1788-1792 and object-index2215-2225. |

In the unchanged legacy failure run, the generic-error group stopped at M1 and
the projection group at M2. M3/M4 and the later lexical-object-local control
were not reached in that run. Their justified new assertions all pass after the
migration. The lexical-local success itself is unchanged.

## Final selected results and boundaries

The unchanged typed independent file and precisely migrated legacy file pass
**11/11,exit0**. Seven related files pass **29/29,exit0**: object reflection,
primitive disjoint equality, object-comprehension keys, object shape, inherited
function contexts, existing object-language cases and generic argument binding.
These are40 distinct selected cases, not the full suite. Required native info
then fmt passed; no .mbti changed and all validated product/oracle hashes stayed
unchanged. No further semantic test rerun was needed.

| Stage | Exit | Seconds |
| --- | --- | --- |
| baseline-check | 255 | 0.503 |
| baseline-typed-check | 0 | 0.323 |
| baseline-test | 2 | 6.014 |
| legacy-baseline | 0 | 0.319 |
| repair-check | 0 | 0.451 |
| repaired-new-and-original-legacy | 2 | 8.790 |
| repaired-directed | 0 | 6.404 |
| neighbors | 0 | 6.502 |
| final-info | 0 | 0.268 |
| final-format | 0 | 0.044 |

Evidence is under `/tmp/moonjsonnet-object-remove-key.4s4i7ee5`, including raw
stdout/stderr and each owned PID/group-exit/argv/environment/time receipt. All
test commands use closed stdin, native debug/frozen/deny-warn/j1/no-parallelize,
with a300-second per-command limit; none timed out. Temporary paths do not
provide an archival availability guarantee.

| Validated artifact | SHA-256 |
| --- | --- |
| stdlib_layer.mbt | `2493937648fb43514842799a65ec4129f9aac9023547a8243377bfd4fbef1449` |
| stdlib.mbt | `31d25cd1347257609205d66e1de21a15dd208388b761dfcc5114b79c1239d487` |
| stdlib_source.mbt | `39212e15a7fce36cda8c620b08116328df801d791ffff775734cd02497bf6e98` |
| object_std_test.mbt | `1cf6d2799a51cc4ba06d156eac1ced5683de032300fb42cfa71b4252126d4829` |
| spec_object_remove_key_test.mbt | `6e5bf45dc9411a8dc196a060353c2676a9b37952bcac608d6591e6a7d89f89cc` |
| Untyped frozen test | `183bedf74ccb273999e7adfd6091a343bb7b5171104e5082039b2abe38d06db3` |
| Typed frozen test | `6e5bf45dc9411a8dc196a060353c2676a9b37952bcac608d6591e6a7d89f89cc` |
| Frozen criteria | `c789eed04bc253bbb926644f46d51725a8cf43a364ad595beb7a7d821c7544de` |
| Baseline stdout | `2ef4ccef52930d634102b564b20a2dba4c34aec76585dbb4597896c8d1ee9a27` |
| Unchanged legacy after repair stdout | `acfeb3f899f6a5ae55dbe7f782683242715a36587412108422b5d62871db6dbe` |
| Repaired directed stdout | `f3cce346a168da9127e82fa09504d0d8393441a20c0ef912e3cf2caaa80e2cfc` |
| Neighbor stdout | `6568c837a5b748e78707f97ae7c803b3ff0f4511e3a122395c8d0b5405600f2a` |

Exactly one manual public-contract record is added:65 prior records remain
equal, yielding66 reviewed subsets and zero whole-function acceptances. No
language-rule completion or prior language evidence is modified; no reviewed
language inspection snapshot references the changed source-routing file or
legacy test file. Existing A0/B0/N0/R0/PE0/DF0 and comparison print disputes keep
their scopes. No new defect remains in the selected projection cases; general
child judgments retain their separate partial matrix status.

Full native regression, release, standalone API/CLI delivery, Linux and Go/C++
were NOTRUN on these new product bytes. The earlier758/758 result belongs to
4b1be8a and older Linux results to228cb25; neither is transferred to this repair.
No SSH, remote window, installation, private proposal import or push occurred.
Overall specification conformance remains incomplete.

The frozen public inventory generator also exited0 in1.616 seconds after
including the staged independent test. It validated the three fixed public
reference hashes and the new record without changing any of the65 prior manual
records. The language coverage map stayed byte-identical; no language matrix
regeneration or semantic rerun was needed. Source/test hashes above stayed
unchanged through generation and formatting.

## Public contract boundary matrix at4488a71

This is one bounded completion of this function's evidence, not a new stdlib
campaign. The original eight groups, original2-pass/6-failure run, four legacy
migrations and fixed source version above remain unchanged. No implementation
change or new defect is assumed. Exactly two consolidated groups, ORK9/ORK10,
will close the direct evidence gaps identified below; no automatic expansion
or whole-suite rerun follows them.

The source has exactly two required parameters obj,key and no defaults. The
[fixed function-parameter description](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#L177-L197)
allows positional/named arguments with positional ones first. For two required
parameters this gives four valid forms: two positional, obj/key names in either
order, or positional obj plus named key. Named uniqueness is separately required
by [chk-apply](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#L1633-L1641).
The [apply named-membership premise](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#L2231-L2249)
excludes unknown parameter names. These rules, the fixed header and existing
host error categories supply independent binding expectations; no diagnostic
text, duplicate-error winner or native callback count is standardized.

| Public contract component | Existing executed coverage | Direct gap and final criterion |
| --- | --- | --- |
| Names/defaults/valid calls | ORK1 positional and reordered names; ORK8 missing/extra calls | ORK9 observes function arity2, all four valid forms, missing named parameters, unknown labels and Static duplicate named arguments. Neither parameter has a default. |
| Object and key domains | ORK8 covers all six non-Object heads plus isolated input/computed-key failures; ORK5/ORK6 cover key demand and all disjoint key kinds | No new String-only key error is required: the fixed predicate performs equality with String k. Same-type nonscalar PE0 is not used. |
| Missing and empty keys | ORK3 removes empty String; ORK5 covers empty/hidden-only iteration and skipped key errors | ORK10 supplies absent String keys on nonempty objects. Remaining visible data is preserved; hidden fields are still not projected. |
| Visibility | ORK3 normal/hidden/forced-visible input; existing Ex child review covers inherited separators | ORK10 composes all nine inherited separator pairs and proves result fields are ordinary colon fields, so an earlier hidden field can keep them hidden. |
| Assertions | ORK7 flat false retained-read failure, metadata laziness and false-assertion empty projection | ORK10 adds flat true with an unused error message, non-Boolean condition rejection and isolated condition error propagation. Values are harmless, avoiding competing-error priority. |
| self/super and closures | ORK1/ORK2 retain original final self, defining super and extracted closure under output overlays | Already directly covered. No stable public std hook/rebinding extension is added. |
| Value/key laziness | ORK4/ORK5/ORK6 skip removed/hidden/unread retained payloads, empty filter key, nonstring nested values and unused calls | Already directly covered; no exact callback multiplicity or independent-error ordering obligation is invented. |
| Unicode identity | ORK3 empty, composed/decomposed and astral keys | ORK10 adds NUL and a versus a-NUL prefix separation. Raw text decoding and invalid host representations belong to producer rules, not a new removal encoding policy. |
| Immutability and aliases | ORK2/ORK3 preserve source values/keys and warmed aliases across result overlays | ORK10 adds cold and warmed reads with an absent key; later result a=99 does not rewrite retained original self or closure value2. Pointer identity/allocation/sharing strategy is not promised. |

ORK9 literal successful result is {keep:7}; signature is [function,2]. Invalid
named bindings reject without fixing human messages; duplicate named inputs
reject Static even when the whole operation is unused. ORK10 visibility metadata
is [[x],true,[x]] when shown and [[],false,[x]] otherwise. Its output-visibility
control is [[],true,7,[x],7]. NUL deletion uses literal ordered key sets and
retained values10/20/30. Cold/warm alias results are [2,2,2,2,2,2,99]. Flat true
assertion yields {keep:7}; one invalid numeric condition rejects Type and an
isolated condition error propagates condition-required. Every new input has
separately built source and handmade public ASTs; no observed result or parser
export supplies an expected answer.

### What is open, and what is not an additional promise

For canonical invocation this function-specific behavior is fixed by the exact
embedded source body. There is no independent body ambiguity, String-only key
precondition, pointer-identity promise, general native trace contract, diagnostic
text or winner among independent failures. Timing, complexity, exact allocation
and unbounded success beyond configured host resource limits are not specified
by this public entry. General call grammar and malformed public AST policies
remain shared language/API obligations, not another private removal framework.

The conditional boundary is genuine: input obj[k] uses the common object-index
judgment. Objects with inherited assertion-super or in-progress/self-indexing
assertions therefore retain the existing N0/R0 child questions. This function
does not rewrite assertions; probing more removal variants cannot settle those
formal clauses. The ordinary-field DF0, A0/B0, PE0 and relational print disputes
keep their global status, but are not independently exercised by this body's
String/disjoint-type key predicate and object-comprehension projection. They
must not be listed as newly discovered function-specific failures or waived.

The target is to close the above direct gaps relative to these existing child
judgments. This does not grant an unconditional whole-function or whole-language
certificate, and does not leave an indefinite queue of unspecified details.
Tests remain local directed native debug, frozen/deny-warn/j1/no-parallelize,
closed stdin, with a300-second per-command ceiling. No new source repair,
reference interpreter, full suite, release, standalone API/CLI delivery, SSH,
Linux, installation, private proposal or push is included.

<!-- This boundary matrix and the new literal criteria precede execution. -->

### Boundary execution and stopping decision

The native check passed first time (exit0,0.518s). The unchanged frozen file then
reported **10 total,10 passed,0 failed,exit0** in8.738 seconds; stderr was empty.
The original eight groups stayed byte-identical as a prefix, and the two new
consolidated groups passed on their first execution. No source implementation,
legacy assertion, oracle, expectation or snapshot was changed. No new defect
was found, so no speculative product correction or further test batch followed.

The completed direct matrix covers the listed public contract relative to its
shared child judgments. Missing String keys and inherited visibility were real
evidence gaps; they are now executed rather than assumed from the old map's
word missing-key. The original flat false cases and new true/error/type controls
separate assertion forwarding from the unresolved inherited-super/reentry model.
The latter remains N0/R0 in the language matrix, not a new function requirement.
The body never compares same-type nonscalar keys or concatenates arrays, and
its filter condition is a Boolean comparison, so PE0/A0/B0/relational print
issues are not independently blocking this specific predicate/projection.
Ordinary input construction and global DF0 retain their own judgment scope.

All valid two-parameter call forms have finite coverage; there are no defaults.
Key values outside String are defined nonmatches, not missing Type errors.
Result identity is value behavior under immutable aliases and overlays; no
pointer identity, allocation strategy, general native callback schedule, runtime
complexity or independently competing-error winner is promised. These are not
pending tests or exemptions from a stated contract. No function-specific gap
remains after this bounded continuation; unconditional formal certification for
all supplied object-index children still requires the common N0/R0 decision.

Required native info then fmt also passed (exit0,0.183s and0.040s). No .mbti or
validated product/test byte changed. The language map and all65 other public
manual records are unchanged. This function remains one reviewed subset: the
total is66 and no unconditional whole-function acceptance is inferred.

Raw command argv/environment, closed-stdin/300s bounds, stdout/stderr, elapsed
and owned-process exit receipts are under
`/tmp/moonjsonnet-object-remove-key-boundary.u0sucnht`. This temp location is not
an archival availability guarantee. The principal hashes are:

| Artifact | SHA-256 |
| --- | --- |
| Frozen boundary criteria | `482ac9918d3981df962648e0daacac605301b42def7ccfab095c2db611d2db27` |
| Frozen ten-case file | `d7edc64d45fa915d283f94658ad836595a14b98dda8660ae279654dca6eedb1e` |
| Original eight-case prefix | `6e5bf45dc9411a8dc196a060353c2676a9b37952bcac608d6591e6a7d89f89cc` |
| Actual directed stdout | `fe181a16b4ba8108dc0e0792dd5f56a8655414d9a3c5ee8b77129291e78080eb` |

The previous2-pass/6-failure record and four precise legacy migrations remain in
the unchanged earlier sections. Earlier11/11 plus29/29 evidence remains bound
to4488a71; those neighbors were not repeated. Full suite, release, standalone
API/CLI delivery, Go/C++, Linux and SSH were NOTRUN. The758 historical full count
is not attached to this continuation. No push, upstream change, proposal import
or further specification domain was included. This contract branch now stops.
