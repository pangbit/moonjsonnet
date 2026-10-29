# Specification conformance work

## Acceptance contract

The final target is complete Jsonnet v0.21.0 conformance, with normative sources
fixed at Google Jsonnet `bbb38f1020be1f5aed560928fb839b2c448cefb4`:
[language reference](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md),
[specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html),
[standard-library documentation](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html),
and its referenced [source definitions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet).
Go/C++ execution is separate comparison evidence. Explicit normative violations
cannot be waived by compatibility exceptions. Ambiguities and untested behavior
remain unresolved, not passing. This document summarizes project engineering
requirements; current supported and tested behavior is documented in
[compatibility](../reference/COMPATIBILITY.md).

Final acceptance requires:

- Every lexical, grammar, static-checking, evaluation and JSON manifestation rule,
  including finite numbers, Unicode, scope, laziness, inheritance, visibility,
  assertions and imports.
- Every public standard-library contract, including parameter names, defaults,
  return values, errors and when arguments or elements are forced. Reflection
  registration counts include internal helpers and do not prove these contracts.
- A rule-by-rule matrix covering ordinary results, static errors, runtime errors,
  lazy and boundary cases, linked to implementation and executed evidence.
- Native debug/release evidence on macOS ARM64 and Linux AMD64 for the library,
  CLI and environment/monitoring/embedded-application examples. Evidence must bind
  source, toolchain, binary and input hashes. The embedded scenario includes
  parameters, controlled imports, structured results, diagnostic context and
  rejection of invalid parameters, assertions, import escape and resource limits.
- CLI success/output and nonzero failure behavior, formatting with comments,
  binding diagnostics, installable native library, runnable examples, source,
  licenses, attribution and API/CLI documentation.

JS/Wasm, LSP and package management are outside the platform/tool scope. Host
permissions and resource limits do not reduce language or public-library scope.
Historical raw upstream results and failure classifications remain preserved.
Private administrative documents and personal data must not be added to commits.

## Cumulative native delivery (2026-10-29)

The [derived current-source report](../archive/reports/native-cumulative-2026-10-29.json)
records one cumulative local regression, the defect it exposed and its repair.
The first full run aborted in host-hook AST inspection; no aggregate pass count
was available. Private standard wrappers now stay outside public hook frames,
while clean source children retain paired events. The original failure and its
six passing repair controls remain separate from the final **1118/1118** native
debug regression (227.247 s). No other full mode was added.

| Technical delivery | Current conclusion |
| --- | --- |
| Language/library regression and the three P0 examples | Current complete project test entry passed, including immutable deletion, nonfinite rejection, fractional-index rejection and their lazy controls. This establishes executed regression results, not every normative contract. |
| Independent native archive and three scenarios | Eight consumer groups passed against the exact 172-file local archive: four existing API groups, three fixed scenarios and one added direct-API resource/location group. Compiler paths and file hashes excluded registry substitution. |
| CLI, tools and required failures | 24 acceptance cases passed through 27 program invocations: 11 existing cases, four resource boundaries, seven stream/multi-output cases and two formatter cases. Required error kinds/positions and output preservation are checked at their actual API/CLI interfaces. |
| Reproduction and evidence | Source/toolchain/package/binary/input binding is retained. Both existing generators passed; 42 reviewed inspection hashes were rebound and ten stale policy descriptions reconciled without promoting rule states or inventing execution. |
| Linux current revision | After explicit approval, source `6ca452f7be9c80d032fec2e762f1714178e14c78` passed 1118/1118 native debug tests in 624.160 s. Upload, evidence recovery and verified cleanup took 632.298 s in total. Resources stayed at two CPUs, 4 GiB, zero swap and 256 tasks; existing services and tools were preserved. The prior denied attempt did not execute. |

The implementation and local delivery are supported within their documented
profiles. **Unqualified complete v0.21.0 conformance remains unestablished.**
The 94-row labels are review bookkeeping, not 58 absent features: finite
constructor, capture and recursive-transfer responsibilities have explicit
endpoints described below. Remaining limitations are the stated conflicting/underdefined
contracts and incomplete integration of later evidence, not a demand to test
all possible inputs. Existing source-compatible names, XML/YAML defaults,
Base64/count/parity policies and removeAt's same-slot alias extension disclose
what is actually implemented. B0/PE0, non-Boolean filtering, surrogate recovery
and HP0 do not gain universal normative certificates from a passing regression.

The cumulative delivery cohort is complete for these declared native profiles.
The accumulated changes form the 0.2.2 release candidate; version availability,
final CI and a fresh registry installation remain separate release checks.
No new version is published by this validation record.

## Dependency triage at 53e2c49 (2026-10-29)

The current generated matrix has 35 completed named-rule reviews, one completed
constructor review, 56 finite subsets and two unreviewed rows. The following
partition accounts for all 58 remaining rows exactly once. It groups review
dependencies, not missing features; existing implementations and executed
evidence remain usable. Historical checkpoints below retain their original counts.

| Shared responsibility | Exact remaining rows | Next review boundary |
| --- | --- | --- |
| Static scope (9) | chk-self, chk-super, chk-object, chk-object-comp, chk-array, chk-apply, chk-var, chk-local, chk-function | Inspect constructor scope/traversal once and reuse child evidence. Canonical literal field-name uniqueness has a confirmed parser defect described below. |
| Calls and substitution (4) | apply, local, local-var, SUBSTITUTION | Reuse closure/default/binding tests; review environment construction and capture boundaries. Unspecified independent-error order is not a new requirement. |
| Objects and inheritance (9) | object, object-comp, object-index, object-inherit, SYN-OBJECT, DESUGAR-ROOT, DESUGAR-FIELDS, DESUGAR-COMPREHENSIONS, HIDDEN-INHERITANCE | Reuse final-self, lexical-super, root, key and visibility evidence. N0/R0/DF0 are shared interpretation questions, not nine missing implementations. |
| Sequences (5) | array-index, array-concat, makeArray, filter, DESUGAR-SLICE | Reuse index/cardinality/lazy-element controls; inspect shared dispatch and domain checks. Separate A0 and the non-Boolean filter applicability question from established behavior. |
| Boolean/equality applicability (3) | boolean-and-longcut, boolean-or-longcut, primitiveEquals | Retain tested Boolean/primitive domains and explicit B0/PE0 profiles; do not invent stronger domains from comparison output. |
| Type observation (6) | type-null, type-boolean, type-number, type-string, type-function, type-array | Inspect the exhaustive Value dispatch. Invalid producers belong to their own judgments, not a new test campaign for every producer/type pair. |
| Manifestation/coercion (5) | string-concat, manifest-value, manifest-object, manifest-array, JSON-VALUES | Review recursive traversal, visibility and finite scalars using existing output/assertion evidence. Keep core manifestation distinct from source-defined manifestJson. |
| Lexing/syntax (9) | LEX-ENCODING, LEX-NAMES, LEX-NUMBERS, LEX-STRINGS, LEX-TEXT-BLOCK, SYN-EXPR, SYN-CALL, SYN-PRECEDENCE, STATIC-TRAVERSAL | Review token/constructor branches and entry paths; add only missing distinguishing cases. Ordinary/verbatim field-name composition is the first confirmed defect. |
| Imports (1) | CORE-IMPORT | Reuse lazy isolated-import and host-cache evidence. Host callbacks must honor their documented immutable source identity; violating that precondition is not an interpreter counterexample. |
| Scalar/operator/library dependencies (5) | VALUE-FINITE, VALUE-UNICODE, DESUGAR-OPERATORS, EXEC-OPERATORS, EXEC-BUILTINS | Review shared finite/Unicode/operator gates, then actual public contracts. Existing public mappings describe finite evidence, not whole functions. |
| Printed greater-than rules (2) | greater-than-true, greater-than-false | The rule names and cmp signs describe greater-than, but their conclusions print less-than. The fixed numeric prose specifies ordinary IEEE/lexicographic ordering; operators.mbt already uses c > 0. Keep that explicit interpretation without changing correct runtime behavior or claiming a proof of the misprinted equations. |

Completion should use finite constructor/branch review with explicit child
assumptions and distinguishing tests. Phrases such as "every combination" in
older remainder cells are not a demand for infinite input enumeration. A0 and
DF0 similarly retain append and field-value behavior supported by the fixed
guide/source, with the printed discrepancies disclosed. These interpretation
decisions do not silently relabel the generated matrix or remove the complete
conformance target. No matrix state is promoted by this triage.

