///|
/// A reusable interpreter with explicit configuration and import-cache lifetime.
/// Ext/native changes invalidate evaluated imports; TLA and trace changes do not.
/// Replacing the importer clears both sources and values. Each execution receives
/// fresh resource counters. Instances cannot be reentered or changed by callbacks.
pub struct Evaluator {
  priv ext_values : Map[String, Json]
  priv ext_codes : Map[String, String]
  priv ext_nodes : Map[String, Program]
  priv tla_values : Map[String, Json]
  priv tla_codes : Map[String, String]
  priv tla_nodes : Map[String, Program]
  priv natives : Map[String, NativeFunction]
  priv mut trace : (Location, String) -> Unit
  priv mut resolver : ((String, String) -> Source raise)?
  priv mut binary_resolver : ((String, String) -> BinarySource raise)?
  priv mut limits : Limits
  priv mut string_output : Bool
  priv mut state : Vm?
  priv mut busy : Bool
}

///|
/// Create a reusable evaluator. Imports start disabled.
///
/// ```mbt check
/// test {
///   let evaluator = @moonjsonnet.Evaluator::new()
///   let program = @moonjsonnet.Program::parse("std.extVar('x')")
///   evaluator.ext_var("x", 42)
///   assert_eq(evaluator.evaluate(program), 42)
///   evaluator.ext_var("x", 7)
///   assert_eq(evaluator.evaluate(program), 7)
/// }
/// ```
pub fn Evaluator::new() -> Evaluator {
  {
    ext_values: Map([]),
    ext_codes: Map([]),
    ext_nodes: Map([]),
    tla_values: Map([]),
    tla_codes: Map([]),
    tla_nodes: Map([]),
    natives: Map([]),
    trace: default_trace,
    resolver: None,
    binary_resolver: None,
    limits: Limits::default(),
    string_output: false,
    state: None,
    busy: false,
  }
}

///|
fn Evaluator::idle(self : Evaluator) -> Unit raise JsonnetError {
  if self.busy {
    raise problem(
      Runtime,
      { file: "<evaluator>", line: 1, column: 1, },
      "evaluator is already executing",
    )
  }
}

///|
fn Evaluator::invalidate_values(self : Evaluator) -> Unit {
  if self.state is Some(vm) {
    vm.thunks.clear()
    vm.objects.clear()
    vm.free_thunks.clear()
    vm.free_objects.clear()
    vm.imports.clear()
    vm.binary_imports.clear()
  }
}

///|
/// Replace import callbacks and invalidate all imported sources, ASTs and values.
/// Omitting both callbacks disables imports.
pub fn Evaluator::set_importer(
  self : Evaluator,
  resolver? : (String, String) -> Source raise,
  binary_resolver? : (String, String) -> BinarySource raise,
) -> Unit raise JsonnetError {
  self.idle()
  self.resolver = resolver
  self.binary_resolver = binary_resolver
  self.state = None
}

///|
pub fn Evaluator::set_trace(
  self : Evaluator,
  trace : (Location, String) -> Unit,
) -> Unit raise JsonnetError {
  self.idle()
  self.trace = trace
}

///|
pub fn Evaluator::set_limits(
  self : Evaluator,
  limits : Limits,
) -> Unit raise JsonnetError {
  self.idle()
  check_limits(limits, { file: "<evaluator>", line: 1, column: 1, })
  self.limits = limits
}

///|
/// Select raw string output for text/multi methods. JSON and stream ignore this.
pub fn Evaluator::set_string_output(
  self : Evaluator,
  enabled : Bool,
) -> Unit raise JsonnetError {
  self.idle()
  self.string_output = enabled
}

///|
pub fn Evaluator::native_function(
  self : Evaluator,
  name : String,
  native : NativeFunction,
) -> Unit raise JsonnetError {
  self.idle()
  self.natives[name] = native
  self.invalidate_values()
}

///|
fn[T] Evaluator::run(
  self : Evaluator,
  program : Program,
  output : (Vm, Value, Location) -> T raise,
) -> T raise JsonnetError {
  self.idle()
  self.busy = true
  defer {
    self.busy = false
  }
  evaluate_with_output(
    program,
    output,
    ext_vars=self.ext_values,
    ext_code=self.ext_codes,
    ext_programs=self.ext_nodes,
    tla_vars=self.tla_values,
    tla_code=self.tla_codes,
    tla_programs=self.tla_nodes,
    native_functions=self.natives,
    trace=self.trace,
    resolver?=self.resolver,
    binary_resolver?=self.binary_resolver,
    limits=self.limits,
    session=self,
  )
}

///|
pub fn Evaluator::evaluate(
  self : Evaluator,
  program : Program,
) -> Json raise JsonnetError {
  self.run(program, (vm, value, loc) => vm.manifest(value, loc, 0))
}

///|
pub fn Evaluator::evaluate_text(
  self : Evaluator,
  program : Program,
) -> String raise JsonnetError {
  self.run(program, (vm, value, loc) => {
    vm.render_text(value, loc, self.string_output)
  })
}

///|
pub fn Evaluator::evaluate_stream(
  self : Evaluator,
  program : Program,
) -> Array[String] raise JsonnetError {
  self.run(program, (vm, value, loc) => vm.render_stream(value, loc))
}

///|
pub fn Evaluator::evaluate_multi(
  self : Evaluator,
  program : Program,
) -> Map[String, String] raise JsonnetError {
  self.run(program, (vm, value, loc) => {
    vm.render_multi(value, loc, self.string_output)
  })
}
