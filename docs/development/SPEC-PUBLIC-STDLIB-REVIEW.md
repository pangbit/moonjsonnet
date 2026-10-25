# Official public standard-library contract review

The [complete candidate-name inventory](SPEC-PUBLIC-STDLIB-INVENTORY.md) is
derived from fixed Google Jsonnet commit
`bbb38f1020be1f5aed560928fb839b2c448cefb4`, not from Go's registration list:

- [Official public documentation](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html): individual headings and the inline type/math declarations.
- [Official source definitions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet): top-level function exports, excluding the six __ helpers.
- [Fixed specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html): native, modulo, primitiveEquals, objectHasEx and objectFieldsEx also have explicit rules/descriptions. Formal metavariables do not define public parameter names.

The union has **153 candidate identifiers**, including the unresolved
escapeStringXml/escapeStringXML spelling pair. This is not a count of accepted
functions or resolved independent contracts. The properties pi and thisFile are
listed separately. The specification's cmp comparison relation is retained in
the JSON appendix; its explicit TODO to introduce it does not establish an
ordinary public callable. Its classification must not become a passing claim.

The six source helpers are __compare, __compare_array, __array_less,
__array_greater, __array_less_or_equal and __array_greater_or_equal. Go reflection
also includes $flatMapArray and $objectFlatMerge. These eight internal helpers
are separate from public contracts. The additional Go id member is not declared
as a public export in these fixed sources; it remains a reference-only extension
entry. Its presence does not establish a normative requirement or exemption.
The original 163-member Go reflection fixture is unchanged and was not rerun.

## Coverage meaning and reproduction

The [JSON inventory](spec-public-inventory.json) preserves each source's spelling,
signature and location independently. It also maps existing test-reference
candidates. A reference can merely reflect a function, be an unused value, or
assert a Go-specific result. It therefore never earns coverage by itself.
Literal scanning excludes the frozen comparison JSON and can miss dynamic
calls; manually inspected digest_test references are included separately.
No direct reference found means exactly that limited search result, not proof
that no test exists anywhere.

N/E/L/B in the table are normal/error/lazy/boundary dimensions. R means only the
specific assertions reviewed against the fixed contract in
[manual case mappings](../../tests/spec-public-coverage.json). U means that
dimension remains unreviewed/unmapped. Sixty-five functions currently have reviewed
subsets, including the ten independent [foundation reviews](SPEC-FOUNDATIONS-REVIEW.md)
and five [array combinators](SPEC-ARRAY-COMBINATORS-REVIEW.md), plus six
[object visibility/lookup functions](SPEC-OBJECT-CONTRACTS-REVIEW.md) and seven
[string/Unicode functions](SPEC-STRING-CONTRACTS-REVIEW.md), plus
[two finite rounding subsets](SPEC-MATH-ROUNDING-2026-10-23.md) and
[four JSON input/output subsets](SPEC-JSON-CONTRACTS-2026-10-23.md) and
[a mergePatch data/demand subset](SPEC-MERGE-PATCH-2026-10-23.md) and
[three integer String parser subsets](SPEC-INTEGER-PARSERS-2026-10-23.md) and
[a prune removal/demand subset](SPEC-PRUNE-2026-10-23.md) and
[a join concatenation/demand subset](SPEC-JOIN-2026-10-23.md) and
[two shallow/deep flattening subsets](SPEC-FLATTEN-2026-10-23.md) and
[deepJoin/lines String composition subsets](SPEC-COMPOSED-STRINGS-2026-10-23.md) and
[three character stripping subsets](SPEC-STRIP-CHARS-2026-10-23.md) and
[three split-family subsets](SPEC-SPLIT-LIMITS-2026-10-23.md) and
[two membership subsets](SPEC-MEMBERSHIP-2026-10-23.md) and
[two Array extrema demand subsets](SPEC-EXTREMA-DEMAND-2026-10-23.md) and
[a sort Array cardinality/demand subset](SPEC-SORT-DEMAND-2026-10-25.md);
even these functions have unresolved or uncovered contracts. No whole
function is accepted as fully conforming by this inventory. Earlier executed
test counts remain tied to their respective stage sources, not to a new claim
about every signature, type, default or forcing order.

