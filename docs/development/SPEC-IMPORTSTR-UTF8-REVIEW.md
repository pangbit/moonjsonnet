# Importstr UTF-8 substitution: pre-execution criteria

Starting source: `0a5cbc9741a1b2751af63618939c0ef68b49b3f4`. Fixed Google Jsonnet
source: `bbb38f1020be1f5aed560928fb839b2c448cefb4`, spec.html SHA-256
`bbac3701ef0316fc29de6c543049ae8f0f78c876bdd94fbf6ab845b2023a720a` and language.md
SHA-256 `c55666af13894c8100c84fb053e647cd0ca516f3bb554d0ced29dfa83c3772be`.
The retained [Core Syntax](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#core_syntax)
lines 911-924 require importstr data to be valid UTF-8 and substitute a string.
The fixed language reference defines strings as sequences of Unicode codepoints.
No network source or reference implementation is used to choose expected values.

## Selected contract and independent oracle

The bounded contract is substitution of successfully supplied UTF-8 data without
an initial byte-order mark, within resource bounds. Each valid scalar sequence
must produce its decoded Unicode text, preserving order, NUL, line endings,
combining characters and interior U+FEFF. Empty data produces an empty string.
Escapes or Jsonnet-looking text in the data are not parsed or evaluated.
Malformed UTF-8 cannot become a successful string import under this validity
requirement. No surrogate escape or std.decodeUTF8 replacement policy is imported
into this contract.

Expected text is specified directly alongside manually written byte sequences;
it is not produced by an encoder/decoder, a Go/C++ output or a source/AST copy.
Valid vectors cover ASCII, the two-byte endpoints, three-byte endpoints around
the surrogate gap, and the four-byte endpoints through U+10FFFF. Malformed vectors
cover stray continuations, overlong forms, truncation, invalid continuations,
encoded surrogate values, values beyond U+10FFFF and illegal leading bytes.
Implementation/dependency case analysis must support generalization beyond these
finite vectors; this remains an engineering review, not a machine-checked proof.

| Necessary condition | Planned independent evidence |
| --- | --- |
| Valid Unicode and opaque data | Exact text from raw BinarySource bytes through source Program::parse and a handmade ImportFile(path,true) AST |
| Malformed UTF-8 | Both entry paths create successfully, then reject on demand instead of returning replacement text |
| Laziness and phase | Invalid bytes in an unselected source/handmade branch make zero requests; source Syntax and source/AST Static controls reuse IR4 rather than duplicating grammar tests |
| Successful repeated demand | Repeated identical source/handmade imports yield two exact strings with one virtual request |
| Failure timing/cache boundary | The same evaluator rejects each demanded invalid import; unused import resolves nothing. Its retained-byte/request observation is a separate host boundary, not general failure-cache acceptance |

## Normative requirement versus embedding policy

The normative requirement is valid text substitution or failure, not a particular
public ErrorKind, message, source location, retry policy or CLI status. The tests
also check the existing embedding Import category and resolved-source/entry
context convention as local regression boundaries. These extra expectations are
not used to claim that the fixed specification mandates that category or message.
If they differ, retain that distinction rather than changing a normative oracle.

The [embedding API](../reference/API.md#reusable-evaluator) promises strict UTF-8
for code/string imports, with a binary callback supplying bytes and a text callback
supplying already decoded String data. New invalid fixtures therefore use only
BinarySource and are decoded by the interpreter's import reader. A host callback
remains responsible for access/identity/resource policy; a supplied String cannot
represent the original invalid byte sequence. The older IR3 text-resolver control
checks opacity, not malformed-byte decoding. Arbitrary ill-formed host UTF-16
strings are outside the byte-input contract.

## Explicit unknown and exclusions

The fixed import paragraph does not specify whether an initial UTF-8 BOM is a
signature or U+FEFF data. Its normative treatment is explicitly unknown here;
do not infer it from the installed decoder's option or change implementation for
it. Interior U+FEFF is ordinary data and is included. No initial-BOM case is
counted as passing this bounded decision.

Canonical aliases, cross-mode cache identity, cycles, code-import scope, host
file I/O, callback replacement/reentry, complete failure-cache lifetime/resource
policy and CLI diagnostics/exits remain outside this batch. No actual imported
file, private document, network, remote, full-suite or Go/C++ execution is planned.
The matrix starts at three completed static judgments, 42 partial rows and
49 unreviewed rows; this work will refine CORE-IMPORT without new inventory rows.
