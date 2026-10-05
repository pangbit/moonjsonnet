///|
fn text(input : Json, key : String, fallback : String) -> String {
  match input {
    Object(fields) =>
      match fields.get(key) {
        Some(String(s)) => s
        _ => fallback
      }
    _ => fallback
  }
}

///|
fn run(input : Json) -> Json {
  let mut error = ""
  let result = try {
    let original = @moonjsonnet.Program::parse(
      text(input, "source", ""),
      filename="entry",
    )
    let tree = original.ast().clone()
    if text(input, "op", "") == "ranges" || text(input, "op", "") == "numbers" {
      let copied = @moonjsonnet.Program::from_ast(tree).ast()
      return {
        "result": if text(input, "op", "") == "numbers" {
          number_spellings(copied, input)
        } else {
          range_result(copied, input)
        },
        "error": "",
        "requests": [],
        "trace": "",
        "native_calls": 0,
      }
    }
    let replacement = @moonjsonnet.Program::parse(
      text(input, "replacement", "42"),
      filename="entry",
    ).ast()
    let op = text(input, "op", "clone")
    let edited = match op {
      "array-first" => {
        guard tree.kind is Arr(xs) && !xs.is_empty() else {
          fail("expected array")
        }
        xs[0] = replacement
        tree
      }
      "add" =>
        {
          kind: @moonjsonnet.AstKind::Binary("+", tree, replacement),
          loc: tree.loc,
          end: None,
        }
      _ => tree
    }
    let program = @moonjsonnet.Program::from_ast(edited)
    let evaluate = fn(program : @moonjsonnet.Program) raise {
      match text(input, "mode", "") {
        "stream" => Json::array(program.evaluate_stream().map(Json::string))
        "multi" =>
          Json::object(
            program.evaluate_multi().map((_, value) => Json::string(value)),
          )
        "text" => Json::string(program.evaluate_text())
        _ => program.evaluate()
      }
    }
    if op == "ext" {
      @moonjsonnet.evaluate(
        "std.extVar('x')",
        ext_programs=Map([("x", program)]),
      )
    } else if op == "tla" {
      @moonjsonnet.evaluate("function(x) x", tla_programs=Map([("x", program)]))
    } else {
      Json::array([evaluate(original), evaluate(program)])
    }
  } catch {
    @moonjsonnet.Error(d) => {
      error = d.format()
      Json::null()
    }
    e => {
      error = e.to_string()
      Json::null()
    }
  }
  {
    "result": result,
    "error": error,
    "requests": [],
    "trace": "",
    "native_calls": 0,
  }
}

///|
fn main {
  try {
    let (status, bytes) = @posix.read_stdin(1048576)
    guard status == 0 else { fail("cannot read fixture") }
    guard @posix.stdout(
      run(@json.parse(@utf8.decode(bytes))).stringify() + "\n",
    ) else {
      fail("cannot write result")
    }
  } catch {
    e => {
      @posix.stderr(e.to_string())
      @posix.exit(2)
    }
  }
}
