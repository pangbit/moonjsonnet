///|
priv struct RuntimeFrame {
  trimmable : Bool
  trace : TraceFrame?
}

///|
// Assert sugar intentionally lacks a public semantic range. Its diagnostic
// failure site covers the original assertion through its final continuation.
fn diagnostic_expr_end(root : Expr) -> Location {
  let mut node = root
  while node.end is None {
    match node.kind {
      Assert(_, _, body) => node = body
      _ => return node.loc
    }
  }
  node.end.unwrap()
}

///|
/// Preserve original object-assert declaration spans when exporting an editable
/// semantic AST. Keys are the condition's source-range identity. The result is
/// independent; pass it to from_ast after edits that retain those identities.
pub fn Program::assertion_ranges(self : Program) -> Map[String, SourceRange] {
  let ranges : Map[String, SourceRange] = Map([])
  let work = [self.expression]
  while work.pop() is Some(node) {
    if node.kind is Obj(_, _, checks, sites) {
      for index, (condition, _) in checks {
        if sites.get(index).bind(site => site) is Some(range) {
          let key = (
            {
              begin: condition.loc,
              end: condition.end.unwrap_or(condition.loc),
            } : SourceRange).format()
          ranges[key] = range
        }
      }
    }
    for child in ast_export_children(node) {
      work.push(child)
    }
  }
  ranges
}

///|
fn Env::trace_context(
  self : Env,
  name : String,
  bound? : String = "anonymous",
) -> Env {
  { ..self, diagnostic_context: (name, bound), }
}

///|
fn Env::trace_thunk(self : Env) -> Env {
  self.trace_context("thunk from <" + self.diagnostic_context.0 + ">")
}

///|
fn Vm::trace_expression(
  self : Vm,
  expression : Expr,
  environment : Env,
) -> Unit {
  self.current_trace = Some({
    location: Source({
      begin: expression.loc,
      end: expression.end.unwrap_or(expression.loc),
    }),
    name: environment.diagnostic_context.0,
  })
}

///|
// Snapshot before any execution frame is removed. Existing snapshots (including
// retained assertion errors) are not extended or shared with a later caller.
fn Vm::traced(self : Vm, diagnostic : Diagnostic) -> Diagnostic {
  if !diagnostic.trace.is_empty() ||
    diagnostic.kind == Syntax ||
    diagnostic.kind == Static {
    return diagnostic
  }
  let trace : Array[TraceFrame] = []
  for frame in self.frames {
    if frame.trace is Some(frame) {
      trace.push(frame)
    }
  }
  if self.current_trace is Some(frame) {
    trace.push(frame)
  }
  { ..diagnostic, trace, }
}

///|
fn Vm::trace_problem(
  self : Vm,
  kind : ErrorKind,
  loc : Location,
  message : String,
) -> JsonnetError {
  Error(self.traced({ kind, location: loc, message, context: [], trace: [], }))
}

///|
fn Vm::pop_frame(self : Vm) -> Unit {
  if self.frames.pop() is Some(frame) {
    self.current_trace = frame.trace
  }
}

///|
fn[T] Vm::with_trace(
  self : Vm,
  location : TraceLocation,
  body : () -> T raise,
) -> T raise {
  let previous = self.current_trace
  self.current_trace = Some({ location, name: "", })
  defer {
    self.current_trace = previous
  }
  body() catch {
    Error(d) => raise Error(self.traced(d))
    e => raise e
  }
}
