///|
test "remove and removeAt preserve lazy payloads and immutable inputs" {
  for
    (source, expected) in [
      ("std.remove([1,2,1,3],1)", "[2,1,3]"),
      ("std.remove([{a:1,h::2},{a:2}],{a:1})", "[{\"a\":2}]"),
      ("std.removeAt([error 'unused',2],0)", "[2]"),
      (
        "local a=[1,2,3]; local m=std.map(function(x)x,a); [std.length(m),std.removeAt(a,0),m]",
        "[3,[2,3],[1,2,3]]",
      ),
      (
        "local a=[1,2,3]; local s=a[:]; [std.length(s),std.removeAt(a,0),s]", "[3,[2,3],[1,2,3]]",
      ),
      (
        "local a=[1,2,3]; [std.filter(function(x) if x==1 then std.length(std.removeAt(a,0))>0 else true,a),a]",
        "[[1,2,3],[1,2,3]]",
      ),
      (
        "local a=[1,2,3,4]; local b=std.removeAt(a,1); [b,a]", "[[1,3,4],[1,2,3,4]]",
      ),
      (
        "local a=[1,2,3,4]; local b=std.removeAt(a,1); local c=std.removeAt(b,0); [c,b,a]",
        "[[3,4],[1,3,4],[1,2,3,4]]",
      ),
      (
        "local a=[1,2,3,4]; local b=std.removeAt(a,1); [std.length(b),std.removeAt(a,0),b,a]",
        "[3,[2,3,4],[1,3,4],[1,2,3,4]]",
      ),
      (
        "local x=1; local a=[x,2,3]; [std.removeAt(a,0),x,a]", "[[2,3],1,[1,2,3]]",
      ),
    ] {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
  // Fixed remove first computes all find indices; only removeAt is a lazy copy.
  let required = array_contract_error(
    "std.length(std.remove([1,error 'unused'],1))",
  )
  assert_eq(required.kind, @moonjsonnet.Runtime)
  assert_eq(required.message, "unused")
}

///|
test "remove rejects guarded inputs and removeAt preserves unmatched positions" {
  for
    source in [
      "std.remove([error 'forced'],0)", "std.remove([function()0],function()0)",
      "std.remove('abc','a')",
    ] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_true(d.kind != @moonjsonnet.Unsupported)
    } noraise {
      _ => fail("expected remove error: " + source)
    }
  }
  assert_eq(
    @moonjsonnet.evaluate("std.remove([],error 'forced')"),
    Json::array([]),
  )
  // Fixed removeAt filters matching indices; it does not reject unmatched ones.
  for
    (source, expected) in [
      ("std.removeAt([1],-1)", "[1]"),
      ("std.removeAt([1],1)", "[1]"),
      ("std.removeAt([],0)", "[]"),
      ("std.removeAt([1],0.5)", "[1]"),
      ("std.removeAt([1],'0')", "[1]"),
    ] {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
}

///|
test "flat object merge keeps bindings visibility and self while dropping assertions" {
  for
    (source, expected) in [
      ("std['$objectFlatMerge']([])", "{}"),
      (
        "{value:local n=7; std['$objectFlatMerge']([{a:n,b:self.a},{c:self.b}])+{a:9}}.value",
        "{\"a\":9,\"b\":9,\"c\":9}",
      ),
      (
        "{value:local m=std['$objectFlatMerge']([{assert false,a:1,h::2}]); [m,m.h]}.value",
        "[{\"a\":1},2]",
      ),
      (
        "{value:std.objectFieldsAll(std['$objectFlatMerge']([{a:error 'lazy'},{h::error 'lazy'}]))}.value",
        "[\"a\",\"h\"]",
      ),
    ] {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
  for
    source in [
      "std['$objectFlatMerge']([{a:1},{a::2}])", "std['$objectFlatMerge']({})", "std['$objectFlatMerge']([1])",
      "std['$objectFlatMerge']([{a:1}+{b:2}])", "std['$objectFlatMerge']([{local x=1,a:x}])",
    ] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_true(d.kind != @moonjsonnet.Unsupported)
    } noraise {
      _ => fail("expected flat merge error: " + source)
    }
  }
}
