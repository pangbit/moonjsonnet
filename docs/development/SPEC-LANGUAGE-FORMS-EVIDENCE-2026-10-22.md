# Recursive binding and comprehension evidence

This batch selected `chk-local` and `object-comp` from the original 53 entirely
unreviewed matrix rows. It started at `5e757b4`, checked existing assertions
first, and fixed the [independent oracle](SPEC-LANGUAGE-FORMS-REVIEW.md) before
the first probe. No Go/C++ execution chose the expected values. No product defect
was found in the selected dimensions, and no interpreter implementation or
public API changed.

Test/corpus/runner source is
`e49dd7d8baa9881bf47a731ec4ebb1826a3723df`, tree
`037baca420f03b9e8282b95def2fc7895014acd2`. The first 13-group baseline passed;
two further groups added native counters for key/filter error timing, within
the already locked oracle. The final affected run below includes all 15 new
groups. These group counts overlap and must not be added.

## Actual new assertions

| Selected rule and adjacent dimensions | Concrete executed evidence |
| --- | --- |
| chk-local: recursive group scope | Forward local references, mutually recursive even/odd functions and lexical shadowing yield exact JSON through source and exported AST |
| chk-local: static rejection in lazy contexts | Duplicate local/function/object-local/comprehension-local groups reject at creation, including unused branches and empty domains; inaccessible sibling/later-loop variables remain Static |
| Local laziness and cache | Repeated native initializer aliases run once; unused recursive/error/native initializers are not demanded |
| Object locals under inheritance | Forward local aliases using self and super produce original/derived/original values `[4,5,4]` |
| object-comp: scope/order | Dependent generator domains and repeated generator names follow explicit Cartesian order and lexical shadowing |
| object-comp: construction and demand | Empty domains skip keys/body, repeated null keys omit bodies, shape inspection still constructs needed keys, repeated selected bodies are cached |
| object-comp: error timing | Duplicate/nonstring keys raise Runtime/Type only after valid Program creation, with 2/1 key callbacks and zero body callbacks; invalid filters raise Type before later domain callbacks |
| object-comp: inheritance | Comprehension-local self/super and enclosing-self/root keys distinguish original and derived objects through both source and exported AST |
| Public AST boundary | Four groups build ASTs by hand: duplicate local groups, inaccessible comprehension scopes, valid forward/null-key controls, and runtime duplicate comprehension keys versus static literal duplicates |

The [library source tests](../../spec_language_forms_test.mbt) use helpers which
assert exact JSON or diagnostic kind and location after successful Program
creation. The separate [handmade AST tests](../../spec_language_forms_ast_test.mbt)
do not depend on parser acceptance. Exporting a valid parsed tree is only an
additional path check; it is not labeled an independent handmade AST test.
Counter controls prevent an early body error or wrongly evaluated later domain
from being accepted merely because its error category happens to match.

The [source CLI corpus](../../tests/spec-language-forms-cli.json) is executed by
[the dedicated runner](../../tools/spec-language-forms.mbtx). Its 16 successful
cases compare exact JSON; its 14 error cases require exit 1, empty stdout and
the expected source/runtime rendering plus the diagnostic fragment. CLI rendering
does not expose the library's finer Type category: `library_kind` in the corpus
is an expectation, not an inferred actual CLI kind. Library assertions separately
check Static/Runtime/Type. Full raw outputs and source/build hashes are retained
in [the CLI execution report](spec-language-forms-cli-evidence-2026-10-22.json).

## Bounded validation

Platform: Darwin arm64. Existing moon/moonrun 0.1.20260920 (914d7da), moonc
v0.10.14+7d59c7ec9; no toolchain or dependency changes. Native build/test commands
used `--frozen --deny-warn -j 1`. There was no full debug/release aggregate,
release build, multi-platform campaign, SSH, upload or new remote request.

