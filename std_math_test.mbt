///|
test "math and boolean standard functions use reviewed contracts" {
  for
    (source, expected) in [
      (
        "[std.sqrt(4),std.hypot(a=3,b=4),std.pow(x=2,n=10),std.modulo(-5,2),std.mod(5,2),std.mod('%02d',3)]",
        "[2,5,1024,-1,1,\"03\"]",
      ),
      (
        "[std.sin(0),std.cos(0),std.tan(0),std.asin(0),std.acos(1),std.atan(0),std.atan2(y=0,x=1),std.log(1),std.exp(0)]",
        "[0,1,0,0,0,0,0,0,1]",
      ),
      (
        "[std.deg2rad(180)==std.pi,std.rad2deg(std.pi),std.log2(2),std.log10(10),std.sign(-2),std.sign(0),std.sign(2)]",
        "[true,180,1,1,-1,0,1]",
      ),
      (
        "[std.xor(true,false),std.xor(true,true),std.xnor(false,false),std.xnor(x=true,y=false)]",
        "[true,false,true,false]",
      ),
      (
        "[std.isEven(2.9),std.isOdd(-3.2),std.isInteger(2),std.isInteger(2.5),std.isDecimal(2.5),std.isDecimal(2)]",
        "[true,true,true,false,true,false]",
      ),
      (
        "[std.round(-2.5),std.round(-1.5),std.round(-0.5),std.round(0.49999999999999994),std.round(0.5),std.round(1.5),std.round(4503599627370497)]",
        "[-2,-1,0,1,1,2,4503599627370498]",
      ),
      (
        "[std.toString(std.round(-0.1)),std.toString(std.round(0)),std.toString(std.mantissa(-0))]",
        "[\"0\",\"0\",\"-0\"]",
      ),
      (
        "[std.mantissa(8),std.exponent(8),std.mantissa(-0.25),std.exponent(-0.25),std.mantissa(5e-324),std.exponent(5e-324),std.mantissa(1.7976931348623157e308),std.exponent(1.7976931348623157e308)]",
        "[0.5,4,-0.5,-1,0.5,-1073,0.9999999999999999,1024]",
      ),
    ] {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
}

///|
test "math argument and domain errors remain explicit" {
  for
    source in [
      "std.sqrt(-1)", "std.log(0)", "std.log(-1)", "std.acos(2)", "std.asin(-2)",
      "std.exp(1000)", "std.pow(-2,0.5)", "std.pow(0,-1)", "std.modulo(1,0)", "std.round('1')",
      "std.isEven(true)", "std.isOdd([])", "std.isInteger(null)", "std.isDecimal({})",
      "std.xor(1,true)", "std.xnor(false,0)", "std.xor(true,error 'forced')", "std.pow(base=2,exp=3)",
      "std.mantissa(std.sum([1e308,1e308]))", "std.round(std.sum([1e308,1e308]))",
      "std.sqrt(std.sum([1e308,1e308]))",
    ] {
    try @moonjsonnet.evaluate(source) catch {
      @moonjsonnet.Error(d) => assert_true(d.kind != @moonjsonnet.Unsupported)
    } noraise {
      _ => fail("expected error: " + source)
    }
  }
}

///|
test "math preserves fixed Go native rounding and underflow" {
  for
    (source, expected) in [
      (
        "[std.sin(7),std.tan(std.pi/4),std.asin(100/101)]",
        if @number.reference_amd64() {
          "[0.65698659871878906,1,1.4299604532284791]"
        } else {
          "[0.6569865987187892,0.9999999999999998,1.4299604532284793]"
        },
      ),
      (
        "[std.sin(536870913),std.sin(1e200),std.tan(1e20)]",
        if @number.reference_amd64() {
          "[-0.61889108887921074,-0.64396871853950577,-0.84460246301988406]"
        } else {
          "[-0.6188910888792108,-0.6439687185395057,-0.8446024630198842]"
        },
      ),
      (
        "[std.exp(-745),std.pow(19/7,-5/13),std.pow(19/7,5/13)]",
        if @number.reference_amd64() {
          "[4.9406564584124654e-324,0.68109767792436338,1.4682181901537052]"
        } else {
          "[0,0.6810976779243634,1.4682181901537052]"
        },
      ),
      (
        "[std.toString(std.pow(-0,3)),std.toString(std.pow(-2,-1075)),std.toString(std.atan2(-0,-0))]",
        "[\"-0\",\"-0\",\"-3.1415926535897931\"]",
      ),
    ] {
    assert_eq(@moonjsonnet.evaluate(source), @json.parse(expected))
  }
}