### First repair: canonical literal field names

Fixed [lexing](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#lexing)
distinguishes escaped and verbatim strings and canonicalizes their values to
codepoints before later rules. In `{"\u0061":1, @"\u0061":2}`, the keys are
`a` and the literal six-character `\u0061`, so they are distinct. At 53e2c49,
parser.mbt correctly decodes the AST key but uses the raw token payload in its
early duplicate-name table, incorrectly rejecting this valid source even when
the whole object is unused. The repair keys that early table by both raw text
and decoded value. Semantic validation continues to check full canonical-name
uniqueness before evaluation. This preserves SyntaxDocument's existing ability
to retain differently spelled duplicate names for source tools, as well as the
raw spelling in existing early-duplicate diagnostics. Dynamic computed-name
collisions retain their runtime boundary.

The fixed C++ parser also compares raw token data at this early check; that
source observation is not a newly executed C++ result or the expected-value
oracle. The normative string rule determines this correction. Frozen Go/C++
fixtures stay unchanged. The focused checks belong in
[spec_literal_field_names_test.mbt](../../spec_literal_field_names_test.mbt);
this repair does not establish complete object or string conformance.

Local native debug verification passed 10/10 groups: four new field-name groups,
three existing quoted-string groups and three parsed-source groups (14.211 s).
The initial test-only compilation errors were corrected with a Json annotation
and a local-variable rename; inputs and assertions were unchanged. Moonc was
v0.10.14+7d59c7ec9, with frozen dependencies, deny-warn and one test worker.
Parser SHA-256: `9e43cb0d10f4b4cf2fcb5782a8ea3d912be060e47f451a869bd896610303de29`.
Test SHA-256: `9f5a3d9081d60355b4d66aa8cc7ae70208ee68afb251053937d00e88509b9581`.
Info/fmt passed; public interfaces and frozen oracles are unchanged. This is a
directed macOS result, not a new full-suite, Linux or complete-conformance result.

### Second repair: inherited sequence-method receivers

The fixed [standard library](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L23)
binds its object-local `std` to `self`.
[flatMap](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L273-L280)
and [foldr](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L771-L777)
use that receiver's dependencies. The language reference's
[inheritance model](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#inheritance)
requires final-self lookup when the inherited field is selected. At 04714ac,
their native overrides instead use the original array length. Static tracing
therefore gives 45 and [1, 2] for the two calls below, contrary to their source
definitions; no pre-repair dynamic result is claimed:

```jsonnet
local derived = std + { length(x): 0 };
[
  derived.foldr(function(x, acc) x + acc, [1, 2], 42),
  derived.flatMap(function(x) [x], [1, 2]),
]
// Required result: [42, []]
```

One private registration now retains and selects the source fallback for
inherited `sort`, `foldr` and `flatMap`; canonical calls still use native bodies.
The new [four-group test](../../spec_inherited_sequence_methods_test.mbt) covers
length overrides, repeated derivation, extracted and forwarded functions,
`super`, lexical `std` shadowing and the differing demand boundaries. In
particular, zero-length `foldr` skips even the callback/input heads, whereas
`flatMap` still performs its explicit function/input type observations. A
native-only field control prevents fallback to lower user definitions.

This repairs a shared object/library dispatch defect without changing public
interfaces or fixed source/oracle files. It does not complete general
substitution, inheritance, the whole `foldr`/`flatMap` contracts or arbitrary
accelerated-method dependency overrides. No generated matrix state is promoted.
The matrix's 14 `objects.mbt` inspection hashes are refreshed only after checking
that the six cited scope, assertion and name/visibility helpers are byte-identical.
Their transfer conclusions retain the same child assumptions; this hash update
does not represent additional execution or newly completed rules.

Local native debug verification passed 8/8 groups: four new source/handmade-AST
groups (10.988 s) and the four existing source-method receiver controls in
`spec_language_object_test.mbt` (0.174 s). Moonc was v0.10.14+7d59c7ec9; runs used
frozen dependencies, deny-warn and one worker. Info/fmt passed, with public
interfaces and all frozen oracle files unchanged. Tested SHA-256 values:

- `objects.mbt`: `b1f9e78dba91c228a0dc4a799c20de6c8e0f94abc1c6dc5c62a8742c7966f9c7`
- `stdlib_layer.mbt`: `bf37d87ebf8e5f2aa66d8a4fb0217d30c6a9f5d9218331d01b13012940a28fbe`
- `spec_inherited_sequence_methods_test.mbt`: `c51245bc23370867b3f995c065b4f898d04f4240b69a3db29de877f012f53634`

The preceding ten field-name checks were not repeated. This is directed macOS
evidence, not a new full-suite, Linux or complete-conformance result.

### Inherited-method follow-up

At c8c40a5, 32 other native accelerators have same-named functions in the fixed
source. Four SHA definitions are Go-only stubs, and `xor`/`xnor` use private
operator bindings rather than the public receiver; those six are unchanged.
The remaining 26 directly or indirectly use object-local `std`. A blanket
fallback would introduce known differences even for `std + {}`, so this batch
adds only 11 methods to the existing private registration:

`join`, `strReplace`, `toString`, `abs`, `lines`, `equals`, `member`, `contains`,
`parseInt`, `manifestJsonEx`, `manifestYamlDoc`.

The [four new groups](../../spec_inherited_standard_methods_test.mbt) give each
method an original-`std`, empty-extension and actual-dependency-override control.
They also cover `lines` through `join`, `manifestJson` through `manifestJsonEx`,
the parser's object-local helper, extracted/forwarded/`super` calls, private
operator bindings and demanded versus unused rendering options. Literal
expectations use both source and independently built AST entry paths. Existing
receiver groups are reused rather than rerun. The native canonical paths,
public interface and frozen source/oracle files are unchanged.

The other 15 are concrete profile reconciliation work, not 15 absent functions.
The following are static source/native observations, not newly executed results
or new acceptance decisions:

| Methods retained on native paths | Known obstacle to unconditional source fallback |
| --- | --- |
| `isEven`, `isOdd` | Fractional Number handling uses truncation in the current native profile and `round` in the fixed source; for 0.5 the parity differs. The existing public prose/source conflict is unresolved. |
| `base64`, `base64Decode`, `base64DecodeBytes` | Negative/fractional byte admission and CR/LF-containing encoded input differ between the native and source paths. Valid-byte receiver examples would not settle these existing profile boundaries. |
| `splitLimit`, `splitLimitR` | Fractional/other-negative limits remain unadjudicated. SPL-R0 also affects valid overlapping separators: unlimited right splitting of `aaa` by `aa` differs from the source's forward-split call. |
| `minArray`, `maxArray` | EXT-A0 concerns String and empty structural inputs beyond the Array-oriented public domain. Native rejection and mechanical source extensions must not change merely because an empty object was added. |
| `startsWith`, `endsWith` | Non-String Array inputs can return false from the source's length comparison while native paths reject them. This is an extension-domain difference, not missing String functionality. |
| `lstripChars`, `rstripChars`, `stripChars` | Empty Array input can return an Array from source while native paths require String input. The existing non-String boundary is not adjudicated here. |
| `manifestTomlEx` | An empty object key is a valid Object input: native output quotes the key, while the source's empty-character-set check produces an unquoted empty key. [TOML permits quoted empty keys and rejects bare empty keys](https://toml.io/en/v1.0.0#keys). Retain the current valid output; any future source fallback must preserve an empty-key guard instead of reproducing this source defect. |

The `base64Decode` and `stripChars` differences above depend on also switching
their respective decoding/stripping callees to source. They are retained as
dependency-group boundaries, not claims that every possible partial source/native
combination already has those differences.

No complete receiver-class, whole-function or language claim follows from the
11-method repair. The generated matrix's review states are unchanged.

Local native debug verification passed the four new groups, failed/unrun zero,
in 14.610 s. Each of the 11 methods has both unchanged-receiver controls and a
distinguishing override result/error. Moonc was v0.10.14+7d59c7ec9; dependencies
were frozen, warnings denied, with one reduced-priority sequential worker.
Info/fmt passed; `objects.mbt`, public interfaces and frozen oracles stayed
unchanged. Tested SHA-256 values:

- `stdlib_layer.mbt`: `e5788d5426a90ec256c063b0110b5fec1a600d3cc4782b0e51f184e883c68f8f`
- `spec_inherited_standard_methods_test.mbt`: `2d6cd47f2026d9919f4e02ce06ca32e3fa4bd0f7f9c661e1dcfbbd59b54b9b7e`

The earlier eight and ten groups, full suites and other platforms were not rerun.

### Profile decisions and wrapper repair

The preceding 15-method inventory is a historical source/native comparison,
not 15 missing functions. The current interpretation gives explicit public
input/output requirements priority over contradictory source branches. Where
the public text leaves a conversion unspecified, a documented project policy
is a choice, not a proof that all interpretations agree. Fixed C++ behavior
must also account for its [native replacement pass](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/core/desugarer.cpp#L858-L886):
raw `std.jsonnet` is not the effective implementation of every method.
For example, C++ replaces `splitLimit`, `join` and `strReplace`. The preceding
receiver tests establish source-level behavior, not new C++ execution results.

| Boundary | Adopted behavior and compatibility consequence |
| --- | --- |
| `isEven` / `isOdd` | Follow the public **integral part** description: truncate then compute parity without narrowing to a host integer. For 0.5, even is true. The fixed source's `round(x)` gives the opposite result; both cannot be promised simultaneously. |
| Unlimited `splitLimitR` | Follow the public right-to-left direction, including overlapping separators: `('aaa', 'aa', -1)` gives `['a', '']`. The fixed source calls forward splitting in this branch and gives `['', 'a']`. Retain correct right splitting rather than reproduce that conflict. |
| Split count conversion | Accept -1 or a finite nonnegative integer. Other negatives reject under the documented -1 sentinel/length bound. Fractions reject as a discrete-count policy. For `('a,b', ',', 0.5)`, raw source would split, while [C++ truncates its native count to zero](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/core/vm.cpp#L1372-L1396). The public prose does not select a fractional conversion. |
| Base64 range and conversion | Reject negative values and values above 255, following the explicit public 0..255 domain. Truncate Numbers within that range toward zero before encoding, following the effective fixed source/C++ path described below. Neither the source's missing lower-bound check nor its `<256` fractional upper-bound extension is adopted. |
| `base64DecodeBytes` input | The public contract specifies padded, line-free output of `base64`. Retain existing CR/LF and unused-pad-bit acceptance as project extensions, not required malformed-input behavior; reject non-Strings. |
| `startsWith` / `endsWith` | Retain the explicitly documented String domain. Incidental Array results from the source's early length comparison are not required String features. |
| `lstripChars` / `rstripChars` | Retain String input for the character-stripping contract and existing String/Array character-set support. Empty Array input to a mechanical source definition is not adopted as an additional return type. |
| `minArray` / `maxArray` | Retain the documented Array domain and reject String/Object inputs. Mechanical source extensions do not require broader admission. |
| `manifestTomlEx` empty key | Preserve `'' = 1` for `{'': 1}`. The source's ` = 1` violates [TOML key syntax](https://toml.io/en/v1.0.0#keys); it is not a valid compatibility target. |

These decisions supersede the corresponding unresolved-policy labels in older
records without rewriting historical results. They do not declare whole
functions conforming or change the acceptance target. At that revision, 13 native
methods still needed demonstrated receiver differences addressed under these
policies; the follow-up below resolves this class without blanket source fallback.

Two wrappers can already use their fixed source bodies safely: `base64Decode`
composes `base64DecodeBytes`, `map`, `char` and `join`; `stripChars` composes
`rstripChars` and `lstripChars`. At that revision, retaining native callees
preserved their input policies while inherited calls observed overrides.
For example, overriding `char`
to return `X` now makes the derived decoder return `X` for `Zg==`; overriding a
strip method similarly affects the wrapper. Canonical calls keep native paths.

The [four new wrapper groups](../../spec_inherited_profile_wrappers_test.mbt)
passed 4/4 in local native debug (11.901 s), using source and handmade AST inputs.
They cover unchanged/empty/overridden receivers, CRLF extension, String admission,
captured and `super` receivers, unused operands and demanded dependency errors.
Info/fmt passed with frozen dependencies, denied warnings and one reduced-priority
sequential worker. Public interfaces, existing tests and frozen oracles are
unchanged. Layer SHA-256:
`9526a223294b1bbcc3524d23f32086c34add7ee0e13a6d6fa0bfd50de8527bc9`;
test SHA-256:
`e4bb35f131961c10bc8f7d3537554abf46625d6ba0b09fa53e3d59c1ef7e6924`.
No old test groups, full suites, other platforms or reference interpreter ran
for this repair. Generated matrix states and complete-conformance status are
unchanged.

### Base64 fractional Number correction

The public byte-Array domain explicitly permits Numbers in 0..255. The fixed
[encoder source](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1291-L1333)
leaves those Numbers intact until bitwise masking. C++ does not replace `base64`
with a native, and its [bitwise operand conversion](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/core/vm.cpp#L3176-L3190)
truncates finite safe-range values toward zero. Thus `[0.5]`, `[1.5]` and
`[254.5]` encode as `AA==`, `AQ==` and `/g==`. These conclusions follow from
static implementation reading, not a newly executed reference interpreter.
The generic numeric specification does not itself spell out fractional
rounding; the effective fixed implementation supplies the conversion within
the explicit public input domain. This settles B64-F0 for that domain.

The repair truncates only Base64 Array Numbers already within 0..255. Values
outside that interval retain rejection, including 255.5 despite the source's
weaker `<256` sanity check. The shared `decodeUTF8` conversion remains integral;
String encoding, non-Number errors and byte forcing are unchanged. The existing
`std.base64([1.5])` rejection assertion is migrated to the independently derived
`AQ==` result with its input retained. Frozen `encoding-base64-reject-fraction`
entries in both Go fixture files stay untouched and remain declared comparison
differences. Historical ungraded numeric observations retain their original
scope and are not retroactively counted as passing tests.

Local native debug passed 5/5 groups in 10.596 s: the
[three new Number-boundary groups](../../spec_base64_fractional_numbers_test.mbt)
and the two directly affected [encoding groups](../../std_encoding_test.mbt).
Literal source/AST expectations cover subnormals, fractional one/two/three-byte
encodings, original bounds before conversion, strict UTF-8 bytes, required tail
errors and unchanged original Arrays. Info/fmt passed under the same frozen,
deny-warn, one-worker settings. Tested SHA-256 values:

- `std_encoding.mbt`: `e39427ae7fccc03b2f32afa6cb26d45ae069d3f21e83eec8f687e180d274ab56`
- `std_encoding_test.mbt`: `34e96edfdc36621608f4c4abc26a9bec0a0639605d3dabb76920774aeba32048`
- `spec_base64_fractional_numbers_test.mbt`: `41ef68d493500feac928cec7b5b522882b408c80d1633a82e94fbe04de5d366e`

The earlier four wrapper groups were not rerun: their frozen files are unchanged,
and the new byte conversion is not used by Base64 decoding or character stripping.
No full suite, remote, release or reference execution was added. Public interfaces
and frozen oracles are unchanged; complete conformance remains unestablished.

### Remaining inherited native profiles

The 13-method follow-up at 7ab5444 separates implementation obligations from
discarded source behavior. `isEven`/`isOdd` retain the documented integral-part
policy; observing the rejected `round` formula is not an additional obligation.
These two retain native behavior. Effective C++ native replacement alone does
not exempt `splitLimit`: as with `join` and `strReplace`, the adopted source-level
receiver contract is implemented while its discrete-count policy is preserved.

The other eleven methods have concrete final-receiver differences on documented
input types. Examples include `substr` overrides in prefix checks, `member`
overrides in character stripping, `__compare` overrides in extrema, and
`objectFields` overrides in TOML rendering. Private local adapters retain the
fixed source bodies while preserving the previously chosen input policies:

- String prefix/strip and Array-extrema guards are lazy parameter views. For
  example, a zero-length override can select `onEmpty` without demanding `arr`.
- Right splitting uses the reverse pipeline for every admitted count, including
  -1. Base64 checks original byte bounds lazily and retains fractional conversion.
- The byte decoder lazily normalizes native-supported input through native
  decode/encode before using the source definition. Canonical input is unchanged;
  CRLF/pad-bit extensions retain their results. An ignored input stays unforced.
- TOML keeps a quoted empty key and lazy Object/String guards. Numeric and String
  output already share the native formatting policy. Depth/output exhaustion
  propagates `Limit`; equivalent internal step/stack costs are not promised.

This review also found an actual shared invocation defect: Closure calls force
supplied/default heads under `tailstrict`, but several native early returns did
not. Native binding now applies that existing public project policy before
dispatch, including extrema's failing default `onEmpty`. Invalid binding still
rejects first; ordinary calls remain lazy and strict calls do not recursively
force argument contents. This is a consistency repair under the documented
policy, not a claim that the fixed specification resolves its `tailstrict` TODO.

The original fixed source, public interfaces and frozen Go/C++ fixtures are
retained. This finishes the implementation classification for these 13 methods;
it does not accept whole functions, generic substitution or full conformance.

Local native-debug evidence covers ten distinct groups: the
[eight new adapter/strict-call groups](../../spec_inherited_profile_adapters_test.mbt),
the existing YAML strict-call group and TOML TI4. The last affected groups
(splitting, TOML and receiver/policy controls) passed 3/3 in 12.036 s; seven
unaffected passing groups were reused after checking their test bodies and
product dependencies. The final product delta since those earlier passes only
adds the `splitLimit` adapter. Info/fmt passed with frozen dependencies, denied
warnings and one sequential worker; public interfaces remained unchanged.

The initial TOML run failed at the helper's depth-64 budget. A diagnostic-only
catch first failed compilation, then exposed `evaluation depth limit exceeded`;
those attempts remain failures. Ordinary TOML correctness now uses the published
default limits. Dedicated output-32 and depth-24 controls remain, with other
limits set to defaults. An additional empty-key/long-String control bypasses the
key-character Array and requires a text-output limit, preserving the original
resource checks. No product limit was increased. Final tested SHA-256 values:

- `stdlib.mbt`: `f8c54ee827295a33de5d035c14bce538db77b9660088da7a6d54ee9f7eb0ed25`
- `stdlib_layer.mbt`: `c12dd3421439f9851f04cd73d43d99d7e4374019b168b8dfd7ff0553f6b432db`
- `stdlib_inherited_profiles.mbt`: `108084f085de62361689218ae009c7b57d813868317d635d85816d2a44e74ebf`
- `spec_inherited_profile_adapters_test.mbt`: `c93a546a5231b478bd952df7deb4aff7a655a883850c49453a8716fbf8d98220`

The eleven dependency groups were then checked against actual remaining work,
without promoting generated matrix rows or rerunning old suites:

| Groups | Current progress and remaining responsibility |
| --- | --- |
| Static scope; lexing/syntax; type observation | Decoded field-name repair is already tested. `validate`/`check_ast_shape` have explicit constructor branches and `value_type` is exhaustive; this read found no additional missing branch. Finite constructor/child transfer review remains distinct from testing every possible AST combination. |
| Calls/substitution; objects/inheritance | The identified accelerated-method receiver class and native strict shortcut defect are addressed above. General binding/substitution review and the N0/R0 assertion model remain separate. |
| Sequences; manifestation/coercion | Existing immutable/lazy/index and rendering evidence remains usable; the adapters preserve the selected input domains and TOML validity. Complete callback/comparator and recursive-child responsibilities are not established by this inheritance batch. |
| Imports | Existing controlled-import/cache/cycle evidence is reused. No new import defect was identified here; mutable host callbacks outside the declared source-identity contract are not a missing interpreter feature. |
| Boolean/equality applicability; scalar/operator/library dependencies | B0/PE0 describe underdefined rule domains. Concrete public-library choices still include `removeAt`'s documented `idx` versus source `at` versus current `i`, XML `Xml`/`XML` spelling, and the YAML-stream false/true end-marker default. These observable interfaces require explicit reconciliation, not more registration counts. |
| Printed greater-than rules | Keep `c > 0`, following the stated operator and ordering prose. The printed less-than conclusion is disclosed; changing correct ordering or enumerating more numeric inputs cannot satisfy both texts. |

N0's right-only `super` rule conflicts with layered inheritance, while R0 lacks
an active assertion-check state; current layered lookup and guarded reentry are
explicit implementation choices. B0's demanded RHS domain and PE0's metavalue
equality domain are underdefined. These concrete conflicts are recorded once,
not multiplied into missing functions or used to block unrelated repairs.
The remaining acceptance work is bounded constructor/public-contract review,
the named/default interface reconciliation above, and a final source-bound
delivery cohort for accumulated post-0.2.1 changes. The older four-mode 1087
records do not automatically cover changed product bytes. No new full-platform
campaign or publication is part of this local repair.

### Named compatibility and finite structural review

The next review resolves the three named/default choices rather than treating
contradictory declarations as three absent functions. `removeAt` retains `i`
and positional calls, accepting documented `idx` and source `at` as aliases of
one required slot. Duplicate slots reject before demand; arity remains two.
A private marker confines normalization to the original standard closure,
including extracted/inherited copies; ordinary and replacement functions keep
their own binding rules. This is an explicit compatible extension. XML retains
the fixed source's existing `escapeStringXML(str_)` export, and YAML stream
retains its `c_document_end=true` default. The latter also agrees with the
documentation's end-marker prose, though not its printed signature. The
[public review](SPEC-PUBLIC-STDLIB-REVIEW.md#removeat-named-parameter-reconciliation)
records the authorities and consequences without claiming both conflicts agree.

Local native debug passed 4/4 groups in 11.458 s: the
[two alias groups](../../spec_remove_at_aliases_test.mbt), the
[migrated binding profile](../../spec_deletion_binding_profile_test.mbt), and
the existing ordinary-default closure control (call group 0). Source and
handmade ASTs cover unchanged positional/`i` calls, aliases, duplicate-slot
rejection before demand, empty-array laziness, strict heads, arity, receiver
capture/forwarding/`super`, and ordinary user functions without aliases. The old
`idx`/`at` error-valued inputs remain: they now reach the same required value
error after successful binding. Info/fmt passed; public interfaces, the fixed
source and all twenty frozen Go fixture files remained unchanged. Tested hashes:

- `eval.mbt`: `d1c9669320bf7d2f8b617795ccc70f84ca25779682ae8b75d42758137e4d4774`
- `stdlib_layer.mbt`: `454d7f6f1a1281e6780f55ac153eeedc0bad1ede0ecc6b885377c5dc3d372dbb`
- `spec_deletion_binding_profile_test.mbt`: `ba4b7505e02e88f5ce1a1b0eacba8944e838d69859876801403882a990071a8c`
- `spec_remove_at_aliases_test.mbt`: `28c88991ae9140e0346307a750da8c304462a550e73eb49b0eaaec89f56223a3`

The finite review endpoint is local constructor/transfer correctness under
explicit child judgments. It covers each current branch and its scope, demand,
failure propagation and recursive edge; it does not require a Cartesian product
of arbitrary child programs or a proof that recursive programs always terminate.

| Responsibility and endpoint | Implementation review and reused distinguishing evidence |
| --- | --- |
| AST shape, scope and traversal | All 19 public constructors and 21 internal constructors (including the two private standard nodes) were checked. [Conversion](../../ast_convert.mbt), [depth traversal](../../ast_depth.mbt) and [validation](../../validate.mbt) visit defaults, arguments, field keys/values, locals, assertion conditions/messages, comprehension clauses and optional slice children. Recursive binding groups are scoped together; object keys use outer scope, bodies use object/local scope, and comprehension scope grows sequentially. Existing static, [forms](../../spec_language_forms_test.mbt) and [handmade AST](../../spec_language_forms_ast_test.mbt) controls distinguish these boundaries. No missing child or scope edge was found. |
| Binding and capture-avoiding environment transfer | [Call environments](../../eval.mbt), [binding validation](../../arguments.mbt) and [lazy local storage](../../runtime_types.mbt) preserve definition environments, caller argument thunks and one complete callee environment for recursive defaults. Binding rejection precedes demand; local groups share their recursive child environment; strict calls force heads only. Existing [call evidence](SPEC-LANGUAGE-CALL-EVIDENCE-2026-10-22.md) distinguishes caller/default capture, mutually recursive defaults, invalid binding and skipped calls. The new alias gate is separately tested; ordinary binding is unchanged. |
| Recursive manifestation and equality | [Manifestation](../../manifest.mbt) checks finite scalars, refuses functions, visits all Array elements and visible Object fields, runs the selected assertion policy and propagates child errors/output limits. [Equality](../../operators.mbt) compares head kind, length/visible key sets and then corresponding children, stopping at a distinguishing difference. Depth accounting is restored on exit. Existing manifestation, equality and object controls establish the child/demand premises. No missing recursive edge or swallowed error was found. |

These local transfer responsibilities are closed under their stated premises.
The call/forms/handmade-form test bytes still match their recorded evidence;
before this alias change, the validation, environment and recursive
implementations were unchanged from the last complete baseline except the
separately verified standard-receiver dispatch. This review adds no mechanical
constructor or recursion test campaign.
Child producer contracts, N0/R0 assertion/inheritance choices and B0/PE0 domains
remain explicit responsibilities of their own rules, rather than an unbounded
"all nesting combinations" remainder. The new alias tests do not certify those
other judgments. Historical matrix counts are not retroactively promoted, and
the final source-bound delivery cohort for accumulated changes remains separate.

### Shared intrinsic dispatch review

The next dependency review inspected the six remaining type observations:
Null, Boolean, Number, String, Function and Array. `value_type` exhaustively
maps these evaluated heads to constant tags; Function covers Closure, Builtin
and Native representations. The intrinsic forces only its argument head and
does not visit nested values, defaults or bodies. Existing
[foundation controls](../../spec_foundation_types_test.mbt) and
[source/AST value-head controls](../../spec_value_heads_test.mbt) support those
boundaries. No missing dispatch branch was found. Arbitrary value producers,
Unicode/finite admission and generic application remain their child obligations,
not additional tag-constructor cases. This was static review without new tests
or changes to the six rows' recorded status.

The review also found 16 stale `stdlib.mbt` inspection references across
`length-object`, `object-has-ex`, `object-fields-ex`, `length-string`,
`length-array` and `type-object`. The exact old source hash
`078d0c869808096e54d1a1bd92196dbc34e19e9ea4fe91e51505e3ea45b96950`
was recovered locally and compared with current
`2bf05de65bc5f755c6b8fcbeeafbf7a1e7dd5844c75c59e9da7150275910240c`.
The differences only change `hypot` parameter names and move TOML into its
dedicated lazy entry. The reviewed intrinsics cannot enter those paths; their
parameters, common forcing block, type mapping and final dispatch are unchanged.
All 16 anchors remain unique. Only these inspection hashes are refreshed;
their child assumptions, scopes, decisions and executed evidence are retained.
The existing metadata generator then completed once (5.426 s) against the three
hash-verified fixed official reference files. Its generated JSON also synchronizes
the preceding 14 object-helper hash refreshes; the Markdown output is unchanged.
Counts remain 35 completed named reviews, one constructor review, 56 partial and
two unreviewed rows, with no execution or complete conformance inferred.

The [2026-10-23 native package regression](SPEC-NATIVE-REGRESSION-2026-10-23.md#later-complete-regression-at-84eb1f7)
records debug and release each passing 713/713 at clean source commit
`84eb1f71d1f408b1aa0bd11526a83b31f51b58d0`, after membership and extrema
corrections. The earlier 672/672 results remain bound separately to 21ee800.
This refreshes local package regression evidence only; matrix coverage,
unresolved contracts and remaining integration/platform requirements are unchanged.

The [local application delivery subset at f23210c](SPEC-NATIVE-REGRESSION-2026-10-23.md#local-application-delivery-subset-at-f23210c)
passed two existing API groups and eleven independent CLI/embedded process cases
against one clean 682-entry source snapshot. This adds current macOS application
evidence only: debug API tests and release executables. It does not establish the
complete 67-case application suite, an independently installed package consumer,
Linux acceptance or a full package regression at f23210c.

The [2026-10-25 Linux record at 228cb25](SPEC-NATIVE-REGRESSION-2026-10-23.md#linux-native-evidence-at-228cb25)
adds same-source debug 734/734 and release 734/734 from separate windows, plus
11/11 existing release CLI/embedded process cases. The first release attempt's
600-second incomplete build and historical cleanup refusal remain preserved;
the successful window used a separately approved 1050-second build followed by
the unchanged complete test command. Source, full private-SDK fingerprints,
raw output, binaries and independent cleanup receipts are bound in that record.
This does not establish complete 67-case application acceptance, a package consumer,
new macOS 734 results, reference parity or full specification conformance.

## P0 normative matrix

This is a focused regression matrix, not the complete final conformance matrix.
All test inputs are synthetic and contain no business data. The first run at
`8e661f9` plus new tests had six groups: five failed, one lazy-boundary group
passed. The rows below identify the corresponding independently reproducible
checks. Files are linked to repository sources rather than private documents.

| ID | Fixed normative basis | Expected behavior and boundaries | Tests | Implementation | First result / corrected result |
| --- | --- | --- | --- | --- | --- |
| P0-IMM | Language reference, Values; stdlib remove/removeAt descriptions | `local a=[1,2,3,4]; local b=std.removeAt(a,1); [b,a]` is `[[1,3,4],[1,2,3,4]]`; aliases, earlier map/slice and chained deletions preserve originals; length does not force payloads | [spec_remove_test.mbt](../../spec_remove_test.mbt), [remove_test.mbt](../../remove_test.mbt) | [current source routes](../../stdlib_layer.mbt), [fixed definitions](../../stdlib_source.mbt), [retained native helper](../../std_remove.mbt) | Original mutated / corrected local regression passes |
| P0-NUM | Language reference, Number | sum/avg overflow is a runtime error at the first invalid addition, including before comparison/type/string consumers or later operands; unused/short-circuited/hidden values stay lazy | [spec_aggregate_test.mbt](../../spec_aggregate_test.mbt), [aggregate_test.mbt](../../aggregate_test.mbt) | [source routing](../../stdlib_layer.mbt), [finite operators](../../operators.mbt), [retained native fallback](../../stdlib.mbt) | Inf/NaN succeeded / corrected local regression passes |
| P0-NUM-OUT | Number requirement and manifestation into JSON | Defensive rejection of internal +/-Inf and NaN by JSON/YAML output paths | [spec_manifest_wbtest.mbt](../../spec_manifest_wbtest.mbt), [spec_yaml_wbtest.mbt](../../spec_yaml_wbtest.mbt) | [manifest.mbt](../../manifest.mbt), [manifest_json.mbt](../../manifest_json.mbt), [manifest_yaml.mbt](../../manifest_yaml.mbt) | Guard added; direct internal-value tests pass |
| P0-IDX | Specification, array-index; language reference, String | Fractional/huge/negative/out-of-bounds indices error before conversion or element access; integral doubles and Unicode code-point access succeed | [spec_index_test.mbt](../../spec_index_test.mbt), [numeric_test.mbt](../../numeric_test.mbt) | [eval.mbt](../../eval.mbt), array_index | Fractional indices truncated / corrected local regression passes |
| P0-SLICE | Specification slice desugaring and std.jsonnet slice definition | Array slices defer indexing errors until demanded; length still succeeds; strings remain strict; fractional end alone may select only integers | [spec_index_test.mbt](../../spec_index_test.mbt) | [slice.mbt](../../slice.mbt), [sequence.mbt](../../sequence.mbt) | Demanded fractional indices truncated / corrected local regression passes |
| P0-YAML | Stdlib documentation's source-defined behavior; std.jsonnet manifestYamlDoc aux | Nested errors and functions at root/array/object/stream levels fail the call; hidden fields remain lazy; no successful partial configuration | [spec_yaml_test.mbt](../../spec_yaml_test.mbt), [toml_yaml_test.mbt](../../toml_yaml_test.mbt) | [manifest_yaml.mbt](../../manifest_yaml.mbt) | Truncated/empty success / corrected local regression passes |

The slice decision follows the source definition's lazy array element expression
and strict string concatenation. It does not impose integer validation on every
slice bound or change unrelated integer conversions. Runtime diagnostic wording
is a tool contract; success versus runtime/static error is normative.

## First-stage evidence and remaining work

The subsequent [independent review and scenario report](SPEC-REVIEW-EVIDENCE-2026-10-22.md)
records full native release and focused CLI/application validation. The latest
[P1 stage](SPEC-P1-EVIDENCE-2026-10-22.md) records the approved function-length
fix, unique formal parameters, CRLF empty text-block lines and import isolation.
The subsequent [chomp and public-inventory stage](SPEC-CHOMP-EVIDENCE-2026-10-22.md)
resolves the final-CRLF boundary and maps official candidate signatures separately
from registration, with unknown coverage retained.
The [foundation stage](SPEC-FOUNDATIONS-EVIDENCE-2026-10-22.md) independently
reviews ten type/numeric/array contracts and corrects range endpoint narrowing;
its table separates reviewed dimensions, oracle corrections and unresolved cases.
The [array-combinator stage](SPEC-ARRAY-COMBINATORS-EVIDENCE-2026-10-22.md)
reviews five adjacent contracts, fixes fold/flatMap forcing and preserves
unresolved cardinality/predicate observations without granting passing status.
The [object-contract stage](SPEC-OBJECT-CONTRACTS-EVIDENCE-2026-10-22.md) reviews
six visibility/lookup functions, distinguishing structural reflection, selected
field assertions and lazy defaults without changing product implementation.
The [string/Unicode stage](SPEC-STRING-CONTRACTS-EVIDENCE-2026-10-22.md) reviews
seven public contracts and fixes fractional char IDs plus substring clipping and
guard/index forcing. Its newer source stays separate from frozen af188da Linux work.
The [language-clause stage](SPEC-LANGUAGE-EVIDENCE-2026-10-22.md) adds independent
function/default and object/assertion/JSON checks without changing the interpreter.
Its [language matrix](SPEC-LANGUAGE-MATRIX.md) enumerates 70 named inference
rules plus 24 initial prose/grammar obligations, with manually reviewed assertion
subsets and explicit unreviewed dimensions; full prose/desugaring decomposition
and conformance remain pending. [Go/C++ status](SPEC-LANGUAGE-COMPARISON-2026-10-22.md)
is separate from normative execution results.
The [recursive-binding/comprehension continuation](SPEC-LANGUAGE-FORMS-EVIDENCE-2026-10-22.md)
adds 15 assertion groups plus 30 source CLI checks for two formerly unreviewed
rules and adjacent scope/forcing dimensions. The focused single-worker affected
run passes 44/44 without a product fix; the matrix now has 43 partially reviewed
rows and 51 unreviewed rows. This does not change the public-stdlib coverage count.
The [application entry-path batch](SPEC-LANGUAGE-CALL-EVIDENCE-2026-10-22.md)
adds seven groups for handmade calls, recursive closure defaults and callee
forcing, validated by 29/29 affected checks and a 15/15 source CLI corpus.
These extend already partial rows; the 43/51 matrix and stdlib counts are unchanged.
The subsequent [chk-importstr review](SPEC-IMPORTSTR-STATIC-EVIDENCE-2026-10-22.md)
closes that premise-free static judgment using constructor analysis and 16/16
focused checks. The matrix now distinguishes one completed named rule, 43
partial rows and 50 unreviewed rows. Runtime import obligations and whole-language
acceptance remain incomplete; public stdlib counts do not change.
The [binary byte-substitution review](SPEC-IMPORTBIN-BYTES-EVIDENCE-2026-10-22.md)
at `10982a4` adds four virtual-import groups and passes one affected 26/26 native
debug run. It completes the bounded importbin byte-value sentence, including all
256 values through source and handmade AST; the broader CORE-IMPORT row remains
partial with explicit loading/cache/error-policy gaps. The adjacent chk-import
and chk-importbin static judgments reuse the shared constructor argument and
existing creation controls, rather than adding duplicate tests. The matrix now
records three completed named static judgments, 42 partial rows and 49 unreviewed
rows, with no new inventory rows or interpreter/API changes. Public stdlib counts
remain unchanged.
The [importstr UTF-8 review](SPEC-IMPORTSTR-UTF8-EVIDENCE-2026-10-22.md) at
`baf115c` adds four source/handmade-AST virtual-byte groups and passes 17/17
affected native debug checks after correcting a test-only host adapter. It
reviews BOM-free text substitution and strict malformed-byte rejection while
separating host diagnostic/cache observations from normative requirements.
Initial-BOM interpretation remains explicitly unknown. The 3/42/49 matrix,
stdlib counts and product/public interfaces are unchanged; CORE-IMPORT still
lists its broader loading, caching and host-policy gaps.
The subsequently released [approved Linux window](SPEC-LINUX-AF188DA-EVIDENCE-2026-10-22.md)
validated only the frozen af188da archive: native debug/release each 425/425,
CLI/application checks 59/59, with completed cleanup. This is not a Linux result
for the newer string/Unicode or language-stage source.
The counts below retain the original first-stage scope.

P0 fixes are local commits `001679a` (immutability), `dd3b9d0` (finite aggregates),
`ece4ff1` (integer indices/lazy slices), and `069b9de` (YAML errors).
Affected native debug suites passed 18/18, 27/27, 24/24 and 18/18 respectively;
these overlapping suite totals must not be added. Zero-warning checks passed,
and generated public interfaces did not change.

The baseline failure log is retained locally at
`/tmp/moonjsonnet-spec-p0.YGGswy/before.log` (SHA-256
`007fc185681075461aa34914b7235cff126160dbe507f245ea2e0dd9ec9a57c1`).
The previous read-only audit remains at its original temporary path, unchanged
(assessed-results SHA-256
`5aa933e4fdb0580760e00a0ebf8975dac2be8df838c88c3806a78f1de1eb47cf`).
Temporary evidence is local and is not an archival delivery guarantee.

Full acceptance remains pending. The first broader debug run found two existing
Program/parameter tests still expecting input mutation; their expected results
were corrected to the same immutable-array rule. The subsequent full native debug
run passed 336/336. Focused native release regressions passed 8/8, the extracted
archive consumer passed 31/31, and documentation validation passed 107 files and
530 links. These were macOS ARM64 results only; full release and CLI scenarios
were then pending and are covered by subsequent source-bound stage reports.
Linux and fresh Go/C++ runs remain pending for the changed implementation.

P1 must enumerate every language rule and public standard-library entry, rather
than treating the 163-member reflection inventory as the public contract list.
For each row, record source/expected/test/implementation/result, and explicitly
mark missing normal/error/lazy/boundary coverage as untested. In particular:

- `removeAt`'s documented `idx`, C++ source `at`, and current `i` are an unresolved
  named-argument conflict; this batch does not select a new signature.
- `std.length(function(a,b=1)a)` has now been adjudicated to require 2 under the
  fixed public documentation and fixed in `2cee5de` after the user's exact
  confirmation. The previous approval blocker is resolved. See the
  [contract review](SPEC-CONTRACT-REVIEW.md).
- `std.manifestJson({assert false})` is distinct from top-level manifestation;
  this batch preserves both existing paths and does not invent an assertion rule.
- Existing Go/C++ fixtures and historical exception reports are unchanged. Fresh
  differences caused by the normative fixes must be recorded separately on rerun.

No Linux upload/execution, database access, remote push, tag, publication,
toolchain upgrade or dependency upgrade is part of this stage. Linux execution
scope and host authorization remain for the parent task to arrange.


## Stage inventory after 0d06ded

The [current macOS native debug run](SPEC-NATIVE-REGRESSION-2026-10-23.md#macos-native-debug-regression-at-0d06ded)
passes816/816, exit0, skipped0 at clean0d06ded (703 inputs). No product or test
bytes changed in this closeout; old failures and migrations remain preserved.
This refreshes regression evidence, not whole-language acceptance.

| Initial P0 responsibility | Current implementation and regression status |
| --- | --- |
| IMM | Original arrays/aliases remain immutable through source remove/removeAt and map/slice compositions; original P0 and complete deletion responsibility tests pass in this run. The named idx/at/i conflict is separate. |
| NUM | sum/avg source reductions and finite operators reject actual nonfinite arithmetic at its producing step; unused expressions, short circuits and hidden fields stay lazy. Addition/coercion, non-Array admission and required foldl consumers are included. |
| NUM-OUT | Defensive internal Inf/NaN rejection in JSON/YAML remains tested; output checks do not substitute for producer checks. |
| IDX | Ordinary Array/String access rejects invalid fractional/huge/negative/range indices and retains Unicode codepoint units. Broader source-defined removeAt admission did not change ordinary indexing. |
| SLICE | Array slice indexing remains deferred until demanded, with length and strict String boundaries preserved. |
| YAML | Nested visible errors/functions cannot return successful partial text; hidden payloads remain lazy. The later option-demand correction and scoped strict dispatch are covered by current directed and full tests. No new swallowed-value defect was manufactured. |

These six scoped regressions are repaired at the current source; no remaining
confirmed initial-P0 implementation failure is recorded. Later sort, member,
extrema, deletion and aggregation repairs also have independent red/green
evidence and current regression coverage. Zero unconditional whole-function
acceptances does not mean those implementations or passing subsets are absent.
The language matrix still has28 named-rule reviews,1 constructor review relative
to children,63 partial rows,2 unreviewed rows and225 evidence IDs; child assumptions
and complete_conformance=false remain unchanged.

### Public evidence rather than registration counts

The [153-candidate inventory](SPEC-PUBLIC-STDLIB-INVENTORY.md) and
[66 exact manual records](../../tests/spec-public-coverage.json) identify every
currently mapped subset and its N/E/L/B assertions. The candidates retain both
XML spelling variants;153 is not153 resolved full contracts. There are87 entries
without a public manual contract record, grouped exhaustively below.

Unmapped is not proof of no implementation, no tests or no independent evidence.
In particular objectHasEx/objectFieldsEx already have independent language-rule
transfer reviews, primitiveEquals has bounded PG evidence, and hypot/parseYaml
have direct finite-producer controls in spec_review_test. Host native references
can instead be test instrumentation. Other literal candidate references require
assertion review before they earn coverage. This inventory does not falsely
classify all87 as zero-evidence functions or promote those cross-domain witnesses
to complete public contracts.

| Unmapped public-record family | Count | Exact candidate names |
| --- | --- | --- |
| Configuration, rendering and host | 12 | extVar, native, trace, format, toString, parseYaml, manifestIni, manifestPython, manifestPythonVars, manifestToml, manifestTomlEx, manifestXmlJsonml |
| String, byte encoding and paths | 17 | asciiLower, asciiUpper, base64, base64Decode, base64DecodeBytes, decodeUTF8, encodeUTF8, equalsIgnoreCase, escapeStringBash, escapeStringDollars, escapeStringJson, escapeStringPython, escapeStringXML, escapeStringXml, resolvePath, strReplace, trim |
| Sequence, predicates and sets | 15 | all, any, count, filterMap, find, isEmpty, mapWithIndex, repeat, reverse, set, setDiff, setInter, setMember, setUnion, uniq |
| Object projections | 6 | mapWithKey, objectFieldsEx, objectHasEx, objectKeysValues, objectKeysValuesAll, objectValuesAll |
| Type, equality and logic | 10 | assertEqual, equals, primitiveEquals, isArray, isBoolean, isFunction, isObject, isString, xnor, xor |
| Numeric domain and arithmetic | 25 | acos, asin, atan, atan2, clamp, cos, deg2rad, exp, exponent, hypot, isDecimal, isEven, isInteger, isOdd, log, log10, log2, mantissa, mod, modulo, rad2deg, round, sin, sqrt, tan |
| Digest conditional scope | 2 | sha256, sha512 |

The66 recorded subsets plus87 unmapped public records partition the153 candidates
without double-counting shared language obligations. The precise count with no
independent assertion anywhere is not established by this map; an absent textual
reference is insufficient, especially for dynamically constructed Ex calls.

### Shared normative questions, counted once

| Question class | Current decision and existing source |
| --- | --- |
| Printed formula conflicts | [A0](SPEC-SEQUENCE-STRUCTURE-2026-10-22.md): array-concat drops e0 in its conclusion despite append prose/library; [DF0](SPEC-ADDITIVE-FIELDS-2026-10-23.md): ordinary-field lowering uses key e as value instead of rhs e-prime; [greater-than](SPEC-RELATIONAL-SIGN-2026-10-23.md): printed cmp-sign conclusions conflict. Behavioral witnesses do not silently repair formulas. |
| Inheritance and assertion model | [N0/R0](SPEC-OBJECT-ASSERTION-ADJUDICATION-2026-10-22.md#complete-shared-assertion-domain-review-atf3871b8): right-only super prefix conflicts with the layered guide; assertion prefix/checking-state rules are missing. Agreed flat demand stays distinct from conditional inheritance/reentry profiles. |
| Underdefined applicability | [B0](SPEC-REMOVE-SEARCH-2026-10-25.md#b0-closeout-and-pivot) does not state the longcut RHS domain; [PE0](SPEC-PRIMITIVE-EQUALS-2026-10-22.md#subsequent-bounded-applicability-review) does not define metavalue equality/application domain. Conditional alternatives are not unconditional pairs of contradictory public promises. |
| Public documentation/source conflicts | [removeAt idx/at and current i](SPEC-PUBLIC-STDLIB-REVIEW.md#removeat-named-parameter-candidates), XML spelling, Stream end default false/true, isEven/isOdd integral-part/round and digest Go-only/stub scope remain unresolved in the existing public review. [HP0](SPEC-INTEGER-PARSERS-2026-10-23.md) covers parseHex punctuation aliases. |
| Unspecified details versus missing tests | [tailstrict TODO and call boundary](SPEC-YAML-DEMAND-2026-10-25.md#bounded-shared-call-follow-up-frozen-at-6569b9f), unrelated-error winner order and exact native callback counts cannot be invented as stronger public promises. Unreviewed input/encoding/numeric/resource cases remain evidence gaps; they are not all specification conflicts or implementation failures. |

These questions remain explicit; they are not normative waivers and are not
recounted for every dependent standard-library function. Go/C++ agreement cannot
settle them. No conflict branch is reopened by this status inventory.

### Recommended bounded batches and acceptance gates

1. Highest-value semantic batch: parseYaml's complete public input/return/error/
   demand responsibility. Reuse existing parser/finite diagnostics first, then
   freeze only missing independent ordinary, malformed/multiple-document, nested
   finite, type/binding, unused-call and resource cases within the fixed contract.
   Stop when that matrix is mapped and any demonstrated defect is repaired with
   unchanged-oracle directed regression; unsupported or contradictory source
   clauses stay explicit. No general YAML-format or new parser feature campaign.
2. Next risk group: encodeUTF8/decodeUTF8 and byte/String/base64 boundaries for
   configuration transport. Separate valid Unicode/byte contracts, error/demand
   and aliasing from unresolved malformed raw-text rules. Then cover the other
   configuration manifests' success-versus-error/output responsibility as a
   distinct batch; do not treat candidate references as evidence.
3. Sequence/object/type groups follow by shared implementation risk, reusing the
   existing Ex, primitive and combinator evidence before adding tests. Math and
   digest work needs independent numeric expectations and conditional API scope;
   it must not copy a reference implementation's outputs. Each batch ends at a
   finite signature/value/error/lazy/boundary map with actual source-bound results.

For delivery, use a stable source boundary rather than another environment loop:
if the next chosen parseYaml batch changes production, complete it and one
combined local debug regression before freezing the new source for macOS release
and Linux debug/release plus controlled API/CLI/embedded checks. If it needs no
production change, current0d06ded product bytes already supply that freeze point.
Schedule one same-source cross-mode/platform cohort, binding inputs/toolchain/
binaries and retaining failure, timeout and cleanup evidence. It must separately
close the full67-scenario application and independently installed consumer gaps;
the old11-process subset cannot establish those. Old228cb25 Linux734/734 evidence
is historical, not coverage of current product bytes. This turn starts none of
those validations or new semantic batches and returns for coordinator assessment.


## Input-converter cohort checkpoint at1a46122

The bounded parseYaml root, parseJson finite-data and shared native/YAML
String-key work is now closed for this batch. Its original failures, scope
limits, independent oracles and justified migrations remain in the linked
contract records. The subsequent [same-source macOS native debug regression](SPEC-NATIVE-REGRESSION-2026-10-23.md#macos-native-debug-regression-at1a46122)
passes835/835, failed/skipped0, exit0 on the fixed708-entry source. No product
or test changes were needed during full validation.835 package regressions
include conditional profiles and are not835 normative judgments.

This checkpoint supersedes only the earlier stage inventory's next parseYaml
batch and source-freeze recommendation: that finite batch is complete, the
current public map is67 subsets plus86 unmapped public records, and zero whole
functions are promoted. All225 language evidence records, shared disputes and
whole-conformance incomplete status remain unchanged. Unmapped public records
still do not prove absence of implementations or independent assertions.

Freeze1a46122 product/test/package/executable-README bytes for later release and
Linux scheduling. Reuse the existing reviewed minimum workflow with fresh
source/toolchain identity and adequate complete-test budget; do not inherit
228cb25 Linux results or silently reuse its near-exhausted120-second test cap.
No archive, SSH, release, standalone application/consumer or new semantic-domain
run starts here. The coordinator assesses that next cohort after this result.

## Same-source platform checkpoint at 97f0938

The [source-bound validation cohort](SPEC-NATIVE-REGRESSION-2026-10-23.md#same-source-validation-cohort-at-97f0938)
now records complete Linux debug F1 and release B, each 835/835 with zero failures
or skips and exit 0, plus D1's independent API 2/2 and CLI/embedded subset 11/11.
All Linux runs used the original 708-entry `9bdacec` archive, whose tree exactly
matches `97f0938` after the commit-message-only rewrite. macOS debug 835/835 was
actually run at `1a46122`; only two non-executable documentation records differ
from that source. Product, test, package, executable README and interface bytes
are unchanged. These are separate runs, not one combined test count.

The earlier A fingerprint failure, A2 timeout without statistics, and D1 partial
root diagnostic remain preserved. F1 supplies complete debug evidence; it does
not retroactively turn those attempts into passes. Evidence recovery, hash
verification and owned-process/directory cleanup have completed. This checkpoint
supersedes only the preceding recommendation to schedule this Linux cohort.
Current-source macOS release, all 67 application scenarios and a separately
installed package consumer still require their own acceptance; the 11-process
subset and in-package API examples do not establish them.

The fixed normative revision remains `bbb38f1020be1f5aed560928fb839b2c448cefb4`.
The [public review](SPEC-PUBLIC-STDLIB-REVIEW.md) still has 67 mapped subsets and
86 candidates without a manual public-contract record, out of 153 candidates;
zero unconditional whole-function acceptances are claimed. The
[language matrix](SPEC-LANGUAGE-MATRIX.md) retains 28 completed named-rule reviews,
one relative prose-constructor review, 63 partial rows, two unreviewed comparison
rules and 225 evidence IDs. The initial prose inventory is not an exhaustive
completed decomposition. Missing mapping does not prove a missing implementation
or an absence of independent assertions; these counts are not a conformance rate.

The scoped original immutability, finite-number/output, integer-index, lazy-slice
and YAML-error repairs are included in the tested source. No still-unfixed
original P0 defect is currently confirmed. The [shared normative questions](#shared-normative-questions-counted-once),
conditional profiles and unreviewed contract boundaries remain open and are
counted once, not once per dependent function. Overall specification conformance
remains **incomplete**. This documentation closeout adds no implementation,
oracle, matrix record, new test execution or new remote campaign.

## Base64 byte-domain correction after 2d34a66

The [bounded base64 contract record](SPEC-BASE64-CONTRACT-2026-10-26.md) adds an
independent String/codepoint-to-byte review. The unchanged fifteen groups first
passed 10 and failed 5: String codepoints 128..255 were incorrectly encoded as
UTF-8 bytes. The scoped String conversion repair passes 15/15 with the same
expectations, plus the existing encoding 2/2, argument 1/1 and scalar 4/4 groups.
The eighteen negative/fraction observations are unchanged and remain ungraded;
B64-R0/F0 are unresolved. One legacy `base64('é')` expectation migrates from
`w6k=` to `6Q==` with its fixed-definition derivation and original result retained.

The record binds directed-run and subsequently formatted test hashes separately;
product bytes and all public interfaces are unchanged by formatting. The later
[complete macOS native debug run](SPEC-BASE64-CONTRACT-2026-10-26.md#complete-macos-native-debug-regression-at-5ae6aab)
validates final `5ae6aabf4150fcf1e9114555f94d9e9419ac6249` and its 711 committed
inputs: actual 851/851 passed, failed/skipped 0, exit 0 in 152.930s. The eighteen
profile observations remain ungraded, with B64-R0/F0 unresolved. Input hashes
and clean repository state stayed stable, and all owned processes exited.
The earlier 835-test platform cohort is historical for this changed implementation;
current release, Linux and standalone CLI/API results are not claimed.
Generated inventory counts above remain checkpoint-specific; this closeout adds
the linked scoped evidence without regenerating that snapshot or promoting a
whole function. Overall specification conformance remains **incomplete**.

## Canonical Base64 decoding after b60c035

The [decoder contract record](SPEC-BASE64-DECODE-CONTRACT-2026-10-26.md) follows
the fixed definition that maps each decoded byte through `std.char`. Its twelve
independent groups first passed 6 and failed 6: `base64Decode` incorrectly
interpreted those bytes as UTF-8. The scoped final String conversion now passes
12/12 with unchanged independent expectations, including all previously blocked
C08/C09 source/AST and length branches. The original failures and historical
NOTRUN branches remain recorded.

The same 714-input candidate passed migrated encoding 2/2, encoder contract
15/15, argument 1/1 and String-scalar 4/4 groups, with check and all directed
commands exiting 0 in a 17.861s window. The 48 observations are byte-identical
to baseline and earn zero normative passes. Only two legacy decoded-String
expectations migrate with fixed-definition evidence; the shared Base64 parser,
byte decoder and explicit UTF-8 operations are unchanged. B64D-M0/A0, malformed
UTF-8 profiles and encoder B64-R0/F0 remain separate unresolved boundaries.

This adds bounded contract evidence without regenerating the historical inventory
or promoting a whole function. The subsequent
[complete macOS debug regression](SPEC-BASE64-DECODE-CONTRACT-2026-10-26.md#complete-macos-native-debug-regression-at-5afcbea)
binds `5afcbea099c2b79e96d5ffcce4a375cbdf1b90b6` and 714 committed inputs:
actual 864/864 passed, failed/skipped 0, exit 0. Compilation/execution took
141.812s, with stable inputs, a clean index/worktree and independently confirmed
process exit. The 48 decoder and 18 encoder observations remain ungraded.
Release, Linux, independent CLI/API and installed-consumer validation are still
NOTRUN for this source. The next delivery checkpoint holds product semantics
fixed while preparing those same-source checks; other normative gaps remain in
the matrix. Overall specification conformance remains **incomplete**.

## JSON manifestation clauses after d0ba232

The [existing JSON contract record](SPEC-JSON-CONTRACTS-2026-10-23.md#json-number-manifestation-continuation-frozen-at-277ccfe)
records the Number correction committed at `d0ba232` and the subsequent
String/key correction. All three JSON wrappers now follow the fixed source's
ordinary numeric String conversion and escapeStringJson policy for valid
Unicode values and keys. Independent literal regressions preserve the original
failures, the JS5 harness-depth correction and each exact legacy migration.

Current directed evidence is 57/57 native debug groups across 14 explicit files,
including both seven-group regressions, plus four unchanged local CLI probes.
Only the three existing manifest public-coverage records gain this evidence;
other 64 records and language-matrix completion counts remain unchanged. This
verifies the selected Number and valid-Unicode String/key clauses, not complete
manifest functions or global numeric/Unicode policy. N0/R0 and other unresolved
responsibilities remain open. No current full-suite, release, Linux or fresh
C++ result is claimed, and published 0.2.0 remains unchanged. Overall
specification conformance remains **incomplete**.

## Combined native checkpoint at 7672947

[Full local native debug and release](SPEC-NATIVE-REGRESSION-2026-10-23.md#combined-macos-native-regression-at-7672947) each pass 890/890 on clean `7672947367912ea8a66acdb6ea136d5da0ec5e22` and its 719 tracked inputs.
This includes cumulative [JSON Number/String/key](SPEC-JSON-CONTRACTS-2026-10-23.md) and [YAML Number/bare-key](SPEC-YAML-DEMAND-2026-10-25.md) corrections; the original failures and published 0.2.0 evidence remain intact.
This is package regression evidence: separate integration/differential/API/CLI/Linux validation and publication remain NOTRUN for this checkpoint. Stream default and other normative gaps remain NOTPASS; whole-function and overall specification acceptance remain **incomplete**.
