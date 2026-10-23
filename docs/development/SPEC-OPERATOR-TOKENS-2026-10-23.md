# Operator token greediness and termination exceptions

## Frozen criteria

Base: 3fbe3ab2fc2cc647d3e92d88bfac279399f23369. Fixed official Jsonnet:
bbb38f1020be1f5aed560928fb839b2c448cefb4. This batch contributes one
coherent operator-token boundary review to the partial LEX-NAMES clause.
It does not complete all lexing, encoding, grammar or child judgments.

The [fixed lexing section](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#lexing)
(123-127, 205-233) specifies greedy tokens, the separate symbols
`{}[],.();`, and the operator alphabet `!$:~+-&|^=<>*/%`. Operators have at
least one character. Multicharacter operators cannot end in `+ - ~ ! $`;
those characters are permitted internally and as singleton tokens. Hence
`++=` is one lexical token, while `=+!$` splits into four. The parser may
still reject a lexically valid operator such as `===` or `<<=`.

The additional termination exceptions protect `//`, `/*` and `|||`.
For recognized comments/valid text blocks, this record explicitly reads
them as stopping at the sentinel's start, so the next comment/String token
can begin there. This is a lexical-priority inference from the exceptions
and the same section's comment/block definitions; ordinary maximal matching
without those exceptions would not alone prove it. Thus `+` before a valid
`|||` block must not consume the first two bars as `+||`. Tests assert this
bounded interpretation, not a new formalization of every malformed opener.
Comments terminate names/operators rather than joining their separated
fragments. Block comments stop at the first closing `*/`.

Reuse UP0's [existing unary/comment controls](../../parser_diagnostic_test.mbt)
and [number-token evidence](SPEC-NUMBER-TOKENS-2026-10-22.md) for already
tested signs, numeric suffixes, comment adjacency and lexical/AST stages.
The [identifier record](SPEC-LEX-NAMES-2026-10-23.md) covers keyword/name
boundaries. Retained [trivia round trips](../../source_fidelity_wbtest.mbt)
are useful preservation evidence; round-tripping alone does not supply the
new expected token vectors. None of those old semantic groups is rerun.

| New group | Independent expected result |
| --- | --- |
| OT1, raw lexer | Literal alphabet singletons, two-character combinations partitioned by the fixed legal/forbidden ending sets, and prescribed longer runs produce exact raw vectors. Only the two comment-open pairs move to OT2. Embedded suffix characters stay within operators when their final character is allowed; repeated forbidden tails split. Separators and identifier/number adjacency remain distinct tokens. Both trivia modes must agree. |
| OT2, raw lexer | Complete line/block-comment and valid text-block sentinels survive at operator boundaries, adjacent tokens do not merge across comments, and spaced slash/bar fragments are not sentinels. A valid block contributes the exact String x plus newline. Recognized unclosed/invalidly closed comments/blocks and characters outside the token alphabets reject Syntax in either trivia mode. Missing-newline block openers are not given a standalone raw-lexer verdict. |
| OT3, public source/AST | New plus/minus/comparison and comment/unary combinations match independently built trees and literal results. A plus directly before a valid block yields ax plus newline. Token vectors confirm the split. Lexically legal but grammatically invalid operators and malformed lexical sources reject source Syntax even unused. Valid token streams with null/error/unbound operands instead show deferred Type/Runtime or admission Static through source/handmade AST, without conflating those judgments. |

The raw lexer is observed directly because arbitrary legal operator tokens
need not form valid programs. Successful expression cases use independent
public ASTs; a source Syntax error is not converted into an AST lexical rule.
Raw vectors are transcribed/derived from the fixed alphabet, ending rule and
explicit sentinel interpretation, never a scanner snapshot or Go/C++ run.
Only isolated demanded failures are selected; diagnostic wording, callback
order and full operator evaluation semantics are outside this judgment.

Two whitebox groups and one public-entry group run sequentially, nice 10,
-j 1, no parallel testing; inputs are finite small fixtures. Public demand
controls use the existing steps=20000/depth=64/stack=96 limits. Preserve first
failures before any minimal product fix. No full suite, remote/browser,
installation, new dependency, release/Linux, push or private external source.

Remaining: general unbounded token-language composition and every malformed
String/block opener, full UTF-8/source coordinate/resource behavior, all
operator/AST/static/evaluation judgments and a complete formal lexical proof.
LEX-NAMES remains partial. Existing A0/B0/N0/R0/PE0, filter non-Boolean and
surrogate questions remain untouched; no whole-language/Go-C++ acceptance
or conformance percentage follows from fixture counts.

<!-- Criteria above are frozen before execution; evidence is appended below. -->

## Results and precise remaining gap

The initial invocations stopped at compilation: deny-warn rejected the
whitebox helper's non-exhaustive catch. Both original logs/files are retained.
The only correction adds `e => raise e`, preserving every expected vector
and assertion. The first executable runs then passed **2/2 whitebox groups**
(3.357 s) and **1/1 public source/AST group** (1.744 s), exit 0. No product
defect was found or interpreter source changed; passed groups were not rerun.
Executed file SHA-256 values:

- spec_operator_tokens_wbtest.mbt:
  `896ac6d32f1def656fe0085409c68bd5cc8abe804826358b68435903a368785a`
- spec_operator_tokens_test.mbt:
  `2c4046d97f089d130b7b84d3f907e68707ac5b2ebc9bebe373b2b2f2f38c7d0d`

The [operator character predicate](../../token.mbt) matches the fixed
alphabet. [lex](../../lexer.mbt) scans a maximal run up to a protected
sentinel, then backs off forbidden ending characters before emitting a
token. The remaining suffix is re-lexed, explaining both repeated singleton
tails and allowed embedded unary symbols. Comment/block entry branches
account for the recognized sentinel controls. This constructor reasoning
is relative to the explicit complete-opener interpretation in the frozen
criteria; the normal/negative vectors and both trivia modes agree with it.

The [parser](../../parser.mbt) accepts only its supported operator grammar
after lexing, so raw `===`/`<<=` tokens and source Syntax rejection are
compatible observations. The successful independent AST controls and the
Type/Runtime/Static boundaries do not promote those child rules. UP0 and
all other previous assertions remain unchanged and were not re-executed.

Native check, info, root fmt, standalone checker format and matrix validation
all exited 0; no public `.mbti` changed. Metadata preparation once rejected
a source anchor missing the formatter's record trailing comma, before any
mapping write. Only that anchor spelling was corrected; case-local checks
now pass. Schema v2 validates **158** canonical case IDs, with all old
evidence preserved. The checker itself changes only the report index link;
its validation logic and historical negative-control results are unchanged.

Only the existing partial LEX-NAMES row gains scope. Counts remain
**16 completed named judgments + 1 relative constructor transfer + 63
partial + 14 unreviewed**, total 94. Source hashes, other row contents and
all existing completion decisions/unknowns retain their former scope.
The full native 539-test result still belongs only to 5651ae9.

The specific unresolved lexical-selector question is how a standalone
malformed `|||` opener, or an analogous partial sentinel at EOF, commits
to an erroneous String versus falls back to shorter operator tokens. This
batch gives missing-newline examples only a source-Syntax verdict and
does not decide their raw tokenization. A same-version normative priority
decision plus explicit opener/EOF controls is needed to close that gap;
more successful fixture counts cannot settle it. General UTF-8/coordinates,
resource policy and full AST/static/evaluation contracts are separate
obligations, not unfinished parts of the tested operator mini-contract.

Raw frozen criteria, initial compile-only rejection, catch-only correction,
first executable results, metadata preparation/checks and final doc/commit
readback: `/tmp/moonjsonnet-operator-tokens.msl3lw9u`.
