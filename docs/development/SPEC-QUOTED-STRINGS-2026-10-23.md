# Quoted and verbatim String boundaries

## Frozen criteria

Base: a3b204f6044d7dbbc724b271235f7aaf2ed98756. The oracle is
[official spec Lexing, lines 149-202](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#lexing)
at fixed Jsonnet bbb38f1020be1f5aed560928fb839b2c448cefb4, not Moon/Go/C++
output. Four quoted forms share canonical codepoint values. Ordinary single
and double quotes recognize the listed nine escapes and four-hex-digit
Unicode escapes. Actual LF/CRLF in an ordinary string is retained. Verbatim
strings process every character literally except doubled closing quotes.
Greedy tokenization and these closing rules determine adjacent token splits.

Reuse only the nine-escape table within the existing `string literals decode
Go escapes and surrogate replacement` case. Its bytes match 5651ae9, where
the native debug full suite passed; no fresh whole-case/Go compatibility claim
is made. The case's surrogate assertions are outside this normative mapping.
Existing text-block and unterminated-single-quote controls remain separate.

| Group | Independent required outcome |
| --- | --- |
| QS1, raw scanner | Ordinary adjacent literals remain separate; doubled verbatim delimiters belong to one token. Quotes protect comment/operator-like contents. First closing quotes leave following operators, identifiers and comments separate, in both trivia modes. Raw spelling is retained. |
| QS2, ordinary values | Double quotes cover the nine-escape table missing from the reused single-quote table. Both ordinary delimiters cover empty/opposite quotes, escaped terminators/backslashes, mixed-case non-surrogate hex escapes, exact Unicode and multiline LF/CRLF values. Literal expected Strings and independent Literal ASTs agree. |
| QS3, verbatim values | Both delimiters preserve backslashes, invalid-looking escapes, opposite quotes, actual control/newline/Unicode characters; only doubled end-quotes collapse. Adjacent valid expressions retain the expected canonical value. |
| QS4, phase/error boundaries | Missing closures, invalid @ prefixes, unknown escapes, incomplete/nonhex Unicode escapes and line continuations reject source Syntax directly and in unused contexts. Valid canonical Strings that look like invalid source escapes are legal hand-built AST data. Valid quoted Runtime errors remain lazy until demanded through source/AST. |

AST values are built from literal expectations, never a parser export. They
check value/phase consistency and do **not** exercise lexing. Syntax error
categories are host embedding controls; exact error wording, diagnostic
locations and precedence between competing errors are not normative here.
No lexical error should be deferred until evaluating an unused expression.

Surrogate escapes, replacement/pairing policy, invalid source UTF-8 and
unescaped non-line controls in ordinary strings remain unadjudicated. A
verbatim backslash-u sequence is literal data, not a surrogate verdict.
The fifth quoting form (text blocks), malformed ||| policy, full grammar,
formatting/import contracts and A0/B0/N0/R0/PE0 remain separate. LEX-STRINGS
may gain scoped partial evidence; this batch cannot mark it wholly complete.

Four new bounded native debug groups, one worker, nice 10, frozen dependencies,
no parallel tests. Preserve first failures before any minimal product repair.
Use existing schema v2 and checker; do not add a new metadata completion form.
No full suite, remote/browser, install, push or private proposal source.

<!-- Criteria above are frozen before execution; append results below. -->

## Result and retained boundaries

The first native debug executions passed **3/3 public groups and 1/1 raw
scanner group, both exit 0**. These formatted test bytes were not rerun.
No product defect was found; interpreter code, legacy tests and public
interfaces remain unchanged. No Go/C++ comparison or full suite ran.

[Public fixtures](../../spec_quoted_strings_test.mbt) supply literal canonical
Strings to independent Literal/Arr/Fail ASTs. [Scanner fixtures](../../spec_quoted_strings_wbtest.mbt)
check raw boundaries in both trivia modes. Their roles remain distinct:
AST success cannot compensate for a source lexical failure, and invalid
source spellings have no claimed lexical AST counterpart. The reused QS0
record maps only the existing standard escape table, excluding every
surrogate assertion in that historically named case.

Inspection of [lex](../../lexer.mbt), [unescape_literal](../../string_literal.mbt)
and [Token::literal_kind](../../token.mbt) confirms the relevant paths:
ordinary escaped quotes/backslashes are protected while scanning, verbatim
quotes double only the matching delimiter, and non-verbatim escape decoding
occurs on token consumption before a Program exists. The decoder's explicit
simple-escape arms and four-digit hexadecimal loop support the specified
subset; its surrogate branch was not adjudicated. No inferred diagnostic
order or formatting behavior is required.

The existing schema-v2 checker passed all **168** unique canonical file::case
bindings and case-local anchors. No checker or harness code changed and no
previous metadata negative suite was repeated. Mapping preparation initially
caught one incorrectly escaped anchor before any mapping write; only that
anchor was corrected. The raw first rejection and draft are retained.
All 163 old evidence records and 65 named-rule mappings remain unchanged;
only five evidence bindings and the LEX-STRINGS row were added/updated.
The other 23 prose rows retain their bytes and meaning.

The 94-row matrix records **24 named completions + 1 relative constructor
transfer + 60 partial + 9 unreviewed**. Only LEX-STRINGS moves from unreviewed
to partial. Its remaining field explicitly retains surrogate policy,
ordinary raw non-line controls, invalid source encoding and unbounded
scanner/grammar/resource obligations. The fifth quoting form and existing
N0/R0/A0/B0/PE0 and comparison boundaries do not gain a completion claim.

Native check, supported info, root/tool formatting and matrix generation
exited 0; no .mbti changed. The initial info invocation rejected the jobs flag
before doing work; the installed command has no jobs option. Its exit-2 log
is retained, and only unrun checks continued at nice 10. Required document
validation uses the existing tracked/staged checker; its final receipt and
exact commit/blob/clean/process audit are retained with the raw evidence at
`/tmp/moonjsonnet-quoted-strings.l7j8b3hr`. Full-suite 539/539 remains bound
only to 5651ae9. A next independent useful gap is the static array-index
constructor, reusing existing index demand/type coverage and preserving its
child-judgment scope.