The [character stripping review](SPEC-STRIP-CHARS-2026-10-23.md) preserves the
first unchanged-product result of five passed and seven failed groups. The
scoped argument/Array-member demand correction then passed all twelve frozen
groups and three neighboring checks. Only those independently reviewed subsets
advance the dimension map; no whole-function acceptance is inferred.

The [split-family review](SPEC-SPLIT-LIMITS-2026-10-23.md) preserves the first
five-pass/six-failure baseline. The scoped wide-limit and guard-demand correction
passed all eleven frozen groups plus three neighboring checks. Only the
independent fixture's bounded obligations advance the public map; the
unlimited-right/overlap documentation/source conflict remains unresolved.

The [membership review](SPEC-MEMBERSHIP-2026-10-23.md) preserves its first
five-pass/nine-failure baseline. The corrected member/contains demand and
traversal passed all fourteen frozen groups, with separate neighboring checks.
The old extrema assertions were run unchanged, retained as a raw failure, then
migrated individually against the fixed definitions and passed separately.
The earlier prose count of 57 was stale: the committed split-stage map already
contained 60 distinct records. This batch adds only member and contains, giving
62 reviewed subsets; correcting that count does not grant any other coverage.

The [Array extrema demand review](SPEC-EXTREMA-DEMAND-2026-10-23.md) retains
its three-pass/eleven-failure baseline. The scoped optional-argument and
unselected-payload correction passed all fourteen unchanged groups, sort's four
groups and arguments' one group. Two conflicting legacy extrema assertions
were migrated individually after preserving the raw failure, and the two
legacy groups then passed. This adds only minArray and maxArray: all 62 prior
manual records are unchanged, yielding 64 reviewed subsets and zero whole
function acceptances. Non-Array scope and singleton/comparator disputes remain
unresolved.

The [extrema comparison continuation](SPEC-EXTREMA-COMPARISON-2026-10-23.md)
retains its one-pass/twelve-failure baseline. It resolves bounded singleton-key
rejection, initial self-comparison demand and condition-before-selection cases
from the earlier open comparator area. The corrected helper passed all thirteen
new groups and the fourteen previous demand groups; one legacy singleton Object
success assertion was migrated after preserving the old group's raw failure,
and both legacy groups then passed. Only the two existing extrema map records
are extended. The total remains 64 reviewed subsets and zero whole-function
acceptances; non-Array admission, exact callback counts, independent error order
and the greater-than formal-rule conflict remain unresolved.

The [sort cardinality/demand review](SPEC-SORT-DEMAND-2026-10-25.md) retains
its two-pass/six-failure baseline. Passing the key thunk through the dispatcher
and returning zero/singleton Arrays before key/element demand passed all eight
unchanged groups and eight neighboring checks. The old sort tests were run
unchanged first; their raw failure is retained, and four conflicting inputs
were individually moved to required two-element contexts. The 64 prior manual
records remain unchanged, yielding 65 reviewed subsets and zero whole-function
acceptances. Non-Array scope, arbitrary key/comparison domains and independent
error priority remain outside this review.

