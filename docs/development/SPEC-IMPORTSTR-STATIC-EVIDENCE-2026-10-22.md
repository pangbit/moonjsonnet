# Completed static judgment: chk-importstr

**Decision: the named static rule chk-importstr is reviewed complete.** This
does not mean that importstr loading or the language as a whole is complete.
The [pre-probe criteria](SPEC-IMPORTSTR-STATIC-REVIEW.md) define the exact
premise-free core judgment and separate its grammar/runtime boundaries. The
rule was one of the 51 entirely unreviewed rows at `b47c148`.

## Why this particular rule can be closed

For any canonical string payload and any static environment, the validator's
`ImportFile(_, _)` arm returns Unit. It does not examine the payload, names or
object-context flag, and calls no resolver or evaluator. AST conversion preserves
the typed string/raw-flag leaf; shape validation adds no ImportFile-specific
payload/scope restriction. This structural case analysis covers the rule's
universal inputs; finite example counts alone would not do so. This is an
engineering review, not a machine-checked proof of the whole implementation.

| In-rule condition | Judgment and executed evidence |
| --- | --- |
| Accept every well-formed importstr leaf | Constructor analysis plus exact source/handmade-AST acceptance of empty, keyword-like, NUL and Unicode/newline payloads |
| Independence from Gamma and enclosing object context | Constructor does not read those inputs; creation controls cover source and handmade locals, shadowed std, functions, objects and unselected branches |
| No target access during checking | No resolver is called in the inspected paths; virtual request counters remain zero through creation |
| Negative static case inside the rule | N/A: this judgment has no rejecting premise for a well-formed leaf |
| Runtime/type error inside the rule | N/A: this static judgment contains no evaluation premise |
| Remaining obligations inside this named judgment | None identified after the constructor analysis and acceptance controls |

The [new tests](../../spec_importstr_static_test.mbt) also protect phase
boundaries without promoting them into completed runtime rules. Synthetic target
text containing missing/self/super/root syntax and malformed code is returned as
opaque data when separately demanded; unused imports make zero virtual requests.
Nonliteral source operands still fail Syntax, and undefined sibling expressions
still fail Static through source and handmade AST. The existing ast_test
semantic round trip is reused for creation acceptance, not its source/copy
equality as an independent value oracle.

## Validation identity and scope

Test source: `2295c820b533ce0af4c9f56a5e129df962c6b00a`, tree
`87d9948f9c2e2565c1c9f8980c5eaba8a4b0d16d`. Existing tools on Darwin arm64:
moon/moonrun 0.1.20260920 (914d7da), moonc v0.10.14+7d59c7ec9.
Semantic fixtures are test-defined strings and virtual resolver responses;
the semantic tests perform no actual imported-file or network I/O. No CLI, full
aggregate, release, platform, reference-implementation or remote run occurred.

| Check | Observed result |
| --- | --- |
| First four-group baseline | 4/4 |
| One affected native debug run | 16/16, including the four new groups and existing AST/origin/syntax/import controls |
| Native flags | --frozen --deny-warn -j 1 |
| Explicit-completion metadata negative controls | Changed implementation hash and transplantation to nonempty-premise chk-self both rejected before output |
| Current matrix | One completed named static rule, 43 partial rows, 50 unreviewed rows |
| Versioned documentation only | 133 files / 1018 local/current-source links passed |
| Final info then fmt, script formatting and whitespace | Passed; no .mbti changes |

Affected command: `moon test spec_importstr_static_test.mbt ast_test.mbt
anonymous_test.mbt syntax_diagnostic_test.mbt spec_import_scope_test.mbt --target
native --frozen --deny-warn -j 1`, with RUST_LOG=error. The counts overlap and are
not added. The interpreter implementation did not change, and public interfaces
remain unchanged. Matrix tooling adds explicit named-rule completion/N/A records,
pins inspected source and test hashes, and validates the fixed rule's empty
premises. It records a manual decision; it does not infer correctness from
matching test names or claim whole-language acceptance.
Documentation validation now consumes Git-tracked/staged Markdown only;
untracked files are outside its validation set.

| Retained artifact | SHA-256 |
| --- | --- |
| Pre-probe criteria | bb23207206b4706b57175d1489bb653c46569cfab79ccf54de235603c1605124 |
| Baseline log | 68e3eed91ee5d217ff66600d731275bc52d0148ef97ff479d64faef8d2e15499 |
| Affected log | f50ce06797bc93504dd0ac75cc2d752711467886b159ce549d1def601b31b490 |
| New test file | 0b97cd9cac93bf34e84d075f45ac4a1691844d473bcd749df42d5321d3779f7d |
| Inspected validate.mbt | 88fec7025eb865c2f5c4563ae7647d3269850673959018985e7b7af1892c7cb4 |
| Inspected ast_convert.mbt | bd3fbff39ccdfc2d177d41435d7a33e96014ae206697c902be69ec2b11d5beed |
| Inspected ast_validate.mbt | cae4abdfdb7e7de57139eb494cdead3a5b96cd82c0e1b3cf9ccb37ce28eb603c |

Raw local evidence is under `/tmp/moonjsonnet-static-importstr.l77alG`;
temporary files are not an archival delivery guarantee. The committed
[machine-readable matrix](spec-language-matrix.json) retains the explicit
decision, criteria, inspected hashes, N/A reasons and exclusions.

## Explicit remaining work outside this rule

- Full source lexing/quoting and enclosing static rules, including their invalid
  shape and diagnostic boundaries, remain independently reviewable obligations.
- Full importstr target loading, UTF-8 decoding, canonical path identity,
  cross-mode caching and resolver/error behavior remain incomplete. This batch's
  opaque-text and unused-request cases are boundary controls only.
- Host filesystem permissions and resource limits, import code scope, importbin
  and the remaining language rules are not completed by this judgment.
- Public stdlib coverage remains 35/153 partial reviews. Earlier naming,
  cardinality/filter and Unicode ambiguities retain their existing status.

[Go/C++ comparison](SPEC-LANGUAGE-COMPARISON-2026-10-22.md) remains separate and
unexecuted for the new cases. The frozen af188da Linux result does not apply to
this newer source. No push, release or tag occurred.
