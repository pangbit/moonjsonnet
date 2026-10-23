# Identifier and keyword token boundaries

## Frozen criteria

Base: 1884dba07ae9c1af9cf69c9c828d7e5fe7edb679. Official Jsonnet:
bbb38f1020be1f5aed560928fb839b2c448cefb4. The current matrix leaves
LEX-NAMES unreviewed. This batch covers identifier/keyword boundaries only;
it does not accept the clause's entire operator-token language.

The [fixed lexing section](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#lexing)
(123-140) defines greedy tokens, optional whitespace/comments, the exact
identifier language `[_a-zA-Z][_a-zA-Z0-9]*`, and these 18 excluded words:
assert, else, error, false, for, function, if, import, importstr, importbin,
in, local, null, tailstrict, then, self, super, true. A proper longer
identifier containing one of those spellings is not a keyword. This follows
from the token languages and greediness, not a Go/C++ observation.

The same fixed abstract syntax requires id in local binders, formal
parameters, unquoted field names and dot lookup. A keyword cannot fill those
slots. A quoted field name is a String, so its content may equal a keyword.
The [core-language note](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#core_syntax)
(882) treats dollar separately from the source identifier language; this
batch does not re-adjudicate the previously reviewed root-object scope.

Reuse [number-token evidence](SPEC-NUMBER-TOKENS-2026-10-22.md) for greedy
number/id boundaries, separate minus/dot, ordinary NaN/Infinity names and
the source-Syntax versus host-AST-Static distinction. Existing lexer
diagnostic tests cover selected Unicode and numeric failures; their exact
Go-oriented human messages are not a normative oracle and are not rerun.
Neutral source/tree, bounded evaluation and SyntaxDocument token helpers
are reused without parser-exported trees supplying expected ASTs.

| New group | Required outcome fixed before execution |
| --- | --- |
| LN1 | Every literal ASCII start character and continuation character in the prescribed alphabets forms the expected complete token in a bound program. Source and independently built Local/Var AST evaluate to 42. Representative case changes and a long identifier remain exact names. |
| LN2 | Each of the 18 keywords rejects Syntax in local, parameter, unquoted-field and dot-name slots even in unused source. Five prescribed prefix/suffix extensions remain one identifier token and evaluate to 42 through source/handmade AST. The quoted keyword field is accessible as String data. |
| LN3 | Numeric-leading, separated, dollar-containing and representative non-ASCII/control spellings cannot form an id in a source binder. Comments between partial names cannot merge them. Three comment forms between complete local/name tokens preserve the explicit token vector and value. A lexically valid unbound name rejects Static through source/AST even unused; a valid bound keyword-prefix name with an error value remains lazy until demanded. |

Source-only Syntax failures do not impose a lexical policy on manually
constructed AST name strings. Normal source/AST comparison assumes admitted
ASCII identifiers. Syntax, Static and Runtime are distinct categories; the
last two are adjacent controls, not an acceptance of full static/dynamic
judgments. Only isolated errors are selected, and human error wording is
not standardized.

No product change is planned absent a real first semantic failure. Preserve
that failure before any minimal correction. Three native debug groups run
sequentially at nice 10, -j 1, no parallel testing, using the existing
steps=20000/depth=64/stack=96 helper limits. No full suite, remote, browser,
installation, release/Linux, push or private external material is needed.

Remaining obligations include the full operator-token grammar and its
termination exceptions, every token-language composition/encoding boundary,
all identifier-bearing grammar/static constructors and resource-independent
proofs. LEX-NAMES can gain partial evidence only. Existing A0/B0/N0/R0/PE0,
the filter non-Boolean question, Unicode surrogate ambiguity and Go/C++
compatibility remain unchanged. Test/case counts are not conformance rates.

<!-- Criteria above are frozen before execution; evidence is appended below. -->

## Result and limits

The first native debug run passed **3/3, exit 0** in 9.403 s. Test SHA-256:
`a6b14de4f4b444d7c4d861eda96e9534cb2e61450dc34b7e87dead6504029883`;
log SHA-256:
`97372d6d024ba8fb9a214e3a9a3495ca88a0631086280e8b2271682e11ea6fb0`.
No interpreter defect was found or product source changed. These exact test
bytes were not rerun. The prior string-concat commit was recovered and
completed as 1884dba before this independent batch began; its semantic and
metadata checks were preserved rather than repeated.

Inspection of [identifier_start and lex](../../lexer.mbt) shows literal
ASCII start ranges and a continuation loop over those ranges plus digits.
It consumes the whole name before [parser keyword classification](../../parser.mbt),
whose exclusions match the fixed 18-word list. This explains both reserved
slot rejection and the intact longer keyword-like names. The lexer skips
comments between tokens; it does not concatenate separated name fragments.
The tests observe those distinctions through complete token vectors,
source admission and independently manufactured successful ASTs. Quoted
field names bypass identifier classification as prescribed String data.
None of this proves arbitrary host-AST name payloads or all grammar slots.

Native check, info, root formatting, standalone tool format checking and
schema-v2 matrix generation all exited 0. Public `.mbti` and every reused
test/product byte remain unchanged. The checker itself changes only its
report index link; its duplicate-key and global identity logic is untouched.
This run validates **155** canonical file/case bindings. The 14 negative
metadata controls at 1884dba were not re-executed or claimed as fresh results.

Only LEX-NAMES gains partial evidence. The 94-row matrix now records
**16 named judgments completed + 1 constructor transfer relative to children
+ 63 partial + 14 unreviewed**. Old named decisions, all other rows, prior
evidence and A0/B0/N0/R0/PE0/filter boundaries retain their previous scope.
Full native debug 539/539 remains bound only to 5651ae9.

Raw pre-run sources/criteria, first execution and final check/readback data:
`/tmp/moonjsonnet-lex-names.s6qr320u`. Documentation/link checking is recorded
separately there. The next concrete gap is the fixed operator-token grammar:
greedy operator runs, comment/text-block sentinels and forbidden trailing
unary symbols need token-level oracles distinct from parser acceptance.
