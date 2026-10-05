// Adapted from Go 1.24.0 src/sort/zsortfunc.go and slice.go.
// Copyright 2017, 2022 The Go Authors. All rights reserved.
// BSD-3-Clause: licenses/GO-BSD-3-Clause.txt.

///|
// The exact unstable order is observable in formatted import declarations.
priv struct FormatImportSorter {
  entries : Array[FormatImportEntry]
}

///|
fn FormatImportSorter::less(
  self : FormatImportSorter,
  a : Int,
  b : Int,
) -> Bool {
  self.entries[a].key.lexical_compare(self.entries[b].key) < 0
}

///|
fn format_import_sort(entries : Array[FormatImportEntry]) -> Unit {
  let sorter : FormatImportSorter = { entries, }
  let mut limit = 0
  for n = entries.length(); n > 0; n = n >> 1 {
    limit += 1
  }
  sorter.pdqsort(0, entries.length(), limit)
}

///|
fn FormatImportSorter::pdqsort(
  self : FormatImportSorter,
  start : Int,
  end : Int,
  budget : Int,
) -> Unit {
  let mut a = start
  let mut b = end
  let mut limit = budget
  let mut balanced = true
  let mut partitioned = true
  while true {
    let length = b - a
    if length <= 12 {
      self.insertion_sort(a, b)
      return
    }
    if limit == 0 {
      self.heap_sort(a, b)
      return
    }
    if !balanced {
      self.break_patterns(a, b)
      limit -= 1
    }
    let (chosen, swaps) = self.choose_pivot(a, b)
    let mut pivot = chosen
    let mut increasing = swaps == 0
    if swaps == 12 {
      self.reverse(a, b)
      pivot = b - 1 - (pivot - a)
      increasing = true
    }
    if balanced &&
      partitioned &&
      increasing &&
      self.partial_insertion_sort(a, b) {
      return
    }
    if a > 0 && !self.less(a - 1, pivot) {
      a = self.partition_equal(a, b, pivot)
      continue
    }
    let (mid, already_partitioned) = self.partition(a, b, pivot)
    partitioned = already_partitioned
    let left_len = mid - a
    let right_len = b - mid
    let threshold = length / 8
    if left_len < right_len {
      balanced = left_len >= threshold
      self.pdqsort(a, mid, limit)
      a = mid + 1
    } else {
      balanced = right_len >= threshold
      self.pdqsort(mid + 1, b, limit)
      b = mid
    }
  }
}

///|
fn FormatImportSorter::insertion_sort(
  self : FormatImportSorter,
  a : Int,
  b : Int,
) -> Unit {
  for i in (a + 1)..<b {
    for j = i; j > a && self.less(j, j - 1); j = j - 1 {
      self.entries.swap(j, j - 1)
    }
  }
}

///|
fn FormatImportSorter::sift_down(
  self : FormatImportSorter,
  lo : Int,
  hi : Int,
  first : Int,
) -> Unit {
  let mut root = lo
  while true {
    let mut child = 2 * root + 1
    if child >= hi {
      break
    }
    if child + 1 < hi && self.less(first + child, first + child + 1) {
      child += 1
    }
    if !self.less(first + root, first + child) {
      return
    }
    self.entries.swap(first + root, first + child)
    root = child
  }
}

///|
fn FormatImportSorter::heap_sort(
  self : FormatImportSorter,
  a : Int,
  b : Int,
) -> Unit {
  let hi = b - a
  for i = (hi - 1) / 2; i >= 0; i = i - 1 {
    self.sift_down(i, hi, a)
  }
  for i = hi - 1; i >= 0; i = i - 1 {
    self.entries.swap(a, a + i)
    self.sift_down(0, i, a)
  }
}