The [sort contract continuation](SPEC-SORT-DEMAND-2026-10-25.md#frozen-continuation-sort-public-contract-review)
maps all thirty legacy assertions individually, retaining the non-Array String
error and unused incompatible-key admission as unresolved. Six independent
groups passed on unchanged dbf322d product, with a preserved initial pass before
key-call class enrichment. Only the existing sort record advances; the count
remains 65 reviewed subsets and zero whole-function acceptances.

The [sort admission adjudication](SPEC-SORT-DEMAND-2026-10-25.md#sort-admission-and-non-promises-frozen-adjudication)
uses the explicit e_std/source implementation contract to resolve the earlier
non-Array/unused-invalid-key scope question. Its preserved2-pass/4-failure
baseline led to a minimal length/deferred-index correction, then20 unchanged
sort groups and8 neighbors passed. The old String-Type assertion was measured
as a failure, retained as a correct positive input, and its Type negative moved
to a Boolean length failure. General native key counts/order and an independent
diagnostic winner are non-promises, not indefinitely pending requirements.
Other receiver/comparison gaps remain; still65 subsets and zero whole functions.

The [receiver/comparison boundary](SPEC-SORT-DEMAND-2026-10-25.md#standard-receiver-composition-and-comparison-boundary)
links four existing-object-file cases to partial language rules. A preserved
2-pass/2-failure baseline exposed lost final self in an inherited optimized
field; the source-context repair passed4/4 plus44 neighbors while canonical
std stays native. Saved/forwarded functions remain lexical, not receiver hooks.
The malformed comparison conclusions remain a stopped global document conflict,
with a proposed erratum only. No sort-specific framework or function completion
was added;65 reviewed subsets and zero whole functions remain.

[tools/spec-public-inventory.mbtx](../../tools/spec-public-inventory.mbtx) checks
the three reference hashes before extracting the fixed headers/exports. Its
source-header assumptions were reviewed against those exact bytes. It records
the generator/manual-map hashes, hashes of every scanned root test, the Git base
identity and any uncommitted test paths. Candidate references can therefore be
checked against their actual bytes even during a review with pending test edits.
The generator and manual case map are independently identified by their hashes.
This generated document is an audit snapshot, not a clean-source
execution report. Regenerate with the same public reference files:

```sh
env RUST_LOG=error moon run --frozen tools/spec-public-inventory.mbtx REFERENCE_DIR OUTPUT_DIR
```

Reference files stay outside the repository; no private application is read by
this generator. The generated inventory contains interface facts and test
references, not copied reference implementations. The focused
[contract matrix](SPEC-CONTRACT-REVIEW.md) retains detailed language/P0 evidence.

## removeAt named-parameter candidates

The fixed documentation declares removeAt(arr, idx). The same version's source
declares removeAt(arr, at). Current MoonJsonnet declares i from Go. The fixed
specification's apply rule matches a named argument to a declared parameter;
named spelling is observable. The
[language parameter guidance](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#function-parameters)
recommends positional arguments when every parameter is required because authors
may not regard those names as stable. That guidance neither selects idx/at/i nor
disables ordinary named-call matching.

| Candidate | Supporting basis | Unresolved consequence |
| --- | --- | --- |
| idx | Explicit public documentation signature and description | Conflicts with the executable source definition's at |
| at | Exact source definition specifies the function and its bound parameter | Conflicts with the documentation signature; no explicit precedence rule resolves it |

Source-defined behavior makes at the stronger implementation candidate if the
source definition is selected as the signature authority. This is a proposed
adjudication, not a unique conclusion from the two conflicting sources. Current
i has no independent support from those sources. Positional immutability remains
independently specified/tested. No name is changed, no additional alias is
accepted, and named conformance stays unresolved. Accepting multiple names would
invent a contract and make mixed named calls ambiguous rather than settle it.

## Other source conflicts and useful gaps

- The documentation spells escapeStringXml while source exports escapeStringXML. Both identifiers are retained as candidates; no alias/rename is inferred.
- The documentation's manifestYamlStream signature defaults c_document_end to false; source defaults it to true. The existing nested-error regression establishes propagation only, not default-option conformance.
- The documentation describes isEven/isOdd using the integral part; source uses round. Existing Go-result assertions require separate normative adjudication, especially fractional/negative inputs.
- SHA-1/SHA-256/SHA-512/SHA3 documentation marks them Go-only, while fixed C++ source exports error stubs. Successful local digest vectors are mapped without settling the public conditional-scope/signature question.

These are review findings, not newly executed implementation-failure claims.
Next useful work is to adjudicate one conflict with minimal source-level probes
and to review actual normal/error/lazy/boundary assertions for currently U rows.
Adding rows, registration checks or new Go-equal snapshots cannot replace that.
