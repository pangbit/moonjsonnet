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
