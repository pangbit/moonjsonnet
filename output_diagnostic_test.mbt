///|
test "output type diagnostics preserve the rejected type and lazy string mode" {
  for
    (source, kind) in [
      ("null", "null"),
      ("true", "boolean"),
      ("42", "number"),
      ("[error 'unused']", "array"),
      ("{assert false,a:error 'unused'}", "object"),
      ("function() function() 42", "function"),
    ] {
    try @moonjsonnet.evaluate_text(source, string_output=true) catch {
      @moonjsonnet.Error(d) => {
        assert_eq(d.kind, @moonjsonnet.Type)
        assert_eq(d.message, "expected string result, got: " + kind)
      }
    } noraise {
      _ => fail("non-string output accepted")
    }
  }
  for
    (source, kind) in [
      ("{a:42}", "float64"),
      ("{a:true}", "bool"),
      ("{a:null}", "<nil>"),
      ("{a:[]}", "[]interface {}"),
      ("{a:{}}", "map[string]interface {}"),
    ] {
    try @moonjsonnet.evaluate_multi(source, string_output=true) catch {
      @moonjsonnet.Error(d) =>
        assert_eq(
          d.message,
          "multi mode: top-level object's key a has a value of type " +
          kind +
          ", should be a string",
        )
    } noraise {
      _ => fail("non-string multi value accepted")
    }
  }
}

///|
test "import compile errors retain their public category and runtime import frames" {
  let formatter = @moonjsonnet.DiagnosticFormatter::new()
  formatter.set_source({ id: "library", text: "invalid !", })
  try
    @moonjsonnet.evaluate("import 'library'", filename="entry", resolver=(_, _) => {
      id: "library",
      text: "invalid !",
    })
  catch {
    @moonjsonnet.Error(d) => {
      assert_eq(d.kind, @moonjsonnet.Syntax)
      assert_eq(
        formatter.format(d),
        "RUNTIME ERROR: library:1:9-10 Not a binary operator: !\n\tentry:1:1-17\t$\n\tDuring evaluation\t\n",
      )
    }
  } noraise {
    _ => fail("invalid import accepted")
  }
}
