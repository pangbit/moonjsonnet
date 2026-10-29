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

## Bounded shared-call follow-up frozen at 6569b9f

The production delta is one Builtin dispatch argument in Vm.call, the private
builtin strict parameter and its YAML-only read, and deferred YAML rendering
options. Neither Closure strict trampoline/call_env/default binding nor Native
dispatch, source selection, source bodies or higher-order ordinary calls changed.
Source-selected foldl, sum/avg, objectRemoveKey, remove and removeAt remain
Closures. The removeAt adapter's inner ordinary call does not discard an outer
strict call: the outer Closure has already demanded its own bound heads.
sum/avg add no unused optional parameter and already have admission/reduction
evidence, so they do not need a duplicate new strict family.

Ordinary call expectations derive from fixed
[apply/local rules](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#L2231-L2265)
and [function/parameter prose](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#L138-L196):
arguments/default expressions remain lazy, named/positional binding selects the
body's formal environment, and an ordinary inner call remains ordinary.
The fixed language page explicitly leaves
[tailstrict semantics TODO](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#L654-L667);
the formal apply grammar/rule has no strict variant. Strict head forcing below
is therefore an existing project regression profile, independently distinguished
from ordinary normative evidence. This does not certify all Builtin strict modes,
callback count/order, diagnostic winner order or complete application semantics.

The finite [six-group fixture](../../spec_shared_call_mode_test.mbt) uses literal
values/isolated errors and independently handmade Call trees, reusing only neutral
builders. Freeze these criteria before running; a missing test is not a defect.

| Group | Expectation and boundary |
| --- | --- |
| SC1 | Ordinary literal/aliased Closures with positional, reordered named, omitted and overridden defaults return7 without unused supplied/default errors. |
| SC2 | Strict regression demands an isolated supplied/default error head but not nested Array/Object/Function payloads; overriding a failing default succeeds. |
| SC3 | Empty foldl/remove/objectRemoveKey/removeAt keep unused arguments lazy normally; explicit strict Closure calls and aliases demand the isolated head. removeAt is positional, leaving idx/at/i unresolved. |
| SC4 | Outer strict calls do not make foldl/map/sort callbacks strict; unused callback defaults and unused element heads stay dormant. Native sort's Vm.call Closure callback is included. |
| SC5 | A strict zero-argument wrapper does not spread strict into an ordinary Doc body. An outer strict forwarding Closure demands its own heads; explicit strict source Stream likewise demands an unused option, while ordinary Stream returns the literal explicit-false-ending result. No default conflict is reopened. |
| SC6 | Ordinary and strict bad bindings reject before supplied/default/body errors for Closure, migrated source functions and Doc. No exact competing-diagnostic order is imposed. |

Reuse the current-byte language/arguments/stack controls from the preceding29/29
receipt without rerunning them. Run the six new groups with existing application,
function/default and YAML strict controls only, native/debug/frozen/deny-warn/j1/
no-parallelize, DEVNULL stdin,300-second per-command limits. No product change
unless an actual failure proves a scoped defect; no full suite, release, remote,
CLI/API, reference interpreter or general dispatch framework. Both evidence maps
and their whole-contract counts remain unchanged; any inventory refresh merely
records the new test file. Append actual results after the frozen criteria.


### Shared-call actual result and closure

No product defect was found. All inspected production files remain byte-identical
to6569b9f. The first check exited255 for two fixture-only issues: a conditional
String suffix needed parentheses, and local alias was a reserved future keyword
under deny-warn. Semantic tests were NOTRUN for that candidate. Only those syntax/
local-name details and formatter layout changed; literal outcomes and handmade
Call modes stayed frozen. Corrected check passes.

The six new groups and13 existing application/function groups plus the prior
one-group YAML strict control pass20/20 (failed0,exit0,8.647549917 seconds).
Both source and handmade paths complete. This is a mixed normative-ordinary and
explicitly scoped strict-regression result, not20 complete language rules. The
current-byte language/arguments/stack evidence from the earlier29/29 was reused
without rerunning it. info then fmt pass with no public mbti change; all17
validated source/test hashes retain their tested bytes.

The shared influence of this production delta is closed for the listed direct
paths: ordinary calls remain lazy, supplied/named/default binding is unchanged,
source-selected Closure calls retain explicit strict mode, and ordinary inner/
higher-order calls do not inherit their caller's strict flag. No product fix,
legacy oracle migration, snapshot update, language mapping or public manual
record change was needed. Whole application acceptance and unreviewed Builtin
strict behaviors are not inferred from this bounded review. The fixed normative
TODO is recorded rather than replaced by a Go/C++ result.

Evidence directory: `/tmp/moonjsonnet-shared-call.m4xpvo4f`. The original and
syntax-corrected fixture plus correction record are retained separately. The
corrected frozen test SHA256 is
`dbbfe455c182196d6c27a40424114ff964ee59781ecfe2f63900d16a4696ed02`;
the20/20 stdout SHA256 is
`d1a37b738e822c0721c7d89ab13954d581721ee65228d7693d1e8d1294bc4beb`.
The plan binds702 existing tracked inputs at6569b9f; shared-impact-review.json
records the inspected routes and reused evidence. Commands use DEVNULL stdin,
single worker and bounded time; raw exits and absent-group receipts are kept.
The generated public inventory adds the new test-file digest and refreshes
source/dirty-test provenance; all existing semantic records and its Markdown
remain equal. All66 manual public records and225 language evidence/acceptance
fields stay equal.

The next full local regression must validate the actual delta since3da8ab8:
eval Builtin strict forwarding, stdlib's YAML-only option/strict branch, recursive
manifest_yaml option demand, the exact scalar-option legacy migration and the
new YAML/shared-call tests. It should exercise ordinary source-route consumers,
callback/default binding, error/finite/output limits and current YAML/Stream
paths together; it must freshly enumerate the suite, not inherit802/802 or20/20.
There is no additional production delta in this follow-up. No full, release,
remote/Linux, independent CLI/API or reference execution occurred. Stream default
and assertion N0/R0 qualifications remain unchanged, with overall conformance
still incomplete. This follow-up ends here rather than expanding call semantics.

## YAML Number clause frozen at fbe2b117

Base `fbe2b117cae1042bccd44cbb7d4dc1b5098e38b9`. The fixed
[Doc Number branch](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1225-L1226)
returns `'' + v`; [Stream delegates each document](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1300-L1306).
The public Doc description supplies no conflicting numeric precision rule.
The current shortest fixed-decimal branch breaks that identity. The preserved
seven-case CLI baseline at `moonjsonnet-yaml-number.59jhivf_/formal-probes/`
has five text mismatches and two controls; its separate launcher failure ran no
product cases. The new native fixture still needs its own unchanged baseline.

`spec_yaml_number_contract_test.mbt` uses source and independently handmade ASTs,
with literal expected text and supplemental ordinary-coercion identities.
Large integers reuse the independent binary64 derivations in the
[JSON Number record](SPEC-JSON-CONTRACTS-2026-10-23.md#exact-legacy-expectation-migration).

| Group | Frozen required outcome |
| --- | --- |
| YN1 | Positive/negative fractions, exact fractions, signed zero, integer boundaries, rounded large integers, normal/subnormal values and both finite extrema use declared coercion text. |
| YN2 | Numeric leaves preserve nested Doc layout under both explicit indentation values, sorted ordinary quoted keys and hidden-field laziness. |
| YN3 | Explicit false/true Stream end flags preserve complete document markers and numeric/nested text; no default decision is made. |
| YN4 | Independent Doc/Stream literal expectations also satisfy the fixed empty-String coercion relation; product output is never the primary oracle. |
| YN5 | Scalar options and unused whole calls stay lazy; required scalar/nested errors and nonfinite producers reject. Existing spec_yaml_wbtest supplies direct internal Inf/NaN checks. |
| YN6 | Exact ASCII byte budgets include numeric text, indentation and explicit Stream markers; one byte less is Limit, observed through std.length to exclude outer JSON quoting. |

Expected baseline: YN1-YN4 and YN6 fail, YN5 passes; later loop branches after
the first failure are NOTRUN. This selects only the Number clause relative to
ordinary coercion. N0/R0, keys/quoting/bare-safe policy, TOML/JSON behavior and
the Stream default dispute remain outside scope. Production, legacy tests,
public documentation and coverage maps stay untouched at this freeze; no
build/test/format/commit, full/platform run, push or publication occurs here.

### Preserved baseline and minimal candidate

The frozen fixture `7f0d489da3514669bedadf50a687d575b11fd3cf76c424fd454f2eeef0dfe6f6`
passes 1/6 and fails 5/6 on unchanged production (exit 2, 6.906 seconds),
exactly YN1-YN4/YN6 versus the passing YN5 control. Check exits 0. Later loop
branches after each failure remain NOTRUN. The completed native receipt was
recovered after a transport error; `native-baseline/receipt.json` and raw logs
remain intact, while `recovered-receipt.json` supersedes the earlier uncertain
execution classification without rewriting it. Both process groups are absent.

The candidate changes only the Num arm to ordinary numeric rendering with
`out.limit - out.bytes`, retaining the finite guard and ManifestText writer.
Shared formatters, other YAML branches, dispatcher/defaults, TOML and JSON are
unchanged. No old test expectation requires migration. Only the two existing
YAML coverage records gain the six Number witnesses; other 65 stay unchanged.
At the candidate freeze, final directed validation remained pending.

Info, formatting and format-check pass with no mbti diff. Formatting changes
only layout and optional trailing commas; literal and executable tokens remain
equivalent. Preformat inputs and raw outputs are retained under `format/`.
Final candidate hashes: regression
`26f7f0ff1d14bd90932ea2b5d2010165003b7497ec772b5398782bfeecb441c2`;
manifest_yaml.mbt
`43da75cae91495727d94cef1b9467e3cf2757be54460ea223b72ee44b63e49a0`.

Final validation passes 27/27 native debug groups (six new, 21 existing; exit 0,
16.222 seconds) and the same seven frozen CLI probes pass 7/7.
`final-directed/receipt.json` binds the exact source/test hashes above; all 11
owned process groups are absent and input hashes remain stable. The original
1/6 baseline and failures remain preserved; no old oracle was migrated.
Full-suite, release, Linux and fresh C++ runs are NOTRUN. This Number clause
does not establish whole-function or overall conformance, which remains incomplete.

## YAML bare-key classifier frozen at 353af358

Base `353af358e695eadb381edef9febc9419a1d1c9fc`. The fixed executable
[bareSafe predicates](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1089-L1220)
use ASCII sets, reserved words, counts and original-case prefixes. They do not
parse a general YAML number: safeChars includes a dot and the float condition
requires exactly one dot, despite looser explanatory comments. Independent
literal field-text expectations in `spec_yaml_key_contract_test.mbt` cover
source and handmade ASTs; no copied interpreter output or second classifier
supplies the oracle. The preserved ten-case CLI baseline has seven mismatches
and three controls at `moonjsonnet-yaml-key.w4encs9i/baseline.json`.

| Group | Frozen required outcome |
| --- | --- |
| YK1 | Exact ASCII admission and full case-insensitive reserved list; nan/inf/infinity boundaries remain nonreserved. |
| YK2 | Date/integer decisions follow allowed characters and dash counts, including underscore-only and malformed-looking shapes. |
| YK3 | Binary decisions admit the fixed permissive digit/set shapes; lowercase original prefixes and total length distinguish 0b/-0b/0B10. |
| YK4 | Float decisions use exactly one dot and bounded e/dash counts, independent of parseability, overflow, underflow or exponent case. |
| YK5 | Hex decisions use anchored lowercase original prefixes, allowed folded characters, length and dash counts; 0x/-0x/0Xaf and x0xffz are distinct. |
| YK6 | Nested Doc and explicit false/true Stream layouts preserve classification; forced quoting is unchanged; exact ASCII output bytes pass and one byte less is Limit. |

All six groups are expected to expose an unchanged-product mismatch; subsequent
loop branches after the first failure are NOTRUN. Existing demand/error/hidden
controls are reused. This selects only the private classifier: value formatting,
quote_keys=true, shared Unicode escaping, JSON/TOML, dispatcher and Stream
default behavior are unchanged. The explicit default conflict remains NOTPASS;
no whole-function/YAML certification is inferred. Phase one changes only this
fixture and frozen criteria, with no production/legacy/map edit or test/build.

### Preserved key baseline and candidate

The frozen key fixture `cbf2ff6f15b42bbff1cd56029410d626b655bac40504d62d096f6935037fdb0f`
fails 6/6 on unchanged production (exit 2, 6.942 seconds); later loop arms were
NOTRUN. With only the classifier replaced by the fixed predicates, all six pass,
including those later arms. The combined legacy run passes 8/9 (10.212 seconds);
its sole failure is the obsolete quoted `x0xffz` expectation below. Raw evidence
and the old test copy remain in `moonjsonnet-yaml-key.w4encs9i/native-baseline/`
and `after-fix-before-migration/`. No old failure is erased or relabeled.

| Unchanged input | Old expected text | New expected text |
| --- | --- | --- |
| `std.manifestYamlDoc({'true':1,'1e309':2,'x0xffz':3,'a/b':4},quote_keys=false)` | `1e309: 2\na/b: 4\n"true": 1\n"x0xffz": 3` | `1e309: 2\na/b: 4\n"true": 1\nx0xffz: 3` |

Only that quotation changes: `x0xffz` has neither original `0x` nor `-0x`
prefix, and `z` is outside the fixed hex set. The private decimal parser is
removed; Number rendering, other branches and guards are unchanged. Only the
two existing YAML coverage records gain YK witnesses; the other 65 are unchanged.
At candidate freeze, the final 33-group run and ten frozen CLI probes were pending.

Info, fmt and fmt-check pass with no interface change. Preformat copies and raw
logs are preserved under `format/`. Formatting changes only layout, optional
commas and expression-body braces in two classifier predicates; literal and
operation tokens are equivalent. Formatted fixture SHA-256:
`498d1196dcb0a677e30b0f609191b3188855755aa356d1c57f48afe47f4bae42`;
classifier source: `2a3064f0dac0cb9a8fc6d7eff52beb701119e5e52f2b73c3d0c1c9d3bd842dc7`.

Final directed validation passes 33/33 native debug groups (exit 0, 15.427 seconds)
and the same ten frozen CLI probes pass 10/10. `final-directed/receipt.json`
binds the source/test hashes above; all 14 owned groups are absent and inputs stable.
The original 0/6 baseline and pre-migration 8/9 result remain preserved.
Full-suite, release and Linux runs are NOTRUN. Stream remains UNRESOLVED/NOTPASS;
whole-function and overall conformance remain incomplete.

The Stream default remains **UNRESOLVED / NOTPASS**: the fixed
[public heading](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#L1757-L1758)
declares false, while the [source](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1300-L1306)
declares true. Thus `std.manifestYamlStream(['1'])` would yield `---\n"1"\n`
versus `---\n"1"\n...\n`. The [fixed e_std rule](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#L1095-L1132) derives the latter source result
but supplies no precedence for contradictory declarations; the
[sort review](SPEC-SORT-DEMAND-2026-10-25.md#why-these-decisions-supersede-the-earlier-open-rows)
explicitly does not establish one. Implementation/default oracles stay unchanged;
the key probes use explicit flags and do not resolve this conflict.
