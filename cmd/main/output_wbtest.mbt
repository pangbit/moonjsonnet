///|
test "output parent follows POSIX dirname and lexical cleanup" {
  for
    (path, parent) in [
      ("x", "."),
      (".", "."),
      ("/x", "/"),
      ("/", "/"),
      ("x/", "x"),
      ("x//y", "x"),
      ("a/../b", "."),
      ("../../x", "../.."),
      ("/../../x", "/"),
      ("a//b/../x", "a"),
      ("a/..", "a"),
    ] {
    assert_eq(output_parent(path), parent)
  }
}
