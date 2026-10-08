///|
/// Callbacks observe admitted expressions and their lazy results. Contexts and
/// value handles are valid only during the callback; copy node/range/text views
/// to retain them. Explicit lookups may force values under the execution budgets.
pub(all) struct EvalHook {
  before : (EvalContext) -> Unit raise
  after : (EvalContext, EvalOutcome) -> Unit raise
}

///|
pub(all) enum EvalOutcome {
  Success(DebugValue)
  Failure(Diagnostic)
}

///|
pub struct EvalContext {
  priv vm : Vm
  priv expression : Expr
  priv environment : Env
  priv active : Ref[Bool]
  priv serial : Int
}

///|
pub struct DebugValue {
  priv vm : Vm
  priv value : Value
  priv active : Ref[Bool]
  priv location : Location
}

///|
priv struct EvalHookFrame {
  expression : Expr
  environment : Env
  serial : Int
}

///|
fn EvalContext::check(self : EvalContext) -> Unit raise JsonnetError {
  if !self.active.val {
    raise problem(
      Runtime,
      self.expression.loc,
      "evaluation context is no longer active",
    )
  }
}

///|
fn EvalContext::tick(self : EvalContext) -> Unit raise JsonnetError {
  self.vm.tick(self.expression.loc) catch {
    Error(d) => raise Error(d)
    e => raise problem(Runtime, self.expression.loc, e.to_string())
  }
}

///|
fn DebugValue::check(self : DebugValue) -> Unit raise JsonnetError {
  if !self.active.val {
    raise problem(Runtime, self.location, "debug value is no longer active")
  }
}

///|
pub fn EvalContext::location(self : EvalContext) -> Location {
  self.expression.loc
}

///|
/// Unique within one execution; before/after callbacks share the same ID.
pub fn EvalContext::evaluation_id(self : EvalContext) -> Int {
  self.serial
}

///|
pub fn EvalContext::source_range(self : EvalContext) -> SourceRange? {
  self.expression.end.map(end => { begin: self.expression.loc, end, })
}

///|
/// Return an independent semantic node without evaluating its children.
pub fn EvalContext::node(self : EvalContext) -> Ast raise JsonnetError {
  self.check()
  self.copy_node(self.expression)
}

///|
fn EvalContext::copy_node(
  self : EvalContext,
  root : Expr,
) -> Ast raise JsonnetError {
  let work = [root]
  while work.pop() is Some(node) {
    self.tick()
    for child in ast_export_children(node) {
      work.push(child)
    }
  }
  export_ast(root)
}

///|
/// List lexical identifiers without forcing their values. Sorted deterministically.
pub fn EvalContext::variables(
  self : EvalContext,
) -> Array[String] raise JsonnetError {
  self.check()
  let names : Array[String] = []
  let mut environment = Some(self.environment)
  while environment is Some(env) {
    self.tick()
    if env.debug_visible is Some(visible) {
      let captured = visible(() => self.vm.tick(self.expression.loc)) catch {
        Error(d) => raise Error(d)
        e => raise problem(Runtime, self.expression.loc, e.to_string())
      }
      for name in captured {
        self.tick()
        names.push(name)
      }
      break
    }
    for name, _ in env.names {
      self.tick()
      if name != "self" && name != "super" {
        names.push(name)
      }
    }
    environment = env.parent
  }
  names.sort_by(compare_unicode)
  names
}

///|
/// Copy the active expression stack, outermost first. This semantic hook stack
/// also includes direct expressions and transparent local/conditional bodies.
pub fn EvalContext::stack(self : EvalContext) -> Array[Ast] raise JsonnetError {
  self.check()
  self.vm.hook_stack.map(frame => self.copy_node(frame.expression))
}

///|
/// Return a handle only when the named thunk is already cached; never force it.
pub fn EvalContext::peek(
  self : EvalContext,
  name : String,
) -> DebugValue? raise JsonnetError {
  self.check()
  if !self.variables().contains(name) && name != "self" && name != "super" {
    return None
  }
  guard self.environment.lookup(if name == "$std" { "std" } else { name })
    is Some(id) else {
    return None
  }
  match self.vm.thunks[id] {
    Ready(value) =>
      Some({
        vm: self.vm,
        value,
        active: self.active,
        location: self.expression.loc,
      })
    _ => None
  }
}

