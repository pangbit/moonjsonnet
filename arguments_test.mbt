///|
test "builtin and closure argument validation precedes forcing" {
  let messages = [
    ("std.length()", "Missing argument: x"),
    ("std.substr(len=1)", "Missing argument: str"),
    ("std.manifestJsonEx(indent='')", "Missing argument: value"),
    ("std.sort(keyF=function(x) x)", "Missing argument: arr"),
    (
      "std.length(error 'unused',error 'unused')", "function expected 1 positional argument(s), but got 2",
    ),
    ("std.length(unknown=error 'unused')", "function has no parameter unknown"),
    (
      "std.length(error 'unused',x=error 'unused')", "Argument x already provided",
    ),
    (
      "(function(x) x)(error 'unused',x=error 'unused')", "Argument x already provided",
    ),
    (
      "(function(x) x)(0,1,x=2)", "function expected 1 positional argument(s), but got 2",
    ),
    ("std.manifestJsonEx(1,'',value=2)", "Argument value already provided"),
  ]
  for (source, expected) in messages {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(diagnostic) => {
        assert_eq(diagnostic.kind, @moonjsonnet.Runtime)
        assert_eq(diagnostic.message, expected)
      }
    } noraise {
      _ => fail("expected invalid call: " + source)
    }
  }
  assert_eq(
    @moonjsonnet.evaluate("std.substr(len=2,from=1,str='abcd')"),
    Json::string("bc"),
  )
  assert_eq(
    @moonjsonnet.evaluate("std.manifestJsonEx(indent='',value={a:1})"),
    Json::string("{\n\"a\": 1\n}"),
  )
}
