// Adapted from Go 1.24.0 src/sort/zsortfunc.go and sort.go.
// Copyright 2009, 2022 The Go Authors. All rights reserved.
// BSD-3-Clause: licenses/GO-BSD-3-Clause.txt.

///|
fn FormatImportSorter::break_patterns(
  self : FormatImportSorter,
  a : Int32,
  b : Int32,
) -> Unit {
  let length = b - a
  if length < 8 {
    return
  }
  let mut random = length.to_uint64()
  let mut modulus = 1UL
  while modulus <= length.to_uint64() {
    modulus = modulus << 1
  }
  let middle = a + length / 4 * 2
  for idx in (middle - 1)..<=(middle + 1) {
    random = random ^ (random << 13)
    random = random ^ (random >> 7)
    random = random ^ (random << 17)
    let mut other = (random & (modulus - 1)).to_int()
    if other >= length {
      other -= length
    }
    self.entries.swap(idx, a + other)
  }
}

///|
fn FormatImportSorter::median(
  self : FormatImportSorter,
  x : Int32,
  y : Int32,
  z : Int32,
) -> (Int32, Int32) {
  let mut a = x
  let mut b = y
  let mut c = z
  let mut swaps = 0
  if self.less(b, a) {
    let temp = a
    a = b
    b = temp
    swaps += 1
  }
  if self.less(c, b) {
    let temp = b
    b = c
    c = temp
    swaps += 1
  }
  if self.less(b, a) {
    b = a
    swaps += 1
  }
  (b, swaps)
}

///|
fn FormatImportSorter::choose_pivot(
  self : FormatImportSorter,
  a : Int32,
  b : Int32,
) -> (Int32, Int32) {
  let length = b - a
  let mut i = a + length / 4
  let mut j = a + length / 4 * 2
  let mut k = a + length / 4 * 3
  let mut swaps = 0
  if length >= 8 {
    if length >= 50 {
      let (p, s) = self.median(i - 1, i, i + 1)
      i = p
      swaps += s
      let (p, s) = self.median(j - 1, j, j + 1)
      j = p
      swaps += s
      let (p, s) = self.median(k - 1, k, k + 1)
      k = p
      swaps += s
    }
    let (p, s) = self.median(i, j, k)
    j = p
    swaps += s
  }
  (j, swaps)
}

///|
fn FormatImportSorter::reverse(
  self : FormatImportSorter,
  a : Int32,
  b : Int32,
) -> Unit {
  for i = a, j = b - 1; i < j; i = i + 1, j = j - 1 {
    self.entries.swap(i, j)
  }
}
