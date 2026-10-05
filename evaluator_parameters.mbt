///|
pub fn Evaluator::ext_var(
  self : Evaluator,
  name : String,
  value : Json,
) -> Unit raise JsonnetError {
  self.idle()
  ignore(self.ext_codes.remove(name))
  ignore(self.ext_nodes.remove(name))
  self.ext_values[name] = value
  self.invalidate_values()
}

///|
pub fn Evaluator::ext_code(
  self : Evaluator,
  name : String,
  value : String,
) -> Unit raise JsonnetError {
  self.idle()
  ignore(self.ext_values.remove(name))
  ignore(self.ext_nodes.remove(name))
  self.ext_codes[name] = value
  self.invalidate_values()
}

///|
pub fn Evaluator::ext_program(
  self : Evaluator,
  name : String,
  value : Program,
) -> Unit raise JsonnetError {
  self.idle()
  ignore(self.ext_values.remove(name))
  ignore(self.ext_codes.remove(name))
  self.ext_nodes[name] = value
  self.invalidate_values()
}

///|
pub fn Evaluator::ext_reset(self : Evaluator) -> Unit raise JsonnetError {
  self.idle()
  self.ext_values.clear()
  self.ext_codes.clear()
  self.ext_nodes.clear()
  self.invalidate_values()
}

///|
pub fn Evaluator::tla_var(
  self : Evaluator,
  name : String,
  value : Json,
) -> Unit raise JsonnetError {
  self.idle()
  ignore(self.tla_codes.remove(name))
  ignore(self.tla_nodes.remove(name))
  self.tla_values[name] = value
}

///|
pub fn Evaluator::tla_code(
  self : Evaluator,
  name : String,
  value : String,
) -> Unit raise JsonnetError {
  self.idle()
  ignore(self.tla_values.remove(name))
  ignore(self.tla_nodes.remove(name))
  self.tla_codes[name] = value
}

///|
pub fn Evaluator::tla_program(
  self : Evaluator,
  name : String,
  value : Program,
) -> Unit raise JsonnetError {
  self.idle()
  ignore(self.tla_values.remove(name))
  ignore(self.tla_codes.remove(name))
  self.tla_nodes[name] = value
}

///|
pub fn Evaluator::tla_reset(self : Evaluator) -> Unit raise JsonnetError {
  self.idle()
  self.tla_values.clear()
  self.tla_codes.clear()
  self.tla_nodes.clear()
}
