///|
fn formatter_sort_fixture(keys : Array[Int]) -> Array[FormatImportEntry] {
  keys.mapi((i, key) => {
    name: "x\{i}",
    key: @utf8.encode(key.to_string()),
    start: i,
    before: "",
    after: "",
  })
}

///|
test "formatter sorter matches pinned Go equal-key permutation" {
  let entries = formatter_sort_fixture(Array::makei(13, i => i * 7 % 5))
  format_import_sort(entries)
  assert_eq(entries.map(e => e.start), [
    5, 10, 0, 8, 3, 6, 1, 11, 4, 9, 7, 2, 12,
  ])
}

///|
test "formatter sorter preserves keys and permutation across partition boundaries" {
  for size in [0, 1, 2, 12, 13, 49, 50, 51, 64, 127, 512, 1024] {
    for pattern in 0..<5 {
      let keys = Array::makei(size, i => {
        match pattern {
          0 => i
          1 => size - i
          2 => 0
          3 => i * 7 % 11
          _ => if i < size / 2 { i } else { size - i }
        }
      })
      for heap in [false, true] {
        let entries = formatter_sort_fixture(keys)
        let originals = entries.map(e => e.key)
        if heap {
          let sorter : FormatImportSorter = { entries, }
          // Exercise the bounded-time fallback independently of pivot luck.
          sorter.pdqsort(0, size, 0)
        } else {
          format_import_sort(entries)
        }
        let seen = Array::make(size, false)
        for i, entry in entries {
          assert_true(!seen[entry.start])
          seen[entry.start] = true
          assert_eq(entry.key, originals[entry.start])
          if i > 0 {
            assert_true(entries[i - 1].key.lexical_compare(entry.key) <= 0)
          }
        }
        assert_true(seen.all(x => x))
      }
    }
  }
}
