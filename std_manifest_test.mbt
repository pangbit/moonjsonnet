///|
test "JSON output style defaults escaping and lazy objects" {
  for
    (source, expected) in [
      (
        "std.manifestJsonEx({b:[1],a:{}},'  ')", "{\n  \"a\": {\n\n  },\n  \"b\": [\n    1\n  ]\n}",
      ),
      ("std.manifestJsonEx({x:[]},'--','|','=>')", "{|--\"x\"=>[||--]|}"),
      (
        "std.manifestJsonEx(value={x:1},indent='',key_val_sep='=')", "{\n\"x\"=1\n}",
      ),
      ("std.manifestJsonMinified({b:[],a:{}})", "{\"a\":{},\"b\":[]}"),
      ("std.manifestJson({assert false,x::error 'hidden'})", "{\n\n}"),
      ("std.manifestJsonMinified('<>&\\u2028\\u2029')", "\"<>&\\u2028\\u2029\""),
      (
        "std.manifestJsonEx([-0,0.1,1e-20],'','',':')", "[-0,0.1,0.00000000000000000001]",
      ),
    ] {
    assert_eq(@moonjsonnet.evaluate(source), Json::string(expected))
  }
}

///|
test "source output functions use reference layouts" {
  for
    (source, expected) in [
      (
        "std.manifestPython({b:[true,false,null],a:'é'})", "{\"a\": \"é\", \"b\": [True, False, None]}",
      ),
      ("std.manifestPythonVars({b:false,a:1})", "a = 1\nb = False\n"),
      ("std.manifestPythonVars({})", ""),
      (
        "std.manifestIni({main:{z:['x','y'],a:1},sections:{s:{b:true}}})", "a = 1\nz = x\nz = y\n[s]\nb = true\n",
      ),
      ("std.manifestIni({sections:{}})", ""),
      (
        "std.manifestXmlJsonml(['p',{b:'2',a:'1'},['br'],'<>&'])", "<p a=\"1\" b=\"2\"><br></br><>&</p>",
      ),
    ] {
    assert_eq(@moonjsonnet.evaluate(source), Json::string(expected))
  }
}

///|
test "output functions validate arguments and visible values" {
  for
    source in [
      "std.manifestJsonEx(indent='',newline='')", "std.manifestJsonEx(value=1,newline='')",
      "std.manifestJsonEx(1,null)", "std.manifestJsonEx(1,'',newline=[])", "std.manifestJsonEx(1,'',key_val_sep=error 'forced')",
      "std.manifestJsonEx({assert false,x:1},'')", "std.manifestJsonMinified([function(x)x])",
      "std.manifestPython(function(x)x)", "std.manifestPythonVars([])", "std.manifestIni({main:{a:1}})",
      "std.manifestXmlJsonml([])", "std.manifestXmlJsonml(['p',1])",
    ] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_true(d.kind != @moonjsonnet.Unsupported)
    } noraise {
      _ => fail("expected output error: " + source)
    }
  }
}

///|
test "JSON output enforces size and depth limits" {
  for
    source in [
      "std.manifestJsonEx([1,2,3],'0123456789')", "std.manifestJsonMinified({x:self})",
    ] {
    let limits = {
      ..@moonjsonnet.Limits::default(),
      output_bytes: 32,
      depth: 20,
    }
    try @moonjsonnet.evaluate(source, limits~) catch {
      @moonjsonnet.Error(d) => assert_eq(d.kind, @moonjsonnet.Limit)
    } noraise {
      _ => fail("expected output limit: " + source)
    }
  }
}
