///|
test "string functions preserve Unicode and native Go contracts" {
  for
    (source, expected) in [
      (
        "[std.asciiLower('AbCÄΣ😀'),std.asciiUpper('abCäσ😀'),std.stringChars('a😀中')]",
        "[\"abcÄΣ😀\",\"ABCäσ😀\",[\"a\",\"😀\",\"中\"]]",
      ),
      (
        "[std.stripChars('😀x😀','😀'),std.lstripChars('aaabaaa','a'),std.rstripChars('aaabaaa','a')]",
        "[\"x\",\"baaa\",\"aaab\"]",
      ),
      (
        "[std.findSubstr('aa','aaaa'),std.findSubstr('😀','😀a😀'),std.findSubstr('','a')]",
        "[[0,1,2],[0,2],[]]",
      ),
      (
        "[std.splitLimit('a::b::c','::',1),std.splitLimitR('a::b::c','::',1),std.splitLimitR('aaa','aa',-1),std.splitLimit('a,b',',',0)]",
        "[[\"a\",\"b::c\"],[\"a::b\",\"c\"],[\"a\",\"\"],[\"a,b\"]]",
      ),
      (
        "[std.parseInt('-12'),std.parseInt('-100000000000000000000'),std.parseInt('100000000000000000000'),std.parseHex('Ff'),std.parseOctal('010') ]",
        "[-12,-100000000000000000000,100000000000000000000,255,8]",
      ),
      (
        "[std.equalsIgnoreCase('KelvinK','kELVINk'),std.equalsIgnoreCase('Σσς','ςΣσ'),std.equalsIgnoreCase('ß','ss'),std.equalsIgnoreCase('İ','i'),std.equalsIgnoreCase('ı','I'),std.equalsIgnoreCase('ß','ẞ')]",
        "[true,true,false,false,false,true]",
      ),
      (
        "[std.trim('\\u2003\\u3000x\\u2029'),std.trim('\\u200bx\\u200b'),std.isEmpty(''),std.isEmpty(' '),std.id(x={a:3, b:error 'lazy'}).a]",
        "[\"x\",\"\\u200bx\\u200b\",true,false,3]",
      ),
      (
        "[std.escapeStringJson('a\\n\\u0085😀'),std.escapeStringPython('x'),std.escapeStringBash(\"a'b\"),std.escapeStringDollars('$a'),std.escapeStringXML('<&>')]",
        "[\"\\\"a\\\\n\\\\u0085😀\\\"\",\"\\\"x\\\"\",\"'a'\\\"'\\\"'b'\",\"$$a\",\"&lt;&amp;&gt;\"]",
      ),
      (
        "[std.resolvePath('a/b/c','../d'),std.resolvePath('a','b'),std.resolvePath('/a/b','/c')]",
        "[\"a/b/../d\",\"b\",\"/a//c\"]",
      ),
    ] {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
}

///|
test "string argument and numeric parsing boundaries" {
  for
    source in [
      "std.parseInt('')",
      "std.parseInt('+')",
      "std.parseInt('-')",
      "std.parseInt('1_0')",
      "std.parseInt(' 1')",
      "std.parseInt('1 ')",
      "std.parseInt('0x10')",
      "std.parseInt('１２')",
      "std.parseInt('1" + "0".repeat(310) + "')",
      "std.parseInt('-1" + "0".repeat(310) + "')",
      "std.parseInt(1)",
      "std.parseHex('0x10')",
      "std.parseOctal('8')",
      "std.parseHex('-1')",
      "std.splitLimit('a,b',',',0.5)",
      "std.splitLimitR('a,b',',',-2)",
      "std.splitLimit('a','',1)",
      "std.isEmpty([])",
      "std.trim(null)",
      "std.equalsIgnoreCase('a',1)",
      "std.id(error 'eager')",
      "std.stripChars('a',error 'eager')",
      "std.stripChars([], 'a')",
      "std.stripChars('a', null)",
    ] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_true(d.kind != @moonjsonnet.Unsupported)
    } noraise {
      _ => fail("expected error: " + source)
    }
  }
}
