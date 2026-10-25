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
