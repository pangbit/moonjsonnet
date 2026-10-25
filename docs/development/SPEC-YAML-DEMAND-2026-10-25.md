# YAML error propagation and actual option demand

## Frozen independent scope

Base3da8ab84953997aab53d96c726656cdbe60e02de has699 clean tracked entries.
Existing P0 YAML nested Runtime/function failures, producer/JSON/YAML finite
checks, Type/assertion errors, hidden values and recovery were included in the
latest802/802 local debug regression. Do not repeat these unchanged cases as a
new baseline or claim a fresh swallowed-value defect without observing one.

References remain google/jsonnet bbb38f1020be1f5aed560928fb839b2c448cefb4.
The [Doc public declaration](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#L1691-L1752)
and [fixed definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1089-L1298)
use value, indent_array_in_object=false and quote_keys=true. The fixed aux uses
quote_keys only for a nonempty visible Object key list, and indentation only
when an actual Object field is a nonempty Array. Scalar/empty/library traversal
paths do not reference unused option expressions. No eager type/argument guard
is specified for those expressions. Required conditions still demand Bool.

The current native entry instead forces every parameter before rendering. A
scalar call with an error-valued unused option is a concrete falsifiable gap;
its expected result is the literal scalar YAML String. This is not a dispute
about independent competing errors. Non-Bool options are rejected when actually
used, not merely because supplied. Preserve existing native quoting/layout
algorithms; this is error/demand responsibility, not full YAML formatting review.

Current yaml_value recursively raises from force/field/finite/output helpers;
its public entry returns String only after successful completion. Stream join
also has no error catch. Internal builder prefixes after a raised error are not
successful public outputs, and no transactional rollback of that private buffer
is invented. P0 no-successful-partial-text behavior is independently supported
by the existing checks; new late-document/required-option cases extend coverage.

[Stream source](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1300-L1306)
first requires an Array, maps Doc, joins all documents and then uses c_document_end.
The [public signature](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#L1754-L1802)
defaults c_document_end=false while source defaults true. That conflict stays
open. Every new stream call supplies the end flag explicitly; no default pass or
compatibility exception is inferred.

Assertions follow the existing [shared adjudication](SPEC-OBJECT-ASSERTION-ADJUDICATION-2026-10-22.md#complete-shared-assertion-domain-review-atf3871b8):
flat actual field reads demand assertions, reflection/zero-key library traversal
does not. New agreed cases use flat objects only. No inherited self/super prefix,
active reentry, constructor-priority or global N0/R0 decision is made. Inherited/
cyclic assertion branches keep their existing conditional qualifications.

## Frozen seven-group probe map

[spec_yaml_demand_test.mbt](../../spec_yaml_demand_test.mbt) has independently
handmade AST and source entries with literal values or isolated supplied markers.

| ID | Independent expectation |
| --- | --- |
| YD1 | Scalar/empty/hidden-only values return exact YAML Strings with unused error-valued or non-Bool options; no unused payload/body is evaluated. |
| YD2 | Visible scalar/Object/empty-Array fields require quote but not array indentation. Required quote errors/Type propagate; unused indentation errors stay dormant. |
| YD3 | Actual nonempty Object Array fields require Bool indentation at any nesting depth; root/nested Arrays alone skip both unused options. |
| YD4 | Explicit true/false-ending streams skip unused options for empty/scalar/hidden-only documents and demand needed options in a later Object document. Literal full markers/documents are required. |
| YD5 | Late visible Runtime/Type/function failures in later documents reject even under type(), so successful prefix text cannot masquerade as a full result. Function bodies remain uncalled. |
| YD6 | Flat empty/hidden assertion conditions/messages remain unneeded, including nested/stream empties; visible fields demand false/non-Bool/error assertions and only needed messages. Hidden cyclic/function payloads stay unused. No N0/R0 profile is counted here. |
| YD7 | Agreed parameter counts/binding reject without supplied-value demand; nonarray stream guard skips options/end. Empty streams still require the explicitly supplied Bool end condition and propagate its error. |

First check then run only these seven new groups on unchanged product, retaining
raw outputs/exit and first-error loop cutoffs. If confirmed, use the smallest
native change: keep binding/defaults/renderer and defer option thunks until those
specific field branches require them. No upstream body, global assertion/index/
arithmetic mechanism or Stream default changes. Keep literal-Bool private helper
callers working for the existing defensive nonfinite test. If the stdlib file
changes, preserve old inspection bindings and prove changed ranges disjoint
before rebinding current hashes; no language evidence/completion is promoted.

Final directed regression reuses spec_yaml, spec_yaml_wbtest, spec_review,
toml_yaml and standard_native_diagnostics alongside the new file. Required
resource errors and recovery keep their old controls. Preserve any obsolete
legacy option assertion and migrate only the same exact input with fixed-source
basis. No bulk snapshot or Go/C++ fixture update.

Use native/debug/frozen/deny-warn/j1/no-parallelize, DEVNULL stdin and300-second
bounds; then info/fmt and consistent metadata, precise English local commit and
owned-group exit receipts. No full suite, release, SSH/Linux, standalone CLI/API,
reference interpreter, installation, upstream/proposal change or push.

<!-- All independent criteria precede execution; append actual results below. -->

## Adjacent tailstrict control frozen before implementation

The original seven groups remain byte-frozen. A separate one-group
[tailstrict control](../../spec_yaml_strict_test.mbt), frozen while the product is
still unchanged, protects explicit argument-head forcing. Needed strict option
errors must propagate after successful binding; unused non-Bool values and
nested payloads are not validated or manifested just because their heads are
strict. Empty flat object assertions are not thereby indexed. Strict-mode
plumbing is read only by YAML's new demand branch; unrelated builtin modes are
not revised by this batch. Reuse existing language trampoline controls afterward.


## Actual result and repair

The original seven independent groups passed3/7 and failed4/7 (exit2,
8.591015125 seconds). YD1-4 stopped at their first unexpected error; later
loop variants/manual branches in those groups were NOTRUN in that baseline.
YD5-7 passed. The separate, pre-repair strict group failed after its two
required-head error checks (exit2,6.355999625 seconds): an unused non-Bool
option was rejected. Later strict variants were NOTRUN until the repair.
The eight frozen test groups and their literal expectations did not change.

The native Doc handler now keeps option thunk IDs until the renderer actually
needs them. Nonempty visible Object keys need quote_keys; a nonempty Object
Array field needs indent_array_in_object. Recursive calls retain those IDs.
Binding/defaults remain first. Vm.call forwards strict mode, which only this
new handler reads: strict calls demand bound heads before traversal, without
adding unused Bool checks or forcing nested option payloads. Private literal-
Bool renderer callers still use their prior behavior. No catch, assertion,
finite/output limit, quoting/layout algorithm or Stream definition changed.
An initial private optional-tuple type annotation failed check (exit255);
semantic tests were NOTRUN for that candidate. Correcting it to an optional
tuple with None default passed check; this was not a semantic red result.

The first repaired run kept old tests unchanged:29 total,28 passed,1 failed
(exit2,13.279143291 seconds). Its sole failure was the old expectation below.
Later error/resource loop variants after that assertion were NOTRUN there.

| Exact old input | Preserved old expectation | New independent expectation | Fixed basis |
| --- | --- | --- | --- |
| std.manifestYamlDoc(1,0) | Error | String with content 1 | Fixed aux Number branch1089-1298 returns the number text without reading either formatting flag. Bool validation belongs only to an actually used condition. The same input moved to toml_yaml_test's literal success list. |

No snapshot or reference fixture was changed. Original product/test bytes and
all raw failures remain in the external evidence directory. The final run
passes29/29, failed0 (exit0,9.545150167 seconds), including the original seven,
strict control, existing YAML/internal finite, general review, TOML/YAML, native
diagnostics, language, argument and stack groups. No groups were filtered out
inside those ten files; this is a directed subset, not a full-suite claim.
moon info --target native --frozen and moon fmt pass; no public mbti changed
and all18 validated source/test inputs retain their tested SHA256 values.

The original P0 has not been relabeled as a new defect. Private builder prefixes
on raised errors are allowed; callers still receive an error, never successful
truncated text. Existing producer and defensive finite guards remain in use.
The new cases close option-demand and later-document error gaps relative to
the fixed ordinary language children. Flat empty/hidden versus visible-field
assertion demands are explicit; inherited/reentrant N0/R0 remains conditional.
The Stream false/true default conflict remains unresolved and every new stream
call supplies c_document_end. Full quoting/layout certification is outside
this responsibility and no whole-function/language acceptance is inferred.

## Evidence and metadata binding

Local raw evidence is retained at
`/tmp/moonjsonnet-yaml-demand.g05i0ni6`. plan.json binds base3da8ab8 and699
tracked inputs; validated-inputs.json binds the18 final runtime/test files.
Each command.json records argv, DEVNULL stdin, C locale, RUST_LOG=error,300-second
limit, exact exit/time, raw output hashes and absent owned process group.
The independent fixed-source references were hash-verified without contacting
or running a reference interpreter.

| Frozen/result artifact | SHA256 |
| --- | --- |
| Seven-group criteria prefix | d36617e9198e330c12a4b0d507a63a898a02d65c4281ead3fcc496ac547e30bc |
| Seven-group test | e12117551de7ef28530b0998ee5f3973f8055e5ce3a4373fa43757dea8c08e5c |
| Separate strict test | 479ecaacea2d21446d3d37151748d7b0eed318d2d3069b2de070139fd43e0d5c |
| Original seven-group stdout | 1954b03ac51915181c52278fd80614932fd90189259f84ccf6f4ccd31e2ca41d |
| Original strict stdout | aab1ab889802a54faac7ee69f020166b3e4111a058cf8b65da9a41c9b6744bdb |
| Repaired unchanged-legacy stdout | 9a0935c109db6b64a72f72a5169aa567dac9fb51367159194fc50cbd12c78544 |
| Final29/29 stdout | 6568c837a5b748e78707f97ae7c803b3ff0f4511e3a122395c8d0b5405600f2a |

inspection-rebinding.json proves35 unchanged anchors lie outside every
normalized source edit (16 stdlib and19 eval); all other mapping fields and225
language evidence records remain equal. This is hash maintenance, not new
language acceptance. Only the two existing YAML public records extend; other64
remain equal,66 subsets/zero whole-function accepts. No old802/802, release,
Linux, independent CLI/API, Go/C++, installation or push evidence is inherited.

The language generator confirms unchanged totals:28 named-rule reviews,1
constructor-transfer review relative to children,63 partial and2 unreviewed rows,
225 evidence IDs and complete_conformance=false. The public generator retains
153 candidates,66 reviewed subsets and zero whole-function passes. Toolchain:
moon0.1.20260920 (914d7da), moonc0.10.14+7d59c7ec9; native macOS debug only.
The project documentation checker validates the final linked report and maps;
its exact raw receipt and the final local commit binding remain alongside the
external evidence. No additional semantic run is needed after metadata-only
updates because all18 validated runtime/test hashes are unchanged.
