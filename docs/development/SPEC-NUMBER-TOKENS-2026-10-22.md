# Number tokens: combined review and evidence

## Frozen criteria

Base: 68aadb4506bdeb1d49016db6c44fbc3f6ab94eff. Official Jsonnet:
bbb38f1020be1f5aed560928fb839b2c448cefb4. Scope: LEX-NUMBERS token
boundaries and the separate finite-number producer/demand boundary. This is
one bounded contract, not a complete lexical, arithmetic or IEEE754 review.
The pre-run manifest preserves this exact prefix before native execution.

The [fixed lexing specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#lexing)
requires greedy tokens, optional whitespace/comments, JSON numbers without
leading minus, ASCII identifiers and a separate dot symbol. Transcribing the
referenced unsigned JSON grammar gives
`(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?`.
An optional suffix belongs to a number only when complete. Thus `1.slot`
has tokens `1`, `.`, `slot`; `1else` has `1`, `else`. This is an explicit
inference from the token languages and greedy matching, not a prediction
from Go/C++ or from the current scanner. The
[surface grammar and dot desugaring](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#desugaring)
then make `1.slot` a well-formed index expression with a numeric base, and
`if true then 1else 2` an ordinary conditional. Index static checking does
not require an object type. A demanded numeric member access fails Type;
an unused one remains lazy.

The [fixed Number/Array/Function description](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md)
defines finite binary64 numbers, errors for nonfinite results and lazy
elements/arguments. It does not cap exponent spelling length or require
conversion of an unused numeric literal. Lexical admission of a well-formed
overflowing spelling is separate from conversion on actual demand. Zero
with a large exponent remains zero; a sufficiently tiny positive value
rounds to zero; leading exponent zeros do not change its value. All finite
expected results below are literal, exactly representable binary64 values.

| Probe | Independent required outcomes |
| --- | --- |
| NT1: greedy valid prefix | Integer 0/1/12, fraction 0.5 and exponent 1e0 before `.slot` parse and admit; unused access yields 42, forced access fails Type. Adjacent `else` after 0/1/0.5/1e+2 selects the specified branch. Exact token texts are checked independently of evaluation. |
| NT2: spelling and separators | `12.50E-1` and `1e+2` remain whole tokens; leading unary signs and following binary plus are separate. The literal result is [0,1.25,-2,3,103]. Comments separate complete tokens and cannot join number fragments; the result is [3,103]. |
| NT3: malformed shapes | 00/00.1/0e/0e-/1.0E+/.5/2_5/0x10/1e2.3 reject source Syntax, even unused. Independently manufactured NumberLiteral payloads reject host-AST Static. NaN/Infinity can be bound as ordinary identifiers; invalid raw numeric-name payloads are mapped from existing tests. |
| NT4: admission versus conversion | A large positive exponent admits through source and independent NumberLiteral, unused local/unselected branch/array length do not force it, and actual numeric or std.type demand fails Runtime. Large-exponent zero and underflow yield 0; 12.5E+000...001 yields 125. These do not complete arithmetic rounding or every producer. |

Reuse [numeric spelling/AST admission controls](../../number_literal_test.mbt),
[token/trivia byte ranges](../../source_fidelity_wbtest.mbt) and
[diagnostic controls](../../lexer_diagnostic_test.mbt). A parser-exported AST
in an old round-trip test is not reclassified as independent; new typed
trees are constructed separately using neutral ordering_*/sequence_* helpers.
Lexical or parse failure of malformed source and host-AST shape failure are
different phases. Diagnostic wording is an embedding control, not normative.
If the candidate greedy-prefix defect is confirmed, preserve the original
failure before the smallest scanner fix. Any changed invalid-source
diagnostic must follow the intended tokenization, with the old Go-labelled
table retained in raw evidence; fresh Go/C++ compatibility remains unknown.

LEX-NUMBERS may gain scoped partial evidence; no constructor or whole lexical
completion follows from this grid. A0/B0/N0/R0 remain unadjudicated. No
nonfinite Json payload, external file, new dependency or network operation
is required. All fixtures are bounded, native debug, one worker at reduced
priority, steps=20000/depth=64/stack=96. No full suite, remote, installation,
push, private document or upstream modification is authorized here.

<!-- Criteria above are frozen before execution; evidence is appended below. -->

## Execution and adjudication

The first command stopped at compile time: the test-only local name `member`
is reserved by MoonBit under deny-warn. No semantics ran. Only that name was
changed to `access`; the oracle prefix and expectations were unchanged. The
next run against the unchanged interpreter completed **4 groups: 3 passed,
1 failed, exit 2**. NT1 fails at its first `0.slot` case: constructing the
unused source `local unused=(0.slot);42` reaches the old scanner's mandatory
post-dot digit and throws Syntax. The original input, test and failure remain
in raw evidence. The pre-fix run does not establish that later NT1 fixtures
were executed; the analogous incomplete exponent defect is also apparent
in the old scanner's unconditional exponent consumption.

The minimal fix keeps the longest complete numeric prefix. A fraction is
consumed only if the next character after dot is a digit; an exponent only
if its optional sign is followed by a digit. Other characters remain for
the next token. The private scanner becomes non-raising, with its two callers
updated. Full raw-AST numeric admission still requires the match to reach
EOF: where an incomplete suffix formerly threw and mapped to false, it now
returns a shorter prefix and fails the length check. The admitted complete
numeric spelling language is unchanged. Numeric conversion, runtime demand,
parser grammar and public interfaces are unchanged.

The **identical** corrected-name test passed **4/4, exit 0** after the fix:

    nice -n 10 env RUST_LOG=error moon test spec_number_tokens_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize

NT1 now covers the dot/else boundaries through source, direct typed trees
and explicit token texts. NT2 preserves complete fractional/exponent spelling
and sign/comment boundaries. NT3 rejects all unused malformed shapes at their
separate source Syntax/host-AST Static stages. NT4 confirms long-spelling
admission without conversion, deferred overflow, zero/underflow and the fixed
125 control. No unused branch or payload is forced to satisfy these tests.

Three directly affected neighboring files ran sequentially with the same
native debug/reduced-priority/frozen/deny-warn/one-worker flags: numeric
literal tests **2/2**, lexer diagnostic tests **2/2**, source-fidelity
whitebox tests **2/2**, each exit 0. Thus the final directed results are
**4 new groups plus 6 adjacent groups**, not a full-suite result. Other
historical tests and platform totals are not promoted to current passes.

Four malformed-source diagnostics intentionally follow different paths:
`1.` now fails the parser's required identifier at byte 3; `1e` fails the
required EOF at byte 2; `1e+中` reaches the ordinary invalid-character lexer
error at byte 4; `['中', 1e+]` fails the array comma requirement at UTF-8
byte 10. They remain Syntax errors. These locations/messages were derived
from the intended tokens and existing parser paths before adjacent execution,
not copied from failing output. The original Go-labelled table remains in
`original/lexer_diagnostic_test.mbt` in raw evidence. This is an explicit
diagnostic compatibility delta from that table; no fresh Go/C++ acceptance
or disagreement has been measured. The normative greedy-prefix inference
above is independent of those implementations.

Six existing named reviews pin ast_validate.mbt: chk-unary, chk-error,
chk-if, chk-import, chk-importstr and chk-importbin. Their reviewed constructor
arms, anchors and all bytes outside the NumberLiteral arm are unchanged;
the full raw numeric-token admission language is also unchanged as argued
above and exercised by old/new controls. Their inspection hash is re-pinned
from cae4abdfdb7e7de57139eb494cdead3a5b96cd82c0e1b3cf9ccb37ce28eb603c to
e7413a4021b056253e179c2cb2b5d73c7a41c0b64573cc11533fa82555e38a59.
No old completion scope, evidence snapshot or child assumption is expanded.
The raw inspection-review.json preserves the before/after arm and comparison.

Native check, required info then fmt, script format check and fixed-source
matrix generation all exited 0. No public .mbti changed. Matrix validation
checks the evidence anchors, fixed-source hashes and refreshed inspection
hashes; its schema is unchanged, so no old negative metadata suite is rerun.
The [94-row matrix](SPEC-LANGUAGE-MATRIX.md) has **12 completed named reviews
(6 static, 6 evaluation), 1 relative prose constructor, 58 partial and 23
unreviewed rows**. Only LEX-NUMBERS changes from unreviewed to scoped partial;
VALUE-FINITE gains the bounded literal producer boundary. No completion or
conformance percentage follows. A0/B0/N0/R0 remain unknown. Full lexical
composition, encodings/resources, arbitrary exponent/precision boundaries,
all numeric producers and IEEE754 rounding remain outside this decision.

Raw: /tmp/moonjsonnet-number-tokens._blxrxyj. baseline.json/before-run.json
pin the clean base tree, original sources, fixed public source hashes, argv
and limits. first-result.json records the compile-only failure;
pre-fix-result.json preserves the semantic failure; post-fix-result.json
and adjacent-results.json preserve actual passes. Criteria-prefix SHA-256:
b06cf0e15caf7a27f6dc17ac209b21c8b6552a729b0b381b32ef75399064ddee;
executed pre/post-fix test:
f2b0623824df00431f167bacc8cf04290ab91158827eb79c4d27c632693d576c;
pre-fix log: bdb49d9c73a327c358fe53f7bb28bd93699d5d04a09da946e7b490dc4dd79986;
passing log: 68e3eed91ee5d217ff66600d731275bc52d0148ef97ff479d64faef8d2e15499.
The frozen prefix is byte-for-byte preserved. Local tools remain moon/moonrun
0.1.20260920 (914d7da), moonc v0.10.14+7d59c7ec9, Darwin arm64. The raw
documentation-result.json and final result.json record tracked/staged-only
document validation and exact-path commit readback. Temporary files are not
archival guarantees; the committed tests and this combined record retain
the criteria, failures, fix rationale and bounded acceptance.

Next high-value candidate: the unreviewed SYN-PRECEDENCE grammar contract,
mapping existing operator controls and comparing ambiguous source groupings
with independent ASTs. It has not been started here.
