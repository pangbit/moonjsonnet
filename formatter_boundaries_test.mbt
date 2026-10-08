///|
test "formatter assertion scope ends with its enclosing delimiter" {
  for
    (source, expected) in [
      (
        "[{assert true},{assert true, f:1},{f:2}]", "[{ assert true }, { assert true, f: 1 }, { f: 2 }]\n",
      ),
      (
        "{assert {assert true,x:1}.x==1, f:1, assert true:'ok', g:2}", "{ assert { assert true, x: 1 }.x == 1, f: 1, assert true : 'ok', g: 2 }\n",
      ),
      ("[(assert true;true), {f:1}]", "[(assert true; true), { f: 1 }]\n"),
    ] {
    let actual = @moonjsonnet.format_source(source)
    assert_eq(actual, expected)
    assert_eq(@moonjsonnet.format_source(actual), actual)
    assert_eq(@moonjsonnet.evaluate(actual), @moonjsonnet.evaluate(source))
  }
}

///|
test "formatter methods reserved object roots and index brackets retain syntax" {
  for
    (source, expected) in [
      ("{'y'(x=1):x}.y()", "{ y(x=1): x }.y()\n"),
      (
        "{a:1,b:(self+{}).a,c:($+{}).a}", "{ a: 1, b: (self + {}).a, c: ($ + {}).a }\n",
      ),
      (
        "local arr=[1,2,3];[arr[(1):],arr[(1)],[(1),(2)]]", "local arr = [1, 2, 3]; [arr[(1):], arr[(1)], [(1), (2)]]\n",
      ),
    ] {
    let actual = @moonjsonnet.format_source(source)
    assert_eq(actual, expected)
    assert_eq(@moonjsonnet.format_source(actual), actual)
    assert_eq(@moonjsonnet.evaluate(actual), @moonjsonnet.evaluate(source))
  }
  let options = { ..@moonjsonnet.FormatOptions::default(), pad_arrays: true, }
  assert_eq(
    @moonjsonnet.format_source("[(1)][(0)]", options~),
    "[ (1) ][(0)]\n",
  )
}

///|
test "formatter text blocks normalize indentation and preserve decoded values" {
  for
    (source, expected) in [
      ("|||\n    first\n    second\n|||", "|||\n  first\n  second\n|||\n"),
      (
        "{\nx: |||\n      first\n      second\n    |||\n}", "{\n  x: |||\n    first\n    second\n  |||,\n}\n",
      ),
      (
        "[|||-\n    first\n    second\n  |||, |||\n\n  third\n\n|||]", "[|||-\n  first\n  second\n|||, |||\n\n  third\n\n|||]\n",
      ),
    ] {
    let document = @moonjsonnet.ParsedSource::parse(source)
    let actual = document.format()
    assert_eq(actual, expected)
    assert_eq(document.text(), source)
    assert_eq(@moonjsonnet.format_source(actual), actual)
    assert_eq(@moonjsonnet.evaluate(actual), @moonjsonnet.evaluate(source))
  }
  let source = "{x: |||\r\n    first\r\n    second\r\n  |||}"
  assert_eq(
    @moonjsonnet.format_source(source),
    "{ x: |||\n  first\n  second\n||| }\n",
  )
  assert_eq(
    @moonjsonnet.format_source(source, options={
      ..@moonjsonnet.FormatOptions::default(),
      indent: 0,
    }),
    "{ x: |||\n    first\n    second\n  ||| }\n",
  )
  try
    @moonjsonnet.format_source("|||\n a\n|||", options={
      ..@moonjsonnet.FormatOptions::default(),
      indent: 2147483647,
    })
  catch {
    @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
  } noraise {
    _ => fail("expected bounded text block indentation")
  }
}