///|
/// Force only the named root value. Other hooks are suppressed while inspecting.
pub fn EvalContext::lookup(
  self : EvalContext,
  name : String,
) -> DebugValue raise JsonnetError {
  self.check()
  let loc = self.expression.loc
  if !self.variables().contains(name) && name != "self" && name != "super" {
    raise problem(Runtime, loc, "invalid identifier " + name)
  }
  guard self.environment.lookup(if name == "$std" { "std" } else { name })
    is Some(id) else {
    raise problem(Runtime, loc, "invalid identifier " + name)
  }
  let previous = self.vm.hooks_suppressed
  self.vm.hooks_suppressed = true
  defer {
    self.vm.hooks_suppressed = previous
  }
  let value = self.vm.force(id, loc) catch {
    Error(d) => raise Error(d)
    e => raise problem(Runtime, loc, e.to_string())
  }
  { vm: self.vm, value, active: self.active, location: loc, }
}

///|
/// Manifest an explicitly inspected value; this forces its children and may
/// execute assertions/imports. Inspection shares normal step/depth/stack budgets.
pub fn DebugValue::json(self : DebugValue) -> Json raise JsonnetError {
  self.check()
  let previous = self.vm.hooks_suppressed
  self.vm.hooks_suppressed = true
  defer {
    self.vm.hooks_suppressed = previous
  }
  self.vm.manifest(self.value, self.location, 0) catch {
    Error(d) => raise Error(d)
    e => raise problem(Runtime, self.location, e.to_string())
  }
}

///|
/// Scalar/function/container category without forcing children or assertions.
pub fn DebugValue::kind(self : DebugValue) -> String raise JsonnetError {
  self.check()
  match self.value {
    Nil => "null"
    Bool(_) => "boolean"
    Num(_) => "number"
    Str(_) => "string"
    ArrayValue(_) => "array"
    ObjectValue(_, _) => "object"
    Closure(_, _, _) | Builtin(_) | Native(_) => "function"
  }
}

///|
fn Vm::hook_before(
  self : Vm,
  expression : Expr,
  environment : Env,
  frames : Array[EvalHookFrame],
) -> Unit raise {
  // These field values are runtime implementation nodes, not exportable source
  // expressions. Compiler sugar may reach them while resolving its builtins.
  if expression.kind is StandardFunction(_) ||
    expression.kind is StandardValue(_) {
    return
  }
  if !self.hooks_suppressed && self.eval_hook is Some(hook) {
    let active = Ref(true)
    let serial = self.hook_serial
    self.hook_serial += 1
    let frame : EvalHookFrame = { expression, environment, serial, }
    let context : EvalContext = {
      vm: self,
      expression,
      environment,
      active,
      serial,
    }
    self.hook_stack.push(frame)
    errdefer ignore(self.hook_stack.pop())
    self.hooks_suppressed = true
    defer {
      active.val = false
      self.hooks_suppressed = false
    }
    (hook.before)(context)
    frames.push(frame)
  }
}

///|
fn Vm::hook_after(
  self : Vm,
  frames : Array[EvalHookFrame],
  result : Value?,
  error : Error?,
) -> Unit raise {
  if frames.is_empty() {
    return
  }
  guard self.eval_hook is Some(hook) else { return }
  let base = self.hook_stack.length() - frames.length()
  defer (while self.hook_stack.length() > base {
    ignore(self.hook_stack.pop())
  })
  self.hooks_suppressed = true
  defer {
    self.hooks_suppressed = false
  }
  for i = frames.length() - 1; i >= 0; i = i - 1 {
    let frame = frames[i]
    if error is Some(_) && self.hook_failure_environment is None {
      self.hook_failure_environment = Some(frame.environment)
    }
    let active = Ref(true)
    defer {
      active.val = false
    }
    let context : EvalContext = {
      vm: self,
      expression: frame.expression,
      environment: if error is Some(_) {
        self.hook_failure_environment.unwrap()
      } else {
        frame.environment
      },
      active,
      serial: frame.serial,
    }
    let outcome = match (result, error) {
      (Some(value), _) =>
        Success({ vm: self, value, active, location: frame.expression.loc, })
      (_, Some(Error(d))) =>
        Failure({ ..d, context: d.context.copy(), trace: d.trace.copy(), })
      (_, Some(e)) =>
        Failure({
          kind: Runtime,
          message: e.to_string(),
          location: frame.expression.loc,
          context: [],
          trace: [],
        })
      _ => abort("missing evaluation hook outcome")
    }
    self.trace_expression(frame.expression, frame.environment)
    (hook.after)(context, outcome) catch {
      Error(d) => raise Error(self.traced(d))
      e =>
        raise self.trace_problem(Runtime, frame.expression.loc, e.to_string())
    }
    ignore(self.hook_stack.pop())
  }
}

///|
/// Hook replacement preserves import caches, like trace replacement. Reentrant
/// configuration changes are rejected. Omit the callback to disable hooks.
pub fn Evaluator::set_eval_hook(
  self : Evaluator,
  hook? : EvalHook,
) -> Unit raise JsonnetError {
  self.idle()
  self.eval_hook = hook
}
