///|
/// Evaluate source to Go-style JSON text or an unescaped string. Both modes
/// append one newline. The byte budget excludes that final newline.
/// Options and fresh evaluation state match `evaluate`.
///
/// ```mbt check
/// test {
///   assert_eq(
///     @moonjsonnet.evaluate_text("'hello'", string_output=true),
///     "hello\n",
///   )
/// }
/// ```
pub fn evaluate_text(
  source : String,
  string_output? : Bool = false,
  filename? : String = "<input>",
  anonymous? : Bool = false,
  ext_vars? : Map[String, Json] = Map([]),
  ext_code? : Map[String, String] = Map([]),
  tla_vars? : Map[String, Json] = Map([]),
  tla_code? : Map[String, String] = Map([]),
  native_functions? : Map[String, NativeFunction] = Map([]),
  trace? : (Location, String) -> Unit = default_trace,
  resolver? : (String, String) -> Source raise,
  binary_resolver? : (String, String) -> BinarySource raise,
  limits? : Limits = Limits::default(),
) -> String raise JsonnetError {
  evaluate_with_output(
    source,
    (vm, value, loc) => {
      if string_output {
        guard value is Str(text) else {
          raise problem(Type, loc, "expected string result")
        }
        vm.account_output(@utf8.encode(text).length(), loc)
        text + "\n"
      } else {
        let json = vm.manifest(value, loc, 0)
        cli_json(json, vm.limits.output_bytes, loc) + "\n"
      }
    },
    filename~,
    anonymous~,
    ext_vars~,
    ext_code~,
    tla_vars~,
    tla_code~,
    native_functions~,
    trace~,
    resolver?,
    binary_resolver?,
    limits~,
  )
}

///|
/// Evaluate a top-level array to JSON documents, each ending in a newline.
/// All visible values are manifested before checking the top-level type.
/// The output byte budget is shared across document payloads; final newlines
/// are excluded. String output mode does not apply to streams.
///
/// ```mbt check
/// test {
///   assert_eq(@moonjsonnet.evaluate_stream("[1,'x']"), ["1\n", "\"x\"\n"])
/// }
/// ```
pub fn evaluate_stream(
  source : String,
  filename? : String = "<input>",
  anonymous? : Bool = false,
  ext_vars? : Map[String, Json] = Map([]),
  ext_code? : Map[String, String] = Map([]),
  tla_vars? : Map[String, Json] = Map([]),
  tla_code? : Map[String, String] = Map([]),
  native_functions? : Map[String, NativeFunction] = Map([]),
  trace? : (Location, String) -> Unit = default_trace,
  resolver? : (String, String) -> Source raise,
  binary_resolver? : (String, String) -> BinarySource raise,
  limits? : Limits = Limits::default(),
) -> Array[String] raise JsonnetError {
  evaluate_with_output(
    source,
    (vm, value, loc) => {
      let json = vm.manifest(value, loc, 0)
      guard json is Array(documents) else {
        raise problem(Type, loc, "stream mode requires a top-level array")
      }
      vm.output_bytes = 0
      documents.map(document => {
        let text = cli_json(
          document,
          vm.limits.output_bytes - vm.output_bytes,
          loc,
        )
        vm.account_output(@utf8.encode(text).length(), loc)
        text + "\n"
      })
    },
    filename~,
    anonymous~,
    ext_vars~,
    ext_code~,
    tla_vars~,
    tla_code~,
    native_functions~,
    trace~,
    resolver?,
    binary_resolver?,
    limits~,
  )
}

///|
fn cli_json(json : Json, limit : Int, loc : Location) -> String raise {
  let output = ManifestText::new(limit, loc)
  write_cli_json(json, output, "")
  output.text()
}

///|
fn write_cli_json(
  json : Json,
  output : ManifestText,
  indent : String,
) -> Unit raise {
  let next = indent + "   "
  match json {
    Array(items) =>
      if items.is_empty() {
        output.write("[ ]")
      } else {
        output.write("[\n")
        for i, item in items {
          if i > 0 {
            output.write(",\n")
          }
          output.write(next)
          write_cli_json(item, output, next)
        }
        output.write("\n" + indent + "]")
      }
    Object(fields) => {
      let keys = fields.keys().collect()
      keys.sort_by(compare_unicode)
      if keys.is_empty() {
        output.write("{ }")
      } else {
        output.write("{\n")
        for i, key in keys {
          if i > 0 {
            output.write(",\n")
          }
          output.write(next + manifest_text_quote(key) + ": ")
          write_cli_json(fields[key], output, next)
        }
        output.write("\n" + indent + "}")
      }
    }
    Number(n, ..) => {
      let text = if n.is_inf() || n.is_nan() {
        manifest_number(n)
      } else {
        @number.format(n)
      }
      if text.is_empty() {
        raise problem(Runtime, output.loc, "cannot format output number")
      }
      output.write(text)
    }
    String(text) => output.write(manifest_text_quote(text))
    _ => output.write(json.stringify())
  }
}
