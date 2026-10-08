///|
/// Evaluate a top-level object into filename/content pairs without filesystem
/// writes. Values are all manifested before checking types. JSON files end in
/// one newline; with string_output=true, raw strings have no added newline.
/// The payload byte budget is shared by all files, excluding JSON final newlines.
///
/// ```mbt check
/// test {
///   let files = @moonjsonnet.evaluate_multi("{'a.json':42,'b.json':[]}")
///   assert_eq(files["a.json"], "42\n")
///   assert_eq(files["b.json"], "[ ]\n")
/// }
/// ```
pub fn evaluate_multi(
  source : String,
  string_output? : Bool = false,
  filename? : String = "<input>",
  anonymous? : Bool = false,
  ext_vars? : Map[String, Json] = Map([]),
  ext_code? : Map[String, String] = Map([]),
  ext_programs? : Map[String, Program] = Map([]),
  tla_vars? : Map[String, Json] = Map([]),
  tla_code? : Map[String, String] = Map([]),
  tla_programs? : Map[String, Program] = Map([]),
  native_functions? : Map[String, NativeFunction] = Map([]),
  trace? : (Location, String) -> Unit = default_trace,
  resolver? : (String, String) -> Source raise,
  binary_resolver? : (String, String) -> BinarySource raise,
  limits? : Limits = Limits::default(),
) -> Map[String, String] raise JsonnetError {
  Program::parse(source, filename~, anonymous~, limits~).evaluate_multi(
    string_output~,
    ext_vars~,
    ext_code~,
    ext_programs~,
    tla_vars~,
    tla_code~,
    tla_programs~,
    native_functions~,
    trace~,
    resolver?,
    binary_resolver?,
    limits~,
  )
}

///|
/// Execute this validated program with fresh evaluation state. Options and output
/// match `evaluate_multi`; source filename and anonymous mode were fixed when parsed.
pub fn Program::evaluate_multi(
  self : Program,
  string_output? : Bool = false,
  ext_vars? : Map[String, Json] = Map([]),
  ext_code? : Map[String, String] = Map([]),
  ext_programs? : Map[String, Program] = Map([]),
  tla_vars? : Map[String, Json] = Map([]),
  tla_code? : Map[String, String] = Map([]),
  tla_programs? : Map[String, Program] = Map([]),
  native_functions? : Map[String, NativeFunction] = Map([]),
  trace? : (Location, String) -> Unit = default_trace,
  resolver? : (String, String) -> Source raise,
  binary_resolver? : (String, String) -> BinarySource raise,
  limits? : Limits = Limits::default(),
) -> Map[String, String] raise JsonnetError {
  evaluate_with_output(
    self,
    (vm, value, loc) => vm.render_multi(value, loc, string_output),
    ext_vars~,
    ext_code~,
    ext_programs~,
    tla_vars~,
    tla_code~,
    tla_programs~,
    native_functions~,
    trace~,
    resolver?,
    binary_resolver?,
    limits~,
  )
}

///|
fn Vm::render_multi(
  vm : Vm,
  value : Value,
  loc : Location,
  string_output : Bool,
) -> Map[String, String] raise {
  let json = vm.manifest(value, loc, 0)
  guard json is Object(fields) else {
    raise problem(
      Type,
      loc,
      "multi mode: top-level object was a " +
      value_type(value) +
      ", should be an object whose keys are filenames and values hold the JSON for that file.",
    )
  }
  vm.output_bytes = 0
  let files : Map[String, String] = Map([])
  let keys = fields.keys().collect()
  keys.sort_by(compare_unicode)
  for key in keys {
    let text = if string_output {
      guard fields[key] is String(text) else {
        let kind = match fields[key] {
          Number(_, ..) => "float64"
          True | False => "bool"
          Null => "<nil>"
          Array(_) => "[]interface {}"
          Object(_) => "map[string]interface {}"
          _ => abort("string excluded by guard")
        }
        raise problem(
          Type,
          loc,
          "multi mode: top-level object's key " +
          key +
          " has a value of type " +
          kind +
          ", should be a string",
        )
      }
      vm.account_output(@utf8.encode(text).length(), loc)
      text
    } else {
      let text = cli_json(
        fields[key],
        vm.limits.output_bytes - vm.output_bytes,
        loc,
      )
      vm.account_output(@utf8.encode(text).length(), loc)
      text + "\n"
    }
    files[key] = text
  }
  files
}