| Check | Result |
| --- | --- |
| First independent semantic baseline | 13/13 |
| One final affected native debug run, eight files | 44/44, including all 15 new groups |
| Native warning-denying check | Passed |
| Source CLI build and cases | Exit 0; 30/30, including all 14 required nonzero exits |
| Matrix source/anchor validation | 39 reviewed assertion blocks; only two formerly unreviewed rows gain partial evidence |
| Documentation | 129 files / 989 local/current-source links passed |
| Final info then fmt, script formatting and whitespace | Passed; no .mbti changes |

Exact affected command: `moon test spec_language_forms_test.mbt
spec_language_forms_ast_test.mbt spec_language_function_test.mbt
spec_language_object_test.mbt spec_static_test.mbt ast_test.mbt
binding_range_test.mbt language_test.mbt --target native --frozen --deny-warn
-j 1`, with RUST_LOG=error. CLI reproduction:
`moon run --frozen tools/spec-language-forms.mbtx EVIDENCE_DIR`; it builds only
cmd/main for native debug with one worker and records its exact inputs/binary.
The initial local script compile diagnostics were fixed before CLI execution;
they are not interpreter failures or additional passed semantic cases.

| Retained artifact | SHA-256 |
| --- | --- |
| Pre-probe oracle | 35a0522d93ae411c111f50e290b9fac85aefca03ac2c7c20217cc701cd2b3770 |
| Initial 13-group log | 8a4e7a01c3f5026ef0c27a47b536bea8872fe1fab2d6d673da8ccd9aea407092 |
| Final affected 44-group log | c163aad54be87d4af7817bdd91fb5a1b4953cd80d65c6887eef0a2655efcb9b2 |
| Forms source-test file | c8e1af3588e9b5fe69b603575c8c807a0a58023d8db3f9ed1df3898275b224fb |
| Handmade AST test file | 4d2bd9c0303a756cfc457fa4cff910f80e094447aaa1b86014b9d3849a90738d |
| CLI fixture | f5490eedc29da5b9f1d39bf2f6edd5c070739505fedcda11bb33980621043136 |
| CLI runner | 2844d3fb5b2112aa0f9561bc696bafe3bea1d446a6f1002e7276826d58c6a924 |
| Full CLI report | d4f021c6b84293ddd687637a43d7f7b67b8726d15cd0b9e16039fbbb4ebc478a |
| Raw CLI cases.json | 05827ef5228527af663a31dcbc8e37a3008cca19b541a9daf16f075f1de814e6 |
| Native debug CLI executable | c41f07805590ddf79326634ece3030355d3776edec3fc6de28463207c14be6cc |
| Manual matrix input | 780f16215fbdeb96f0f4e5e8ad24b886fcc22afe27d4a9d0b6ede392efbbf092 |
| Generated machine matrix | 14a73ec6c76b5ac3e3baeddc417803a565151c543ed551fcbbddb03ef285e4ba |

Local raw evidence is at `/tmp/moonjsonnet-language-forms.q0vOaL`. Temporary raw
files are not an archival delivery guarantee; the committed CLI report preserves
the source-case results. The native sources used by the affected run and CLI
remain unchanged by the later mapping/documentation changes.

## No wider acceptance claim

The [current matrix](SPEC-LANGUAGE-MATRIX.md) has 43 rows with manually reviewed
subsets and 51 entirely unreviewed rows, compared with 41/53 in the prior stage.
No rule is marked completely conformant. Adjacent already partial rows gain
specific dimensions, rather than being counted again as newly accepted rules.
Mechanical string/object/function generator-domain extensions and exhaustive
desugaring/nesting remain unadjudicated. All earlier unresolved contracts,
including the eleven array observations, removeAt naming and Unicode surrogate
ambiguity, retain their status. Public stdlib coverage remains 35/153 partial
function reviews.

[Go/C++ comparison](SPEC-LANGUAGE-COMPARISON-2026-10-22.md) remains unknown for
these cases. The approved af188da Linux 425/59 result is unchanged and gives no
Linux credit to this batch. No push, release or tag occurred.
