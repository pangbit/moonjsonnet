# Canonical Base64 decoding and explicit UTF-8 text

## Fixed contract

This review uses Google Jsonnet
`bbb38f1020be1f5aed560928fb839b2c448cefb4`. The public
[base64DecodeBytes paragraph](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#L3426-L3445)
returns byte numbers from padded Base64 without line breaks, consuming the output
of `std.base64`. The public
[base64Decode paragraph](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#L3455-L3475)
returns a naively encoded String. Although deprecated, it remains a public
function. Its
[source definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1424-L1426)
joins `std.char` applied to each decoded byte. The public
[char definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#L422-L438)
assigns that number as the resulting character's codepoint.

Consequently, `base64Decode('6Q==')` yields `"é"` (U+00E9), and
`base64Decode('w6k=')` yields `"Ã©"` (U+00C3/U+00A9). Explicit
`decodeUTF8(base64DecodeBytes('w6k='))` instead yields `"é"`, following the
separate [UTF-8 operations](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#L1329-L1376).
These are independent expectations derived from fixed definitions; no reference
interpreter supplies their answer.

The raw public HTML SHA-256 is
`0eb80c0ccaf781c4c2c1bc06a22d2d6e57f9866f41c0b62431b5ca4f510e6853`;
the upstream standard-library source SHA-256 is
`e76dd6b8e51a2ca041b292dadea9c5521aeea5781b0ffe7c2c683865e7e45351`.
The canonical String input domain is unambiguous across these sources. This
record does not settle malformed encodings or source-defined non-String admission.

## Independent contract and original RED

The [twelve contract groups](../../spec_base64_decode_contract_test.mbt) were
frozen before product changes at `b60c0357acd38710bf9a4a4b368702ebdf7d1372`:
711 existing inputs plus two new test files. Their literal vectors reuse the
independent octet arithmetic from the [encoder contract](SPEC-BASE64-CONTRACT-2026-10-26.md),
without running the maintained encoder to generate expected answers.

| Groups | Obligation and entry scope |
| --- | --- |
| C01-C02 | Required `str`, positional/named/alias binding, empty and ASCII results, result heads, binding errors before supplied demand; source and handmade AST |
| C03-C04 | Separate source and AST byte-to-character witnesses, so one failure cannot block the other entry |
| C05 | DecodeBytes: all 256 individual octets, ten mixed-length sequences, the full alphabet and `+`/`/`; both entries |
| C06-C07 | Separate source and AST vectors of all 256 one-byte Strings |
| C08-C09 | Mixed lengths, zero/high bytes, full alphabet, String lengths; both entries planned with recorded first-failure cutoffs |
| C10 | Literal byte, text and Base64 controls for explicit valid UTF-8 composition; both entries |
| C11-C12 | Required errors, unambiguous invalid heads and unused-expression laziness; C11 both entries, C12 source-only alias/immutability controls |

The 2026-10-26 macOS native debug baseline used closed stdin, frozen dependencies,
one worker and serial execution. Check exited 0 in 0.723s. The contract exited 2
in 9.746s: **6 passed, 6 failed**. C03, C04, C06, C07, C08 and C09 failed;
C01, C02, C05, C10, C11 and C12 passed. Both primary entries returned
`["�","�","é","\u0000\u0001�"]` instead of
`["é","ÿ","Ã©","\u0000\u0001ÿ"]` for `6Q==`, `/w==`, `w6k=` and `AAH/`.
C06 and C07 each evaluated the entire 256-value vector before comparison:
0..127 matched, while 128..255 all became U+FFFD.

C08 completed the first two mixed vectors, including both entry paths and length
checks. The third source result, `AH+A`, was codepoints `[0,127,65533]` instead
of `[0,127,128]`. Its AST result, both length checks and all later vectors were
NOTRUN. C09 evaluated and failed the full-alphabet source value; its AST value
and both length checks were NOTRUN. Those historical cutoffs must remain even
if a later candidate completes the same unchanged groups.

The unchanged legacy encoding tests passed 2/2 in 0.286s. The separate
[observation collector](../../spec_base64_decode_profile_test.mbt) exited 0 in
0.402s and emitted 48 records: 12 inputs, two functions and two entry paths.
Sixteen returned values and 32 returned errors; all 24 source/AST pairs agreed.
They earn **zero normative passes**. The four-command run took 11.703s; input
hashes stayed stable, and all owned process groups and the controller exited.

| Preserved baseline artifact | SHA-256 |
| --- | --- |
| Original freeze | `1de7b400160e59a2018c00ae4d4aa0d082b9b09318a0f7c2460a92699321cb47` |
| Contract failure stdout | `f9f8afe7babe1da093b6ede2c624c81a88a95637f5f3dcc658b8318b4444167f` |
| Observation stdout | `5008b2e3a439163b51cf655e23bfe7b574cbc65687815ff786cbaa662157274b` |
| Unchanged legacy stdout | `ddd0722f90fd133207ca9e423fc1faa05c3608f3be5c5eb4fdbea4259682b120` |
| Execution result | `3e22babf7c492c19a12425b061e089aa794daa137acf005093290f1df5152492` |
| Assessment with blocked subbranches | `ea383e4a9a456b6aecf139d9882851047096d688ad9923a615c1eda4d1540262` |

## Candidate and exact legacy migration

The candidate changes only the final `base64Decode` conversion in
[std_encoding.mbt](../../std_encoding.mbt). Each decoded Byte becomes its
corresponding Char in a StringBuilder. Every Byte is in 0..255, hence is a valid
Unicode codepoint. Argument binding/demand, the shared Base64 parser,
`base64DecodeBytes`, `byte_array`, `decodeUTF8` and its UTF-8 helper are unchanged.
Existing decoder budget checks remain in the shared parser. The independent
twelve groups and all 48 observation inputs retain their original bytes.

Two expectations in one [legacy tuple](../../std_encoding_test.mbt) migrate:

| Original input | Original expectation | Candidate expectation | Fixed reason |
| --- | --- | --- | --- |
| `std.base64Decode('w6k=')` | `"é"` | `"Ã©"` | Bytes 195 and 169 map through `char` separately; the former result performed UTF-8 decoding |
| `std.base64Decode('6Q==')` | `"�"` | `"é"` | Byte 233 maps to U+00E9; the former result replaced it as an incomplete UTF-8 sequence |

The tuple's third result, `base64DecodeBytes(str='AAH/') == [0,1,255]`, and every
other legacy assertion remain unchanged. The original file and its passing
baseline survive as historical compatibility evidence. This is a definition-led
migration of two concrete values, not a snapshot refresh or a reference-output
update.

## Directed validation of the repaired candidate

The repaired candidate passed the unchanged twelve groups on 2026-10-26, using
macOS native debug, frozen dependencies, closed stdin, one worker and serial
execution. The frozen manifest contains 714 inputs: 711 tracked entries at
`b60c035` with the two documented modifications, plus the two independent test
files and this record. All executable expectations and observed inputs were
frozen before the repair; only the two justified legacy results migrated.

```sh
moon check . --target native --frozen --deny-warn -j 1
moon test spec_base64_decode_contract_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize
moon test spec_base64_decode_profile_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize
moon test std_encoding_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize
moon test spec_base64_contract_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize
moon test arguments_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize
moon test spec_string_scalar_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize
```

| Stage | Actual result | Seconds | Exit |
| --- | --- | ---: | ---: |
| Check | Passed | 0.784 | 0 |
| Decoder contract | 12/12 groups | 12.595 | 0 |
| Observation collector | 48 records, zero normative passes | 0.505 | 0 |
| Migrated legacy encoding | 2/2 groups | 0.290 | 0 |
| Encoder contract | 15/15 groups | 2.108 | 0 |
| Argument regression | 1/1 group | 0.188 | 0 |
| String-scalar regression | 4/4 groups | 0.337 | 0 |

The seven-command run took 17.861s within its 600s budget. All 714 input hashes
stayed stable, and all owned process groups and the controller exited with an
independent absence check. C08 now completes all ten vectors and C09 the full
alphabet, including their source/AST value and length assertions. The original
six failures and their historical NOTRUN subbranches are retained, alongside
these new passing results. Observation stdout is byte-identical to baseline;
the 48 observations do not become normative passes.

| Executed artifact | SHA-256 |
| --- | --- |
| Candidate freeze | `d719bd55b3d2f27d45b1f17d6cd50dc4ec145d8fcfc73646b94613d6b8b736c1` |
| Candidate input manifest | `335788ef081f01bcca81ca8a83169f3281e019d5c388fc02348a19e5229caab5` |
| Product encoding source | `fbc685fe54e38d70d7ba1304725e3cd92969b783f00c573e999bd6687b74268f` |
| Migrated legacy test | `7f95c69c5264c02382e03cd5ace0d9afc1dae7a6514e630849f5defa80e103bc` |
| Passing decoder stdout | `93c9e82a1dd3b474b47ec50aaa8d469426ac678830197ac3f32118be93f2c7ff` |
| Execution result | `5e14a08b22f4e9bc47a1e032668a6ab2080b6894073b8ab06d470b610f24af0f` |
| Assessment | `ff58e5d9960ccf35cbf319accae56afb21365ef313c2ca5aedac1670babd2408` |

This record's result text and the conformance summary are later documentation
bytes than the executed candidate. Subsequent `moon info --frozen`, `moon fmt`
and `moon fmt --check` each exited 0. All product and test files remain
byte-identical to the executed candidate, including all 20 generated interfaces;
no token or literal migration is needed. The other 712 candidate inputs remain
unchanged. Full-suite, release, Linux and independent CLI/API runs are NOTRUN
for this changed implementation. The earlier 851-test encoder result remains
bound to its previous implementation.

## Remaining boundaries

- **B64D-M0:** missing/interior/trailing padding, nonzero pad bits, CR/LF and
  nonstandard alphabet remain ungraded outside this canonical input domain.
- **B64D-A0:** empty Array/Object and zero-arity Function admission remain
  observations where source behavior and the public `str` domain need separate
  review. This repair does not change their existing rejection.
- Invalid UTF-8 recovery remains a separate explicit-decoder profile. Encoder
  B64-R0/F0 and generic language disputes are not decided by this repair.

This is bounded evidence for the decoded-byte mapping and its direct controls.
It does not establish whole-function acceptance. Overall
[specification conformance](SPEC-CONFORMANCE.md) remains incomplete.
