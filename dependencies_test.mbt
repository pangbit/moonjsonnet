///|
test "dependency scan is static recursive sorted and excludes every entry" {
  let files = Map([
    (
      "main", b"local unused=import 'z'; if false then import 'a' else error 'not evaluated'",
    ),
    ("a", b"[import 'main', importstr 'raw']"),
    ("z", b"importbin 'raw'"),
    ("raw", b"\xff\x00"),
  ])
  let requests = []
  let resolver : (String, String) -> @moonjsonnet.BinarySource raise = (
    from,
    path,
  ) => {
    requests.push((from, path))
    @moonjsonnet.BinarySource::{ id: path, bytes: files[path], }
  }
  assert_eq(
    @moonjsonnet.find_dependencies("origin", ["main", "z"], resolver~),
    ["a", "raw"],
  )
  assert_true(requests.contains(("origin", "main")))
  assert_true(requests.contains(("a", "main")))
  assert_eq(@moonjsonnet.find_dependencies("", [], resolver~), [])
}

///|
test "dependency identities cache aliases and requests only within a scan" {
  let mut reads = 0
  let mut data = b"import 'leaf'"
  let resolver : (String, String) -> @moonjsonnet.BinarySource raise = (_, path) => {
    reads += 1
    match path {
      "main" =>
        @moonjsonnet.BinarySource::{
          id: path,
          bytes: b"[import 'a',import 'a',import 'alias']",
        }
      "a" | "alias" => { id: "same", bytes: data, }
      _ => { id: path, bytes: b"1", }
    }
  }
  assert_eq(@moonjsonnet.find_dependencies("", ["main"], resolver~), [
    "leaf", "same",
  ])
  assert_eq(reads, 4)
  data = b"1"
  assert_eq(@moonjsonnet.find_dependencies("", ["main"], resolver~), ["same"])
  assert_eq(reads, 7)
}

///|
test "dependency scan preserves Go raw masking and omitted object assertions" {
  let files = Map([
    ("main", b"[importstr 'a',import 'a',{assert import 'missing'}]"),
    ("a", b"import 'leaf'"),
  ])
  assert_eq(
    @moonjsonnet.find_dependencies("", ["main"], resolver=fn(_, path) {
      { id: path, bytes: files[path], }
    }),
    ["a"],
  )
  files["a"] = b"local"
  try
    @moonjsonnet.find_dependencies("", ["main"], resolver=fn(_, path) {
      { id: path, bytes: files[path], }
    })
  catch {
    @moonjsonnet.Error(d) => {
      assert_eq(d.kind, @moonjsonnet.Syntax)
      assert_eq(d.location.file, "a")
    }
  } noraise {
    _ => fail("code is parsed even after raw identity was seen")
  }
}

///|
test "dependency failures and resource budgets do not run Jsonnet" {
  let defaults = @moonjsonnet.Limits::default()
  for
    limits in [
      { ..defaults, imports: 1, },
      { ..defaults, import_bytes: 18, },
      { ..defaults, source_bytes: 1, },
      { ..defaults, steps: 1, },
      { ..defaults, output_bytes: 4, },
      { ..defaults, depth: 1, },
      { ..defaults, stack: 0, },
    ] {
    try
      @moonjsonnet.find_dependencies("", ["main"], limits~, resolver=fn(
        _,
        path,
      ) {
        {
          id: path,
          bytes: if path == "main" {
            b"[import 'leaf']"
          } else {
            b"123456"
          },
        }
      })
    catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
    } noraise {
      _ => fail("expected scan budget")
    }
  }
  try
    @moonjsonnet.find_dependencies("", ["main"], resolver=fn(_, _) raise {
      fail("resolver failed")
    })
  catch {
    @moonjsonnet.Error(d) => {
      assert_eq(d.kind, @moonjsonnet.Import)
      assert_true(d.message.contains("resolver failed"))
    }
  } noraise {
    _ => fail("expected import failure")
  }
  try
    @moonjsonnet.find_dependencies("", ["main"], resolver=fn(_, path) {
      { id: path, bytes: b"\xff", }
    })
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Import)
  } noraise {
    _ => fail("expected invalid code UTF-8")
  }
}

///|
test "dependency graph depth does not recurse on the native stack" {
  let limits = {
    ..@moonjsonnet.Limits::default(),
    // 601 files plus the distinct request from file 600 back to entry 0.
    imports: 602,
    depth: 16,
    stack: 1,
  }
  let dependencies = @moonjsonnet.find_dependencies("", ["0"], limits~, resolver=(
    _,
    path,
  ) => {
    let n = @string.parse_int(path)
    let text = if n == 600 {
      "import '0'"
    } else {
      "import '" + (n + 1).to_string() + "'"
    }
    { id: path, bytes: @utf8.encode(text), }
  })
  assert_eq(dependencies.length(), 600)
  assert_true(dependencies.contains("600"))
  assert_true(!dependencies.contains("0"))
}
