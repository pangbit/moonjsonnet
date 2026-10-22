// Normative sources are pinned to google/jsonnet
// bbb38f1020be1f5aed560928fb839b2c448cefb4. See the P0 matrix in
// docs/development/SPEC-CONFORMANCE.md. Inputs are synthetic and public.

///|
test "P0 immutable array deletion preserves originals and deferred aliases" {
  for
    (source, expected) in [
      (
        "local a=[1,2,3,4]; local b=std.removeAt(a,1); [b,a]", "[[1,3,4],[1,2,3,4]]",
      ),
      ("local a=[1,2,3]; [std.remove(a,2),a]", "[[1,3],[1,2,3]]"),
      (
        "local a=[1,2,3]; local m=std.map(function(x)x,a); [std.length(m),std.removeAt(a,0),m,a]",
        "[3,[2,3],[1,2,3],[1,2,3]]",
      ),
      (
        "local a=[1,2,3]; local s=a[:]; [std.length(s),std.removeAt(a,0),s,a]", "[3,[2,3],[1,2,3],[1,2,3]]",
      ),
      (
        "local a=[1,2,3,4]; local b=std.removeAt(a,1); [std.removeAt(b,0),b,a]",
        "[[3,4],[1,3,4],[1,2,3,4]]",
      ),
      ("[std.removeAt([1],0),std.remove([1,2],3)]", "[[],[1,2]]"),
    ] {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
}
