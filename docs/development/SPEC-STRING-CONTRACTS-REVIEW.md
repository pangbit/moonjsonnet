# String and Unicode contract review

Expectations below precede the new probes and use fixed Google Jsonnet commit
bbb38f1020be1f5aed560928fb839b2c448cefb4:
[public functions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html),
[source definitions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet),
and [language rules](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html).
All seven functions are public and currently lack an independently reviewed
subset in the inventory. All their public arguments are required; none has
optional defaults. Existing Go fixtures and local assertions do not determine
the oracle. New inputs are synthetic and contain no private application data.

| Function | Signature | Independent normal/error/lazy criterion |
| --- | --- | --- |
| char | (n) | A successful result has one codepoint with integer identifier n; scalar examples including NUL and supplementary/maximal codepoints round-trip through codepoint. A fractional identifier cannot be truncated into a different successful identifier. Nonnumber and out-of-range demanded values fail. Unused calls remain lazy. |
| codepoint | (str) | Exactly one codepoint is required; a grapheme made of multiple codepoints is not one character for this operation. NUL yields 0 under the inverse relation, despite the documentation's informal positive qualifier. Nonstrings and empty/multiple-codepoint strings fail without demanding container/function payloads. |
| substr | (str,from,len) | Source asserts string, numeric from, numeric len and nonnegative len in that order. Then size is max(0,min(len,length(str)-from)); only demanded generated characters evaluate str[i+from]. Large finite lengths clamp before allocation/index conversion. Empty generated size performs no index validation. Needed fractional/negative indices fail at indexing. |
| findSubstr | (pat,str) | Source validates pat before str. All overlapping matches return codepoint offsets; empty pattern/input or a longer pattern yields an empty array. No Unicode normalization/case folding is introduced. Invalid pattern rejects without demanding str. |
| stringChars | (str) | String input produces an array of one-codepoint strings, including NUL, combining and supplementary codepoints. Input is shared/cached; elements preserve codepoint order. Primitive kinds rejected by length fail. |
| startsWith | (a,b) | On strings, compare the prefix by codepoint sequence; empty b is true, a shorter than b is false. Both required outer strings are demanded. Primitive length-invalid input kinds fail. |
| endsWith | (a,b) | Same supported string/error domain using suffixes, with empty and supplementary-codepoint boundaries. |

The substring size formula resolves the tested zero/integral generated counts
without deciding the older nonintegral makeArray-cardinality question. In
particular a fractional from with len=0, or a fractional requested length clamped
by an empty string to zero, must not force a nonexistent string index. A huge
requested length clamped to a short suffix does not require a huge array. The
source's explicit assertions also stop before later arguments if an earlier
guard fails; native counters make that observable independently of message text.

## Explicitly unadjudicated scope

Surrogate identifiers U+D800..U+DFFF and their representation/error policy are
not settled here; legacy replacement behavior does not earn normative passing
status. Successful scalar cases and fractional rejection are separate questions.
The char/codepoint inverse relation and the lexical codepoint model establish
NUL=0 rather than a one-based numbering scheme.

stringChars and the prefix/suffix source bodies can mechanically accept some
nonstrings through length or early branches, outside their documented string
domain. Array/object/function input policies and competing-error order there
remain unadjudicated. New type-error assertions use only explicit source guards
or primitive kinds on which length fails. Substring cases whose computed
makeArray size is fractional are also excluded from a new pass/fail criterion.
The earlier eleven cardinality/filter observations are unchanged and not rerun.
Exact diagnostic wording is a tool contract, not standardized by the language.

This batch is separate from frozen af188da Linux verification. Neither its tar
nor its additional archive controller is modified by the new tests or fixes.
