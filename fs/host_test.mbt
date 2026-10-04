///|
fn search_test_root() -> String raise {
  let suffix = @env.rand(16)
    .unwrap()
    .to_array()
    .map(b => b.to_int().to_string())
    .join("-")
  let root = "_build/host-search-" + suffix
  assert_true(@posix.mkdir_all(root + "/local"))
  assert_true(@posix.mkdir_all(root + "/low"))
  assert_true(@posix.mkdir_all(root + "/high"))
  root
}

///|
test "library priority, importer directory, absolute paths and entry loading" {
  let root = search_test_root()
  assert_true(@posix.write(root + "/low/value", "21"))
  assert_true(@posix.write(root + "/high/value", "42"))
  assert_true(@posix.write(root + "/local/value", "7"))
  assert_true(@posix.write(root + "/entry", "import 'value'"))
  let paths = ["low", "high"]
  let host = @fs.FileHost::new(root, jpaths=paths)
  paths[1] = "low"
  assert_eq(host.resolve("", "value").text, "42")
  assert_eq(host.resolve(root + "/local/entry", "value").text, "7")
  assert_eq(
    host.resolve(@posix.canonical(root + "/local").unwrap() + "/entry", "value").text,
    "7",
  )
  assert_eq(
    host.resolve("", @posix.canonical(root + "/low/value").unwrap()).text,
    "21",
  )
  assert_eq(@fs.evaluate_file("entry", root~, jpaths=["low", "high"]), 42)
  assert_true(!host.load("entry").text.is_empty())
  try host.load("value") catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Import)
  } noraise {
    _ => fail("entry file must not search libraries")
  }
}

///|
test "successful and missing attempts remain stable until a fresh host" {
  let root = search_test_root()
  assert_true(@posix.write(root + "/high/value", "42"))
  let host = @fs.FileHost::new(root, jpaths=["high"])
  assert_eq(host.resolve("", "value").text, "42")
  assert_true(@posix.write(root + "/value", "7"))
  assert_true(@posix.write(root + "/high/value", "21"))
  assert_eq(host.resolve("", "./value").text, "42")
  assert_eq(@utf8.decode(host.resolve_binary("", "high/./value").bytes), "42")
  try host.resolve("", "missing") catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Import)
  } noraise {
    _ => fail("missing import must fail")
  }
  assert_true(@posix.write(root + "/high/missing", "1"))
  try host.resolve("", "./missing") catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Import)
  } noraise {
    _ => fail("negative attempts must remain cached")
  }
  let fresh = @fs.FileHost::new(root, jpaths=["high"])
  assert_eq(fresh.resolve("", "value").text, "7")
  assert_eq(fresh.resolve("", "missing").text, "1")
}

///|
test "library errors do not fall through and byte limits are retained" {
  let root = search_test_root()
  assert_true(@posix.mkdir_all(root + "/high/value"))
  assert_true(@posix.write(root + "/low/value", "42"))
  let host = @fs.FileHost::new(root, jpaths=["low", "high"])
  try host.resolve("", "value") catch {
    @moonjsonnet.Error(d) => {
      assert_eq(d.kind, @moonjsonnet.Import)
      assert_eq(d.message, "expected regular file")
    }
  } noraise {
    _ => fail("directory must not fall through")
  }
  assert_true(@posix.write(root + "/high/large", "123"))
  assert_true(@posix.write(root + "/low/large", "1"))
  let limited = @fs.FileHost::new(root, jpaths=["low", "high"], max_bytes=2)
  try limited.resolve_binary("", "large") catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("byte limit must not fall through")
  }
  try host.resolve("", "x\u0000y") catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Import)
  } noraise {
    _ => fail("NUL path must fail")
  }
}
