///|
// Clean environments, additive fields and manifestation own runtime frames.
// A tail call can remove the current frame only if tailstrict created it.
fn Vm::push_frame(self : Vm, loc : Location, trimmable : Bool) -> Unit raise {
  if self.frames.length() >= self.limits.stack {
    raise problem(Limit, loc, "max stack frames exceeded.")
  }
  self.frames.push(trimmable)
}

///|
fn Vm::eval_frame(
  self : Vm,
  expr : Expr,
  env : Env,
  trimmable? : Bool = false,
) -> Value raise {
  self.push_frame(expr.loc, trimmable)
  let size = self.frames.length()
  // A tail call may already have removed this frame.
  defer (if self.frames.length() == size { ignore(self.frames.pop()) })
  self.eval(expr, env, tail=true)
}
