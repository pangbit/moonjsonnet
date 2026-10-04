///|
/// Evaluate Jsonnet source into JSON. Imports are disabled unless a resolver is
/// provided. Each call has independent caches and resource counters.
/// `ext_code` and `tla_code` contain lazy Jsonnet expressions in clean scopes.
/// Code overrides JSON for duplicate names. A top-level function is applied once
/// with named TLAs; other top-level values ignore them.
///
/// ```mbt check
/// test {
///   let result = @moonjsonnet.evaluate("local x = 6; { answer: x * 7 }")
///   assert_eq(result.stringify(), "{\"answer\":42}")
/// }
/// ```
pub fn evaluate(
  source : String,
  filename? : String = "<input>",
  ext_vars? : Map[String, Json] = Map([]),
  ext_code? : Map[String, String] = Map([]),
  tla_vars? : Map[String, Json] = Map([]),
  tla_code? : Map[String, String] = Map([]),
  native_functions? : Map[String, NativeFunction] = Map([]),
  trace? : (Location, String) -> Unit = default_trace,
  resolver? : (String, String) -> Source raise,
  binary_resolver? : (String, String) -> BinarySource raise,
  limits? : Limits = Limits::default(),
) -> Json raise JsonnetError {
  let loc : Location = { file: filename, line: 1, column: 1, }
  try {
    if limits.steps <= 0 ||
      limits.depth <= 0 ||
      limits.depth > 512 ||
      limits.source_bytes <= 0 ||
      limits.import_bytes <= 0 ||
      limits.imports <= 0 ||
      limits.output_bytes <= 0 {
      raise problem(
        Limit,
        loc,
        "limits must be positive; depth must be at most 512",
      )
    }
    if @utf8.encode(source).length() > limits.source_bytes {
      raise problem(Limit, loc, "source byte limit exceeded")
    }
    let vm : Vm = {
      library: standard_library_expression(),
      thunks: [],
      objects: [],
      limits,
      ext: Map([]),
      parameter_files: Map([]),
      native_functions,
      trace,
      resolver,
      binary_resolver,
      binary_sources: Map([]),
      binary_imports: Map([]),
      sources: Map([]),
      imports: Map([]),
      steps: 0,
      depth: 0,
      imported_bytes: 0,
      output_bytes: 0,
    }
    let ext = vm.prepare_parameters(ext_vars, ext_code, "extvar")
    for name, id in ext {
      vm.ext[name] = id
    }
    let expression = parse(source, filename, limits.depth)
    let value = vm.eval(expression, vm.base_env(file=filename))
    let value = match value {
      Closure(_, _, _) | Builtin(_) | Native(_) => {
        let tla = vm.prepare_parameters(tla_vars, tla_code, "top-level-arg")
        let names = tla.keys().collect()
        names.sort()
        vm.call(value, names.map(name => (Some(name), tla[name])), loc)
      }
      _ => value
    }
    vm.output_bytes = 0
    vm.manifest(value, loc, 0)
  } catch {
    Error(d) => raise Error(d)
    e =>
      raise Error({
        kind: Runtime,
        message: e.to_string(),
        location: loc,
        context: [],
      })
  }
}
