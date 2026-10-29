# Public JSON input and output contracts

## Frozen priority and oracle

Base 110e4036041ebb2956767bd04d02659bb8c9a8d7. This batch selects parseJson,
manifestJsonEx, manifestJson and manifestJsonMinified from the public inventory.
None has manually mapped dimensions yet. The repository's
[engineering requirements](zh-CN/REQUIREMENTS.md) require JSON processing for
configuration generation, dashboard data and embedded structured results; the
[current acceptance contract](SPEC-CONFORMANCE.md) requires errors and demand
timing for every public function. This cohesive input/output group therefore
has direct user impact beyond adding another language subdomain. No private
application document is read, quoted or added.

Official Jsonnet remains bbb38f1020be1f5aed560928fb839b2c448cefb4:
[parseJson](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#std-parseJson)
(stdlib.html 1268-1290) parses JSON String data; the
[manifest declarations](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#std-manifestJsonEx)
(1535-1690) specify the value/indent/newline/key_val_sep interface and wrappers.
The fixed [source](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1048-L1094)
defines default newline '\n', key separator ': ', manifestJson's four spaces
and minified empty indent/newline with ':'. Its aux branch determines demand:

- Scalar null/Boolean/Number/String output does not read formatting options.
- Empty Array/Object output uses newline twice, without indent or key separator.
- Nonempty arrays use indent/newline; key separator is needed only for actual
  visible object fields, including nested fields.
- Visible values are traversed, hidden values are omitted, Function values fail
  without invoking their bodies, and required errors cannot become success.

Expected JSON values and small exact layouts are written independently. Parsed
manifestation strings are compared with literal expected JSON using the host
JSON parser, never product parseJson output as another product call's oracle.
Source calls and independent Call/Obj/Arr/Function ASTs are separate entries.
JSON payload syntax errors occur on call demand as Runtime, not source Syntax;
nonnumeric/nonstring host error tags and missing/unknown bindings are embedding
checks, not a standardized human diagnostic format.

| Group | Independent required outcomes |
| --- | --- |
| JC1 | Valid scalar/empty/nested JSON String fixtures, Unicode and standard escapes yield literal JSON values through positional/named str calls and independent ASTs. |
| JC2 | Malformed JSON and wrong outer argument types reject without forcing unrelated container/function payloads. Required input errors and scalar nonfinite production propagate; unused whole calls stay lazy. |
| JC3 | The three output APIs preserve literal visible JSON data and hidden errors, with declared named/default options, four-space/default and minified/custom layouts. No general float spelling or source-tree round trip supplies the expected result. |
| JC4 | Visible nested errors, Functions and required format options fail; Function bodies stay uncalled. Missing/unknown interface bindings fail before provided native gates. Unknown value expressions remain statically invalid even when unused. |
| JC5 | Source Ex calls skip error-valued format options in scalar/empty/array-only branches, yielding declared literal Strings. |
| JC6 | Independently built AST Ex calls satisfy the same fixed demand outcomes; parser export does not construct them. |

The suspected eager-formatting mismatch must first fail on unchanged product
code. Only then may the Ex path retain option thunks and force them in used
branches. Existing native/reference-oriented std_manifest error cases for scalar
unused indent/newline/key separator do not establish normative eagerness. If
the regression confirms the mismatch, preserve those original bytes and move
the three old cases to nonempty-array/empty-array/nonempty-object contexts where
their type/error checks are actually required. Keep the new unused-error
regressions and all literal expectations unchanged; do not make a guessed
blanket type-domain decision for unused invalid option values.

Reuse existing string-concat/manifest/finite/visibility evidence in its original
scope. In particular std.manifestJson's visible-field traversal and ordinary
top-level manifestation are distinct; no new assertion policy or N0/R0 result.
Duplicate JSON keys, malformed host Strings/surrogates, general decimal rounding,
all formatting/type/resource combinations and whole function conformance remain
unproved. YAML's documented best-effort/root restrictions are outside this group.
Language print conflicts, shift exclusions and A0/B0/N0/R0/PE0/DF0 remain intact.

Use existing public inventory/schema v2 tools. No new metadata framework. If
product changes, run affected output/argument/diagnostic/finite/reflection
neighbors once, rebind only demonstrably unchanged inspection anchors to the
new source hash, and retain all prior decisions. Single worker, nice 10, native
debug frozen -j 1, no parallel tests/full suite/remote/install/push/dependencies.

<!-- Criteria above are frozen before execution; append results below. -->

## Results and bounded correction

The first native debug run on unchanged product code ran six tests: four
passed, and JC5/JC6 failed (exit 2). Both the source calls and independent AST
calls incorrectly demanded unused format expressions. For example,
`std.manifestJsonEx(1, error 'unused')` must return the String `1`: the fixed
source's scalar branch never reads indent. Empty containers still demand
newline; nonempty arrays demand indent; actual visible object fields demand
key_val_sep. The first failure log and original product/test bytes are retained
in `/tmp/moonjsonnet-json-contracts.zk9x_k_t`.

The correction keeps manifestJsonEx's format arguments as existing VM thunk
IDs, rather than including them in the native dispatcher's eager parameter
loop. The visible-value renderer resolves a format argument only in a branch
that uses it and forwards the same IDs into nested containers. Existing fixed
String-style callers keep their private interface defaults. The change does
not add a public interface or modify the ordinary manifestation path.

Three legacy error cases formerly supplied invalid/failed options to a scalar
that does not use them. Their original bytes remain in the evidence directory;
their calls now use `[1]` for invalid indent, `[]` for invalid newline, and
`{x:1}` for failed key separator. The assertions still require errors in these
demanded contexts. All other legacy String inputs and nonlayout tokens are
unchanged. This correction follows the frozen plan above, rather than changing
the new regressions' expectations to match implementation behavior.

After the correction the exact first-run regression bytes passed 6/6. Their
SHA-256 remains
`4b6cf2af9358e616bab60e695a65ac7e47e454d83a722a493ae9a325826ac8d0`.
The affected tests ran serially once on the corrected source:

| Test file | Passed |
| --- | ---: |
| spec_json_contracts_test.mbt | 6/6 |
| std_manifest_test.mbt | 4/4 |
| arguments_test.mbt | 1/1 |
| standard_native_diagnostics_test.mbt | 2/2 |
| spec_manifest_wbtest.mbt | 1/1 |
| spec_string_concat_test.mbt | 4/4 |
| spec_object_ex_test.mbt | 3/3 |
| spec_object_head_test.mbt | 2/2 |
| spec_sequence_structure_test.mbt | 4/4 |

All nine commands exited 0: 27/27 in total, with nice 10, native debug,
`--frozen --deny-warn -j 1 --no-parallelize`. These are directed affected-path
checks, not a current full-suite result. The corrected product hashes are
stdlib.mbt
`a8bd68d2263344036a9c89975385754610b1ccc7d906fc213da7fe65157679a4`
and manifest_json.mbt
`319fc7f84c60fd65609af3cc4fbe84bfaa54f4d3107b114a7fca6737f93b08bc`.
The saved before/after receipts bind each test's bytes and log hash; check,
info, root formatting and the existing matrix script also exited 0. Generated
public interfaces are unchanged. No semantic check was repeated after these
receipts merely to refresh a report.

The one-off final scope audit initially stopped before staging or the docs
checker because prose rows carry a null rule_review. Its receipt is retained;
only that audit's null handling was corrected. No product, test expectation,
matrix data or existing checker changed to satisfy it.

## Inventory and evidence limits

The public inventory still lists 153 function candidates. Its manual map has
44 records, of which 41 functions have at least one reviewed dimension;
parseJson and the three JSON rendering APIs add normal/error/lazy/boundary
subsets. All 40 preexisting manual records are unchanged. A reviewed dimension
is not whole-function acceptance: every whole-contract status stays
unaccepted, and behavioral_conformance_proven stays false. JC1-JC6 are this
report's groups, not invented canonical language test IDs. Inventory source
hashes include both changed test files; their uncommitted-at-generation labels
describe the frozen generation inputs, not the final Git state.

The language matrix remains 94 rows: 28 completed named transfers (9 static,
19 evaluation), one constructor transfer completed relative to its child
judgments, 63 partial and two unreviewed. All 195 canonical evidence entries
and all decisions/clauses are unchanged. The product's shared stdlib file hash
changed, so 16 existing inspection anchors across six named reviews were
rebound: length-array, length-object, length-string, object-fields-ex,
object-has-ex and type-object. Their anchors and reasoning remain unchanged.
Removing the new Ex-only dispatch branch and restoring the old Ex match arm
reconstructs the entire prior stdlib file exactly; this byte check and the
affected neighbors support the limited rebindings. It is not a rerun or an
upgrade of those reviews. Schema v2 and both generators remain unchanged.

No new conclusion covers duplicate JSON keys, malformed host Strings or
surrogate policy, general decimal rounding or float rendering, all escaping
and resource combinations, every argument combination, exact error messages,
or unused invalid option *value types*. Unused error expressions and required
option failures have the specific evidence above. Output order in a failure
race is not adjudicated. YAML, ordinary top-level assertion manifestation,
N0/R0 and all other paper conflicts remain outside this correction. The two
unreviewed greater-than print conflicts and bounded-shift exclusions are
unchanged. No Go/C++ comparison, remote operation, new dependency, full suite
or push ran; the historical 539/539 full run remains bound only to 5651ae9.

Raw frozen criteria, first failure, after-fix results, scope/mapping audits,
generated inventories, final staged hashes and documentation/commit receipts
are retained in `/tmp/moonjsonnet-json-contracts.zk9x_k_t`.

## parseJson input-domain continuation frozen at 727a59d

Base727a59dd9695009113a554b1d623dd071950ede0 is clean with706 inputs.
Reuse JC1/JC2/JC4 normal roots, str binding/type errors, required markers and
whole-call laziness. The relevant parseJson dispatcher, from_json/native_result,
diagnostic scanner and six-group JSON test bytes equal the0d06ded816/816 snapshot;
only the unrelated YAML wrapper changed since that full run. Do not rerun old
controls merely to refresh counts before finding a new gap.

The fixed public parseJson paragraph1267-1290 parses JSON String data without
YAML's best-effort/container-root restriction. The fixed JSON value grammar and
finite Number requirement apply. JSON Number tokens do not have YAML's untagged
String fallback;1e309 must not become a successful Jsonnet Number anywhere in
the parsed tree. Ordinary Jsonnet field expressions remain lazy, but input JSON
is data, not a collection of unevaluated Jsonnet field expressions.

Static inspection finds complete input consumption in the installed core parser:
parse_value, four-character JSON whitespace skipping, then an explicit EOF
check. Error data is translated only after that parser rejects. All JSON root
classes pass through from_json; no collection-only guard applies. The suspected
gap is instead conversion: from_json recursively converts Arrays but stores
Object members as Literal JSON. An overflow member might therefore be delayed
past type/length or an unrelated selected field. Freeze the minimal candidate
`std.type(std.parseJson('{"x":1e309}'))` as Runtime before modifying product code.
The local core parser/source hashes are retained externally; they explain the
path but do not supply normative expected results.

The [five new groups](../../spec_parse_json_input_test.mbt) supply literal
expectations through source and independently handmade Call trees:

| ID | Independent gap or control |
| --- | --- |
| PJI1 | Every primitive/Array/Object root allows JSON whitespace, but rejects a second value, nonwhitespace suffix or comment. No valid prefix can stand in for the complete input. |
| PJI2 | The eight standard JSON escapes, nonsurrogate Unicode escapes, three canonical well-formed supplementary pairs, literal astral data and escaped keys produce exact Strings/values. Interior U+FEFF is data. Empty/reserved-word keys retain literal data bindings. |
| PJI3 | Incomplete/nonhex escapes, non-JSON escape letters and raw controls in String keys/values reject as data errors before type(). These are JSON data rules, not Jsonnet source quoting rules. |
| PJI4 | Parsed unique-key Object/Array members must all be finite before type(), length() or an unrelated field succeeds; ordinary unused whole calls still skip parsing. Finite large values and quoted numeric text remain valid. |
| PJI5 | Ordinary Jsonnet Object fields remain unforced by type or other field reads. Existing caller/resource bounds are controls: actual40-level JSON nesting rejects at depth32;40 bracket characters inside a String do not count as nesting. |

PJI2's canonical paired JSON data escapes do not adjudicate ill-paired/unpaired
surrogates, arbitrary malformed host UTF16, replacement recovery or Jsonnet
source escape policy. The older
[quoted-source review](SPEC-QUOTED-STRINGS-2026-10-23.md) keeps those source-side
limits; [encoding/import reviews](SPEC-IMPORTSTR-UTF8-REVIEW.md#explicit-unknown-and-exclusions)
keep the distinct initial-BOM question. No initial JSON-data BOM verdict is
borrowed from imports or inferred from installed parser acceptance. No new BOM
or lone-surrogate profile is run. Duplicate JSON keys, general numeric rounding,
diagnostic winner order and complete unbounded parser/resource proofs stay open.

First run the five frozen groups against unchanged code. If the finite-data
gap is real, prefer a parseJson-only eager data conversion using the unchanged
bounded native_result helper with the current VM depth as its base. Keep generic
from_json, user Object expression laziness, host callbacks, YAML admission and
the installed parser unchanged. Do not default the conversion depth to zero and
weaken caller-relative limits. This avoids a general dispatch/value refactor.

After a demonstrated repair, rerun the same five groups and necessary existing
JSON input/diagnostic/finite/type/reflection neighbors once, keeping all oracles.
Use native/debug/frozen/deny-warn/j1/no-parallelize, DEVNULL and300-second bounds.
If stdlib changes, preserve all old inspection anchors with an exact edit-span
proof before hash maintenance; no language completion follows. Only the existing
parseJson public record may extend; the other66 remain equal and the count stays67.
No full suite, release, SSH/Linux, CLI/API campaign, Go/C++, dependency change,
upstream edit, private application document or push is authorized here.


### Current baseline and scoped repair

The initial fixture check exited255 because the MoonBit expected-number literal
1e308 needs the spelling1.0e308. Only that host-language spelling and formatter
layout changed; input JSON1e308 and its expected finite numeric value did not.
Semantic tests were NOTRUN for that candidate. The corrected five-group fixture
was frozen before any product edit. Its first native result was4 passed/1 failed,
exit2,8.730338417 seconds. PJI4 accepted the minimal Object overflow unexpectedly;
later variants in that group were NOTRUN after the first failure. The other four
groups passed; no defect was manufactured in already-correct EOF/escape paths.

The first candidate reused native_result as the constructor, with caller-relative
depth. It fixed the finite member demand but failed PJI2, which had passed before
the edit:26 total,25 passed,1 failed, exit2,14.032675917 seconds. The raw error is
opaque JsonnetError, not a printed per-key vector. Static diagnosis is precise:
native_result binds each field through Var(name), while layer_scope overwrites
self/super/$ with receiver bindings. These names are legal JSON String keys.
The candidate source/input/logs remain intact. No oracle or legal key was removed
to make this route pass.

The final change keeps from_json unchanged and adds a private parseJson-only
read-only finite/depth visitor before the original conversion. It checks actual
Number values throughout the parsed tree, beginning at current VM depth, without
constructing new field environments or touching Jsonnet thunks. Arrays/Objects
are data here; ordinary language Object expressions keep their previous lazy
field rules. Parser/depth scanning, diagnostics, SDK, native_result and YAML
behavior stay byte-identical. Removing only this call/comment and visitor block
reconstructs the entire previous stdlib exactly. This is not a global object or
shared-native conversion change. No old test or reference snapshot changes.

The adjacent native_result name-binding collision remains a separately recorded
implementation risk for its existing native/YAML entry points. This task did
not independently execute those endpoints with reserved keys or repair that
shared helper, so it does not count new passing/failing conformance cases there.
The observed rejected parseJson candidate and source diagnosis should guide a
separate bounded follow-up, rather than widening this input-function repair.

### Current directed result and exact evidence map

The unchanged corrected five-group oracle and required neighbors pass26/26,
failed0, exit0,14.003159917 seconds. The seven files are the new input fixture,
existing six-group JSON contracts, four-group P0 review, two-group JSON/YAML
diagnostics, four-group sequence structure, three-group Object Ex and two-group
Object head controls. This final run justifies affected checks after the product
change; pre-repair existing evidence was reused without a gratuitous repeat.
Every old test file remains byte-identical. No legacy migration was needed.

Input contract map now links signature/default/binding and wrong-head/unused
paths to JC1/JC2/JC4 plus the unchanged common binder; complete value consumption
to the installed EOF check and PJI1; canonical String/Unicode data to JC1/PJI2/
PJI3; all parsed finite members to PJI4 and the new read-only visitor; ordinary
field/resource boundaries to PJI5. This closes that bounded responsibility
relative to its underlying grammar/Number/String children, not an unbounded
parser proof or every public function. Valid canonical JSON data pairs are
separate from raw source quoting and lone-surrogate recovery. No initial BOM
profile, duplicate-key decision or stronger Unicode recovery promise is added.

info then fmt pass, no public mbti changes and all11 final source/test inputs
retain their tested SHA256 bytes.16 old stdlib inspection anchors are unchanged
and outside both insertions; only their full-file hashes rebind. All225 language
evidence/completion fields otherwise equal the preceding map. Only parseJson's
existing public record extends; other66 equal,67 public subsets/zero whole
function acceptances remain. Counts28 named/1 relative constructor/63 partial/
2 unreviewed are not promoted by this source-hash maintenance.

Local evidence: `/tmp/moonjsonnet-parse-json.95je6oxq`. The original/corrected
fixture, baseline, rejected candidate, final inputs, exact source reconstruction
and inspection-span proof remain separate. Commands retain argv, DEVNULL,
300-second bounds, C locale/RUST_LOG=error, raw output hashes and absent groups.

| Artifact | SHA256 |
| --- | --- |
| frozen/spec_parse_json_input_test.mbt | `2a2789f3a380bf427aa4a39ab24f86f71ef5bd1b34ad5db0cc5a2b760ebbaef6` |
| frozen/spec_parse_json_input_syntax_corrected_test.mbt | `b5670db7d32b7eaab017aa043a6b590053824cb9354a2af184239c358faf65fc` |
| baseline/stdout | `a8c04b395a932b7121db23f79f6b48892e20407c7c154945dec7cfe24278e14b` |
| first-repair-stdlib.mbt | `e065e7395739d8704a689849d69a231c05c2b1cf22d65b9193e865eaa7988d8e` |
| final-directed/stdout | `973dbdc45d682ba354c3af785e54f2b9229ec5b1a4df79464defabb29929a7a1` |
| final-corrected/stdout | `87401a4cbc4cddeb67eab1b97b48b8137260b9ed0411d731c7cb3ac2d95c7193` |
| validated-inputs.json | `f0756525ebe9bf0de5b6358ac01385d9b32ffc131279cf6fcd7a3f4bdac7e42e` |
| inspection-rebinding.json | `28483e5de3dbd359390366d8774cdce9dd6b4fa5d48abe6597ae4556462fc184` |

No current full suite, release, SSH/Linux, independent CLI/API or Go/C++ run
occurs here. Old816/816 and Linux228cb25 counts are not inherited by these new
product bytes. No dependency, upstream, private proposal or push operation was
performed. Overall specification conformance remains incomplete; this bounded
JSON-input responsibility ends after evidence/commit closeout.


## Shared returned-data String keys (frozen at8aba1ec)

This follow-up independently checks the adjacent risk left above. Fixed
google/jsonnet bbb38f1020be1f5aed560928fb839b2c448cefb4 language Object
paragraphs305–343 define a mapping from String keys and arbitrary-expression
bracket indexing, with simple-map inheritance replacing only matching fields.
The specification JSON-value grammar2868–2936 admits String-keyed JObject
data without reserving self/super/$. The language353–372 describes self/super
as actual receiver references; a String bearing the same text is data. The
project NativeFunction callback API returns Json, so the same data distinction
applies to its returned object members. parseYaml uses only unambiguous
JSON-compatible Mapping examples here, not an expanded YAML schema promise.

Actual direct callers are Vm.call_native and Vm.parse_yaml. Current parseJson
uses its finite visitor plus unchanged from_json and is a negative control.
The old candidate diagnosis above grouped self/super/$ too broadly: scope
always shadows self/super, whereas it injects $ only when outer.lookup lacks
that binding. This follow-up tests $ independently rather than presuming failure.

Six fixed groups NK1–NK6 separately check native self, native super, the YAML
Mapping entry, dollar/opaque/code-looking String controls including candidate
internal-binding-like names, nested data/closures/simple overlays, and eager
nonfinite rejection versus unused whole calls. Every tree is handmade separately
from source and both Program entries share literal independent expectations.
NK5 runs json then native then yaml; any first-failure loop cutoff is NOTRUN.
Native callbacks return Json data, not language closures: the closure test
captures returned data in ordinary Jsonnet. No key text is evaluated as code.

Frozen plan/oracles and the707-entry base manifest are held in
`/tmp/moonjsonnet-data-keys.2pidvzs6`. No implementation has changed at freeze.
The first test run must preserve all raw failures before repair. Any repair is
limited to the shared converter and must retain recursive eager number/depth
checks, copying, and ordinary language-field laziness. No old assertion or
reference snapshot may change. Scope/stdlib/from_json are outside the repair.
No full suite, release, SSH/Linux, external reference run or push occurs here.


### Independent baseline, minimal repair and direct-entry result

The initial check exited255 because MoonBit reserves the local identifier
member for future use. Renaming only that host-local variable to selected in
NK1/NK2 let check pass; Jsonnet source, handmade trees and literal oracles were
unchanged. That first fixture has no semantic result. The corrected baseline
is6 total,2 passed/4 failed, exit2,7.890883166 seconds. NK1/NK2 each independently
observe String("object") where the literal type oracle requires String("number")
for native {"self":7}/{"super":8}. NK3 independently observes the same self
Mapping failure through parseYaml. These stop on their first source observation;
their later value/full-object/handmade branches were NOTRUN at baseline. NK5
passes its json source/AST control before the native source raises an opaque
JsonnetError; subsequent native/YAML branches were NOTRUN there. No narrower
per-field cause or all-loop coverage is inferred from that opaque output.
NK4 opaque/$ controls and NK6 eager nonfinite/unused-call controls both pass.
The earlier broad $ diagnosis is therefore corrected, not promoted to a defect.

The product diff changes only native_result's Object branch. External keys
remain Literal(String(name)); each eagerly copied/validated value is instead
stored under a fresh $native:<ordinal> private binding, and its field references
that binding. The ordinal advances per unique Map key, so bindings are distinct
regardless of input names, including names that resemble the internal prefix.
They cannot be self/super/$/$std, and the colon is not an ordinary source
identifier. No input name becomes executable code. Reversing these8 diff lines
reconstructs the entire old native.mbt byte-for-byte. Existing recursive Ready
conversion, finite/depth/step checks, value copying and generic lazy fields stay
unchanged. objects.mbt, runtime_types.mbt, stdlib.mbt and parse_yaml.mbt are
byte-identical to8aba1ec. No old test/assertion or Go/reference snapshot changes.

The fixed basis is [String-keyed objects and bracket indexing](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#object)
and [JSON values](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#json_values),
combined with the project's [NativeFunction Json-result API](../reference/API.md).
The fixed specification explicitly leaves std.native environment semantics
external; these host-API observations do not certify that whole public function.
parseYaml uses already-admitted JSON-compatible collection data, while parseJson
retains its independent finite visitor and original from_json constructor.
This is an adapter-data repair, not a change to general self/super/$ semantics,
object assertions, public std receivers or unresolved N0/R0/DF0 contracts.

| Group | Independent observation | Baseline | Final |
| --- | --- | --- | --- |
| NK1 | Native String self selects7 and manifests the same map | Type object != number; later branches NOTRUN | Source/AST exact values pass |
| NK2 | Native String super selects8 and manifests the same map | Type object != number; later branches NOTRUN | Source/AST exact values pass |
| NK3 | YAML JSON-compatible map retains self7/super8 | First self type fails; later branches NOTRUN | Source/AST accesses/full map pass |
| NK4 | parseJson control; $, opaque, NUL/Unicode and inert code/internal-name-like keys | Pass; no $ ordinary-map defect observed | All three entries pass |
| NK5 | Nested data in captured closures/maps; matching right overlay leaves other/original data | JSON dual entry passes; native source error, rest NOTRUN | All three entries/source/AST pass |
| NK6 | Native Inf/NaN, JSON overflow, YAML parsed Inf/NaN under each special-looking key | Pass; unused calls return42, used calls Runtime | Same unchanged eager/lazy criteria pass |

After info then fmt and deny-warn check, the final directed result is37/37,
failed0, exit0,15.388536417 seconds. The eight files are the six new groups,
six native API/copy/error/depth regressions, six YAML public groups, two separate
YAML normative-null profiles, five JSON input groups, six JSON contract groups,
two JSON/YAML diagnostics and four P0 controls. All loops in these six new groups
complete in both entries after repair. Existing host-mutation/cycle/output-limit
cases are reused rather than duplicating those established direct-entry tests.
Formatter changes to the new fixture are layout/trailing commas only; its
corrected frozen oracle and all old tests remain semantically unchanged.
No mbti diff occurs and all13 final source/test inputs retain tested hashes.

Only the two existing public records change: parseYaml gains direct String-key
and adapter-demand evidence; parseJson gains unaffected control witnesses and
updates its separate-risk link. Other65 equal,67 subsets and zero whole-function
acceptances remain. native_result has no existing inspected-source hash binding;
the entire language map, all225 evidence records and completion counters stay
byte-identical. No language-source inspection is silently rebound or broadened.
The public inventory refresh only reflects these mapped inputs/provenance.

Evidence root: `/tmp/moonjsonnet-data-keys.2pidvzs6`. Raw first check, corrected
check, red baseline and green result are separate, with argv/DEVNULL/C locale/
RUST_LOG=error and300-second per-command bounds. All recorded command process
groups are absent after exit. No current full-suite/release/Linux/CLI/API or
Go/C++ result is inherited; no dependency/upstream/proposal/push operation occurs.
Overall specification conformance remains incomplete. This concrete converter
and its two direct consumers are the boundary of this follow-up.

| Artifact | SHA256 |
| --- | --- |
| plan.json | `5f9b95369fb09a8831a5b5dacb08e1884193035defc718d752922f21c19593fc` |
| frozen/spec_native_data_keys_test.mbt | `9f8d995bab7dc32328eda629f792afb070474717a43505fe0650a9be3a5135e0` |
| frozen/spec_native_data_keys_host_corrected_test.mbt | `b4614233f46ecd7b01a0e0c57aec1bde14f17dbaad1953506de5467ced6df29b` |
| frozen/spec_native_data_keys_formatted_test.mbt | `1f40c3d4f36e83a04e0fd4433b13f325f4ff21865009bb359698ae6ddb89547a` |
| baseline/stdout | `de4274ab83c99c98db1c4cd92338fc89e6099c1440f0ea191a1e583ccfdf8a6f` |
| final-directed/stdout | `692831b047c266f17b1e325dce2cd02f863c7390a89daf97c3ab7cd4358b6c8e` |
| validated-inputs.json | `0d791d9ebadc284f8f4a3db29af7faad2098620059547f1ee2f27b7c216f9841` |
| repair-proof.json | `eb374007e6ca45a8209c08acf08985d47ef304019694928d3ad522cd5ead3e10` |
| public-map-delta.json | `3395c941bd8135f1b2cf928968a2974d09bac794ba0d7640d79fe1c4ec9f48e2` |

## JSON Number manifestation continuation frozen at 277ccfe

Base `277ccfe0bf017ec65332a14ca80475dfb8ae0ff2` is the published 0.2.0
tree. This continuation selects only the Number responsibility of
manifestJsonEx and its manifestJson/manifestJsonMinified wrappers. The fixed
[v0.21.0 source Number branch](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1060-L1061)
is `'' + v`; both wrappers forward to Ex. Therefore numeric JSON String
manifestation must agree with the existing ordinary numeric String coercion.
The separate shortest fixed-decimal manifest_number profile currently breaks
that identity, for example `0.1` versus `0.10000000000000001`. This criterion
comes from the fixed source definition, not a preference for a C++ executable.

The independent `spec_json_number_contract_test.mbt` freezes seven groups before
production edits. Every group exercises source and separately handmade public
ASTs with neutral builders. Literal expected Strings are never produced by a
product formatter; JN4 additionally checks the defining coercion relation.
The maximum finite binary64 integer is written in full, and tiny values retain
the scientific text of the existing coercion contract. No numeric conversion
or global formatting policy is changed by this continuation.

| Group | Frozen required outcome |
| --- | --- |
| JN1 | Scalar fractions use independent exact text in positional/named Ex and both wrapper calls. |
| JN2 | Negative zero remains `-0`; exact integers, the binary64 integer boundary, a rounded large integer and both largest finite magnitudes use the existing coercion spelling. |
| JN3 | Small normal and subnormal finite values use independently declared scientific text, including both signs of the minimum positive subnormal. |
| JN4 | Independently expected empty-String concatenation and toString results agree with each JSON Number entry; the relation supplements rather than replaces literal oracles. |
| JN5 | Nested numeric arrays/visible fields retain default, minified and custom layouts, key order and hidden-field laziness. |
| JN6 | Scalar Number does not force erroneous format options; unused calls do not demand erroneous values; demanded scalar/nested explicit errors and arithmetic nonfinite production reject. |
| JN7 | ASCII numeric text and enclosing array/object punctuation fit at exactly their declared byte length and fail at one byte less; std.length isolates the intermediate String budget from outer JSON quoting. |

Reuse `spec_manifest_wbtest.mbt` for direct defensive Inf/NaN Number rejection,
and the existing JSON contracts, output, concatenation and legacy render tests
for adjacent finite/demand/resource controls. JN6 arithmetic overflow does not
by itself prove the defensive internal Number guard. N0/R0 assertions, invalid
Unicode and other renderers remain outside this bounded Number responsibility.
Passing these groups is not whole manifest-function or whole-spec conformance.

The expected unchanged-product failures are JN1 (short fraction text), JN2
(rounded large integral text), JN3 (fixed instead of scientific text), JN4
(coercion identity), JN5 (nested numeric text), and JN7 (numeric byte length).
JN6 is an expected unchanged control. Each group's later loop iterations are
NOTRUN if an earlier assertion fails; no execution result is claimed at freeze.
Preserve old assertions, old CI evidence and first raw failures before any
per-input expectation migration. Production, differential declarations and
generated interfaces remain untouched during this first phase. No test/build,
full suite, external reference run, dependency/toolchain installation, remote
operation, proposal copying, publication or commit occurs at this freeze.

### Independent failure, Number-only repair and preserved legacy conflicts

The unchanged-production native baseline passes the deny-warning check and
runs all seven frozen groups: 1 passed, 6 failed, exit 2 in 9.094 seconds.
JN1-JN5 and JN7 fail for exactly the frozen reasons; JN6 passes. Later iterations
after each first failure remain NOTRUN for that baseline. The earlier published
CLI probe independently records five requirement mismatches and three passing
controls; it is not a new C++ reference run or an additional native group count.

The production change replaces only `write(manifest_number(n))` in the Number
arm with `write(render_json(Json::number(n), false, 0, limit - size, loc))`.
The existing finite guard runs first, and both render_json and the enclosing
writer enforce the remaining byte budget. No formatting thunk is touched.
The shared render.mbt/manifest_number implementation and its other consumers
remain byte-identical. This restores the fixed `'' + v` identity without
changing the ordinary numeric String renderer or deciding a new global format.

Before any legacy migration, the same frozen seven groups pass in a directed
12-file run: 48 total, 44 passed, 4 failed, exit 2 in 19.074 seconds. The four
failures are the old scalar shortest-profile group, its nested group, its
326-byte subnormal budget group, and the numeric row of the legacy JSON style
group. The remaining controls pass, including direct internal Inf/NaN rejection,
ordinary output/coercion, argument/demand checks, YAML and TOML. A group stopped
at its first old assertion does not establish later loop results.

Evidence is retained at `/tmp/moonjsonnet-json-number-contract.tai872qs`:
`native-baseline/initial` contains the original product, legacy tests,
differential declaration and manual map; `native-baseline/receipt.json` and
`test.stdout` preserve the red new-regression run;
`after-fix-before-migration/receipt.json` and `tests.stdout` preserve the green
new regressions together with the four old-profile conflicts. Their raw bytes
are not rewritten by the migration. Published macOS/Linux 0.2.0 differential
artifacts remain separate historical evidence for 277ccfe.

| Input identity | SHA256 |
| --- | --- |
| Frozen new regression, unchanged through repair/migration | `f6dba44e14dff27a1195173d7cc3d4afb189f6406c4133e2a446fa750f50d56a` |
| Original manifest_json.mbt | `319fc7f84c60fd65609af3cc4fbe84bfaa54f4d3107b114a7fca6737f93b08bc` |
| Number-only repaired manifest_json.mbt | `0c763c7da2c9aa91142bd55731f8183464406138b59d6e338343f5fb7b6a0d7b` |
| Unchanged shared render.mbt | `c1920a012c82bb49a4327995df20482c14280715a9677ec2236b757c370f3377` |
| Original render_test.mbt | `de5bec68aa7a01e91b9c4033e04a822752f562f69a560c4e197fe9de63c451e3` |
| Original std_manifest_test.mbt | `5839dce0b2e12d84bb785151e907d59791059fcb0eb2c9d1c71e93bdfdc1e59f` |

### Exact legacy expectation migration

Every source expression remains unchanged. The following String expectations
change because each Number leaf must use the fixed definition's ordinary
coercion; no expected value is copied from a fresh product run. `repeat` below
is the exact old test's zero-repetition expression, and M denotes the exact
maximum finite binary64 integer printed after the table. Unlisted scalar rows,
the independent coercion control, layouts and other legacy assertions stay
unchanged. Only descriptions of the three affected render groups are renamed.

| Existing input or observation | Old expected text/value | New expected text/value |
| --- | --- | --- |
| manifestJson(0.1) | `0.1` | `0.10000000000000001` |
| manifestJson(1e-8) | `0.00000001` | `1e-08` |
| manifestJson(-1.23e-7) | `-0.000000123` | `-1.23e-07` |
| manifestJson(1.234e30) | `"1234" + "0".repeat(27)` | `1233999999999999958672482500608` |
| manifestJson(1000000000000000100) | `1000000000000000100` | `1000000000000000128` |
| manifestJson(5e-324) | `"0." + "0".repeat(323) + "5"` | `4.9406564584124654e-324` |
| manifestJson(-5e-324) | `"-0." + "0".repeat(323) + "5"` | `-4.9406564584124654e-324` |
| manifestJson(1.7976931348623157e308) | `"17976931348623157" + "0".repeat(292)` | M |
| manifestJson({z::error 'hidden',b:-0,a:[0.1,1e-8]}) | `"{\n    \"a\": [\n        0.1,\n        0.00000001\n    ],\n    \"b\": -0\n}"` | `"{\n    \"a\": [\n        0.10000000000000001,\n        1e-08\n    ],\n    \"b\": -0\n}"` |
| manifestJsonEx([-0,0.1,1e-20],'','',':') | `[-0,0.1,0.00000000000000000001]` | `[-0,0.10000000000000001,9.9999999999999995e-21]` |
| length(manifestJson(5e-324)) at exact output_bytes | 326-byte budget returns 326 | 23-byte budget returns 23 |
| Same length expression at one byte less | 325-byte budget raises Limit | 22-byte budget raises Limit |

The maximum integer M is independently `(2^53 - 1) * 2^971`:

```text
179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858368
```

For `1000000000000000100`, binary64 spacing is 128: quotient
7812500000000000 and remainder 100 round upward to 1000000000000000128.
For `1.234e30`, the exact decimal integer is `1234 * 10^27` and spacing is
`2^47 = 140737488355328`: quotient 8768097359279636 and remainder
41327517499392 round downward to 1233999999999999958672482500608.
These are exact integer derivations, independent of either product formatter.
The scientific/fractional spellings retain the existing numeric coercion
contract rather than defining a new parser or general conversion policy.

The current `numeric-string-rendering` differential case keeps its source and
success outcome; its former cpp_difference becomes a literal result equal to
the original frozen reference array. Its nested x value is now
`0.10000000000000001`. The other six difference declarations, all Go fixtures
and historical reports remain unchanged. This declaration edit alone is not
new external-reference execution evidence.

Only the existing manifestJsonEx/manifestJson/manifestJsonMinified manual
records gain JN1-JN7 witnesses. Other 64 records, the language matrix, its
inspection anchors and all completion counters remain unchanged. The Number
clause is verified relative to existing numeric String coercion; none of these
three whole functions or the overall specification is accepted. N0/R0,
invalid Unicode, nonnumeric rendering and other unresolved responsibilities
retain their prior scope. The generated inventory remains its historical
checkpoint rather than silently gaining new runtime evidence.

### Final formatted and directed result

After the expectation migration, `moon info --target native --frozen`,
`moon fmt` and `moon fmt --check` all exit 0 with no generated interface diff.
Formatting changes only line layout and one optional tuple trailing comma in
the new regression; the migrated render test has one layout change. Static
token comparison preserves every String literal and all non-layout tokens
apart from that optional comma. The independent criteria are unchanged.
Preformat copies and command output remain in the evidence root's `format/`.

| Final formatted test | SHA256 |
| --- | --- |
| spec_json_number_contract_test.mbt | `51aee0b4542cb3f39d1690a6907e79acca642ad29303bc3bea3e44d76742bf91` |
| render_test.mbt | `4e1780fd1cd69207bc02800ccc6c4ce64accf8e7b10f744863ded263dfba4ce9` |
| std_manifest_test.mbt | `c5c09aad61f843cec33a26e80a5c2c5fd184fb8925feb8734aee78b6ecca9d14` |

The exact 48-group outline and final native debug run cover the same 12 selected
files: 48 passed, failed/skipped 0, exit 0 in 14.613 seconds. All JN1-JN7
source/handmade-AST iterations and migrated legacy rows complete. The directed
CLI build exits 0 in 3.149 seconds; the unchanged numeric-string-rendering
input matches its exact original reference literal. The same eight frozen CLI
probes now pass 8/8, preserving the original five mismatches and three controls
as separate baseline evidence. Required CLI errors count as expected errors,
not zero exit codes; API JN7 independently requires the Limit category.

`final-directed/receipt.json` retains commands, input hashes and raw output
paths. Its controller takes 21.17 seconds; all recorded process groups are
absent after completion, and all tested input hashes remain stable. The earlier
1/7 baseline and 44/48 pre-migration records remain unchanged. This closes the
verified Number clause relative to the existing coercion contract, with no
whole-function or overall-specification acceptance. No current full-suite,
release, Linux or fresh C++ run is claimed, and old 0.2.0 platform results are
not inherited by these new bytes. Published 0.2.0 remains tied to 277ccfe;
the behavior and text-migration guidance are recorded as Unreleased without
a version bump.

## JSON String values and keys frozen at d0ba232

Base `d0ba232f1d21fc483d8445f75e2fc4dcde0424d3` contains the committed
Number-only correction above. This continuation selects valid Unicode String
values and visible String keys in manifestJsonEx and its two wrappers. The fixed
[escapeStringJson definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L999-L1023)
escapes quote/backslash, uses the short b/f/n/r/t escapes, and emits lowercase
four-digit hex for every other C0 control and codepoints 127..159. Other valid
Unicode, including U+2028/U+2029, remains raw. The same fixed Ex body delegates
both String values and visible keys to that helper. No new malformed-String,
surrogate, raw-byte or source-decoding policy follows from this clause.

The independent `spec_json_string_contract_test.mbt` freezes seven groups with
source and separately handmade AST entries. Quoted expected text is explicitly
written, never obtained from a product renderer or a second escaping algorithm.
Complete C0 and C1 tables are literal fixtures; ordinary Unicode and boundary
characters are controls. The escapeStringJson relation supplements primary
literal assertions rather than supplying their expected values.

| Group | Frozen required outcome |
| --- | --- |
| JS1 | Empty/printable/quote/slash/backslash/HTML/non-BMP/combining controls and every C0 codepoint have independently declared text in Ex and both wrappers. |
| JS2 | Every codepoint 127..159 is escaped using lowercase four-digit hex; U+007E and U+00A0 remain raw controls at the boundaries. |
| JS3 | U+2028/U+2029 remain raw alone, together and among ordinary Unicode; each wrapper returns the exact declared String. |
| JS4 | Visible keys use the same escaping as String values, with sorted keys and exact Ex/default/minified/custom layouts; hidden error fields remain unread and nested Array/Object String values are retained. |
| JS5 | Independently expected escapeStringJson text agrees with scalar rendering; a visible single-key minified object also obeys the fixed helper relation, without evaluating key text as code. |
| JS6 | Scalar String skips error-valued style expressions; unused whole calls skip erroneous values/keys; required input, nested value and key-expression errors propagate. |
| JS7 | Exact UTF-8 byte budgets accept escaped expansion, raw separators, non-BMP data and enclosing key/array punctuation; one byte less raises Limit. Independently declared codepoint lengths are observed through std.length to avoid outer JSON quoting. |

JS7 uses UTF-8 bytes from each literal expected String and checks codepoint
length separately: quoted raw U+2028/U+2029 is 4 codepoints/8 bytes, while quoted
escaped U+007F is 8/8. A compact key containing both is 13 codepoints/15 bytes
with value zero. These are bounded host-resource checks, not a Unicode-policy
or universal resource-equivalence theorem.

### Preserved baselines and bounded repair

Evidence remains under `/tmp/moonjsonnet-json-number-contract.tai872qs`.
The original retained CLI probes in `next-string-baseline/` have three failures
(C1 values, raw separators, visible key) and one ordinary-escaping control pass.
That executable's String helper equals d0ba232's; the Number change is unrelated.

| Native record | Result | Interpretation |
| --- | --- | --- |
| string-native-baseline | 2 passed/5 failed; 7.711 seconds | JS2/3/4/7 text or length failures; JS5 is a harness Limit, not a fifth proven semantic mismatch. |
| string-corrected-baseline | 2 passed/5 failed; 9.584 seconds | JS5 now reaches the exact raw-C1 versus escaped-C1 mismatch on unchanged production. |
| string-after-fix-before-migration | 56 passed/1 failed; 18.370 seconds | All seven String and seven Number groups pass; only the old legacy separator expectation fails. |
| string-final-directed | 57 passed/0 failed; 19.967 seconds | All 14 selected files pass after the single legacy migration and formatting. |

`string-helper-diagnostic/receipt.json` identifies the first JS5 expression at
depth 64 as `Limit: JSON value depth limit exceeded`; the same helper with API
default limits yields the unchanged literal. Only JS5's local assertion helper
uses default depth 200/stack 500, retaining 20000 steps, both entry paths and
every literal/source/AST. Shared sequence_limits and JS7's byte limits stay
unchanged. The wrapper edit was restored before the corrected baseline.
Original fixture copies, raw failures and resource controls remain separate;
later-loop NOTRUN branches in each failed baseline are not retroactive passes.
The final run completes every corrected fixture and migrated legacy iteration.

The only executable repair makes manifest_json_quote call the existing
manifest_text_quote. String/key call sites, Number rendering, sorting, layout,
lazy styles and output guards retain their logic. The shared helper's obsolete
comment is updated afterward; its executable tokens and all other consumers
are unchanged. There is no numeric, YAML/TOML or ordinary-output policy change.

### One exact legacy migration and final identities

Only this std_manifest_test expectation changes. Its source is unchanged:
[Ex delegates String escaping](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1062-L1063),
and [the minified wrapper supplies layout only](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1050).
These are MoonBit expected-String literals: doubled backslashes denote literal
output escapes; single Unicode escapes denote raw characters.

| Unchanged Jsonnet input | Old expected String literal | New expected String literal |
| --- | --- | --- |
| `std.manifestJsonMinified('<>&\u2028\u2029')` | `"\"<>&\\u2028\\u2029\""` | `"\"<>&\u2028\u2029\""` |

The new literal has 7 codepoints/11 UTF-8 bytes, replacing 17 ASCII characters.
JS3 already independently requires it; no fresh product output supplies the
oracle. The original row and conflict remain preserved, with no snapshot update.

| Input | SHA256 |
| --- | --- |
| Original String fixture, JS5 depth-limited | `1d3618f4b1ae0a7b8926c26aaa1a855e51f916b71d6c8e436f6e691e1be0a43d` |
| Corrected frozen String fixture | `d5a61eaa9f17b0d9f71e83d054f68bc82d83f5761e3386d63e6d1c996570a891` |
| Final formatted String fixture | `9f8b3144c6bf6c19327556e2223c09022a4fd2833868c2d7545fe71c18eca6c2` |
| Repaired manifest_json.mbt | `8d27faa615e0d9f18c6708ff04dd6c0d7050eaa8a1fe02e822674442a9e58456` |
| Original shared manifest_text.mbt | `bd43da963aaf94eb4859bfcce19271f3253295bd4787f57e2ff5d151ef788e88` |
| Comment-only shared manifest_text.mbt | `64b60079fcc6a65b1e7037ca5a4c044f2e2383de8321433bd08730694bdccda0` |
| Migrated std_manifest_test.mbt | `77d76bbf83041e9f44f28f9cef263b5ccfe713145b3a7350f9fc163860533e41` |

Info, formatting and format-check pass with no mbti diff. Only the new fixture
changes during formatting: layout and optional trailing commas; all literal
and other executable tokens remain equivalent. Preformat inputs and raw command
outputs remain in `string-format/`. `string-final-directed/receipt.json` binds
these final inputs and the 57/57 result; `cli-binding.json` records the selected
CLI. Its build passes and all four original literal probes pass unchanged.
The controller takes 24.597 seconds, all eight owned process groups are absent
after exit, and tested hashes remain stable. No code/test change follows.

Only the three existing manifest public records gain JS1-JS7 evidence; other
64 records remain byte-identical and the count stays 67. Number evidence,
differential.json and its six remaining declarations, language-matrix counts
and historical reports remain unchanged. This verifies the selected Number
and valid-Unicode String/key clauses, not complete functions or overall
conformance. N0/R0, malformed Unicode and other responsibilities remain open.
No current full-suite, release, Linux or fresh C++ result is claimed. Module
version and published 0.2.0 remain unchanged; no push or publication occurs.
