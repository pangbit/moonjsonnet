// Adapted from Go 1.24.0 src/sort/zsortfunc.go.
// Copyright 2022 The Go Authors. All rights reserved.
// BSD-3-Clause: licenses/GO-BSD-3-Clause.txt.

///|
fn FormatImportSorter::partition(
  self : FormatImportSorter,
  a : Int32,
  b : Int32,
  pivot : Int32,
) -> (Int32, Bool) {
  self.entries.swap(a, pivot)
  let mut i = a + 1
  let mut j = b - 1
  while i <= j && self.less(i, a) {
    i += 1
  }
  while i <= j && !self.less(j, a) {
    j -= 1
  }
  if i > j {
    self.entries.swap(j, a)
    return (j, true)
  }
  self.entries.swap(i, j)
  i += 1
  j -= 1
  while true {
    while i <= j && self.less(i, a) {
      i += 1
    }
    while i <= j && !self.less(j, a) {
      j -= 1
    }
    if i > j {
      break
    }
    self.entries.swap(i, j)
    i += 1
    j -= 1
  }
  self.entries.swap(j, a)
  (j, false)
}

///|
fn FormatImportSorter::partition_equal(
  self : FormatImportSorter,
  a : Int32,
  b : Int32,
  pivot : Int32,
) -> Int32 {
  self.entries.swap(a, pivot)
  let mut i = a + 1
  let mut j = b - 1
  while true {
    while i <= j && !self.less(a, i) {
      i += 1
    }
    while i <= j && self.less(a, j) {
      j -= 1
    }
    if i > j {
      break
    }
    self.entries.swap(i, j)
    i += 1
    j -= 1
  }
  i
}

///|
fn FormatImportSorter::partial_insertion_sort(
  self : FormatImportSorter,
  a : Int32,
  b : Int32,
) -> Bool {
  let mut i = a + 1
  for _ in 0..<5 {
    while i < b && !self.less(i, i - 1) {
      i += 1
    }
    if i == b {
      return true
    }
    if b - a < 50 {
      return false
    }
    self.entries.swap(i, i - 1)
    if i - a >= 2 {
      // Preserve Go's lower bound of 1, rather than replacing it with a + 1.
      for j = i - 1; j >= 1; j = j - 1 {
        if !self.less(j, j - 1) {
          break
        }
        self.entries.swap(j, j - 1)
      }
    }
    if b - i >= 2 {
      for j in (i + 1)..<b {
        if !self.less(j, j - 1) {
          break
        }
        self.entries.swap(j, j - 1)
      }
    }
  }
  false
}
