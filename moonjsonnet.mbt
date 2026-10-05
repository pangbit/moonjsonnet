///|
/// Evaluate Jsonnet source into JSON. Imports are disabled unless a resolver is
/// provided. Each call has independent caches and resource counters.
/// `ext_code` and `tla_code` contain lazy Jsonnet expressions in clean scopes.
/// Parsed `ext_programs`/`tla_programs` override code, which overrides JSON for
/// duplicate names. Parsed parameters are lazy, with synthetic std.thisFile but
/// their original diagnostic location and import origin. A top-level function is
/// applied once with named TLAs; other top-level values ignore them.
/// With `anonymous=true`, filename is diagnostic-only: std.thisFile and the
/// entry import origin are empty, matching Go's EvaluateAnonymousSnippet.
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
) -> Json raise JsonnetError {
  Program::parse(source, filename~, anonymous~, limits~).evaluate(
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
/// match `evaluate`; source filename and anonymous mode were fixed when parsed.
pub fn Program::evaluate(
  self : Program,
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
) -> Json raise JsonnetError {
  evaluate_with_output(
    self,
    (vm, value, loc) => vm.manifest(value, loc, 0),
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
fn[T] evaluate_with_output(
  program : Program,
  output : (Vm, Value, Location) -> T raise,
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
  session? : Evaluator,
) -> T raise JsonnetError {
  let filename = program.filename
  let anonymous = program.anonymous
  let loc : Location = { file: filename, line: 1, column: 1, }
  try {
    check_limits(limits, loc)
    if program.source_bytes > limits.source_bytes {
      raise problem(Limit, loc, "source byte limit exceeded")
    }
    check_ast_depth(program.expression, limits.depth)
    let previous : Vm? = match session {
      Some(s) => s.state
      None => None
    }
    let vm : Vm = {
      library: previous
      .map(vm => vm.library)
      .unwrap_or_else(standard_library_expression),
      thunks: previous.map(vm => vm.thunks).unwrap_or([]),
      free_thunks: previous.map(vm => vm.free_thunks).unwrap_or([]),
      free_objects: previous.map(vm => vm.free_objects).unwrap_or([]),
      retries: Map([]),
      persistent: session is Some(_),
      accessed_sources: Map([]),
      parsed_imports: session.map(s => s.parsed_imports).unwrap_or(Map([])),
      objects: previous.map(vm => vm.objects).unwrap_or([]),
      limits,
      ext: Map([]),
      native_functions,
      trace,
      resolver,
      binary_resolver,
      binary_sources: session.map(s => s.binary_sources).unwrap_or(Map([])),
      binary_imports: Map([]),
      sources: session.map(s => s.sources).unwrap_or(Map([])),
      imports: previous.map(vm => vm.imports).unwrap_or(Map([])),
      steps: 0,
      depth: 0,
      frames: [],
      imported_bytes: 0,
      output_bytes: 0,
    }
    defer (if session is Some(owner) {
      vm.retain_imports()
      owner.state = Some(vm)
    })
    let ext = vm.prepare_parameters(ext_vars, ext_code, ext_programs, "extvar")
    for name, id in ext {
      vm.ext[name] = id
    }
    let expression = program.expression
    let value = vm.eval_frame(
      expression,
      vm.base_env(file=if anonymous { "" } else { filename }),
    )
    let value = match value {
      Closure(_, _, _) | Builtin(_) | Native(_) => {
        let tla = vm.prepare_parameters(
          tla_vars, tla_code, tla_programs, "top-level-arg",
        )
        let names = tla.keys().collect()
        names.sort()
        vm.call(value, names.map(name => (Some(name), tla[name])), loc)
      }
      _ => value
    }
    vm.output_bytes = 0
    output(vm, value, loc)
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
